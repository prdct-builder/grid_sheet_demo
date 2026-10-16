# Cell operations

Cells are read and written through `gridManager.cells`: single values or
batches, fills, find and find-and-replace, clearing, copy and paste in the
format spreadsheets use, and validation. Cell edits can be undone with
Ctrl+Z, and with `enableCellNavigation` the keyboard moves between cells.

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
final cells = gridManager.cells;

final city = cells.value(rowKey, cityKey);
cells.update(rowKey: rowKey, columnKey: populationKey, value: 37.4);
cells.updateAll([
  GridSheetCellUpdate(rowKey: r1, columnKey: populationKey, value: 32.9),
  GridSheetCellUpdate(rowKey: r2, columnKey: populationKey, value: 28.5),
]);
final replaced = await cells.findAndReplace(findValue: 'Delhi', replaceValue: 'New Delhi');
await cells.copy();                                   // the selected cells
await cells.paste(startRowKey: r1, startColumnKey: cityKey);
gridManager.history.undo();
```

---

## Configuration

On `GridSheetConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enableCellNavigation` | `false` | Arrow keys, Tab and Enter move between cells. |
| `enableCellSelection` | `false` | Lets cells be selected, which `copy` and actions on the selected cells use. See [Selection](selection.md). |
| `undoHistoryLimit` | `100` | How many steps of cell edits can be undone. `0` turns undo off. |

Whether a cell can be edited comes from its column (`editable`,
`hasTextController`, `conditionalEditExpression`); see
[Column types](column-types.md) and
[Conditional editability](conditional-edit.md).

---

## Behavior

### Writing values

- `update` and `updateAll` store the value **as given**: pass the type the
  column holds (`42`, not `'42'`). They skip cells that can't be edited.
- Typing, `pasteText` and `findAndReplace` convert text by the column's
  type, and store a blank as `null`. See
  [Editing and parsing](column-types.md#editing-and-parsing).
- Every write marks the row as modified, recomputes dependent formulas,
  fires `onCellValueChanged` and is recorded for undo.
- `updateAll` writes everything in one batch: formulas recompute once, and
  it's undone as one step.

### Finding

`find` returns the cells your predicate accepts, optionally only in some
columns:

```dart
final big = gridManager.cells.find(
  predicate: (value, row, column) => value is num && value > 30,
  columnKeys: [populationKey],
);
```

### Find and replace

`findAndReplace` matches each cell's text (`contains` by default, or
`exactMatch: true`; case-insensitive unless `matchCase: true`) and replaces
the **whole value** of each matching cell. Read-only cells are skipped. It
returns how many cells it replaced.

```dart
await gridManager.cells.findAndReplace(
  findValue: 'Active',
  replaceValue: 'Completed',
  exactMatch: true,
  columnKeys: [statusKey],
);
```

### Filling

`fill` writes one value down a column between two rows; with
`increment: true` and a number, each row gets the next number:

```dart
await gridManager.cells.fill(
  startRowKey: r1,
  endRowKey: r10,
  columnKey: idKey,
  value: 1,
  increment: true,
);
```

Pattern fills (`1, 2, 3 → 4, 5, 6`, dates, weekdays) are covered in
[Autofill](autofill.md).

### Clearing

| Call | Writes |
| --- | --- |
| `clear(keys)` | `null` into each listed cell, as `clearRange` does. |
| `clearRange(startRowKey:, endRowKey:, startColumnKey:, endColumnKey:)` | `null` into every cell of the rectangle. |

### Copy and paste

- `selectedText()` returns the selected cells as text: one line per row and
  one field per column, both in display order, tab-separated. `copy()` also
  writes it to the clipboard. `includeHeaders: true` adds the column titles.
- `pasteText(text:, startRowKey:, startColumnKey:)` writes text into the
  grid from a starting cell, across and down; `paste(...)` reads the
  clipboard first.
- Both use the spreadsheet format: a value holding a tab, a line break or a
  quote is quoted, `\r\n` line breaks are accepted, and the final line
  break doesn't add a row. Text copied from Excel or Google Sheets pastes
  correctly.
- Pinned rows are left out unless asked in with `includePinnedBands`.

### Undo and redo

Every cell write is recorded in `gridManager.history`. While focus is in
the grid, **Ctrl+Z** (⌘Z) undoes and **Ctrl+Y** or **Ctrl+Shift+Z** redoes,
even while a cell is being typed in.

- One call, one paste or one fill is one step. Typing in a cell is one step
  until the cell loses focus.
- A formula cell is restored to its formula.
- Structural changes (inserting, deleting, reordering) aren't recorded.
  Deletion has its own undo window.
- The history is cleared when the data is replaced: a reload, a server page
  change, a snapshot restore, new `rows`, or `changes.undo`.

### Keyboard navigation

With `enableCellNavigation`:

| Key | Moves |
| --- | --- |
| ↑ / ↓ | To the cell above or below, stopping at the first and last row. |
| ← / → | To the cell beside, within the row. While a cell is being typed in, they move the text cursor instead. |
| Tab / Shift+Tab | To the next or previous cell, wrapping to the next or previous row. |
| Enter / Shift+Enter | While typing in a cell, to the cell below or above. |

Navigation moves focus only: it doesn't select cells.

### Validation

`validateAll` checks every cell of the named columns and returns the cells
that fail, with your message:

```dart
final errors = gridManager.cells.validateAll(
  validators: {'POPULATION_M': (value) => value is num && value > 0},
  errorMessages: {'POPULATION_M': 'Population must be positive'},
);
```

---

## Runtime API

### gridManager.cells (`GridSheetCellsAPI`)

| Member | Description |
| --- | --- |
| `value(rowKey, columnKey)` / `values(cells)` | Reads values. |
| `range(startRowKey, endRowKey, startColumnKey, endColumnKey, {scope})` | Reads a rectangle: its column names and a 2-D list of values. |
| `find({predicate, columnKeys})` | Finds cells by predicate. |
| `update({rowKey, columnKey, value})` / `updateAll(updates)` | Writes values. |
| `findAndReplace({findValue, replaceValue, matchCase, exactMatch, columnKeys})` | Replaces matching cells; returns the count. |
| `fill({...})` | Fills a column range. |
| `autoFillVertical` / `autoFillHorizontal` | Pattern fills. See [Autofill](autofill.md). |
| `clear(keys)` / `clearRange({...})` | Clears cells. |
| `selectedText({delimiter, includeHeaders})` / `copy(...)` | The selected cells as text. |
| `pasteText({text, startRowKey, startColumnKey, ...})` / `paste(...)` | Writes text into the grid. |
| `validateAll({validators, errorMessages})` | Validates columns. |
| `scrollTo({columnKey, rowKey})` | Scrolls a cell into view. |
| `controller(...)` / `focusNode(...)` | A cell's text controller and focus node. Requesting focus on the node starts editing the cell. |

### gridManager.history (`GridSheetHistoryAPI`)

| Member | Description |
| --- | --- |
| `canUndo` / `canRedo` | Whether there's a step to undo or redo. |
| `undo()` / `redo()` | Undoes or redoes a step; returns whether one was. |
| `clear()` | Forgets every step. |

```dart
IconButton(
  icon: const Icon(Icons.undo),
  onPressed: gridManager.history.canUndo ? gridManager.history.undo : null,
),
```

`gridManager` notifies its listeners when `canUndo` or `canRedo` changes,
so a `ListenableBuilder` keeps such a button up to date.

---

## Events

### GridSheet.onCellValueChanged: GridSheetCellValueChangedEvent

Fires for every cell whose value changes, by typing, the API, paste, fill
or undo.

| Field | Description |
| --- | --- |
| `rowKey` / `columnKey` | The cell. |
| `columnIndex` / `name` / `title` | Its column. |
| `oldValue` / `newValue` | The value before and after, as stored (typed). |
| `rowData` | A read-only copy of the row's values after the change. |
| `rowAsMap` | The row as a map of column name → value. |
| `rowState` | The row's state after the change. |
| `gridManager` | The grid. |

While a cell is being typed in, this fires on **every keystroke**. Don't
reject or revert incomplete values here; validate when the user saves.

```dart
onCellValueChanged: (event) {
  if (event.name == 'QTY' || event.name == 'PRICE') {
    final total = (event.rowAsMap['QTY'] ?? 0) * (event.rowAsMap['PRICE'] ?? 0);
    event.gridManager.cells.update(rowKey: event.rowKey, columnKey: totalKey, value: total);
  }
},
```

---

## Customization

- **How a cell looks**: `GridSheet.cellBuilder`. See
  [Custom cells](custom-cells.md).
- **Which cells can be edited**: `GridSheetColumn.editable` and
  `conditionalEditExpression`. See
  [Conditional editability](conditional-edit.md).
- **The copy format**: `selectedText(delimiter: ',', includeHeaders: true)`.

---

## Limitations

- **`update` doesn't convert text.** `update(value: '42')` stores a
  string, even in a number column.
- **Find and replace replaces whole values**, not the matching part of the
  text.

---

## See also

- [Autofill](autofill.md): the fill handle and pattern fills
- [Column types](column-types.md): how text is converted by type
- [Selection](selection.md): selecting cells, and copying them
- [Formula columns](formula-columns.md)
- [Row operations](row-operations.md): change tracking
