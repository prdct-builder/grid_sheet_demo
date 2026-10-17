# Wrappers

Wrappers put your own widget **around** the grid's header row, filter row
and data rows, without replacing their cells. Use them for card-style rows,
rounded headers, hover shadows or custom selection highlights; the cells
inside keep editing, selection and everything else.

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
  styleConfiguration: const GridSheetStyleConfiguration(leftPadding: 8, rightPadding: 8),
  rowWrapper: (context, child, details) => Padding(
    padding: EdgeInsets.only(
      top: 4,
      left: details.pinnedLeft ? 8 : 0,
      right: details.pinnedLeft ? 0 : 8,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: details.selected ? Colors.blue.shade50 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    ),
  ),
)
```

---

## Configuration

### The wrappers

| `GridSheet` option | Signature | Wraps |
| --- | --- | --- |
| `headerWrapper` | `(context, child, GridSheetHeaderWrapperDetails details)` | The column header row. |
| `filterWrapper` | `(context, child, GridSheetFilterWrapperDetails details)` | The filter row. |
| `rowWrapper` | `(context, child, GridSheetRowWrapperDetails details)` | Each data row. |

Each returns a widget that contains `child`. `null` (the default) keeps the
built-in look.

### Details

| Field | Header | Filter | Row | Meaning |
| --- | :-: | :-: | :-: | --- |
| `gridManager` | ✓ | ✓ | ✓ | The grid. |
| `pinnedLeft` | ✓ | ✓ | ✓ | This is the pinned-left section. |
| `pinnedRight` | ✓ | ✓ | ✓ | This is the pinned-right section. Both `false` means the scrollable section. |
| `row` | | | ✓ | The row being wrapped. |
| `hovered` | | | ✓ | The pointer is over the row; needs `enableRowHover`. |
| `selected` | | | ✓ | The row is selected (`selection.rowKeys`). Selecting a single cell doesn't select its row. |

### Padding

| `GridSheetStyleConfiguration` option | Default | Meaning |
| --- | --- | --- |
| `leftPadding` | `0` | Width reserved before the pinned-left section, for the wrapper's left padding. |
| `rightPadding` | `0` | Width reserved after the last section (pinned-right if there is one, otherwise the scrollable one). |

Both apply only while at least one wrapper is set.

---

## Behavior

### Sections

A row is built in up to three sections: pinned-left (which holds the index
column), scrollable, and pinned-right. **Each wrapper is called once per
section**, so a card-style row is really two or three pieces side by side.
Use `pinnedLeft` / `pinnedRight` to round only the outer corners and pad
only the outer edges.

### Padding must match

Horizontal padding inside a wrapper must use exactly `leftPadding` and
`rightPadding`, on the sections that reserve them; otherwise the content
overflows or is clipped:

- Add `leftPadding` on the left of the `pinnedLeft` section.
- Add `rightPadding` on the right of the last section: `pinnedRight` when
  there are right-pinned columns, otherwise the scrollable section.

```dart
EdgeInsets sidePadding(bool pinnedLeft, bool pinnedRight, GridSheetManager grid) {
  final last = grid.columns.pinnedRight.isEmpty ? !pinnedLeft && !pinnedRight : pinnedRight;
  return EdgeInsets.only(left: pinnedLeft ? 8 : 0, right: last ? 8 : 0);
}
```

Vertical padding (`top: 4`) is free: it's taken from inside the row's
height, so leave room for it in `GridSheetRow.height` and `headerHeight` /
`filterHeight`.

### Rebuilds

The row wrapper is called again when the row's hover or selection changes,
and when the row rebuilds. Keep it cheap: no async work, no heavy layout.

### What wrappers don't change

- Cell content, editing, selection and keyboard navigation are untouched.
- Pinned rows go through `rowWrapper` like any other row.
- `leftPadding` and `rightPadding` stay physically left and right under
  RTL; apply your padding on the matching sides.

---

## Runtime API

None. Pass `null` to remove a wrapper, or a new function to change it.
`details.gridManager` lets a wrapper read grid state, for example to tint
rows with active filters:

```dart
headerWrapper: (context, child, details) => DecoratedBox(
  decoration: BoxDecoration(
    border: details.gridManager.filters.active.isEmpty
        ? null
        : const Border(bottom: BorderSide(color: Colors.orange, width: 2)),
  ),
  child: child,
),
```

---

## Events

None.

---

## Customization

### Hover and selection

Turn on `enableRowHover`, and set `selectionColor` to transparent if the
wrapper draws its own selection:

```dart
configuration: const GridSheetConfiguration(enableRowHover: true),
styleConfiguration: const GridSheetStyleConfiguration(selectionColor: Colors.transparent),
rowWrapper: (context, child, details) => AnimatedContainer(
  duration: const Duration(milliseconds: 120),
  decoration: BoxDecoration(
    color: details.selected ? Colors.blue.shade50 : null,
    boxShadow: details.hovered || details.selected
        ? const [BoxShadow(blurRadius: 6, color: Colors.black12)]
        : null,
  ),
  child: child,
),
```

### Dashed and dotted lines

`GridSheetDashedBorder` works wherever a `Border` does, including a
wrapper's `BoxDecoration`:

| Constructor | Draws |
| --- | --- |
| `GridSheetDashedBorder(top:, right:, bottom:, left:, dashLength: 6, gapLength: 2, strokeCap:)` | Dashes per side. |
| `GridSheetDashedBorder.all(side, …)` | The same dashes on all sides. |
| `GridSheetDashedBorder.dotted(side: or top/right/bottom/left:, spacing: 2)` | Round dots as wide as the side. |

```dart
border: GridSheetDashedBorder.dotted(
  bottom: BorderSide(color: Colors.grey.shade400, width: 1.5),
  spacing: 3,
),
```

Rounded corners are followed when all four sides are the same.

---

## Limitations

- **One call per section.** A wrapper can't draw one continuous box across
  pinned and scrollable columns; draw matching pieces instead.
- **No horizontal padding beyond `leftPadding` / `rightPadding`.**
- **No column wrapper.** For per-cell looks, use
  [custom cells](custom-cells.md) or [styling](styling.md).

---

## See also

- [Styling](styling.md): colors, borders, text styles
- [Custom cells](custom-cells.md)
- [Fixed columns](fixed-columns.md): the pinned sections
