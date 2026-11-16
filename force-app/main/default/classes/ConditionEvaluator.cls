/**
 * ConditionEvaluator
 * ------------------------------------------------------------------
 * Evaluates a SINGLE Email_Condition__mdt against one anchor record and returns
 * a Boolean.
 *
 *   - "Main"  condition: reads a field directly off the anchor record.
 *   - "Child" condition: walks a child relationship (already loaded via the
 *      SOQL sub-query) and applies the child criteria:
 *          ANY / OR  -> true if at least one child matches
 *          ALL / AND -> true only if every child matches
 *
 * requiresChange, when set on a Main condition, demands the field actually
 * changed this transaction (new value != old value). In a trigger context the
 * engine supplies the prior values; outside a trigger there is no baseline, so
 * the field is treated as changed.
 */
public inherited sharing class ConditionEvaluator {

    public static final String RELATION_MAIN  = 'Main';
    public static final String RELATION_CHILD = 'Child';

    public static Boolean evaluate(
        Email_Condition__mdt cond,
        SObject anchor,
        Map<Id, Map<String, Object>> oldValuesByRecord
    ) {
        if (RELATION_CHILD.equalsIgnoreCase(cond.Relation_Type__c)) {
            return evaluateChild(cond, anchor);
        }
        return evaluateMain(cond, anchor, oldValuesByRecord);
    }

    // ------------------------------------------------------------------ main
    private static Boolean evaluateMain(
        Email_Condition__mdt cond,
        SObject anchor,
        Map<Id, Map<String, Object>> oldValuesByRecord
    ) {
        if (cond.Requires_Change__c == true
            && !hasChanged(anchor, cond.Field_Name__c, oldValuesByRecord)) {
            return false; // field did not change this transaction -> condition fails
        }
        Object current = anchor.get(cond.Field_Name__c);
        return SObjectFieldComparator.compare(
            current, cond.Operator__c, cond.Value__c, cond.Data_Type__c
        );
    }

    // ----------------------------------------------------------------- child
    private static Boolean evaluateChild(Email_Condition__mdt cond, SObject anchor) {
        // children were loaded under the relationship named in Child_Load__c
        List<SObject> children = anchor.getSObjects(cond.Child_Load__c);
        if (children == null || children.isEmpty()) return false;

        Boolean useAnd = 'ALL'.equalsIgnoreCase(cond.Child_Criteria__c)
                      || 'AND'.equalsIgnoreCase(cond.Child_Criteria__c);

        for (SObject child : children) {
            Boolean match = SObjectFieldComparator.compare(
                child.get(cond.Field_Name__c),
                cond.Operator__c, cond.Value__c, cond.Data_Type__c
            );
            if (useAnd && !match) return false;   // ALL: first miss fails
            if (!useAnd && match) return true;     // ANY: first hit passes
        }
        return useAnd; // ALL and never failed => true ; ANY and never hit => false
    }

    // --------------------------------------------------------------- change?
    private static Boolean hasChanged(
        SObject anchor, String field, Map<Id, Map<String, Object>> oldValuesByRecord
    ) {
        if (oldValuesByRecord == null) return true;          // no baseline -> treat as changed
        Map<String, Object> olds = oldValuesByRecord.get((Id) anchor.get('Id'));
        if (olds == null || !olds.containsKey(field)) return true;
        return anchor.get(field) != olds.get(field);
    }
}
