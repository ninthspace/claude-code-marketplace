/**
 * FR5 — what the coverage rows say, for one spec, in one call.
 *
 * Two skills compute this today and both compute it in prose. `/dpm:epics` Step 4 reads every
 * requirement and calls `list_coverage` on each; `/dpm:do` Step 8 does the same at the other end of
 * the work. That is a per-requirement page read driven from a skill, written out twice in English,
 * and the two can disagree without anything noticing — which is the ordinary way a rule kept in two
 * paragraphs stops being one rule.
 *
 * **The counts block exists so a skill quotes a number rather than deriving one**, and that makes
 * its shape a contract rather than an implementation detail: a renamed field breaks a consuming
 * skill silently, because a skill quoting a count that is no longer there renders an absence, and
 * an absence reads as a section that was not needed.
 *
 * **Every count here is the length of the array it summarises, taken in the same pass.** Nothing is
 * counted twice by two routes. The miscount FR5's third criterion cites is a run that reported
 * twelve of twelve over thirteen rows — two computations of one number, agreeing until they did
 * not — and the cheapest way to make that unreachable is to leave only one computation.
 *
 * **Nothing is per requirement.** `claimState` in `claim.js` answers the same question for a single
 * requirement and takes two statements to do it; called once per row it would satisfy every
 * criterion about the answer and fail the one about the cost, invisibly, in any test whose fixture
 * holds two requirements. So the standings come from grouped queries whose statement count does not
 * move with the corpus, and `claimState` is left where it is — Story 3 needs its `current` half,
 * which is a different question about a different hash.
 */

/**
 * Each requirement of a spec, with what its coverage rows say about it.
 *
 * **Left join, because a requirement with no bindings is the interesting one.** An inner join
 * answers about the requirements that are already bound, which is the population that needs no
 * report — and it would report a spec with nothing bound as a spec with nothing wrong.
 *
 * `retired_at IS NULL` on the join, not in a `WHERE`: a withdrawn binding is readable and does not
 * count, and moving the clause into `WHERE` would drop the requirement from the report entirely the
 * moment its last live binding was retired, which is the opposite of what a reader needs to see.
 */
const STANDINGS = `
  SELECT r.id,
         r.label,
         r.moscow,
         r.class,
         r.exclusion,
         r.coverage_claimed_at IS NOT NULL                     AS claimed,
         EXISTS (SELECT 1 FROM acceptance_criterion ac
                  WHERE ac.requirement_id = r.id)              AS has_criterion,
         count(c.id)                                           AS bound,
         count(CASE WHEN c.verified_at IS NOT NULL THEN 1 END) AS verified
    FROM requirement r
    LEFT JOIN coverage c
      ON c.requirement_id = r.id AND c.retired_at IS NULL
   WHERE r.spec_id = ?
   GROUP BY r.id
   ORDER BY r.position`;

/**
 * Every live story criterion under a spec, with the three facts the lists are built from.
 *
 * One query rather than three, because the three lists are three readings of one population and a
 * criterion has to appear in the right ones — a criterion can be untagged *and* unaccounted for,
 * and three separate queries would each have to re-derive the same reachability join.
 *
 * **A superseded criterion is excluded.** It was overtaken by an amendment rather than delivered or
 * skipped, so it is not outstanding work and reporting it as a gap would put an item on a reader's
 * list that no action can clear.
 *
 * `accounted` is `warrant.js`'s rule read as a set: a live binding **or** a warrant. It is written
 * here as a join rather than imported because that module answers per row for a tool's read path
 * and this one answers for a whole spec — but the rule is the same one, and the test asserts the
 * two agree on the same criterion rather than trusting that they do.
 */
const CRITERIA = `
  SELECT sc.id,
         sc.story_id,
         sc.text,
         s.epic_id,
         EXISTS (SELECT 1 FROM coverage c
                  WHERE c.story_criterion_id = sc.id AND c.retired_at IS NULL)  AS bound,
         sc.warrant_adr_id IS NOT NULL                                          AS warranted,
         EXISTS (SELECT 1 FROM story_criterion_approach a
                  WHERE a.story_criterion_id = sc.id)                           AS tagged,
         EXISTS (SELECT 1 FROM coverage c
                  JOIN requirement r ON r.id = c.requirement_id
                  WHERE c.story_criterion_id = sc.id
                    AND c.retired_at IS NULL
                    AND r.moscow = 'must')                                      AS must_have
    FROM story_criterion sc
    JOIN story s ON s.id = sc.story_id
    JOIN document e ON e.id = s.epic_id AND e.kind = 'epic'
   WHERE e.parent_id = ?
     AND sc.superseded_at IS NULL
   ORDER BY s.position, sc.position`;

