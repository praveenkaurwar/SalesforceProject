/**
 * EmailConditionQueueable
 * ------------------------------------------------------------------
 * Runs the engine asynchronously over a large population of anchor records.
 * Each execution processes a bounded chunk, then CHAINS itself (one child
 * Queueable per run) for the remainder. Chaining keeps every transaction inside
 * governor limits while still processing an arbitrarily large population, and
 * each chained job starts with a fresh set of limits.
 *
 * Queueable (not @future) because it carries complex state (the Id list) and is
 * chainable; a Queueable may enqueue exactly one child Queueable, which is all
 * the chain needs.
 */
public with sharing class EmailConditionQueueable implements Queueable {

    private final List<Id> anchorIds;
    private final Integer chunkSize;

    public EmailConditionQueueable(List<Id> anchorIds) {
        this(anchorIds, 200);
    }
    public EmailConditionQueueable(List<Id> anchorIds, Integer chunkSize) {
        this.anchorIds = anchorIds;
        this.chunkSize = (chunkSize == null || chunkSize <= 0) ? 200 : chunkSize;
    }

    public void execute(QueueableContext ctx) {
        if (anchorIds == null || anchorIds.isEmpty()) return;

        // 1. take this chunk
        Integer end = Math.min(chunkSize, anchorIds.size());
        Set<Id> batch = new Set<Id>();
        for (Integer i = 0; i < end; i++) {
            batch.add(anchorIds[i]);
        }

        // 2. evaluate, then hand the qualified records to the generator.
        //    EmailGenerationService is the downstream component that renders the
        //    emails / faxes / letters from each rule's template. It is NOT part
        //    of this engine package - wire it to your real generation class.
        List<EmailConditionEngine.RuleResult> results = EmailConditionEngine.run(batch);
        EmailGenerationService.generate(results);

        // 3. chain the remainder as one child Queueable (skipped under test,
        //    where chaining is not allowed).
        if (anchorIds.size() > end && !Test.isRunningTest()) {
            List<Id> remaining = new List<Id>();
            for (Integer i = end; i < anchorIds.size(); i++) {
                remaining.add(anchorIds[i]);
            }
            System.enqueueJob(new EmailConditionQueueable(remaining, chunkSize));
        }
    }
}
