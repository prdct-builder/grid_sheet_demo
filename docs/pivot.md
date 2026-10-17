# Pivot tables

`GridSheet` can summarize its rows as a pivot table, like Excel's PivotTable:
**row fields** group the rows into lines down the side, **column fields**
group them into columns across the top, and **values** are computed from the
rows each line and column share. It can also add grand totals, subtotals and
averages.

The pivot is read-only. It replaces the table in the grid's body and keeps
the table's own state (rows, selection, changes, scroll) as it is, so

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
const regionKey = ValueKey<String>('region');
const dateKey = ValueKey<String>('date');
const amountKey = ValueKey<String>('amount');

GridSheet(
  columns: columns,
  rows: rows,
  pivotConfiguration: GridSheetPivotConfiguration(
    rowFields: [GridSheetGroupDescriptor(columnKey: regionKey)],
    columnFields: [GridSheetGroupDescriptor.date(dateKey, GridSheetGroupDatePart.year)],
    values: [GridSheetAggregateSpec.sum(amountKey)],
  ),
)
```

| Row Labels | 2024 | 2025 | Grand Total |
| ---------- | ---: | ---: | ----------: |
| EU         | 150  | 200  | 350         |
| US         | 300  | (Blanks) | 300     |
| **Grand Total** | 450 | 200 | 650     |

Filters and search apply before the rows are summarized, and the pivot
updates when rows are added, edited or removed.

---

## Configuration

### Showing the pivot: view modes

Which body the grid shows is set by `GridSheet.viewMode`:

| `GridSheetViewMode` | Shows |
| --- | --- |
| `auto` (default) | The pivot when `pivotConfiguration` is set, otherwise the table. |
| `pivot` | The pivot. |
| `table` | The table, even with a pivot configured. |
| `form` | The card-based form layout. |
| `responsive` | The form below `GridSheetFormConfiguration.breakpoint`, the table above it. |

`auto` and `pivot` fall back to the table in these cases, and report why
**once** through `GridSheet.onError` (`GridSheetErrorSource.pivot`):

- no `pivotConfiguration` is set (`pivot` only);
- the configuration has no `values`;
- the rows come from a server (`serverSidePagination` or `infiniteScroll`)
  and `onPivotRequest` isn't set. See
  [Rows from a server](#rows-from-a-server-onpivotrequest).

Switch views at runtime:

```dart
gridManager.config.setViewMode(GridSheetViewMode.table);
gridManager.config.viewMode; // the view mode in effect
```

A value set this way stays until the parent passes a different
`GridSheet.viewMode`.

While the pivot shows, `GridSheet.groupingConfiguration` (row and column
grouping of the table) is ignored. Debug builds print a warning once. The
pagination bar is hidden.

### GridSheetPivotConfiguration

```dart
const GridSheetPivotConfiguration({
  List<GridSheetGroupDescriptor> rowFields = const [],
  List<GridSheetGroupDescriptor> columnFields = const [],
  List<GridSheetAggregateSpec> values = const [],
  bool showRowGrandTotal = true,
  bool showColumnGrandTotal = true,
  bool showRowSubtotals = true,
  bool showColumnSubtotals = true,
  bool showRowAverage = false,
  bool showColumnAverage = false,
  int maxColumns = 500,
  bool expandedByDefault = true,
  List<GridSheetConditionalFormatRule> conditionalFormatRules = const [],
})
```

Every option is optional, so later releases can add options without breaking
this constructor. It is immutable, with value equality and `copyWith`.

| Option | Default | Meaning |
| --- | --- | --- |
| `rowFields` | `[]` | Row fields, outermost first. One line per group, nested. Empty means a single Grand Total line, as in Excel. |
| `columnFields` | `[]` | Column fields, outermost first. One column per bucket (and per value), under stacked headers. Empty means the values appear once per line, as their grand total. |
| `values` | `[]` | What's computed where a line and a column meet. **At least one is needed** for the pivot to show. |
| `showRowGrandTotal` | `true` | A **Grand Total column** at the right: each line's value over all column buckets. |
| `showColumnGrandTotal` | `true` | A **Grand Total line** at the bottom: each column's value over all row groups. |
| `showRowSubtotals` | `true` | With 2+ row fields, an outer group's line shows its subtotals. When `false`, it shows only its label. |
| `showColumnSubtotals` | `true` | With 2+ column fields, each outer bucket gets a **Total** column after its inner buckets, inside its header band. |
| `showRowAverage` | `false` | An **Average column** at the right, before the Grand Total: the mean of each line's bucket values, skipping empty ones. |
| `showColumnAverage` | `false` | An **Average line** at the bottom, above the Grand Total: the mean of each column's values over the outermost row groups, skipping empty ones. |
| `maxColumns` | `500` | The most bucket and subtotal columns shown (must be ≥ 1). Beyond it, the first ones in sort order are shown, and the cut is reported through `onError`. Totals and averages still count every bucket. |
| `expandedByDefault` | `true` | Whether row groups start expanded. |
| `conditionalFormatRules` | `[]` | Conditional formatting for pivot cells. See [Formatting](#formatting). |

**How totals are computed.** A grand total or subtotal is computed from the
**rows** with the value's own aggregator, not by adding up the cells. That
makes it correct for averages, minimums and maximums too: the average of a
total is the average of all its rows. Averages (the Average column and line)
are means of the **shown values**.

### Fields: GridSheetGroupDescriptor

A field groups rows by one column. The same type is used by row grouping, so
everything below works in both.

```dart
// By exact value (the default bucketer); groups in first-appearance order.
GridSheetGroupDescriptor(columnKey: regionKey)

