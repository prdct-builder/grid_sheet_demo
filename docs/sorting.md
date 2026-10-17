# Sorting

Rows sort by one column or several: double-tap a header to sort by it, and
double-tap more headers to add tie-breakers. Sorting compares values by
type (numbers as numbers, text naturally), and a column can use a
comparator of your own.

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
GridSheetColumn(key: const ValueKey('medals'), index: 3, name: 'MEDALS', title: 'Medals',
    type: const GridSheetColumnType.integer(), sortable: true),
```

```dart
await gridManager.sorting.sortBy(medalsKey, direction: GridSheetSortDirection.desc);
await gridManager.sorting.clear();
```

---

## Configuration

| Option | Default | Meaning |
| --- | --- | --- |
| `GridSheetColumn.sortable` | `false` | Lets a double-tap on the header sort by the column. |
| `GridSheet.sortIconBuilder` | `null` | Draws the sort arrow yourself. See [Customization](#customization). |
| `GridSheetStyleConfiguration.ascendingSortIconColor` / `descendingSortIconColor` | `Colors.green` / `Colors.red` | The built-in arrows' colors. |

`sortable` only governs the header gesture: `sorting.sortBy` sorts by any
column.

---

## Behavior

### Sorting from the header

**Double-tap** a sortable header (a single tap selects the column):

| The column is | A double-tap |
| --- | --- |
| Not sorted | Adds it as the next sort key, ascending. |
| Ascending | Makes it descending. |
| Descending | Removes it from the sort. |

So double-tapping a second header sorts by it **within** the first: the
first sorted column is the primary key, the next one breaks ties, and so on.
Each sorted header shows an arrow.

### Sort order

| Values | Order (ascending) |
| --- | --- |
| Numbers | By value. Text holding a number (`'10'`) sorts as that number. |
| Dates | Chronological. |
| Booleans | `false` before `true`. |
| Text | Case-insensitive and natural: `item 9` before `item 10`. |
| Mixed | Numbers, then dates, then booleans, then text. |
| Blank (`null`) | Last when ascending. |

Descending reverses the whole order, so blanks come first. Rows that are
equal on every sort key keep their original order.

### Sorting and the rest of the grid

- Pinned rows don't sort; they stay in their bands.
- Sorting turns off row drag-and-drop (`rows.reorder` too) until the sort
  is cleared.
- Editing a value doesn't move its row, and inserted rows go where they're
  inserted. The sort is re-applied when you sort again, reload, or pass
  new `rows`.
- With `serverSidePagination`, a sort change asks your `onPageChange` for
  sorted data instead; `GridSheetPageRequest.sortKeys` carries the sort
  (by column name). See [Pagination](pagination.md).
- With `animateRowsOnSortOrFilter`, rows cascade in after a sort. See
  [Column animation](column-animation.md).

---

## Runtime API

`gridManager.sorting` (`GridSheetSortingAPI`):

| Member | Description |
| --- | --- |
| `keys` | The active sort, in priority order, as `GridSheetSortState` (`key`, `name`, `direction`). |
| `sortBy(key, {direction})` | Without `direction`, toggles the column as a header double-tap does. With it, sets that direction (adding the column if it isn't sorted). |
| `clear()` | Removes every sort key and restores the original order. |
| `setComparator(key, comparator)` | Sets a column's comparator, or restores the default with `null`. |

```dart
// Country A→Z, then medals high→low within each country.
await gridManager.sorting.clear();
await gridManager.sorting.sortBy(countryKey);
await gridManager.sorting.sortBy(medalsKey, direction: GridSheetSortDirection.desc);

gridManager.sorting.keys.map((k) => '${k.name} ${k.direction.name}');
// ['COUNTRY asc', 'MEDALS desc']
```

### Custom comparators

A comparator gets the two values, their rows and the column, and returns
negative, zero or positive like `compareTo`. Descending order applies on top
of it.

```dart
const rank = {'Gymnastics': 0, 'Swimming': 1, 'Athletics': 2};

gridManager.sorting.setComparator(sportKey, (a, b, {required rowA, required rowB, required column}) {
  return (rank[a] ?? rank.length).compareTo(rank[b] ?? rank.length);
});
```

---

## Events

None of their own. With server-side pagination, sorting calls
`GridSheet.onPageChange`; a failure there is reported to `onError` with
`GridSheetErrorSource.serverSideSort`.

---

## Customization

### Your own sort icon

`GridSheet.sortIconBuilder` is called for each sorted header with the
column, the direction and its priority (`1` for the primary key). Return a
widget, or `null` for the built-in arrow:

```dart
sortIconBuilder: (column, direction, priority) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(direction == GridSheetSortDirection.asc ? Icons.arrow_upward : Icons.arrow_downward,
        size: 15),
    Text(' $priority', style: const TextStyle(fontSize: 10)),
  ],
),
```

A custom header cell (`cellBuilder` with `GridSheetCellKind.header`) gets
the column's sort as `cell.columnSortState`. See
[Custom cells](custom-cells.md).

---

## Limitations

- **Sorting is by double-tap**, since a single tap selects the column.
- **Blanks come first when descending.**
- **Row-numbered formulas don't follow sorted rows.** See
  [Formula columns](formula-columns.md#limitations).

---

## See also

- [Filters](filters.md) · [Search](search.md)
- [Pagination](pagination.md): server-side sorting
- [Custom cells](custom-cells.md): custom headers
- [Row operations](row-operations.md): reordering
