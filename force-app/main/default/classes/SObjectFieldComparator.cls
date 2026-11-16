/**
 * SObjectFieldComparator
 * ------------------------------------------------------------------
 * Low-level, stateless comparison of a single field value against a target,
 * typed by the condition metadata's Data_Type__c. Every operator in the engine
 * funnels through here, so all comparison logic lives in exactly one place and
 * is unit-testable on its own.
 */
public inherited sharing class SObjectFieldComparator {

    public class ComparatorException extends Exception {}

    // Operator constants mirror the picklist values on Email_Condition__mdt.Operator__c
    public static final String EQUALS           = 'EQUALS';
    public static final String NOT_EQUALS       = 'NOT_EQUALS';
    public static final String GREATER_THAN     = 'GREATER_THAN';
    public static final String LESS_THAN        = 'LESS_THAN';
    public static final String GREATER_OR_EQUAL = 'GREATER_OR_EQUAL';
    public static final String LESS_OR_EQUAL    = 'LESS_OR_EQUAL';
    public static final String CONTAINS         = 'CONTAINS';
    public static final String STARTS_WITH      = 'STARTS_WITH';
    public static final String IN_LIST          = 'IN';
    public static final String IS_NULL          = 'IS_NULL';
    public static final String IS_NOT_NULL      = 'IS_NOT_NULL';

    /**
     * @param fieldValue  the live value read off the record
     * @param operator    one of the operator constants above
     * @param targetValue the metadata's comparison value (string form)
     * @param dataType    STRING | NUMBER | DATE | DATETIME | BOOLEAN
     */
    public static Boolean compare(Object fieldValue, String operator, String targetValue, String dataType) {
        if (String.isBlank(operator)) {
            throw new ComparatorException('Operator is required');
        }
        operator = operator.toUpperCase();

        // Null-aware operators are evaluated before any type coercion
        if (operator == IS_NULL)     return fieldValue == null;
        if (operator == IS_NOT_NULL) return fieldValue != null;

        // For every other operator, a null field value cannot match
        if (fieldValue == null) return false;

        String type = String.isBlank(dataType) ? 'STRING' : dataType.toUpperCase();

        switch on type {
            when 'NUMBER', 'DECIMAL', 'DOUBLE', 'INTEGER', 'CURRENCY', 'PERCENT' {
                return compareNumber(toDecimal(fieldValue), operator, targetValue);
            }
            when 'DATE' {
                return compareDate(toDate(fieldValue), operator, targetValue);
            }
            when 'DATETIME' {
                return compareDateTime(toDateTime(fieldValue), operator, targetValue);
            }
            when 'BOOLEAN' {
                return compareBoolean(Boolean.valueOf(fieldValue), operator, targetValue);
            }
            when else {
                return compareString(String.valueOf(fieldValue), operator, targetValue);
            }
        }
    }

    // ---------------------------------------------------------------- strings
    private static Boolean compareString(String a, String op, String b) {
        b = (b == null) ? '' : b;
        switch on op {
            when 'EQUALS'      { return a.equalsIgnoreCase(b); }
            when 'NOT_EQUALS'  { return !a.equalsIgnoreCase(b); }
            when 'CONTAINS'    { return a.toLowerCase().contains(b.toLowerCase()); }
            when 'STARTS_WITH' { return a.toLowerCase().startsWith(b.toLowerCase()); }
            when 'IN'          { return splitList(b).contains(a); }
            when else { throw new ComparatorException('Unsupported string operator: ' + op); }
        }
    }

    // ---------------------------------------------------------------- numbers
    private static Boolean compareNumber(Decimal a, String op, String b) {
        if (op == 'IN') return splitList(b).contains(String.valueOf(a));
        Decimal t = Decimal.valueOf(b);
        switch on op {
            when 'EQUALS'           { return a == t; }
            when 'NOT_EQUALS'       { return a != t; }
            when 'GREATER_THAN'     { return a > t; }
            when 'LESS_THAN'        { return a < t; }
            when 'GREATER_OR_EQUAL' { return a >= t; }
            when 'LESS_OR_EQUAL'    { return a <= t; }
            when else { throw new ComparatorException('Unsupported number operator: ' + op); }
        }
    }

    // ------------------------------------------------------------------ dates
    private static Boolean compareDate(Date a, String op, String b) {
        Date t = Date.valueOf(b);
        switch on op {
            when 'EQUALS'           { return a == t; }
            when 'NOT_EQUALS'       { return a != t; }
            when 'GREATER_THAN'     { return a > t; }
            when 'LESS_THAN'        { return a < t; }
            when 'GREATER_OR_EQUAL' { return a >= t; }
            when 'LESS_OR_EQUAL'    { return a <= t; }
            when else { throw new ComparatorException('Unsupported date operator: ' + op); }
        }
    }

    private static Boolean compareDateTime(Datetime a, String op, String b) {
        Datetime t = Datetime.valueOf(b.replace('T', ' '));
        switch on op {
            when 'EQUALS'           { return a == t; }
            when 'NOT_EQUALS'       { return a != t; }
            when 'GREATER_THAN'     { return a > t; }
            when 'LESS_THAN'        { return a < t; }
            when 'GREATER_OR_EQUAL' { return a >= t; }
            when 'LESS_OR_EQUAL'    { return a <= t; }
            when else { throw new ComparatorException('Unsupported datetime operator: ' + op); }
        }
    }

    // --------------------------------------------------------------- booleans
    private static Boolean compareBoolean(Boolean a, String op, String b) {
        Boolean t = Boolean.valueOf(b);
        switch on op {
            when 'EQUALS'     { return a == t; }
            when 'NOT_EQUALS' { return a != t; }
            when else { throw new ComparatorException('Unsupported boolean operator: ' + op); }
        }
    }

    // --------------------------------------------------------------- coercion
    private static Decimal toDecimal(Object v) {
        if (v instanceof Decimal) return (Decimal) v;
        if (v instanceof Integer) return (Decimal) (Integer) v;
        if (v instanceof Double)  return Decimal.valueOf((Double) v);
        return Decimal.valueOf(String.valueOf(v));
    }
    private static Date toDate(Object v) {
        if (v instanceof Date) return (Date) v;
        return Date.valueOf(String.valueOf(v));
    }
    private static Datetime toDateTime(Object v) {
        if (v instanceof Datetime) return (Datetime) v;
        return Datetime.valueOf(String.valueOf(v).replace('T', ' '));
    }
    // Multi-value lists are stored semicolon-separated on the metadata value
    private static List<String> splitList(String csv) {
        List<String> out = new List<String>();
        if (String.isBlank(csv)) return out;
        for (String s : csv.split(';')) out.add(s.trim());
        return out;
    }
}
