PRAGMA foreign_keys=OFF;
CREATE TABLE schema_version (
  version     INTEGER NOT NULL,
  applied_at  TEXT    NOT NULL,
  UNIQUE (version)
);
CREATE TABLE document_kind (
  kind        TEXT NOT NULL PRIMARY KEY, -- 'spec','epic','retro','review','runbook',…
  dir         TEXT,                      -- projection dir under docs/; NULL = this kind
                                         -- produces no file and renders inside its parent
  numbering   TEXT NOT NULL DEFAULT 'root'
                CHECK (numbering IN ('root','child','none')),
  UNIQUE (kind, numbering)               -- parent key for document's composite FK
);
CREATE TABLE document_kind_parent (
  kind        TEXT NOT NULL REFERENCES document_kind(kind),
  parent_kind TEXT NOT NULL REFERENCES document_kind(kind),
  PRIMARY KEY (kind, parent_kind)
);
CREATE TABLE document_section (
  id           TEXT NOT NULL PRIMARY KEY,
  document_id  TEXT NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  heading      TEXT    NOT NULL,
  body         TEXT    NOT NULL,
  position     INTEGER NOT NULL, superseded_at TEXT,
  UNIQUE (document_id, position)
);
CREATE TABLE library_document (
  document_id   TEXT NOT NULL PRIMARY KEY,
  document_kind TEXT NOT NULL DEFAULT 'library' CHECK (document_kind = 'library'),
  doc_type      TEXT NOT NULL, source TEXT,     -- 'architecture','coding-standards','domain',…
  FOREIGN KEY (document_id, document_kind) REFERENCES document(id, kind) ON DELETE CASCADE
);
CREATE TABLE library_scope (
  document_id  TEXT NOT NULL REFERENCES library_document(document_id) ON DELETE CASCADE,
  scope        TEXT    NOT NULL,  -- a skill name, or 'all'
  PRIMARY KEY (document_id, scope)
);
CREATE TABLE adr (
  document_id     TEXT NOT NULL PRIMARY KEY,
  document_kind   TEXT NOT NULL DEFAULT 'adr' CHECK (document_kind = 'adr'),
  decision_status TEXT NOT NULL DEFAULT 'proposed'
                    CHECK (decision_status IN
                      ('proposed','accepted','rejected','superseded','deprecated')),
  decision        TEXT NOT NULL,
  FOREIGN KEY (document_id, document_kind) REFERENCES document(id, kind) ON DELETE CASCADE
);
CREATE TABLE adr_option (
  id           TEXT NOT NULL PRIMARY KEY,
  adr_id       TEXT NOT NULL REFERENCES adr(document_id) ON DELETE CASCADE,
  name         TEXT    NOT NULL,
  chosen       INTEGER NOT NULL DEFAULT 0,
  rationale    TEXT,
  position     INTEGER NOT NULL,
  UNIQUE (adr_id, position)
);
CREATE TABLE adr_option_tradeoff (
  option_id    TEXT NOT NULL REFERENCES adr_option(id) ON DELETE CASCADE,
  axis         TEXT    NOT NULL,   -- 'cost','complexity','reversibility',…
  assessment   TEXT    NOT NULL,
  PRIMARY KEY (option_id, axis)
);
CREATE TABLE review (
  document_id    TEXT NOT NULL PRIMARY KEY,
  document_kind  TEXT NOT NULL DEFAULT 'review' CHECK (document_kind = 'review'),
  scope          TEXT NOT NULL DEFAULT 'whole'
                   CHECK (scope IN ('whole','story')),
  scope_story_id TEXT REFERENCES story(id) ON DELETE CASCADE,
  CHECK ((scope = 'story') = (scope_story_id IS NOT NULL)),
  FOREIGN KEY (document_id, document_kind) REFERENCES document(id, kind) ON DELETE CASCADE
);
CREATE TABLE quick (
  document_id   TEXT NOT NULL PRIMARY KEY,
  document_kind TEXT NOT NULL DEFAULT 'quick' CHECK (document_kind = 'quick'),
  closed_at     TEXT,
  FOREIGN KEY (document_id, document_kind) REFERENCES document(id, kind) ON DELETE CASCADE
);
CREATE TABLE quick_criterion (
  id           TEXT NOT NULL PRIMARY KEY,
  quick_id     TEXT NOT NULL REFERENCES quick(document_id) ON DELETE CASCADE,
  text         TEXT    NOT NULL,
  met          INTEGER,           -- NULL until closed
  note         TEXT,
  position     INTEGER NOT NULL,
  UNIQUE (quick_id, position)
);
CREATE TABLE requirement (
  id            TEXT NOT NULL PRIMARY KEY,
  spec_id       TEXT    NOT NULL,
  spec_kind     TEXT    NOT NULL DEFAULT 'spec' CHECK (spec_kind = 'spec'),
  label         TEXT    NOT NULL,                  -- display only: 'FR1','NFR3','ENVX2'
  class         TEXT    NOT NULL CHECK (class IN (
                  'functional','non_functional',
                  'environmental_requirement','environmental_restriction')),
  moscow        TEXT    CHECK (moscow IN ('must','should','could','wont')),
  exclusion     TEXT    CHECK (exclusion IN ('deferred','out_of_scope')),
  parent_id     TEXT REFERENCES requirement(id),  -- FR1a's parent is FR1
  text          TEXT    NOT NULL,
  position      INTEGER NOT NULL,
  -- FR26. NULL = nobody has claimed the bindings account for this requirement.
  -- Set together, cleared together, by the Story 7 triggers.
  coverage_claimed_at TEXT,
  coverage_claim_hash TEXT,   -- hash of the bound fragment set at claim time
  FOREIGN KEY (spec_id, spec_kind) REFERENCES document(id, kind) ON DELETE CASCADE,
  UNIQUE (spec_id, label),
  CHECK ((coverage_claimed_at IS NULL) = (coverage_claim_hash IS NULL))
);
CREATE TABLE acceptance_criterion (
  id              TEXT NOT NULL PRIMARY KEY,
  requirement_id  TEXT NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
  text            TEXT    NOT NULL,
  polarity        TEXT    NOT NULL DEFAULT 'must'
                    CHECK (polarity IN ('must','must_not','control')),
  position        INTEGER NOT NULL,
  UNIQUE (requirement_id, position)
);
CREATE TABLE criterion_approach (
  criterion_id  TEXT NOT NULL REFERENCES acceptance_criterion(id) ON DELETE CASCADE,
  tag           TEXT    NOT NULL REFERENCES test_approach(tag),
  PRIMARY KEY (criterion_id, tag)
);
CREATE TABLE story_criterion (
  id          TEXT NOT NULL PRIMARY KEY,
  story_id    TEXT NOT NULL REFERENCES story(id) ON DELETE CASCADE,
  text        TEXT    NOT NULL,
  polarity    TEXT    NOT NULL DEFAULT 'must'
                CHECK (polarity IN ('must','must_not','control')),
  position    INTEGER NOT NULL,
  UNIQUE (story_id, position)
);
CREATE TABLE story_criterion_approach (
  story_criterion_id TEXT NOT NULL REFERENCES story_criterion(id) ON DELETE CASCADE,
  tag                TEXT    NOT NULL REFERENCES test_approach(tag),
  PRIMARY KEY (story_criterion_id, tag)
);
CREATE TABLE coverage (
  id                 TEXT NOT NULL PRIMARY KEY,
  requirement_id     TEXT NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
  spec_fragment      TEXT    NOT NULL,
  story_criterion_id TEXT NOT NULL REFERENCES story_criterion(id) ON DELETE CASCADE,
  position           INTEGER NOT NULL,   -- display order only; NOT part of identity
  verified_at        TEXT,            -- NULL = unverified; the ✓ column
  binding_hash       TEXT,            -- hash of (spec_fragment ‖ criterion text) at verification
  UNIQUE (requirement_id, spec_fragment, story_criterion_id),
  CHECK ((verified_at IS NULL) = (binding_hash IS NULL))
);
CREATE TABLE coverage_story (
  coverage_id  TEXT NOT NULL REFERENCES coverage(id) ON DELETE CASCADE,
  story_id     TEXT NOT NULL REFERENCES story(id)    ON DELETE CASCADE,
  PRIMARY KEY (coverage_id, story_id)
);
CREATE TABLE milestone (
  id          TEXT    NOT NULL PRIMARY KEY,
  spec_id     TEXT    NOT NULL,
  spec_kind   TEXT    NOT NULL DEFAULT 'spec' CHECK (spec_kind = 'spec'),
  label       TEXT    NOT NULL,      -- 'M1'
  title       TEXT    NOT NULL,      -- 'Substrate'
  summary     TEXT,
  position    INTEGER NOT NULL,
  FOREIGN KEY (spec_id, spec_kind) REFERENCES document(id, kind) ON DELETE CASCADE,
  UNIQUE (spec_id, label),
  UNIQUE (spec_id, position)
);
CREATE TABLE document_milestone (
  document_id  TEXT NOT NULL REFERENCES document(id)  ON DELETE CASCADE,
  milestone_id TEXT NOT NULL REFERENCES milestone(id) ON DELETE CASCADE,
  PRIMARY KEY (document_id, milestone_id)
);
CREATE TABLE finding (
  id              TEXT NOT NULL PRIMARY KEY,
  review_id       TEXT NOT NULL,
  review_kind     TEXT NOT NULL DEFAULT 'review' CHECK (review_kind = 'review'),
  position        INTEGER NOT NULL,   -- projection order; without it a review's findings render unordered
  agent           TEXT REFERENCES agent(name),   -- nullable: not every finding is attributed
  category_id     TEXT NOT NULL,
  category_domain TEXT NOT NULL DEFAULT 'finding'
                    CHECK (category_domain = 'finding'),
  severity_id     TEXT NOT NULL,
  severity_domain TEXT NOT NULL DEFAULT 'severity'
                    CHECK (severity_domain = 'severity'),
  summary         TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open','accepted','rejected','remediated')),
  -- Closes a loop CPM leaves open: which findings were actually acted on becomes a query.
  remediation_task_id TEXT REFERENCES task(id),
  FOREIGN KEY (review_id, review_kind)      REFERENCES document(id, kind) ON DELETE CASCADE,
  FOREIGN KEY (category_id, category_domain) REFERENCES taxonomy(id, domain),
  FOREIGN KEY (severity_id, severity_domain) REFERENCES taxonomy(id, domain),
  UNIQUE (review_id, position)
);
CREATE TABLE observation_category (
  observation_id   TEXT NOT NULL REFERENCES observation(id) ON DELETE CASCADE,
  taxonomy_id      TEXT NOT NULL,
  taxonomy_domain  TEXT NOT NULL DEFAULT 'observation'
                     CHECK (taxonomy_domain = 'observation'),
  PRIMARY KEY (observation_id, taxonomy_id),
  FOREIGN KEY (taxonomy_id, taxonomy_domain) REFERENCES taxonomy(id, domain)
);
CREATE TABLE audit_finding (
  id               TEXT NOT NULL PRIMARY KEY,
  audit_id         TEXT NOT NULL,
  audit_kind       TEXT NOT NULL DEFAULT 'audit' CHECK (audit_kind = 'audit'),
  position         INTEGER NOT NULL,   -- projection order, as on `finding`
  dimension_id     TEXT NOT NULL,
  dimension_domain TEXT NOT NULL DEFAULT 'audit_dimension'
                     CHECK (dimension_domain = 'audit_dimension'),
  file             TEXT NOT NULL,
  line             INTEGER,
  symbol           TEXT,
  severity_id      TEXT NOT NULL,
  severity_domain  TEXT NOT NULL DEFAULT 'severity'
                     CHECK (severity_domain = 'severity'), summary TEXT NOT NULL DEFAULT '', recommendation TEXT,
  FOREIGN KEY (audit_id, audit_kind)           REFERENCES document(id, kind) ON DELETE CASCADE,
  FOREIGN KEY (dimension_id, dimension_domain) REFERENCES taxonomy(id, domain),
  FOREIGN KEY (severity_id,  severity_domain)  REFERENCES taxonomy(id, domain),
  UNIQUE (audit_id, position)
);
CREATE TABLE retro_application (
  id            TEXT NOT NULL PRIMARY KEY,
  retro_id      TEXT NOT NULL,
  retro_kind    TEXT NOT NULL DEFAULT 'retro' CHECK (retro_kind = 'retro'),
  -- `applied_to_id` is deliberately NOT kind-pinned: a retro's lesson may be
  -- applied to a document of any kind, so there is no single legal target kind.
  applied_to_id TEXT NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  theme         TEXT NOT NULL DEFAULT '',
  disposition   TEXT NOT NULL
                  CHECK (disposition IN ('applied','not_applicable','deferred')),
  note          TEXT NOT NULL DEFAULT '',
  FOREIGN KEY (retro_id, retro_kind) REFERENCES document(id, kind) ON DELETE CASCADE,
  UNIQUE (retro_id, applied_to_id, theme, note)
);
CREATE TABLE artifact (
  id            TEXT NOT NULL PRIMARY KEY,
  url           TEXT NOT NULL UNIQUE,
  title         TEXT NOT NULL,
  description   TEXT,
  published_at  TEXT NOT NULL
, retired_at TEXT, retired_reason TEXT
  CHECK ((retired_at IS NULL) = (retired_reason IS NULL)));
CREATE TABLE artifact_document (
  artifact_id   TEXT NOT NULL REFERENCES artifact(id)  ON DELETE CASCADE,
  document_id   TEXT NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  PRIMARY KEY (artifact_id, document_id)
);
CREATE TABLE session (
  id             TEXT NOT NULL PRIMARY KEY,       -- CPM_SESSION_ID
  skill          TEXT,
  phase          TEXT,
  state          TEXT,                   -- JSON blob, skill-defined
  superseded_by  TEXT REFERENCES session(id),
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL
);
CREATE TABLE taxonomy (
  id          TEXT NOT NULL PRIMARY KEY,
  domain      TEXT    NOT NULL,   -- 'observation','finding','audit_dimension','severity'
  name        TEXT    NOT NULL,   -- canonical form, e.g. 'Patterns Worth Reusing'
  singular    TEXT,               -- per-item display form, e.g. 'Pattern worth reusing'
  position    INTEGER NOT NULL,
  retired_at  TEXT,
  UNIQUE (domain, name),
  -- The parent key every domain-scoped reference resolves against. Without it a reference
  -- can only join to `id`, and a severity fits a category slot — which relocates the drift
  -- rather than removing it.
  UNIQUE (id, domain)
);
CREATE TABLE agent (
  name                TEXT NOT NULL PRIMARY KEY, -- 'pm', 'architect' — the id skills reference
  display_name        TEXT    NOT NULL,          -- 'Jordan'
  icon                TEXT    NOT NULL,          -- single emoji, the party-mode prefix
  role                TEXT    NOT NULL,          -- 'Product Manager'
  personality         TEXT    NOT NULL,
  communication_style TEXT    NOT NULL,
  position            INTEGER NOT NULL,
  retired_at          TEXT,
  UNIQUE (display_name)                          -- two Jordans make rendered output ambiguous
);
CREATE TABLE test_approach (
  tag         TEXT NOT NULL PRIMARY KEY,  -- unit, integration, feature, manual, target, tdd
  kind        TEXT NOT NULL CHECK (kind IN ('level','mode')),
  position    INTEGER NOT NULL,
  retired_at  TEXT
);
CREATE TABLE number_sequence (
  kind        TEXT    NOT NULL REFERENCES document_kind(kind),
  -- Deliberately not kind-pinned, and named as such in the Data Model's enumeration: the
  -- parent a child-numbered kind counts within varies by kind — an epic counts under a spec,
  -- an ADR under a spec, a brief or a discussion.
  parent_id   TEXT REFERENCES document(id) ON DELETE CASCADE,
  next_value  INTEGER NOT NULL DEFAULT 1
);
CREATE UNIQUE INDEX number_sequence_root
  ON number_sequence (kind)            WHERE parent_id IS NULL;
CREATE UNIQUE INDEX number_sequence_child
  ON number_sequence (kind, parent_id) WHERE parent_id IS NOT NULL;
CREATE TABLE dependency_kind (
  kind         TEXT NOT NULL PRIMARY KEY,  -- 'blocks','builds_on','constrains','supersedes'
  gates_work   INTEGER NOT NULL DEFAULT 0,
  position     INTEGER NOT NULL,
  retired_at   TEXT                        -- FR24 applies here too
);
CREATE TABLE dependency (
  id                  TEXT NOT NULL PRIMARY KEY,
  kind                TEXT NOT NULL REFERENCES dependency_kind(kind),
  -- Both ends are deliberately not kind-pinned, and are named as such in the Data Model's
  -- enumeration: which kinds are legal at each end varies by edge kind, which is register
  -- entry #6 rather than a constraint.
  source_document_id  TEXT REFERENCES document(id) ON DELETE CASCADE,
  source_story_id     TEXT REFERENCES story(id)    ON DELETE CASCADE,
  target_document_id  TEXT REFERENCES document(id) ON DELETE CASCADE,
  target_story_id     TEXT REFERENCES story(id)    ON DELETE CASCADE,
  CHECK ((source_document_id IS NULL) <> (source_story_id IS NULL)),
  CHECK ((target_document_id IS NULL) <> (target_story_id IS NULL)),
  CHECK (source_document_id IS NULL OR target_document_id IS NULL
         OR source_document_id <> target_document_id),
  CHECK (source_story_id IS NULL OR target_story_id IS NULL
         OR source_story_id <> target_story_id)
);
CREATE UNIQUE INDEX dependency_edge ON dependency (
  kind,
  coalesce(source_document_id, -1), coalesce(source_story_id, -1),
  coalesce(target_document_id, -1), coalesce(target_story_id, -1)
);
CREATE TRIGGER coverage_unverify_on_criterion_edit
AFTER UPDATE OF text ON story_criterion
WHEN OLD.text <> NEW.text
BEGIN
  UPDATE coverage SET verified_at = NULL, binding_hash = NULL
   WHERE story_criterion_id = NEW.id;
END;
CREATE TRIGGER coverage_unverify_on_requirement_edit
AFTER UPDATE OF text ON requirement
WHEN OLD.text <> NEW.text
BEGIN
  UPDATE coverage SET verified_at = NULL, binding_hash = NULL
   WHERE requirement_id = NEW.id;
END;
CREATE TRIGGER coverage_unverify_on_fragment_edit
AFTER UPDATE OF spec_fragment ON coverage
WHEN OLD.spec_fragment <> NEW.spec_fragment
BEGIN
  UPDATE coverage SET verified_at = NULL, binding_hash = NULL
   WHERE id = NEW.id;
END;
CREATE TRIGGER requirement_unclaim_on_coverage_insert
AFTER INSERT ON coverage
BEGIN
  UPDATE requirement SET coverage_claimed_at = NULL, coverage_claim_hash = NULL
   WHERE id = NEW.requirement_id;
END;
CREATE TRIGGER requirement_unclaim_on_coverage_delete
AFTER DELETE ON coverage
BEGIN
  UPDATE requirement SET coverage_claimed_at = NULL, coverage_claim_hash = NULL
   WHERE id = OLD.requirement_id;
END;
CREATE TRIGGER requirement_unclaim_on_fragment_edit
AFTER UPDATE OF spec_fragment ON coverage
WHEN OLD.spec_fragment <> NEW.spec_fragment
BEGIN
  UPDATE requirement SET coverage_claimed_at = NULL, coverage_claim_hash = NULL
   WHERE id = NEW.requirement_id;
