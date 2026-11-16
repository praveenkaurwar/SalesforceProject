/**
 * FormulaResolver_T
 * ------------------------------------------------------------------
 * Unit tests for FormulaResolver, the recursive-descent parser that resolves a
 * rule's boolean formula ("1 AND (2 OR 3)") over condition results that have
 * already been computed.
 *
 * FormulaResolver is stateless and takes its operands from a map, so none of
 * these tests touch the database or depend on org metadata - every case is pure
 * logic and runs with SeeAllData off and no test setup.
 *
 * Functional coverage:
 *   - operator precedence: AND binds tighter than OR, and parentheses override it
 *   - NOT binds tighter than AND, including NOT applied to a parenthesised group
 *   - nested parentheses resolve innermost first
 *   - operators are recognised regardless of letter case
 *   - a blank formula falls back to AND of every condition, and returns false
 *     when there is nothing to AND
 *   - malformed formulas raise FormulaException rather than returning a wrong
 *     boolean: unknown condition key, missing closing parenthesis, and a
 *     trailing token the grammar cannot consume
 */
@IsTest
private class FormulaResolver_T {
    // 1 = true, 2 = true, 3 = false. Chosen so that "1 OR 2 AND 3" tells
    // correct precedence (true) apart from left-to-right evaluation (false).
    private static Map<String, Boolean> baseResults() {
        return new Map<String, Boolean>{ '1' => true, '2' => true, '3' => false };
    }

    @IsTest
    static void andBindsTighterThanOr() {
        Test.startTest();
        Boolean result = FormulaResolver.evaluate('1 OR 2 AND 3', baseResults());
        Test.stopTest();

        // 1 OR (2 AND 3) = true OR false = true.
        // Evaluated left to right it would be (1 OR 2) AND 3 = false.
        Assert.isTrue(result, 'AND should bind tighter than OR');
    }

    @IsTest
    static void parenthesesOverridePrecedence() {
        Boolean result = FormulaResolver.evaluate('(1 OR 2) AND 3', baseResults());

        // Forcing the OR first gives true AND false = false.
        Assert.isFalse(result, 'Parentheses should force the OR to resolve first');
    }

    @IsTest
    static void notBindsTighterThanAnd() {
        Boolean result = FormulaResolver.evaluate('1 AND NOT 3', baseResults());

        // 1 AND (NOT 3) = true AND true = true
        Assert.isTrue(result, 'NOT should apply to its operand before the AND');
    }

    @IsTest
    static void notAppliesToParenthesisedGroup() {
        Boolean result = FormulaResolver.evaluate('NOT (1 AND 2)', baseResults());

        // NOT (true AND true) = false
        Assert.isFalse(result, 'NOT should negate the whole parenthesised group');
    }

    @IsTest
    static void nestedParenthesesResolveInnermostFirst() {
        Boolean result = FormulaResolver.evaluate(
            '((1 AND 2) OR 3) AND NOT 3',
            baseResults()
        );

        // ((true AND true) OR false) AND NOT false = true AND true = true
        Assert.isTrue(result, 'Nested groups should resolve from the inside out');
    }

    @IsTest
    static void operatorsAreCaseInsensitive() {
        Boolean result = FormulaResolver.evaluate('1 and not 3', baseResults());

        Assert.isTrue(result, 'Lower-case operators should be recognised');
    }

    @IsTest
    static void blankFormulaRequiresEveryConditionTrue() {
        Boolean allTrue = FormulaResolver.evaluate(
            '',
            new Map<String, Boolean>{ '1' => true, '2' => true }
        );
        Boolean oneFalse = FormulaResolver.evaluate(
            null,
            new Map<String, Boolean>{ '1' => true, '2' => false }
        );

        Assert.isTrue(allTrue, 'A blank formula should AND every condition');
        Assert.isFalse(oneFalse, 'A single false condition should fail the AND');
    }

    @IsTest
    static void blankFormulaWithNoConditionsIsFalse() {
        Boolean emptyMap = FormulaResolver.evaluate('', new Map<String, Boolean>());
        Boolean nullMap = FormulaResolver.evaluate('', null);

        Assert.isFalse(emptyMap, 'No conditions should not qualify a record');
        Assert.isFalse(nullMap, 'A null result map should not qualify a record');
    }

    @IsTest
    static void unknownConditionKeyThrows() {
        try {
            FormulaResolver.evaluate('1 AND 9', baseResults());
            Assert.fail('Expected FormulaException for a key with no result');
        } catch (FormulaResolver.FormulaException e) {
            Assert.isTrue(
                e.getMessage().contains('9'),
                'The message should name the unresolved key: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void missingClosingParenthesisThrows() {
        try {
            FormulaResolver.evaluate('(1 AND 2', baseResults());
            Assert.fail('Expected FormulaException for an unbalanced formula');
        } catch (FormulaResolver.FormulaException e) {
            Assert.isTrue(
                e.getMessage().contains('closing parenthesis'),
                'The message should describe the unbalanced parenthesis: ' +
                    e.getMessage()
            );
        }
    }

    @IsTest
    static void trailingTokenThrows() {
        try {
            // No operator between the two operands, so a token is left over.
            FormulaResolver.evaluate('1 2', baseResults());
            Assert.fail('Expected FormulaException for an unconsumed token');
        } catch (FormulaResolver.FormulaException e) {
            Assert.isTrue(
                e.getMessage().contains('Unexpected token'),
                'The message should flag the unexpected token: ' + e.getMessage()
            );
        }
    }
}
