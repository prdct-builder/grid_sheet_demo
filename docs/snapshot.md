# Snapshot & restore

A snapshot is a **checkpoint of the whole grid**: its rows and their change
state, its columns, formulas, sorting, filters, search, conditional
formats, pagination and pivot view. Restoring one brings all of it back and
discards everything done since. Use it for "Discard changes", named
checkpoints, or your own multi-step undo.

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
final checkpoint = gridManager.snapshots.create();

// ... the user edits, inserts, deletes, sorts ...

await gridManager.snapshots.restore(checkpoint); // back to the checkpoint
```

---

## Configuration

Nothing to configure: snapshots are always available through
`gridManager.snapshots`.

---

## Behavior

### What a snapshot holds

| Captured | Notes |
| --- | --- |
| Every row | Including filtered-out, hidden, pinned and soft-deleted rows, with their data, height, visibility and change state (inserted, modified, deleted, and the original data behind "modified"). |
| Every column | Including hidden ones, with width, pinning, order and type. |
| Formulas | The formula text of formula-column cells, so formulas come back live, not as plain values. |
| Sorting | The sort keys and directions. |
| Filters | By column name. |
| Search | The terms, exact match and smart syntax. |
| Conditional formats | The rules. |
| Pagination | The current page and rows per page. |
| View | The view mode and the pivot table's state. |

Not captured: the selection, the scroll position, group expansion, open row
panels, and the widget's configuration objects.

### Creating

- `create()` copies row data and columns, so later edits don't change the
  snapshot, and one snapshot can be restored any number of times.
- It's synchronous and cheap for small grids, but holds a full copy of the
  data: keep a bounded number for large ones.

### Restoring

- Replaces rows, columns and the query state with the snapshot's, then
  recomputes formulas, filters and the page, behind the loading indicator.
- **Change tracking comes back as it was**: rows inserted or modified
  before the checkpoint show as such again, and `gridManager.changes` matches.
- **Clears cell undo / redo** (`history`): those steps were made to data
  that no longer exists.
- **Ends a pending undo-delete window**: rows waiting to be deleted are
  deleted first.
- Selection and other state for rows or columns that no longer exist is
  dropped.
- Works with stretched columns (`stretchColumnsToFillWidth`): the restored
  widths become the base widths again.

---

## Runtime API

`gridManager.snapshots` (`GridSheetSnapshotsAPI`):

| Member | Description |
| --- | --- |
| `create()` | Returns a `GridSheetSnapshot` of the current state. |
| `restore(snapshot)` | Restores it. Returns a `Future` that completes once the grid is rebuilt. |

### Multi-step undo

```dart
final undoStack = <GridSheetSnapshot>[];
final redoStack = <GridSheetSnapshot>[];

void checkpoint() {
  undoStack.add(gridManager.snapshots.create());
  if (undoStack.length > 20) undoStack.removeAt(0); // keep memory bounded
  redoStack.clear();
}

Future<void> undo() async {
  if (undoStack.isEmpty) return;
  redoStack.add(gridManager.snapshots.create());
  await gridManager.snapshots.restore(undoStack.removeLast());
}
```

For single cell edits, the built-in [cell undo / redo](cell-operations.md) is
lighter; snapshots suit bigger steps such as a bulk import or a delete.

### Discard changes

```dart
late final GridSheetSnapshot loaded;

onLoaded: (event) {
  gridManager = event.gridManager;
  loaded = gridManager.snapshots.create();
},

TextButton(
  onPressed: () => gridManager.snapshots.restore(loaded),
  child: const Text('Discard changes'),
),
```

---

## Events

None of its own. Restoring doesn't fire `onCellValueChanged`, and clears
the cell undo history.

---

## Customization

`GridSheetSnapshot` is a plain immutable class; `copyWith` builds a variant,
for example the same data with no filters:

```dart
final unfiltered = gridManager.snapshots.create().copyWith(filters: {}, searchItems: []);
await gridManager.snapshots.restore(unfiltered);
```

Filters are stored by column name, so they survive a change of column keys.

---

## Limitations

- **In memory only.** A snapshot holds `GridSheetRow`, `GridSheetColumn` and
  `ValueKey` objects; it isn't serialized to JSON. Persist your data
  separately to keep it across app restarts.
- **Full copies.** Each snapshot copies every row; there's no delta
  storage.
- **No selection or scroll state.**

---

## See also

- [Cell operations](cell-operations.md): cell undo / redo
- [Row operations](row-operations.md): change tracking, undoing row changes
- [Reload](reload.md): replacing the data from your source
