/**
 * SOQLBuilder
 * ------------------------------------------------------------------
 * Assembles ONE selective SOQL query for an anchor object (e.g.
 * CareProgramEnrollee) that collects:
 *   - every field referenced by "Main" conditions, and
 *   - a child sub-query per child relationship referenced by "Child" conditions.
 *
 * Fields go into Sets so duplicates collapse, and the query is always bound to
 * a Set<Id> so it stays selective (filter on the indexed Id field). Building the
 * query from metadata means one query serves any rule, regardless of how many
 * fields or child relationships it touches.
 */
public inherited sharing class SOQLBuilder {

    private final String anchorObject;
    private final Set<String> parentFields = new Set<String>{ 'Id' };
    // child relationship name -> set of fields to select from it
    private final Map<String, Set<String>> childFields = new Map<String, Set<String>>();

    public SOQLBuilder(String anchorObject) {
        this.anchorObject = anchorObject;
    }

    public SOQLBuilder addParentField(String field) {
        if (String.isNotBlank(field)) parentFields.add(field);
        return this;
    }

    public SOQLBuilder addChildField(String childRelationship, String field) {
        if (String.isBlank(childRelationship) || String.isBlank(field)) return this;
        if (!childFields.containsKey(childRelationship)) {
            childFields.put(childRelationship, new Set<String>{ 'Id' });
        }
        childFields.get(childRelationship).add(field);
        return this;
    }

    public String build() {
        List<String> selects = new List<String>(parentFields);
        for (String rel : childFields.keySet()) {
            selects.add(
                '(SELECT ' + String.join(new List<String>(childFields.get(rel)), ', ')
                + ' FROM ' + rel + ')'
            );
        }
        return 'SELECT ' + String.join(selects, ', ')
             + ' FROM '  + anchorObject
             + ' WHERE Id IN :anchorIds';
    }

    /**
     * Runs the built query. The local parameter name MUST stay `anchorIds`
     * because the dynamic SOQL binds to :anchorIds.
     */
    public List<SObject> query(Set<Id> anchorIds) {
        String soql = build();
        return Database.query(soql);
    }
}
