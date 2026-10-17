# Column animation

`GridSheet` has four opt-in animations: columns **revealing** one after
another when the grid appears, rows **revealing** after a sort or filter, a
cell **flashing** when its value changes, and columns **fading** in and out
when they're shown or hidden. All four are off by default and set through
one `GridSheetAnimationConfiguration`.

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
  animationConfiguration: const GridSheetAnimationConfiguration(
    enabled: true,                     // column reveal on mount and page change
    animateRowsOnSortOrFilter: true,   // row reveal after sort / filter
    cellChangeFlashEnabled: true,      // flash a cell when its value changes
    columnVisibilityFadeEnabled: true, // fade columns in and out
  ),
)
```

---

## Configuration

`GridSheet.animationConfiguration` takes a `GridSheetAnimationConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enabled` | `false` | Turns on the **column reveal**: columns slide and fade in one after another when the grid first appears. Turned on later, the reveal plays once right away. |
| `replayOnPageChange` | `true` | Replays the column reveal on every page change. Needs `enabled`. |
| `animateRowsOnSortOrFilter` | `false` | Turns on the **row reveal**: rows slide and fade in top to bottom after a sort or filter. It can be turned on or off at any time. |
| `cellChangeFlashEnabled` | `false` | Turns on the **cell flash**: a cell briefly highlights when its value changes. |
| `cellChangeFlashColor` | `Colors.amber` | The flash color. |
| `cellChangeFlashDuration` | `800 ms` | How long the flash takes to fade out. |
| `columnVisibilityFadeEnabled` | `false` | Turns on the **column fade**: a column shrinks and fades out when hidden, and grows and fades in when shown. |
| `animationDuration` | `700 ms` | The duration of the column reveal (the whole cascade, not each column), the row reveal and the column fade. |
| `curve` | `Curves.easeOutCubic` | The curve of each column's or row's slide and fade. |
| `slideDistance` | `24` | How far, in logical pixels, a column or row slides in from. |
| `revealTransitionBuilder` | `null` | Replaces the built-in slide-and-fade of the reveals. See [Customization](#customization). |
| `cellFlashBuilder` | `null` | Replaces the built-in color flash. See [Customization](#customization). |

The four features are independent: turn on any combination.

---

## Behavior

### Column reveal (`enabled`)

- Plays **once** when the grid mounts. Pinned-left columns reveal first,
  then the scrollable columns, left to right. Each column's header, filter
  field and cells move together.
- Replays on every page change while `replayOnPageChange` is on: client
  pages, server pages and a rows-per-page change.
- Doesn't replay on `reload()`, sorting or auto-reload.

### Row reveal (`animateRowsOnSortOrFilter`)

- Plays after the page is re-sorted or re-filtered: the rows cascade in
  from the top. It replays a stagger; it doesn't animate each row from its
  old position.
- With `replayOnPageChange` also on, a server page change
  (`serverSidePagination`) replays it for the whole page, and an
  infinite-scroll batch animates only the newly added rows.
- Client-side page changes never play it.

### Cell flash (`cellChangeFlashEnabled`)

- Plays whenever a cell's value changes: typing, `cells.update`, paste,
  find-and-replace, undo and redo, and a formula recalculating because a
  cell it depends on changed.
- Doesn't play when formulas are evaluated in bulk: on mount, a page
  change, a sort or filter, or `formulas.refreshAll()`.

### Column fade (`columnVisibilityFadeEnabled`)

- `columns.show(keys)`: the column grows from zero width while fading in.
- `columns.hide(keys)`: the column shrinks to zero width while fading out,
  then leaves the layout.
- Columns to its right slide along as it grows or shrinks, instead of
  jumping.

---

## Runtime API

There's no API on `gridManager` for animations. They're set through
`GridSheet.animationConfiguration`, and they play on their own when the
matching thing happens:

| Animation | Triggered by |
| --- | --- |
| Column reveal | Mounting the grid; `pagination.goTo`, `next`, `previous`, `setRowsPerPage` |
| Row reveal | `sorting.sortBy`, `sorting.clear`, `filters.add`, `filters.clear`, `search.apply`, or the same from the UI |
| Cell flash | `cells.update`, `cells.updateAll`, `cells.pasteText`, `cells.findAndReplace`, `history.undo`, typing |
| Column fade | `columns.show`, `columns.hide` |

```dart
// With cellChangeFlashEnabled on, this cell flashes:
gridManager.cells.update(rowKey: rowKey, columnKey: salaryKey, value: 98000.0);

// With columnVisibilityFadeEnabled on, this fades out:
gridManager.columns.hide([statusKey]);
```

---

## Events

None. Animations don't fire callbacks.

---

## Customization

### Your own reveal transition

`revealTransitionBuilder` replaces the slide-and-fade for both reveals. It
receives the column or row to show, the progress (`0` hidden → `1` shown,
already shaped by `curve`) and the axis (`Axis.horizontal` for columns,
`Axis.vertical` for rows):

```dart
animationConfiguration: GridSheetAnimationConfiguration(
  enabled: true,
  revealTransitionBuilder: (context, child, progress, axis) => Opacity(
    opacity: progress,
    child: Transform.scale(scale: 0.7 + 0.3 * progress, child: child),
  ),
),
```

### Your own flash

`cellFlashBuilder` paints over the changed cell. Its progress runs from `1`
(just changed) to `0` (settled) over `cellChangeFlashDuration`. Return a
`Positioned.fill`, so it covers the cell, wrapped in `IgnorePointer`, so the
cell stays tappable:

```dart
animationConfiguration: GridSheetAnimationConfiguration(
  cellChangeFlashEnabled: true,
  cellFlashBuilder: (context, progress) => Positioned.fill(
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink.withValues(alpha: progress), width: 2),
        ),
      ),
    ),
  ),
),
```

---

## Limitations

- **The reveals don't animate each row's or column's movement.** They
  replay a cascade from the start.

---

## See also

- [Column operations](column-operations.md): `columns.show` and `columns.hide`
- [Pagination](pagination.md) · [Sorting](sorting.md) · [Filters](filters.md)
- [Cell operations](cell-operations.md)
- [Formula columns](formula-columns.md)
