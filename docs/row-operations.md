# Row operations

Rows can be inserted, duplicated, updated, deleted (with an undo window),
hidden and shown, reordered by drag or by code, and resized. The grid
tracks which rows were inserted, modified or deleted, so you can save just
the changes, and revert them. This page covers `gridManager.rows`,
`gridManager.changes` and the row look while hovering and dragging.

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
final rows = gridManager.rows;

await rows.insert([
  GridSheetRow(key: const ValueKey('r9'), index: 0, data: ['New task', 'Ava', 'Low']),
]);
rows.update(const ValueKey('r9'), ['New task', 'Liam', 'High']);
await rows.hide([const ValueKey('r9')]);
await rows.showAll();
await rows.delete([const ValueKey('r9')]);

// Save only what changed.
await api.save(
  create: gridManager.data.toMaps(gridManager.changes.inserted),
  update: gridManager.data.toMaps(gridManager.changes.modified),
  delete: gridManager.changes.deleted.map((r) => r.key.value).toList(),
);
```

---

## Configuration

On `GridSheetConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `rowInsertPosition` | `above` | Where `rows.insert` and `rows.duplicate` place new rows relative to the selected row: `above` or `below`. |
| `enableRowReorder` | `false` | Lets rows be dragged (long-press the index cell), and enables `reorder` and `resetOrder`. |
| `enableReorderOnPinnedTopRows` / `…BottomRows` | `false` | Lets pinned rows be dragged within their band. See [Fixed rows](fixed-rows.md). |
| `enableRowResize` | `false` | Shows a resize handle at each row's bottom edge, and enables `setHeights`, `resetHeights` and `autoFitHeights`. |
| `enableRowHover` | `false` | Highlights the row under the pointer. |
| `enableUndoDelete` | `true` | Deleting opens an undo window instead of deleting at once. |
| `enableRowSelectionOnFirstColumnTap` | `false` | Lets rows be selected, which `insert`, `duplicate` and actions on the selected rows use. See [Selection](selection.md). |

On `GridSheetRow`:

