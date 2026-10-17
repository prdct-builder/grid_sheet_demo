# Data export & statistics

`gridManager.data` gives you the grid's data in other shapes: **CSV**,
**maps** (for JSON or an API), **lists**, **grouped data** for your own
spreadsheet or PDF writer, and **per-column statistics** such as sum,
average and median. Exports follow what the user sees, filters and hidden
columns included, unless you ask for everything.

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
final csv = gridManager.data.toCsv();                         // visible columns, filtered rows
final json = jsonEncode(gridManager.data.toMaps(gridManager.rows.all));
final stats = gridManager.data.statistics(salaryKey);          // {'Sum': '475500.000', ...}
```

---

## Configuration

Nothing to configure on the grid. Each method takes its own options; see
[Runtime API](#runtime-api). The pagination bar's statistics are set up in
[Pagination](pagination.md#configuration) (`showColumnStatistics`, and
`PaginationConfiguration.hideAggregateStats`).

---

## Behavior

### Which rows and columns

Methods take a column scope and a row scope:

| `GridSheetColumnScope` | Columns |
| --- | --- |
| `visible` | The columns on screen, in display order; hidden and collapsed-group columns are left out. |
| `all` | Every data column, hidden or not. |

| `GridSheetRowScope` | Rows |
| --- | --- |
| `filtered` | Rows passing filters and search, across all pages. No pinned rows. |
| `currentPage` | The filtered rows on the current page. No pinned rows. |
| `all` | Every row, pinned included, ignoring filters and pages. |

With `filtered` or `currentPage`, `includePinnedBands: {GridSheetPinnedRowBand.top, .bottom}`
adds the pinned rows back, before and after the others.

### Values

- **As stored.** Values come out exactly as held in the grid, not parsed by
  column type: what the grid shows is what you get. Use
  `row.toParsedDataMap(columns)` for typed values.
- **Formulas are up to date.** Formula cells are recomputed before export,
  and export their result; `toCsv(includeFormulas: true)` exports the
  formula text (`=C1*0.1`) instead.
- The index column is never exported.

### CSV

- Comma-separated, `\n` line ends, headers (column titles) first.
- Values with commas, quotes or line breaks are quoted; quotes are doubled.
- **Formula injection guard.** A text value starting with `=`, `+`, `-`,
  `@`, tab or carriage return gets a leading `'`, so spreadsheet apps open
  it as text. Plain numbers such as `-5` and formulas exported with
  `includeFormulas` are left alone.

### Statistics

`statistics(columnKey)` works over the **filtered** rows of one column and
returns a map keyed by label:

| Key | Value | When |
| --- | --- | --- |
| `Count` | Non-blank values | Always |
| `Unique Count` | Distinct non-blank values | Always |
| `Blanks` / `Non-Blanks` | Empty or `null` values / the rest | Always |
| `Sum`, `Average`, `Median` | Strings with 3 decimals (`'475500.000'`) | At least one numeric value |
| `Min`, `Max` | Numbers | At least one numeric value |

Numeric text such as `'42'` counts as a number. Pass `hideAggregateStats`
to leave keys out.

---

## Runtime API

`gridManager.data` (`GridSheetDataAPI`):

| Method | Returns |
| --- | --- |
| `toCsv({includeHeaders = true, includeFormulas = false, columnScope = visible, rowScope = filtered, includePinnedBands})` | A CSV string. |
| `toMaps(rows)` | One map per row, keyed by column **name**. |
| `toMap(rowKey)` | One row as a map; `{}` if there's no such row. |
| `toLists({columnScope = visible, rowScope = filtered, includePinnedBands})` | Rows as value lists in column order. |
| `toGrouped({columnScope = visible})` | `GridSheetGroupedData`: the rows with their group headers, subtotals, grand total and column bands. |
| `statistics(columnKey, {hideAggregateStats})` | The column's statistics. |
| `groupBy(columnKey)` | All rows grouped by the column's distinct values. |

Row counts, on `gridManager.rows`:

| Member | Counts |
| --- | --- |
| `count` | Every row. |
| `filteredCount` | Rows passing filters and search. |
| `currentPageCount` | Rows on the current page. |

### Examples

```dart
// Save a CSV file of everything, hidden columns included.
final csv = gridManager.data.toCsv(
  columnScope: GridSheetColumnScope.all,
  rowScope: GridSheetRowScope.all,
);
await File('export.csv').writeAsString(csv);

// Send only what's on screen to an API.
final payload = gridManager.data.toMaps(gridManager.rows.currentPage);

// Statistics without the counts.
final stats = gridManager.data.statistics(salaryKey, hideAggregateStats: const [
  GridSheetAggregation.count,
  GridSheetAggregation.uniqueCount,
]);

// Rows per department.
final byDepartment = gridManager.data.groupBy(departmentKey);
byDepartment.forEach((dept, rows) => debugPrint('$dept: ${rows.length}'));
```

### Grouped export

With [row grouping](row-grouping.md) on, `toGrouped().lines` lists every
group (expanded or not) in display order, each line with a `kind`
(`groupHeader`, `row`, `groupSummary`, `grandTotal`), its `level`, `values`
and `aggregates`. With [column grouping](column-grouping.md),
`columnBands` lists the bands per level.

```dart
for (final line in gridManager.data.toGrouped().lines) {
  switch (line.kind) {
    case GridSheetGroupedLineKind.groupHeader:
      sheet.addRow(['${line.group!.label} (${line.group!.count})']);
    case GridSheetGroupedLineKind.row:
      sheet.addRow(line.values);
    default:
      break;
  }
}
```

`toGrouped` doesn't escape anything: guard text starting with `=`, `+`, `-`
or `@` yourself when writing a spreadsheet.

---

## Events

None.

---

## Customization

For a different format, start from `toLists` or `toMaps` and write it
yourself, for example tab-separated:

```dart
final tsv = gridManager.data
    .toLists()
    .map((values) => values.map((v) => v ?? '').join('\t'))
    .join('\n');
```

The pivot table has its own CSV export; see [Pivot](pivot.md).

---

## Limitations

- **No file or Excel writing.** Exports return strings and objects; saving,
  sharing or `.xlsx` writing is up to your app.
- **Formatting isn't exported**: no colors or conditional formats, and
  values are raw, not as a custom cell displays them.
- **Statistics cover one column** of the filtered rows; for several
  columns, call it per column.

---

## See also

- [Pagination](pagination.md): statistics in the pagination bar
- [Selection](selection.md): copying a selection as text
- [Formula columns](formula-columns.md)
- [Row grouping](row-grouping.md) · [Pivot](pivot.md)
