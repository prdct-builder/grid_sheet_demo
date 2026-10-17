# Filters

Filters narrow the rows column by column: each column has its own filter,
and a row shows only if it passes every one. Users type into the filter row
under the headers, using operators like `>100`, `10..50` or `=Apple`, and
the same filters can be set from code with any comparison.

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
  configuration: const GridSheetConfiguration(showColumnFilters: true),
)
```

```dart
await gridManager.filters.add({medalsKey: ['>2']});
await gridManager.filters.add({sportKey: ['Swimming', 'Athletics']},
    comparison: GridSheetFilterComparison.exact);
await gridManager.filters.clearAll();
```

---

## Configuration

On `GridSheetConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `showColumnFilters` | `false` | Shows the filter row. |
| `filterPosition` | `below` | `GridSheetFilterPosition.below` or `.above` the header row. |
| `filterHeight` | `30` | The filter row's height. |
| `blanksText` | `'(Blanks)'` | Typed as a filter, shows only blank cells. |
| `noBlanksText` | `'(Non-Blanks)'` | Typed as a filter, shows only non-blank cells. |

On `GridSheetColumn`:

| Property | Default | Meaning |
| --- | --- | --- |
| `filterHint` | `'Search..'` | The hint in the column's filter field. |

---

## Behavior

### Typing in the filter row

Type into a column's filter field and press **Enter**. Commas separate
several values, any of which can match (`Swimming, Athletics`). Clearing the
field and pressing Enter removes the filter.

### Operators

With no comparison given (`auto`, the default for the filter row and for
`filters.add`), what you type picks the comparison:

| Type | Comparison | Matches |
| --- | --- | --- |
| `app` | contains | `Apple`, `Application` |
| `=Apple` | exact | `Apple`, not `Apple Pie` |
| `!=Apple` | not equal | everything but `Apple` |
| `!app` | does not contain | `Orange` |
| `app%` | starts with | `Apple` |
| `%apple` | ends with | `Pineapple` |
| `>100`, `>=100`, `<100`, `<=100` | greater / less than | numbers, or dates (`>2026-01-01`) |
| `10..50` | between, inclusive | `10`, `25`, `50`, or a date range |
| `!..10..50` | not between | below 10 or above 50 |

Text matching ignores case. Number columns (integer, double) compare as
numbers and date columns as dates.

### Combining values

| How | Means |
| --- | --- |
| Several values in the list (`['Swimming', 'Athletics']`) or commas in the filter row | Any of them (OR). |
| `||` inside one value (`'Swimming||Athletics'`) | OR. |
| `&&` inside one value (`'Amara&&Diallo'`) | AND: both in the same cell. |
| Filters on several columns | AND: a row must pass every column's filter. |

`&&` binds tighter than `||`: `'Urgent&&Billing||Pending&&Reviewed'` is
(Urgent and Billing) or (Pending and Reviewed).

### Blanks

Type the `blanksText` keyword (`(Blanks)` by default) to show only blank
cells, or `noBlanksText` (`(Non-Blanks)`) for the rest. Empty text, an empty
list and a list of empty items count as blank.

### Filters and the rest of the grid

- Filters combine with search: a row must pass both. See [Search](search.md).
- Pinned rows are never filtered out.
- Filtering clears the selection and goes back to page 1.
- With `serverSidePagination` or `infiniteScroll`, filters go to your
  `onPageChange` instead (after a 400 ms pause in typing), by column
  name in `GridSheetPageRequest.filters` and `filterComparisons`.
- With `animateRowsOnSortOrFilter`, rows cascade in after filtering.

---

## Runtime API

`gridManager.filters` (`GridSheetFiltersAPI`):

| Member | Description |
| --- | --- |
| `hasAny` | Whether any filter is active. |
| `active` | The active filters, by column key. |
| `add(filters, {comparison})` | Sets the filters of the given columns, replacing their previous ones. Other columns keep theirs. |
| `clear(key)` | Removes one column's filter. |
| `clearAll()` | Removes every filter. |

`comparison` defaults to `auto`, which reads operators from the values as
in the filter row. Passing any comparison, even `contains`, matches the
values literally, without reading operators:

```dart
await gridManager.filters.add({ageKey: ['>100']});                                   // auto
await gridManager.filters.add({ageKey: ['100']}, comparison: GridSheetFilterComparison.greaterThan);
await gridManager.filters.add({notesKey: ['>100']}, comparison: GridSheetFilterComparison.contains);
// the last one finds the text ">100"
```

The comparisons: `auto`, `contains`, `notContains`, `exact`, `notEquals`,
`greaterThan`, `greaterThanOrEqual`, `lessThan`, `lessThanOrEqual`,
`between`, `notBetween`, `startsWith`, `endsWith`, `like`, `notLike`
(`%` matches any text: `%apple%`).

Read the result through `gridManager.rows.filtered` and `filteredCount`.

---

## Events

None of their own. With server-side data, a failed filter request is
reported to `onError` with `GridSheetErrorSource.serverSideFilter`.

---

## Customization

A filter cell can be any widget: `GridSheet.cellBuilder` is called with
`GridSheetCellKind.filter`, gets `cell.filterController` (kept in step with
the active filter) and applies filters with `filters.add`. A dropdown of the
column's values is a common choice; see
[Custom cells](custom-cells.md#a-custom-filter).

---

## Limitations

- **No literal commas in the filter row.** A comma always separates
  values; use `filters.add` to match text containing a comma.
- **No parentheses** in `&&` / `||` combinations.
- **The filter row applies on Enter**, not as you type (on the client).

---

## See also

- [Search](search.md): searching across all columns
- [Sorting](sorting.md)
- [Pagination](pagination.md): server-side filtering
- [Custom cells](custom-cells.md#a-custom-filter)
