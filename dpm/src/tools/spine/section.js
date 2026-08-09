/**
 * `document_section` — the home for prose that is not decomposed into anything else.
 *
 * Every kind of document has narrative sections, which is why `document_id` here is one of the
 * references the Data Model names as legitimately kind-agnostic. Until now the table had no create
 * tool, which under FR3 — the tool surface is the only write path — meant the corpus's prose was
 * unreachable: Story 3 indexes this table and Story 6 asks for a search hit from it, and neither
 * could have had a row to find.
 *
 * **`body` is declared as a body column, and this is the first tool where that costs something.**
 * FR13 withholds it unless `include_body` asks. A section body is the largest single value in the
 * schema, and a list of a spec's sections that returned every one of them in full is the unbounded
 * result the requirement exists to prevent — the heading and the position are what a caller needs
 * to decide which one to open.
 */

import { entityTools } from '../entity.js';

/**
 * @param {object} context
 * @returns {object[]}
 */
export function sectionTools(context) {
  return entityTools(context, {
    table: 'document_section',
    noun: 'one prose section of a document',
    fields: {
      document_id: { type: 'string', minLength: 1, description: 'any kind of document' },
      heading: { type: 'string', minLength: 1 },
      body: { type: 'string', minLength: 1, description: 'the section\'s prose, verbatim' },
      position: { type: 'integer', minimum: 0 },
    },
    required: ['document_id', 'heading', 'body', 'position'],
    mutable: ['heading', 'body', 'position'],
    body: ['body'],
  });
}
