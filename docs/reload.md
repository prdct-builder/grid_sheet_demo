# Reload

Reload fetches fresh rows and swaps them in, keeping the user's sort and
filters. It can run on demand from a button or pull-to-refresh, on a
**timer** (every 5 minutes), or at a **time of day** (9:00 every morning).
`rowsLoader` is the one function that fetches; the grid takes care of the
loading indicator, overlapping reloads and failures.

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
  rows: initialRows,
  rowsLoader: () async {
    final items = await api.fetchPrices();
    return [for (final (i, p) in items.indexed) toRow(i, p)];
  },
  reloadConfiguration: const GridSheetReloadConfiguration(interval: Duration(minutes: 5)),
  loadingIndicator: const Center(child: CircularProgressIndicator()),
)

// Anywhere else:
await gridManager.reload();
```

---

## Configuration

### On GridSheet

| Option | Meaning |
| --- | --- |
| `rowsLoader` | `Future<List<GridSheetRow>> Function()`: fetches the rows for a client-side reload. |
| `reloadConfiguration` | The automatic schedule, below. `null` means manual reloads only. |
| `loadingIndicator` | Shown during manual reloads (and auto-reloads, if asked). |
| `onBeforeReload` / `onAfterReload` | See [Events](#events). |

### GridSheetReloadConfiguration

| Option | Default | Meaning |
| --- | --- | --- |
| `interval` | `null` | Reload this long after mounting, then again this long after each reload finishes. |
| `scheduledTime` | `null` | Reload daily at this `TimeOfDay`, locked to the clock. |
| `showLoadingOnAutoReload` | `false` | Show `loadingIndicator` during automatic reloads too; by default they're silent. |
| `autoStart` | `true` | Start the schedule when the grid mounts. `false` waits for `autoReload.start()`, for example from a toggle. |

Both can be set together, for example hourly plus a midnight reset.

---

## Behavior

### What a reload does

| Mode | Reload |
| --- | --- |
| Client-side with `rowsLoader` | Calls it and replaces the rows with the result. |
| Client-side without `rowsLoader` | Re-applies sort and filters to the current rows; nothing is fetched. |
| Server-side pagination or infinite scroll | Fetches page 1 again through `onPageChange`, with the current sort and filters. |

### After rows are replaced

- **Kept**: sort, filters, search, column widths and order, hidden
  columns.
- **Reset**: selection and open row panels are cleared, the page goes back
  to 1, and the cell undo history is cleared.
- **The new rows are the baseline.** Local edits and inserted rows that
  `rowsLoader` doesn't return are gone. Each row's `state` and pinning come
  from the rows you return. Save pending changes (`gridManager.changes`)
  before reloading.
- A pending undo-delete is completed first.

### Timing

- **Manual** `reload()` shows the loading indicator and completes when the
  rows are in.
- **Interval**: the next reload is scheduled only after the previous one
  finishes, so a slow loader never stacks up reloads.
- **Overlapping reloads**: if a reload starts while another is still
  fetching, the newer one's rows win, even if the older one finishes last.
- A reload finishing after the grid is disposed is ignored.

### Failures

- A **manual** reload that throws completes with that error; await it to
  catch it.
- An **automatic** reload that throws is reported to `GridSheet.onError`
  (source `GridSheetErrorSource.reload`) and the schedule keeps running.
  Interval reloads back off after failures, waiting 2×, 4×, then up to 8×
  the interval, and return to normal after a success.
  `autoReload.failureCount` counts consecutive failures.

---

## Runtime API

| Member | Description |
| --- | --- |
| `gridManager.reload()` | Reloads now. |
| `gridManager.autoReload.start()` | Starts (or restarts) the schedule. It starts by itself on mount when a schedule is configured, unless `autoStart` is `false`. A running schedule restarts when the configuration changes. |
| `gridManager.autoReload.stop()` | Stops the schedule; `start()` resumes it. |
| `gridManager.autoReload.isActive` | Whether the schedule is running. |
| `gridManager.autoReload.failureCount` | Consecutive failed automatic reloads. |

```dart
// Refresh only while the app is in the foreground.
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  state == AppLifecycleState.resumed
      ? gridManager.autoReload.start()
      : gridManager.autoReload.stop();
}
```

### Pull to refresh

There's no built-in flag; wrap the grid in a `RefreshIndicator`. The row
list is nested inside the horizontal scroll view, so accept depth 1 too:

```dart
RefreshIndicator(
  onRefresh: gridManager.reload,
  notificationPredicate: (n) =>
      n.metrics.axis == Axis.vertical && (n.depth == 0 || n.depth == 1),
  child: GridSheet(...),
)
```

The pull only registers once the rows overflow the viewport.

---

## Events

### onBeforeReload / onAfterReload: GridSheetReloadEvent

`onBeforeReload` is called before each reload, manual or automatic.
`onAfterReload` is called once the reload's rows are in: not when the
reload fails, and not for a reload that a newer one replaced before it
finished (the newer one calls it).

| Field | Description |
| --- | --- |
| `isAutoReload` | `true` for a scheduled reload. |
| `gridManager` | The grid. |

```dart
onAfterReload: (event) => setState(() => lastUpdated = DateTime.now()),
```

Errors from automatic reloads go to `onError`; see
[Failures](#failures).

---

## Customization

- **A stale-data banner**: show it in a top bar while
  `autoReload.failureCount > 0`:

```dart
topBarBuilder: (grid) => grid.autoReload.failureCount > 0
    ? const MaterialBanner(content: Text('Prices may be out of date'), actions: [SizedBox()])
    : const SizedBox.shrink(),
```

- **Replacing rows from your own state** instead: pass new `rows` to the
  widget; the grid follows them like any input. Use `rowsLoader` when the
  grid should fetch on its own schedule.

---

## Limitations

- **Unsaved changes are replaced.** Reload doesn't merge; save or warn
  first.
- **The daily `scheduledTime` isn't backed off** after failures.

---

## See also

- [Layout widgets](layout-widgets.md): the loading indicator
- [Pagination](pagination.md): server-side pages
- [Snapshot](snapshot.md): restoring a local checkpoint instead
- [Row operations](row-operations.md): saving changes
