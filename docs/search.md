# Search

Search looks for terms across **every column** at once, where filters look
at one column each. A row stays when each term is found in some cell of
it. Terms can combine alternatives (`Mechanic||Electrician`), require
several things (`23&&Mechanic`), or match a range (`20..30`).

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
await gridManager.search.apply(['Mechanic']);          // rows with "Mechanic" anywhere
await gridManager.search.apply(['Mechanic', 'John']);  // and "John" somewhere too
await gridManager.search.clear();
```

Search has no built-in input field; wire it to your own (a `TextField` that calls `gridManager.search.apply`).

---

## Configuration

Search has no configuration options; everything is passed to
`search.apply`:

| Argument | Default | Meaning |
| --- | --- | --- |
| `values` | required | The search terms. An empty list clears the search. |
| `exactMatch` | `false` | Matches case-sensitively. |
| `smartSyntax` | `true` | Also reads filter operators in terms (`>100`, `app%`). `false` matches terms literally. |

---

## Behavior

### How terms combine

| Write | Means |
| --- | --- |
| Several terms (`['Mechanic', 'John']`) | **Every** term must match, each in any cell. |
| `||` inside a term (`'Mechanic||Electrician'`) | Either alternative. |
| `&&` inside a term (`'23&&Mechanic'`) | Both, each in any cell of the row. |
| `low..high` (`'20..30'`) | Any cell between the two numbers (or dates). |

`&&` binds tighter than `||`: `'Active&&John||Pending&&Sarah'` is (Active
and John) or (Pending and Sarah).

A term matches a cell when the cell's text **contains** it, ignoring case
(unless `exactMatch`). A number term (`23`) matches cells containing `23`.

### Smart syntax

With `smartSyntax` (the default), a term can use the
[filter operators](filters.md#operators): `>100` matches any cell holding a
number over 100, `app%` any cell starting with "app". Set
`smartSyntax: false` to search for text such as `%` or `>` literally.

### Search and the rest of the grid

- Search **and** column filters both apply: a row must pass both.
- Every column is searched, hidden ones included.
- Pinned rows are never hidden by a search.
- Searching clears the selection and goes back to page 1.
- With `serverSidePagination` or `infiniteScroll`, the terms go to your
  `onPageChange` (`GridSheetPageRequest.searchItems`, `searchExactMatch`,
  `searchSmartSyntax`) instead of being matched in the grid.
- With `animateRowsOnSortOrFilter`, rows cascade in after a search.

---

## Runtime API

`gridManager.search` (`GridSheetSearchAPI`):

| Member | Description |
| --- | --- |
| `apply(values, {exactMatch, smartSyntax})` | Replaces the search with these terms. |
| `clear()` | Removes the search. Column filters stay. |
| `terms` | The active terms. |
| `exactMatch` / `smartSyntax` | The options of the active search. |

```dart
// A search box with chips: keep the terms yourself, and re-apply them.
final terms = <dynamic>[];

Future<void> addTerm(String text) async {
  terms.add(text.trim());
  await gridManager.search.apply(terms);
  status = '${gridManager.rows.filteredCount} of ${gridManager.rows.count} rows match';
}
```

`search.apply` has no debounce: debounce it yourself when searching as the
user types on a large grid.

---

## Events

None of their own. With server-side data, a failed search request is
reported to `onError` (`GridSheetErrorSource.serverSideFilter`).

---

## Customization

Build the search UI you want (a text field, chips, saved searches) and call
`search.apply`. To show matches, a conditional format rule or a
`cellBuilder` can highlight cells containing the terms.

---

## Limitations

- **No highlighting of matches.** Matching rows are shown, but the matching
  text isn't marked.
- **Hidden columns are searched too**, which can keep rows whose visible
  cells don't show the term.
- **No parentheses** in `&&` / `||` combinations.

---

## See also

- [Filters](filters.md): filtering one column at a time, and the operators
- [Pagination](pagination.md): server-side search
- [Conditional formatting](conditional-format.md)
