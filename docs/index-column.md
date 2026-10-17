# Index column

The **index column** is the numbered column at the edge of the grid. It
shows each row's number, is where a row is selected (with row selection
on), holds the Select All checkbox, and can mark rows that have unsaved
changes. It's shown by default, pinned to the left.

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

The index column needs no setup. To change it, pass a `GridSheetColumn` as
`GridSheet.indexColumn`; to remove it, pass `null`:

```dart
GridSheet(
  columns: columns,
  rows: rows,
  indexColumn: const GridSheetColumn(
    key: ValueKey('index'), // required by the constructor, not used
    index: -1,
    name: 'index',
    title: 'S.No',
    width: 56,
  ),
)

GridSheet(columns: columns, rows: rows, indexColumn: null); // no index column
```

---

## Configuration

`GridSheet.indexColumn` takes a `GridSheetColumn`, or `null` for none. The
default is `GridSheetColumn.defaultIndexColumn`: no title, 60 px wide,
centered, pinned left.

Only these properties of the column you pass are used:

| Property | Meaning |
| --- | --- |
| `title` | The header text. Blank by default. |
| `width` | The column's width. |
| `textAlign` | The number's alignment. |
| `pinnedRight` | `true` pins it to the right instead of the left. |
| `visible` | `false` hides it, the same as passing `null`. |

`key`, `index`, `name` and `type` are required by the constructor but
ignored. The index column is never editable, sortable or resizable.

Related options elsewhere:

| Option | Meaning |
| --- | --- |
| `GridSheet.rowStateIndicatorBuilder` | Marks inserted, modified and deleted rows in their index cell. See [Customization](#customization). |
| `GridSheetConfiguration.enableRowSelectionOnFirstColumnTap` | Lets the index cell select its row. See [Selection](selection.md). |

---

## Behavior

### Numbers

Each index cell shows the row's position as displayed, counting across
pages: row 1 on page 2 of a 10-row page shows `11`. Numbers follow sorting
and filtering, so they always run in order.

### What the index column does

| With | The index column |
| --- | --- |
| Row selection (`enableRowSelectionOnFirstColumnTap`) | Selects a row on a tap of its index cell. Rows are selected **only** from here while it's shown. |
| Row and multi-selection | Shows the Select All checkbox in its header. |
| Row reorder (`enableRowReorder`) | Is where a row is dragged: long-press the index cell. With `enableRowHover` too, a drag handle replaces the number while the row is hovered (not while sorted or grouped). |
| Row resize (`enableRowResize`) | Holds the row-height resize handle at the bottom edge of each index cell. |
| Row expansion | Shows the expand chevron next to the number. See [Row expansion](row-expansion.md). |

When the index column is hidden or pinned right, the row drag handle and
the resize handle move to the data cells. Without an index column, a data
cell tap selects the row only when cell selection is off; see
[Where a tap selects](selection.md#where-a-tap-selects).

---

## Runtime API

There's no API on `gridManager` for the index column. To change it at
runtime, pass a different `indexColumn` to the `GridSheet`. It's not part
of `columns.all`, so column operations don't see it: it can't be hidden,
deleted, renamed or unpinned through `gridManager.columns`.

---

## Events

No events of its own. A tap that selects a row fires `onRowsSelected`; see
[Selection](selection.md).

---

## Customization

### Marking changed rows

`GridSheet.rowStateIndicatorBuilder` is called for every row, and returns
how its index cell should look, or `null` for the default (just the
number):

```dart
rowStateIndicatorBuilder: (row) {
  if (row.isInserted) {
    return GridSheetRowStateIndicator(
      color: Colors.green.shade50,
      icon: const Icon(Icons.add, size: 14, color: Colors.green),
    );
  }
  if (row.isModified) {
    return GridSheetRowStateIndicator(
      color: Colors.amber.shade50,
      icon: const Icon(Icons.edit, size: 14, color: Colors.orange),
    );
  }
  return null; // unchanged rows keep the default look
},
```

| `GridSheetRowStateIndicator` | Meaning |
| --- | --- |
| `color` | The index cell's background. `null` keeps `rowColor`. |
| `icon` | An icon beside the number. Unchanged rows never show it. |

In the row expansion form, the icon (its `Icon.icon`) and `color` also mark
the fields that were edited.

### Your own index cell

`GridSheet.cellBuilder` is called with `cell.kind == GridSheetCellKind.indexing`
for each index cell, and with `GridSheetCellKind.selectAll` for its header.
See [Custom cells](custom-cells.md).

---

## Limitations

- **Only five properties are used.** Anything else set on the column you
  pass is ignored.
- **It isn't a real column.** It's not in `columns.all`, and column
  operations can't reach it.

---

## See also

- [Selection](selection.md): selecting rows from the index column
- [Row operations](row-operations.md): reordering and resizing rows
- [Row expansion](row-expansion.md)
- [Custom cells](custom-cells.md)
- [Fixed columns](fixed-columns.md)
