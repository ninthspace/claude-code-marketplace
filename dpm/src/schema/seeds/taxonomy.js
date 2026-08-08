/**
 * The four `taxonomy` domains, transcribed from a real CPM project's output.
 *
 * **Ids are stable slugs, not ULIDs.** AD9 makes every id a ULID because ids are minted by
 * the tool surface and only have to be unique. These are not minted — they are the same
 * terms in every database dpm ever creates, and Story 5's vocabulary migrations are
 * insert-if-absent, which needs a key that means the same thing in two databases that never
 * met. A ULID here would make `observation:testing-gaps` a different row in every project
 * and leave the migration keying on `(domain, name)` anyway, which is the natural key with
 * an extra indirection in front of it.
 *
 * `singular` is set only where the display form genuinely differs from the plural heading —
 * retro categories are written as headings in the plural and cited per-observation in the
 * singular, and nothing else here is.
 */

/** Retro observation categories. CPM fixes these in prose; 22 real retros spell them twelve ways. */
const OBSERVATION = [
  ['smooth-deliveries', 'Smooth Deliveries', 'Smooth delivery'],
  ['scope-surprises', 'Scope Surprises', 'Scope surprise'],
  ['criteria-gaps', 'Criteria Gaps', 'Criteria gap'],
  ['complexity-underestimates', 'Complexity Underestimates', 'Complexity underestimate'],
  ['codebase-discoveries', 'Codebase Discoveries', 'Codebase discovery'],
  ['testing-gaps', 'Testing Gaps', 'Testing gap'],
  ['patterns-worth-reusing', 'Patterns Worth Reusing', 'Pattern worth reusing'],
];

/**
 * Review concern types. The control case in the spec's evidence: these appear as literal
 * headings in `cpm:review`'s output template and held almost perfectly across the corpus,
 * where the retro categories above — the same project, the same author, prose instead of a
 * template — did not.
 */
const FINDING = [
  ['unclear-requirements', 'Unclear Requirements'],
  ['missing-acceptance-criteria', 'Missing Acceptance Criteria'],
  ['hidden-complexity', 'Hidden Complexity'],
  ['architectural-risks', 'Architectural Risks'],
  ['testability-concerns', 'Testability Concerns'],
  ['scope-creep', 'Scope Creep'],
  ['dependency-risks', 'Dependency Risks'],
  ['spec-compliance', 'Spec Compliance'],
  ['adr-compliance', 'ADR Compliance'],
  ['missing-test-coverage', 'Missing Test Coverage'],
];

/** Shared by `finding` and `audit_finding`, which is why it is a domain and not a column enum. */
const SEVERITY = [
  ['critical', 'Critical'],
  ['warning', 'Warning'],
  ['suggestion', 'Suggestion'],
];

/** The nine dimensions `cpm:audit` sweeps, in the fixed order it sweeps them. */
const AUDIT_DIMENSION = [
  ['architectural-decay', 'Architectural decay'],
  ['consistency-rot', 'Consistency rot'],
  ['type-debt', 'Type & contract debt'],
  ['test-debt', 'Test debt'],
  ['dependency-debt', 'Dependency & config debt'],
  ['performance', 'Performance'],
  ['error-observability', 'Error handling & observability'],
  ['security', 'Security'],
  ['documentation-drift', 'Documentation drift'],
];

function domain(name, terms) {
  return terms.map(([slug, term, singular = null], index) => ({
    id: `${name}:${slug}`,
    domain: name,
    name: term,
    singular,
    position: index + 1,
    retired_at: null,
  }));
}

export const TAXONOMY = [
  ...domain('observation', OBSERVATION),
  ...domain('finding', FINDING),
  ...domain('severity', SEVERITY),
  ...domain('audit_dimension', AUDIT_DIMENSION),
];
