# Fixed rows

Rows can be **pinned** to a band above or below the scrolling rows, so they
stay in view however far the user scrolls: a header row of key figures, or
a totals row at the bottom. Pin them when the grid is built or at runtime,
insert rows straight into a band, and style each band's divider.

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
GridSheetRow(
  key: const ValueKey('totals'),
  index: rows.length,
  data: ['TOTALS', '', '', '', totalRevenue],
  pinnedBottom: true,
),
```

Or at runtime:

```dart
await gridManager.rows.pinTo(2, 0);              // the first two rows, top
await gridManager.rows.pin(topKeys: [rowKey]);   // specific rows
await gridManager.rows.unpinAll();
```

---

## Configuration

On `GridSheetRow`:

| Property | Default | Meaning |
| --- | --- | --- |
| `pinnedTop` | `false` | Pins the row to the top band. |
| `pinnedBottom` | `false` | Pins the row to the bottom band. Wins when both are set. |

On `GridSheetConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enableReorderOnPinnedTopRows` / `…BottomRows` | `false` | Lets pinned rows be dragged within their band. |
| `selectionIncludesPinnedTopCells` / `…BottomCells` | `false` | Extends a selected column's highlight into the band. See [Selection](selection.md). |

On `GridSheetAutoFillConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enableOnPinnedTopRows` / `…BottomRows` | `false` | Lets the fill handle work within the band. See [Autofill](autofill.md). |

On `GridSheetStyleConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `pinnedTopDividerColor` | `null` | Draws a divider between the top band and the scrolling rows. `null` draws none. |
| `pinnedBottomDividerColor` | `null` | The same for the bottom band. Independent of the top one. |
| `pinnedRowsDividerWidth` | `1` | Both dividers' thickness. Only visible on a side whose color is set. |
| `topPinnedRowColor` / `bottomPinnedRowColor` | `null` | A background for each band's rows. |

---

## Behavior

### What pinned rows are exempt from

A pinned row stays where it is in its band. It's left out of:

- **sorting, filtering and search**: it's always shown, whatever the sort
  or filter;
- **pagination**: it shows on every page and doesn't take a page slot;
- **keyboard navigation**: arrow keys and Tab skip it;
- **the formula engine**: a formula in a pinned row isn't evaluated, and
  formulas can't refer to it. Store computed values instead.

Select All, the select-all checkbox and Ctrl+A do include pinned rows.

In the [form layout](form-layout.md), pinned rows show as cards in fixed
bands above and below the scrolling cards.

### Pinning and unpinning

| Call | Effect |
| --- | --- |
| `pin(topKeys:, bottomKeys:)` | Pins the listed rows; leaves the others as they are. A row in both lists goes to the bottom. |
| `pinTo(topCount, bottomCount)` | Pins the first `topCount` rows of the scrollable section, as currently sorted and filtered, to the top, and the last `bottomCount` to the bottom. |
| `unpin(keys)` | Returns the listed rows to the scrollable section. |
| `unpinAll()` | Unpins every row, including rows pinned when the grid was built. |

`pin` and `pinTo` return `null` on success, or an error message: an
unknown key, or counts that are negative or add up to more rows than are
unpinned.

```dart
final error = await gridManager.rows.pin(topKeys: gridManager.selection.rowKeys);
if (error != null) showSnackBar(error);
```

### Inserting into a band

`rows.insertAt` with `band: GridSheetRowBand.top` or `.bottom` puts new
rows straight into a band, before a row of that band (or at its end with
`key: null`). The rows' own `pinnedTop` / `pinnedBottom` are set to match:

```dart
await gridManager.rows.insertAt(
  totalsKey,                      // before the totals row
  [newRow],
  band: GridSheetRowBand.bottom,
);
```

### Hiding a pinned row

`rows.hide` and `rows.show` work on pinned rows by key. A hidden pinned row
stays pinned (it's still in `rows.pinnedBottom`), it just isn't drawn.

### Reordering within a band

With `enableReorderOnPinnedTopRows` or `…BottomRows`, a pinned row can be
dragged onto another row **in the same band**. A drop into another band or
the scrolling rows is rejected.

### Pasting into a band

`cells.pasteText` and `cells.clearRange` stay out of the bands unless asked
in with `includePinnedBands: {GridSheetPinnedRowBand.top}` (or `.bottom`).
See [Cell operations](cell-operations.md).

---

## Runtime API

`gridManager.rows`:

| Member | Description |
| --- | --- |
| `pinnedTop` / `pinnedBottom` | The pinned rows of each band, in display order. |
| `pin({topKeys, bottomKeys})` | Pins rows by key; returns an error or `null`. |
| `pinTo(topCount, bottomCount)` | Pins by count; returns an error or `null`. |
| `unpin(keys)` / `unpinAll()` | Unpins. |
| `insertAt(key, rows, {band, position, defaultValues})` | Inserts into a band with `band: .top` / `.bottom`. |
| `hide(keys)` / `show(keys)` | Hides or shows rows, pinned or not. |

```dart
final topNames = gridManager.rows.pinnedTop.map((r) => r.data.first);
```

---

## Events

No events of their own. Selecting a pinned row fires `onRowsSelected`, and
dragging one within its band fires `onRowReorder`, where `fromIndex` and
`toIndex` count within the band. See [Row operations](row-operations.md).

---

## Customization

```dart
styleConfiguration: GridSheetStyleConfiguration(
  pinnedTopDividerColor: Colors.indigo,
  pinnedBottomDividerColor: Colors.pink,
  pinnedRowsDividerWidth: 2,
  bottomPinnedRowColor: Colors.grey.shade100,
),
```

A divider takes up its own height rather than covering cells.

---

## Limitations

- **No formulas in pinned rows.** A totals row needs precomputed values,
  updated by your code when the data changes.
- **No keyboard navigation into pinned rows.**
- **Bands need room.** Many pinned rows leave little height for the
  scrolling rows.

---

## See also

- [Fixed columns](fixed-columns.md): pinning columns
- [Row operations](row-operations.md)
- [Selection](selection.md) · [Autofill](autofill.md) · [Row expansion](row-expansion.md)
- [Cell operations](cell-operations.md): pasting into bands
