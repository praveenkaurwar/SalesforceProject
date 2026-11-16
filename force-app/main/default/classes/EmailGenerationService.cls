/**
 * EmailGenerationService
 * ------------------------------------------------------------------
 * PLACEHOLDER - NOT A WORKING IMPLEMENTATION.
 *
 * EmailConditionQueueable hands the qualified records from each rule to
 * EmailGenerationService.generate(...). That generator - the component that
 * actually renders and sends the emails, faxes or letters from each rule's
 * template - is not part of the condition engine and was not included with it.
 *
 * This class exists only so the engine compiles and deploys. It deliberately
 * does nothing but log. Before the engine can deliver anything, replace this
 * class with the real generation class, or change the call in
 * EmailConditionQueueable.execute to point at it.
 */
public with sharing class EmailGenerationService {
    /**
     * @description Placeholder for the downstream generation step. Logs the
     *              rules that produced qualified records and sends nothing.
     * @param results per-rule evaluation output from EmailConditionEngine
     * @return void
     */
    public static void generate(List<EmailConditionEngine.RuleResult> results) {
        // Nothing to do without a real generator; log so a deployed-but-unwired
        // engine is visible in the debug log rather than silently dropping work.
        if (results == null || results.isEmpty()) {
            return;
        }

        for (EmailConditionEngine.RuleResult result : results) {
            System.debug(
                LoggingLevel.WARN,
                'EmailGenerationService is a placeholder - no communication sent. Rule: ' +
                    result.ruleName +
                    ', template: ' +
                    result.template +
                    ', qualified records: ' +
                    result.qualifiedAnchorIds.size()
            );
        }
    }
}
