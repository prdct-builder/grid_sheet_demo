# Row swipe

Rows can be swiped sideways, like list items in a mobile app, to reveal
actions: drag a row one way to show **Save**, the other way to show **Edit**
and **Delete**, or swipe all the way to run an action at once. Each side is
set up separately.

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
  rowSwipeConfiguration: GridSheetRowSwipeConfiguration(
    enabled: true,
    end: GridSheetRowSwipeSideConfiguration(
      revealBuilder: (context, details) => const ColoredBox(
        color: Colors.red,
        child: Center(child: Icon(Icons.delete, color: Colors.white)),
      ),
      onFullSwipe: (event) => event.gridManager.rows.delete([event.key]),
    ),
  ),
)
```

Swipe a row toward the start (left in LTR) and let go past the threshold:
it's deleted.

---

## Configuration

### GridSheetRowSwipeConfiguration

`GridSheet.rowSwipeConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enabled` | `false` | The master switch. Turning it off closes an open row. |
| `start` | `null` | The side revealed by dragging toward the reading **end** (right in LTR). `null` turns it off. |
| `end` | `null` | The side revealed by dragging toward the reading **start** (left in LTR). |

### GridSheetRowSwipeSideConfiguration

| Option | Default | Meaning |
| --- | --- | --- |
| `revealBuilder` | `null` (a neutral tint) | Builds the strip shown behind the row. |
| `revealExtent` | `80` | The strip's width: how far the row can be dragged without a full swipe, and where it rests when held open. |
| `release` | `slideBack` | What a released row does: `slideBack` always slides back; `holdOpen` stays open past half the strip, so its actions can be tapped. |
| `onFullSwipe` | `null` | Runs when the row is swiped past `fullSwipeThreshold`. `null` means no full swipe. |
| `fullSwipeThreshold` | `0.6` | Where a full swipe starts, as a fraction of the grid's visible width. |
| `canSwipe` | `null` | `(row) => bool`: whether a row can be swiped on this side. |
| `allowedPointerKinds` | touch, stylus | Which pointers can swipe. Add `PointerDeviceKind.mouse` to swipe with a mouse. |
| `animationDuration` | `200 ms` | Sliding back, opening, closing and sliding out. |
| `onSwipeStart` / `onSwipeEnd` | `null` | Called when a swipe starts and when it's released. See [Events](#events). |

---

## Behavior

### Swiping

- A sideways drag on a row becomes a swipe once it clearly moves sideways;
  vertical drags keep scrolling.
- **Held open** (`holdOpen`), a row closes on a tap outside it, a tap on the
  row, a scroll, dragging it back, or `details.close()`.
- **Full swipe.** With `onFullSwipe`, the row can be dragged past
  `revealExtent`, up to the grid's width. Released past
  `fullSwipeThreshold`, it slides out and the callback runs. If the
  callback returns a `Future`, the row waits for it, then slides back if it
  still exists. An error it throws goes to `FlutterError.onError`.
- **`canSwipe`** is asked once per drag, before it becomes a swipe; return
  `false` to let the drag go to the cell or scroll view instead.

### Swipes and scrolling

Only the scrollable columns slide; pinned-left and pinned-right columns
stay in place, and drags on them don't swipe.

When the table is wider than the viewport, horizontal drags scroll the
table; a swipe is claimed only when the scroll position can't take the
drag: start-side swipes at the start edge, end-side swipes at the end edge.
When the table fits, both directions swipe anywhere.

### Swipes and the rest of the grid

- Cell editing, selection and taps keep working.
- The autofill fill handle never swipes the row.
- Trackpad two-finger gestures always scroll.
- Widgets in your cells that drag sideways (a `Slider`) need
  `GridSheetRowSwipeExclusion` around them; otherwise the swipe takes their
  drag. See [Customization](#customization).
- Under RTL, the sides mirror with the reading direction.

---

## Runtime API

There's no API on `gridManager` for swiping. Turn it on and off, or change
its sides, by passing a new `rowSwipeConfiguration`; rows and cell edits are
kept. Callbacks get the grid in their event or details, to act on the row:

```dart
onFullSwipe: (event) async {
  await api.archive(event.key.value);
  await event.gridManager.rows.delete([event.key]);
},
```

---

## Events

### GridSheetRowSwipeEvent

Passed to `onSwipeStart`, `onSwipeEnd` and `onFullSwipe`.

| Field | Description |
| --- | --- |
| `key` | The swiped row's key. |
| `side` | `GridSheetRowSwipeSide.start` or `.end`. |
| `revealedExtent` | How far the row has moved, in pixels. |
| `velocity` | The release velocity in pixels per second (positive while opening); `0` in `onSwipeStart`. |
| `gridManager` | The grid. |

```dart
onSwipeEnd: (event) {
  if (event.velocity > 600) analytics.log('fast swipe on ${event.key.value}');
},
```

---

## Customization

### The strip

`revealBuilder` gets `GridSheetRowSwipeRevealDetails`:

| Field | Description |
| --- | --- |
| `rowKey` / `side` | The row and side. |
| `revealedExtent` | How far it's revealed, to show more as it opens. |
| `fullSwipeReached` | Whether letting go now runs the full swipe, to show "Release to delete". |
| `close()` | Closes the row. |
| `gridManager` | The grid. |

```dart
revealBuilder: (context, details) => details.fullSwipeReached
    ? const ColoredBox(color: Colors.red, child: Center(child: Text('Release to delete')))
    : Row(children: [
        Expanded(child: TextButton(onPressed: () { edit(details.rowKey); details.close(); },
            child: const Text('Edit'))),
        Expanded(child: TextButton(onPressed: () => details.gridManager.rows.delete([details.rowKey]),
            child: const Text('Delete'))),
      ]),
```

The strip's buttons become tappable once the row is held open.

### Keeping a cell's own drag

Wrap a cell widget that drags sideways in `GridSheetRowSwipeExclusion`, so
dragging it moves the widget instead of swiping the row:

```dart
cellBuilder: (cell) => cell.column.name == 'RATING'
    ? GridSheetRowSwipeExclusion(child: Slider(value: rating, onChanged: setRating))
    : null,
```

---

## Limitations

- **Mouse swiping is off by default**, so mouse drags keep selecting and
  scrolling; add it per side with `allowedPointerKinds`.
- **No API to open or close rows** from outside the strip.
- **Pinned rows, pinned columns and the form layout never swipe.**

---

## See also

- [Row operations](row-operations.md): deleting rows, the undo window
- [Custom cells](custom-cells.md)
- [RTL support](rtl-support.md)
- [Autofill](autofill.md)