/**
 * One epic's bindings, as rows rather than as a count.
 *
 * **Rows, because the roll-up's numbers have to agree with something.** A `count(*)` here would be a
 * second computation of a figure the report also states, and two computations of one number is the
 * defect the counts block was shaped to make unreachable — so the roll-up counts the length of this,
 * exactly as the spec-level block counts the length of its lists.
 *
 * Reached through the criterion rather than through the requirement: a binding belongs to this epic
 * because the criterion it quotes does, and the requirement it points at belongs to the spec and may
 * be shared with any number of other epics. Counting by requirement would credit one epic with
 * another's work.
 */
const EPIC_BINDINGS = `
  SELECT c.id,
         c.verified_at,
         c.requirement_id,
         c.story_criterion_id,
         s.id AS story_id,
         r.label AS requirement_label
    FROM coverage c
    JOIN story_criterion sc ON sc.id = c.story_criterion_id
    JOIN story s ON s.id = sc.story_id
    JOIN requirement r ON r.id = c.requirement_id
   WHERE s.epic_id = ?
     AND c.retired_at IS NULL
   ORDER BY s.number, c.position`;

/** The stories an epic holds, in the order a reader meets them. */
const EPIC_STORIES = 'SELECT id, number, title, status FROM story WHERE epic_id = ? ORDER BY number';

/** What a reader can act on. A criterion has no title, so the text is what names it. */
const named = (row) => ({ id: row.id, story_id: row.story_id, text: row.text });

/**
 * Whitespace-normalised text, for the one comparison that is about what a criterion *says*.
 *
 * Two criteria written a week apart differ in their line breaks far more often than in their
 * meaning, so an exact comparison finds almost none of the duplicates it exists to find. Runs of
 * any whitespace collapse to one space and the ends are trimmed; nothing else is touched, because
 * every further normalisation — case, punctuation, stop words — starts merging criteria that are
 * genuinely different and reporting work as duplicated when it is not.
 */
const normalised = (text) => text.replace(/\s+/g, ' ').trim();

/**
 * The three findings that are warnings and never gaps (FR9).
 *
 * **They are warnings because of what they are, not because of where they are rendered.** Each one
 * is a state a project can be in legitimately and for as long as it likes: a claim nobody has got
 * round to making, a requirement whose criteria have not been written yet, two stories that really
 * do have to satisfy the same sentence. None of them is work missing, so none of them may block an
 * epic that would otherwise close — which is why this returns its own structure rather than adding
 * rows to the three lists above. A finding that arrives in `unaccounted` is a gap whatever the
 * prose around it says.
 *
 * **Computed from rows the report has already fetched**, so all three cost nothing beyond what the
 * spec-level report already spends. The alternative — a query per warning — would have put the
 * single-call bound at the mercy of how many warnings the spec later grows.
 */
function warningsFor(standings, criteria) {
  // **Claimable: every binding verified and the claim never made.** `bound > 0` is load-bearing.
  // Without it a requirement nothing binds satisfies "every binding is verified" vacuously, and the
  // report would invite a claim that the fragments account for a requirement no fragment quotes.
  //
  // Whether a claim that *was* made still describes what is bound is a different question, decided
  // by a different hash: `claimHash` is taken over the bound fragments and their criterion ids, so
  // rewording a criterion clears its binding's verification and leaves the claim reading current.
  // That asymmetry is real and this warning is not about it — a stale claim is its own finding and
  // is not one of FR9's three.
  const claimable = standings
    .filter((row) => row.bound > 0 && row.verified === row.bound && row.claimed === 0)
    .map((row) => ({ id: row.id, label: row.label }));

  // **No acceptance criterion at all, and only where the requirement is in scope.** A requirement
  // recorded as deferred or out of scope is supposed to carry nothing.
  //
  // This is the state the criterion calls out as one no gap can ever show, and the reason is
  // structural rather than incidental: a gap is computed by asking which criteria are unaccounted
  // for, and a requirement with no criteria contributes nothing to that population. It is invisible
  // to the check by construction, however carefully the check is written, which is why it needs a
  // detection of its own rather than a widened rule.
  const noCriterion = standings
    .filter((row) => row.exclusion === null && row.has_criterion === 0)
    .map((row) => ({ id: row.id, label: row.label }));

  // **One text, live, under two different stories.** Grouped on the normalised text and reported
  // only where the group spans more than one story: the same sentence twice under one story is a
  // position collision the `UNIQUE` constraint already has an opinion about, and repeating it here
  // would report a different problem under this one's name.
  const byText = new Map();

  for (const row of criteria) {
    const key = normalised(row.text);

    if (!byText.has(key)) byText.set(key, []);

    byText.get(key).push(row);
  }

  const duplicated = [...byText.entries()]
    .filter(([, rows]) => new Set(rows.map((row) => row.story_id)).size > 1)
    .map(([text, rows]) => ({ text, criteria: rows.map(named) }));

  return {
    claimable,
    no_criterion: noCriterion,
    duplicated,
    counts: {
      claimable: claimable.length,
      no_criterion: noCriterion.length,
      duplicated: duplicated.length,
    },
  };
}

