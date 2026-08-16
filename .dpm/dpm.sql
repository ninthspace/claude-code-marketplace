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
INSERT INTO "library_document" ("document_id", "document_kind", "doc_type", "source") VALUES ('01M04XXNBGJS968318HYM0WAM8', 'library', 'coding-standards', 'docs/cpm/library/lessons-learned.md — carried over from CPM at the 2026-08-16 migration, with its amendment blocks folded into the body');
INSERT INTO "library_scope" ("document_id", "scope") VALUES ('01M04XXNBGJS968318HYM0WAM8', 'do');
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:architectural-decay', 'audit_dimension', 'Architectural decay', NULL, 1, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:consistency-rot', 'audit_dimension', 'Consistency rot', NULL, 2, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:dependency-debt', 'audit_dimension', 'Dependency & config debt', NULL, 5, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:documentation-drift', 'audit_dimension', 'Documentation drift', NULL, 9, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:error-observability', 'audit_dimension', 'Error handling & observability', NULL, 7, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:performance', 'audit_dimension', 'Performance', NULL, 6, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:security', 'audit_dimension', 'Security', NULL, 8, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:test-debt', 'audit_dimension', 'Test debt', NULL, 4, NULL);
INSERT INTO "taxonomy" ("id", "domain", "name", "singular", "position", "retired_at") VALUES ('audit_dimension:type-debt', 'audit_dimension', 'Type & contract debt', NULL, 3, NULL);
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
INSERT INTO "number_sequence" ("kind", "parent_id", "next_value") VALUES ('library', NULL, 1);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('blocks', 1, 1, NULL);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('builds_on', 0, 2, NULL);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('constrains', 0, 3, NULL);
INSERT INTO "dependency_kind" ("kind", "gates_work", "position", "retired_at") VALUES ('supersedes', 0, 4, NULL);
INSERT INTO "document" ("id", "kind", "numbering", "number", "sequence", "slug", "title", "status", "status_note", "parent_id", "parent_kind", "archived_at", "commit_sha", "created_at", "updated_at", "retro_waived_at", "retro_waived_reason") VALUES ('01M04XXNBGJS968318HYM0WAM8', 'library', 'root', 1, NULL, 'lessons-learned', 'Promoted Retro Lessons', 'complete', 'In force. Each entry names the retro observation it came from; that observation is retired at source, so a lesson lives here or there and never in both.', NULL, NULL, NULL, NULL, '2026-08-16T09:19:53.712Z', '2026-08-16T09:19:53.712Z', NULL, NULL);
