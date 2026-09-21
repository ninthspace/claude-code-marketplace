/**
 * The sentence a server says when the database it just opened is behind the dump beside it.
 *
 * `verdict()` has been able to answer this since AD13, and until now only the pre-commit guard
 * asked. That left the detection on the one surface a person reaches deliberately, at the end of a
 * piece of work — so a session could open a database three weeks behind the repository, answer every
 * read from it, and finish without anything having compared the two. The reads are what make it
 * dangerous: they succeed, they are internally consistent, and there is no error to catch.
 *
 * **A sentence rather than a refusal.** Serving is what the server is for, and a database that is
 * behind is still the user's database — a launch that refused would break a pull that happened to
 * land mid-session. The requirement is that the state stops being *silent*, not that it stops being
 * servable.
 *
 * **Nothing here reads a file or opens a database**, the same separation `skew.js` keeps for the
 * version-skew prose: given a verdict it returns prose, so the states are assertable without
 * constructing a repository in each of them. Which verdicts are worth saying out loud is decided
 * here too, because that is a property of the verdict rather than of the caller.
 */

import { IMPORT_COMMAND, MERGE_COMMAND, PUBLISH_COMMAND } from '../guard/index.js';
import { VERDICT } from './verdict.js';

/**
 * Whether a verdict means the database may be behind what the repository holds.
 *
 * Three of the six are silent, and each for its own reason rather than by a shared rule:
 *
 * - `clean` — the two artefacts agree and the marker records it. The ordinary state.
 * - `adopt` — they agree and the marker is stale. The guard writes the marker when it next runs;
 *   there is nothing for a reader to do, and every database that predates AD13 reaches this once.
 * - `database-moved` — local work not yet published. That is what the middle of a session looks
 *   like, and the pre-commit guard already stands between it and a commit.
 *
 * The other three all mean the same thing to the person at the terminal: what you are reading may
 * not be what the repository holds.
 *
 * @param {string} state One of {@link VERDICT}.
 * @returns {boolean}
 */
export function behind(state) {
  return state === VERDICT.dumpMoved
    || state === VERDICT.bothMoved
    || state === VERDICT.unknown;
}

/**
 * What to say, chosen by the verdict.
 *
 * **The remedy is per-verdict and the commands are imported rather than spelled**, for the reason
 * the guard gives at length where they are defined: a diagnostic naming a command is useful only
 * while the command is where it says it is, and the day a file moves a hard-coded path becomes a
 * sentence that looks like help and sends the reader nowhere.
 *
 * **`unknown` names no single command, and that is the answer rather than a gap.** With no sync
 * point, nothing in either artefact says which of them moved, and both repairs discard whichever
 * side did. Naming one would be a guess wearing a diagnosis's clothes — the failure this check
 * exists to remove, arriving one state further along.
 *
 * @param {string} state One of {@link VERDICT}.
 * @param {string} dump The dump's path, as the caller found it, so the sentence names the file the
 *   reader can actually go and look at rather than a constant that is right for the default layout.
 * @returns {string|null} The line, or `null` when this verdict has nothing to say.
 */
export function syncNotice(state, dump) {
  if (state === VERDICT.dumpMoved) {
    return `${dump} has moved and this database has not, which is what a pull leaves behind — `
      + 'so everything read through this server is behind what the repository holds. Rebuild it '
      + `with:  node ${IMPORT_COMMAND}`;
  }

  if (state === VERDICT.bothMoved) {
    return `${dump} and this database have both changed since they last agreed, so this server `
      + 'may be answering from a database that is behind the repository. Neither can be '
      + `regenerated from the other without loss. Reconcile them with:  node ${MERGE_COMMAND}`;
  }

  if (state === VERDICT.unknown) {
    return `${dump} and this database disagree, and no sync point records which of them moved, `
      + 'so this server may be answering from a database that is behind the repository. Both '
      + `fixes discard one side, so the choice is yours:  node ${IMPORT_COMMAND} takes the dump, `
      + `node ${PUBLISH_COMMAND} takes the database.`;
  }

  return null;
}