/**
 * The roll-up for one epic, or `null` when none was named.
 *
 * **Its own branch rather than a filter on the spec-level figures**, because the two answer about
 * different populations: a spec's bindings are every binding under it, and an epic's are the ones
 * its own criteria carry. Deriving the second by narrowing the first would be right only while an
 * epic is the only thing binding its requirements.
 */
function epicRollUp(db, epicId) {
  if (epicId === undefined || epicId === null) return null;

  const stories = db.prepare(EPIC_STORIES).all(epicId);
  const bindings = db.prepare(EPIC_BINDINGS).all(epicId);
  const verified = bindings.filter((row) => row.verified_at !== null);

  return {
    epic_id: epicId,

    // The query names the columns, so the rows are already the shape the response wants. A second
    // projection here would be the same list of field names written twice, and the copy that went
    // stale would be the one nothing reads.
    stories,

    // **The rows, not only their count** (FR10). A run closing an epic needs to see *which*
    // bindings are still unverified, and it needs them named by something it can check — the
    // requirement's label rather than an id it would have to have kept from an earlier call. The
    // label is joined here rather than derived afterwards because this query already reaches the
    // requirement; `src/coverage/label.js` does the same job on the read tools, where there is no
    // join to ride on.
    bindings,
    counts: {
      stories: stories.length,
      bindings: bindings.length,
      verified_bindings: verified.length,
    },
  };
}

/**
 * The report for one spec.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} scope
 * @param {string} scope.specId The spec every requirement and every epic below is read from.
 * @param {string} [scope.epicId] One epic under it, which adds a roll-up and changes nothing else.
 *   Optional because the two questions are asked at different moments — a breakdown asks about the
 *   spec, a run finishing an epic asks about both — and a scope nobody supplied should not silently
 *   narrow the answer.
 * @returns {{spec_id: string, requirements: object[], unaccounted: object[], untagged: object[],
 *   must_have: object[], counts: object, epic: object|null}}
 */
export function coverageReport(db, { specId, epicId }) {
  const standings = db.prepare(STANDINGS).all(specId);
  const requirements = standings.map((row) => ({
    id: row.id,
    label: row.label,
    moscow: row.moscow,
    class: row.class,
    exclusion: row.exclusion,
    bound: row.bound,
    verified: row.verified,
    claimed: row.claimed === 1,
    standing: standingOf(row),
  }));

  const criteria = db.prepare(CRITERIA).all(specId);

  const unaccounted = criteria.filter((row) => row.bound === 0 && row.warranted === 0).map(named);
  const untagged = criteria.filter((row) => row.tagged === 0).map(named);
  const mustHave = criteria.filter((row) => row.must_have === 1).map(named);

  return {
    spec_id: specId,

    // **Present as `null` rather than absent when no epic was named.** A field that appears only
    // sometimes makes a consuming skill test for its existence before reading it, and the skill that
    // forgets renders an absence — which reads as a roll-up of nothing rather than as a roll-up
    // nobody asked for.
    epic: epicRollUp(db, epicId),
    requirements,
    unaccounted,
    untagged,
    must_have: mustHave,
    warnings: warningsFor(standings, criteria),

    // Every number below is the length of something returned above it. See the module note: two
    // routes to one count is the defect this shape exists to make unreachable.
    counts: {
      requirements: requirements.length,
      bound: requirements.filter((row) => row.bound > 0).length,
      unbound: requirements.filter((row) => row.bound === 0).length,
      bindings: requirements.reduce((total, row) => total + row.bound, 0),
      verified_bindings: requirements.reduce((total, row) => total + row.verified, 0),
      criteria: criteria.length,
      unaccounted: unaccounted.length,
      untagged: untagged.length,
      must_have: mustHave.length,
    },
  };
}

/**
 * One word for where a requirement has got to.
 *
 * **Three states and not two**, because *nothing is bound to this* and *everything bound to this is
 * still unverified* want different things done about them: the first is a breakdown's problem and
 * the second is a run's. Collapsing them into "not verified" is what makes a gap list read as a
 * progress bar.
 *
 * The claim is deliberately not part of it. Whether someone has claimed the fragments account for
 * the requirement whole is a judgement a person made, and folding it into a word computed from row
 * counts would report that judgement as though the rows had produced it.
 */
function standingOf({ bound, verified }) {
  if (bound === 0) return 'unbound';

  return verified === bound ? 'verified' : 'partial';
}
