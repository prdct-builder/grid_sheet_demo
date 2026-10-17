# Fixed columns

Columns can be **pinned** (frozen) to the left or right edge, so they stay
in view while the other columns scroll horizontally, like Excel's Freeze
Panes. Pin them when the grid is built or at runtime, insert new columns
straight into a pinned pane, and style each pane and its divider.

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

Pin when the grid is built:

```dart
GridSheetColumn(key: const ValueKey('id'), index: 0, name: 'id', title: 'ID', pinnedLeft: true),
GridSheetColumn(key: const ValueKey('status'), index: 9, name: 'status', title: 'Status', pinnedRight: true),
```

Or at runtime:

```dart
await gridManager.columns.pin(leftKeys: [idKey, nameKey], rightKeys: [statusKey]);
await gridManager.columns.unpinAll();
```

---

## Configuration

On `GridSheetColumn`:

| Property | Default | Meaning |
| --- | --- | --- |
| `pinnedLeft` | `false` | Pins the column to the left pane. |
| `pinnedRight` | `false` | Pins the column to the right pane. Wins when both are set. |

On `GridSheetConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enableReorderOnPinnedLeftColumns` / `…RightColumns` | `false` | Lets pinned columns be dragged within their pane. |
| `selectionIncludesPinnedLeftCells` / `…RightCells` | `false` | Extends a selected row's highlight into the pane. See [Selection](selection.md). |
| `conditionalFormatIncludesPinnedLeftCells` / `…RightCells` | `false` | Applies conditional formatting to the pane's cells too. See [Conditional formatting](conditional-format.md). |

On `GridSheetStyleConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `pinnedLeftDividerColor` | `null` | Draws a divider between the left pane and the scrollable columns. `null` draws none. |
| `pinnedRightDividerColor` | `null` | The same for the right pane. Independent of the left one. |
| `pinnedColumnsDividerWidth` | `1` | Both dividers' width. Only visible on a side whose color is set. |
| `pinnedLeftColumnColor` | `null` | A background for the left pane's cells, over the row colors. |
| `pinnedRightColumnColor` | `null` | The same for the right pane. |

---

## Behavior

### Layout

- Pinned columns don't scroll horizontally. The scrollable columns scroll
  between the two panes, and the vertical scrollbar sits after the right
  pane, at the grid's true right edge.
- A divider takes up its own width rather than covering cells: the
  scrollable area is narrower by `pinnedColumnsDividerWidth`.
- A pane's order follows the columns' order in `columns.all`. Pinning
  doesn't move a column; use `insertAt` with a `band` to place a new
  column at a specific spot in a pane.
- The index column is pinned on its own; see [Index column](index-column.md).

### Pinning and unpinning

| Call | Effect |
| --- | --- |
| `pin(leftKeys:, rightKeys:)` | Pins the listed columns; leaves the others as they are. A column in both lists goes right. |
| `pinTo(leftCount, rightCount)` | Pins the first `leftCount` scrollable columns left and the last `rightCount` right. |
| `unpin(keys)` | Unpins the listed columns, leaving other pins alone. |
| `unpinAll()` | Unpins every column, however it was pinned. |

`pin` and `pinTo` return `null` on success, or an error message: an
unknown key, or counts that are negative or add up to more columns than
are unpinned.

```dart
final error = await gridManager.columns.pinTo(2, 1); // two left, one right
if (error != null) showSnackBar(error);
```

### Inserting into a pane

`columns.insertAt` with `band: GridSheetColumnBand.left` or `.right` puts
new columns straight into a pane, next to a column of that pane (or at its
end with `key: null`):

```dart
await gridManager.columns.insertAt(
  null,                          // end of the left pane
  [notesColumn],
  defaultValues: const [''],
  band: GridSheetColumnBand.left,
);
```

`columns.insert` and `columns.duplicate` never insert into a pane.

### Reordering pinned columns

With `enableReorderOnPinnedLeftColumns` or `…RightColumns`, a pinned
column's header can be dragged onto another header **in the same pane**. A
drop into another pane is rejected. `columns.reorder` works on any column,
pinned or not, and is governed by `enableColumnReorder` alone.

---

## Runtime API

`gridManager.columns`:

| Member | Description |
| --- | --- |
| `pinnedLeft` / `pinnedRight` / `scrollable` | The columns in each section. |
| `pin({leftKeys, rightKeys})` | Pins columns by key; returns an error or `null`. |
| `pinTo(leftCount, rightCount)` | Pins by count; returns an error or `null`. |
| `unpin(keys)` / `unpinAll()` | Unpins. |
| `insertAt(key, columns, {band, position, defaultValues})` | Inserts into a pane with `band: .left` / `.right`. |
| `duplicateAt(key, keys, newKeys, {band, position})` | Duplicates into a pane. |

```dart
gridManager.columns.pinnedLeft.map((c) => c.name); // ['ID', 'NAME']
```

---

## Events

No events of their own. Selecting a column, pinned or not, fires
`onColumnsSelected`; see [Selection](selection.md).

---

## Customization

```dart
styleConfiguration: GridSheetStyleConfiguration(
  pinnedLeftDividerColor: Colors.indigo,
  pinnedRightDividerColor: Colors.pink,
  pinnedColumnsDividerWidth: 2,
  pinnedLeftColumnColor: Colors.amber.withValues(alpha: 0.12),
  pinnedRightColumnColor: Colors.amber.withValues(alpha: 0.20),
),
```

A pane color overrides the row's own color (plain, striped or pinned-row),
but selection and conditional formatting still draw over it.

---

## Limitations

- **Row highlights stop at the panes by default.** A selected or
  conditionally formatted row doesn't color its pinned cells unless the
  matching `…IncludesPinned…Cells` option is on. A selected cell is always
  highlighted.
- **Pinned columns need room.** Pin too many and the scrollable area has
  little or no width left.

---

## See also

- [Fixed rows](fixed-rows.md): pinning rows
- [Index column](index-column.md): the pinned row-number column
- [Column operations](column-operations.md)
- [Selection](selection.md) · [Conditional formatting](conditional-format.md)
- [Scroll configuration](scrollbar.md)
