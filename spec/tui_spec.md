# TUI (Terminal User Interface) Specification

## Overview

The TUI provides an interactive directory selector featuring fuzzy search, keyboard navigation, and responsive layout that adapts to terminal window size changes.

## Terminal Size

### Detection Priority

1. Query terminal for current dimensions (rows × columns)
2. Fall back to environment variables if available
3. Default to 80 columns × 24 rows if detection fails

### Dynamic Layout

Layout dimensions are recalculated on every render:

- **Header**: 3 lines (title + separator + search input)
- **Footer**: 2 lines (separator + help text)
- **List area**: Remaining vertical space

## Resize Handling

When terminal is resized:

1. Interrupt any blocking input read
2. Query new terminal dimensions
3. Re-render UI with updated layout
4. Preserve selection index and scroll position

## Display Layout

### Two-Layer Entry Display

Each directory entry has two display components:

**Primary Layer (left-aligned):**
- Selection indicator (`→` for selected, space for others)
- Directory icon (📁)
- Directory name with fuzzy match highlighting
- Truncated with ellipsis (`…`) if too long

**Secondary Layer (right-aligned):**
- Relative timestamp ("just now", "2h ago", "3d ago")
- Fuzzy match score (e.g., "3.2")
- Only shown when sufficient space exists

### Layout Rules

```
[→] [📁] [directory-name.............] [timestamp, score]
     ^                                  ^
     left-aligned                       right-aligned
```

- Metadata is anchored to terminal right edge
- Path expands to fill available space
- If path would overlap metadata, metadata is hidden
- If path is truncated, metadata is hidden

## Path Truncation

When paths exceed available space:

1. Calculate maximum visible characters
2. Preserve formatting tokens (don't split `{b}...{/b}`)
3. Truncate at character boundary
4. Append ellipsis character (`…`)

Example:
```
Full:      "2025-11-29-very-long-project-name"
Truncated: "2025-11-29-very-long-pro…"
```

## Metadata Display

### Relative Timestamps

| Age | Display |
|-----|---------|
| < 1 minute | "just now" |
| < 1 hour | "Xm ago" |
| < 24 hours | "Xh ago" |
| < 7 days | "Xd ago" |
| ≥ 7 days | "Xw ago" |

### Score Format

- Single decimal precision: "3.2", "10.5"
- Displayed after timestamp, separated by comma

### Metadata Positioning

```
metadata_start = terminal_width - metadata_length - margin
show_metadata = path_end + gap < metadata_start
```

## Visual Layout

### Header (lines 1-3)

```
┌─────────────────────────────────────────────────┐
│ 📁 Try Selector                                  │
├─────────────────────────────────────────────────┤
│ > user query here                                │
└─────────────────────────────────────────────────┘
```

### List Section (dynamic height)

```
→ 📁 2025-11-29-project                  just now, 5.2
  📁 2025-11-28-another-project             2h ago, 3.1
  📁 2025-11-27-old-thing                   3d ago, 2.4
```

### Footer (bottom 2 lines)

```
┌─────────────────────────────────────────────────┐
│ ↑/↓: Navigate  Enter: Select  Esc: Cancel        │
└─────────────────────────────────────────────────┘
```

## Keyboard Input

| Key | Action |
|-----|--------|
| ↑ / Ctrl-P | Move selection up |
| ↓ / Ctrl-N | Move selection down |
| Enter | Select current entry |
| Esc / Ctrl-C | Cancel selection |
| Backspace | Delete last query character |
| Any printable | Append to query, re-filter |

## Scrolling

- List scrolls to keep selection visible
- Selection clamped to valid range (0 to entry_count - 1)
- Scroll offset adjusts when selection moves outside visible area

## Actions

Selection can result in three action types:

| Action | Trigger | Result |
|--------|---------|--------|
| CD | Select existing directory | Navigate to directory |
| MKDIR | Select "[new]" entry | Create and navigate to new directory |
| CANCEL | Press Esc | Exit without action |

## New Directory Creation

When query doesn't match any existing directory:

- Show "[new] query-text" as first option
- Selecting creates `YYYY-MM-DD-query-text` directory
- New directory is created in tries base path
