# Scrollbars

`GridSheetScrollBarConfiguration` sets how the grid's two scrollbars look
and where they sit: thickness, corners, colors, always-on or on-scroll,
inside the grid or out beside it. It can also turn scrolling off on either
axis or replace the scrollbar widget with your own.

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
  scrollConfiguration: const GridSheetScrollBarConfiguration(
    thickness: 10,
    radius: Radius.circular(5),
    trackVisibility: true,
  ),
)
```

---

## Configuration

`GridSheet.scrollConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `thickness` | `6` | The thumb's width (vertical) or height (horizontal). |
| `radius` | `Radius.zero` | The thumb's corners. |
| `thumbVisibility` | `true` | Always show the thumb; `false` shows it only while scrolling. |
| `trackVisibility` | `false` | Show the track behind the thumb. |
| `thumbColor` / `trackColor` | `null` (theme) | Colors; `null` follows `ScrollbarTheme`. |
| `showVerticalScrollbar` | `true` | Vertical scrolling at all. `false` stops wheel, trackpad and touch scrolling too. |
| `showHorizontalScrollbar` | `true` | Horizontal scrolling at all. |
| `verticalScrollbarPlacement` | `afterLastColumn` | Where the vertical scrollbar sits; see below. |
| `horizontalScrollbarPlacement` | `bottom` | Where the horizontal scrollbar sits; see below. |
| `scrollbarBuilder` | `null` | Replaces the scrollbar widget for both axes. See [Customization](#customization). |

### Placements

| `GridSheetVerticalScrollbarPlacement` | |
| --- | --- |
| `afterLastColumn` | Reserves a strip after the last column, so the scrollbar never covers content. |
| `overlay` | Draws over the last column, like a desktop overlay scrollbar; no space reserved. |
| `external` | The grid draws none and reserves no space; place a `GridSheetScrollbar` yourself. |

| `GridSheetHorizontalScrollbarPlacement` | |
| --- | --- |
| `bottom` | Along the bottom, under the scrollable columns, below any pinned-bottom rows. |
| `external` | The grid draws none; place a `GridSheetScrollbar` yourself. |

---

## Behavior

- **What scrolls.** The vertical scrollbar scrolls the rows (pinned rows
  stay put); the horizontal one scrolls the unpinned columns (pinned
  columns stay put), so it runs under the scrollable section only.
- **Turning an axis off** (`showVerticalScrollbar: false`) removes its
  scrollbar and stops all scrolling on that axis; no space is reserved.
- **Scrollbars appear only when there's something to scroll.**
- With pinned-right columns, the vertical scrollbar's strip sits after
  them, at the grid's edge.
- Under RTL, the vertical scrollbar moves to the left edge.

---

## Runtime API

Change the look by passing a new `scrollConfiguration`. To scroll in code:

| Member | Description |
| --- | --- |
| `gridManager.cells.scrollTo(rowKey:, columnKey:)` | Scrolls both axes to bring a cell into view. |
| `gridManager.grouping.rows.scrollTo(groupId)` | Scrolls a row group's header to the top. |
| `gridManager.config.scroll` | The current scroll configuration (read-only). |

```dart
gridManager.cells.scrollTo(rowKey: lastRow.key, columnKey: totalKey);
```

### External scrollbars

Set a placement to `external` and put a `GridSheetScrollbar` anywhere,
for example beside or below the grid:

```dart
Column(children: [
  Expanded(
    child: Row(children: [
      Expanded(
        child: GridSheet(
          columns: columns,
          rows: rows,
          scrollConfiguration: const GridSheetScrollBarConfiguration(
            verticalScrollbarPlacement: GridSheetVerticalScrollbarPlacement.external,
            horizontalScrollbarPlacement: GridSheetHorizontalScrollbarPlacement.external,
          ),
          onLoaded: (event) => setState(() => gridManager = event.gridManager),
        ),
      ),
      if (gridManager != null)
        GridSheetScrollbar(gridManager: gridManager!, axis: Axis.vertical),
    ]),
  ),
  if (gridManager != null)
    GridSheetScrollbar(gridManager: gridManager!, axis: Axis.horizontal),
]),
```

`GridSheetScrollbar`:

- Fills the length its parent allows along its axis; give it a bounded one.
  The thumb is proportional to the content over that length.
- Takes the grid's look (`thickness`, `radius`, colors, visibility), each
  overridable on the widget: `thumbVisibility`, `trackVisibility`,
  `thickness`, `radius`, `thumbColor`, `trackColor`.
- Shows nothing before the grid's first layout, in the form layout, when
  the axis has nothing to scroll, or when that axis's scrolling is off.

---

## Events

None.

---

## Customization

`scrollbarBuilder` replaces the scrollbar widget. It's called once per
axis with the scrolling content (`child`), its `controller` and the
`axis`; wrap `child` and attach the given controller. When set, the look
options above are ignored, and it isn't called for an `external` axis.

The two scroll views are nested, so a vertical scrollbar needs a
`notificationPredicate` that skips the horizontal view's notifications:

```dart
scrollbarBuilder: (context, child, controller, axis) => RawScrollbar(
  controller: controller,
  thumbVisibility: true,
  thickness: 14,
  radius: const Radius.circular(20),
  notificationPredicate: axis == Axis.vertical
      ? (n) => n.metrics.axis == Axis.vertical && n.depth == 1
      : defaultScrollNotificationPredicate,
  child: child,
),
```

Return `child` unchanged to hide the scrollbar but keep scrolling, for
example on phones:

```dart
scrollbarBuilder: isPhone ? (context, child, controller, axis) => child : null,
```

---

## Limitations

- **One builder for both axes**; branch on `axis` for different looks.
- **`copyWith` can't clear a field to `null`** (`thumbColor`,
  `scrollbarBuilder`); build a new configuration instead.
- **No scroll events or position API**; use `cells.scrollTo` to move.

---

## See also

- [Styling](styling.md)
- [Fixed columns](fixed-columns.md) · [Fixed rows](fixed-rows.md)
- [Layout widgets](layout-widgets.md): the grid inside scrollable pages
