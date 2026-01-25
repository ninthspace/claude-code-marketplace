---
name: noteplan
description: Search and query NotePlan content across markdown files and Spaces (team/shared) SQLite database. Use when user wants to search NotePlan notes, find content, list notes, or fetch specific notes. Triggers on "/noteplan", "search NotePlan", "find in my notes", "search spaces", "list NotePlan notes".
---

# NotePlan Search

Search across **all** NotePlan content:
- **Notes folder** — standalone notes
- **Calendar folder** — daily/weekly/monthly notes  
- **Spaces** — team/shared notes (SQLite database)
- **iCloud** — if syncing via iCloud Drive

Results are sorted by **most recently modified first**.

**Note:** Folders starting with `@` (like `@Templates`, `@Trash`, `@Archive`) are excluded by default. Use `--all` to include them.

## Usage

Run the `npq.py` script in this skill's `scripts/` folder with the provided arguments:

```bash
python3 scripts/npq.py $ARGUMENTS --json
```

**Examples:**
- `/noteplan coffee` → Search for "coffee" in all notes
- `/noteplan --list --spaces` → List all Spaces notes  
- `/noteplan --get UUID` → Fetch full note by ID
- `/noteplan find me everything about coffee` → Search for "coffee"
- `/noteplan coffee --after 2025-01-01` → Notes about coffee modified after Jan 1
- `/noteplan meeting --after 2025-01-01 --before 2025-01-31` → January meetings

When user provides natural language like "find me everything about X", extract the search term and run the search.

## Date Interpretation for Calendar Queries

When the user asks about a specific date (e.g., "what's on my schedule for the 29th"):
- **No year specified** → assume current year
- **No month specified** → assume current month
- **Day only** (e.g., "the 15th") → assume current month and year

Examples:
- "January 29" → January 29 of current year (e.g., 20260129)
- "the 15th" → 15th of current month and year
- "March 3rd" → March 3 of current year

## Interpreting Results

**Search results** — Summarise what was found with titles and snippets. Offer to fetch full content of specific notes.

**Get note** — Display the note with a clear heading and the URL to open it:
```
## Note Title
📎 noteplan://x-callback-url/openNote?filename=...

<note content here>
```

**List** — Show notes grouped by source with their URLs.

## Script Flags

| Flag | Description |
|------|-------------|
| `"term"` | Search for term in all notes |
| `--md` | Markdown files only |
| `--spaces` | Spaces database only |
| `--list` | List all notes |
| `--get ID` | Fetch full note by ID/title/path |
| `--after DATE` | Only notes modified after DATE (YYYY-MM-DD) |
| `--before DATE` | Only notes modified before DATE (YYYY-MM-DD) |
| `--all` | Include @folders (@Templates, @Trash, @Archive) |
| `--json` | JSON output (always use) |

## Date Filtering Examples

```bash
# Notes modified after a date
python3 scripts/npq.py "coffee" --after 2025-01-01 --json

# Notes modified before a date  
python3 scripts/npq.py "meeting" --before 2025-01-15 --json

# Notes within a date range
python3 scripts/npq.py --list --after 2025-01-01 --before 2025-01-31 --json
```

Natural language triggers: "notes from last week", "what did I write in January", "recent notes about X"

## JSON Responses

**Search:** (sorted by most recent first)
```json
{"query": "...", "count": N, "results": [{"source": "spaces|markdown", "title": "...", "snippet": "...", "note_id": "uuid", "modified_at": "2025-01-21T10:30:00", "noteplan_url": "noteplan://x-callback-url/openNote?noteTitle=..."}]}
```

**Get:**
```json
{"found": true, "title": "...", "source": "...", "content": "...", "noteplan_url": "noteplan://x-callback-url/openNote?noteTitle=..."}
```

**List:** (sorted by most recent first)
```json
{"spaces": [{"id": "...", "title": "...", "type": "note|folder", "modified_at": "...", "noteplan_url": "..."}], "markdown": [{"path": "...", "filename": "...", "modified_at": "...", "noteplan_url": "..."}]}
```

The `noteplan_url` field provides a clickable link to open the note directly in NotePlan:
- Calendar notes (YYYYMMDD): `noteplan://x-callback-url/openNote?noteDate=YYYYMMDD`
- Regular notes: `noteplan://x-callback-url/openNote?filename=<relative-path>`
- Spaces notes (no file path): `noteplan://x-callback-url/openNote?noteTitle=<title>`

## Data Locations Searched (macOS)

**Markdown files:**
- `~/Library/Containers/co.noteplan.NotePlan3/.../Notes/` — standalone notes
- `~/Library/Containers/co.noteplan.NotePlan3/.../Calendar/` — daily/weekly notes
- `~/Library/Mobile Documents/iCloud~co~noteplan~NotePlan/Documents/` — iCloud sync

**Spaces database:**
- `~/Library/Containers/co.noteplan.NotePlan3/.../Caches/teamspace.db` — team/shared notes
