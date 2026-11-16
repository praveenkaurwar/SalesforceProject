/**
 * FormulaResolver
 * ------------------------------------------------------------------
 * Evaluates a boolean formula such as  "1 AND (2 OR 3) AND NOT 4"  where each
 * operand is a condition key whose truth value has ALREADY been computed and
 * passed in via the results map (key -> Boolean).
 *
 * Implemented as a recursive-descent parser so it supports parentheses and
 * correct operator precedence:   NOT  >  AND  >  OR.
 *
 * This is the layer that lets an admin express nested logic like
 * "1 AND 2 OR 3" purely in metadata, without touching Apex. If the formula is
 * blank, the engine falls back to a plain AND of every condition.
 */
public inherited sharing class FormulaResolver {

    public class FormulaException extends Exception {}

    private final List<String> tokens;
    private final Map<String, Boolean> values;
    private Integer pos;

    private FormulaResolver(List<String> tokens, Map<String, Boolean> values) {
        this.tokens = tokens;
        this.values = values;
        this.pos    = 0;
    }

    /**
     * @param formula          e.g. "1 AND 2 OR 3"  (null/blank => AND of all)
     * @param conditionResults conditionKey -> Boolean result
     */
    public static Boolean evaluate(String formula, Map<String, Boolean> conditionResults) {
        if (String.isBlank(formula)) {
            if (conditionResults == null || conditionResults.isEmpty()) return false;
            for (Boolean b : conditionResults.values()) {
                if (b != true) return false;      // default behaviour: all must be true
            }
            return true;
        }
        FormulaResolver r = new FormulaResolver(tokenize(formula), conditionResults);
        Boolean result = r.parseOr();
        if (r.pos != r.tokens.size()) {
            throw new FormulaException('Unexpected token near: ' + r.peek());
        }
        return result;
    }

    // ---- grammar (lowest precedence first) ---------------------------------
    //   expr := orExpr
    //   orExpr  := andExpr ( 'OR'  andExpr )*
    //   andExpr := notExpr ( 'AND' notExpr )*
    //   notExpr := 'NOT' notExpr | atom
    //   atom    := '(' orExpr ')' | conditionKey

    private Boolean parseOr() {
        Boolean left = parseAnd();
        while (isNext('OR')) {
            consume('OR');
            Boolean right = parseAnd();
            left = left || right;
        }
        return left;
    }

    private Boolean parseAnd() {
        Boolean left = parseNot();
        while (isNext('AND')) {
            consume('AND');
            Boolean right = parseNot();
            left = left && right;
        }
        return left;
    }

    private Boolean parseNot() {
        if (isNext('NOT')) {
            consume('NOT');
            return !parseNot();
        }
        return parseAtom();
    }

    private Boolean parseAtom() {
        String tok = peek();
        if (tok == '(') {
            consume('(');
            Boolean inner = parseOr();
            if (!isNext(')')) throw new FormulaException('Missing closing parenthesis');
            consume(')');
            return inner;
        }
        // operand: a condition key, must resolve from the supplied map
        String key = consumeAny();
        if (!values.containsKey(key)) {
            throw new FormulaException('No evaluated result for condition key: ' + key);
        }
        return values.get(key) == true;
    }

    // ---- token helpers -----------------------------------------------------
    private String peek() {
        return pos < tokens.size() ? tokens[pos] : null;
    }
    private Boolean isNext(String t) {
        String p = peek();
        return p != null && p.equalsIgnoreCase(t);
    }
    private void consume(String expected) {
        if (!isNext(expected)) {
            throw new FormulaException('Expected ' + expected + ' but found ' + peek());
        }
        pos++;
    }
    private String consumeAny() {
        String t = peek();
        if (t == null) throw new FormulaException('Unexpected end of formula');
        pos++;
        return t;
    }

    private static List<String> tokenize(String formula) {
        List<String> out = new List<String>();
        // pad parentheses so a whitespace split isolates them as their own tokens
        String padded = formula.replace('(', ' ( ').replace(')', ' ) ');
        for (String raw : padded.split('\\s+')) {
            String t = raw.trim();
            if (String.isNotBlank(t)) out.add(t);
        }
        return out;
    }
}
