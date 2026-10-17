# Row grouping

Row grouping gathers rows that share a value under **collapsible group
headers**, one or more levels deep (Region › Category), with aggregates
such as sums and averages per group and an optional grand total. Groups can
be by exact value, by date part, by number range, or by your own rule.

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
  groupingConfiguration: GridSheetGroupingConfiguration(
    enabled: true,
    rows: GridSheetRowGroupingConfiguration(
      groupBy: const [GridSheetGroupDescriptor(columnKey: regionKey, title: 'Region')],
      aggregates: const [GridSheetAggregateSpec.sum(amountKey, label: 'Total')],
      showGrandTotal: true,
    ),
  ),
)
```

---

## Configuration

### GridSheetGroupingConfiguration

`GridSheet.groupingConfiguration`, shared with
[Column grouping](column-grouping.md):

| Option | Default | Meaning |
| --- | --- | --- |
| `enabled` | `false` | Turns grouping on. |
| `rows` | `null` | The row grouping, below. `null` means no row groups. |
| `columns` | `null` | Column groups. See [Column grouping](column-grouping.md). |
| `expandedByDefault` | `true` | Whether groups start expanded. |
| `onExpansionChanged` | `null` | Called when groups expand or collapse. See [Events](#events). |

### GridSheetRowGroupingConfiguration

| Option | Default | Meaning |
| --- | --- | --- |
| `groupBy` | `[]` | The grouping levels, outermost first. Empty means no grouping. |
| `aggregates` | `[]` | Aggregates computed for every group and the grand total. |
| `aggregatePosition` | `header` | Where aggregates show: `header` (visible while collapsed), `footer` (a subtotal line after the group's rows), `both`, or `none` (computed only). |
| `showGrandTotal` | `false` | Ends the rows with a grand-total line. |
| `labelColumnSpan` | `1` | How many columns the group label may span. Aggregates show in the columns after it. |
| `cellBuilder` | `null` | Builds group header and summary cells yourself. See [Customization](#customization). |

### Levels: GridSheetGroupDescriptor

```dart
GridSheetGroupDescriptor(columnKey: regionKey, title: 'Region')            // by value
GridSheetGroupDescriptor.date(dateKey, GridSheetGroupDatePart.quarter)     // Q1 2024, …
GridSheetGroupDescriptor.range(amountKey, [500, 2000],                     // < 500, 500–2,000, ≥ 2,000
    labels: ['Small', 'Medium', 'Large'])
GridSheetGroupDescriptor(columnKey: categoryKey,
    sort: const GridSheetGroupSort.aggregate('sum:amount'))                // biggest totals first
```

| Member | Meaning |
| --- | --- |
| `columnKey` | The grouped column. |
| `bucketer` | Decides each row's group: by value (default), date part, number range, or your own function. |
| `sort` | How sibling groups are ordered: first appearance (default), by value, by row count, by an aggregate, or your own comparator. |
| `title` | Shown before the group's label. |

The bucketers and sorts are the same as the pivot table's; see
[Fields](pivot.md#fields-gridsheetgroupdescriptor) for every option.

### Aggregates: GridSheetAggregateSpec

```dart
GridSheetAggregateSpec.sum(qtyKey, label: 'Qty')
GridSheetAggregateSpec.average(amountKey, label: 'Avg')
GridSheetAggregateSpec.count(productKey)
GridSheetAggregateSpec.min(amountKey)
GridSheetAggregateSpec.max(amountKey)
```

Each aggregate shows in its column on the group lines. Its `id` (for
example `sum:col_amount`) is how sorting and custom cells refer to it. See
[Values](pivot.md#values-gridsheetaggregatespec).

---

## Behavior

- **Headers.** Each group gets a header line with a chevron, its title,
  label and row count. Tap the header to collapse or expand it.
- **Aggregates** cover the group's rows that pass filters and search.
- **Sorting** orders the rows inside each group; groups keep their own
  order (`sort` on the descriptor).
- **Selection.** With row and multi-selection on, a group header has a
  checkbox selecting all of the group's rows. See
  [Selection](selection.md#row-groups).
- **Pagination.** With client-side pagination, each page holds
  `rowsPerPage` lines, group headers and summary lines included.
- **Everything else keeps working** on the data rows: editing, keyboard
  navigation, row expansion, separators, swipe and autofill.
- Pinned rows are never grouped.
- While grouped, rows can't be reordered by dragging.

---

## Runtime API

`gridManager.grouping.rows` (`GridSheetRowGroupingAPI`):

| Member | Description |
| --- | --- |
| `isActive` | Whether rows are grouped now. |
| `groupBy` / `setGroupBy(levels)` | The levels; an empty list removes grouping. |
| `aggregates` / `setAggregates(specs)` | The aggregates. |
| `groups` | The outermost groups, in display order (each with `id`, `label`, `count`, `level`, children and aggregates). |
| `find(groupId)` / `groupOf(rowKey)` | A group by id, or the innermost group holding a row. |
| `isExpanded(id)` / `expand(ids)` / `collapse(ids)` / `toggle(id)` | One group's expansion. |
| `expandAll()` / `collapseAll()` / `expandToLevel(level)` | Every group's expansion. |
| `scrollTo(groupId)` | Scrolls a group's header to the top. |

```dart
final rows = gridManager.grouping.rows;
rows.setGroupBy([
  const GridSheetGroupDescriptor(columnKey: regionKey),
  const GridSheetGroupDescriptor(columnKey: categoryKey),
]);
rows.expandToLevel(1); // regions open, categories closed
```

Changes made through the API replace the widget's configuration until the
parent passes a different one. They do nothing while grouping is disabled.

---

## Events

### GridSheetGroupingConfiguration.onExpansionChanged: GridSheetGroupExpansionEvent

| Field | Description |
| --- | --- |
| `axis` | `GridSheetGroupAxis.rows` or `.columns`. |
| `groupId` | The group that changed, or `null` when several did (e.g. `expandAll`). |
| `expanded` | `true` / `false`, or `null` when some groups expanded and others collapsed. |
| `gridManager` | The grid. |

---

## Customization

`GridSheetRowGroupingConfiguration.cellBuilder` builds any cell of a group
header or summary line; return `null` to keep the default. `cell.kind` is
one of `headerIndex`, `headerLabel`, `headerAggregate`, `summaryIndex`,
`summaryLabel` or `summaryAggregate`, and the context provides the group,
its label and count, its `aggregates`, `isExpanded`, `onToggleExpansion`,
and the selection state (`isSelected`, `onSelectionChanged`):

```dart
cellBuilder: (cell) {
  if (cell.kind != GridSheetRowGroupCellKind.headerLabel) return null;
  return Row(children: [
    IconButton(
      icon: Icon(cell.isExpanded ? Icons.expand_more : Icons.chevron_right),
      onPressed: cell.onToggleExpansion,
    ),
    Chip(label: Text(cell.label)),
    Text('${cell.count} orders'),
  ]);
},
```

Group lines use the grid's default row height and header colors and text
styles.

---

## Limitations

- **No dragging rows while grouped.**
- **Group lines have the default row height.**
- **The form layout shows its cards in one list** while grouped.

---

## See also

- [Column grouping](column-grouping.md)
- [Pivot table](pivot.md): the same fields and values, summarized
- [Selection](selection.md#row-groups)
- [Custom cells](custom-cells.md)
