#!/usr/bin/env python3
"""
NotePlan Query (npq) - Search and query NotePlan notes.

Searches across:
- Notes folder (standalone notes)
- Calendar folder (daily/weekly/monthly notes)
- Spaces database (team/shared notes)
- iCloud Drive (if syncing)

Results sorted by most recently modified first.
"""
import argparse
import json
import os
import re
import sqlite3
import sys
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Generator
from urllib.parse import quote


# Default paths for NotePlan data
NOTEPLAN_CONTAINER = Path.home() / "Library/Containers/co.noteplan.NotePlan3/Data/Library/Application Support/co.noteplan.NotePlan3"
DEFAULT_NOTES_DIR = NOTEPLAN_CONTAINER / "Notes"
DEFAULT_CALENDAR_DIR = NOTEPLAN_CONTAINER / "Calendar"
DEFAULT_TEAMSPACE_DB = NOTEPLAN_CONTAINER / "Caches/teamspace.db"
ICLOUD_NOTEPLAN = Path.home() / "Library/Mobile Documents/iCloud~co~noteplan~NotePlan/Documents"


def parse_date_filters(after: str | None, before: str | None) -> tuple[datetime | None, datetime | None]:
    """Parse date filter arguments into datetime objects."""
    after_dt = None
    before_dt = None
    
    if after:
        try:
            after_dt = datetime.fromisoformat(after)
        except ValueError:
            try:
                after_dt = datetime.strptime(after, "%Y-%m-%d")
            except ValueError:
                print(f"Invalid date format for --after: {after}. Use YYYY-MM-DD", file=sys.stderr)
                sys.exit(1)
    
    if before:
        try:
            before_dt = datetime.fromisoformat(before)
        except ValueError:
            try:
                before_dt = datetime.strptime(before, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
            except ValueError:
                print(f"Invalid date format for --before: {before}. Use YYYY-MM-DD", file=sys.stderr)
                sys.exit(1)
    
    return after_dt, before_dt


def matches_date_filter(modified_at: str | None, after_dt: datetime | None, before_dt: datetime | None) -> bool:
    """Check if a modification date falls within the filter range."""
    if not after_dt and not before_dt:
        return True
    
    if not modified_at:
        return False
    
    try:
        mod_dt = datetime.fromisoformat(modified_at.replace('Z', '+00:00').split('+')[0])
    except ValueError:
        return False
    
    if after_dt and mod_dt < after_dt:
        return False
    if before_dt and mod_dt > before_dt:
        return False
    
    return True


@dataclass
class SearchResult:
    """A single search result."""
    source: str  # 'markdown' or 'spaces'
    title: str
    path: str
    snippet: str
    line_number: int | None = None
    note_id: str | None = None  # UUID for Spaces notes
    modified_at: str | None = None  # ISO timestamp for sorting
    noteplan_url: str | None = None  # x-callback-url to open in NotePlan


def make_noteplan_url(title: str | None = None, filename: str | None = None, relative_path: str | None = None) -> str:
    """Generate a noteplan:// x-callback-url to open a note.
    
    Uses filename parameter for most reliable note opening.
    - For calendar notes (YYYYMMDD), uses noteDate
    - For notes with a path, uses filename with relative path
    - Falls back to noteTitle if only title is available
    """
    # Check if it's a calendar note (filename like YYYYMMDD.md or YYYYMMDD.txt)
    if filename:
        stem = Path(filename).stem
        if re.match(r'^\d{8}$', stem):
            # It's a calendar note - use noteDate
            return f"noteplan://x-callback-url/openNote?noteDate={stem}"
    
    # Use filename with relative path if available (most reliable)
    if relative_path:
        # URL encode the path
        encoded_path = quote(relative_path, safe='')
        return f"noteplan://x-callback-url/openNote?filename={encoded_path}"
    
    if filename:
        encoded_filename = quote(filename, safe='')
        return f"noteplan://x-callback-url/openNote?filename={encoded_filename}"
    
    # Fall back to noteTitle for Spaces notes without filename
    if title:
        encoded_title = quote(title, safe='')
        return f"noteplan://x-callback-url/openNote?noteTitle={encoded_title}"
    
    return ""


def get_context_snippet(content: str, search_term: str, context_chars: int = 80) -> tuple[str, int | None]:
    """Extract a snippet of text around the search term with context."""
    search_lower = search_term.lower()
    content_lower = content.lower()
    
    pos = content_lower.find(search_lower)
    if pos == -1:
        return content[:150].replace('\n', ' ').strip() + "...", None
    
    # Find line number
    line_number = content[:pos].count('\n') + 1
    
    # Get context around match
    start = max(0, pos - context_chars)
    end = min(len(content), pos + len(search_term) + context_chars)
    
    snippet = content[start:end].replace('\n', ' ').strip()
    
    if start > 0:
        snippet = "..." + snippet
    if end < len(content):
        snippet = snippet + "..."
    
    return snippet, line_number


def search_markdown_files(search_term: str, notes_dir: Path, calendar_dir: Path,
                          after_dt: datetime | None = None, before_dt: datetime | None = None,
                          include_special: bool = False) -> Generator[SearchResult, None, None]:
    """Search through markdown files in Notes and Calendar directories."""
    search_lower = search_term.lower()
    
    dirs_to_search = []
    
    # Check local container paths
    if notes_dir.exists():
        dirs_to_search.append(("Notes", notes_dir))
    if calendar_dir.exists():
        dirs_to_search.append(("Calendar", calendar_dir))
    
    # Also check iCloud Drive if it exists
    if ICLOUD_NOTEPLAN.exists():
        icloud_notes = ICLOUD_NOTEPLAN / "Notes"
        icloud_calendar = ICLOUD_NOTEPLAN / "Calendar"
        if icloud_notes.exists():
            dirs_to_search.append(("iCloud/Notes", icloud_notes))
        if icloud_calendar.exists():
            dirs_to_search.append(("iCloud/Calendar", icloud_calendar))
    
    for label, directory in dirs_to_search:
        for filepath in directory.rglob("*"):
            if filepath.suffix.lower() in ('.md', '.txt') and filepath.is_file():
                # Skip @folders (templates, trash, archive) unless --all
                if not include_special:
                    rel_parts = filepath.relative_to(directory).parts
                    if any(part.startswith('@') for part in rel_parts):
                        continue
                
                try:
                    # Get file modification time first for date filtering
                    mtime = filepath.stat().st_mtime
                    modified_at = datetime.fromtimestamp(mtime).isoformat()
                    
                    # Apply date filter early
                    if not matches_date_filter(modified_at, after_dt, before_dt):
                        continue
                    
                    content = filepath.read_text(encoding='utf-8')
                    if search_lower in content.lower():
                        snippet, line_num = get_context_snippet(content, search_term)
                        
                        # Get title from first line or filename
                        first_line = content.split('\n')[0].strip()
                        title = first_line.lstrip('#').strip() if first_line else filepath.stem
                        
                        rel_path = filepath.relative_to(directory)
                        
                        yield SearchResult(
                            source='markdown',
                            title=title[:60] + "..." if len(title) > 60 else title,
                            path=f"{label}/{rel_path}",
                            snippet=snippet,
                            line_number=line_num,
                            modified_at=modified_at,
                            noteplan_url=make_noteplan_url(title=title, filename=filepath.name, relative_path=str(rel_path))
                        )
                except (UnicodeDecodeError, PermissionError):
                    continue


def search_spaces_db(search_term: str, db_path: Path,
                     after_dt: datetime | None = None, before_dt: datetime | None = None) -> Generator[SearchResult, None, None]:
    """Search through Spaces notes in the SQLite database."""
    if not db_path.exists():
        return
    
    search_lower = search_term.lower()
    
    try:
        conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, title, filename, content, note_path, modified_at 
            FROM notes 
            WHERE (note_type = 11 OR note_type IS NULL)
              AND (LOWER(content) LIKE ? OR LOWER(title) LIKE ?)
        """, (f'%{search_lower}%', f'%{search_lower}%'))
        
        for row in cursor.fetchall():
            note_id, title, filename, content, note_path, modified_at = row
            
            # Apply date filter
            if not matches_date_filter(modified_at, after_dt, before_dt):
                continue
            
            if content:
                snippet, line_num = get_context_snippet(content, search_term)
            else:
                snippet = "(no content)"
                line_num = None
            
            display_path = note_path.replace('%%NotePlanCloud%%/', '') if note_path else note_id
            
            yield SearchResult(
                source='spaces',
                title=title or filename or note_id,
                path=display_path,
                snippet=snippet,
                line_number=line_num,
                note_id=note_id,
                modified_at=modified_at,
                noteplan_url=make_noteplan_url(title=title or filename or note_id)
            )
        
        conn.close()
    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)


def get_note(identifier: str, db_path: Path, notes_dir: Path, calendar_dir: Path) -> dict:
    """Fetch full note content by ID, title, or path."""
    result = {"found": False, "identifier": identifier}
    
    # Try Spaces database first (by UUID)
    if db_path.exists():
        try:
            conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
            cursor = conn.cursor()
            
            # Try exact ID match
            cursor.execute("SELECT id, title, content, note_path FROM notes WHERE id = ?", (identifier,))
            row = cursor.fetchone()
            
            # Try title match if not found
            if not row:
                cursor.execute("SELECT id, title, content, note_path FROM notes WHERE LOWER(title) = LOWER(?)", (identifier,))
                row = cursor.fetchone()
            
            if row:
                note_id, title, content, note_path = row
                result = {
                    "found": True,
                    "source": "spaces",
                    "id": note_id,
                    "title": title,
                    "path": note_path.replace('%%NotePlanCloud%%/', '') if note_path else "",
                    "content": content or "",
                    "noteplan_url": make_noteplan_url(title=title) if title else None
                }
                conn.close()
                return result
            
            conn.close()
        except sqlite3.Error:
            pass
    
    # Build mapping of labels to directories
    dirs_map = {
        "Notes": notes_dir,
        "Calendar": calendar_dir,
        "iCloud/Notes": ICLOUD_NOTEPLAN / "Notes",
        "iCloud/Calendar": ICLOUD_NOTEPLAN / "Calendar",
    }
    
    # Check if identifier starts with a known label prefix (from search results)
    for label, base_dir in dirs_map.items():
        if identifier.startswith(label + "/"):
            rel_path = identifier[len(label) + 1:]  # Strip "Label/" prefix
            test_path = base_dir / rel_path
            if test_path.exists() and test_path.is_file():
                try:
                    content = test_path.read_text(encoding='utf-8')
                    first_line = content.split('\n')[0].strip()
                    title = first_line.lstrip('#').strip() if first_line else test_path.stem
                    return {
                        "found": True,
                        "source": "markdown",
                        "title": title,
                        "path": str(test_path),
                        "content": content,
                        "noteplan_url": make_noteplan_url(title=title, filename=test_path.name, relative_path=rel_path)
                    }
                except (UnicodeDecodeError, PermissionError):
                    pass
    
    # Try markdown files by direct path or filename
    for base_dir in [notes_dir, calendar_dir, ICLOUD_NOTEPLAN / "Notes", ICLOUD_NOTEPLAN / "Calendar"]:
        if not base_dir.exists():
            continue
        
        # Try direct path match
        test_path = base_dir / identifier
        if test_path.exists() and test_path.is_file():
            try:
                content = test_path.read_text(encoding='utf-8')
                first_line = content.split('\n')[0].strip()
                title = first_line.lstrip('#').strip() if first_line else test_path.stem
                return {
                    "found": True,
                    "source": "markdown",
                    "title": title,
                    "path": str(test_path),
                    "content": content,
                    "noteplan_url": make_noteplan_url(title=title, filename=test_path.name, relative_path=identifier)
                }
            except (UnicodeDecodeError, PermissionError):
                pass
        
        # Try finding by filename or title
        for filepath in base_dir.rglob("*.md"):
            if filepath.stem.lower() == identifier.lower() or filepath.name.lower() == identifier.lower():
                try:
                    content = filepath.read_text(encoding='utf-8')
                    first_line = content.split('\n')[0].strip()
                    title = first_line.lstrip('#').strip() if first_line else filepath.stem
                    rel_path = str(filepath.relative_to(base_dir))
                    return {
                        "found": True,
                        "source": "markdown",
                        "title": title,
                        "path": str(filepath),
                        "content": content,
                        "noteplan_url": make_noteplan_url(title=title, filename=filepath.name, relative_path=rel_path)
                    }
                except (UnicodeDecodeError, PermissionError):
                    pass
        
        # Also try .txt files
        for filepath in base_dir.rglob("*.txt"):
            if filepath.stem.lower() == identifier.lower() or filepath.name.lower() == identifier.lower():
                try:
                    content = filepath.read_text(encoding='utf-8')
                    first_line = content.split('\n')[0].strip()
                    title = first_line.lstrip('#').strip() if first_line else filepath.stem
                    rel_path = str(filepath.relative_to(base_dir))
                    return {
                        "found": True,
                        "source": "markdown",
                        "title": title,
                        "path": str(filepath),
                        "content": content,
                        "noteplan_url": make_noteplan_url(title=title, filename=filepath.name, relative_path=rel_path)
                    }
                except (UnicodeDecodeError, PermissionError):
                    pass
    
    return result


def list_notes(spaces_only: bool, md_only: bool, db_path: Path, notes_dir: Path, calendar_dir: Path,
               as_json: bool = False, after_dt: datetime | None = None, before_dt: datetime | None = None,
               include_special: bool = False):
    """List all notes."""
    result = {"spaces": [], "markdown": []}
    
    if not md_only:
        if db_path.exists():
            try:
                conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
                cursor = conn.cursor()
                cursor.execute("""
                    SELECT id, title, note_type, note_path, modified_at 
                    FROM notes 
                    ORDER BY modified_at DESC
                """)
                for note_id, title, note_type, note_path, modified_at in cursor.fetchall():
                    if not matches_date_filter(modified_at, after_dt, before_dt):
                        continue
                    
                    path_display = note_path.replace('%%NotePlanCloud%%/', '') if note_path else ""
                    result["spaces"].append({
                        "id": note_id,
                        "title": title,
                        "type": "folder" if note_type == 10 else "note",
                        "path": path_display,
                        "modified_at": modified_at,
                        "noteplan_url": make_noteplan_url(title=title) if title and note_type != 10 else None
                    })
                conn.close()
            except sqlite3.Error as e:
                if not as_json:
                    print(f"  Database error: {e}", file=sys.stderr)
    
    if not spaces_only:
        dirs_to_list = []
        if notes_dir.exists():
            dirs_to_list.append(("Notes", notes_dir))
        if calendar_dir.exists():
            dirs_to_list.append(("Calendar", calendar_dir))
        if ICLOUD_NOTEPLAN.exists():
            if (ICLOUD_NOTEPLAN / "Notes").exists():
                dirs_to_list.append(("iCloud/Notes", ICLOUD_NOTEPLAN / "Notes"))
            if (ICLOUD_NOTEPLAN / "Calendar").exists():
                dirs_to_list.append(("iCloud/Calendar", ICLOUD_NOTEPLAN / "Calendar"))
        
        md_files = []
        for label, directory in dirs_to_list:
            for filepath in directory.rglob("*"):
                if filepath.suffix.lower() in ('.md', '.txt') and filepath.is_file():
                    # Skip @folders (templates, trash, archive) unless --all
                    if not include_special:
                        rel_parts = filepath.relative_to(directory).parts
                        if any(part.startswith('@') for part in rel_parts):
                            continue
                    
                    rel_path = filepath.relative_to(directory)
                    mtime = filepath.stat().st_mtime
                    modified_at = datetime.fromtimestamp(mtime).isoformat()
                    
                    if not matches_date_filter(modified_at, after_dt, before_dt):
                        continue
                    
                    md_files.append({
                        "path": f"{label}/{rel_path}",
                        "filename": filepath.name,
                        "modified_at": modified_at,
                        "noteplan_url": make_noteplan_url(title=filepath.stem, filename=filepath.name, relative_path=str(rel_path))
                    })
        
        md_files.sort(key=lambda x: x["modified_at"], reverse=True)
        result["markdown"] = md_files
    
    if as_json:
        return result
    
    # Human-readable output
    date_range_info = ""
    if after_dt or before_dt:
        parts = []
        if after_dt:
            parts.append(f"after {after_dt.strftime('%Y-%m-%d')}")
        if before_dt:
            parts.append(f"before {before_dt.strftime('%Y-%m-%d')}")
        date_range_info = f" ({', '.join(parts)})"
    
    if not md_only:
        print(f"\n=== Spaces Notes{date_range_info} (most recent first) ===\n")
        if result["spaces"]:
            for note in result["spaces"]:
                type_indicator = "📁" if note["type"] == "folder" else "📄"
                mod_date = note.get("modified_at", "")[:10] if note.get("modified_at") else ""
                print(f"  {type_indicator} {mod_date}  {note['title']:<40}")
        else:
            print("  (no spaces notes found)")
    
    if not spaces_only:
        print(f"\n=== Markdown Notes{date_range_info} (most recent first) ===\n")
        if result["markdown"]:
            for note in result["markdown"]:
                mod_date = note.get("modified_at", "")[:10] if note.get("modified_at") else ""
                print(f"  📄 {mod_date}  {note['path']}")
        else:
            print("  (no markdown notes found)")


def format_result(result: SearchResult, use_color: bool = True) -> str:
    """Format a search result for display."""
    if use_color:
        source_color = "\033[36m" if result.source == 'spaces' else "\033[33m"
        reset = "\033[0m"
        bold = "\033[1m"
        dim = "\033[2m"
    else:
        source_color = reset = bold = dim = ""
    
    source_tag = f"[{result.source.upper()}]"
    line_info = f" (line {result.line_number})" if result.line_number else ""
    id_info = f"\n    {dim}id: {result.note_id}{reset}" if result.note_id else ""
    
    mod_date = ""
    if result.modified_at:
        try:
            date_str = result.modified_at[:10] if len(result.modified_at) >= 10 else result.modified_at
            mod_date = f" {dim}[{date_str}]{reset}"
        except:
            pass
    
    return f"""{source_color}{source_tag}{reset} {bold}{result.title}{reset}{mod_date}
    {result.path}{line_info}{id_info}
    {result.snippet}
"""


def main():
    parser = argparse.ArgumentParser(
        description="Search NotePlan notes (markdown + Spaces)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    npq "meeting notes"           Search all sources
    npq "todo" --md               Search markdown files only
    npq "project" --spaces        Search Spaces only
    npq --list                    List all notes
    npq -c "search"               Case-sensitive search
    npq --get UUID                Fetch full note by Spaces ID
    npq --get "Note Title"        Fetch note by title
    npq --get Notes/myfile.md     Fetch markdown file by path
    npq "search" --json           JSON output (for AI tools)
    npq "coffee" --after 2025-01-01          Notes modified after date
    npq "coffee" --before 2025-01-15         Notes modified before date
    npq --list --after 2025-01-01 --before 2025-01-31   Date range
    npq "template" --all          Include @Templates, @Trash, @Archive
        """
    )
    
    parser.add_argument("query", nargs="?", help="Search term")
    parser.add_argument("--md", action="store_true", help="Search markdown files only")
    parser.add_argument("--spaces", action="store_true", help="Search Spaces (SQLite) only")
    parser.add_argument("--list", "-l", action="store_true", help="List all notes")
    parser.add_argument("--get", "-g", metavar="ID", help="Fetch full note by ID, title, or path")
    parser.add_argument("--json", "-j", action="store_true", help="Output as JSON (for AI tools)")
    parser.add_argument("--after", metavar="DATE", help="Only notes modified after DATE (YYYY-MM-DD)")
    parser.add_argument("--before", metavar="DATE", help="Only notes modified before DATE (YYYY-MM-DD)")
    parser.add_argument("--all", "-a", action="store_true", help="Include @folders (templates, trash, archive)")
    parser.add_argument("--no-color", action="store_true", help="Disable colored output")
    parser.add_argument("-c", "--case-sensitive", action="store_true", help="Case-sensitive search")
    parser.add_argument("--db", type=Path, default=DEFAULT_TEAMSPACE_DB, help="Path to teamspace.db")
    parser.add_argument("--notes-dir", type=Path, default=DEFAULT_NOTES_DIR, help="Path to Notes directory")
    parser.add_argument("--calendar-dir", type=Path, default=DEFAULT_CALENDAR_DIR, help="Path to Calendar directory")
    
    args = parser.parse_args()
    
    use_color = not args.no_color and sys.stdout.isatty() and not args.json
    
    # Parse date filters
    after_dt, before_dt = parse_date_filters(args.after, args.before)
    
    # Handle --get
    if args.get:
        result = get_note(args.get, args.db, args.notes_dir, args.calendar_dir)
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            if result["found"]:
                print(f"\n=== {result['title']} ===")
                print(f"Source: {result['source']}")
                print(f"Path: {result['path']}")
                print("\n" + result['content'])
            else:
                print(f"Note not found: {args.get}")
        return
    
    # Handle --list
    if args.list:
        if args.json:
            result = list_notes(
                spaces_only=args.spaces,
                md_only=args.md,
                db_path=args.db,
                notes_dir=args.notes_dir,
                calendar_dir=args.calendar_dir,
                as_json=True,
                after_dt=after_dt,
                before_dt=before_dt,
                include_special=args.all
            )
            print(json.dumps(result, indent=2))
        else:
            list_notes(
                spaces_only=args.spaces,
                md_only=args.md,
                db_path=args.db,
                notes_dir=args.notes_dir,
                calendar_dir=args.calendar_dir,
                after_dt=after_dt,
                before_dt=before_dt,
                include_special=args.all
            )
        return
    
    # Search requires a query
    if not args.query:
        parser.print_help()
        return
    
    results = []
    
    if not args.spaces:
        results.extend(search_markdown_files(args.query, args.notes_dir, args.calendar_dir, after_dt, before_dt, args.all))
    
    if not args.md:
        results.extend(search_spaces_db(args.query, args.db, after_dt, before_dt))
    
    # Sort by modified_at descending
    results.sort(key=lambda r: r.modified_at or "", reverse=True)
    
    if not results:
        if args.json:
            print(json.dumps({"query": args.query, "count": 0, "results": []}))
        else:
            print(f"No results found for: {args.query}")
        return
    
    if args.json:
        output = {
            "query": args.query,
            "count": len(results),
            "results": [asdict(r) for r in results]
        }
        print(json.dumps(output, indent=2))
    else:
        print(f"\nFound {len(results)} result(s) for '{args.query}':\n")
        for result in results:
            print(format_result(result, use_color))


if __name__ == "__main__":
    main()
