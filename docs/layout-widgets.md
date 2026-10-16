# Layout widgets

Slots on `GridSheet` for your own widgets around and in place of the
table. **Top and bottom bars** sit above and below it. **Placeholders**
replace it when there are no rows or no visible columns. A **loading
indicator** covers it while work is in progress.

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
  topBarBuilder: (grid) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text('Watchlist · ${grid.rows.count} tickers'),
  ),
  emptyRowsPlaceholder: const Center(child: Text('Nothing here yet')),
  loadingIndicator: const Center(child: CircularProgressIndicator()),
)
```

---

## Configuration

| `GridSheet` option | Type | Shown |
| --- | --- | --- |
| `topBarBuilder` | `Widget Function(GridSheetManager grid)` | Above the header row. |
| `bottomBarBuilder` | `Widget Function(GridSheetManager grid)` | Below the table, after the pagination bar. |
| `emptyRowsPlaceholder` | `Widget` | In place of the rows when the current page has none. Default: the localized "no rows" text. |
| `emptyColumnsPlaceholder` | `Widget` | In place of the whole table when every column is hidden. Default: the localized "no columns" text. |
| `loadingIndicator` | `Widget` | Over the whole grid while loading. Default: `null`, no overlay. |

Related style options: `GridSheetStyleConfiguration.loadingOverlayColor`
(the overlay's tint) and `bottomBarBorderColor` (the line above the
pagination bar).

---

## Behavior

### Layout

From top to bottom, inside the grid's border and background:

1. `topBarBuilder`
2. The table (header, filter row, rows), which takes the remaining height
3. The built-in pagination bar, when pagination is on
4. `bottomBarBuilder`

The bars stay fixed while the table scrolls, and are rebuilt whenever the
grid rebuilds, so a count or status in them stays current.

### Placeholders

- **No rows**: shown below the header and filter row whenever the current
  page is empty, including when filters or search match nothing. The
  header and filters stay, so the user can clear a filter. The placeholder
  gets the remaining width and height, so a `LayoutBuilder` inside it gets
  real constraints.
- **No columns**: shown when every data column is hidden (the index column
  doesn't count). It replaces the header, filters and rows; the bars stay,
  so put the controls to show columns again there.

### Loading

- While loading, `loadingIndicator` is shown full-size over the grid, bars
  included, on a `loadingOverlayColor` tint.
- The grid shows it during its own async work (reload, snapshot restore,
  server pages, infinite scroll) and between `loading.start()` and
  `loading.stop()`.
- Without `loadingIndicator`, nothing is shown, and `start()` does
  nothing.

---

## Runtime API

`gridManager.loading` (`GridSheetLoadingAPI`):

| Member | Description |
| --- | --- |
| `isActive` | Whether the grid is loading. |
| `start()` | Shows the loading indicator. |
| `stop()` | Hides it. |

```dart
gridManager.loading.start();
try {
  await api.syncPrices();
} finally {
  gridManager.loading.stop();
}
```

`stop()` hides the indicator even if the grid's own work, or another
`start()`, is still running.

---

## Events

None.

---

## Customization

The bars get the grid, so they can show its state and act on it:

```dart
bottomBarBuilder: (grid) => Row(children: [
  Text('${grid.rows.filteredCount} of ${grid.rows.count} rows'),
  const Spacer(),
  TextButton(
    onPressed: grid.changes.all.isEmpty ? null : () => save(grid.changes.all),
    child: const Text('Save changes'),
  ),
]),
```

A bar draws its own borders; the grid's `bottomBarBorderColor` applies only
to the built-in pagination bar.

---

## Limitations

- **One loading state.** `start()` and `stop()` aren't counted: one
  `stop()` ends every loading in progress.
- **No separate placeholder for "filters match nothing"**; check
  `grid.rows.count` in your placeholder to tell the cases apart.
- **No built-in toolbar.** The top bar is yours to fill.

---

## See also

- [Reload](reload.md): reloading rows with the loading indicator
- [Pagination](pagination.md): the built-in bar
- [Dialog](dialog.md): sizing the grid
- [Column operations](column-operations.md): hiding and showing columns
