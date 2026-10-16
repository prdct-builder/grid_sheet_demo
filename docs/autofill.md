# Autofill

Autofill is Excel's fill handle: select a cell, then drag the small handle
at its corner across neighboring cells to copy its value or continue a
series (`1, 2, 3 → 4, 5, 6`, `Mon, Tue → Wed`, `Item 1 → Item 2`, dates,
formulas). The same fills run from code through `cells.autoFillVertical`
and `cells.autoFillHorizontal`.

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
  configuration: const GridSheetConfiguration(enableCellSelection: true),
  autoFillConfiguration: const GridSheetAutoFillConfiguration(enabled: true),
)
```

Select a cell and drag the handle at its bottom-right corner.

---

## Configuration

`GridSheet.autoFillConfiguration` takes a `GridSheetAutoFillConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enabled` | required | Turns autofill on, for the handle and the API. |
| `enablePatternDetection` | `true` | Continues series (numbers, dates, names, numbered text, formulas). `false` copies the source values as they are. It also limits the API's own `enablePatternDetection`. |
| `enforceTypeMatching` | `true` | A horizontal fill only writes into columns of the same type as the source. |
| `showPreviewOverlay` | `true` | Highlights the target cells while dragging. |
| `fillHandleSize` | `6` | The handle's size. |
| `fillHandleColor` | `selectionColor` | The handle's color. |
| `fillHandleShape` | `BoxShape.rectangle` | `rectangle` or `circle`. |
| `fillHandleBorderRadius` | `BorderRadius.zero` | Corner radius of a rectangular handle. |
| `dragCursor` | `SystemMouseCursors.cell` | The mouse cursor over the handle. |
| `enableOnPinnedTopRows` / `…BottomRows` | `false` | Lets fills run inside a pinned band. See [Fixed rows](fixed-rows.md). |

---

## Behavior

### The handle

- With `enableCellSelection` on, the handle appears on the selected cell
  (the bottom-right one of a multi-cell selection), and a fill drag starts
  only from it.
- With cell selection off, no handle is shown; a drag from **any** cell's
  bottom-right corner fills from that cell.
- Drag down or up to fill the column, left or right to fill the row. The
  source is the cell (or selected cells) you dragged from.

### Patterns

With `enablePatternDetection`, the fill continues what the source cells
show:

| Source | Fills |
| --- | --- |
| `1, 2, 3` | `4, 5, 6` (any constant step) |
| `2024-01-01, 2024-01-02` | `2024-01-03, 2024-01-04` |
| `Mon, Tue` | `Wed, Thu` (full and short day names) |
| `Jan, Feb` | `Mar, Apr` (full and short month names) |
| `Item 1, Item 2` | `Item 3, Item 4` (text ending in a number) |
| `=A1*2` | `=A2*2, =A3*2` (cell references shift) |
| Anything else | The source values repeated |

Without it, the source values are copied as they are.

### Type matching

With `enforceTypeMatching` (the default), a **horizontal** fill skips target
columns whose type differs from the source column's: filling right from an
integer column writes only into integer columns. Vertical fills stay in one
column, so they're never affected.

### What a fill writes

Each filled cell is written like an edit: rows become modified, formulas
recompute, `onCellValueChanged` fires, and the whole fill is one undo step
(Ctrl+Z). Read-only cells are skipped.

---

## Runtime API

`gridManager.cells`. Both are no-ops unless `enabled` is on.

| Member | Fills |
| --- | --- |
| `autoFillVertical({startRowKey, endRowKey, columnKey, sourceValues, enablePatternDetection, skipRowKeys, includePinnedBands})` | A column, from `startRowKey` to `endRowKey`, continuing `sourceValues`. |
| `autoFillHorizontal({startRowKey, endRowKey, startColumnKey, endColumnKey, sourceValues, enablePatternDetection, includePinnedBands})` | Rows, from `startColumnKey` to `endColumnKey`, continuing `sourceValues`. |
| `fill({startRowKey, endRowKey, columnKey, value, increment})` | A column with one value, or counting up from a number. Works without autofill on. See [Cell operations](cell-operations.md). |

```dart
// Continue 100, 118 down the column: 136, 154, …
await gridManager.cells.autoFillVertical(
  startRowKey: const ValueKey('row_0'),
  endRowKey: const ValueKey('row_7'),
  columnKey: unitsKey,
  sourceValues: const [100, 118],
);
```

`autoFillVertical` throws an `ArgumentError` for an unknown row or column,
an empty `sourceValues`, or a pinned row whose band isn't in
`includePinnedBands`.

---

## Events

No events of its own. Each filled cell fires `onCellValueChanged`.

---

## Customization

```dart
autoFillConfiguration: GridSheetAutoFillConfiguration(
  enabled: true,
  fillHandleSize: 8,
  fillHandleColor: Colors.blue,
  fillHandleShape: BoxShape.circle,
),
```

---

## Limitations

- **Horizontal fills respect column types** by default; set
  `enforceTypeMatching: false` to fill across types.
- **Pinned rows are left out** unless `enableOnPinnedTopRows` /
  `…BottomRows` (and, for the API, `includePinnedBands`) allow them.
- **Patterns follow the source as typed.** A column of numbers stored as
  text continues as text.

---

## See also

- [Cell operations](cell-operations.md): `fill`, undo
- [Fixed rows](fixed-rows.md): autofill in pinned bands
- [Formula columns](formula-columns.md): filling formulas
- [Selection](selection.md)
