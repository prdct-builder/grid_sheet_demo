# Right-to-left (RTL) support

`GridSheet` lays out right to left for Arabic, Hebrew, Persian and other RTL
languages: columns run from the right, text aligns to the right, and every
handle, icon and scroll direction mirrors. It follows the app's
`Directionality` by default, or a direction you set for one grid.

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

A grid inside an RTL app is RTL with no setup. To set one grid's direction
yourself:

```dart
GridSheet(
  columns: columns,
  rows: rows,
  direction: GridSheetDirection.rightToLeft,
)
```

---

## Configuration

| Option | Default | Meaning |
| --- | --- | --- |
| `GridSheet.direction` | `null` | `GridSheetDirection.leftToRight` or `.rightToLeft`. `null` follows the surrounding `Directionality` (usually set by `MaterialApp` from the locale). |
| `GridSheetColumn.textAlign` | `TextAlign.start` | Use `start` and `end`, not `left` and `right`, so alignment mirrors with the direction. |
| `GridSheetColumn.pinnedLeft` / `pinnedRight` | `false` | **Logical** sides: `pinnedLeft` pins to the reading start (the right edge under RTL), `pinnedRight` to the reading end. |

---

## Behavior

Under RTL, everything that has a side mirrors together:

| Mirrors | Under RTL |
| --- | --- |
| Column order | The first column is at the right. |
| Text alignment | `start` aligns right, `end` aligns left. |
| Pinned columns | `pinnedLeft` columns sit at the right edge, `pinnedRight` at the left. |
| Index column | At the right edge (or the left with `pinnedRight`). |
| Horizontal scrolling | Scrolls from the right; the scrollbar follows. |
| Resize handles | On each column's left edge. |
| Fill handle | At each cell's bottom-left corner. |
| Column drag | Drop targets and the drop indicator mirror. |
| Sort arrows, chevrons, pagination arrows | Mirror to point the reading way. |
| Borders and dividers | Follow the columns. |

What **doesn't** change:

- **Identity.** Keys, sort state, filters and selection belong to columns,
  not screen positions. A selected cell stays selected when the direction
  changes.
- **The API.** `columns.all`, `at(index)`, `reorder` and every other call
  use reading order, which is the same in both directions.
- **Keyboard.** The Left and Right arrow keys move by screen position,
  as in every RTL app: Right moves toward the previous column under RTL.
  Tab and Shift+Tab follow reading order in both directions.

---

## Runtime API

There's no API on `gridManager` for the direction. Change it by passing a
different `direction` to the `GridSheet`; the grid relays out at once,
keeping its state.

---

## Events

None. Events report keys and reading-order indexes, the same in both
directions.

---

## Customization

Custom cells (`GridSheet.cellBuilder`) and wrappers are built inside the
grid's `Directionality`, so widgets that use `start` / `end`
(`EdgeInsetsDirectional`, `AlignmentDirectional`, `Row`) mirror with it.
Avoid fixed `left` / `right` in them.

---

## Limitations

- **Fixed `left` / `right` doesn't mirror.** `TextAlign.left` and
  `TextAlign.right` on a column, and fixed sides in your own widgets, stay
  where they are.

---

## See also

- [Fixed columns](fixed-columns.md): pinning sides
- [Layout widgets](layout-widgets.md)
- [Custom cells](custom-cells.md)
