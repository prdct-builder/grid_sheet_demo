import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheetManager.reload], [GridSheet.rowsLoader],
/// [GridSheet.reloadConfiguration]'s auto-reload schedule, and (toggle-able,
/// off by default) pull-to-refresh — a plain [RefreshIndicator] wrapped
/// around [GridSheet] in [_buildGrid]; there's no dedicated package API for
/// this, [GridSheetManager.reload] is all a host needs.
class ReloadDemo extends StatefulWidget {
  const ReloadDemo({super.key});

  @override
  State<ReloadDemo> createState() => _ReloadDemoState();
}

class _ReloadDemoState extends State<ReloadDemo> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'rowsLoader() simulates a server fetch. Manual Reload calls reload() once; '
    'Auto-Reload repeats it on the reloadConfiguration.interval timer.',
  );

  static const _tickers = ['ACME', 'GLBX', 'INTL', 'UMBR', 'NOVA'];
  final _rng = math.Random();
  final Map<String, double> _prices = {
    'ACME': 128.45,
    'GLBX': 74.10,
    'INTL': 39.90,
    'UMBR': 210.75,
    'NOVA': 58.20,
  };
  int _fetchCount = 0;
  int _newRowCount = 0;
  bool _autoReloadOn = false;
  bool _pullToRefreshOn = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FeaturePageTemplate(
      title: 'Reload',
      description:
          'rowsLoader re-fetches row data on demand — either manually via GridSheetManager.reload() or '
          'automatically on a repeating interval.',
      icon: Icons.sync_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Add Row',
            icon: Icons.add_circle_outline,
            color: context.accents.purple,
            onPressed: _addRow,
            tooltip: 'Insert a local row not known to rowsLoader',
          ),
          DemoActionButton(
            label: 'Manual Reload',
            icon: Icons.refresh_outlined,
            color: context.accents.blue,
            onPressed: _manualReload,
            tooltip: 'Call reload() once and refetch rows now',
          ),
          DemoToggleButton(
            label: 'Auto-Reload (5s)',
            icon: Icons.autorenew_outlined,
            color: context.accents.green,
            value: _autoReloadOn,
            onChanged: _toggleAutoReload,
            tooltip: 'Repeat reload() automatically every 5 seconds',
          ),
          DemoToggleButton(
            label: 'Pull to Refresh',
            icon: Icons.swipe_down_alt_outlined,
            color: context.accents.teal,
            value: _pullToRefreshOn,
            onChanged: _togglePullToRefresh,
            tooltip: 'Wrap the grid in a RefreshIndicator calling reload()',
          ),
        ],
      ),
      grid: _buildGrid(colorScheme),
    );
  }

  Widget _buildGrid(ColorScheme colorScheme) {
    final gridSheet = GridSheet(
      columns: _columns(),
      rows: _buildInitialRows(),
      configuration: const GridSheetConfiguration(enableCellSelection: true),
      styleConfiguration: styleConfig(context),
      scrollConfiguration: scrollConfig(context),
      rowsLoader: _loadRows,
      reloadConfiguration: const GridSheetReloadConfiguration(
        interval: Duration(seconds: 5),
      ),
      loadingIndicator: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5),
            const SizedBox(height: 10),
            Text(
              'Reloading…',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      onLoaded: (event) {
        gridManager = event.gridManager;
        // reloadConfiguration.interval auto-starts the schedule on mount —
        // stop it immediately so the toggle below starts in sync as OFF.
        gridManager.autoReload.stop();
      },
      onAfterReload: (event) {
        if (!mounted) return;
        status.value = 'reload() completed — '
            '${event.isAutoReload ? 'auto-reload' : 'manual reload'} · '
            'fetch #$_fetchCount · ${_tickers.length} row(s) refreshed at '
            '${_formatTime(DateTime.now())}';
      },
      rowStateIndicatorBuilder: (row) {
        if (row.isInserted) {
          return GridSheetRowStateIndicator(
            color: context.accents.green.withValues(alpha: 0.08),
            icon: Icon(Icons.fiber_new, color: context.accents.green, size: 16),
          );
        }
        if (row.isModified) {
          return GridSheetRowStateIndicator(
            color: context.accents.orange.withValues(alpha: 0.08),
            icon: Icon(Icons.edit, color: context.accents.orange, size: 16),
          );
        }
        if (row.isDeleted) {
          return GridSheetRowStateIndicator(
            color: context.accents.red.withValues(alpha: 0.08),
          );
        }
        return null; // default look
      },
    );

    if (!_pullToRefreshOn) return gridSheet;

    // Pull-to-refresh recipe: GridSheet has no enablePullToRefresh flag of
    // its own — a plain RefreshIndicator wrapping the grid and calling
    // GridSheetManager.reload() (the same method Manual Reload above uses)
    // is all that's needed. Two things to know before copying this:
    //
    // 1. notificationPredicate must accept BOTH depth 0 and depth 1. Table
    //    view's virtualized-rows layout nests its vertical row list inside
    //    an outer horizontal scroller (for column scrolling), which bumps
    //    the vertical scroll notification's depth to 1 by the time it
    //    reaches this RefreshIndicator; the empty-rows layout doesn't have
    //    that extra nesting, so it stays at depth 0. RefreshIndicator's own
    //    default predicate only accepts depth 0, so it would silently never
    //    trigger here without this override. Form view (list or masonry)
    //    only ever has one scroller, so the default predicate is fine
    //    there — this override is specific to wrapping table view.
    // 2. Like any RefreshIndicator, the gesture only registers once the
    //    content actually overflows the viewport — on a very short dataset
    //    (this demo's 5 rows, before any narrow/mobile-sized window makes
    //    that overflow) there's nothing to drag against, so pulling won't
    //    do anything yet. Add a few rows (or shrink the window) to see it
    //    respond.
    return RefreshIndicator(
      onRefresh: () => gridManager.reload(),
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.vertical &&
          (notification.depth == 0 || notification.depth == 1),
      child: gridSheet,
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['TICKER', 'PRICE', 'CHANGE', 'UPDATED'];
    const titles = ['Ticker', 'Price', 'Change', 'Updated'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
    ];
    const widths = [100.0, 100.0, 100.0, 100.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : (i == 0 ? TextAlign.left : TextAlign.center),
      );
    });
  }

  List<GridSheetRow> _buildInitialRows() {
    return _tickers.asMap().entries.map((e) {
      return GridSheetRow(
        key: ValueKey('row_${e.key}'),
        index: e.key,
        data: [e.value, _prices[e.value], '—', '—'],
        height: Constants.rowHeight,
      );
    }).toList();
  }

  Future<List<GridSheetRow>> _loadRows() async {
    // Simulated network latency — long enough for the manual-reload
    // loadingIndicator overlay to be visible.
    await Future.delayed(const Duration(milliseconds: 700));
    _fetchCount++;
    final now = _formatTime(DateTime.now());
    return _tickers.asMap().entries.map((e) {
      final ticker = e.value;
      final prevPrice = _prices[ticker]!;
      final changePct = (_rng.nextDouble() - 0.5) * 6; // -3% .. +3%
      final newPrice = double.parse((prevPrice * (1 + changePct / 100))
          .clamp(1.0, 999.0)
          .toStringAsFixed(2));
      _prices[ticker] = newPrice;
      return GridSheetRow(
        key: ValueKey('row_${e.key}'),
        index: e.key,
        data: [
          ticker,
          newPrice,
          '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
          now,
        ],
        height: Constants.rowHeight,
      );
    }).toList();
  }

  Future<void> _addRow() async {
    _newRowCount++;
    final row = GridSheetRow(
      key: ValueKey('new_row_$_newRowCount'),
      index: gridManager.rows.count,
      data: ['NEW$_newRowCount', 100.0, '—', 'not from server'],
      state: GridSheetRowState.inserted,
      height: Constants.rowHeight,
    );
    await gridManager.rows.insertAt(null, [row]);
    if (!mounted) return;
    status.value = 'insertRowsAt(): added "NEW$_newRowCount" locally — now try '
        'Manual Reload: rowsLoader only returns the ${_tickers.length} known '
        'tickers, so this row will disappear.';
  }

  Future<void> _manualReload() async {
    status.value = 'Reloading…';
    await gridManager.reload();
  }

  void _toggleAutoReload(bool enable) {
    if (enable) {
      gridManager.autoReload.start();
      status.value =
          'startAutoReload(): reload() will now run every 5 seconds.';
    } else {
      gridManager.autoReload.stop();
      status.value = 'stopAutoReload(): schedule stopped.';
    }
    setState(() => _autoReloadOn = enable);
  }

  void _togglePullToRefresh(bool enable) {
    status.value = enable
        ? 'RefreshIndicator now wraps the grid — drag down from the top to '
            'call reload().'
        : 'RefreshIndicator removed.';
    setState(() => _pullToRefreshOn = enable);
  }

  String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
}
