/**
 * The verification binding (FR21) — what a ✓ is a ✓ *of*.
 *
 * `coverage.verified_at` says a fragment was checked against a criterion; `binding_hash` says
 * which texts were in front of whoever checked. The `CHECK` keeps the pair in lockstep and the
 * three triggers in `011-decay.sql` clear both when either text moves, so the mark cannot outlive
 * what it attests to.
 *
 * **The hash is computed here and is not an argument.** A caller that supplies it can supply
 * anything, and a digest chosen by the same party making the claim records nothing — it is
 * false-pass register #1 with an extra column, and the column makes it look checked. `claim.js`
 * already settled this shape one level up: `claimComplete` takes a requirement and a time, never
 * a hash. This is the same rule for the row-level mark, and the reason `binding_hash` came off
 * `create_coverage` and `update_coverage` when `do` first needed to write a verification.
 *
 * **Two texts, not three.** FR21 names "the requirement fragment or the story criterion", and the
 * fragment is `coverage.spec_fragment` — a stored verbatim slice — rather than `requirement.text`.
 * The requirement-edit trigger clears the mark as well, which is wider than what is hashed here
 * and deliberately so: a fragment is a slice of a text, and a text that has been rewritten no
 * longer vouches for the slice even when the slice's own bytes are unchanged.
 */

import { createHash } from 'node:crypto';

/**
 * The criterion text a binding is half made of, by id.
 *
 * Read rather than passed, because the caller writing a verification holds the coverage row and
 * has no reason to be holding the criterion's current text — and if it did hold a stale copy, the
 * hash would attest to text nobody is looking at.
 */
const CRITERION = 'SELECT text FROM story_criterion WHERE id = ?';

const BOUND = `
  SELECT coverage.spec_fragment, coverage.story_criterion_id, coverage.binding_hash
    FROM coverage
   WHERE coverage.id = ?
`;

/**
 * A hash over the two texts a coverage row binds together.
 *
 * The separator is a character no text can contain, so two different pairs cannot hash the same
 * by their concatenation running together — the reason `claimHash` uses the same one.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} binding
 * @param {string} binding.spec_fragment
 * @param {string} binding.story_criterion_id
 * @returns {string}
 * @throws {Error} If the criterion is not there — a hash over a missing half is a hash over `''`,
 *   which is a real-looking digest for a binding that does not exist.
 */
export function bindingHash(db, { spec_fragment: fragment, story_criterion_id: criterionId }) {
  const criterion = db.prepare(CRITERION).get(criterionId);

  if (!criterion) throw new Error(`no story_criterion ${criterionId} to bind against`);

  return createHash('sha256')
    .update(`${fragment}\\u0000${criterion.text}\\u0000`)
    .digest('hex');
}

/**
 * Whether a coverage row's stored hash still describes the texts it is bound to.
 *
 * The mirror of `claimState`'s `current`, and here for the same reason: the triggers make a stale
 * hash unreachable in normal use, so this is what would notice if a migration recreating the table
 * dropped one. `verified` and `current` are separate answers because an unverified row is not a
 * stale one.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} coverageId
 * @returns {{verified: boolean, current: boolean}}
 */
export function bindingState(db, coverageId) {
  const row = db.prepare(BOUND).get(coverageId);

  if (!row) throw new Error(`no coverage ${coverageId}`);

  return {
    verified: row.binding_hash !== null,
    current: row.binding_hash === bindingHash(db, row),
  };
}

/**
 * Whether a fragment occurs in the requirement it claims to quote, and where it does occur instead.
 *
 * **The same test the integrity register's entry 9 runs, moved to the moment the row is written.**
 * The register keeps its copy and needs it: a restore replays rows without passing through any
 * tool, so a dump can still bring in a binding that quotes nothing. What the write path adds is
 * that a fragment nobody can find stops being a thing you discover later — a mistyped or
 * paraphrased quote is a binding that looks sound in every roll-up until somebody runs the check.
 *
 * **`instr` in SQL and `includes` here are the same predicate**, and the register's is the one this
 * was read from. Written in JavaScript because the refusal wants the sibling as well as the verdict,
 * and one query answering both beats two that could disagree about which requirements exist.
 *
 * **A missing requirement is not this check's business.** It returns `found` for a requirement that
 * is not there, so the foreign key produces its own refusal rather than this one reporting that a
 * fragment was not found in text that does not exist — which would name the wrong fault and send
 * the caller looking for a typo in their quote.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} binding
 * @param {string} binding.requirement_id The requirement the row claims to quote.
 * @param {string} binding.spec_fragment The verbatim slice.
 * @returns {{found: boolean, label: string|null, sibling: {id: string, label: string}|null}}
 *   `found` is the verdict; `label` names the requirement asked about, for a refusal that can say
 *   which one it looked in; `sibling` is the requirement in the same spec whose text does contain
 *   the fragment, or `null` where none does.
 */
export function fragmentPlacement(db, { requirement_id: requirementId, spec_fragment: fragment }) {
  const requirement = db
    .prepare('SELECT id, label, spec_id, text FROM requirement WHERE id = ?')
    .get(requirementId);

  if (!requirement) return { found: true, label: null, sibling: null };
  if (requirement.text.includes(fragment)) {
    return { found: true, label: requirement.label, sibling: null };
  }

  // **Searched within the spec and not across the database.** A fragment turning up under some
  // other project's requirement is a coincidence of wording, and naming it would send the caller
  // to a document that has nothing to do with theirs. `instr` rather than a JavaScript scan so the
  // search stays one statement whatever the spec holds.
  const sibling = db
    .prepare(`SELECT id, label FROM requirement
               WHERE spec_id = ? AND id <> ? AND instr(text, ?) > 0
               ORDER BY position LIMIT 1`)
    .get(requirement.spec_id, requirement.id, fragment);

  return { found: false, label: requirement.label, sibling: sibling ?? null };
}
