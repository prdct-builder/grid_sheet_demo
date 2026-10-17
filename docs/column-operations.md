# Column operations

Columns can be added, duplicated, deleted (with an undo window), renamed,
hidden and shown, reordered by drag or by code, resized and auto-fitted,
and switched between wrapping and truncating text. This page covers all of
them through `gridManager.columns`.

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
final columns = gridManager.columns;

await columns.insert([
  GridSheetColumn(key: const ValueKey('notes'), index: columns.count, name: 'notes', title: 'Notes'),
]);
await columns.hide([const ValueKey('notes')]);
await columns.show([const ValueKey('notes')]);
await columns.rename({const ValueKey('notes'): (newName: 'remarks', newTitle: 'Remarks')});
await columns.delete([const ValueKey('notes')]);
```

Reordering, resizing and the undo window need their flags; see
[Configuration](#configuration).

---

## Configuration

On `GridSheetConfiguration` unless noted:

| Option | Default | Meaning |
| --- | --- | --- |
| `columnInsertPosition` | `after` | Where `columns.insert` and `columns.duplicate` place new columns relative to the selected column: `before` or `after`. |
| `enableColumnReorder` | `false` | Lets scrollable columns be dragged by their header, and enables `reorder`, `setOrder` and `resetOrder`. |
| `enableReorderOnPinnedLeftColumns` / `…RightColumns` | `false` | Lets pinned columns be dragged within their pane. |
| `enableUndoDelete` | `true` | Deleting opens an undo window instead of deleting at once. |
| `showColumnHeaderRow` | `true` | Shows the header row (titles, sort arrows, resize handles). |
| `stretchColumnsToFillWidth` | `false` | Grows columns to fill leftover width, each up to its `maxStretchWidth`. |
| `enableColumnSelection` | `false` | Lets a header tap select the column, which `insert`, `duplicate` and actions on the selected columns use. See [Selection](selection.md). |
| `GridSheetColumn.resizable` | `false` | Shows the column's resize handle, and lets `setWidths`, `resetWidths` and `autoFitWidths` change it. |
| `GridSheetColumn.wrap` | `false` | Wraps text instead of truncating it with an ellipsis. |
| `GridSheetColumn.maxStretchWidth` | `null` | The most a column grows under `stretchColumnsToFillWidth`. |

Style (`GridSheetStyleConfiguration`):

| Option | Default | Meaning |
| --- | --- | --- |
| `resizeHandleColor` | `selectionColor` | The resize handle's color while hovered or dragged. |
| `resizeHandleThickness` | `3` | The resize handle's thickness. |
| `columnDragFeedbackElevation` | `8` | The lift of a column while it's dragged. |
| `dragFeedbackOpacity` | `0.35` | The opacity of the dragged column's preview. |

---

## Behavior

### Where inserted columns go

`insert` and `duplicate` place columns next to the **last selected
column**, before or after it per `columnInsertPosition`. With nothing
selected, they go at the start (`before`) or the end (`after`). They only
ever insert into the scrollable section: a selected pinned column counts as
no selection.

`insertAt` and `duplicateAt` take an explicit key instead, and can insert
into a pinned pane with `band: GridSheetColumnBand.left` or `.right`.

A new column's cells start empty, or take `defaultValues`:

```dart
await gridManager.columns.insertAt(
  priceKey,
  [taxColumn],
  position: GridSheetColumnInsertPosition.after,
  defaultValues: [0.0],
);
```

### Deleting, and the undo window

With `enableUndoDelete` (the default), deleted columns leave the grid at
once, but stay recoverable until the undo prompt is resolved:

- The built-in banner shows **Undo** and finalizes the deletion after 5
  seconds.
- `GridSheet.undoDeleteBuilder` replaces the banner with your own widget,
  which calls `event.onUndo()` or `event.onDismiss()`. See
  [Customization](#customization).
- A second deletion, a reorder or another structural change finalizes the
  pending one first.

Without it, deletion is immediate and permanent. The index column and hidden
columns can't be deleted.

### Hiding and showing

A hidden column keeps its data and its place, and comes back where it was.
It's left out of the display, exports that use the visible scope, and the
selection. With `columnVisibilityFadeEnabled`, hiding and showing animate;
see [Column animation](column-animation.md).

### Renaming

`rename` changes a column's `name` and `title`, never its key, so code that
holds the key keeps working. Filters, sorting, comparators and widths follow
the column to its new name. Either every rename in the call succeeds, or
none does: the returned map then has an error per bad key (unknown key, or
an empty or already used name).

```dart
final errors = await gridManager.columns.rename({
  firstKey: (newName: 'first_name', newTitle: 'First name'),
});
if (errors.isNotEmpty) debugPrint(errors.values.join('\n'));
```

### Reordering

With `enableColumnReorder`, a long press on a header drags the column; drop
it on another header to take that column's place. `reorder`, `setOrder` and
`resetOrder` do the same by code. Each move fires `onColumnReorder`, except
`setOrder` and `resetOrder`.

### Widths

- **Drag:** a resizable column's header edge drags to resize.
- `setWidths` sets widths by key; `widths` reads the current ones, for
  saving a layout.
- `autoFitWidths` sizes columns to their header and cell content.
- `resetWidths` restores the widths the columns were created with.

All three skip columns that aren't `resizable`.

---

## Runtime API

`GridSheetColumnsAPI`, from `gridManager.columns`.

### Reading

| Member | Returns |
| --- | --- |
| `all` / `count` | Every column in display order, hidden ones included; how many there are. |
| `at(index)` / `atIndexes([...])` | Columns by display position. |
| `find(key)` / `findAll(keys)` / `contains(key)` | Columns by key. |
| `findByNames(names)` | Columns by `name`; unknown names are skipped. |
| `inScope({scope})` | `GridSheetColumnScope.all` (default) or `.visible`. |
| `scrollable` / `pinnedLeft` / `pinnedRight` / `hidden` | Columns by section. |
| `widths` | The current width of each column. |

### Changing

| Member | Does |
| --- | --- |
| `insert(columns, {defaultValues})` | Inserts next to the selection, per `columnInsertPosition`. |
| `insertAt(key, columns, {defaultValues, band, position})` | Inserts before or after `key` (or at the end when `null`), optionally into a pinned pane. |
| `duplicate(keys, newKeys, {defaultValues})` / `duplicateAt(key, keys, newKeys, {defaultValues, band, position})` | Adds a copy of each column under a new key, with all its properties except pinning, and every row's value (formulas stay live). Empty cells get `defaultValues`. |
| `delete(keys)` | Deletes columns; returns the keys deleted. |
| `rename(renames)` | Renames columns; returns errors by key, empty on success. |
| `hide(keys)` / `show(keys)` / `showAll()` | Hides or shows columns. |
| `reorder(fromKey:, toKey:)` | Moves a column to another's place. |
| `setOrder(keys)` / `resetOrder()` | Sets the whole order; restores the original order. |
| `setWidths(widths)` / `resetWidths(keys)` / `autoFitWidths(keys)` | Changes widths. |
| `setWrap(keys, wrap)` | Turns wrapping on or off. |
| `pin(...)` / `pinTo(...)` / `unpin(keys)` / `unpinAll()` | Pins columns. See [Fixed columns](fixed-columns.md). |

```dart
// Save and restore a layout.
final saved = (
  order: gridManager.columns.all.map((c) => c.key).toList(),
  widths: gridManager.columns.widths,
  hidden: gridManager.columns.hidden.map((c) => c.key).toList(),
);