END;
CREATE TRIGGER requirement_unclaim_on_text_edit
AFTER UPDATE OF text ON requirement
WHEN OLD.text <> NEW.text
BEGIN
  UPDATE requirement SET coverage_claimed_at = NULL, coverage_claim_hash = NULL
   WHERE id = NEW.id;
END;
CREATE VIRTUAL TABLE document_fts USING fts5(heading, body, section_id UNINDEXED);
CREATE TRIGGER document_fts_insert
AFTER INSERT ON document_section
BEGIN
  INSERT INTO document_fts (heading, body, section_id)
  VALUES (NEW.heading, NEW.body, NEW.id);
END;
CREATE TRIGGER document_fts_update
AFTER UPDATE OF heading, body ON document_section
BEGIN
  DELETE FROM document_fts WHERE section_id = OLD.id;
  INSERT INTO document_fts (heading, body, section_id)
  VALUES (NEW.heading, NEW.body, NEW.id);
END;
CREATE TRIGGER document_fts_delete
AFTER DELETE ON document_section
BEGIN
  DELETE FROM document_fts WHERE section_id = OLD.id;
END;
CREATE VIRTUAL TABLE entry_fts USING fts5(entity, text, entity_id UNINDEXED);
CREATE TRIGGER entry_fts_requirement_insert
AFTER INSERT ON requirement
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('requirement', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_requirement_update
AFTER UPDATE OF text ON requirement
BEGIN
  DELETE FROM entry_fts WHERE entity = 'requirement' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('requirement', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_requirement_delete
AFTER DELETE ON requirement
BEGIN
  DELETE FROM entry_fts WHERE entity = 'requirement' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_acceptance_criterion_insert
AFTER INSERT ON acceptance_criterion
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('acceptance_criterion', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_acceptance_criterion_update
AFTER UPDATE OF text ON acceptance_criterion
BEGIN
  DELETE FROM entry_fts WHERE entity = 'acceptance_criterion' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('acceptance_criterion', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_acceptance_criterion_delete
AFTER DELETE ON acceptance_criterion
BEGIN
  DELETE FROM entry_fts WHERE entity = 'acceptance_criterion' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_story_criterion_insert
AFTER INSERT ON story_criterion
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('story_criterion', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_story_criterion_update
AFTER UPDATE OF text ON story_criterion
BEGIN
  DELETE FROM entry_fts WHERE entity = 'story_criterion' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('story_criterion', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_story_criterion_delete
AFTER DELETE ON story_criterion
BEGIN
  DELETE FROM entry_fts WHERE entity = 'story_criterion' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_finding_insert
AFTER INSERT ON finding
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('finding', NEW.summary, NEW.id);
END;
CREATE TRIGGER entry_fts_finding_update
AFTER UPDATE OF summary ON finding
BEGIN
  DELETE FROM entry_fts WHERE entity = 'finding' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('finding', NEW.summary, NEW.id);
END;
CREATE TRIGGER entry_fts_finding_delete
AFTER DELETE ON finding
BEGIN
  DELETE FROM entry_fts WHERE entity = 'finding' AND entity_id = OLD.id;
END;
CREATE TABLE "observation" (
  id              TEXT NOT NULL PRIMARY KEY,
  retro_id        TEXT,
  retro_kind      TEXT CHECK (retro_kind = 'retro'),
  story_id        TEXT REFERENCES story(id)    ON DELETE CASCADE,
  quick_id        TEXT,
  quick_kind      TEXT CHECK (quick_kind = 'quick'),
  position        INTEGER NOT NULL DEFAULT 0,  -- projection order within a retro
  text            TEXT NOT NULL,
  synthesis       TEXT,            -- written when grouped into a retro
  note            TEXT,            -- escape hatch: qualifiers, caveats, scope
  library_doc_id  TEXT,            -- set on promotion
  library_doc_kind TEXT CHECK (library_doc_kind = 'library'),
  retired_at      TEXT,
  retired_reason  TEXT,
  FOREIGN KEY (library_doc_id, library_doc_kind) REFERENCES document(id, kind),
  FOREIGN KEY (retro_id, retro_kind) REFERENCES document(id, kind) ON DELETE CASCADE,
  FOREIGN KEY (quick_id, quick_kind) REFERENCES document(id, kind) ON DELETE CASCADE,
  CHECK ((library_doc_id IS NULL) = (library_doc_kind IS NULL)),
  CHECK ((retro_id IS NULL) = (retro_kind IS NULL)),
  CHECK ((quick_id IS NULL) = (quick_kind IS NULL)),
  CHECK (retro_id IS NOT NULL OR story_id IS NOT NULL OR quick_id IS NOT NULL),
  CHECK ((retired_at IS NULL) = (retired_reason IS NULL))
);
CREATE UNIQUE INDEX observation_retro_position
  ON observation (retro_id, position) WHERE retro_id IS NOT NULL;
CREATE TRIGGER entry_fts_observation_insert
AFTER INSERT ON observation
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('observation', NEW.text || ' ' || coalesce(NEW.synthesis, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_observation_update
AFTER UPDATE OF text, synthesis ON observation
BEGIN
  DELETE FROM entry_fts WHERE entity = 'observation' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('observation', NEW.text || ' ' || coalesce(NEW.synthesis, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_observation_delete
AFTER DELETE ON observation
BEGIN
  DELETE FROM entry_fts WHERE entity = 'observation' AND entity_id = OLD.id;
END;
CREATE TABLE "document" (
  id          TEXT NOT NULL PRIMARY KEY,
  kind        TEXT    NOT NULL,
  numbering   TEXT    NOT NULL,  -- denormalised from document_kind, pinned by FK
  number      INTEGER,           -- root-numbered kinds: spec 47
  sequence    INTEGER,           -- child-numbered kinds: epic 03 within spec 101
  slug        TEXT    NOT NULL,
  title       TEXT    NOT NULL,
  status      TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','complete','superseded','withdrawn')),
  status_note TEXT,             -- the free-text qualifier real epics append to a status
  parent_id   TEXT,             -- epic→spec; adr→spec, brief or discussion;
                                -- retro→epic, spec or quick; review→spec or epic
  parent_kind TEXT,             -- denormalised from the parent, pinned by FK
  archived_at TEXT,             -- orthogonal to status; NULL means live
  commit_sha  TEXT,             -- audit and inspect pin to a commit
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  retro_waived_at     TEXT,     -- from `015-retro-waiver.sql`; both or neither, as its CHECK says
  retro_waived_reason TEXT,
  FOREIGN KEY (kind, numbering)        REFERENCES document_kind(kind, numbering),
  FOREIGN KEY (kind, parent_kind)      REFERENCES document_kind_parent(kind, parent_kind),
  FOREIGN KEY (parent_id, parent_kind) REFERENCES document(id, kind),
  CHECK ((numbering = 'root'  AND number   IS NOT NULL AND sequence IS NULL)
      OR (numbering = 'child' AND sequence IS NOT NULL AND number   IS NULL)
      OR (numbering = 'none'  AND number   IS NULL     AND sequence IS NULL)),
  CHECK ((parent_kind IS NULL) = (parent_id IS NULL)),
  CHECK (numbering <> 'child' OR parent_id IS NOT NULL),
  CHECK ((retro_waived_at IS NULL) = (retro_waived_reason IS NULL))
);
CREATE UNIQUE INDEX document_id_kind      ON document (id, kind);
CREATE UNIQUE INDEX document_root_number
  ON document (kind, number)              WHERE number IS NOT NULL;
CREATE UNIQUE INDEX document_child_number
  ON document (kind, parent_id, sequence)
  WHERE sequence IS NOT NULL AND parent_id IS NOT NULL;
CREATE TABLE "story" (
  id          TEXT NOT NULL PRIMARY KEY,
  epic_id     TEXT    NOT NULL,
  epic_kind   TEXT    NOT NULL DEFAULT 'epic' CHECK (epic_kind = 'epic'),
  number      INTEGER NOT NULL,
  title       TEXT    NOT NULL,
  status      TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','complete','superseded','withdrawn')),
  status_note TEXT,
  position    INTEGER NOT NULL,
  plan        INTEGER NOT NULL DEFAULT 0 CHECK (plan IN (0, 1)),  -- from `014-story-plan.sql`
  FOREIGN KEY (epic_id, epic_kind) REFERENCES document(id, kind) ON DELETE CASCADE,
  UNIQUE (epic_id, number)
);
CREATE TABLE "task" (
  id          TEXT NOT NULL PRIMARY KEY,
  story_id    TEXT NOT NULL REFERENCES story(id) ON DELETE CASCADE,
  number      INTEGER NOT NULL,
  title       TEXT    NOT NULL,
  description TEXT,
  status      TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','complete','superseded','withdrawn')),
  status_note TEXT,
  position    INTEGER NOT NULL,
  UNIQUE (story_id, number)
);
CREATE TABLE document_agent (
  document_id   TEXT NOT NULL,
  document_kind TEXT NOT NULL CHECK (document_kind IN ('review','discussion')),
  agent         TEXT NOT NULL REFERENCES agent(name),
  PRIMARY KEY (document_id, agent),
  FOREIGN KEY (document_id, document_kind) REFERENCES document(id, kind) ON DELETE CASCADE
);
CREATE TRIGGER entry_fts_adr_insert
AFTER INSERT ON adr
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('adr', NEW.decision, NEW.document_id);
END;
CREATE TRIGGER entry_fts_adr_update
AFTER UPDATE OF decision ON adr
BEGIN
  DELETE FROM entry_fts WHERE entity = 'adr' AND entity_id = OLD.document_id;
  INSERT INTO entry_fts (entity, text, entity_id) VALUES ('adr', NEW.decision, NEW.document_id);
END;
CREATE TRIGGER entry_fts_adr_delete
AFTER DELETE ON adr
BEGIN
  DELETE FROM entry_fts WHERE entity = 'adr' AND entity_id = OLD.document_id;
END;
CREATE TRIGGER entry_fts_adr_option_insert
AFTER INSERT ON adr_option
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('adr_option', coalesce(NEW.rationale, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_adr_option_update
AFTER UPDATE OF rationale ON adr_option
BEGIN
  DELETE FROM entry_fts WHERE entity = 'adr_option' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('adr_option', coalesce(NEW.rationale, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_adr_option_delete
AFTER DELETE ON adr_option
BEGIN
  DELETE FROM entry_fts WHERE entity = 'adr_option' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_agent_insert
AFTER INSERT ON agent
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('agent', NEW.personality || ' ' || NEW.communication_style, NEW.name);
END;
CREATE TRIGGER entry_fts_agent_update
AFTER UPDATE OF personality, communication_style ON agent
BEGIN
  DELETE FROM entry_fts WHERE entity = 'agent' AND entity_id = OLD.name;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('agent', NEW.personality || ' ' || NEW.communication_style, NEW.name);
END;
CREATE TRIGGER entry_fts_agent_delete
AFTER DELETE ON agent
BEGIN
  DELETE FROM entry_fts WHERE entity = 'agent' AND entity_id = OLD.name;
END;
CREATE TRIGGER entry_fts_artifact_insert
AFTER INSERT ON artifact
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('artifact', coalesce(NEW.description, '') || ' ' || coalesce(NEW.retired_reason, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_artifact_update
AFTER UPDATE OF description, retired_reason ON artifact
BEGIN
  DELETE FROM entry_fts WHERE entity = 'artifact' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('artifact', coalesce(NEW.description, '') || ' ' || coalesce(NEW.retired_reason, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_artifact_delete
AFTER DELETE ON artifact
BEGIN
  DELETE FROM entry_fts WHERE entity = 'artifact' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_audit_finding_insert
AFTER INSERT ON audit_finding
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('audit_finding', NEW.summary || ' ' || coalesce(NEW.recommendation, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_audit_finding_update
AFTER UPDATE OF summary, recommendation ON audit_finding
BEGIN
  DELETE FROM entry_fts WHERE entity = 'audit_finding' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('audit_finding', NEW.summary || ' ' || coalesce(NEW.recommendation, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_audit_finding_delete
AFTER DELETE ON audit_finding
BEGIN
  DELETE FROM entry_fts WHERE entity = 'audit_finding' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_milestone_insert
AFTER INSERT ON milestone
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('milestone', coalesce(NEW.summary, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_milestone_update
AFTER UPDATE OF summary ON milestone
BEGIN
  DELETE FROM entry_fts WHERE entity = 'milestone' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('milestone', coalesce(NEW.summary, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_milestone_delete
AFTER DELETE ON milestone
BEGIN
  DELETE FROM entry_fts WHERE entity = 'milestone' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_quick_criterion_insert
AFTER INSERT ON quick_criterion
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('quick_criterion', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_quick_criterion_update
AFTER UPDATE OF text ON quick_criterion
BEGIN
  DELETE FROM entry_fts WHERE entity = 'quick_criterion' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('quick_criterion', NEW.text, NEW.id);
END;
CREATE TRIGGER entry_fts_quick_criterion_delete
AFTER DELETE ON quick_criterion
BEGIN
  DELETE FROM entry_fts WHERE entity = 'quick_criterion' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_retro_application_insert
AFTER INSERT ON retro_application
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('retro_application', NEW.note, NEW.id);
END;
CREATE TRIGGER entry_fts_retro_application_update
AFTER UPDATE OF note ON retro_application
BEGIN
  DELETE FROM entry_fts WHERE entity = 'retro_application' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('retro_application', NEW.note, NEW.id);
END;
CREATE TRIGGER entry_fts_retro_application_delete
AFTER DELETE ON retro_application
BEGIN
  DELETE FROM entry_fts WHERE entity = 'retro_application' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_story_insert
AFTER INSERT ON story
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('story', coalesce(NEW.status_note, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_story_update
AFTER UPDATE OF status_note ON story
BEGIN
  DELETE FROM entry_fts WHERE entity = 'story' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('story', coalesce(NEW.status_note, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_story_delete
AFTER DELETE ON story
BEGIN
  DELETE FROM entry_fts WHERE entity = 'story' AND entity_id = OLD.id;
END;
CREATE TRIGGER entry_fts_task_insert
AFTER INSERT ON task
BEGIN
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('task', coalesce(NEW.description, '') || ' ' || coalesce(NEW.status_note, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_task_update
AFTER UPDATE OF description, status_note ON task
BEGIN
  DELETE FROM entry_fts WHERE entity = 'task' AND entity_id = OLD.id;
  INSERT INTO entry_fts (entity, text, entity_id)
  VALUES ('task', coalesce(NEW.description, '') || ' ' || coalesce(NEW.status_note, ''), NEW.id);
END;
CREATE TRIGGER entry_fts_task_delete
AFTER DELETE ON task
BEGIN
  DELETE FROM entry_fts WHERE entity = 'task' AND entity_id = OLD.id;
END;
CREATE TRIGGER criterion_approach_tag_not_retired_on_insert
    BEFORE INSERT ON criterion_approach FOR EACH ROW
    WHEN (SELECT retired_at FROM test_approach WHERE tag = NEW.tag) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: criterion_approach.tag references a retired test_approach row');
    END;
CREATE TRIGGER criterion_approach_tag_not_retired_on_update
    BEFORE UPDATE OF tag ON criterion_approach FOR EACH ROW
    WHEN (SELECT retired_at FROM test_approach WHERE tag = NEW.tag) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: criterion_approach.tag references a retired test_approach row');
    END;
CREATE TRIGGER story_criterion_approach_tag_not_retired_on_insert
    BEFORE INSERT ON story_criterion_approach FOR EACH ROW
    WHEN (SELECT retired_at FROM test_approach WHERE tag = NEW.tag) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: story_criterion_approach.tag references a retired test_approach row');
    END;
CREATE TRIGGER story_criterion_approach_tag_not_retired_on_update
    BEFORE UPDATE OF tag ON story_criterion_approach FOR EACH ROW
    WHEN (SELECT retired_at FROM test_approach WHERE tag = NEW.tag) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: story_criterion_approach.tag references a retired test_approach row');
    END;
CREATE TRIGGER finding_severity_id_severity_domain_not_retired_on_insert
    BEFORE INSERT ON finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.severity_id AND domain = NEW.severity_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: finding.severity_id, finding.severity_domain references a retired taxonomy row');
    END;
CREATE TRIGGER finding_severity_id_severity_domain_not_retired_on_update
    BEFORE UPDATE OF severity_id, severity_domain ON finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.severity_id AND domain = NEW.severity_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: finding.severity_id, finding.severity_domain references a retired taxonomy row');
    END;
CREATE TRIGGER finding_category_id_category_domain_not_retired_on_insert
    BEFORE INSERT ON finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.category_id AND domain = NEW.category_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: finding.category_id, finding.category_domain references a retired taxonomy row');
    END;
CREATE TRIGGER finding_category_id_category_domain_not_retired_on_update
    BEFORE UPDATE OF category_id, category_domain ON finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.category_id AND domain = NEW.category_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: finding.category_id, finding.category_domain references a retired taxonomy row');
    END;
CREATE TRIGGER finding_agent_not_retired_on_insert
    BEFORE INSERT ON finding FOR EACH ROW
    WHEN (SELECT retired_at FROM agent WHERE name = NEW.agent) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: finding.agent references a retired agent row');
    END;
CREATE TRIGGER finding_agent_not_retired_on_update
    BEFORE UPDATE OF agent ON finding FOR EACH ROW
    WHEN (SELECT retired_at FROM agent WHERE name = NEW.agent) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: finding.agent references a retired agent row');
    END;
CREATE TRIGGER observation_category_taxonomy_id_taxonomy_domain_not_retired_on_insert
    BEFORE INSERT ON observation_category FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.taxonomy_id AND domain = NEW.taxonomy_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: observation_category.taxonomy_id, observation_category.taxonomy_domain references a retired taxonomy row');
    END;
CREATE TRIGGER observation_category_taxonomy_id_taxonomy_domain_not_retired_on_update
    BEFORE UPDATE OF taxonomy_id, taxonomy_domain ON observation_category FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.taxonomy_id AND domain = NEW.taxonomy_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: observation_category.taxonomy_id, observation_category.taxonomy_domain references a retired taxonomy row');
    END;
CREATE TRIGGER observation_category_observation_id_not_retired_on_insert
    BEFORE INSERT ON observation_category FOR EACH ROW
    WHEN (SELECT retired_at FROM observation WHERE id = NEW.observation_id) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: observation_category.observation_id references a retired observation row');
    END;
CREATE TRIGGER observation_category_observation_id_not_retired_on_update
    BEFORE UPDATE OF observation_id ON observation_category FOR EACH ROW
    WHEN (SELECT retired_at FROM observation WHERE id = NEW.observation_id) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: observation_category.observation_id references a retired observation row');
    END;
CREATE TRIGGER audit_finding_severity_id_severity_domain_not_retired_on_insert
    BEFORE INSERT ON audit_finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.severity_id AND domain = NEW.severity_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: audit_finding.severity_id, audit_finding.severity_domain references a retired taxonomy row');
    END;
CREATE TRIGGER audit_finding_severity_id_severity_domain_not_retired_on_update
    BEFORE UPDATE OF severity_id, severity_domain ON audit_finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.severity_id AND domain = NEW.severity_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: audit_finding.severity_id, audit_finding.severity_domain references a retired taxonomy row');
    END;
CREATE TRIGGER audit_finding_dimension_id_dimension_domain_not_retired_on_insert
    BEFORE INSERT ON audit_finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.dimension_id AND domain = NEW.dimension_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: audit_finding.dimension_id, audit_finding.dimension_domain references a retired taxonomy row');
    END;
CREATE TRIGGER audit_finding_dimension_id_dimension_domain_not_retired_on_update
    BEFORE UPDATE OF dimension_id, dimension_domain ON audit_finding FOR EACH ROW
    WHEN (SELECT retired_at FROM taxonomy WHERE id = NEW.dimension_id AND domain = NEW.dimension_domain) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: audit_finding.dimension_id, audit_finding.dimension_domain references a retired taxonomy row');
    END;
CREATE TRIGGER artifact_document_artifact_id_not_retired_on_insert
    BEFORE INSERT ON artifact_document FOR EACH ROW
    WHEN (SELECT retired_at FROM artifact WHERE id = NEW.artifact_id) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: artifact_document.artifact_id references a retired artifact row');
    END;
CREATE TRIGGER artifact_document_artifact_id_not_retired_on_update
    BEFORE UPDATE OF artifact_id ON artifact_document FOR EACH ROW
    WHEN (SELECT retired_at FROM artifact WHERE id = NEW.artifact_id) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: artifact_document.artifact_id references a retired artifact row');
    END;
CREATE TRIGGER dependency_kind_not_retired_on_insert
    BEFORE INSERT ON dependency FOR EACH ROW
    WHEN (SELECT retired_at FROM dependency_kind WHERE kind = NEW.kind) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: dependency.kind references a retired dependency_kind row');
    END;
CREATE TRIGGER dependency_kind_not_retired_on_update
    BEFORE UPDATE OF kind ON dependency FOR EACH ROW
    WHEN (SELECT retired_at FROM dependency_kind WHERE kind = NEW.kind) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: dependency.kind references a retired dependency_kind row');
    END;
CREATE TRIGGER document_agent_agent_not_retired_on_insert
    BEFORE INSERT ON document_agent FOR EACH ROW
    WHEN (SELECT retired_at FROM agent WHERE name = NEW.agent) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: document_agent.agent references a retired agent row');
    END;
CREATE TRIGGER document_agent_agent_not_retired_on_update
    BEFORE UPDATE OF agent ON document_agent FOR EACH ROW
    WHEN (SELECT retired_at FROM agent WHERE name = NEW.agent) IS NOT NULL
    BEGIN
      SELECT RAISE(ABORT, 'retired: document_agent.agent references a retired agent row');
    END;
INSERT INTO "schema_version" ("version", "applied_at") VALUES (1, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (2, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (3, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (4, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (5, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (6, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (7, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (8, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (9, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (10, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (11, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (12, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (13, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (14, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (15, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (16, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (17, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (18, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (19, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (20, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (21, '1970-01-01T00:00:00Z');
INSERT INTO "schema_version" ("version", "applied_at") VALUES (22, '1970-01-01T00:00:00Z');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('adr', NULL, 'child');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('audit', 'audits', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('communication', 'communications', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('coverage_matrix', 'epics', 'child');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('discussion', 'discussions', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('epic', 'epics', 'child');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('library', 'library', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('problem_brief', 'plans', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('product_brief', 'briefs', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('quick', 'quick', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('retro', 'retros', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('review', 'reviews', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('runbook', 'runbooks', 'root');
INSERT INTO "document_kind" ("kind", "dir", "numbering") VALUES ('spec', 'specifications', 'root');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('adr', 'discussion');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('adr', 'problem_brief');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('adr', 'product_brief');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('adr', 'spec');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('coverage_matrix', 'epic');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('epic', 'spec');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('product_brief', 'problem_brief');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('retro', 'epic');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('retro', 'quick');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('retro', 'spec');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('review', 'epic');
INSERT INTO "document_kind_parent" ("kind", "parent_kind") VALUES ('review', 'spec');
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M04XYEFE9BKW5TV9701GKQVF', '01M04XXNBGJS968318HYM0WAM8', 'Reach for it before assuming the surface has it', '**Source**: retro 38, Codebase Discoveries — "The surface refuses what it never anticipated, and refuses it quietly." `entityTools` dropped nulls, so a waiver could not be lifted and the refused clear reported success. `list_artifact_document` was scoped one way only. `artifact.url` and `published_at` are both `NOT NULL`. `review_agent` is kind-pinned to `review`. `document_kind` was neither readable nor listable. The shared `Perspectives` procedure loaded a roster without `include_body` and rendered voices off nothing.

A tool surface, schema, or shared procedure will accept a call it was never designed for and answer it wrongly without erroring. Every gap of this kind found in this project was found by a consumer reaching for something; none came from reading the schema. Reading is not a substitute for reaching.

- **Walk the reads before writing the consumer.** Call each read the new skill, migration or client will need, and look at what comes back. It costs minutes; the alternative is a debugging pass, and sometimes a shipped defect.
- **Expect the quiet refusal, not the loud one.** These failures do not throw. A dropped null reports success. A one-way scope returns rows. A withheld column arrives as an absent field rather than an error. Ask what a wrong answer would look like, and whether you could tell.

**A fix at the site is not a fix of the class.** This was recorded in three consecutive retros — 36, 38 and 39 — and each time repaired where it surfaced and nowhere else. Retro 38 named the shared `Perspectives` procedure reading a roster without `include_body`; that was fixed, and the 23 skill files beside it were not. When a surface behaviour bites once, sweep every caller before closing it.', 0, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M04XYS90T01YE3QY0GWN8AKA', '01M04XXNBGJS968318HYM0WAM8', 'A check that passes may be passing for a reason other than the one you want', '**Sources**: retro 42, Criteria gaps; retro 56, Testing gaps. Promoted because it is the single most re-derived lesson in this project''s history — the same rule was found independently, in a different disguise, in **thirteen** retros: 35 (a truncated check reported a pass it never computed), 36 (a green suite proved nothing about whether the server could start; section-scoped assertions alias against nearby prose), 37 (two checks that agree are not two checks), 38 (three quantifier failures, all making the assertion vacuous rather than wrong), 39 (a green assertion is not evidence until the wrong answer is known to be excluded), 40 (a vacuous regex reads exactly like a working one), 41 (a criterion phrased as "the corpus still has N of these" expires the moment the epic succeeds), 42, 44 (a specific assertion placed behind a generic one never runs), 45 (a criterion with two failure shapes gets tested against whichever one the code makes easy), 47 (a token sweep cannot prove a path writes nothing), 49 (a comparator that never sorts passes an ordering test whose code already emits in order), and 56.

**At the criterion.** An absence can be delivered by something other than the mechanism under test. Before marking a criterion of the form "X is not created / does not happen" as met, ask what else in the current state of the tree would produce that absence — a crashed process, a sibling change, a fix that landed elsewhere. Where the answer is "something else could", the criterion needs the mechanism named before it can be verified. Retro 42''s case is the hardest kind to see: a correct assertion in one spec, undermined by a sibling spec that removed the condition it discriminated on.

**At the sweep.** A must-NOT that cannot be handed a broken corpus is a must-NOT nobody has checked. All three of spec 50''s cross-site sweeps passed on their first run, which is what a vacuous sweep looks like: one matched a phrase that was present either way, one had a control asserting only that the fixture contained a label, and one exercised `String.replace` rather than the reading it was meant to test. The fix was the same move each time — extract the reading into a function taking a `read(skill)` callback, so it can be pointed at a corpus with the defect planted.

The practical form of both: **plant the defect, then watch the check fail.** A check that has never been shown failing is a check whose passing means nothing, and neither reading it nor reviewing it substitutes. Budget the fixture, not just the assertion.

Two corollaries this project paid for separately:

- **A must-NOT placed on the epic that *introduces* a rule, rather than the epic that gives it content, passes vacuously and looks like coverage.** Ask of every must-NOT what would make it pass for the wrong reason on the day it is written.
- **Success can make a check undrivable on its own subject** (retro 41). A criterion counting instances of the thing being removed expires the moment the work succeeds; phrase it against a fixture, not against the corpus.', 1, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M04XZ45N7MTCBF1GX9X68YD9', '01M04XXNBGJS968318HYM0WAM8', 'A control mutation needs a revert that cannot take the tree with it', '**Source**: retro 56, Testing gaps.

Proving a control means deliberately breaking a file, running the suite, and putting the file back. The reflex for the last step is `git checkout -- <file>`, and it is wrong: it discards whatever else is uncommitted in that file, and a run that has been editing all session has plenty. Spec 50''s run did exactly this and had to correct mid-flight.

**Copy the file to a scratchpad before mutating it, and `cp` it back afterwards.** The revert is then bounded to the file and to the change you made, and it cannot reach anything else.

Two guidelines sit behind this and are worth restating because a control mutation is the moment both get bent:

- **Version control stays with the user.** No `checkout`, `reset`, `stash` or `commit` on the agent''s own initiative — including as a convenience during testing.
- **Edits go through the Edit tool, file by file.** Not `sed`, `perl` or `awk`. Same run, same session, also breached: a bulk edit is opaque, bypasses review, and corrupts files on partial matches.

Neither breach was caught by the suite. Both were caught by noticing, and written into the session''s conduct notes so the rest of the run would not repeat them.', 2, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M04Y2PYPSJ8P96G8J9AGCV1W', '01M04XXNBGJS968318HYM0WAM8', 'A control is only a control once you have watched it fail, and read why', '**Synthesised from** retros 37, 39, 44, 46, 47, 48 and 55 — the second theme this project re-derived repeatedly. Unlike the entries above this is a synthesis rather than the promotion of one observation, so those retros keep their originals rather than carrying a retirement marker.

A control is the run that proves a check can fail. Six ways this project has had one that did not do its job:

- **A control needs a body, not just a row** (37). A fixture that exists but carries none of the content the check reads passes for the wrong reason.
- **A mutation is only caught when the mutation ran** (39). Confirm the mutated code path was actually reached before believing the failure it produced — or the pass it did not.
- **A control belongs in the same fixture as the arm it controls, not beside it** (47). Two fixtures drift, and the control ends up proving something about a state the real arm never enters.
- **A control that fails by propagating someone else''s exception is half a control** (55). The remove-the-condition control caught its mutation by throwing "table schema_version already exists" four frames down: a true verdict about the wrong harm.
- **An assertion message that names the presumed cause is wrong for every other way it can fail** (45, 46). Retro 44''s control caught its mutation and said nothing about why; the whole difference is what the next person reads at 2am.
- **Assert the exception *type*, not merely that something was raised** (48). "DID NOT RAISE" is a true verdict that names the wrong harm — twice in one epic.

The positive form, from retro 44: **to close a must-NOT, remove the condition and watch the same inputs produce what was refused.** "X does not happen under condition C" is satisfied by a feature that never works at all, and only removing C distinguishes them.

And read the failure text every time, not just the failure. Retro 55: three of seventeen mutations were about *where* a line sits rather than what it does, and two of those either survived or produced a misleading message. Neither is visible from a green suite.', 3, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M050NPBGJPF3DGFC5CNCA9CK', '01M050N7S7YF827QD2CH0TVTFK', 'Problem recap', 'An MCP server is pinned to a version directory for the life of the session. The plugin root is resolved once at launch; installing a new plugin version writes a new version directory and repoints the installation registry, and reaches into nothing already running. Only sessions open *across* an upgrade are affected, and nothing tells them.

On 2026-08-16 this repository''s own session ran dpm 0.3.0 for several hours after 0.4.0 was installed. All twenty-one tools answered normally. The four `disposition` taxonomy terms 0.4.0 seeds were never inserted, because the server doing the seeding did not know they existed. Nothing failed, nothing logged, and it surfaced only because a taxonomy listing was read for an unrelated reason.

**The harm is one-way.** An older server under-seeds and under-reports; it does not corrupt. The opposite direction — a database migrated beyond what the server understands — is already handled: `migrate()` reports `ahead`, the server logs `aheadMessage` and degrades to a read-only tool set. The backward case has no detection at all, and this spec is about the backward case.

**There are two backward skews, and neither subsumes the other.**

The first is *the server is older than the plugin installed beside it*. That is the failure observed, and it is detectable from the filesystem alone: the running server''s own version directory has a newer sibling.

The second is *the server is older than the plugin that last wrote to this database*. That is the shared-repository case — a colleague publishes from a newer plugin, and the next person pulls and opens the result on an older one. It requires the database to carry a stamp, and no such stamp exists.

The redirection that produced this spec is that the second detector is blind to the first. In the observed failure nothing newer had ever written to the database, so a stamp recording who last wrote would have read clean while the server sat four terms short of the vocabulary it was supposed to seed. A design that shipped only the stamp would have been a correct implementation of a check that could not have caught the incident that motivated it.', 0, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M051QZ3KAQR98TTAZRKX0PJJ', '01M050N7S7YF827QD2CH0TVTFK', 'In scope', 'The neighbour check, taking the plugin root as an argument rather than reading it from the environment, evaluated each time it is reported.

The database stamp: a migration, a one-row table, and a write that happens only when the running version exceeds the version already recorded.

Detection of both backward skews — the server older than the plugin installed beside it, and the server older than the plugin that last wrote to the database.

Reporting through two channels: a new top-level field on `check_integrity`''s response, which is the one a session actually reads, and a stderr line at database open in the manner of the existing ahead-message.

A read-only launch reporting both skews, despite reaching neither detector today.

The maintenance record covering the coupling to the host''s plugin cache layout.', 1, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M051R4NVP2WQ98AR8A1QQ8R3', '01M050N7S7YF827QD2CH0TVTFK', 'Out of scope', 'The three excluded requirements carry their reasoning on their own rows: refusing or degrading tool calls on a backward skew, self-repairing by loading from a newer sibling directory, and restarting the server into the newer version.

Anything over the network, which is foreclosed by ENVX4 rather than merely unplanned.

Two further exclusions are not requirements at all, and are written down so that nobody reopens them part-way through an epic.

**The existing forward-skew behaviour is not touched.** A database migrated beyond what the server understands continues to produce `ahead`, the ahead-message and a read-only tool set, exactly as it does now. This spec adds a second, opposite detector; it does not revisit the first.

**No session hook is added.** dpm ships none, deliberately — a skill names the shared conventions file and reads it, rather than a hook injecting anything into every session. A warning delivered by hook would also be useless for the failure that motivated this work, since a hook belonging to a stale plugin is as stale as the server it ships beside.', 2, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M051R9S9BMV48YK5194EWBGH', '01M050N7S7YF827QD2CH0TVTFK', 'Deferred', '**Consulting the host''s installation registry** (FR8), which would still detect a skew once the older sibling directories have been swept. Deferred rather than excluded: the decision records it as the route this takes when the sibling scan proves insufficient.

**Reporting a skew from the `publish` path.** This is the gap worth stating plainly, because it is the one where a stale server does the most damage. `publish` regenerates every projected document using its own release''s renderers, and it opens the database rather than starting it — so it reaches neither detector, and produces a tree of subtly outdated markdown that the pre-commit guard then passes, because the guard compares that projection against a regeneration from the same stale code. Four missing vocabulary terms are a smaller problem than that.

It is deferred because closing it means deciding whether a stale publish warns or refuses, and refusing reopens the requirement this spec excluded. The plumbing is cheap once the neighbour check exists as a function taking a root; the policy is what needs its own conversation.', 3, NULL);
INSERT INTO "document_section" ("id", "document_id", "heading", "body", "position", "superseded_at") VALUES ('01M052788NATYB2CQ5QHJ68EQS', '01M050N7S7YF827QD2CH0TVTFK', 'Integration boundaries', 'Five seams, drawn from the decisions rather than invented.

**The neighbour check and the filesystem.** The reader is a parameter; the contract is a root in, sibling names out. This is where NFR1''s read-counting and ENVX2''s prohibition on reaching the home directory are both enforced, and having it as a seam at all is what makes either of them enforceable.

**The detectors and the verdict.** Two detectors producing one verdict shape, carrying the state, the running version, the version found and the message. FR4''s must-not against composing the sentence in more than one place lives here; it is the only point that keeps one sentence from becoming four as the second channel is added.

**The verdict and the integrity response.** A new top-level field beside `entries` and `orphans`, leaving both `ok` and the register derivation untouched.

**`start()` and the stamp.** The documented contract is three steps in a fixed order, and this makes it four. The ordering constraint is the one already stated: the table has to exist before anything writes to it, so the stamp follows migration for the same reason vocabulary does.

**The read-only bring-up and the detectors.** The read-only branch is deliberately one call where the ordinary one is five, and the four it omits are the requirement rather than an optimisation. FR7 adds reading to it and must add nothing else. This is the seam most likely to be got wrong, because the obvious way to give a read-only launch the detectors is to let it call `start()` — which would reintroduce every write the branch exists to avoid.', 4, NULL);
INSERT INTO "library_document" ("document_id", "document_kind", "doc_type", "source") VALUES ('01M04XXNBGJS968318HYM0WAM8', 'library', 'coding-standards', 'docs/cpm/library/lessons-learned.md — carried over from CPM at the 2026-08-16 migration, with its amendment blocks folded into the body');
INSERT INTO "library_scope" ("document_id", "scope") VALUES ('01M04XXNBGJS968318HYM0WAM8', 'do');
INSERT INTO "adr" ("document_id", "document_kind", "decision_status", "decision") VALUES ('01M051JPHA56Z9A2VTMBV2EWHY', 'adr', 'accepted', 'A skew is reported in a new top-level field of `check_integrity`''s response, separate from `entries` and `orphans` and carrying its own verdict and could-not-check state, leaving `ok` a statement about the data alone.');
INSERT INTO "adr" ("document_id", "document_kind", "decision_status", "decision") VALUES ('01M051JRSZA8SNR8N4NXQRQ0ZY', 'adr', 'accepted', 'The plugin version is recorded in a new one-row table introduced by a migration, accepting the one-time consequence that servers older than that release degrade to read-only against any project the new release has opened.');
INSERT INTO "adr" ("document_id", "document_kind", "decision_status", "decision") VALUES ('01M051JTJK59ZEVNHVWNJM286Q', 'adr', 'accepted', 'The running plugin''s directory is derived from the module''s own URL and its siblings are read from the parent directory and compared as versions with the existing `parseVersion`, with the root taken as an argument rather than from the environment.');
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051K1KHBMJJX6VTF1F2TXAZ', '01M051JPHA56Z9A2VTMBV2EWHY', 'A new top-level field', 1, 'The skew sits beside `entries` and `orphans` rather than inside either, with its own verdict and its own could-not-check state. `ok` continues to mean the database is internally consistent, which it is — the rows are sound and the reader is stale. The field is present whether or not a skew was found, because an absent field and a field reporting nothing found read identically to someone who was not already looking for it.', 0);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051K3WPAVHV481KMPD62QW4', '01M051JPHA56Z9A2VTMBV2EWHY', 'A register entry', 0, 'Rejected. `entries` is built by mapping over the register so that an entry added there appears in the report without the tool being edited, and a parity test holds that derivation. A version skew names no rows and is not a cross-row invariant, so it would have to arrive either as a fake register entry or by breaking the mapping — and the second would cost the property the parity test exists to protect.', 1);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051K6SRPA4CZ2J3SB07JEZM', '01M051JPHA56Z9A2VTMBV2EWHY', 'Setting `ok` to false', 0, 'Rejected. It would guarantee the warning is noticed, at the price of the report saying the database is broken when nothing is wrong with it. Every caller branching on `ok` would begin treating an environment warning as corruption, and the one report whose job is to be trusted would start crying wolf.', 2);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051KAAEKYJNBV8STXF1S9Y7', '01M051JRSZA8SNR8N4NXQRQ0ZY', 'A new one-row table', 1, 'A named table holding a named column, arriving through the migration path everything else in the schema arrives through, and appearing in the dump like every other row. It costs a schema bump, and therefore costs older servers their write tools against any project this release has opened. That is accepted: read-only is already the policy for a database a server does not fully understand, so this extends an existing rule by one release rather than inventing a lockout. The cost is also one-time and bounded — the stamp records the plugin version rather than the schema version, so every release after it moves the stamp without moving the schema.', 0);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051KDP8VDCSFBJ7BCQYXPVK', '01M051JRSZA8SNR8N4NXQRQ0ZY', 'A column on `schema_version`', 0, 'Rejected. It costs the same schema bump as its own table while additionally putting two adjacent answers in one place: `schema_version` records how far the database has been migrated, one row per migration, and the plugin version is neither of those things. A table holding one fact per row and another fact on some of those rows is a table that will be read wrongly.', 1);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051KGCK9HG6ASNKPGQ3ZA21', '01M051JRSZA8SNR8N4NXQRQ0ZY', '`PRAGMA user_version`', 0, 'Rejected, and it is the one that tempts. It avoids the migration and the bump entirely. But it is a single unnamed 32-bit integer, so a three-part version has to be encoded into it and decoded on the way out, and the slot belongs to whoever claims it first — nothing marks it as ours, and nothing would notice if something else began writing there.', 2);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051KK0AEXHQ7P9118CQP1PP', '01M051JRSZA8SNR8N4NXQRQ0ZY', 'A sidecar file beside the database', 0, 'Rejected. It avoids the schema bump, and it is a file rather than a row in a system whose thesis is that planning state is rows and files are a generated projection. To be useful across a team it would have to be committed, which means the pre-commit guard has to learn about it, which means a second artefact to keep in step with the database — more machinery than the migration it was avoiding.', 3);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051KNWC8HBWK4HHPASBABDF', '01M051JTJK59ZEVNHVWNJM286Q', 'Sibling directory scan', 1, 'The running directory comes from the module''s own URL, the parent is read, and the names are compared as versions with the parser the Node floor check already uses. It depends on one property of the host — that versions are sibling directories — rather than on a file format. The root is a parameter, which is what makes it testable against a constructed directory instead of against the author''s own machine.', 0);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051KSV79WJZXMVZ1PY79ESW', '01M051JTJK59ZEVNHVWNJM286Q', 'Read the host''s installation registry', 0, 'Not chosen now, and the route FR8 would take. It carries strictly better information — which version is current, rather than which are present — and would still detect a skew after the older sibling directories are swept. It is rejected for the first release because it is an undocumented JSON file at a path we would have to construct, owned by a component shipping on its own schedule. A weaker signal from a stabler surface is the better first move.', 1);
INSERT INTO "adr_option" ("id", "adr_id", "name", "chosen", "rationale", "position") VALUES ('01M051KVG2NWPTJTFC8S7DV0F8', '01M051JTJK59ZEVNHVWNJM286Q', 'Query the marketplace over the network', 0, 'Rejected, and foreclosed by ENVX4. It answers a different question — what has been published, rather than what is installed — and makes a local diagnostic fail differently depending on whether the machine is online.', 2);
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051K1KHBMJJX6VTF1F2TXAZ', 'complexity', 'Low, but it introduces a second notion of "something is wrong" alongside `ok`. Anyone reading the report now has two places to look, and the field has to be self-describing enough that the second place is obvious.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051K1KHBMJJX6VTF1F2TXAZ', 'cost', 'One added field on one response. Nothing existing changes shape, so no caller of `check_integrity` has to be touched.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051K1KHBMJJX6VTF1F2TXAZ', 'reversibility', 'High. An added field can be renamed or moved while `ok` and `entries` keep their meanings, because nothing downstream has been asked to reinterpret what it already reads.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051K6SRPA4CZ2J3SB07JEZM', 'reversibility', 'Low, and that is the reason to refuse it rather than try it. Once `ok` has meant "no skew either" for one release, every caller written against it encodes that meaning, and narrowing it back is a silent behaviour change in the direction of missing things.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KAAEKYJNBV8STXF1S9Y7', 'complexity', 'Low, and deliberately the most boring option available. It uses the migration path, the dump and the guard exactly as they already work, so nothing new has to be kept in step.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KAAEKYJNBV8STXF1S9Y7', 'cost', 'A migration file, a table, and a one-time read-only lockout for anyone still on an older plugin the first time this release opens a shared project. The lockout is the real price and it is paid by people who did nothing.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KAAEKYJNBV8STXF1S9Y7', 'reversibility', 'Low in one direction only. A schema version, once raised, cannot be lowered for databases already migrated, so the lockout cannot be taken back by a later release. What can be changed freely is what is done with the stamp — the reading, the comparison and the reporting are all ordinary code.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KGCK9HG6ASNKPGQ3ZA21', 'cost', 'Lowest of the four up front — no migration, no bump, no lockout, and no change to the dump''s shape.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KGCK9HG6ASNKPGQ3ZA21', 'reversibility', 'Superficially high and actually poor. Moving off the pragma later means every database already carrying an encoded integer has to be read by something that knows the encoding, and by then the encoding is undocumented history rather than a decision.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KK0AEXHQ7P9118CQP1PP', 'complexity', 'Highest of the four, in the place it is least visible. A committed sidecar becomes a second artefact the pre-commit guard has to reconcile, which is the machinery the migration was supposedly too expensive for.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KNWC8HBWK4HHPASBABDF', 'complexity', 'Low in code and non-zero in coupling: it assumes the host lays versions out as sibling directories. That assumption is the thing recorded in the maintenance record under NFR5, because it is the host''s to change.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KNWC8HBWK4HHPASBABDF', 'cost', 'One directory read and a comparison, reusing a parser that already exists. No dependency, no schema change, no new file.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KNWC8HBWK4HHPASBABDF', 'reversibility', 'High. It writes nothing and nothing persists, so it can be replaced or removed in a release without leaving anything behind to migrate.');
INSERT INTO "adr_option_tradeoff" ("option_id", "axis", "assessment") VALUES ('01M051KSV79WJZXMVZ1PY79ESW', 'reversibility', 'High, which is why deferring it costs nothing. It reads a file and persists no state, so adopting it under FR8 later is an addition rather than a migration away from this.');
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050SJFST75N3GFZ64WNPTND', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR1', 'functional', 'must', NULL, NULL, 'The server reports when a newer version of the plugin is installed alongside the version it is running from.', 0, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050SM0JB72VCAW0BVRQCXG6', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR2', 'functional', 'must', NULL, NULL, 'The database records the version of the plugin that last wrote to it. The record is made by a server that writes, and never by one that only observes — a read-only launch leaves it as it found it.', 3, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050SSS6FCCYF8A9QZWQZ7DY', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR1a', 'functional', 'must', NULL, '01M050SJFST75N3GFZ64WNPTND', 'The neighbour check is evaluated at the moment it is reported, never cached from server start. The observed failure arrived twenty hours into a running session, when a check evaluated at start had already found nothing and been right to.', 1, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050SWEGP80AYH58ZK0P47FG', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR1b', 'functional', 'must', NULL, '01M050SJFST75N3GFZ64WNPTND', 'The neighbour check completes without error when the plugin root is not a version directory, reporting could-not-check rather than failing and rather than claiming no skew. A plugin loaded from a working tree is the ordinary case for anyone developing dpm, and it produces the same "found nothing" as a genuinely current install — only one of which is honestly a no-skew answer.', 2, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050SYMMPF5JV138K22HFYK4', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR2a', 'functional', 'must', NULL, '01M050SM0JB72VCAW0BVRQCXG6', 'The recorded version is written only when the writing server''s version is greater than the version already recorded, so an unchanged project produces an unchanged dump.', 4, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050T08GZRV3X57AD61PWZ0N', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR3', 'functional', 'must', NULL, NULL, 'The server reports when the plugin version recorded in the database is newer than its own.', 5, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050T1XRVWJYY3T5XXJNXTPB', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR4', 'functional', 'must', NULL, NULL, 'A reported skew names the version running, the newer version found, and what to do about it, and the sentence saying so is composed in one place rather than assembled separately by each caller. Naming the remedy is the existing convention: the dump-staleness message names publish, which is both true and the fix. One composer is what keeps the tool response and the stderr line from drifting into two accounts of the same skew.', 6, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050T4QAWVSBRF17V42XSGVA', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR5', 'functional', 'must', NULL, NULL, 'The report distinguishes checked-and-found-no-skew from could-not-check. A check that silently did not run is the defect `checkIntegrity` already guards against by counting what it checked rather than reporting only what failed.', 7, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050T70SV8AT324K0BEZ2NY2', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR6', 'functional', 'must', NULL, NULL, 'A skew known at database open is written to stderr, in the manner of the existing ahead-message. In practice this carries the database-stamp skew; the neighbour skew is usually absent at open and arrives later.', 8, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050T8WP5MTS43W8JCHRM0HM', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR7', 'functional', 'should', NULL, NULL, 'A server launched read-only reports both skews. It never reaches `start()`, so as things stand it would learn of neither — and a board observing many projects is the surface where an unnoticed stale server misreports the most of them.', 9, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050TB4BT5FV666XQ878A5A0', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR8', 'functional', 'could', 'deferred', NULL, 'The neighbour check also consults the installation registry, catching a skew after the older sibling directories have been swept.', 10, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050TDKCNVM023XFMKM2YT85', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR9', 'functional', 'wont', 'out_of_scope', NULL, 'Refusing or degrading tool calls on a backward skew. The forward case earns a read-only tool set because an older server can damage a newer database; the backward case cannot, and a server that refused to serve because a newer plugin exists would cost more than the under-seeding it was protecting against.', 11, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050THQ89YAFXGN0CEHW85QJ', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR10', 'functional', 'wont', 'out_of_scope', NULL, 'Loading seed data or code from a newer sibling version directory in order to self-repair. It is the fix that suggests itself once the neighbour is visible, and it runs a newer release''s data through an older release''s guards and schema — the precise combination `migrate()` refuses in the forward direction. Recorded so the reasoning outlives the impulse.', 12, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M050TKQCY5G6Q54HYH2SFQJA', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'FR11', 'functional', 'wont', 'out_of_scope', NULL, 'Restarting or reloading the server into the newer version. Which version directory a server runs from is chosen by the MCP client at launch, and a process that re-executed itself elsewhere would be overriding that choice from inside.', 13, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051AB08BP2SRQPB92XZE056', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'NFR1', 'non_functional', 'must', NULL, NULL, 'The neighbour check costs one bounded directory read per report — no recursion, no process spawn, no network call. It runs on every report rather than once per session, so its cost is paid repeatedly and has to stay negligible.', 14, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051AD1B1DTGSST2N23P7VY1', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'NFR2', 'non_functional', 'must', NULL, NULL, 'A skew check that cannot complete degrades to could-not-check. It never fails the tool call and never stops the server. Paired with FR5: FR5 gives the report a way to say it, this gives the failure somewhere to go.', 15, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051AFK6WGGR51HRDBJZ3BBP', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'NFR3', 'non_functional', 'must', NULL, NULL, 'A session that neither upgrades the plugin nor changes planning data leaves the committed dump byte-identical. A stamp written on every start would diverge the dump every session, the pre-commit guard would fire on commits that changed nothing, and a guard that fires on nothing stops being read — which costs more than this feature is worth.', 16, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051AH8HRSBNM3HQ4EDKZEQH', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'NFR4', 'non_functional', 'must', NULL, NULL, 'The neighbour check reads only. It creates no file and no directory, and writes nothing anywhere — including under a read-only launch, whose whole guarantee is inertness.', 17, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051AM2H7N225EFYN5FJ12K3', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'NFR5', 'non_functional', 'must', NULL, NULL, 'The coupling to the host''s plugin cache layout is recorded in the project''s maintenance record, and named from no skill file. The layout is the host''s to change and not ours to rely on quietly; a pointer from a skill would be a line every invocation pays for.', 18, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051FXVRATSJ9792ABHWG7ZH', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENV1', 'environmental_requirement', 'must', NULL, NULL, 'Development: Node 22.5.0 or later, matching `engines.node`. Checkable by comparing the running `process.version` against the floor the server already states as `REQUIRED_NODE`.', 19, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051FZZSFG41WN4XKAXYESRJ', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENV2', 'environmental_requirement', 'must', NULL, NULL, 'Development: the suite runs via the built-in `node --test` runner with no install step. Checkable by running the test script on a clean checkout. This project has no CI, so the suite is run by whoever is at the keyboard — a runner needing setup is a runner that stops being run.', 20, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051G26K8RP8E6QZDKGAX8RB', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENV3', 'environmental_requirement', 'must', NULL, NULL, 'Development: a fixture standing in for a plugin cache layout — a directory holding sibling version directories — that the neighbour check can be pointed at. Checkable by a test that constructs one and asserts the check''s verdict against it.', 21, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051G46647GRRP5FMHZYGMX7', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENV4', 'environmental_requirement', 'must', NULL, NULL, 'Production: Node 22.5.0 or later on the machine running the MCP client. Checkable by the floor check the entry point already performs before anything reaches `node:sqlite`.', 22, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051G66CR82G4ZNEQYCM5V83', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENV5', 'environmental_requirement', 'must', NULL, NULL, 'Production: the running plugin''s own directory is derivable from the module''s URL at runtime. Checkable by resolving it and asserting it names the directory the module was loaded from. This is what makes the neighbour check possible without the host handing us anything.', 23, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051G8YMR8QX20G7SWFWNC4B', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENVX1', 'environmental_restriction', 'must', NULL, NULL, 'Development: no runtime or development dependency may be required. Checkable by asserting `dependencies` and `devDependencies` are both empty in `package.json`. A semver comparison is the obvious place a package would creep in, and the parser this needs already exists in `node-floor.js`.', 24, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051GBWM7XJNH6W0HTCEN3M0', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENVX2', 'environmental_restriction', 'must', NULL, NULL, 'Development: the suite must not require the real plugin cache or the user''s home directory. Checkable by the neighbour check taking its root as an argument, and by a test asserting it reads only the path it was given. Without this the obvious implementation passes on the author''s machine for reasons unrelated to the code being correct.', 25, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051GDWWCKCKECZJ1PQSW3TZ', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENVX3', 'environmental_restriction', 'must', NULL, NULL, 'Production: an environment variable naming the plugin root must not be required. Checkable by the resolver taking no value from `process.env`. The host expands its plugin-root placeholder into the launch arguments, and nothing guarantees it in the process environment.', 26, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M051GFMNV8HS8QM80BWP7S0T', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENVX4', 'environmental_restriction', 'must', NULL, NULL, 'Production: network access must not be required. Checkable by asserting no path this spec adds makes an outbound call. This forecloses the tempting implementation of FR8 — asking the marketplace what the current version is — which would make a local diagnostic depend on being online.', 27, NULL, NULL);
INSERT INTO "requirement" ("id", "spec_id", "spec_kind", "label", "class", "moscow", "exclusion", "parent_id", "text", "position", "coverage_claimed_at", "coverage_claim_hash") VALUES ('01M05271SG9G0BYGH25VE7SAKB', '01M050N7S7YF827QD2CH0TVTFK', 'spec', 'ENV6', 'environmental_requirement', 'must', NULL, NULL, 'Development: a temporary filesystem location the suite can create, write to and remove. Checkable by a test that creates one, writes into it and asserts it is gone afterwards. Reached from Step 6d rather than elicited: several integration criteria write and compare real files — the two dump comparisons, the filesystem-unchanged assertion, and the construction of ENV3''s sibling directories — and nothing recorded said the suite could.', 28, NULL, NULL);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051TBFX7E95TB876RV668HE', '01M050SJFST75N3GFZ64WNPTND', 'Given a root holding the running version and a higher-numbered sibling, the check reports a skew naming the higher version.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051TCZYEB1N87469MA9K0TE', '01M050SJFST75N3GFZ64WNPTND', 'Given a root whose siblings are all lower than or equal to the running version, the check reports no skew.', 'must', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051TEJSB2XEGC0VBWR5V707', '01M050SJFST75N3GFZ64WNPTND', 'The check reports a skew for a sibling lower than the running version. A reversed comparison satisfies the first criterion on any machine with more than one version installed, so the first criterion alone does not pin the direction.', 'must_not', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051THCGRV518WES6VFC0QPB', '01M050SSS6FCCYF8A9QZWQZ7DY', 'Two consecutive reports against a root that gained a higher sibling between them return different verdicts.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051TKHZA6VAENCTS8SPWJTS', '01M050SSS6FCCYF8A9QZWQZ7DY', 'With the check deliberately memoised, the two-consecutive-reports criterion fails, and the failure has been observed and read rather than assumed. This requirement exists because a start-time check would have been silently wrong for twenty hours; a test unable to distinguish a cached verdict from a fresh one reproduces the defect it was written to catch.', 'control', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051TN2ATPKBMTAR0JJG73WM', '01M050SWEGP80AYH58ZK0P47FG', 'Given a root whose name does not parse as a version, the check reports could-not-check.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051TQPRFBD4RDE03W6HDSGA', '01M050SWEGP80AYH58ZK0P47FG', 'Given a root with no sibling directories at all, the check reports could-not-check rather than no skew.', 'must', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051TTAKHBRAHVKC5R8CSZ8D', '01M050SWEGP80AYH58ZK0P47FG', 'The check throws for an unreadable or unparseable root.', 'must_not', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051WPWSFWJ6JKHX42F2WTRY', '01M050SM0JB72VCAW0BVRQCXG6', 'A database started by a server at version X carries X as its recorded plugin version.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051WRPMNHYZ5C6C372ABPKV', '01M050SM0JB72VCAW0BVRQCXG6', 'A database migrated from before the stamp existed acquires the running version on the next start.', 'must', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051WTC2610QCJ66WZ4Z1FQ5', '01M050SM0JB72VCAW0BVRQCXG6', 'A read-only launch writes the stamp. The read-only path exists so a board can observe every registered project without touching any of them; a stamp written on observation would diverge every one of those projects from its committed dump, and the owner would find the guard refusing a commit in a repository they had not opened.', 'must_not', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051WVXVPHHPN2H39DD9Y4DR', '01M050SYMMPF5JV138K22HFYK4', 'A server at the recorded version leaves the row untouched.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051WXGY1NBENQV371WWJQFK', '01M050SYMMPF5JV138K22HFYK4', 'A server below the recorded version leaves the row untouched — the stamp never moves backwards.', 'must', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051WZ06D57PMQ676MFKJCE2', '01M050SYMMPF5JV138K22HFYK4', 'A server above the recorded version replaces it.', 'must', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051X0FKZ98Z9V5989SF2V2Y', '01M050SYMMPF5JV138K22HFYK4', 'The row carries a value that differs between two runs of the same version. This is NFR3 stated where it can be checked: a timestamp column would satisfy every other criterion here and still diverge the dump on every start, which is the exact failure the requirement exists to prevent — while looking like good practice.', 'must_not', 3);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051X1YG1EMZ0QVMBZNGV51H', '01M050SYMMPF5JV138K22HFYK4', 'With the write made unconditional, the criterion that a server at the recorded version leaves the row untouched fails, and that failure has been observed and read rather than assumed.', 'control', 4);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051X3MJGQ517REPGWQJVHT0', '01M050T08GZRV3X57AD61PWZ0N', 'A database stamped above the running version produces a skew naming both versions.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051X5PXSZW7XZECRN3G0QZN', '01M050T08GZRV3X57AD61PWZ0N', 'A database stamped at or below the running version produces no skew.', 'must', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051X7BW2SS23NPB29ZHFKZ0', '01M050T08GZRV3X57AD61PWZ0N', 'A database whose stamp table is absent produces could-not-check rather than no skew. This is the read-only launch against a project the release has never opened: the table will not be there, and no-skew would be a lie told confidently.', 'must', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051Z4AKAQ4JTHJ4HFEV1DPS', '01M050T1XRVWJYY3T5XXJNXTPB', 'A reported skew contains the running version, the newer version found, and a remedy naming a session restart.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051Z6PN842RF5DXJMPZF2WN', '01M050T1XRVWJYY3T5XXJNXTPB', 'The skew sentence is composed in more than one place. This extends the rule the ahead-message already holds — one sentence serving both bring-ups, so a reader parsing the line matches one wording rather than two that are one edit from disagreeing. Two detectors reporting through two channels is four opportunities to write that sentence four times.', 'must_not', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051Z88XTCF9TD9KYBDFMZAX', '01M050T4QAWVSBRF17V42XSGVA', 'The skew field is present in the response when no skew was found.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051ZAE9DGY9WJ6FQ8MGX661', '01M050T4QAWVSBRF17V42XSGVA', 'The three states — skew found, no skew, could not check — are distinguishable without parsing message text.', 'must', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051ZBZR5PA0GE6NG2K27T8W', '01M050T4QAWVSBRF17V42XSGVA', 'A check that could not run renders as no skew.', 'must_not', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051ZDJ4V1CHVZ3DXJ0YVRT1', '01M050T4QAWVSBRF17V42XSGVA', 'With could-not-check collapsed into no-skew, FR1b''s criteria fail, and that failure has been observed and read rather than assumed.', 'control', 3);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051ZFZ032E4Y7C71NS00Z60', '01M050T70SV8AT324K0BEZ2NY2', 'A database stamped above the running version writes a line to stderr when opened.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051ZHP7FFBBTNJZJFCGC3JC', '01M050T70SV8AT324K0BEZ2NY2', 'A clean open writes anything to stderr. This continues the rule the project already holds — a clean session is silent there — which is what makes any line that does appear worth reading.', 'must_not', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M051ZKFEXZFV2W0257B57DPX', '01M050T8WP5MTS43W8JCHRM0HM', 'A read-only launch''s integrity response carries the same skew field, in the same three states, as an ordinary one.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521HBXYWCMC53PZBYR7VR9', '01M051AB08BP2SRQPB92XZE056', 'The check performs exactly one directory read per invocation. Counting reads means the reader is injectable — a seam falling out of the criterion rather than a preference, and the same seam ENVX2 needs.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521JYZ5YBG2BQHG4WQB5DB', '01M051AB08BP2SRQPB92XZE056', 'The check recurses into subdirectories.', 'must_not', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521NPJTBGKBW3F9JZ6AJN8', '01M051AB08BP2SRQPB92XZE056', 'The check spawns a process or opens a socket.', 'must_not', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521QD2BDHC8HGFVHEDZ5ES', '01M051AD1B1DTGSST2N23P7VY1', 'A directory read that throws produces could-not-check and a successful tool response.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521S0F3NDQJGMG0VKX8XDR', '01M051AD1B1DTGSST2N23P7VY1', 'An error from the check propagates out of the tool handler.', 'must_not', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521V0D5326TK967Y2MG48A', '01M051AD1B1DTGSST2N23P7VY1', 'With the error handling removed, the criterion that a throwing read produces could-not-check fails, and that failure has been observed and read rather than assumed.', 'control', 2);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521WNR1F2KCHXEJRQVK3MA', '01M051AFK6WGGR51HRDBJZ3BBP', 'Two consecutive starts at the same version, with no planning data changed, produce byte-identical dumps.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521YA35YV05139S92NQJN0', '01M051AFK6WGGR51HRDBJZ3BBP', 'A start that raises the recorded version does change the dump. Without this positive half, a comparison that is broken — reading the wrong file, comparing nothing to nothing — passes the first criterion perfectly.', 'must', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0521ZWYKTSPN8FX984QRDG2', '01M051AH8HRSBNM3HQ4EDKZEQH', 'After a report, the filesystem beneath and beside the plugin root is unchanged.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M05221FRMDZ1T6GNBPQRBXWS', '01M051AH8HRSBNM3HQ4EDKZEQH', 'The check creates a file or directory anywhere.', 'must_not', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M052230NFE5D4YN76Y8XCH5E', '01M051AM2H7N225EFYN5FJ12K3', 'The maintenance record documents the assumed plugin cache layout and what breaks if the host changes it. Manual because whether a written record actually explains the coupling is a judgement about prose; the automatable version — asserting the file contains certain words — would pass on a heading with nothing under it, which measures the wrong thing.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M05225Q4DMXXEZFYKHHP29XD', '01M051AM2H7N225EFYN5FJ12K3', 'Any file under the skills directory names the maintenance record''s path.', 'must_not', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524E0N4ND8DKZ5N0BGJFFS', '01M051FXVRATSJ9792ABHWG7ZH', 'The running Node satisfies `REQUIRED_NODE`, and `engines.node` equals it.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524FM7138ATHKDMN38HGGG', '01M051FZZSFG41WN4XKAXYESRJ', 'The test script invokes only the built-in runner, with no binary resolved from `node_modules`.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524HBPKPGKKYX42KKPJ39Y', '01M051G26K8RP8E6QZDKGAX8RB', 'A constructed directory of sibling version directories exists in the suite, and the check reports a verdict against it.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524K76BDESFGQ3H8KSA1PE', '01M051G46647GRRP5FMHZYGMX7', 'On the host, launching below the floor produces the floor message rather than the raw unknown-builtin-module error.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524N9RHH8DJ2G1T4YSQMVK', '01M051G66CR82G4ZNEQYCM5V83', 'Resolving from the module''s own URL names the directory the module was loaded from.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524QQ515E0J1KW7J078G3M', '01M051G8YMR8QX20G7SWFWNC4B', '`dependencies` and `devDependencies` are both empty.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524SHWXQHBN7QS7QATKDKA', '01M051GBWM7XJNH6W0HTCEN3M0', 'The check reads only the path it was given.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524VCM0R7758DB5VVD8CAA', '01M051GBWM7XJNH6W0HTCEN3M0', 'Any path a test resolves runs through the user''s home directory.', 'must_not', 1);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524X0GJ00QMKYP5P1ZMQ0D', '01M051GDWWCKCKECZJ1PQSW3TZ', 'The resolver reads no value from `process.env`.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0524YSBF3VN42ZN5GJPSZ52', '01M051GFMNV8HS8QM80BWP7S0T', 'No path this spec adds makes an outbound call.', 'must', 0);
INSERT INTO "acceptance_criterion" ("id", "requirement_id", "text", "polarity", "position") VALUES ('01M0527DQBQZNY61FXTFF9YT2A', '01M05271SG9G0BYGH25VE7SAKB', 'A test creates a temporary location, writes into it, and asserts it is gone afterwards.', 'must', 0);
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051TBFX7E95TB876RV668HE', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051TCZYEB1N87469MA9K0TE', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051TEJSB2XEGC0VBWR5V707', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051THCGRV518WES6VFC0QPB', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051TKHZA6VAENCTS8SPWJTS', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051TN2ATPKBMTAR0JJG73WM', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051TQPRFBD4RDE03W6HDSGA', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051TTAKHBRAHVKC5R8CSZ8D', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051WPWSFWJ6JKHX42F2WTRY', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051WRPMNHYZ5C6C372ABPKV', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051WTC2610QCJ66WZ4Z1FQ5', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051WVXVPHHPN2H39DD9Y4DR', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051WXGY1NBENQV371WWJQFK', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051WZ06D57PMQ676MFKJCE2', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051X0FKZ98Z9V5989SF2V2Y', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051X1YG1EMZ0QVMBZNGV51H', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051X3MJGQ517REPGWQJVHT0', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051X5PXSZW7XZECRN3G0QZN', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051X7BW2SS23NPB29ZHFKZ0', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051Z4AKAQ4JTHJ4HFEV1DPS', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051Z6PN842RF5DXJMPZF2WN', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051Z88XTCF9TD9KYBDFMZAX', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051ZAE9DGY9WJ6FQ8MGX661', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051ZBZR5PA0GE6NG2K27T8W', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051ZDJ4V1CHVZ3DXJ0YVRT1', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051ZFZ032E4Y7C71NS00Z60', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051ZHP7FFBBTNJZJFCGC3JC', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M051ZKFEXZFV2W0257B57DPX', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521HBXYWCMC53PZBYR7VR9', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521JYZ5YBG2BQHG4WQB5DB', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521NPJTBGKBW3F9JZ6AJN8', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521QD2BDHC8HGFVHEDZ5ES', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521S0F3NDQJGMG0VKX8XDR', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521V0D5326TK967Y2MG48A', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521WNR1F2KCHXEJRQVK3MA', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521YA35YV05139S92NQJN0', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0521ZWYKTSPN8FX984QRDG2', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M05221FRMDZ1T6GNBPQRBXWS', 'integration');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M052230NFE5D4YN76Y8XCH5E', 'manual');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M05225Q4DMXXEZFYKHHP29XD', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524E0N4ND8DKZ5N0BGJFFS', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524FM7138ATHKDMN38HGGG', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524HBPKPGKKYX42KKPJ39Y', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524K76BDESFGQ3H8KSA1PE', 'target');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524N9RHH8DJ2G1T4YSQMVK', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524QQ515E0J1KW7J078G3M', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524SHWXQHBN7QS7QATKDKA', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524VCM0R7758DB5VVD8CAA', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524X0GJ00QMKYP5P1ZMQ0D', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0524YSBF3VN42ZN5GJPSZ52', 'unit');
INSERT INTO "criterion_approach" ("criterion_id", "tag") VALUES ('01M0527DQBQZNY61FXTFF9YT2A', 'unit');
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QA1PG8SXW71QSF4X0KQE', '01M052PPSQZFX5YAE75ZZQKBTX', 'A constructed directory of sibling version directories exists in the suite, and the check reports a verdict against it.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QBMCWS17Y9WCWC1199ED', '01M052PPSQZFX5YAE75ZZQKBTX', 'A test creates a temporary location, writes into it, and asserts it is gone afterwards.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QE4FW69YVEG8DF4JRHA1', '01M052PPSQZFX5YAE75ZZQKBTX', 'The running Node satisfies `REQUIRED_NODE`, and `engines.node` equals it.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QFTP88S3SV8Z0SGTV4WV', '01M052PPSQZFX5YAE75ZZQKBTX', 'The test script invokes only the built-in runner, with no binary resolved from `node_modules`.', 'must', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QMWZX6MST5FF5SJQ8D25', '01M052PRC8AKV31ND1YD9TYMQ8', 'Resolving from the module''s own URL names the directory the module was loaded from.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QPV9CQSSXFSZSGE40EKP', '01M052PRC8AKV31ND1YD9TYMQ8', 'The resolver reads no value from `process.env`.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QR9X7FRR5VNQXPVGMTAT', '01M052PRC8AKV31ND1YD9TYMQ8', 'The check reads only the path it was given.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QSWM2SFHETFD6CV6XHZ5', '01M052PRC8AKV31ND1YD9TYMQ8', 'The check performs exactly one directory read per invocation.', 'must', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QVZ4429WFGAN69MAZCZY', '01M052PRC8AKV31ND1YD9TYMQ8', 'No path this spec adds makes an outbound call.', 'must', 4);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QXH6NFFA5SA1NFE5Y4Y5', '01M052PRC8AKV31ND1YD9TYMQ8', 'After a report, the filesystem beneath and beside the plugin root is unchanged.', 'must', 5);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052QZ1S278H0M1BCMYVJ48F', '01M052PRC8AKV31ND1YD9TYMQ8', 'The check recurses into subdirectories.', 'must_not', 6);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052R0NEBSDZY9KE18YJ62WK', '01M052PRC8AKV31ND1YD9TYMQ8', 'The check spawns a process or opens a socket.', 'must_not', 7);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052R2D9ZBR40NCEJY7ANF1Y', '01M052PRC8AKV31ND1YD9TYMQ8', 'The check creates a file or directory anywhere.', 'must_not', 8);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052R3ZN160W7VTBA69E9GNN', '01M052PRC8AKV31ND1YD9TYMQ8', 'Any path a test resolves runs through the user''s home directory.', 'must_not', 9);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052R9CT9QZXPHQP1FQM0M4X', '01M052PT0XX69QRRH81SA6WS0B', 'Given a root holding the running version and a higher-numbered sibling, the check reports a skew naming the higher version.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RAVS4JZP8HR1MDNNDGWM', '01M052PT0XX69QRRH81SA6WS0B', 'Given a root whose siblings are all lower than or equal to the running version, the check reports no skew.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RCEGFJVZQ959EX996TRN', '01M052PT0XX69QRRH81SA6WS0B', 'Given a root whose name does not parse as a version, the check reports could-not-check.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RE7EQDQ8DS32YBX60BB5', '01M052PT0XX69QRRH81SA6WS0B', 'Given a root with no sibling directories at all, the check reports could-not-check rather than no skew.', 'must', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RFV6MW9X2JRD8PB74S8R', '01M052PT0XX69QRRH81SA6WS0B', 'The three states — skew found, no skew, could not check — are distinguishable without parsing message text.', 'must', 4);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RHFYNA4Z7EBTFTSW9X2E', '01M052PT0XX69QRRH81SA6WS0B', '`dependencies` and `devDependencies` are both empty.', 'must', 5);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RK0W7EGK2XK69S0EPCTC', '01M052PT0XX69QRRH81SA6WS0B', 'The check reports a skew for a sibling lower than the running version. A reversed comparison satisfies the first criterion on any machine with more than one version installed, so the first criterion alone does not pin the direction.', 'must_not', 6);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RMVD075AE45MWYNJAWXX', '01M052PT0XX69QRRH81SA6WS0B', 'The check throws for an unreadable or unparseable root.', 'must_not', 7);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RPGFSXGRVMBDRV4T6WNK', '01M052PT0XX69QRRH81SA6WS0B', 'A check that could not run renders as no skew.', 'must_not', 8);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RRNYYCRKN50ZF86RTYHG', '01M052PVJ78F729JVQ3374SKS7', 'Two consecutive reports against a root that gained a higher sibling between them return different verdicts.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RTV9GJCTR4JY5NNY657Z', '01M052PVJ78F729JVQ3374SKS7', 'With the check deliberately memoised, the two-consecutive-reports criterion fails, and the failure has been observed and read rather than assumed.', 'control', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052RZT6HV2HP1RHYW0X639A', '01M052PX5CZY0C594F5DZ7DMEQ', 'The skew field is present in the response when no skew was found.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052S1C4034VWQYWQS2ZM7GJ', '01M052PX5CZY0C594F5DZ7DMEQ', 'A reported skew contains the running version, the newer version found, and a remedy naming a session restart.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052S31SKSFTMP5QWD5VGGN6', '01M052PX5CZY0C594F5DZ7DMEQ', 'A directory read that throws produces could-not-check and a successful tool response.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052S4N4YF8TAWXZ4NMB8AMF', '01M052PX5CZY0C594F5DZ7DMEQ', 'The skew sentence is composed in more than one place.', 'must_not', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052S6D4P10XDG6R2TT4E29G', '01M052PX5CZY0C594F5DZ7DMEQ', 'An error from the check propagates out of the tool handler.', 'must_not', 4);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052S8FPFR6581KF0941DEG2', '01M052PX5CZY0C594F5DZ7DMEQ', 'A version skew changes `ok`. The report''s `ok` states that the database is internally consistent, and under a skew it still is — the rows are sound and the reader is stale.', 'must_not', 5);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052SA77ZAZBV0A1VDPH7KJG', '01M052PX5CZY0C594F5DZ7DMEQ', 'A version skew appears in `entries`. That list is derived from the register and held to it by a parity test; a skew there is either a fabricated register entry or a broken derivation.', 'must_not', 6);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052SCJKDPTM2XZH0V72YTEG', '01M052PX5CZY0C594F5DZ7DMEQ', 'With the error handling removed, the criterion that a throwing read produces could-not-check fails, and that failure has been observed and read rather than assumed.', 'control', 7);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052SE84XB26KDG3CXVBM1P4', '01M052PYQDDQ7DH1QBGNZADESJ', 'The maintenance record documents the assumed plugin cache layout and what breaks if the host changes it.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052SGPKZGDG7HQXQZ0HK26Q', '01M052PYQDDQ7DH1QBGNZADESJ', 'Any file under the skills directory names the maintenance record''s path.', 'must_not', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052Z4RNRJAETPKB06KZE5AP', '01M052YZWZ5SEB1HYP9VY0TR72', 'A `check_integrity` call against a constructed root holding a higher sibling returns a skew field naming both versions, with `ok` still true.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M052Z6DN5EFBHM69HSXG3SZD', '01M052YZWZ5SEB1HYP9VY0TR72', 'A `check_integrity` call against a root that is not a version directory returns could-not-check, with `ok` still true.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HCW0ZZ1RDDGZ60WFFJYX', '01M053DWR0V5SD8P9SREMJZP1E', 'After `migrate()` on an empty database, the stamp table exists.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HEK7HE0S91PJVEBACT2M', '01M053DWR0V5SD8P9SREMJZP1E', '`migrate()` run twice against the same database applies the new migration once and leaves the table''s contents unchanged.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HG6EPK2WCRD2E38R5VTS', '01M053DWR0V5SD8P9SREMJZP1E', 'A database at the previous schema version gains the stamp table when migrated, and no other table''s contents change.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HHWJPCWAMK34RRYKCZYJ', '01M053DWR0V5SD8P9SREMJZP1E', 'A server whose target version is below the migrated database''s version returns `ahead: true` and serves the read-only tool set. This is the one-time lockout of older servers that AD2 accepted deliberately, asserted here rather than discovered in the field.', 'must', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HKBPPRRRQJRPWC8WDHDR', '01M053DWR0V5SD8P9SREMJZP1E', 'The table admits a second row.', 'must_not', 4);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HN3BRN2Z9PEQCGN4W10A', '01M053DWR0V5SD8P9SREMJZP1E', 'The migration inserts a row as part of applying itself. Migration SQL is static and cannot know the running version, so a row written there would carry a placeholder — and FR2 already says the value arrives on the next start.', 'must_not', 5);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HPW1ER9QQDKHNQDH2S59', '01M053DYJ1RV66CC6XZ9ZF89E1', 'The resolver returns the version stated in the plugin''s own manifest.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HRAPM39GMQ6BXYXGCSEH', '01M053DYJ1RV66CC6XZ9ZF89E1', 'The resolver returns a version when the plugin is loaded from a working tree, where no version directory exists.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HSV55179W454ZJQ9EPSW', '01M053DYJ1RV66CC6XZ9ZF89E1', 'The resolver derives the version from the containing directory''s name. That is the neighbour check''s mechanism, and it yields nothing in a working tree — which is the whole reason this resolver is separate from it.', 'must_not', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053HVBHVCRPXGZZXXY009S6', '01M053DYJ1RV66CC6XZ9ZF89E1', 'The resolver takes any value from `process.env`.', 'must_not', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053J07S15FFWTYAW6H2DBKE', '01M053E06Z2GM9R7STNT70P8VM', 'A database started by a server at version X carries X as its recorded plugin version.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053J1VX1E44W7NX322MPWR5', '01M053E06Z2GM9R7STNT70P8VM', 'A database migrated from before the stamp existed acquires the running version on the next start.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053J4Q38WKT494XXC3NWXAC', '01M053E06Z2GM9R7STNT70P8VM', 'A server at the recorded version leaves the row untouched.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053J6A95CDX39BK7B90B3NZ', '01M053E06Z2GM9R7STNT70P8VM', 'A server below the recorded version leaves the row untouched — the stamp never moves backwards.', 'must', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053J7XCXND5BQEKA1MV2KNJ', '01M053E06Z2GM9R7STNT70P8VM', 'A server above the recorded version replaces it.', 'must', 4);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053J9E34XJD6HT3TDY30XTT', '01M053E06Z2GM9R7STNT70P8VM', 'Two consecutive starts at the same version, with no planning data changed, produce byte-identical dumps.', 'must', 5);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053JAYJ6GK645AX7A1C3Q8M', '01M053E06Z2GM9R7STNT70P8VM', 'A start that raises the recorded version does change the dump. Without this positive half, a comparison that is broken — reading the wrong file, comparing nothing to nothing — passes the byte-identical criterion perfectly.', 'must', 6);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053JCHSC0W08S8JMYKMPR7J', '01M053E06Z2GM9R7STNT70P8VM', 'A read-only launch writes the stamp. The read-only path exists so a board can observe every registered project without touching any of them; a stamp written on observation would diverge every one of those projects from its committed dump, and the owner would find the guard refusing a commit in a repository they had not opened.', 'must_not', 7);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053JF4Q231SKY3272VMSRK3', '01M053E06Z2GM9R7STNT70P8VM', 'The row carries a value that differs between two runs of the same version. This is NFR3 stated where it can be checked: a timestamp column would satisfy every other criterion here and still diverge the dump on every start, which is the exact failure the requirement exists to prevent — while looking like good practice.', 'must_not', 8);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053JGSWTC56HXH67R1VYNF4', '01M053E06Z2GM9R7STNT70P8VM', 'With the write made unconditional, the criterion that a server at the recorded version leaves the row untouched fails, and that failure has been observed and read rather than assumed.', 'control', 9);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053MQ6SQHARJSV0C73RA6HK', '01M053E1Q8TDNDN5B78V98WD47', 'A database stamped above the running version produces a skew naming both versions.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053MRRYJXWJYYHMPR75YXMZ', '01M053E1Q8TDNDN5B78V98WD47', 'A database stamped at or below the running version produces no skew.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053MTFVYVRNY0XBDQ2P0S8S', '01M053E1Q8TDNDN5B78V98WD47', 'A database whose stamp table is absent produces could-not-check rather than no skew. This is the read-only launch against a project the release has never opened: the table will not be there, and no-skew would be a lie told confidently.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053MWBCVQPPGC75B9SP714Q', '01M053E1Q8TDNDN5B78V98WD47', 'A stamp comparison that throws yields could-not-check and the call it was made from succeeds.', 'must', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053MXWVEDK9RDKHVSD56H3X', '01M053E1Q8TDNDN5B78V98WD47', 'An absent or unreadable stamp renders as checked-and-found-no-skew.', 'must_not', 4);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053MZGCYSMG9KTYB84CJ708', '01M053E3BFMFVWFRFCEP2SFYPY', 'A database stamped above the running version writes a line to stderr when opened.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053N15HS8C67EDSM263FYWH', '01M053E3BFMFVWFRFCEP2SFYPY', 'The stamp skew reaches `check_integrity` through the same top-level field the neighbour skew uses.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053N2V6VZ1C8186MZN4QNVG', '01M053E3BFMFVWFRFCEP2SFYPY', 'The stamp skew''s sentence names the version running, the version recorded, and the remedy.', 'must', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053N4DHBCSY3Q2MSEVGN1BZ', '01M053E3BFMFVWFRFCEP2SFYPY', 'A clean open writes anything to stderr. This continues the rule the project already holds — a clean session is silent there — which is what makes any line that does appear worth reading.', 'must_not', 3);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053N605S3ZV8SQ30RNMVJJ6', '01M053E3BFMFVWFRFCEP2SFYPY', 'The stamp skew adds a second top-level field distinct from the neighbour''s. AD1 gave the skew one field beside `entries` and `orphans`; two fields would make a caller check both to learn whether anything is stale.', 'must_not', 4);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053N7SGB97EMC98VFRM71P7', '01M053E4Z5EW3VZ5FBQ4FNXWB4', 'A read-only launch''s integrity response carries the same skew field, in the same three states, as an ordinary one.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053N9JMBC9SQ86B8H39NVGE', '01M053E4Z5EW3VZ5FBQ4FNXWB4', 'A read-only launch reports a neighbour skew as well as a stamp skew. It never reaches `start()`, so both detectors have to be reachable from the read-only open for either to arrive.', 'must', 1);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053NBGJJ0V2N1D4CM558B6V', '01M053E4Z5EW3VZ5FBQ4FNXWB4', 'A read-only launch writes to the database or to the filesystem while reporting a skew.', 'must_not', 2);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053TPW5K7BT8W0GZKB99Q0Y', '01M053T5F2BHGEB0A3RBPX8Z8T', 'A database stamped by a newer server and then opened by an older one produces a skew on `check_integrity` naming both versions, and a line on stderr, in a single run exercising the table, the write, the comparison and the report.', 'must', 0);
INSERT INTO "story_criterion" ("id", "story_id", "text", "polarity", "position") VALUES ('01M053TS144GH9X2VNPRHD01Q7', '01M053T5F2BHGEB0A3RBPX8Z8T', 'Two consecutive full starts at the same version, with the neighbour check running as well, leave the committed dump byte-identical. This is not story 3''s comparison repeated: it adds the other epic''s detector to the run, which is where the two meet.', 'must', 1);
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QA1PG8SXW71QSF4X0KQE', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QBMCWS17Y9WCWC1199ED', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QE4FW69YVEG8DF4JRHA1', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QFTP88S3SV8Z0SGTV4WV', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QMWZX6MST5FF5SJQ8D25', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QPV9CQSSXFSZSGE40EKP', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QR9X7FRR5VNQXPVGMTAT', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QSWM2SFHETFD6CV6XHZ5', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QVZ4429WFGAN69MAZCZY', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QXH6NFFA5SA1NFE5Y4Y5', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052QZ1S278H0M1BCMYVJ48F', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052R0NEBSDZY9KE18YJ62WK', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052R2D9ZBR40NCEJY7ANF1Y', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052R3ZN160W7VTBA69E9GNN', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052R9CT9QZXPHQP1FQM0M4X', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RAVS4JZP8HR1MDNNDGWM', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RCEGFJVZQ959EX996TRN', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RE7EQDQ8DS32YBX60BB5', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RFV6MW9X2JRD8PB74S8R', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RHFYNA4Z7EBTFTSW9X2E', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RK0W7EGK2XK69S0EPCTC', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RMVD075AE45MWYNJAWXX', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RPGFSXGRVMBDRV4T6WNK', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RRNYYCRKN50ZF86RTYHG', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RTV9GJCTR4JY5NNY657Z', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052RZT6HV2HP1RHYW0X639A', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052S1C4034VWQYWQS2ZM7GJ', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052S31SKSFTMP5QWD5VGGN6', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052S4N4YF8TAWXZ4NMB8AMF', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052S6D4P10XDG6R2TT4E29G', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052S8FPFR6581KF0941DEG2', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052SA77ZAZBV0A1VDPH7KJG', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052SCJKDPTM2XZH0V72YTEG', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052SE84XB26KDG3CXVBM1P4', 'manual');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052SGPKZGDG7HQXQZ0HK26Q', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052Z4RNRJAETPKB06KZE5AP', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M052Z6DN5EFBHM69HSXG3SZD', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HCW0ZZ1RDDGZ60WFFJYX', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HEK7HE0S91PJVEBACT2M', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HG6EPK2WCRD2E38R5VTS', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HHWJPCWAMK34RRYKCZYJ', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HKBPPRRRQJRPWC8WDHDR', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HN3BRN2Z9PEQCGN4W10A', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HPW1ER9QQDKHNQDH2S59', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HRAPM39GMQ6BXYXGCSEH', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HSV55179W454ZJQ9EPSW', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053HVBHVCRPXGZZXXY009S6', 'unit');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053J07S15FFWTYAW6H2DBKE', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053J1VX1E44W7NX322MPWR5', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053J4Q38WKT494XXC3NWXAC', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053J6A95CDX39BK7B90B3NZ', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053J7XCXND5BQEKA1MV2KNJ', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053J9E34XJD6HT3TDY30XTT', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053JAYJ6GK645AX7A1C3Q8M', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053JCHSC0W08S8JMYKMPR7J', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053JF4Q231SKY3272VMSRK3', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053JGSWTC56HXH67R1VYNF4', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053MQ6SQHARJSV0C73RA6HK', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053MRRYJXWJYYHMPR75YXMZ', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053MTFVYVRNY0XBDQ2P0S8S', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053MWBCVQPPGC75B9SP714Q', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053MXWVEDK9RDKHVSD56H3X', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053MZGCYSMG9KTYB84CJ708', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053N15HS8C67EDSM263FYWH', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053N2V6VZ1C8186MZN4QNVG', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053N4DHBCSY3Q2MSEVGN1BZ', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053N605S3ZV8SQ30RNMVJJ6', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053N7SGB97EMC98VFRM71P7', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053N9JMBC9SQ86B8H39NVGE', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053NBGJJ0V2N1D4CM558B6V', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053TPW5K7BT8W0GZKB99Q0Y', 'integration');
INSERT INTO "story_criterion_approach" ("story_criterion_id", "tag") VALUES ('01M053TS144GH9X2VNPRHD01Q7', 'integration');
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M0539VBE1FDA0SHYHQ0EE1MM', '01M051G26K8RP8E6QZDKGAX8RB', 'a directory holding sibling version directories', '01M052QA1PG8SXW71QSF4X0KQE', 1, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M0539XKS6WDZ9VZB97P2MPF3', '01M05271SG9G0BYGH25VE7SAKB', 'a temporary filesystem location the suite can create, write to and remove', '01M052QBMCWS17Y9WCWC1199ED', 2, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M0539Z5KQ7KJEGHE8H62ESJM', '01M051FXVRATSJ9792ABHWG7ZH', 'Node 22.5.0 or later, matching `engines.node`', '01M052QE4FW69YVEG8DF4JRHA1', 3, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053A0RR8EPRZ1WRC4F8QNAY', '01M051FZZSFG41WN4XKAXYESRJ', 'the suite runs via the built-in `node --test` runner with no install step', '01M052QFTP88S3SV8Z0SGTV4WV', 4, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053A2VFY11ZH0S7MFKPJZPV', '01M051G66CR82G4ZNEQYCM5V83', 'the running plugin''s own directory is derivable from the module''s URL at runtime', '01M052QMWZX6MST5FF5SJQ8D25', 5, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053A4HDQ1JDQT73J4Y9FVRG', '01M051GDWWCKCKECZJ1PQSW3TZ', 'an environment variable naming the plugin root must not be required', '01M052QPV9CQSSXFSZSGE40EKP', 6, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053A67TEXRVHD6XP8S5K52S', '01M051GBWM7XJNH6W0HTCEN3M0', 'the suite must not require the real plugin cache or the user''s home directory', '01M052QR9X7FRR5VNQXPVGMTAT', 7, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053A8BFYBTQBQS2VW4EW2CV', '01M051AB08BP2SRQPB92XZE056', 'costs one bounded directory read per report', '01M052QSWM2SFHETFD6CV6XHZ5', 8, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AA7FC6HHDNNQ1RZRXSEM', '01M051GFMNV8HS8QM80BWP7S0T', 'network access must not be required', '01M052QVZ4429WFGAN69MAZCZY', 9, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ABVW3J4TWRGV929SZKE6', '01M051AH8HRSBNM3HQ4EDKZEQH', 'It creates no file and no directory, and writes nothing anywhere', '01M052QXH6NFFA5SA1NFE5Y4Y5', 10, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AGFA63XWQG1JXHG105E7', '01M051AB08BP2SRQPB92XZE056', 'no recursion', '01M052QZ1S278H0M1BCMYVJ48F', 11, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AJCWMF9RJ220PQGEG44N', '01M051AB08BP2SRQPB92XZE056', 'no process spawn, no network call', '01M052R0NEBSDZY9KE18YJ62WK', 12, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AM0YK1X0ND0CTV08V257', '01M051AH8HRSBNM3HQ4EDKZEQH', 'creates no file and no directory', '01M052R2D9ZBR40NCEJY7ANF1Y', 13, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ANWZ29F5GMW3338EDE21', '01M051GBWM7XJNH6W0HTCEN3M0', 'the user''s home directory', '01M052R3ZN160W7VTBA69E9GNN', 14, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AR8MS8SM0TDJM52ZQZT5', '01M050SJFST75N3GFZ64WNPTND', 'reports when a newer version of the plugin is installed alongside the version it is running from', '01M052R9CT9QZXPHQP1FQM0M4X', 15, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AT8X1QFD4VHAH7A91AS0', '01M050SJFST75N3GFZ64WNPTND', 'a newer version of the plugin is installed alongside', '01M052RAVS4JZP8HR1MDNNDGWM', 16, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AVW09CZPMGM7P858TJ0B', '01M050SWEGP80AYH58ZK0P47FG', 'when the plugin root is not a version directory, reporting could-not-check', '01M052RCEGFJVZQ959EX996TRN', 17, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AXCR3523D3SMHTY373QX', '01M050SWEGP80AYH58ZK0P47FG', 'reporting could-not-check rather than failing and rather than claiming no skew', '01M052RE7EQDQ8DS32YBX60BB5', 18, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053AYZ5EAM484C4875P61TA', '01M050T4QAWVSBRF17V42XSGVA', 'The report distinguishes checked-and-found-no-skew from could-not-check', '01M052RFV6MW9X2JRD8PB74S8R', 19, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053B0E03PCMXT4TA5XSH2J6', '01M051G8YMR8QX20G7SWFWNC4B', 'no runtime or development dependency may be required', '01M052RHFYNA4Z7EBTFTSW9X2E', 20, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053B5DFEZGJND9VA2FSC1DP', '01M050SJFST75N3GFZ64WNPTND', 'The server reports when a newer version of the plugin is installed alongside the version it is running from.', '01M052RK0W7EGK2XK69S0EPCTC', 21, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053B76CFZRE17GH88RWN38N', '01M050SWEGP80AYH58ZK0P47FG', 'completes without error', '01M052RMVD075AE45MWYNJAWXX', 22, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053B8SDZQSDEYT05961AYJK', '01M050T4QAWVSBRF17V42XSGVA', 'distinguishes checked-and-found-no-skew from could-not-check', '01M052RPGFSXGRVMBDRV4T6WNK', 23, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BAC3ATNHHPJ47R3MZBYP', '01M050SSS6FCCYF8A9QZWQZ7DY', 'evaluated at the moment it is reported, never cached from server start', '01M052RRNYYCRKN50ZF86RTYHG', 24, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BC9W9AHJ2088J7J3HTJ2', '01M050SSS6FCCYF8A9QZWQZ7DY', 'never cached from server start', '01M052RTV9GJCTR4JY5NNY657Z', 25, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BEFXNHH1AKN0Z5M4Y3SQ', '01M050T4QAWVSBRF17V42XSGVA', 'The report distinguishes checked-and-found-no-skew from could-not-check', '01M052RZT6HV2HP1RHYW0X639A', 26, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BJN9JYGBFNVCARCC9XQR', '01M050T1XRVWJYY3T5XXJNXTPB', 'names the version running, the newer version found, and what to do about it', '01M052S1C4034VWQYWQS2ZM7GJ', 27, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BMMMCBT2HSEZGXVZPSYM', '01M051AD1B1DTGSST2N23P7VY1', 'A skew check that cannot complete degrades to could-not-check', '01M052S31SKSFTMP5QWD5VGGN6', 28, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BPCEQKQ8RPCRY18YYEC4', '01M050T1XRVWJYY3T5XXJNXTPB', 'composed in one place rather than assembled separately by each caller', '01M052S4N4YF8TAWXZ4NMB8AMF', 29, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BRJFF6PZ2A7WQC9PKNW8', '01M051AD1B1DTGSST2N23P7VY1', 'It never fails the tool call and never stops the server', '01M052S6D4P10XDG6R2TT4E29G', 30, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053BYDDBAYV42QQV059PPSR', '01M051AD1B1DTGSST2N23P7VY1', 'It never fails the tool call and never stops the server', '01M052SCJKDPTM2XZH0V72YTEG', 31, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053C0HR3PJ83614T2E6174T', '01M051AM2H7N225EFYN5FJ12K3', 'The coupling to the host''s plugin cache layout is recorded in the project''s maintenance record', '01M052SE84XB26KDG3CXVBM1P4', 32, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053C23X4TCJ6J460YC9EXSS', '01M051AM2H7N225EFYN5FJ12K3', 'named from no skill file', '01M052SGPKZGDG7HQXQZ0HK26Q', 33, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053C5213YN6WPCN0NXK9ENX', '01M050SJFST75N3GFZ64WNPTND', 'The server reports when a newer version of the plugin is installed alongside', '01M052Z4RNRJAETPKB06KZE5AP', 34, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053C6NVPF0YKK017CNVD305', '01M050SWEGP80AYH58ZK0P47FG', 'reporting could-not-check rather than failing', '01M052Z6DN5EFBHM69HSXG3SZD', 35, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053XT2TRR2Y9YAN2PARBZ90', '01M050SM0JB72VCAW0BVRQCXG6', 'The database records the version', '01M053HCW0ZZ1RDDGZ60WFFJYX', 1, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053XW32X820BQXZT5K748JA', '01M051AFK6WGGR51HRDBJZ3BBP', 'leaves the committed dump byte-identical', '01M053HEK7HE0S91PJVEBACT2M', 2, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053XY3AGETNACVWY74Z46Z1', '01M050SM0JB72VCAW0BVRQCXG6', 'The database records the version of the plugin that last wrote to it', '01M053HG6EPK2WCRD2E38R5VTS', 3, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Y09H4H56R3N634MVC5FW', '01M050SM0JB72VCAW0BVRQCXG6', 'the version of the plugin that last wrote to it', '01M053HKBPPRRRQJRPWC8WDHDR', 4, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Y2XG4ZG02TSBYWNCS83A', '01M050SM0JB72VCAW0BVRQCXG6', 'the plugin that last wrote to it', '01M053HN3BRN2Z9PEQCGN4W10A', 5, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Y4KXP880W1PGR89BHBKB', '01M050SM0JB72VCAW0BVRQCXG6', 'the version of the plugin that last wrote to it', '01M053HPW1ER9QQDKHNQDH2S59', 6, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Y6918NGHH0SMXSZGR4JZ', '01M050SM0JB72VCAW0BVRQCXG6', 'The database records the version of the plugin that last wrote to it', '01M053HRAPM39GMQ6BXYXGCSEH', 7, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Y7ZZ03ACQW1J3ANRR89E', '01M050SM0JB72VCAW0BVRQCXG6', 'The database records the version', '01M053HSV55179W454ZJQ9EPSW', 8, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Y9V8DSQVY79QV63NP9J1', '01M051GDWWCKCKECZJ1PQSW3TZ', 'an environment variable naming the plugin root must not be required', '01M053HVBHVCRPXGZZXXY009S6', 9, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YBJVFN9SVD6F3A118XZB', '01M050SM0JB72VCAW0BVRQCXG6', 'The database records the version of the plugin that last wrote to it', '01M053J07S15FFWTYAW6H2DBKE', 10, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YH1Q833F2J8JWYYZZ1MD', '01M050SM0JB72VCAW0BVRQCXG6', 'The database records the version', '01M053J1VX1E44W7NX322MPWR5', 11, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YJTP33H1J8Y9JYDBBHPH', '01M050SYMMPF5JV138K22HFYK4', 'written only when the writing server''s version is greater than the version already recorded', '01M053J4Q38WKT494XXC3NWXAC', 12, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YMG8A9PPX7ZPQF5N55J9', '01M050SYMMPF5JV138K22HFYK4', 'written only when the writing server''s version is greater than the version already recorded', '01M053J6A95CDX39BK7B90B3NZ', 13, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YPAQGJZQXWSC9QBF3JB9', '01M050SYMMPF5JV138K22HFYK4', 'The recorded version is written only when the writing server''s version is greater than the version already recorded', '01M053J7XCXND5BQEKA1MV2KNJ', 14, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YRJ1JW6BHTKJK12NYB1N', '01M051AFK6WGGR51HRDBJZ3BBP', 'A session that neither upgrades the plugin nor changes planning data leaves the committed dump byte-identical', '01M053J9E34XJD6HT3TDY30XTT', 15, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YTQECAA56DDAPC0KZNK9', '01M050SYMMPF5JV138K22HFYK4', 'so an unchanged project produces an unchanged dump', '01M053JAYJ6GK645AX7A1C3Q8M', 16, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YWCSC8AMGB1ZMF254MKJ', '01M050SM0JB72VCAW0BVRQCXG6', 'never by one that only observes — a read-only launch leaves it as it found it', '01M053JCHSC0W08S8JMYKMPR7J', 17, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053YY2DVM3YKZRTVRPT1522', '01M051AFK6WGGR51HRDBJZ3BBP', 'leaves the committed dump byte-identical', '01M053JF4Q231SKY3272VMSRK3', 18, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Z06GZ9KNGJ6004VNEZN4', '01M050SYMMPF5JV138K22HFYK4', 'written only when the writing server''s version is greater than the version already recorded', '01M053JGSWTC56HXH67R1VYNF4', 19, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Z1YARA35HM80J6WVQ5R5', '01M050T08GZRV3X57AD61PWZ0N', 'The server reports when the plugin version recorded in the database is newer than its own.', '01M053MQ6SQHARJSV0C73RA6HK', 20, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053Z8TDFJC9B81JN13456ME', '01M050T08GZRV3X57AD61PWZ0N', 'when the plugin version recorded in the database is newer than its own', '01M053MRRYJXWJYYHMPR75YXMZ', 21, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZAH4KMAN1SX4W4RNCS78', '01M050T4QAWVSBRF17V42XSGVA', 'The report distinguishes checked-and-found-no-skew from could-not-check', '01M053MTFVYVRNY0XBDQ2P0S8S', 22, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZCZEKC38NHN4RJ4MMSCN', '01M051AD1B1DTGSST2N23P7VY1', 'A skew check that cannot complete degrades to could-not-check', '01M053MWBCVQPPGC75B9SP714Q', 23, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZENWCF089D0F2N6VWGW5', '01M050T4QAWVSBRF17V42XSGVA', 'distinguishes checked-and-found-no-skew from could-not-check', '01M053MXWVEDK9RDKHVSD56H3X', 24, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZGBSNKN93A5NX93B786H', '01M050T70SV8AT324K0BEZ2NY2', 'A skew known at database open is written to stderr, in the manner of the existing ahead-message.', '01M053MZGCYSMG9KTYB84CJ708', 25, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZJ8MPWWDZTSN4F72TM6A', '01M050T08GZRV3X57AD61PWZ0N', 'The server reports when the plugin version recorded in the database is newer than its own.', '01M053N15HS8C67EDSM263FYWH', 26, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZKZ27M97FW8QFJ9SYK9Y', '01M050T1XRVWJYY3T5XXJNXTPB', 'names the version running, the newer version found, and what to do about it', '01M053N2V6VZ1C8186MZN4QNVG', 27, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZNSCBSFP3FAN9QA6Z91N', '01M050T70SV8AT324K0BEZ2NY2', 'A skew known at database open is written to stderr', '01M053N4DHBCSY3Q2MSEVGN1BZ', 28, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZQB3ES7PVHEEA2EDE49S', '01M050T8WP5MTS43W8JCHRM0HM', 'A server launched read-only reports both skews.', '01M053N7SGB97EMC98VFRM71P7', 29, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZT8ECV0X8D7J6FETDBP5', '01M050T8WP5MTS43W8JCHRM0HM', 'reports both skews', '01M053N9JMBC9SQ86B8H39NVGE', 30, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZVYFE5VW871WHGCKRN8B', '01M051AH8HRSBNM3HQ4EDKZEQH', 'including under a read-only launch, whose whole guarantee is inertness', '01M053NBGJJ0V2N1D4CM558B6V', 31, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZXFG7SXEMMWHTNMQ9A02', '01M050T08GZRV3X57AD61PWZ0N', 'The server reports when the plugin version recorded in the database is newer than its own.', '01M053TPW5K7BT8W0GZKB99Q0Y', 32, NULL, NULL);
INSERT INTO "coverage" ("id", "requirement_id", "spec_fragment", "story_criterion_id", "position", "verified_at", "binding_hash") VALUES ('01M053ZYYAV8ASHX453HF0TGF6', '01M051AFK6WGGR51HRDBJZ3BBP', 'A session that neither upgrades the plugin nor changes planning data leaves the committed dump byte-identical', '01M053TS144GH9X2VNPRHD01Q7', 33, NULL, NULL);
INSERT INTO "session" ("id", "skill", "phase", "state", "superseded_by", "created_at", "updated_at") VALUES ('c9d2d7d0-539e-4543-8d15-3722aab48f6f', 'dpm:epics', 'Complete — both epics recorded', '{"skill":"dpm:epics","status":"complete","spec_id":"01M050N7S7YF827QD2CH0TVTFK","epics":[{"id":"01M052GWNT4AY7KXAR34WVS29E","slug":"neighbour-skew","stories":7,"criteria":37,"tasks":19,"coverage":35},{"id":"01M052GYJD9P02SK48ACH7SAX2","slug":"database-stamp","stories":7,"criteria":35,"tasks":19,"coverage":33}],"spec_amendments":["FR4 widened to state the single-composer rule","FR2 widened to state that only a writing server records the version","FR8 given exclusion: deferred"],"unbound_criteria":"Four, all tracing to AD1/AD2 rather than requirement text: skew must not change ok, must not appear in entries, older server returns ahead:true, stamp skew must not add a second field.","known_gaps":"ENV4 is target-tagged and verifiable only on a production host.","next":"Implementation via dpm:do, starting with epic 1 story 1. Epic 1 blocks epic 2."}', NULL, '2026-08-16T10:06:51.394Z', '2026-08-16T11:06:51.866Z');
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:architectural-decay', 'audit_dimension', 'Architectural decay', NULL, 1, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:consistency-rot', 'audit_dimension', 'Consistency rot', NULL, 2, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:dependency-debt', 'audit_dimension', 'Dependency & config debt', NULL, 5, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:documentation-drift', 'audit_dimension', 'Documentation drift', NULL, 9, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:error-observability', 'audit_dimension', 'Error handling & observability', NULL, 7, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:performance', 'audit_dimension', 'Performance', NULL, 6, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:security', 'audit_dimension', 'Security', NULL, 8, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:test-debt', 'audit_dimension', 'Test debt', NULL, 4, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:type-debt', 'audit_dimension', 'Type & contract debt', NULL, 3, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('disposition:fixed', 'disposition', 'Fixed', NULL, 1, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('disposition:left-alone', 'disposition', 'Left alone', NULL, 2, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('disposition:needs-you', 'disposition', 'Needs you', NULL, 4, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('disposition:unverified', 'disposition', 'Unverified', NULL, 3, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:adr-compliance', 'finding', 'ADR Compliance', NULL, 9, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:architectural-risks', 'finding', 'Architectural Risks', NULL, 4, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:dependency-risks', 'finding', 'Dependency Risks', NULL, 7, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:hidden-complexity', 'finding', 'Hidden Complexity', NULL, 3, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:missing-acceptance-criteria', 'finding', 'Missing Acceptance Criteria', NULL, 2, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:missing-test-coverage', 'finding', 'Missing Test Coverage', NULL, 10, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:scope-creep', 'finding', 'Scope Creep', NULL, 6, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:spec-compliance', 'finding', 'Spec Compliance', NULL, 8, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:testability-concerns', 'finding', 'Testability Concerns', NULL, 5, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('finding:unclear-requirements', 'finding', 'Unclear Requirements', NULL, 1, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('observation:codebase-discoveries', 'observation', 'Codebase Discoveries', 'Codebase discovery', 5, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('observation:complexity-underestimates', 'observation', 'Complexity Underestimates', 'Complexity underestimate', 4, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('observation:criteria-gaps', 'observation', 'Criteria Gaps', 'Criteria gap', 3, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('observation:patterns-worth-reusing', 'observation', 'Patterns Worth Reusing', 'Pattern worth reusing', 7, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('observation:scope-surprises', 'observation', 'Scope Surprises', 'Scope surprise', 2, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('observation:smooth-deliveries', 'observation', 'Smooth Deliveries', 'Smooth delivery', 1, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('observation:testing-gaps', 'observation', 'Testing Gaps', 'Testing gap', 6, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('severity:critical', 'severity', 'Critical', NULL, 1, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('severity:suggestion', 'severity', 'Suggestion', NULL, 3, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('severity:warning', 'severity', 'Warning', NULL, 2, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('architect', 'Margot', '🏗️', 'Software Architect', 'Systems thinker who sees the big picture. Obsessed with how pieces fit together and what happens at scale. Wary of short-term hacks that create long-term debt. Respects simplicity but knows when complexity is genuinely warranted. Has strong opinions on boundaries and separation of concerns.', 'Structured and precise. Thinks in terms of trade-offs — rarely says something is simply "good" or "bad" without qualifying the context. Draws analogies to explain architectural concepts. Will sketch out alternatives before recommending one.', 2, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('dev', 'Bella', '💻', 'Senior Developer', 'Practical and implementation-aware. Knows the difference between what sounds good in a design doc and what actually works in code. Flags hidden complexity that others miss. Values clean, readable code over clever abstractions. Has been burned by over-engineering and isn''t shy about saying so.', 'Candid and grounded. Speaks from implementation experience. Quick to point out "this is harder than it looks" or "this is simpler than we''re making it." Prefers concrete code examples over theoretical discussion.', 3, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('devops', 'Sable', '🚀', 'DevOps Engineer', 'Thinks about what happens after the code is written — deployment, monitoring, scaling, and incident response. Allergic to "works on my machine" solutions. Values automation, reproducibility, and operational simplicity. Knows that the hardest problems often aren''t in the code but in the environment.', 'Pragmatic and systems-oriented. Asks about deployment pipelines, environment differences, and failure modes. Speaks in terms of reliability, observability, and operational cost. Brings up infrastructure concerns early rather than late.', 7, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('pm', 'Jordan', '📋', 'Product Manager', 'Pragmatic and user-focused. Always asks "but does the user actually need this?" Pushes back on complexity that doesn''t serve a clear user outcome. Thinks in terms of value delivered, not technical elegance. Comfortable saying no to good ideas that don''t fit the current iteration.', 'Direct and outcome-oriented. Frames everything in terms of user value and business impact. Uses concrete examples and scenarios rather than abstract principles. Asks pointed questions that cut through ambiguity.', 1, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('qa', 'Tomas', '🔍', 'QA Engineer', 'Sceptical by nature — assumes things will break until proven otherwise. Thinks in edge cases, error states, and "what if the user does something unexpected." Not a pessimist, but a realist who has seen too many confident launches turn into fire drills. Values testability and observability.', 'Methodical and questioning. Asks "what happens when..." and "how do we know if..." Raises scenarios others haven''t considered. Frames concerns as risks with likelihood and impact rather than just objections.', 5, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('sm', 'Ren', '🔄', 'Scrum Master', 'Focused on process, delivery, and team dynamics. Watches for scope creep, blocked work, and unrealistic commitments. Pragmatic about methodology — uses what works, discards what doesn''t. Believes the best process is the one the team actually follows. Protective of sustainable pace.', 'Facilitative and action-oriented. Asks "what''s blocking this?" and "can we break this down smaller?" Steers discussions toward decisions and next steps. Flags when a conversation is going in circles and suggests concrete actions.', 9, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('test', 'Casey', '🧪', 'Test Engineer', 'Strategic about testing — thinks in terms of test pyramids, coverage boundaries, and what the right test approach is for each situation. Advocates for testing early (shift-left) and choosing the right level of test rather than testing everything at every level. Knows that too many integration tests slow the pipeline and too few miss real bugs. Pragmatic about when manual verification is the right call.', 'Asks "what type of test proves this works?" and "where''s the integration boundary?" Frames testing as a design decision, not an afterthought. Speaks in concrete terms about what to test at which level. Challenges both over-testing and under-testing.', 6, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('ux', 'Priya', '🎨', 'UX Designer', 'Empathetic advocate for the end user. Sees every feature through the lens of the person who has to use it. Questions assumptions about what users understand or will tolerate. Pushes for clarity, simplicity, and consistency in every interaction. Uncomfortable with "power user only" as a default answer.', 'Warm but firm on usability principles. Asks "how will the user feel when..." questions that reframe technical discussions. Uses journey mapping language — talks about flows, friction points, and moments of delight.', 4, NULL);
INSERT INTO "agent" ("name", "display_name", "icon", "role", "personality", "communication_style", "position", "retired_at") VALUES ('writer', 'Elli', '📝', 'Technical Writer', 'Believes that if you can''t explain it clearly, you don''t understand it well enough. Champions documentation, clear naming, and self-evident interfaces. Notices when jargon excludes people and when complexity could be simplified through better communication. Values consistency in terminology.', 'Clear and precise. Rephrases complex ideas in simpler terms. Points out naming inconsistencies and ambiguous language. Asks "what would a new team member understand from this?" Advocates for the reader, not the writer.', 8, NULL);
INSERT INTO "test_approach" ("tag", "kind", "position", "retired_at") VALUES ('feature', 'level', 3, NULL);
INSERT INTO "test_approach" ("tag", "kind", "position", "retired_at") VALUES ('integration', 'level', 2, NULL);
INSERT INTO "test_approach" ("tag", "kind", "position", "retired_at") VALUES ('manual', 'level', 4, NULL);
INSERT INTO "test_approach" ("tag", "kind", "position", "retired_at") VALUES ('target', 'level', 5, NULL);
INSERT INTO "test_approach" ("tag", "kind", "position", "retired_at") VALUES ('tdd', 'mode', 6, NULL);
INSERT INTO "test_approach" ("tag", "kind", "position", "retired_at") VALUES ('unit', 'level', 1, NULL);
INSERT INTO "number_sequence" ("kind", "parent_id", "next_value") VALUES ('adr', '01M050N7S7YF827QD2CH0TVTFK', 3);
INSERT INTO "number_sequence" ("kind", "parent_id", "next_value") VALUES ('coverage_matrix', '01M052GWNT4AY7KXAR34WVS29E', 1);
INSERT INTO "number_sequence" ("kind", "parent_id", "next_value") VALUES ('coverage_matrix', '01M052GYJD9P02SK48ACH7SAX2', 1);
INSERT INTO "number_sequence" ("kind", "parent_id", "next_value") VALUES ('epic', '01M050N7S7YF827QD2CH0TVTFK', 2);
INSERT INTO "number_sequence" ("kind", "parent_id", "next_value") VALUES ('library', NULL, 1);
INSERT INTO "number_sequence" ("kind", "parent_id", "next_value") VALUES ('spec', NULL, 1);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('blocks', 1, 1, NULL);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('builds_on', 0, 2, NULL);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('constrains', 0, 3, NULL);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('supersedes', 0, 4, NULL);
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052H7C4S8KEPWT34XP4VE8S', 'blocks', '01M052GWNT4AY7KXAR34WVS29E', NULL, '01M052GYJD9P02SK48ACH7SAX2', NULL);
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052Q39ZGEGWVYYYT8G44JJN', 'blocks', NULL, '01M052PPSQZFX5YAE75ZZQKBTX', NULL, '01M052PRC8AKV31ND1YD9TYMQ8');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052Q4SMBH5K4QN8EDA44N7R', 'blocks', NULL, '01M052PRC8AKV31ND1YD9TYMQ8', NULL, '01M052PT0XX69QRRH81SA6WS0B');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052Q6RXKPKN509CW3JDG51N', 'blocks', NULL, '01M052PT0XX69QRRH81SA6WS0B', NULL, '01M052PVJ78F729JVQ3374SKS7');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052Q8DZAECWQ168MFZF7BSN', 'blocks', NULL, '01M052PT0XX69QRRH81SA6WS0B', NULL, '01M052PX5CZY0C594F5DZ7DMEQ');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052ZAME993GN3E2EGQKYVTQ', 'blocks', NULL, '01M052PPSQZFX5YAE75ZZQKBTX', NULL, '01M052YZWZ5SEB1HYP9VY0TR72');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052ZCD287EYRT3Q1A3S0TV5', 'blocks', NULL, '01M052PRC8AKV31ND1YD9TYMQ8', NULL, '01M052YZWZ5SEB1HYP9VY0TR72');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052ZE4XMTAEYYD8058A77FY', 'blocks', NULL, '01M052PT0XX69QRRH81SA6WS0B', NULL, '01M052YZWZ5SEB1HYP9VY0TR72');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052ZG13PW4G06H8QGK8C2XN', 'blocks', NULL, '01M052PVJ78F729JVQ3374SKS7', NULL, '01M052YZWZ5SEB1HYP9VY0TR72');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052ZJ6FBDK7GGC17G2EN1B3', 'blocks', NULL, '01M052PX5CZY0C594F5DZ7DMEQ', NULL, '01M052YZWZ5SEB1HYP9VY0TR72');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M052ZM0RFQG11MWSQVE1QBCT', 'blocks', NULL, '01M052PYQDDQ7DH1QBGNZADESJ', NULL, '01M052YZWZ5SEB1HYP9VY0TR72');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053E9Z1SQWS8A1T57GJ9WFX', 'blocks', NULL, '01M053DWR0V5SD8P9SREMJZP1E', NULL, '01M053E06Z2GM9R7STNT70P8VM');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053EBPAAD40QJE6Z4TSPN7D', 'blocks', NULL, '01M053DWR0V5SD8P9SREMJZP1E', NULL, '01M053E1Q8TDNDN5B78V98WD47');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053ED6JDGFDM2444AB8HGRP', 'blocks', NULL, '01M053DYJ1RV66CC6XZ9ZF89E1', NULL, '01M053E06Z2GM9R7STNT70P8VM');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053EENFMQMTYM783JWH04ZC', 'blocks', NULL, '01M053E06Z2GM9R7STNT70P8VM', NULL, '01M053E1Q8TDNDN5B78V98WD47');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053EG7YWQ5YMJR8SFESZ7H5', 'blocks', NULL, '01M053E1Q8TDNDN5B78V98WD47', NULL, '01M053E3BFMFVWFRFCEP2SFYPY');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053EHPV45X8GM88FXR1EAQT', 'blocks', NULL, '01M053E3BFMFVWFRFCEP2SFYPY', NULL, '01M053E4Z5EW3VZ5FBQ4FNXWB4');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053TAQ1H6Y8CJE2QPN358M3', 'blocks', NULL, '01M053DWR0V5SD8P9SREMJZP1E', NULL, '01M053T5F2BHGEB0A3RBPX8Z8T');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053TCDSZQSWN9YB9JZMPM4Z', 'blocks', NULL, '01M053DYJ1RV66CC6XZ9ZF89E1', NULL, '01M053T5F2BHGEB0A3RBPX8Z8T');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053TEB4SFT994A7RSHSWJAS', 'blocks', NULL, '01M053E06Z2GM9R7STNT70P8VM', NULL, '01M053T5F2BHGEB0A3RBPX8Z8T');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053TGATEQPAVHWY2C32X0WC', 'blocks', NULL, '01M053E1Q8TDNDN5B78V98WD47', NULL, '01M053T5F2BHGEB0A3RBPX8Z8T');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053TJ11RQ0DYT0EA0MYKP19', 'blocks', NULL, '01M053E3BFMFVWFRFCEP2SFYPY', NULL, '01M053T5F2BHGEB0A3RBPX8Z8T');
INSERT INTO "dependency" ("id", "kind", "source_document_id", "source_story_id", "target_document_id", "target_story_id") VALUES ('01M053TNB9G9PH7SVJZW73PEA1', 'blocks', NULL, '01M053E4Z5EW3VZ5FBQ4FNXWB4', NULL, '01M053T5F2BHGEB0A3RBPX8Z8T');
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M04XXNBGJS968318HYM0WAM8', 'library', 'root', 1, NULL, 'lessons-learned', 'Promoted Retro Lessons', 'complete', 'In force. Each entry names the retro observation it came from; that observation is retired at source, so a lesson lives here or there and never in both.', NULL, NULL, NULL, NULL, '2026-08-16T09:19:53.712Z', '2026-08-16T09:19:53.712Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M050N7S7YF827QD2CH0TVTFK', 'spec', 'root', 1, NULL, 'version-skew-detection', 'Version skew detection', 'complete', 'Approved 2026-08-16. Sequenced so the neighbour check ships before the database stamp — the stamp alone would not have caught the incident that prompted the work.', NULL, NULL, NULL, NULL, '2026-08-16T10:07:43.399Z', '2026-08-16T10:36:46.162Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M051JPHA56Z9A2VTMBV2EWHY', 'adr', 'child', NULL, 1, 'skew-report-shape', 'Where a version skew appears in the integrity report', 'complete', NULL, '01M050N7S7YF827QD2CH0TVTFK', 'spec', NULL, NULL, '2026-08-16T10:23:48.778Z', '2026-08-16T10:25:13.372Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M051JRSZA8SNR8N4NXQRQ0ZY', 'adr', 'child', NULL, 2, 'stamp-storage', 'Where the database records the plugin that wrote it', 'complete', 'Accepted with the read-only lockout of older servers understood and accepted as a one-time cost, not discovered afterwards.', '01M050N7S7YF827QD2CH0TVTFK', 'spec', NULL, NULL, '2026-08-16T10:23:51.103Z', '2026-08-16T10:25:15.132Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M051JTJK59ZEVNHVWNJM286Q', 'adr', 'child', NULL, 3, 'neighbour-resolution', 'How the running plugin finds its neighbours', 'complete', NULL, '01M050N7S7YF827QD2CH0TVTFK', 'spec', NULL, NULL, '2026-08-16T10:23:52.915Z', '2026-08-16T10:25:16.758Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M052GWNT4AY7KXAR34WVS29E', 'epic', 'child', NULL, 1, 'neighbour-skew', 'Neighbour version skew', 'pending', 'Ships on its own — no schema change, no migration. Builds the verdict shape and the report channel that the stamp then extends.', '01M050N7S7YF827QD2CH0TVTFK', 'spec', NULL, NULL, '2026-08-16T10:40:18.106Z', '2026-08-16T10:40:18.106Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M052GYJD9P02SK48ACH7SAX2', 'epic', 'child', NULL, 2, 'database-stamp', 'The database stamp', 'pending', 'Adds a migration, and with it the one-time read-only lockout of older servers that the storage decision accepted deliberately.', '01M050N7S7YF827QD2CH0TVTFK', 'spec', NULL, NULL, '2026-08-16T10:40:20.045Z', '2026-08-16T10:40:20.045Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M052H3MGVYM6BK9Z8SK3DRA2', 'coverage_matrix', 'child', NULL, 1, 'neighbour-skew-coverage', 'Coverage — Neighbour version skew', 'pending', NULL, '01M052GWNT4AY7KXAR34WVS29E', 'epic', NULL, NULL, '2026-08-16T10:40:25.232Z', '2026-08-16T10:40:25.232Z', NULL, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M052H5DNCCA3W4TYE6Z5Z3NB', 'coverage_matrix', 'child', NULL, 1, 'database-stamp-coverage', 'Coverage — The database stamp', 'pending', NULL, '01M052GYJD9P02SK48ACH7SAX2', 'epic', NULL, NULL, '2026-08-16T10:40:27.061Z', '2026-08-16T10:40:27.061Z', NULL, NULL);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M052PPSQZFX5YAE75ZZQKBTX', '01M052GWNT4AY7KXAR34WVS29E', 'epic', 1, 'Test scaffolding for a plugin cache layout', 'pending', NULL, 0, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M052PRC8AKV31ND1YD9TYMQ8', '01M052GWNT4AY7KXAR34WVS29E', 'epic', 2, 'Resolve the running plugin''s version and its neighbours', 'pending', NULL, 1, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M052PT0XX69QRRH81SA6WS0B', '01M052GWNT4AY7KXAR34WVS29E', 'epic', 3, 'Compare versions and produce a three-state verdict', 'pending', NULL, 2, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M052PVJ78F729JVQ3374SKS7', '01M052GWNT4AY7KXAR34WVS29E', 'epic', 4, 'Re-evaluate on every report', 'pending', NULL, 3, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M052PX5CZY0C594F5DZ7DMEQ', '01M052GWNT4AY7KXAR34WVS29E', 'epic', 5, 'Report the verdict on check_integrity', 'pending', NULL, 4, 1);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M052PYQDDQ7DH1QBGNZADESJ', '01M052GWNT4AY7KXAR34WVS29E', 'epic', 6, 'Record the plugin-cache coupling', 'pending', NULL, 5, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M052YZWZ5SEB1HYP9VY0TR72', '01M052GWNT4AY7KXAR34WVS29E', 'epic', 7, 'Verify cross-story integration for Neighbour version skew', 'pending', NULL, 6, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M053DWR0V5SD8P9SREMJZP1E', '01M052GYJD9P02SK48ACH7SAX2', 'epic', 1, 'The stamp table and its migration', 'pending', NULL, 0, 1);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M053DYJ1RV66CC6XZ9ZF89E1', '01M052GYJD9P02SK48ACH7SAX2', 'epic', 2, 'Resolve this server''s own plugin version', 'pending', NULL, 1, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M053E06Z2GM9R7STNT70P8VM', '01M052GYJD9P02SK48ACH7SAX2', 'epic', 3, 'Write the stamp on increase', 'pending', NULL, 2, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M053E1Q8TDNDN5B78V98WD47', '01M052GYJD9P02SK48ACH7SAX2', 'epic', 4, 'Compare the stamp and produce a verdict', 'pending', NULL, 3, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M053E3BFMFVWFRFCEP2SFYPY', '01M052GYJD9P02SK48ACH7SAX2', 'epic', 5, 'Report the stamp skew on check_integrity and stderr', 'pending', NULL, 4, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M053E4Z5EW3VZ5FBQ4FNXWB4', '01M052GYJD9P02SK48ACH7SAX2', 'epic', 6, 'Report both skews under a read-only launch', 'pending', NULL, 5, 0);
INSERT INTO "story" ("id", "epic_id", "epic_kind", "number", "title", "status", "status_note", "position", "plan") VALUES ('01M053T5F2BHGEB0A3RBPX8Z8T', '01M052GYJD9P02SK48ACH7SAX2', 'epic', 7, 'Verify cross-story integration for The database stamp', 'pending', NULL, 6, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052XKAJDP0Z00ZHDM3BZ6D1', '01M052PPSQZFX5YAE75ZZQKBTX', 1, 'Build a helper that constructs a temporary directory of sibling version directories', 'The stand-in the neighbour check is pointed at. Addresses the fixture itself, not the check that reads it — and exists so that no test reaches the real plugin cache.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052XPGK78VXXHZCHXPZ4WRP', '01M052PPSQZFX5YAE75ZZQKBTX', 2, 'Build a helper that creates and removes a temporary location', 'Covers removal on failure as well as on success. A helper that only cleans up on the happy path leaves the next run reading the previous one''s directory.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052XR5R340860YK0BZXAMWM', '01M052PPSQZFX5YAE75ZZQKBTX', 3, 'Assert the project''s standing environmental constraints', 'The Node floor matching `engines.node`, and the test script invoking only the built-in runner. Addresses the assertions, not the constraints — both already hold and the point is that they keep holding.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052XTBHFGQEJWT07ZPT1BV9', '01M052PPSQZFX5YAE75ZZQKBTX', 4, 'Write tests for the scaffolding helpers', 'Covers the four criteria tagged `unit`. The helpers are themselves test machinery, so they need cover of their own — a fixture builder that silently builds nothing would make every test above it pass for the wrong reason.', 'pending', NULL, 3);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052XZ5FQJV46W24VBPP959V', '01M052PRC8AKV31ND1YD9TYMQ8', 1, 'Resolve the running plugin''s directory from the module''s own URL', 'Takes nothing from the process environment. Respects the decision that the host expands its plugin-root placeholder into launch arguments and does not guarantee it as a variable.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052Y0SB9AB3MC61HMK2Y76Q', '01M052PRC8AKV31ND1YD9TYMQ8', 2, 'Read the sibling directories, taking the root and the reader as parameters', 'One read, no recursion, nothing written. The reader is a parameter so the read can be counted and so the path read is the path given — which is what makes the bounded-cost and no-home-directory criteria checkable at all.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052Y2EDEMTYGMMY3C9F5B3D', '01M052PRC8AKV31ND1YD9TYMQ8', 3, 'Write tests for resolving the version and its neighbours', 'Covers the ten criteria tagged `unit` and `integration`, including the four rejections — recursion, process or socket, any write, and any path through the home directory.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052Y44WCN6R5RMBHMWZFHZD', '01M052PT0XX69QRRH81SA6WS0B', 1, 'Compare sibling names as versions using the existing parser', 'Addresses the direction of the comparison and the unparseable path. Reuses the parser the Node floor check already carries rather than adding a dependency for it.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052Y5SPEDM1Q77H38X3MAK8', '01M052PT0XX69QRRH81SA6WS0B', 2, 'Define the three-state verdict', 'Skew found, no skew, could not check — distinguishable from the value rather than from its message text, so that a reader branching on the state never has to parse prose.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052Y7VNN3ZHS7BFKNPYDPPB', '01M052PT0XX69QRRH81SA6WS0B', 3, 'Write tests for the comparison and the verdict', 'Covers the nine criteria tagged `unit`, including the rejection of a skew reported for a lower sibling — the case a reversed comparison would otherwise pass.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YAT5VW2RPK18FFM7XTM0', '01M052PVJ78F729JVQ3374SKS7', 1, 'Evaluate the check at report time rather than at start', 'Addresses the wiring, not the check. Nothing computed at module load or server start may be reused, because the upgrade this exists to catch lands after both.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YCP0CRVXQ04EMZG5RQB5', '01M052PVJ78F729JVQ3374SKS7', 2, 'Write tests for re-evaluation on every report', 'Covers both criteria tagged `integration`. The control is run rather than reasoned about: memoise the check, watch the two-report test fail, and read why before reverting.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YJXC6A7S699M6M9APEV6', '01M052PX5CZY0C594F5DZ7DMEQ', 1, 'Add the skew field to the integrity response', 'Beside `entries` and `orphans`, never inside either. Respects the decision that `ok` keeps meaning the data is sound and that the entries list stays derived from the register.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YMWY0QDAZF3NYKEBHY0J', '01M052PX5CZY0C594F5DZ7DMEQ', 2, 'Compose the skew sentence in one place', 'One producer, used by every channel that reports a skew. Addresses the wording, not the detection — two channels and two detectors is four chances for the sentence to be written four times and drift.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YPCCA2CCVXK0FK2PD6Z9', '01M052PX5CZY0C594F5DZ7DMEQ', 3, 'Contain failures inside the check', 'Addresses the error path, not the happy path. A read that throws becomes could-not-check and a successful response; nothing from the check reaches the caller as an error.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YRHE54YTYTKRGT773907', '01M052PX5CZY0C594F5DZ7DMEQ', 4, 'Write tests for reporting the verdict on check_integrity', 'Covers the eight criteria, including the two rejections that hold the report''s shape and the control on error handling — which is run and its failure read, not assumed.', 'pending', NULL, 3);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YW7CW4BKMCTSK2P1M0N9', '01M052PYQDDQ7DH1QBGNZADESJ', 1, 'Write the maintenance record for the plugin-cache coupling', 'What layout is assumed, and what breaks if the host changes it. The coupling is to something we do not own, so the record is the only place it is stated deliberately rather than implied by code.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052YYA7RCGB0NRPW98ZRZ5Z', '01M052PYQDDQ7DH1QBGNZADESJ', 2, 'Write the test that no skill file names the maintenance record''s path', 'Covers the criterion tagged `unit`. The record''s content is judged by reading it; what a test can hold is that no skill pays for a pointer to it on every invocation.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M052Z8Y6VZEE1AQ17N8ZMVP9', '01M052YZWZ5SEB1HYP9VY0TR72', 1, 'Write the end-to-end tests for neighbour skew reporting', 'A real tool call against a real constructed cache, covering the whole path the per-story tests only cover a link of. Both criteria name the state of `ok`, which is what shows the report''s separation holding end to end rather than only in the unit test written against the same assumption.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053Q7VHW3F3TWRPX6KNEZT2', '01M053DWR0V5SD8P9SREMJZP1E', 1, 'Write the migration adding the one-row stamp table', 'The DDL and the constraint that admits only one row. Addresses the table''s existence and shape, not the write path — the migration inserts nothing.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053Q9RXD8YPDQH8KDFRYFHP', '01M053DWR0V5SD8P9SREMJZP1E', 2, 'Raise the schema target version and register the migration', 'Addresses the ordered migration list and the version the server reports as its target. This is the change that puts older servers into the read-only branch, which AD2 accepted.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QC54GXFT03BAF0ZBPF8J', '01M053DWR0V5SD8P9SREMJZP1E', 3, 'Write tests for The stamp table and its migration', 'Covers the six criteria tagged integration, including the second-row rejection and the assertion that an older server degrades to read-only rather than failing.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QERVMPK1AJ6EP3WW2YQV', '01M053DYJ1RV66CC6XZ9ZF89E1', 1, 'Add a resolver reading the version from the plugin''s own manifest', 'Addresses the case the neighbour check cannot serve — a plugin loaded from a working tree, where no version directory exists to read a name off.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QGK5F5VAJ0NWA9TFMY64', '01M053DYJ1RV66CC6XZ9ZF89E1', 2, 'Write tests for Resolve this server''s own plugin version', 'Covers the four criteria tagged unit, including the two rejections: no directory-name derivation and no read of process.env.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QM1M27MHNMTC3JJTMY6A', '01M053E06Z2GM9R7STNT70P8VM', 1, 'Add the stamp write as a fourth step in start()', 'Addresses where the write sits in the fixed order: after migrate, because the table it writes to is created there. Scope is placement, not the increase condition.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QNNBHGNAP2THGKYEY35C', '01M053E06Z2GM9R7STNT70P8VM', 2, 'Gate the write on the running version exceeding the recorded one', 'Addresses FR2a — equal and lower both leave the row untouched, so the stamp never moves backwards and an unchanged project produces an unchanged dump.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QQAWHHHDWQZ992XRS2VW', '01M053E06Z2GM9R7STNT70P8VM', 3, 'Keep the write off the read-only path', 'A separate path from the increase gate: a correct gate still writes when a newer server merely observes a project. Addresses the read-only rejection only.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QRZTYW68600EMJX3N84M', '01M053E06Z2GM9R7STNT70P8VM', 4, 'Write tests for Write the stamp on increase', 'Covers the ten criteria tagged integration, including both dump comparisons and the control that makes the write unconditional and observes the untouched-row criterion fail.', 'pending', NULL, 3);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QV6AYMQ5DR2RENFQ0NFR', '01M053E1Q8TDNDN5B78V98WD47', 1, 'Read the recorded stamp, tolerating an absent table', 'Addresses the read and its failure mode. An absent table is the ordinary case for a project this release has never opened, so it is a value the reader returns rather than an error it raises.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QWYBGQQ7CHBGP3JW516Y', '01M053E1Q8TDNDN5B78V98WD47', 2, 'Compare with the running version and return the three-state verdict', 'Addresses the comparison and its three outcomes, reusing parseVersion. Scope is the verdict; how it is reported belongs to story 5.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053QYNY79Q7XK2JHW9KJN2H', '01M053E1Q8TDNDN5B78V98WD47', 3, 'Write tests for Compare the stamp and produce a verdict', 'Covers the five criteria tagged integration, including the rejection that an absent or unreadable stamp must not render as no-skew.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053R0T5EXQW2ND2TQ9AC6QD', '01M053E3BFMFVWFRFCEP2SFYPY', 1, 'Extend the single skew composer to cover the stamp skew', 'Addresses the sentence, not its transport. FR4 requires one composer, so this extends what epic 1 built rather than adding a second one.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053R2MMKT9YWYYNYJRWM3CT', '01M053E3BFMFVWFRFCEP2SFYPY', 2, 'Report the stamp skew through the field the neighbour skew already uses', 'Addresses the tool response. AD1 gave the skew one top-level field beside entries and orphans; this fills it from a second source rather than adding a field.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053R4TXY65DW58RXFWRT79H', '01M053E3BFMFVWFRFCEP2SFYPY', 3, 'Write the stderr line at database open', 'Addresses FR6 and the parity with the existing ahead-message. A clean open stays silent, which is what makes a line that does appear worth reading.', 'pending', NULL, 2);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053R6ZNT9HM0R049WFTXMSV', '01M053E3BFMFVWFRFCEP2SFYPY', 4, 'Write tests for Report the stamp skew on check_integrity and stderr', 'Covers the five criteria tagged integration, including the silence of a clean open and the rejection of a second top-level field.', 'pending', NULL, 3);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053R95F6BD03XE1NTDM48QW', '01M053E4Z5EW3VZ5FBQ4FNXWB4', 1, 'Reach both detectors from the read-only branch of open()', 'Addresses the path that never calls start(). Both detectors have to be reachable without it, and neither may write anything on the way.', 'pending', NULL, 0);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053RASNZEGX4AYAKD06FJQ9', '01M053E4Z5EW3VZ5FBQ4FNXWB4', 2, 'Write tests for Report both skews under a read-only launch', 'Covers the three criteria tagged integration, including the rejection that a read-only launch writes nothing while reporting a skew.', 'pending', NULL, 1);
INSERT INTO "task" ("id", "story_id", "number", "title", "description", "status", "status_note", "position") VALUES ('01M053TTJ84H73WSFQGTZE758F', '01M053T5F2BHGEB0A3RBPX8Z8T', 1, 'Write the cross-story integration tests for the database stamp', 'Covers behaviour spanning stories 1 to 6 — the end-to-end skew and the dump left undisturbed by both detectors together. Not a repeat of the per-story suites.', 'pending', NULL, 0);
