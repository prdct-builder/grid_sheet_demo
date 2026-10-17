# grid_sheet feature guides

One guide per feature of `grid_sheet`.

## How the guides are organized

Every guide has the same sections, in the same order:

| Section | What it covers |
| --- | --- |
| **Quick start** | The smallest code that turns the feature on. |
| **Configuration** | Every option, with its default. |
| **Behavior** | What the feature does, and how it interacts with the rest of the grid. |
| **Runtime API** | `gridManager` members for changing it from code. |
| **Events** | Callbacks and their event fields. |
| **Customization** | Builders and hooks for your own look. |
| **Limitations** | What it doesn't do, and workarounds. |
| **See also** | Related guides. |

A section that doesn't apply to a feature still appears, with a one-line
note.

## Columns

| Guide | |
| --- | --- |
| [Column types](column-types.md) | Text, numbers, dates, booleans, dropdowns, formulas, each with its editor. |
| [Column operations](column-operations.md) | Insert, delete, rename, resize, reorder, hide, auto-fit. |
| [Fixed columns](fixed-columns.md) | Pin columns left or right. |
| [Index column](index-column.md) | The row-number column and row state marks. |
| [Column grouping](column-grouping.md) | Collapsible header bands over related columns. |
| [Column animation](column-animation.md) | Reveal, replay and cell-flash animations. |

## Rows

| Guide | |
| --- | --- |
| [Row operations](row-operations.md) | Insert, delete, duplicate, resize, reorder, change tracking, undo. |
| [Fixed rows](fixed-rows.md) | Pin rows to the top or bottom. |
| [Row expansion](row-expansion.md) | A detail panel below a row. |
| [Row separators](row-separator.md) | Full-width widgets between rows. |
| [Row grouping](row-grouping.md) | Group headers, aggregates and grand totals. |
| [Row swipe](row-swipe.md) | Swipe rows to reveal actions. |

## Cells and editing

| Guide | |
| --- | --- |
| [Cell operations](cell-operations.md) | Update, clear, fill, find and replace, undo and redo. |
| [Custom cells](custom-cells.md) | Your own widgets in any cell. |
| [Dropdown cells](dropdown-cells.md) | Pick from a fixed list. |
| [Formula columns](formula-columns.md) | Spreadsheet formulas that recalculate. |
| [Conditional editing](conditional-edit.md) | Cells editable only when a rule allows. |
| [Conditional formatting](conditional-format.md) | Colors and text styles from rules. |
| [Autofill](autofill.md) | Drag the fill handle to copy or extend values. |
| [Selection](selection.md) | Rows, columns, cells, ranges and copying. |

## Finding data

| Guide | |
| --- | --- |
| [Sorting](sorting.md) | Single and multi-column sort. |
| [Filters](filters.md) | The filter row and filter API. |
| [Search](search.md) | Search across all columns. |
| [Pagination](pagination.md) | Client and server pages, infinite scroll, the pagination bar. |
| [Pivot table](pivot.md) | Summaries by row and column fields. |

## Data

| Guide | |
| --- | --- |
| [Data export & statistics](export-stats.md) | CSV, maps, grouped data and column statistics. |
| [Snapshot & restore](snapshot.md) | Checkpoints of the whole grid. |
| [Reload](reload.md) | Manual, scheduled and pull-to-refresh reloads. |
| [Table generation](table-generation.md) | Blank spreadsheets from a column and row count. |

## Look and layout

| Guide | |
| --- | --- |
| [Styling](styling.md) | Colors, borders, text styles. |
| [Wrappers](wrappers.md) | Decorate header, filter and data rows. |
| [Scrollbars](scrollbar.md) | Look, placement, external scrollbars. |
| [Context menus](context-menu.md) | Right-click menus for cells, rows and headers. |
| [Layout widgets](layout-widgets.md) | Top and bottom bars, placeholders, loading. |
| [Grids in dialogs](dialog.md) | Sizing, stretching columns. |
| [Form layout](form-layout.md) | Rows as cards on narrow screens. |
| [RTL support](rtl-support.md) | Right-to-left layouts. |
