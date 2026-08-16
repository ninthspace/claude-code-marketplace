# Bringing the DPM board back to the CPM board's look and keys

**Number**: 01  
**Status**: complete — Consultation closed with the scope agreed in outline and handed to /dpm:spec.  

## What was actually different

The consultation started from an observation — that the two boards feel different — and was answered by reading both trees, `cpm/tools/board/` and `dpm/tools/board/`, rather than from memory. Four differences are real, and they are not all of the same kind.

**The keys.** The two boards share `q`, `l`, `o`, `t`, `c`, `space`, `←` and `→`, and diverge everywhere else. CPM binds `r` to refresh, `R` to clear cache, `a` to add a project, `x` to remove one and `z` to show or hide completed work. DPM binds `R` to a forced re-read, `ctrl+k` to clear the cache and `ctrl+n` to register a project; leaves unregister and plain refresh in the command palette with no key at all; adds `ctrl+f` for search and `ctrl+g` for coverage gaps, which CPM has no counterpart for; and has nothing at all for hiding completed work. `R` is the direct collision: it clears the cache on one board and re-reads every project on the other.

**The cursor.** CPM subclasses `OptionList` as `InverseOptionList` (`cpm/tools/board/board.py:192`), which post-processes the highlighted strip into a muted, row-coloured inverse bar, and pairs it with CSS neutralising Textual's own `option-list--option-highlighted` so the two do not fight. DPM has neither the subclass nor the CSS, so it shows the stock blue cursor block sitting over its state colours. This is the difference most likely to be what a user means by "it looks different".

**The pill.** CPM composes the projects row as a `Table.grid` with a right-justified cell, so the `● live` pill hugs the right edge whatever the column width (`cpm/tools/board/board_view.py:109`). DPM appends it to a plain string label (`_pill_suffix`), so it floats immediately after the progress figure. DPM also carries a `⚠` integrity badge in the same position, which CPM has no equivalent of.

**The previews.** CPM renders the panel beneath a column through `markdown_content()` (`cpm/tools/board/board.py:161`): a Rich `Markdown` rasterised to styled segments at the panel's own width and rebuilt as a Textual `Content`, so headings, emphasis, lists and tables draw and the text stays selectable — a live Rich `Markdown` renders to strips with no selection mapping, which is why the raster exists rather than a simpler renderable. A `HardBreakMarkdown` subclass rewrites soft breaks to hard ones in the token stream, and `on_resize` re-renders because the raster is width-specific. DPM has none of this: `document_preview` and `story_preview` return a plain `str` that goes straight into a `Static`, so the epic and story panels show raw markdown.

One difference was examined and deliberately left out of scope: the state-colour palettes. CPM keys its styles on `BLOCKED`, `IN_PROGRESS`, `EPICS_READY`, `SPEC_READY`, `COMPLETE` and `NO_ARTIFACTS`; DPM keys its own on `READY`, `IN_PROGRESS`, `BLOCKED`, `PENDING`, `COMPLETE`, `SUPERSEDED` and `WITHDRAWN`. These are different state vocabularies rather than different colour choices, and `superseded` and `withdrawn` have nothing on the CPM board to match. The colours agree for the states that exist in both, and that is as far as parity can honestly be taken.

## What was decided, and why

**CPM's keys are the base; DPM's extra capabilities take non-colliding keys.** The alternative on the table was literal parity — every shared key identical and everything DPM-only pushed into the command palette — and it was rejected because search and coverage gaps are the things a user opens the DPM board to do, and a palette-only capability costs two keystrokes forever. The rule chosen keeps muscle memory intact where the two boards do the same thing and spends new keyspace only where DPM does something CPM cannot.

The map that follows from it:

- `r` refresh, `R` clear cache, `a` register, `x` unregister, `z` show/hide retired — CPM's meanings, taken as given.
- `ctrl+r` for the forced re-read, evicted from `R` by the rule above. It is a DPM-only capability: CPM's board reads files and has nothing a stamp can miss, whereas DPM's cache is invalidated by the database's mtime and size, and a write that leaves both unchanged is invisible to it.
- `ctrl+f` search and `ctrl+g` gaps stay where they are — already non-colliding, already bound and in the palette.
- `ctrl+k` is freed by `R` reverting to CPM's meaning.
- `r` and `x` are new bindings rather than moved ones: refresh and unregister exist on the DPM board today as palette entries with no key.

**The epic and story previews render markdown, through CPM's renderer.** The rasteriser itself is a copy — `markdown_content`, `HardBreakMarkdown`, the panel-width helper and the `on_resize` re-render port across as they stand.

**The consequence that makes this more than a copy** is where the two boards get their preview text. CPM renders a markdown *file*. DPM builds its preview from rows returned by the tools — deliberately, because the projected `.md` is a rendering of those same rows and can be stale, absent or hand-edited into something the database does not say. But it builds them as *text*: a bare title line, the literal string `Acceptance criteria:`, and bullets written as `- `. Rasterised as markdown, the section prose renders correctly and that scaffolding renders as prose that happens to begin with a dash. So `document_preview` and `story_preview` change from emitting text to emitting markdown source — a heading for the title, a subheading per section, real list syntax — and `dpm/tools/board/tests/test_previews.py` asserts the current plain-text shapes and moves with them. That is the substantive work in this item; the renderer is the easy half.

**`z` hides everything retired, not only what is complete.** CPM's model has one retired state and DPM's has three, so "hide done" had to be decided rather than transcribed. The filter is `complete` plus the two in `status_model.RETIRED` — `superseded` and `withdrawn` — which is a grouping the model already names, so nothing new is invented for the board's benefit.

**A consequence worth stating before it is a surprise:** CPM's default is completed work *hidden*, and parity means the DPM board opens showing fewer rows than it does today. It also toasts on each press. Both behaviours come across.

**The look-and-feel fixes are ports, agreed without argument:** `InverseOptionList` and the CSS that neutralises Textual's default cursor, and the `Table.grid` composition that right-hugs the live pill. DPM's integrity badge sits in the same cell and has no CPM counterpart to conflict with.

## Open when it ended

The consultation closed on the scope being agreed in outline rather than on it being complete, and three things were never settled.

**Nobody swept for further divergence.** Four differences were found by reading the two boards for the things the observation pointed at — keys, cursor, pill, previews. `dpm/tools/board/board.py` is 1,871 lines against CPM's 1,321, and the surplus was not read line for line. The footer labels are one known-unchecked case: CPM's `o` reads "Open project" and DPM's reads "Open", and no one looked at whether the rest of the footer agrees.

**The palette was left alone.** Both boards replace Textual's system commands with their own provider, and DPM's list will read differently once five actions have keys — an entry whose key has just changed is a line of documentation that is now wrong. Whether the palette text is in scope was not asked.

**Nothing was said about how parity is kept.** Every difference here is one board drifting from the other after they were built from the same shape, and the work agreed closes today's gap without doing anything about the next one. Whether that matters — whether a test, a shared module or nothing at all is the right answer — is a question for the spec rather than a decision this conversation took.
