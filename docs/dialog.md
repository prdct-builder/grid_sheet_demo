# Grids in dialogs

A `GridSheet` works inside a dialog, a side sheet or any other sized box:
give it a bounded width and height, and it fills them. This page covers
sizing a grid to its columns, letting columns **stretch** when the box is
wider than the table, and how the scrollbars change the space the columns
get.

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
showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    child: SizedBox(
      width: 520,
      height: 420,
      child: GridSheet(
        columns: columns,
        rows: rows,
        indexColumn: null,
        configuration: const GridSheetConfiguration(stretchColumnsToFillWidth: true),
      ),
    ),
  ),
);
```

---

## Configuration

| Option | Default | Meaning |
| --- | --- | --- |
| `GridSheetConfiguration.stretchColumnsToFillWidth` | `false` | Grows the scrollable columns to fill leftover width. |
| `GridSheetColumn.maxStretchWidth` | `null` (no cap) | The most a column may grow while stretching. |
| `GridSheetScrollBarConfiguration.verticalScrollbarPlacement` | `afterLastColumn` | Whether space is reserved for the vertical scrollbar. |
| `showVerticalScrollbar` / `showHorizontalScrollbar` | `true` | Scrolling on each axis. |
| `GridSheet.indexColumn` | an index column | `null` removes it, so the columns get all the width. |

---

## Behavior

### Sizing

- The grid **fills its parent** and needs bounded constraints on both
  axes. In a `Dialog`, `Column` or `Row`, wrap it in a `SizedBox`,
  `Expanded` or `Flexible`. An unbounded height (directly inside a
  `ListView` or `SingleChildScrollView`) can't be laid out.
- The width the columns need is the sum of their widths, plus each
  column's right border (`columnBorderWidth` when `showColumnBorders` is
  on), plus the vertical scrollbar strip when it's reserved. The index
  column and any pinned columns add their own widths.
- Height is the header, the filter row if shown, the rows and the
  pagination bar.

### Stretching

With `stretchColumnsToFillWidth`:

- When the scrollable columns are narrower than the space for them, they
  grow **by the same factor**, keeping their proportions.
- A column stops at its `maxStretchWidth`; the others take its share.
- Columns never shrink below their `width`; a table wider than the box
  scrolls as usual.
- Pinned-left columns don't stretch.
- Stretching sets the columns' real widths, so resize handles,
  `columns.widths` and autofill see what's on screen. A column the user
  resizes keeps its new weight in later stretches.
- It recomputes when the box's size changes, such as when a dialog is
  resized.

### The vertical scrollbar strip

| Setting | Space after the last column |
| --- | --- |
| `afterLastColumn` (default) | The scrollbar's thickness plus a small margin, whether or not the rows overflow. |
| `overlay` | None; the scrollbar draws over the last column. |
| `showVerticalScrollbar: false` | None. |
| `external` | None; see [Scrollbar](scrollbar.md#external-scrollbars). |

The vertical scrollbar never changes where the horizontal scroll ends: the
last column is always reachable, and the table never scrolls past it.

---

## Runtime API

None specific to dialogs. Read or set widths through `gridManager.columns`
(`widths`, `setWidths`, `autoFitWidths`); see
[Column operations](column-operations.md).

---

## Events

None.

---

## Customization

- **Cap a short column** so wide ones take the space:

```dart
GridSheetColumn(key: statusKey, index: 3, name: 'STATUS', title: 'Status',
    type: const GridSheetColumnType.text(), width: 100, maxStretchWidth: 110),
```

- **Size the dialog to the table**: sum the column widths and borders, and
  add `thickness + 4` for the scrollbar strip under `afterLastColumn`, or
  use `overlay` to skip it.

---

## Limitations

- **No intrinsic size.** The grid doesn't size itself to its content; the
  parent sets its size.
- **Stretching only grows columns**, never shrinks them to fit.
- **Pinned-left columns don't stretch.**

---

## See also

- [Scrollbar](scrollbar.md)
- [Column operations](column-operations.md): widths and auto-fit
- [Layout widgets](layout-widgets.md): bars and placeholders around the grid
