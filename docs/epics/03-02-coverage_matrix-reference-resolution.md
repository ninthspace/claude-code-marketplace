# Coverage — resolving a reference back to a document

**Number**: 03-02  
**Source epic**: 03-02  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR8 | A reference a user supplies resolves to exactly one document. | `resolve_reference` given a reference matching exactly one document returns that document's row. | Story 1 | `[integration]` | ✓ |
| 2 | FR8 | resolves to exactly one document | A reference matching both an epic and its coverage matrix, called with `kind: 'epic'`, returns the epic. | Story 1 | `[integration]` | ✓ |
| 3 | FR8 | An unresolvable reference, and one that matches more than one document, are each refused with a message naming what was looked for | A reference matching no document is refused, and the refusal message contains the reference that was looked for. | Story 2 | `[integration]` | ✓ |
| 4 | FR8 | never resolved to a best guess | must NOT — A reference matching both an epic and its coverage matrix, called with no `kind`, must not return either one. It is refused as ambiguous. | Story 2 | `[integration]` | ✓ |
| 5 | FR8 | one that matches more than one document | control — The fixture holds a colliding pair — an epic and its coverage matrix — so the ambiguous path is reachable. Against a fixture with one epic and no matrix the ambiguity never fires and the two criteria above pass by never being exercised. | Story 2 | `[integration]` | ✓ |
| 6 | FR9 | Resolution costs one tool call, not a listing of every document in the project | Resolution issues a bounded number of statements against the database, and the count does not grow with the number of documents the project holds — measured against two corpora of different sizes. | Story 1 | `[integration]` | ✓ |
| 7 | FR10 | names the candidates it did find, so a mistyped reference is corrected from the refusal itself | The refusal for an unresolvable reference names the references that do exist for that kind, so a mistyped one is corrected from the message. | Story 2 | `[integration]` | ✓ |
| 8 | NFR3 | no transformation, case-folding, quoting or escaping between what a person reads and what they type | A reference read from any tool's output is accepted verbatim by `resolve_reference` and returns the document it came from — a round trip over every document in the fixture corpus, with no transformation applied in between. | Story 1 | `[integration]` | ✓ |
