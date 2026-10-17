# Row separators

`GridSheet.rowSeparatorBuilder` puts your own widget **below a row**,
spanning the grid's full width: a subtotal after each order, a section
heading, a note. Separators take their own height in the row list and
scroll with the rows.

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
  rowSeparatorBuilder: (context, row, gridManager) {
    if (!isLastItemOfOrder(row)) return null; // no separator for this row
    return GridSheetRowSeparator(
      height: 36,
      widget: Text('Order ${row.data[0]} total: ${orderTotal(row, gridManager)}'),
    );
  },
)
```

---

## Configuration

| Option | Meaning |
| --- | --- |
| `GridSheet.rowSeparatorBuilder` | `GridSheetRowSeparator? Function(BuildContext context, GridSheetRow row, GridSheetManager gridManager)`. Called for each row; return a separator or `null`. |

`GridSheetRowSeparator`:

| Field | Meaning |
| --- | --- |
| `widget` | The content, given exactly `height` and the grid's full width. |
| `height` | The exact height the separator takes below its row. |

---

## Behavior

- **Full width.** A separator spans every column, pinned and scrollable,
  instead of sitting in one column.
- **Exact height.** The height is part of the row's slot in the row list,
  so content taller than `height` is clipped and shorter content leaves
  space. Size the widget to fit.
- **Recomputed when rows change.** Separator heights are cached, and
  recomputed when rows are inserted, deleted, reordered, sorted, filtered,
  edited, regrouped or paged, when a new builder is passed, and on
  `gridManager.notifyListeners()`.
- **Built for rows on screen**, like the rows themselves.
- With row expansion, a row's separator appears below its expansion panel.

---

## Runtime API

There's no API for separators: they come from the builder. If a separator
depends on something outside the grid, call
`gridManager.notifyListeners()` after it changes so heights are recomputed.

The builder's `gridManager` gives it the grid's **current** data, so
totals stay right after edits and sorting:

```dart
rowSeparatorBuilder: (context, row, gridManager) {
  final rows = gridManager.rows.currentPage;
  final i = rows.indexWhere((r) => r.key == row.key);
  final isLast = i == rows.length - 1 || rows[i + 1].data[0] != row.data[0];
  if (!isLast) return null;
  final total = rows
      .where((r) => r.data[0] == row.data[0])
      .fold<double>(0, (sum, r) => sum + (r.data[4] as num));
  return GridSheetRowSeparator(height: 36, widget: Text('Total: $total'));
},
```

---

## Events

None.

---

## Customization

The separator is any widget. Return different widgets, or different heights,
per row. For grouped data with built-in headers, subtotals and collapsing,
use [Row grouping](row-grouping.md) instead.

---

## Limitations

- **Not for pinned rows.** Only the scrollable rows get separators.
- **Fixed height per separator.** It doesn't size to its content.
- **Not part of the data.** Separators aren't exported, selected or
  navigated to.

---

## See also

- [Row grouping](row-grouping.md): group headers and subtotals
- [Row expansion](row-expansion.md): a detail panel below a row
- [Fixed columns](fixed-columns.md)
