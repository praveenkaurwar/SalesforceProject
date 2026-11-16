/**
 * EmailConditionEngine
 * ------------------------------------------------------------------
 * Orchestrates the whole evaluation. For each active communication rule it:
 *   1. collects the fields and child relationships its conditions reference,
 *   2. builds ONE selective SOQL per anchor object (SOQLBuilder),
 *   3. evaluates each condition per anchor record (ConditionEvaluator) into a
 *      Map<conditionKey, Boolean>,
 *   4. resolves the rule's formula over that map (FormulaResolver),
 *   5. returns the anchors that qualified, per rule, for downstream generation.
 *
 * Config lives entirely in Custom Metadata, so adding or changing a rule is a
 * metadata deployment, not an Apex change. CMDT reads are platform-cached and
 * do not consume SOQL query limits.
 */
public with sharing class EmailConditionEngine {

    public class RuleResult {
        public String ruleName;
        public String template;
        public Set<Id> qualifiedAnchorIds = new Set<Id>();
    }

    /** Entry point outside a trigger (no change-detection baseline). */
    public static List<RuleResult> run(Set<Id> anchorIds) {
        return run(anchorIds, null);
    }

    /**
     * @param anchorIds          records to evaluate (e.g. CareProgramEnrollee Ids)
     * @param oldValuesByRecord  prior field values for requiresChange, or null
     */
    public static List<RuleResult> run(
        Set<Id> anchorIds,
        Map<Id, Map<String, Object>> oldValuesByRecord
    ) {
        List<RuleResult> results = new List<RuleResult>();
        if (anchorIds == null || anchorIds.isEmpty()) return results;

        List<Email_Communication_Rule__mdt> rules = [
            SELECT Id, DeveloperName, Formula__c, Anchor_Object__c, Template__c
            FROM Email_Communication_Rule__mdt
            WHERE Active__c = true
        ];
        Map<Id, List<Email_Condition__mdt>> conditionsByRule = loadConditions();

        for (Email_Communication_Rule__mdt rule : rules) {
            List<Email_Condition__mdt> conds = conditionsByRule.get(rule.Id);
            if (conds == null || conds.isEmpty()) continue;

            // 1 + 2 : build and run the selective query for this rule's anchor object
            SOQLBuilder builder = new SOQLBuilder(rule.Anchor_Object__c);
            for (Email_Condition__mdt c : conds) {
                if (ConditionEvaluator.RELATION_CHILD.equalsIgnoreCase(c.Relation_Type__c)) {
                    builder.addChildField(c.Child_Load__c, c.Field_Name__c);
                } else {
                    builder.addParentField(c.Field_Name__c);
                }
            }
            List<SObject> anchors = builder.query(anchorIds);

            // 3 + 4 : evaluate conditions, then resolve the formula per record
            RuleResult rr = new RuleResult();
            rr.ruleName = rule.DeveloperName;
            rr.template = rule.Template__c;

            for (SObject anchor : anchors) {
                Map<String, Boolean> condResults = new Map<String, Boolean>();
                for (Email_Condition__mdt c : conds) {
                    condResults.put(
                        c.Condition_Key__c,
                        ConditionEvaluator.evaluate(c, anchor, oldValuesByRecord)
                    );
                }
                if (FormulaResolver.evaluate(rule.Formula__c, condResults)) {
                    rr.qualifiedAnchorIds.add((Id) anchor.get('Id'));
                }
            }
            results.add(rr);
        }
        return results;
    }

    /** Group every condition under its parent rule (CMDT metadata relationship). */
    private static Map<Id, List<Email_Condition__mdt>> loadConditions() {
        Map<Id, List<Email_Condition__mdt>> byRule = new Map<Id, List<Email_Condition__mdt>>();
        for (Email_Condition__mdt c : [
            SELECT Condition_Key__c, Relation_Type__c, Related_Object__c,
                   Parent_Lookup_Field__c, Field_Name__c, Operator__c, Value__c,
                   Data_Type__c, Child_Criteria__c, Requires_Change__c,
                   Child_Load__c, Rule__c
            FROM Email_Condition__mdt
        ]) {
            if (!byRule.containsKey(c.Rule__c)) {
                byRule.put(c.Rule__c, new List<Email_Condition__mdt>());
            }
            byRule.get(c.Rule__c).add(c);
        }
        return byRule;
    }
}