// Sorted by value, with a title for the row-labels header.
GridSheetGroupDescriptor(
  columnKey: regionKey,
  title: 'Region',
  sort: const GridSheetGroupSort.value(),
)

// Dates by year / quarter / month / day (sorted chronologically).
GridSheetGroupDescriptor.date(dateKey, GridSheetGroupDatePart.quarter)

// Numbers by range: < 0, 0 – 100, 100 – 500, ≥ 500.
GridSheetGroupDescriptor.range(amountKey, [0, 100, 500])
```

| Member | Meaning |
| --- | --- |
| `columnKey` | The grouped column. Fields naming an unknown column are ignored. |
| `bucketer` | Decides each row's group (see below). Default: `GridSheetGroupValueBucketer()`. |
| `sort` | How sibling groups are ordered. Default: `GridSheetGroupSort.firstAppearance()`. |
| `title` | Shown in the row-labels header. Row field titles are joined with ` / `, and the column's own title is used when this is null. |

#### Bucketers

| Bucketer | Groups by | Label example |
| --- | --- | --- |
| `GridSheetGroupValueBucketer` | Exact value. Strings are trimmed; `1` and `1.0` share a group. | `EU` |
| `GridSheetGroupDateBucketer(part)` | `DateTime` or ISO-8601 text by `year`, `quarter`, `month`, `day`. | `2024`, `Q1 2024`, `Jan 2024`, `2024-01-31` |
| `GridSheetGroupRangeBucketer(boundaries, labels:)` | Numeric ranges; each includes its lower bound. | `0 – 100`, `≥ 500` |
| `GridSheetGroupCustomBucketer((value, row) => bucket)` | Your function. Create it once, never inline in `build()`. | anything |

Blank values, or values a built-in bucketer can't read, fall into one group
labelled `GridSheetConfiguration.blanksText` (`(Blanks)`).

#### Group sorting (`GridSheetGroupSort`)

| Constructor | Order |
| --- | --- |
| `.firstAppearance()` | The order the groups' first rows appear in (the grid's current sort). The default. |
| `.value({direction = asc})` | By the groups' values; blanks last. |
| `.count({direction = desc})` | By number of rows. |
| `.aggregate(id, {direction = desc})` | By an aggregate's value, e.g. `'sum:amount'`. In a pivot, a row group sorts by its line total and a column bucket by its column total. |
| `.custom(comparator)` | By your comparator over `GridSheetGroupSortEntry` (`label`, `sortValue`, `count`, `aggregate(id)`). |

The user can also re-sort the row groups by tapping a header. See
[Sorting](#sorting).

### Values: GridSheetAggregateSpec

```dart
GridSheetAggregateSpec.sum(amountKey)              // id 'sum:amount', label 'Sum'
GridSheetAggregateSpec.count(productKey)           // non-blank values
GridSheetAggregateSpec.average(amountKey)          // id 'avg:amount'
GridSheetAggregateSpec.min(amountKey)
GridSheetAggregateSpec.max(amountKey, label: 'Highest')
GridSheetAggregateSpec(columnKey: k, aggregator: myAggregator)
```

| Member | Meaning |
| --- | --- |
| `columnKey` | The summarized column. Values naming an unknown column are ignored. |
| `aggregator` | `GridSheetAggregators.sum` / `count` / `average` / `min` / `max`, or your own `GridSheetAggregator` (e.g. `GridSheetCustomAggregator`). |
| `label` | Overrides the aggregator's label in headers. |
| `id` | `'<aggregator id>:<column key>'`, e.g. `sum:amount`. This is the key of a value everywhere: sorting, server cells. |

Numbers are read the same way as everywhere else in the grid: `.` as the
decimal point and no thousands separators.

### Rows from a server: onPivotRequest

With `serverSidePagination` or `infiniteScroll`, the grid holds only a page
of rows, so it can't summarize them itself. Set `GridSheet.onPivotRequest`
and the **server** summarizes all of them, while the grid lays them out,
sorts, expands, totals the averages and exports just as for client rows.

```dart
final Future<GridSheetPivotData> Function(GridSheetPivotRequest request)? onPivotRequest;
```

It is ignored when the rows are on the client.

#### When the grid asks

| Triggers a request | Doesn't |
| --- | --- |
| The pivot starts showing | Showing/hiding totals, subtotals, averages |
| `rowFields`, `columnFields` or `values` change | `maxColumns`, `expandedByDefault` |
| Filters or search change (after the grid's server-filter debounce) | Sorting, expanding, collapsing |
| `gridManager.reload()` | Switching to the table and back without changes |

- **Requests are made after the frame**, so `onPivotRequest` may set state.
- **Only the latest request's answer is kept.** An older one that arrives
  late is dropped.
- **While it runs**, the grid shows `GridSheet.loadingIndicator` (if set)
  over the previous values. It shows the empty layout if there are no
  previous values yet.
- **On failure**, the error is reported to `onError`
  (`GridSheetErrorSource.pivot`) and the previous values stay. The same
  query isn't retried automatically; `reload()` retries it.

#### GridSheetPivotRequest

| Member | Description |
| --- | --- |
| `GridSheetPivotConfiguration configuration` | The fields and values. Read each field's `columnKey`, `bucketer` (e.g. `GridSheetGroupDateBucketer.part`, `GridSheetGroupRangeBucketer.boundaries`) and the values' `id`. |
| `Map<String, List<dynamic>> filters` | Active filters by column **name**, as in `GridSheetPageRequest`. |
| `Map<String, GridSheetFilterComparison> filterComparisons` | As in `GridSheetPageRequest`. |
| `List<dynamic> searchItems`, `bool searchExactMatch`, `bool searchSmartSyntax` | The search, as in `GridSheetPageRequest`. |
| `GridSheetManager gridManager` | The grid. |
| `groupingSets` | Every grouping the grid needs (see below). |

`groupingSets` is a `List<GridSheetPivotGroupingSet>`, each a
`({List<GridSheetGroupDescriptor> rowFields, List<GridSheetGroupDescriptor> columnFields})`
record. The list has every leading part of the row fields (none, the first, the
first two, …) combined with every leading part of the column fields. That is
SQL's:

```sql
GROUP BY ROLLUP(row1, row2, ...), ROLLUP(col1, col2, ...)
```

With rowFields `[region, product]` and columnFields `[year]`:

| rowFields | columnFields | gives |
| --- | --- | --- |
| – | – | the overall grand total |
| – | year | the Grand Total line's cells |
| region | – | each region's Grand Total column |
| region | year | each region's cells |
| region, product | – | each product line's Grand Total column |
| region, product | year | each product line's cells |

The grid needs **one cell per group of every set**. A missing one shows as
empty.

#### GridSheetPivotData and GridSheetPivotCellData

```dart
const GridSheetPivotData({required List<GridSheetPivotCellData> cells});

