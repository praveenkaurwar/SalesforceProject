# Email Condition Engine

A metadata-driven engine that decides which records qualify for a communication.
Rules and their conditions live entirely in Custom Metadata, so adding or
changing a rule is a metadata deployment rather than an Apex change.

## Classes (the flow)

```
EmailConditionQueueable   async driver — chunks the population, chains itself
        │
        ▼
EmailConditionEngine      orchestrator — loads CMDT rules + conditions,
        │                 builds the query, evaluates, resolves the formula
        ├── SOQLBuilder            builds ONE selective query (parent fields +
        │                          child sub-queries) bound to :anchorIds
        ├── ConditionEvaluator     evaluates one condition (Main or Child),
        │                          handles child AND/OR and requiresChange
        │        └── SObjectFieldComparator   typed field-vs-value comparison
        └── FormulaResolver        evaluates "1 AND (2 OR 3)" over the per-key
                                   boolean results (recursive-descent parser)
```

**FormulaResolver** is the piece that lets an admin express nested logic
(`1 AND 2 OR 3`) purely in metadata. It is a recursive-descent parser with
precedence `NOT > AND > OR` and parentheses support; a blank formula falls back
to AND of all conditions.

`EmailConditionEngine.run(Set<Id>)` returns a `RuleResult` per active rule,
carrying the rule name, its template and the Ids of the anchor records that
qualified.

## Custom Metadata

**Email_Communication_Rule__mdt** — one record per communication rule

| Field | Type | Purpose |
|---|---|---|
| `Formula__c` | Text | e.g. `1 AND (2 OR 3)`; blank means AND of all conditions |
| `Anchor_Object__c` | Text | API name of the object being evaluated, e.g. `CareProgramEnrollee` |
| `Template__c` | Text | template / channel reference passed to the generator |
| `Active__c` | Checkbox | only active rules are evaluated |

**Email_Condition__mdt** — one record per condition, linked to a rule

| Field | Type | Purpose |
|---|---|---|
| `Rule__c` | Metadata Relationship | parent `Email_Communication_Rule__mdt` |
| `Condition_Key__c` | Text | the token used in the formula, e.g. `1` |
| `Relation_Type__c` | Picklist | `Main` or `Child` |
| `Related_Object__c` | Text | child object API name |
| `Parent_Lookup_Field__c` | Text | child's lookup back to the anchor |
| `Field_Name__c` | Text | API name of the field to test |
| `Operator__c` | Picklist | `EQUALS`, `NOT_EQUALS`, `GREATER_THAN`, `LESS_THAN`, `GREATER_OR_EQUAL`, `LESS_OR_EQUAL`, `CONTAINS`, `STARTS_WITH`, `IN`, `IS_NULL`, `IS_NOT_NULL` |
| `Value__c` | Text | comparison value (`;`-separated for `IN`) |
| `Data_Type__c` | Picklist | `STRING`, `NUMBER`, `DATE`, `DATETIME`, `BOOLEAN` |
| `Child_Criteria__c` | Picklist | `ANY` or `ALL` (`OR`/`AND` spellings also accepted) |
| `Requires_Change__c` | Checkbox | field must have changed this transaction |
| `Child_Load__c` | Text | child relationship name for the sub-query and `getSObjects(...)` |

Both types and all their fields are defined under
`force-app/main/default/objects/`, so a source deploy creates them. The rule and
condition *records* themselves are not in the repo — create them per org.

## Tests

`FormulaResolver_T` and `SObjectFieldComparator_T` cover the two stateless
classes: operator precedence, parentheses, `NOT`, the blank-formula fallback and
the malformed-formula exceptions; and every typed comparison branch, `IN`
splitting, null handling and the unsupported-operator exceptions.

```bash
sf apex run test --tests FormulaResolver_T --tests SObjectFieldComparator_T --result-format human --target-org <alias>
```

## Known gaps

- **`EmailGenerationService` is a placeholder.** `EmailConditionQueueable` calls
  `EmailGenerationService.generate(...)`, and the class in this repo only logs.
  Point it at the real generation class before expecting any communication to be
  sent.
- **The engine itself is untested.** `EmailConditionEngine`,
  `ConditionEvaluator`, `SOQLBuilder` and `EmailConditionQueueable` have no test
  coverage. Testing them properly means injecting conditions rather than
  querying CMDT, so the tests do not depend on org metadata.
- **`requiresChange` needs a prior-value map.** Pass it from the trigger's
  `oldMap` via `run(anchorIds, oldValuesByRecord)`; with no baseline the field is
  treated as changed.
- **Dynamic SOQL is not escaped.** `SOQLBuilder` interpolates object, field and
  child-relationship names straight from metadata without
  `String.escapeSingleQuotes()`. The Id filter is bound, and the names come from
  admin-controlled metadata rather than user input, but it is a deviation from
  the project's SOQL guidance.
- **`SObjectFieldComparator.compareDateTime` can throw on a blank `Value__c`,**
  since it calls `.replace('T', ' ')` on the target before any null check.

## A note on `SOQLBuilder`

`SOQLBuilder.query(Set<Id> anchorIds)` runs dynamic SOQL that binds to
`:anchorIds`. That bind resolves against the method's parameter name, so **do not
rename that parameter** — the query breaks at runtime if you do.
