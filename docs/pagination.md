# Pagination

`GridSheet` pages its rows three ways: **client-side** (all rows loaded,
shown a page at a time), **server-side** (each page fetched on demand
through `onPageChange`), and **infinite scroll** (more rows loaded as the
user nears the bottom). The pagination bar is built in, and can be
replaced by your own.

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

Client-side pagination is on by default, 30 rows per page:

```dart
GridSheet(
  columns: columns,
  rows: rows,
  configuration: const GridSheetConfiguration(rowsPerPage: 25),
)
```

Server-side:

```dart
GridSheet(
  columns: columns,
  rows: const [], // the first page is fetched on mount
  configuration: const GridSheetConfiguration(serverSidePagination: true, rowsPerPage: 25),
  onPageChange: (request) async {
    final page = await api.orders(offset: request.offset, limit: request.rowsPerPage);
    return GridSheetPageData(rows: page.rows, totalCount: page.total);
  },
)
```

---

## Configuration

On `GridSheetConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enableDefaultPagination` | `true` | Pages the rows, with the built-in bar at the bottom. |
| `enableCustomPagination` | `false` | Pages the rows without the built-in bar; you place a bar yourself (see [Customization](#customization)). |
| `rowsPerPage` | `30` | Rows per page. |
| `serverSidePagination` | `false` | Fetches each page through `onPageChange`. |
| `infiniteScroll` | `false` | Fetches more rows through `onPageChange` as the user scrolls down; no page bar. |
| `infiniteScrollThreshold` | `200` | How close, in pixels, to the bottom the next fetch starts. |
| `selectOnlyCurrentPageRows` | `true` | The Select All checkbox covers the current page only. See [Selection](selection.md). |
| `selectColumnAcrossAllPages` | `false` | A selected column covers every page. |

On `GridSheet`:

| Option | Meaning |
| --- | --- |
| `onPageChange` | `Future<GridSheetPageData> Function(GridSheetPageRequest)`. Required for server-side pagination and infinite scroll. |
| `bottomBarBuilder` | Builds the area below the grid, for example your own pagination bar. |

To show every row on one page, turn pagination off with
`enableDefaultPagination: false`.

---

## Behavior

### Client-side

All rows are in the grid; the page only decides which are shown. Sorting,
filtering and search apply to every row, and the pages follow. The bar
hides itself when there's only one page.

These go back to **page 1**: sorting, filtering, searching and changing the
rows per page.

### Server-side

The grid shows one page at a time, fetched from your `onPageChange`:

- It's called on mount when `rows` is empty, and for every page change,
  sort, filter or search (filters and search after a 400 ms pause).
- Return the page's rows and the **total** row count; the grid works out
  the number of pages from it.
- Each page replaces the previous one, so the selection is cleared.
- The rows are numbered by position (the index column counts across pages).
- A page's row keys must be unique and differ from pinned rows'.

`GridSheetPageRequest` carries everything a backend needs:

| Field | Meaning |
| --- | --- |
| `page` | The 1-based page number. |
| `rowsPerPage` | The page size. |
| `offset` | `(page - 1) * rowsPerPage`: usable as SQL `OFFSET` or a REST `skip`. |
| `sortKeys` | The sort, in priority order (`GridSheetSortState`: `key`, `name`, `direction`). |
| `filters` / `filterComparisons` | The column filters and their comparisons, **by column name**. |
| `searchItems` / `searchExactMatch` / `searchSmartSyntax` | The search. |
| `gridManager` | The grid. |

### Infinite scroll

When the user scrolls within `infiniteScrollThreshold` pixels of the
bottom, `onPageChange` is called for the next batch, and the returned rows
are **appended**. A row whose key is already loaded is skipped. Fetching
stops once the loaded rows reach `totalCount` (`pagination.hasMore` turns
`false`). Sorting, filtering and search start over from the first batch.

### Failures

If `onPageChange` throws, the grid stays on its current page (or keeps its
rows), and the error goes to `onError`: `GridSheetErrorSource.pageChange`,
`serverSideSort`, `serverSideFilter` or `infiniteScrollFetch`.

---

## Runtime API

`gridManager.pagination` (`GridSheetPaginationAPI`):

| Member | Description |
| --- | --- |
| `current` | The current page, from 1. |
| `totalPages` | The number of pages. |
| `rowsPerPage` | The page size. |
| `isEnabled` | Whether pagination is on. |
| `hasMore` / `serverTotalCount` | Server modes: whether more rows can be fetched, and the total the server reported. |
| `goTo(page)` | Goes to a page, clamped to `1..totalPages`. |
| `next()` / `previous()` | One page forward or back; nothing at the ends. |
| `setRowsPerPage(n)` | Changes the page size and goes back to page 1. Throws an `ArgumentError` below 1. |

```dart
await gridManager.pagination.goTo(3);
await gridManager.pagination.setRowsPerPage(50);
gridManager.rows.currentPage; // the rows on this page
```

In server-side mode, `next()` and `previous()` start a fetch and return at
once; `goTo` and `setRowsPerPage` complete when the page has loaded.

---

## Events

| Callback | When |
| --- | --- |
| `GridSheet.onPageChange` | The grid needs rows from your server: see [Server-side](#server-side). |
| `GridSheet.onError` | A fetch failed. |

---

## Customization

### Your own bar

Turn on `enableCustomPagination` and build a `GridSheetPagination` (or any
widget) in `bottomBarBuilder`:

```dart
configuration: const GridSheetConfiguration(enableCustomPagination: true, rowsPerPage: 8),
bottomBarBuilder: (manager) => GridSheetPagination(
  gridManager: manager,
  maxPageButtons: 3,
  showRowsPerPageSelector: false,
  paginationConfiguration: PaginationConfiguration(
    backgroundColor: Colors.grey.shade100,
    selectionColor: Colors.indigo,
  ),
),
```

| `GridSheetPagination` | Default | Meaning |
| --- | --- | --- |
| `compactMode` | `false` | A minimal, icon-only layout. |
| `maxPageButtons` | `5` | Page-number buttons shown. |
| `rowsPerPageOptions` | `[25, 50, 100, 200, 500]` | The page-size choices. |
| `showRowCount` | `true` | "Showing 1–25 of 100 rows". |
| `showSelectedCount` | `true` | "Selected: n". |
| `showColumnStatistics` | `true` | The selected column's statistics. |
| `showRowsPerPageSelector` | `true` | The page-size picker. |
| `showPageNumbers` | `true` | The page-number buttons. |
| `showGoToPage` | `true` | A field to type a page number. |
| `height` | `30` | The bar's height. |
| `paginationConfiguration` | `PaginationConfiguration()` | Colors (`backgroundColor`, `selectionColor`, `selectedTextColor`, `disabledColor`, `borderColor`), `textStyle`, `padding`, `iconSize`, `showBorder`, and `hideAggregateStats` (Blanks, Non-Blanks and Median by default). |

A bar you build yourself shows the grid's state as of its last build;
rebuild it when the selection changes if it shows the selected count.

### Text

The bar's text comes from `GridSheetLocalizations` (`rowRange`,
`selectedCount`, and so on).

---

## Limitations

- **The built-in bar's options are fixed.** To change its parts, use your
  own `GridSheetPagination` with `enableCustomPagination`.
- **Infinite scroll has no page bar** and doesn't page backwards: rows stay
  loaded until a sort, filter, search or reload starts over.
- **Pinned rows are on every page**, outside the paging.

---

## See also

- [Reload](reload.md): refreshing server data
- [Sorting](sorting.md) · [Filters](filters.md) · [Search](search.md): sent to the server in server mode
- [Selection](selection.md): selection across pages
- [Layout widgets](layout-widgets.md): the bars above and below the grid