const GridSheetPivotCellData({
  List<Object?> rowGroupKeys = const [],    // one per row field, outermost first
  List<Object?> columnGroupKeys = const [], // one per column field, outermost first
  required Map<String, Object?> values, // by GridSheetAggregateSpec.id
});
```

**Each value must be computed over the group's rows.** Totals are not
summed from cells, so averages, minimums and maximums come out right.

**Keys.** A key is **any value in the group**. The grid buckets it with the
field's own bucketer, exactly as it would a row's value. Labels, sorting and
group ids therefore match a client pivot, and expansion state carries over.

| Field | Return as the key |
| --- | --- |
| By value | The value (`'EU'`); `null` for the blank group. |
| By date part | Any date in the period, e.g. its first day: `date_trunc('quarter', order_date)` → `DateTime` or ISO text. |
| By range | Any number in the range, e.g. its lower bound. |
| Custom bucketer reading other columns | A `GridSheetGroupBucket(id:, label:, sortValue:)`. The grid can't run the bucketer without the row, so it falls back to grouping by the key's value. |

You can return a `GridSheetGroupBucket` for any field to set the id, label and
sort value yourself.

Other rules:

- **Order:** cells can come in any order. Groups whose field sorts by
  `firstAppearance` show in the order they first appear in `cells`.
- **Count sort:** row counts aren't sent, so `GridSheetGroupSort.count`
  keeps the server's order. Sort by an aggregate (e.g. a count value)
  instead.
- **Ignored:** cells with more keys than fields, and value ids that aren't
  in the configuration.

#### Example: SQL

```sql
SELECT region,
       date_trunc('year', order_date) AS year,
       SUM(amount) AS sum_amount
