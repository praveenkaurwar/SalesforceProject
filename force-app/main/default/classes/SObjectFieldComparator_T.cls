/**
 * SObjectFieldComparator_T
 * ------------------------------------------------------------------
 * Unit tests for SObjectFieldComparator, the single place where every operator
 * in the condition engine compares a field value against a metadata value.
 *
 * The comparator is stateless and takes its inputs as plain parameters, so none
 * of these tests touch the database or depend on org metadata.
 *
 * Functional coverage:
 *   - one typed branch per Data_Type__c: STRING, NUMBER, DATE, DATETIME, BOOLEAN,
 *     plus the fallback to STRING when the data type is blank
 *   - string comparison is case-insensitive for EQUALS, CONTAINS and STARTS_WITH
 *   - IN splits the metadata value on semicolons and tolerates spacing
 *   - IS_NULL and IS_NOT_NULL are answered before any type coercion, so they
 *     work on a null field value
 *   - every other operator fails closed on a null field value rather than
 *     throwing
 *   - ComparatorException is raised for a blank operator and for an operator the
 *     chosen data type does not support
 */
@IsTest
private class SObjectFieldComparator_T {
    // ------------------------------------------------------------------ strings
    @IsTest
    static void stringOperatorsIgnoreCase() {
        Assert.isTrue(
            SObjectFieldComparator.compare('Gold', 'EQUALS', 'gold', 'STRING'),
            'EQUALS should ignore case'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare('Platinum', 'CONTAINS', 'LATIN', 'STRING'),
            'CONTAINS should ignore case'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare('Platinum', 'STARTS_WITH', 'plat', 'STRING'),
            'STARTS_WITH should ignore case'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare('Gold', 'NOT_EQUALS', 'Silver', 'STRING'),
            'NOT_EQUALS should be true for different values'
        );
    }

    @IsTest
    static void blankDataTypeFallsBackToString() {
        Assert.isTrue(
            SObjectFieldComparator.compare('Gold', 'EQUALS', 'gold', null),
            'A blank data type should be treated as STRING'
        );
    }

    @IsTest
    static void inOperatorSplitsOnSemicolons() {
        Assert.isTrue(
            SObjectFieldComparator.compare('Silver', 'IN', 'Gold; Silver;Bronze', 'STRING'),
            'IN should match a value after trimming the list entries'
        );
        Assert.isFalse(
            SObjectFieldComparator.compare('Copper', 'IN', 'Gold;Silver', 'STRING'),
            'IN should not match a value outside the list'
        );
    }

    // ------------------------------------------------------------------ numbers
    @IsTest
    static void numberComparisonsHandleIntegerAndDecimal() {
        Assert.isTrue(
            SObjectFieldComparator.compare(150, 'EQUALS', '150', 'NUMBER'),
            'An Integer field value should coerce to Decimal'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare(99.5, 'GREATER_THAN', '50', 'NUMBER'),
            'GREATER_THAN should compare numerically'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare(50, 'LESS_OR_EQUAL', '50', 'NUMBER'),
            'LESS_OR_EQUAL should be true at the boundary'
        );
        Assert.isFalse(
            SObjectFieldComparator.compare(10, 'GREATER_OR_EQUAL', '20', 'NUMBER'),
            'GREATER_OR_EQUAL should be false below the target'
        );
    }

    // -------------------------------------------------------------------- dates
    @IsTest
    static void dateComparisonsUseDateSemantics() {
        Date value = Date.newInstance(2026, 1, 15);

        Assert.isTrue(
            SObjectFieldComparator.compare(value, 'GREATER_THAN', '2026-01-01', 'DATE'),
            'A later date should be greater'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare(value, 'EQUALS', '2026-01-15', 'DATE'),
            'The same date should be equal'
        );
    }

    @IsTest
    static void dateTimeComparisonsAcceptIsoSeparator() {
        Datetime value = Datetime.newInstance(2026, 1, 15, 10, 0, 0);

        // The comparator swaps the ISO 'T' separator for a space before parsing.
        Assert.isTrue(
            SObjectFieldComparator.compare(
                value,
                'LESS_THAN',
                '2026-02-01T00:00:00',
                'DATETIME'
            ),
            'An earlier datetime should be less than the target'
        );
    }

    // ----------------------------------------------------------------- booleans
    @IsTest
    static void booleanComparisonsMatchOnValue() {
        Assert.isTrue(
            SObjectFieldComparator.compare(true, 'EQUALS', 'true', 'BOOLEAN'),
            'EQUALS should match a true checkbox'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare(false, 'NOT_EQUALS', 'true', 'BOOLEAN'),
            'NOT_EQUALS should match an unchecked checkbox against true'
        );
    }

    // --------------------------------------------------------------- null logic
    @IsTest
    static void nullOperatorsAnswerBeforeCoercion() {
        Assert.isTrue(
            SObjectFieldComparator.compare(null, 'IS_NULL', null, 'NUMBER'),
            'IS_NULL should be true for a null field value'
        );
        Assert.isFalse(
            SObjectFieldComparator.compare(null, 'IS_NOT_NULL', null, 'NUMBER'),
            'IS_NOT_NULL should be false for a null field value'
        );
        Assert.isTrue(
            SObjectFieldComparator.compare('Gold', 'IS_NOT_NULL', null, 'STRING'),
            'IS_NOT_NULL should be true for a populated field'
        );
    }

    @IsTest
    static void nullFieldValueFailsEveryOtherOperator() {
        Assert.isFalse(
            SObjectFieldComparator.compare(null, 'EQUALS', 'Gold', 'STRING'),
            'A null field value should not match EQUALS'
        );
        Assert.isFalse(
            SObjectFieldComparator.compare(null, 'GREATER_THAN', '10', 'NUMBER'),
            'A null field value should not match GREATER_THAN'
        );
    }

    // --------------------------------------------------------------- exceptions
    @IsTest
    static void blankOperatorThrows() {
        try {
            SObjectFieldComparator.compare('Gold', '', 'Gold', 'STRING');
            Assert.fail('Expected ComparatorException for a blank operator');
        } catch (SObjectFieldComparator.ComparatorException e) {
            Assert.isTrue(
                e.getMessage().contains('Operator'),
                'The message should say the operator is required: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void operatorUnsupportedByTypeThrows() {
        try {
            // GREATER_THAN has no meaning for the string branch.
            SObjectFieldComparator.compare('Gold', 'GREATER_THAN', 'Silver', 'STRING');
            Assert.fail('Expected ComparatorException for an unsupported operator');
        } catch (SObjectFieldComparator.ComparatorException e) {
            Assert.isTrue(
                e.getMessage().contains('string operator'),
                'The message should name the unsupported branch: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void operatorUnsupportedByBooleanThrows() {
        try {
            SObjectFieldComparator.compare(true, 'CONTAINS', 'true', 'BOOLEAN');
            Assert.fail('Expected ComparatorException for CONTAINS on a boolean');
        } catch (SObjectFieldComparator.ComparatorException e) {
            Assert.isTrue(
                e.getMessage().contains('boolean operator'),
                'The message should name the unsupported branch: ' + e.getMessage()
            );
        }
    }
}