| Property | Default | Meaning |
| --- | --- | --- |
| `key` | — | A stable `ValueKey<String>`, unique among all rows. |
| `index` | — | The row's position when loaded. The grid renumbers rows by position. |
| `data` | — | One value per column, in the columns' `index` order. |
| `height` | `30` (`GridSheetConstants.defaultRowHeight`) | The row's height. |
| `state` | `existing` | `existing`, `inserted`, `modified` or `deleted`. See [Change tracking](#change-tracking). |
| `visible` | `true` | Whether the row is shown. |
| `pinnedTop` / `pinnedBottom` | `false` | Pins the row. See [Fixed rows](fixed-rows.md). |
| `isSelected` | `false` | Starts the row selected. See [Selection](selection.md). |

Style (`GridSheetStyleConfiguration`):

| Option | Default | Meaning |
| --- | --- | --- |
| `hoverColorOnRow` | `null` (falls back to `selectionColor`) | The hovered row's color. |
| `resizeHandleColor` / `resizeHandleThickness` | `selectionColor` / `3` | The row resize handle. |
| `rowDragFeedbackElevation` | `8` | The lift of a row while it's dragged. |
| `dragFeedbackOpacity` | `0.35` | The opacity of the dragged row's preview. |
| `rowDragIndicatorColor` | `selectionColor` | The drag handle shown in a hovered index cell. |

---

## Behavior

### Where inserted rows go

`insert` and `duplicate` place rows next to the **last selected row**,
above or below it per `rowInsertPosition`. With nothing selected, they go
at the top (`above`) or the end (`below`) of the current page. They only
insert into the scrollable section.

`insertAt` and `duplicateAt` take an explicit key, a `position` (`above` by
default) and a `band` for inserting into a pinned band:

```dart
await gridManager.rows.insertAt(
  anchorKey,
  [newRow],
  position: GridSheetRowInsertPosition.below,
  defaultValues: [null, 'Unassigned'],
);
```

Row keys must be unique: a repeated key inserts nothing (and asserts in
debug builds). A row whose `data` is shorter than the column count is
filled from `defaultValues`, or with `null`.

### Change tracking

Every row has a `state`, and `gridManager.changes` lists the rows by state:

| State | How a row gets it | In |
| --- | --- | --- |
| `inserted` | Added through `rows.insert`, `insertAt`, `duplicate`, or given to the grid as `inserted` | `changes.inserted` |
| `modified` | An existing row whose data was edited. Editing it back to its original values makes it `existing` again. | `changes.modified` |
| `deleted` | Deleted for good (after any undo window closes) | `changes.deleted` |

`changes.all` combines the three. `changes.undo(keys)` reverts rows:
inserted rows are removed and modified rows get their original data back.
`changes.undoAll()` reverts every row. A row deleted for good can't be
brought back by them; only its undo window can do that.

```dart
if (gridManager.changes.all.isNotEmpty) showSaveButton();
await gridManager.changes.undo(gridManager.selection.rowKeys);
```

Reverting rows also clears the cell undo history
(`gridManager.history`), since its steps can no longer be replayed in
order.

### Deleting, and the undo window

With `enableUndoDelete` (the default), deleted rows leave the grid at once
but stay recoverable until the undo prompt is resolved: the built-in banner
shows **Undo** for 5 seconds; `GridSheet.undoDeleteBuilder` replaces it. A
second deletion, a sort, an insert or a reorder finalizes the pending one
first. See [Column operations](column-operations.md#deleting-and-the-undo-window),
which works the same way.

### Hiding and showing

A hidden row keeps its data and state, and is left out of filtering,
paging, display, selection and keyboard navigation, exactly like a row a
filter excludes. `show` brings it back as it was.

### Reordering

With `enableRowReorder`, long-press a row's index cell and drag it; drop it
on another row to place it **before** that row (or on the last row's lower
half for after it). `reorder(fromKey:, toKey:)` does the same by code.
Reordering is off while a sort is active. `resetOrder()` restores the
original order of the scrollable rows.

### Heights

With `enableRowResize`, drag a row's bottom edge (on its index cell, or on
the data cells when there's no index column on the left). By code:

```dart
await gridManager.rows.setHeights({rowKey: 80});
await gridManager.rows.autoFitHeights([rowKey]); // fit wrapped text
await gridManager.rows.resetHeights([rowKey]);   // back to the original
```

---

## Runtime API

### gridManager.rows (`GridSheetRowsAPI`)

| Member | Description |
| --- | --- |
| `all` / `count` | Every row in display order, pinned and hidden ones included. |
| `filtered` / `filteredCount` | Rows after filters and search, every page. |
| `currentPage` / `currentPageCount` | The rows on the current page. |
| `at(index)` / `atIndexes([...])` / `find(key)` / `findAll(keys)` / `contains(key)` | Look rows up. |
| `inScope({scope})` / `range(startKey, endKey, {scope})` | Rows in a scope, or between two keys. |
| `hidden` / `pinnedTop` / `pinnedBottom` | Rows by state. |
| `insert(rows, {defaultValues})` | Inserts next to the selection. |
| `insertAt(key, rows, {defaultValues, band, position})` | Inserts next to `key`, or at the end. In both, formula text (`=...`) in a formula column is evaluated, except in pinned bands. |
| `duplicate(keys, newKeys, {defaultValues})` / `duplicateAt(key, keys, newKeys, {defaultValues, band, position})` | Copies rows as `inserted` rows: every value, and formulas as formulas so they stay live. Empty cells (null, blank text, empty list or map) get `defaultValues`: one value for every column, or one per column. |
| `update(key, data)` | Replaces a row's whole data. |
| `delete(keys)` | Deletes rows; returns the keys deleted. |
| `reorder(fromKey:, toKey:, {band})` / `resetOrder()` | Moves rows. |
| `setHeights(heights)` / `resetHeights(keys)` / `autoFitHeights(keys)` | Row heights. |
| `hide(keys)` / `show(keys)` / `showAll()` | Visibility. |
| `pin(...)` / `pinTo(...)` / `unpin(keys)` / `unpinAll()` | See [Fixed rows](fixed-rows.md). |

### gridManager.changes (`GridSheetChangesAPI`)

| Member | Description |
| --- | --- |
| `inserted` / `modified` / `deleted` / `all` | Changed rows, by state. |
| `undo(keys)` / `undoAll()` | Reverts rows to how they were loaded. |

To change single cells rather than whole rows, see
[Cell operations](cell-operations.md).

---

## Events

### GridSheet.onRowReorder: GridSheetRowReorderEvent

Fires after a row moves by drag or `reorder`.

| Field | Description |
| --- | --- |
| `fromKey` | The row that moved. |
| `toKey` | The row it was placed before, or the last row for a drop after it. |
| `fromIndex` | Its position before the move, within its section (the scrollable rows, or its pinned band). |
| `toIndex` | Where it was inserted, counted before the move, like `ReorderableListView.onReorder`: it ends up at `toIndex - 1` when moved down. |
| `gridManager` | The grid. |

### GridSheet.onCellValueChanged

`rows.update` fires `onCellValueChanged` for each changed cell. See
[Cell operations](cell-operations.md).

### GridSheet.undoDeleteBuilder: GridSheetUndoDeleteEvent

Builds the undo prompt; for a row deletion, `rows` and `rowKeys` hold what
was deleted. See [Column operations](column-operations.md#customization).

---

## Customization

### Hover and drag

```dart
configuration: const GridSheetConfiguration(enableRowHover: true, enableRowReorder: true),
styleConfiguration: GridSheetStyleConfiguration(
  hoverColorOnRow: Colors.teal.shade50,
  rowDragFeedbackElevation: 20,
  dragFeedbackOpacity: 0.6,
),
```

### Your own drag preview

`GridSheet.rowDragPreviewBuilder` replaces what follows the pointer while a
row is dragged. `details.defaultPreview` is the built-in one, to keep or
wrap:

```dart
rowDragPreviewBuilder: (context, details) => Material(
  elevation: 8,
  borderRadius: BorderRadius.circular(20),
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Text('Moving: ${details.row.data.first}'),
  ),
),
```

### Marking changed rows

`GridSheet.rowStateIndicatorBuilder` colors and marks inserted, modified and
deleted rows in their index cell. See
[Index column](index-column.md#marking-changed-rows).

### Long text

`GridSheetColumn.showOverflowTooltip` shows the full value on hover when a
cell's text is cut off; `GridSheetColumn.wrap` wraps it instead.

---

## Limitations

- **Reordering is off while sorted.** Clear the sort first.
- **`insert` and `duplicate` only target the scrollable section.** Use
  `insertAt` or `duplicateAt` with a `band` for a pinned band.
- **Height changes need `enableRowResize`.** Without it, `setHeights`,
  `resetHeights` and `autoFitHeights` do nothing.
- **`update` replaces the whole row.** Its `data` must match the column
  count and order.

---

## See also

- [Fixed rows](fixed-rows.md): pinning rows
- [Index column](index-column.md): marking changed rows
- [Cell operations](cell-operations.md): changing single cells
- [Selection](selection.md)
- [Column operations](column-operations.md): the same operations for columns