gridManager.columns.setOrder(saved.order);
await gridManager.columns.setWidths(saved.widths);
await gridManager.columns.hide(saved.hidden);
```

---

## Events

### GridSheet.onColumnReorder: GridSheetColumnReorderEvent

Fires after a column moves by drag or `reorder`.

| Field | Description |
| --- | --- |
| `fromKey` | The column that moved. |
| `toKey` | The column whose place it took. |
| `fromIndex` / `toIndex` | Its position in `columns.all` before and after the move, hidden and pinned columns included. |
| `gridManager` | The grid. |

```dart
onColumnReorder: (event) => prefs.saveColumnOrder(
  event.gridManager.columns.all.map((c) => c.name).toList(),
),
```

### GridSheet.undoDeleteBuilder: GridSheetUndoDeleteEvent

Builds the undo prompt after a deletion. For a column deletion, `columns`
and `columnKeys` hold what was deleted and `isColumnDeletion` is `true`.
`onUndo` restores them; `onDismiss` finalizes the deletion. Both do nothing
once the deletion is no longer pending.

---

## Customization

### Your own undo prompt

```dart
undoDeleteBuilder: (context, event) => MaterialBanner(
  content: Text(event.isColumnDeletion
      ? '${event.columns.length} column(s) deleted'
      : '${event.rows.length} row(s) deleted'),
  actions: [
    TextButton(onPressed: event.onUndo, child: const Text('Undo')),
    TextButton(onPressed: event.onDismiss, child: const Text('Dismiss')),
  ],
),
```

Your widget decides when to dismiss: the grid imposes no timer on it.

### Handles and drag feedback

```dart
styleConfiguration: GridSheetStyleConfiguration(
  resizeHandleColor: Colors.pink,
  resizeHandleThickness: 5,
  columnDragFeedbackElevation: 20,
  dragFeedbackOpacity: 0.6,
),
```

---

## Limitations

- **`insert` and `duplicate` only target the scrollable section.** Use
  `insertAt` or `duplicateAt` with a `band` for a pinned pane.
- **Width changes need `resizable`.** `setWidths`, `resetWidths` and
  `autoFitWidths` silently skip other columns.
- **Reordering needs `enableColumnReorder`.** Without it, `reorder`,
  `setOrder` and `resetOrder` do nothing.
- **A duplicate's name** is the original's name followed by the new key;
  rename it with `rename` if formulas should refer to it by another name.

---

## See also

- [Fixed columns](fixed-columns.md): pinning
- [Column animation](column-animation.md): fading columns in and out
- [Column types](column-types.md): column properties
- [Selection](selection.md): selecting columns
- [Row operations](row-operations.md): the same operations for rows
