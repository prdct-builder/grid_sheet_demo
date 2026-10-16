# Selection

`GridSheet` lets the user select **rows**, **columns** and **cells**, one at
a time or several at once. Each kind is switched on separately in
`GridSheetConfiguration`, reported through its own callback, and readable and
changeable at runtime through `gridManager.selection`.

Selection is separate from **editing**: tapping into a cell's text or opening
its dropdown edits the cell and selects nothing. It's also separate from
**keyboard focus**: arrow keys and Tab move the focused cell without
selecting it.

- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Behavior](#behavior)
- [Runtime API](#runtime-api)
- [Events](#events)
- [Customization](#customization)
- [Limitations](#limitations)
- [See also](#see-also)

---

## Quick start

```dart
GridSheet(
  columns: columns,
  rows: rows,
  configuration: const GridSheetConfiguration(
    enableRowSelectionOnFirstColumnTap: true, // rows
    enableColumnSelection: true,              // columns
    enableCellSelection: true,                // cells
    enableMultiSelection: true,               // several at once
  ),
  onRowsSelected: (event) => debugPrint('rows: ${event.keys}'),
  onColumnsSelected: (event) => debugPrint('columns: ${event.names}'),
  onCellsSelected: (event) => debugPrint('cells: ${event.cells}'),
)
```

With this configuration and the default index column:

- a tap on a row's **index cell** (its number) selects the row;
- a tap on a **column header** selects the column;
- a tap on a **data cell** selects the cell.

---

## Configuration

### Turning selection on

Every kind of selection is off by default.

| Flag | Default | Turns on |
| --- | --- | --- |
| `enableRowSelectionOnFirstColumnTap` | `false` | Row selection. The name is historical: where a tap selects a row depends on the index column, see [Where a tap selects](#where-a-tap-selects). |
| `enableColumnSelection` | `false` | Column selection, by tapping a header. |
| `enableCellSelection` | `false` | Cell selection. |
| `enableMultiSelection` | `false` | Selecting several rows, columns or cells at once. See [Single and multi-selection](#single-and-multi-selection). |

The flags also gate the API: `selection.selectRows` does nothing while row
selection is off, and the same goes for columns and cells.

### Configuration reference

All on `GridSheetConfiguration` unless noted.

| Option | Default | Meaning |
| --- | --- | --- |
| `enableRowSelectionOnFirstColumnTap` | `false` | Row selection. |
| `enableColumnSelection` | `false` | Column selection by header tap. |
| `enableCellSelection` | `false` | Cell selection. |
| `enableMultiSelection` | `false` | Several at once; Ctrl+A; the Select All checkbox. |
| `selectOnlyCurrentPageRows` | `true` | The Select All checkbox covers the current page only. |
| `selectColumnAcrossAllPages` | `false` | A selected column covers every page. |
| `showBorderOnSelection` | `true` | Border (`true`) or background (`false`). |
| `selectionIncludesPinnedLeftCells` / `RightCells` | `false` | Row highlight in pinned columns. |
| `selectionIncludesPinnedTopCells` / `BottomCells` | `false` | Column highlight in pinned rows. |
| `GridSheet.indexColumn` | the default index column | Where rows are selected; `null` hides it. |
| `GridSheetStyleConfiguration.selectionColor` | `Colors.blue` | Selection color. |
| `GridSheetStyleConfiguration.selectionBorderWidth` | `2` | Selection border width. |

---

## Behavior

### Where a tap selects

Which tap selects a row and which selects a cell depends on whether the grid
shows an **index column** (`GridSheet.indexColumn`, the numbered column; it's
shown by default, and `indexColumn: null` hides it).

#### With an index column

| Row selection | Cell selection | Index cell tap | Data cell tap |
| :---: | :---: | --- | --- |
| on | on | selects the row | selects the cell |
| on | off | selects the row | nothing |
| off | on | nothing | selects the cell |

A row is selected **only** from its index cell. The index column counts as
shown wherever it's pinned, left or right.

#### Without an index column

| Row selection | Cell selection | Data cell tap |
| :---: | :---: | --- |
| on | on | selects the **cell**: cells take priority, and no tap selects a row |
| on | off | selects the **row** |
| off | on | selects the cell |

With both on and no index column, rows can still be selected through the API
(`selection.selectRows`) and with Ctrl+A.

#### What counts as a "data cell tap"

A cell holds either something you can edit or plain content. A tap on the
editable part **edits** the cell; a tap anywhere else **selects** (the cell or
the row, per the tables above).

| Cell | Selects on a tap on… | A tap on the rest… |
| --- | --- | --- |
| Read-only | the whole cell | — |
| Editable text | its **outer padding**, the 4px margin around the text box | starts editing; selects nothing |
| Dropdown | its **outer padding** | opens the dropdown; selects nothing |
| Wrapped text (`wrap: true`) | the whole cell | — |
| Custom (`cellBuilder`) | the whole cell, even where your widget handles the tap | — |

A tap into an editor does one more thing: with single cell selection, it
**clears** what was selected, as a tap on another cell would. Otherwise the
old selection would stay highlighted, and be what a copy takes, while you type
in a different cell. With multi-selection, the selection stays.

> **Double tap.** The second tap of a double tap on the same cell doesn't
> toggle the selection, so double-tapping a cell to edit it keeps it
> selected, as in a spreadsheet.

### Single and multi-selection

| | `enableMultiSelection: false` (default) | `enableMultiSelection: true` |
| --- | --- | --- |
| Tap an unselected item | Selects it and clears **everything** else (rows, columns and cells) | Adds it to the selection |
| Tap a selected item | Keeps it selected | Removes it (toggles) |
| `selectRows([a, b, c])` | Selects only `c`, the last key, like a tap | Adds `a`, `b` and `c` |
| Ctrl+A | Nothing | Selects every row (all pages, hidden rows excluded); again deselects them |
| Select All checkbox | Not shown | Shown, see [Rows](#rows) |

Multi-selection adds with a plain tap: no Ctrl or Shift key is needed, and
Shift doesn't select a range. To select a range, call `selectRowRange`,
`selectColumnRange` or `selectCellRange` (see
[Selecting a range](#selecting-a-range)), for example from your own
Shift+Click handling.

Even with multi-selection, an item and its parts aren't both selected:

- selecting a **row** removes that row's selected cells;
- selecting a **column** removes that column's selected cells;
- selecting a **cell** removes its column from the selection.

### Rows

Turn on with `enableRowSelectionOnFirstColumnTap: true`. A tap selects a row
from its index cell, or from any data cell when there's no index column and
cell selection is off. See [Where a tap selects](#where-a-tap-selects).

#### Select All checkbox

The index column's header shows a checkbox that selects or deselects every
row. It needs all three of:

- an index column;
- `enableRowSelectionOnFirstColumnTap: true`;
- `enableMultiSelection: true`.

It covers the current page only (`selectOnlyCurrentPageRows: true`, the
default) or every filtered row (`false`), plus pinned rows. Hidden rows are
never selected. When some rows are selected, it shows a dash.

Ctrl+A (with `enableMultiSelection`) also toggles the rows, whether or not
the checkbox is shown. Unlike the checkbox, it always covers every row on
every page (hidden rows excluded), whatever `selectOnlyCurrentPageRows` says.

The checkbox's tooltip is "Select all rows", or "Deselect all rows" when
every row it covers is selected. Translate them with
`GridSheetLocalizations.selectAllRows` and `deselectAllRows`.

#### Rows that start selected

A row built with `isSelected: true` starts out selected:

```dart
GridSheetRow(key: const ValueKey('r1'), index: 0, data: data, isSelected: true)
```

This needs row selection on, and the row must be visible
(`GridSheetRow.visible`). Otherwise the grid sets `isSelected` back to
`false` and the row isn't selected. It's applied when the grid first loads
its rows, and again when the parent passes new `rows`: rows created
selected join the selection.

No `onRowsSelected` event fires for it. Read `gridManager.selection` in
`onLoaded` if you need it.

After that, `row.isSelected` follows the selection: read it, but select and
deselect through `gridManager.selection`.

#### Inserted rows are selected

With row selection on, inserting rows selects the **first** inserted row
and clears the rest of the selection (rows, columns and cells), so the new
row is ready to act on. This applies to `rows.insert`, `rows.insertAt` and
what's built on them, such as `rows.duplicate`, in the scrollable section
and in pinned bands. `onRowsSelected` fires.

#### Row groups

With row grouping (`GridSheet.groupingConfiguration`), each group header
shows a checkbox that selects or deselects **all of the group's rows** at
once. It needs both:

- `enableRowSelectionOnFirstColumnTap: true`;
- `enableMultiSelection: true`.

The checkbox shows checked when all the group's rows are selected, a dash
when some are, and empty when none are. With `selectOnlyCurrentPageRows`, it
covers only the group's rows on the current page, and a group with none
there (for example, a collapsed one) has no checkbox.

A custom group header (`GridSheetRowGroupingConfiguration.cellBuilder`) gets
the same through `GridSheetRowGroupCellContext`: `isSelected` (`true`,
`false`, or `null` for some) and `onSelectionChanged(bool)`, which is `null`
when the group can't be selected.

#### Form view

In the form layout (`GridSheetViewMode.form`), a row is a card, and tapping
the card selects its row. There's no index cell, so this works whenever row
selection is on, whatever the index column setting.

- With multi-selection, a tap toggles the card's row, as in the table.
- With single selection, a tap selects the card's row, and a tap on the
  already selected card deselects it.

### Columns

Turn on with `enableColumnSelection: true`. A tap on a column header selects
the column.

A selected column covers its cells on the current page, or on every page
with `selectColumnAcrossAllPages: true`. That also decides which values
`selection.columnsData()` and the `onColumnsSelected` event's `data` return.

### Cells

Turn on with `enableCellSelection: true`. A tap selects the cell, as
described in [What counts as a "data cell tap"](#what-counts-as-a-data-cell-tap).

- The last selected cell becomes where keyboard navigation continues from.
- With a cell context menu, a right-click acts on the cell as a tap would
  (selecting it, or toggling it with multi-selection), then opens the menu.
- With auto-fill on, the selected cell shows the fill handle in its corner.

### How the selection looks

| Setting | Default | Effect |
| --- | --- | --- |
| `GridSheetConfiguration.showBorderOnSelection` | `true` | `true` draws a border around the selection; `false` fills it with a background color instead. |
| `GridSheetStyleConfiguration.selectionColor` | `Colors.blue` | The border or background color. |
| `GridSheetStyleConfiguration.selectionBorderWidth` | `2` | The border's width. |
| `selectionIncludesPinnedLeftCells` / `…RightCells` | `false` | Extends a selected **row**'s highlight into the pinned-left / pinned-right columns. Otherwise it covers the scrollable columns only. |
| `selectionIncludesPinnedTopCells` / `…BottomCells` | `false` | Extends a selected **column**'s highlight into the pinned-top / pinned-bottom rows. |

These only change how the selection is **drawn**. A selected cell is always
highlighted, pinned or not, and the selection and its events are the same
whatever these are set to.

#### Hovered rows

With `GridSheetConfiguration.enableRowHover`, the row under the pointer is
drawn the way a selected row is: with a border when `showBorderOnSelection`
is on, or else filled with `GridSheetStyleConfiguration.hoverColorOnRow`
(falling back to `selectionColor`). A hovered row isn't selected: it's not
in `selection.rowKeys`, and no event fires. To style hover and selection
differently, set `hoverColorOnRow`, or use a `rowWrapper` (see
[Building on the selection](#customization)).

### When the selection is cleared

The grid clears the selection when the rows it refers to may no longer be
there or in the same place:

- a filter is added or cleared, or the search changes;
- a server page is loaded (`serverSidePagination`), since the rows are
  replaced;
- `gridManager.reload()`;
- rows or columns are reordered;
- rows or columns are deleted;
- all row changes are undone (`changes.undoAll()`).

Hiding a column removes it, and its cells, from the selection. Changing page
on the client keeps the selection.

None of these fire the selection events.

### Pivot selection

While the grid shows a pivot table, `gridManager.pivot.selection` holds the
pivot's own cell selection, through the same `GridSheetSelectionAPI` but in
pivot keys. It's separate from the table's selection. See
[Selection and copy](pivot.md#selection-and-copy) in the pivot doc.

---

## Runtime API

`GridSheetSelectionAPI`, from `GridSheetManager.selection`
(`GlobalKey<GridSheetState>().currentState!.selection`, or
`event.gridManager.selection`).

### Reading

| Member | Description |
| --- | --- |
| `List<ValueKey<String>> rowKeys` / `columnKeys` | The selected rows' / columns' keys. |
| `List<GridSheetCell> cellKeys` | The selected cells. |
| `List<GridSheetRow> rows` / `List<GridSheetColumn> columns` / `List<GridSheetCell> cells` | The selected rows, columns and cells. |
| `bool containsRow(key)` / `containsColumn(key)` / `containsCell(rowKey, columnKey)` | Whether one is selected. |
| `List<Map<String, dynamic>> rowsData` | The selected rows as maps, as in the row event's `data`. |
| `Map<String, List<dynamic>> columnsData({bool? onlyCurrentPageRows})` | The selected columns' values, as in the column event's `data`. `onlyCurrentPageRows` overrides `selectColumnAcrossAllPages`. |
| `Map<String, List<dynamic>> cellsData` | The selected cells' values, as in the cell event's `data`. |
| `List<String> columnNames` | The selected columns' names. |
| `int rowIndex` / `int columnIndex` | Where row and column inserts go: after the last selected row or column. |

### Changing

| Member | Description |
| --- | --- |
| `void selectRows(List<ValueKey<String>> keys)` / `deselectRows(...)` | Selects or deselects rows. Needs row selection on. |
| `void selectColumns(List<ValueKey<String>> keys)` / `deselectColumns(...)` | The same for columns. Needs column selection on. |
| `void selectCells(List<GridSheetCell> keys)` / `deselectCells(...)` | The same for cells. Needs cell selection on. |

Each fires its event. Without `enableMultiSelection`, a select call replaces
the whole selection with its **last** key, like a tap.

### Selecting a range

| Member | Selects |
| --- | --- |
| `void selectRowRange(ValueKey<String> fromKey, ValueKey<String> toKey)` | Every row from `fromKey` to `toKey`. |
| `void selectColumnRange(ValueKey<String> fromKey, ValueKey<String> toKey)` | Every column from `fromKey` to `toKey`. |
| `void selectCellRange(GridSheetCell from, GridSheetCell to)` | The rectangle with `from` and `to` at opposite corners. |

A range runs through the rows and columns **as they're displayed**:

- **Rows** in their sorted and filtered order, across every page, with
  pinned rows in their bands: pinned-top first, pinned-bottom last.
- **Columns** in display order, pinned ones where they're shown.
- **Hidden** rows and columns, and rows a filter or search leaves out, are
  skipped, and can't be an end: if either end isn't displayed, nothing
  happens.
- The ends can come in **either order**, and a cell range's corners can be
  any two opposite ones.

They select through `selectRows`, `selectColumns` and `selectCells`, so
the same rules apply:

- each needs its kind of selection on;
- with `enableMultiSelection`, the range is **added** to the selection;
- without it, only the `to` end is selected, as a single tap would;
- the event fires **once** for the whole range.

```dart
// Shift+click style: from the last selected row to the tapped one.
void onRowTapped(ValueKey<String> tapped) {
  final selection = gridManager.selection;
  final anchor = selection.rowKeys.lastOrNull;
  if (HardwareKeyboard.instance.isShiftPressed && anchor != null) {
    selection.selectRowRange(anchor, tapped);
  } else {
    selection.selectRows([tapped]);
  }
}

// The block from B2 to D5.
gridManager.selection.selectCellRange(
  GridSheetCell(row2Key, colBKey),
  GridSheetCell(row5Key, colDKey),
);
```

```dart
final selection = gridManager.selection;

// Select the first row (needs enableRowSelectionOnFirstColumnTap).
selection.selectRows([gridManager.rows.all.first.key]);

// Select a block of cells (needs enableMultiSelection for more than one).
selection.selectCells([
  for (final row in gridManager.rows.currentPage.take(3))
    GridSheetCell(row.key, amountKey),
]);

// Clear everything.
selection
  ..deselectRows(selection.rowKeys)
  ..deselectColumns(selection.columnKeys)
  ..deselectCells(selection.cellKeys);
```

### Copying the selection

The selected **cells** can be copied as text, ready to paste into Excel,
Google Sheets or back into the grid:

```dart
final text = gridManager.cells.selectedText();      // just the text
await gridManager.cells.copy(includeHeaders: true); // also the clipboard

await gridManager.cells.paste(                      // the clipboard, into the grid
  startRowKey: rowKey,
  startColumnKey: columnKey,
);
```

- One line per row and one field per column with a selected cell, **both
  in display order**. An unselected cell inside that block is an empty
  field, so values stay under their columns.
- Fields are tab-separated (`delimiter` changes it). A value holding the
  delimiter, a line break or a quote is quoted as spreadsheets do, so it
  pastes back as one value.
- `paste` and `pasteText` read what spreadsheets copy, including `\r\n` line
  breaks and quoted fields.

---

## Events

Each kind of selection has its own callback. It fires when a tap, Ctrl+A,
the Select All checkbox or the API changes that kind of selection, with the
**whole** selection of that kind, not just what changed.

It doesn't fire when the grid clears the selection itself (see
[When the selection is cleared](#when-the-selection-is-cleared)), so read
`gridManager.selection` again after a filter, reload or delete rather than
relying on the last event.

### GridSheet.onRowsSelected: GridSheetRowsSelectedEvent

| Field | Description |
| --- | --- |
| `List<GridSheetRow> rows` | The selected rows. |
| `List<ValueKey<String>> keys` | Their keys. Use these with `rows.delete`, `rows.update` and so on. |
| `List<Map<String, dynamic>> data` | Each row as a map of column name → value. |
| `GridSheetManager gridManager` | The grid. |

### GridSheet.onColumnsSelected: GridSheetColumnsSelectedEvent

| Field | Description |
| --- | --- |
| `List<GridSheetColumn> columns` | The selected columns. |
| `List<ValueKey<String>> keys` | Their keys. |
| `List<String> names` | Their names (`GridSheetColumn.name`). |
| `Map<String, List<dynamic>> data` | Each column's values by name: the filtered rows on the current page, or on every page with `selectColumnAcrossAllPages`. |
| `GridSheetManager gridManager` | The grid. |

### GridSheet.onCellsSelected: GridSheetCellsSelectedEvent

| Field | Description |
| --- | --- |
| `List<GridSheetCell> cells` | The selected cells, each a `(rowKey, columnKey)` pair. |
| `Map<String, List<dynamic>> data` | The selected values by column name, **without duplicates**. To get each cell's own value, use `gridManager.cells.value(cell.rowKey, cell.columnKey)`. |
| `GridSheetManager gridManager` | The grid. |

```dart
onRowsSelected: (event) {
  setState(() => canDelete = event.keys.isNotEmpty);
},
onCellsSelected: (event) {
  final total = event.cells
      .map((c) => event.gridManager.cells.value(c.rowKey, c.columnKey))
      .whereType<num>()
      .fold<num>(0, (a, b) => a + b);
  status.value = 'Sum: $total';
},
```

> These events were renamed in this release. The 2.2.3 names
> (`selectedRowKeys`, `selectedCells`, `selectedColumnsData`, …) are listed
> with their replacements in `MIGRATION.md`.

---

## Customization

### Pagination bar

The built-in pagination bar (`enableDefaultPagination`) shows two things
from the selection:

- **Selected count**, next to the row range: the number of selected rows,
  columns and cells together, `Selected: 0` included. It updates as you
  select.
- **Column statistics**, before the page controls: when a column is
  selected, the statistics of the **last** selected column, as
  `gridManager.data.statistics` computes them: Count and Unique Count for
  any column, plus Sum, Average, Min and Max for a numeric one. Blanks,
  Non-Blanks and Median are hidden by default
  (`PaginationConfiguration.hideAggregateStats`).

The bar itself only shows when there's more than one page.

The built-in bar always shows both. With `enableCustomPagination`, you place
a `GridSheetPagination` widget yourself and can turn them off with
`showSelectedCount: false` and `showColumnStatistics: false`. A bar you
place yourself shows the selection as of its last build, so rebuild it when
the selection changes (for example from `onRowsSelected`,
`onColumnsSelected` and `onCellsSelected`).

### Custom select-all cell

A `GridSheet.cellBuilder` can replace the index column's header (the Select
All checkbox). It's called with `cell.kind == GridSheetCellKind.selectAll`,
and only where the checkbox itself would show: with an index column, row
selection and multi-selection on. That cell's context has two callbacks:

| Member | Does |
| --- | --- |
| `onToggleSelectAllRows(bool)` | `true` selects every row the checkbox covers, `false` deselects them, as the checkbox does. Clears columns and cells first. |
| `onToggleSelectAllColumns(bool)` | `true` selects every visible column except the index column; `false` deselects them. Clears rows and cells first. `null` while `enableColumnSelection` is off. The built-in checkbox has no equivalent. |

```dart
cellBuilder: (cell) {
  if (cell.kind != GridSheetCellKind.selectAll) return null;
  final selection = cell.gridManager.selection;
  final all = selection.rowKeys.length == cell.gridManager.rows.currentPageCount;
  return IconButton(
    tooltip: all ? 'Clear selection' : 'Select page',
    icon: Icon(all ? Icons.deselect : Icons.select_all),
    onPressed: () => cell.onToggleSelectAllRows?.call(!all),
  );
},
```

### Row wrappers

`GridSheet.rowWrapper` wraps each row, and its `details` say whether the row
is selected:

| `GridSheetRowWrapperDetails` | |
| --- | --- |
| `selected` | Whether the row is selected (its key is in `selection.rowKeys`). Row selection only: a selected cell doesn't make its row `selected`. |
| `hovered` | Whether the pointer is over the row (with `enableRowHover`). |
| `row`, `pinnedLeft`, `pinnedRight`, `gridManager` | The row, which pane is being wrapped, and the grid. |

```dart
rowWrapper: (context, child, details) => AnimatedOpacity(
  duration: const Duration(milliseconds: 150),
  opacity: details.selected || details.hovered ? 1 : 0.85,
  child: child,
),
```

### Context menus

A context menu builder's info carries the selection at the moment the menu
opened, whichever kind of menu it is (`GridSheetCellContextInfo`,
`GridSheetRowContextInfo`, `GridSheetColumnContextInfo`, all
`GridSheetContextMenuInfo`):

| Member | |
| --- | --- |
| `selectedRowKeys` / `selectedColumnKeys` / `selectedCellKeys` | The selected rows, columns and cells. |
| `selectedRowsData` (row menu) / `selectedColumnsData` (column menu) / `selectedCellsData` (cell menu) | Their data, as in the matching selection event. |

So a menu can offer "Delete 3 selected rows" and act on all of them:

```dart
if (info.selectedRowKeys.isNotEmpty) {
  await info.gridManager.rows.delete(info.selectedRowKeys);
}
```

These still use the `selected…` prefix that the events dropped.

---

## Limitations

- **No Shift or drag ranges.** Taps add or remove one item; select ranges
  with `selectRowRange`, `selectColumnRange` and `selectCellRange` (see
  [Selecting a range](#selecting-a-range)).
- **A column and its cells aren't selected together**; one replaces the
  other.
- **Selection isn't saved** in snapshots, and a reload clears it.
- **Selection draws but doesn't edit**: actions on the selection (delete,
  hide, copy) are yours to wire up, or come from the API.

---

## See also

- [Row operations](row-operations.md) and [Column operations](column-operations.md):
  acting on the selected rows and columns
- [Pagination](pagination.md): `selectOnlyCurrentPageRows` and
  `selectColumnAcrossAllPages` across pages
- [Context menus](context-menu.md) · [Wrappers](wrappers.md)
- [Pivot table](pivot.md#selection-and-copy): the pivot's own selection