FROM orders
WHERE ...filters from request.filters...
GROUP BY ROLLUP(region), ROLLUP(date_trunc('year', order_date));
```

```dart
onPivotRequest: (request) async {
  final result = await api.pivot(request); // runs the query above
  return GridSheetPivotData(cells: [
    for (final r in result)
      GridSheetPivotCellData(
        // In a ROLLUP, NULL marks "all", so leave rolled-up fields out. Use
        // SQL's GROUPING() to tell a rolled-up NULL from a blank value.
        rowGroupKeys: [if (!r.regionRolledUp) r.region],
        columnGroupKeys: [if (!r.yearRolledUp) r.year],
        values: {'sum:amount': r.sumAmount},
      ),
  ]);
},
```

#### Example: any backend (one query per grouping set)

```dart
onPivotRequest: (request) async {
  final cells = <GridSheetPivotCellData>[];
  for (final set in request.groupingSets) {
    final groups = await api.groupBy(
      fields: [...set.rowFields, ...set.columnFields].map((f) => f.columnKey.value),
      values: request.configuration.values.map((v) => v.id),
      filters: request.filters,
    );
    for (final g in groups) {
      cells.add(GridSheetPivotCellData(
        rowGroupKeys: g.keys.sublist(0, set.rowFields.length),
        columnGroupKeys: g.keys.sublist(set.rowFields.length),
        values: g.values,
      ));
    }
  }
  return GridSheetPivotData(cells: cells);
},
```

#### Drill-down on a server pivot

`GridSheetPivotCellTappedEvent.rows` and `pivot.rowsAt` are empty because the
rows are on the server. Use the keys instead: they are exactly what the
server returned for that cell.

```dart
onPivotCellTapped: (event) async {
  final orders = await api.ordersWhere(
    rowFields: configuration.rowFields, rowGroupKeys: event.rowGroupKeys,
    columnFields: configuration.columnFields, columnGroupKeys: event.columnGroupKeys,
  );
  showOrdersDialog(orders);
},
```

---

## Behavior

### What the table shows

#### Columns

From left to right:

1. **Row labels.** Its header is the row field titles (or `Row Labels`). Its
   key is `GridSheetPivotColumn.rowLabelsKey`.
2. **Bucket columns**, depth-first. With nested column fields, an outer
   bucket's **Total** (subtotal) columns follow its inner buckets inside its
   band.
3. **Average** columns (`showRowAverage`, with column fields).
4. **Grand Total** columns (`showRowGrandTotal`, or always when there are no
   column fields).

With **one** value, a column's title is its bucket label (`Q3`, under the
band `2025`). With **several** values, each bucket gets one column per value,
titled `Sum of Amount`, under the bucket's labels.

#### Lines

From top to bottom:

1. **Row groups**, nested by the row fields, following expansion.
2. **Average** line (`showColumnAverage`, with row fields).
3. **Grand Total** line (`showColumnGrandTotal`, or always when there are no
   row fields).

The summary lines stay pinned at the bottom.

#### Cells

- An empty cell shows `blanksText`.
- Whole doubles show without decimals, and other doubles with up to 2
  decimals.
- Outer group and summary lines show in bold.

### Interactions

#### Expanding row groups

A row group with inner groups has a chevron: tap it to expand or collapse
the group. The same can be done through the API (`expand`, `collapse`,
`expandAll`, `collapseAll`). Expansion state is kept by group id, so it
survives edits, filters and re-sorting.

#### Sorting

Tap a header to sort the row groups by that column, within each level:
ascending, then descending, then back to the fields' own order. An arrow
shows the direction.

- The row-labels header sorts by label.
- Empty values go last in both directions.
- Grand Total and Average lines stay at the bottom.

Sorting is done in the grid: a server pivot isn't requested again for it.

```dart
gridManager.pivot.sortBy(columnKey);                       // asc, or desc if already asc
gridManager.pivot.sortBy(columnKey, direction: GridSheetSortDirection.desc);
gridManager.pivot.sortBy(GridSheetPivotColumn.rowLabelsKey); // by label
gridManager.pivot.sort;       // GridSheetSortState? (key, name, direction)
gridManager.pivot.clearSort();
```

#### Collapsing column bands

With nested column fields and `showColumnSubtotals`, tap an outer band (e.g.
`2024`) to collapse it to its **Total** column, and tap again to expand it.

#### Drill-down

Set `GridSheet.onPivotCellTapped` to hear taps on values and row labels. Each
event carries the rows behind the cell. See
[GridSheetPivotCellTappedEvent](#gridsheetpivotcelltappedevent).

- Tapping a row label's **text** reports a tap; its chevron only expands.
- Drags don't count as taps, and the grid's own selection keeps working.

### Snapshots

`gridManager.snapshots.create()` also captures the view mode
(`GridSheetSnapshot.viewMode`) and the pivot's state
(`GridSheetSnapshot.pivot`, a `GridSheetPivotSnapshot`):

| `GridSheetPivotSnapshot` | |
| --- | --- |
| `configuration` | Fields, values, totals and format rules. |
| `sort` | The pivot sort (`pivot.sort`). |
| `toggledLineKeys` | Row groups whose expansion differs from `expandedByDefault`. |
| `columnWidths` | Widths set by the user or the API. |
| `hiddenColumnKeys` | Hidden pivot columns. |

`snapshots.restore(snapshot)` brings them back, so the pivot shows as it
was. A snapshot whose `viewMode` or `pivot` is `null` (e.g. built by hand)
leaves those as they are. The pivot's selection isn't captured, the same as
the table's.

### Errors and limits

| Situation | Behavior |
| --- | --- |
| No configuration / no values / server rows without `onPivotRequest` | The table shows; reported once through `onError`. |
| A field or value naming an unknown column | Ignored. |
| More bucket columns than `maxColumns` | The first `maxColumns` show; `isTruncated` is `true`; reported once. Totals still count everything. |
| `onPivotRequest` throws | Reported; previous values stay. |
| Editing in the pivot | Not possible: the pivot is read-only. |

Cost on the client: one grouping pass per row group over that group's rows,
O(rows × row levels × column levels). The result is cached until the rows,
their values, filters, columns or configuration change.

---

## Runtime API

`GridSheetPivotAPI`, obtained from `GridSheetManager.pivot`
(`GlobalKey<GridSheetState>().currentState!.pivot`, or `event.gridManager`).

Changes made here replace `GridSheet.pivotConfiguration` until the parent
passes a **different** one. Pass the configuration once (e.g. a `final`
field) and drive later changes through this API. Reads return empty results
while `isActive` is `false`.

### Configuration

| Member | Description |
| --- | --- |
| `GridSheetPivotConfiguration? configuration` | The current configuration. |
| `bool isActive` | Whether the pivot shows: the view mode resolves to it, a configuration with a value is set, and the rows are on the client or `onPivotRequest` is set. |
| `void setConfiguration(GridSheetPivotConfiguration? c)` | Replaces the whole configuration; `null` removes it. |
| `void setRowFields(List<GridSheetGroupDescriptor> rowFields)` | Replaces the row fields. |
| `void setColumnFields(List<GridSheetGroupDescriptor> columnFields)` | Replaces the column fields. |
| `void setValues(List<GridSheetAggregateSpec> values)` | Replaces the values. |

```dart
final pivot = gridManager.pivot;
pivot.setColumnFields([GridSheetGroupDescriptor.date(dateKey, GridSheetGroupDatePart.quarter)]);
pivot.setConfiguration(pivot.configuration!.copyWith(showRowAverage: true));
```

### Reading

| Member | Description |
| --- | --- |
| `List<GridSheetPivotColumn> columns` | The value columns, left to right (after the row labels). |
| `List<GridSheetPivotLine> lines` | The lines shown, top to bottom, following expansion and sorting. |
| `bool isTruncated` | Whether column buckets were cut at `maxColumns`. |
| `Object? value(ValueKey<String> lineKey, ValueKey<String> columnKey)` | The value at a line and column, as computed (not formatted); `null` when empty. |
| `List<GridSheetRow> rowsAt(ValueKey<String> lineKey, ValueKey<String> columnKey)` | The source rows behind a value, in the grid's row order. With `rowLabelsKey`: all of the line's rows. Empty for the Average line, for unknown cells and **always for a server pivot**. |
| `GridSheetPivotGroupKeys groupKeysAt(ValueKey<String> lineKey, ValueKey<String> columnKey)` — a `({rowGroupKeys, columnGroupKeys})` record | The group keys behind a value, outermost first. For a server pivot, these are the keys the server returned; on the client, each group's value (its bucket's sort value, e.g. `'2024-Q1'` for a quarter). Empty for summary lines and columns. |

```dart
final eu = gridManager.pivot.lines.firstWhere((l) => l.label == 'EU');
final y2024 = gridManager.pivot.columns.firstWhere((c) => c.path.join() == '2024');
gridManager.pivot.value(eu.key, y2024.key);   // 150
gridManager.pivot.rowsAt(eu.key, y2024.key);  // the 2 EU rows of 2024
```

### Sorting

`sort`, `sortBy`, `clearSort`. See [Sorting](#sorting).

### Expansion

| Member | Description |
| --- | --- |
| `bool isExpanded(ValueKey<String> lineKey)` | Whether a row group shows its inner groups. |
| `void expand(List<ValueKey<String>> lineKeys)` / `collapse(...)` | Expands or collapses those groups. |
| `void expandAll()` / `collapseAll()` | Expands or collapses every group with inner groups. |

### Selection and copy

`pivot.selection` is a `GridSheetSelectionAPI`, the same API as
`gridManager.selection`, but in pivot keys. A row key is a line's
`GridSheetPivotLine.key`, and a column key is a pivot column's
`GridSheetPivotColumn.key` (or `rowLabelsKey`). Its rows are the pivot's
lines: the label, then the values as shown. Its range methods
(`selectCellRange` and the others) run over the lines and columns as shown,
following expansion and sorting.

```dart
final eu = const ValueKey<String>('/region=EU');
final q1 = gridManager.pivot.columns.first.key;
gridManager.pivot.selection.selectCells([GridSheetCell(eu, q1)]);
gridManager.pivot.selection.cellKeys; // [GridSheetCell(eu, q1)]
```

- Cell selection follows `GridSheet.configuration`
  (`enableCellSelection`, `enableMultiSelection`). Column selection is off.
- It's separate from the table's selection, and it's empty while the pivot
  isn't showing. Switching to another view mode clears it.

| Member | Description |
| --- | --- |
| `GridSheetSelectionAPI selection` | The pivot's selection, as above. |
| `String selectedText({String delimiter = '\t', bool includeHeaders = false})` | The selected cells as text, like `cells.selectedText`. It has one line per line with a selected cell and one field per column with one, **both in display order**. Unselected cells in that block are empty. Values are as computed (`1234.5`); labels as shown. With `includeHeaders`, the first line holds the headers, as in `toCsv`. It only returns the text; it doesn't touch the clipboard. |
| `Future<String> copy({String delimiter = '\t', bool includeHeaders = false})` | Copies the selected cells to the system clipboard, formatted as `selectedText`, and returns the text. With nothing selected, it returns `''` and leaves the clipboard as it was. |

### Formatting

`pivot.formatting` is a `GridSheetFormattingAPI`, the same API as
`gridManager.formatting` (`rules`, `add`, `setRules`, `clear`, `styles`).
Its rules are `GridSheetPivotConfiguration.conditionalFormatRules`, so they
last across recomputes, view switches and snapshots. Changing them through
the API replaces the configuration's.

**What a rule covers:**

| Rule | Covers |
| --- | --- |
| `scope: GridSheetFormatScope.cell`, `name: 'sum:amount'` (a value id) | Every column showing that value: buckets, subtotals, totals and averages. |
| `scope: GridSheetFormatScope.cell`, `name: 'pivot:label'` | The row labels. |
| `scope: GridSheetFormatScope.row` (any name) | Whole lines. |

A cell rule names a **value id** rather than a column because pivot columns
are generated from the data. One value id covers all the columns showing
that value, today's and those that appear later.

**Variables** an expression reads, besides the usual ones:

| Variable | Value |
| --- | --- |
| `_cell_value` | The value **as computed**: a number, not the formatted text. |
| `_column_kind` | `bucket`, `subtotal`, `grandTotal` or `average`; `null` for the row labels. Per cell. |
| `_line_kind` | `group`, `grandTotal` or `average`. |
| `_level` | A row group's nesting depth; 0 for the outermost groups and summary lines. |

```dart
await gridManager.pivot.formatting.setRules([
  // Totals in bold: the Grand Total line and column.
  const GridSheetConditionalFormatRule(
    name: 'totals',
    expression: '_line_kind == "grandTotal" || _column_kind == "grandTotal"',
    textStyle: TextStyle(fontWeight: FontWeight.bold),
  ),
  // Large quarters in green.
  const GridSheetConditionalFormatRule(
    name: 'sum:amount',
    scope: GridSheetFormatScope.cell,
    expression: '_column_kind == "bucket" && _cell_value >= 5000 ? "#C8E6C9" : null',
  ),
]);
```

- Rules cover the row labels and the summary lines too, whatever the
  `conditionalFormatIncludesPinned…` settings. Pinning is the pivot's layout
  there, not the user's choice.
- `styles()` returns the pivot's styles keyed `<line key>|<pivot column key>`,
  summary lines included.
- Like the table's, `setRules` returns whether the rules changed, and always
  re-applies them.
- The table's own rules (`gridManager.formatting`) are separate and don't
  apply to the pivot.

### Columns

Pivot columns follow the **configured columns**:

| Pivot column | Default width | Resizable when |
| --- | --- | --- |
| A value column (bucket, subtotal, total, average) | Its value's source column's `width` | Its source column is `resizable` |
| The row labels | The widest row field's column | Any row field's column is `resizable` |

The user can drag a resizable column's edge, and widths can be set through
the API. Both are kept by pivot column key, so they last across recomputes,
view switches and snapshots, and they apply to a column that appears later.

| Member | Description |
| --- | --- |
| `Map<ValueKey<String>, double> columnWidths` | Widths set by the user or `setColumnWidths`. Columns not listed have their configured width. |
| `void setColumnWidths(Map<ValueKey<String>, double> widths)` | Sets widths, like `columns.setWidths`. A column that isn't resizable is skipped. |
| `void resetColumnWidths(List<ValueKey<String>> keys)` | Back to the configured widths. |
| `List<ValueKey<String>> hiddenColumns` | The hidden pivot columns. |
| `void hideColumns(List<ValueKey<String>> keys)` / `showColumns(...)` | Hides or shows pivot columns, kept by key. The row labels can't be hidden. Hidden columns are left out of `toMaps`, `toCsv`, `selectedText` and `copy`. |

Pivot columns can't be reordered. Their order comes from the data: buckets
in their fields' sort order, a band's Total last, then Average and Grand
Total.

### Export

| Member | Description |
| --- | --- |
| `List<Map<String, Object?>> toMaps({bool selectedOnly = false})` | One map per line shown: `'Row Labels'` → label, then each shown column's header → value. A header is the column's bands and title joined with ` / `, e.g. `2024 / Total`. Values are as computed. An outer line without subtotals has `null` values. With `selectedOnly`, only the lines and columns with a selected cell. |
| `String toCsv({bool selectedOnly = false})` | The same as CSV with a header row. Text is guarded against spreadsheet formula injection, as in `data.toCsv`. |

`gridManager.data.toCsv()` still exports the **source rows**.

### Type reference

#### GridSheetPivotColumn

| Member | Description |
| --- | --- |
| `static const rowLabelsKey` | Key of the row-labels column (`ValueKey('pivot:label')`). |
| `ValueKey<String> key` | Unique among the pivot's columns. It stays the same while its bucket and value exist, so sorting by it survives a refresh. |
| `GridSheetPivotColumnKind kind` | `bucket`, `subtotal`, `grandTotal`, `average`. |
| `List<String> path` | Header labels, outermost first (`['2025', 'Q3']`), or the summary's label. |
| `GridSheetAggregateSpec value` | The value shown. |
| `String bucketId` | The column bucket's group id (`''` for totals and averages). |

#### GridSheetPivotLine

| Member | Description |
| --- | --- |
| `ValueKey<String> key` | A row group's path key (e.g. `ValueKey('/region=EU')`), or `GridSheetPivotLine.grandTotalKey` / `averageKey`. Use it with `value`, `rowsAt`, `groupKeysAt` and expansion. |
| `GridSheetPivotLineKind kind` | `group`, `grandTotal`, `average`. |
| `String label` | The group's label, or the summary's. |
| `int level` | Nesting depth; 0 for outermost groups and summary lines. |
| `bool hasChildren` | Whether the group has inner groups. |
| `bool isExpanded` | Whether those are shown. |

#### Line keys

A row group's line key is its path:
`/<column key>=<bucket id>/<column key>=<bucket id>…`, URL-encoded. An
example is `ValueKey('/region=EU/product=A')`. Keys are the same for client
and server pivots, and they stay the same across edits, filters, sorting and
reloads. The summary lines use `GridSheetPivotLine.grandTotalKey` and
`averageKey`.

#### Public types at a glance

| Type | Kind |
| --- | --- |
| `GridSheetPivotConfiguration` | Configuration |
| `GridSheetGroupDescriptor`, `GridSheetGroupSort`, `GridSheetGroupSortEntry` | Fields (shared with row grouping) |
| `GridSheetGroupBucket`, `GridSheetGroupBucketer`, `GridSheetGroupValueBucketer`, `GridSheetGroupRangeBucketer`, `GridSheetGroupDateBucketer`, `GridSheetGroupCustomBucketer`, `GridSheetGroupDatePart` | Bucketing (shared) |
| `GridSheetAggregateSpec`, `GridSheetAggregators`, `GridSheetAggregator` | Values (shared) |
| `GridSheetViewMode` | View selection |
| `GridSheetPivotAPI` | `gridManager.pivot` |
| `GridSheetPivotColumn`, `GridSheetPivotColumnKind`, `GridSheetPivotLine`, `GridSheetPivotLineKind` | Layout read from the API |
| `GridSheetPivotCellTappedEvent` | Drill-down event |
| `GridSheetPivotRequest`, `GridSheetPivotData`, `GridSheetPivotCellData`, `GridSheetPivotGroupingSet` | Server pivot |
| `GridSheetPivotGroupKeys` | Group keys of a value (`groupKeysAt`) |
| `GridSheetPivotSnapshot` | Pivot state in a `GridSheetSnapshot` |
| `GridSheetErrorSource.pivot` | Error source |

---

## Events

### GridSheet.onPivotCellTapped

```dart
final void Function(GridSheetPivotCellTappedEvent event)? onPivotCellTapped;
```

### GridSheetPivotCellTappedEvent

| Field | Description |
| --- | --- |
| `gridManager` | The grid. |
| `GridSheetPivotLine line` | The line tapped: a row group, or the Grand Total or Average line. |
| `GridSheetPivotColumn? column` | The column tapped; `null` for the row-labels column. |
| `Object? value` | The value as computed; `null` for a row label or an empty cell. |
| `List<GridSheetRow> rows` | The source rows behind the cell (all of the line's rows for a label). **Empty for a server pivot.** |
| `List<Object?> rowGroupKeys` | The line's group keys (group values, not row keys), outermost first, as in `groupKeysAt`. |
| `List<Object?> columnGroupKeys` | The column's group keys; empty for labels, totals and averages. |

```dart
onPivotCellTapped: (event) => showOrdersDialog(event.rows),
```

### GridSheet.onError

A pivot problem is reported with `source: GridSheetErrorSource.pivot`:

- why the pivot can't show (once, until the view mode or configuration
  changes);
- a column field cut at `maxColumns`;
- a failed `onPivotRequest`.

---

## Customization

### Building a field chooser

The package has no built-in field chooser, so you can design your own and
connect it to the API. A chooser only needs to produce a
`GridSheetPivotConfiguration` and pass it to `gridManager.pivot`:

```dart
PivotFieldChooser(
  fields: columns,
  configuration: gridKey.currentState?.pivot.configuration ?? initial,
  onChanged: (c) => setState(() => gridKey.currentState!.pivot.setConfiguration(c)),
)
```

A chooser modeled on Excel's PivotTable Fields pane works well:

- Let fields be dragged into Rows, Columns and Values, and give each field
  and entry a menu too, so dragging is never required.
- Let each value pick its aggregator (Sum, Count, Average, Min, Max), and
  each date field its part (Year, Quarter, Month, Day).
- Keep a field on one axis at a time.
- Decide dragging by pointer kind, not platform, which matters on the web:
  a mouse or stylus drags at once, and a finger long-presses so the panel
  still scrolls.

Pass the configuration to `GridSheet.pivotConfiguration` **once** (e.g. a
`final` field), and make every later change through `gridManager.pivot`. A
new configuration passed by the parent replaces changes made through the API.

### Text and localization

| Constant (`GridSheetConstants`) | Default | Where |
| --- | --- | --- |
| `pivotGrandTotalText` | `Grand Total` | Grand Total column and line. |
| `pivotTotalText` | `Total` | Subtotal columns inside a band. |
| `pivotAverageText` | `Average` | Average column and line. |
| `pivotRowLabelsText` | `Row Labels` | Row-labels header without field titles; the label key in `toMaps`/`toCsv`. |
| `GridSheetConfiguration.blanksText` | `(Blanks)` | The blank group and empty cells. |

---

## Limitations

- **Read-only.** Cells can't be edited in the pivot; edit the table, and
  the pivot follows.
- **No built-in field chooser.** Build one on `gridManager.pivot`; see
  [Building a field chooser](#building-a-field-chooser).
- **Pivot columns can't be reordered**; their order comes from the data.
- **At most `maxColumns` bucket columns** are shown (500 by default).
- **Table grouping and the pagination bar are off** while the pivot shows.
- **Server pivots**: `rowsAt` and the tap event's `rows` are empty, and
  `GridSheetGroupSort.count` keeps the server's order.
- **The pivot's selection isn't saved** in snapshots.

---

## See also

- [Row grouping](row-grouping.md): the same fields and values, in the table
- [Selection](selection.md#pivot-selection)
- [Conditional formatting](conditional-format.md)
- [Snapshot](snapshot.md) · [Data export](export-stats.md)
