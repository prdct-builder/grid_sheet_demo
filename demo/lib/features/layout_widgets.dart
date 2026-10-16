import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class LayoutWidgets extends StatefulWidget {
  const LayoutWidgets({super.key});

  @override
  State<LayoutWidgets> createState() => _LayoutWidgetsState();
}

class _LayoutWidgetsState extends State<LayoutWidgets> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'topBarBuilder/bottomBarBuilder wrap the table; emptyRowsPlaceholder/emptyColumnsPlaceholder/loadingIndicator swap '
    'in for the empty, no-columns, and loading states below.',
  );
  List<GridSheetRow> _rows = [];
  bool _isEmpty = false;
  bool _footerBorderColor = false;
  bool _columnsHidden = false;

  @override
  void initState() {
    super.initState();
    _rows = _buildRows();
  }

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = styleConfig(context);

    return FeaturePageTemplate(
      title: 'Layout Widgets',
      description:
          'Layout slots for wrapping the grid with fixed content and swapping in placeholder widgets '
          'for empty, columnless, or loading states.',
      icon: Icons.dashboard_customize_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Empty Table',
            icon: Icons.inbox_outlined,
            color: context.accents.deepOrange,
            value: _isEmpty,
            onChanged: (_) => _toggleEmptyState(),
            tooltip: 'Clear all rows to preview emptyRowsPlaceholder',
          ),
          DemoToggleButton(
            label: 'Hide All Columns',
            icon: Icons.view_column_outlined,
            color: context.accents.teal,
            value: _columnsHidden,
            onChanged: (_) => _toggleColumnsHidden(),
            tooltip: 'Hide every column to preview emptyColumnsPlaceholder',
          ),
          DemoActionButton(
            label: 'Simulate Loading (2s)',
            icon: Icons.hourglass_top_outlined,
            color: context.accents.indigo,
            onPressed: _simulateLoading,
            tooltip: 'Show loadingIndicator for 2 seconds',
          ),
          DemoToggleButton(
            label: 'Footer Border',
            icon: Icons.inbox_outlined,
            color: context.accents.deepOrange,
            value: _footerBorderColor,
            onChanged: (_) => _toggleFooterBorderColor(),
            tooltip: 'Toggle footer border',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows,
        configuration: const GridSheetConfiguration(
          enableCellSelection: true,
        ),
        styleConfiguration: style,
        scrollConfiguration: scrollConfig(context),
        rowsLoader: () async => _rows,
        onLoaded: (event) => gridManager = event.gridManager,
        loadingIndicator: const _TickerLoadingWidget(),
        emptyRowsPlaceholder: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 40, color: colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'emptyRowsPlaceholder — No data available.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        emptyColumnsPlaceholder: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_column_outlined,
                  size: 40, color: colorScheme.outlineVariant),
              const SizedBox(height: 8),
              Text(
                'emptyColumnsPlaceholder — every column is hidden',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        topBarBuilder: (manager) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'topBarBuilder — ',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(Icons.show_chart, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Live Watchlist · ${manager.rows.all.length} ticker(s)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        bottomBarBuilder: (manager) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: _footerBorderColor
                    ? Colors.blue
                    : style.bottomBarBorderColor,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'bottomBarBuilder — showing ${manager.rows.all.length} row(s)',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['TICKER', 'COMPANY', 'PRICE'];
    const titles = ['Ticker', 'Company', 'Price'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
    ];
    const widths = [120.0, 120.0, 120.0];
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
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _buildRows() {
    final raw = [
      ['ACME', 'Acme Corp', 128.45],
      ['GLBX', 'Globex Inc', 74.10],
      ['INTL', 'Initech Ltd', 39.90],
      ['UMBR', 'Umbrella Group', 210.75],
    ];
    return raw.asMap().entries.map((e) {
      return GridSheetRow(
        key: ValueKey('row_${e.key}'),
        index: e.key,
        data: e.value,
        height: Constants.rowHeight,
      );
    }).toList();
  }

  Future<void> _toggleEmptyState() async {
    setState(() {
      _isEmpty = !_isEmpty;
      _rows = _isEmpty ? [] : _buildRows();
    });
    // `rows` is only consumed once at mount; swapping the row set at runtime
    // has to go through rowsLoader + reload() rather than a plain rebuild.
    await gridManager.reload();
    if (!mounted) return;
    status.value = _isEmpty
        ? 'rows: [] — emptyRowsPlaceholder is now displayed instead of the table body'
        : 'rows restored — table body shown again';
  }

  static const _allColumnNames = ['TICKER', 'COMPANY', 'PRICE'];

  Future<void> _toggleColumnsHidden() async {
    final keys = gridManager.columns
        .findByNames(_allColumnNames)
        .map((c) => c.key)
        .toList();
    if (_columnsHidden) {
      await gridManager.columns.show(keys);
    } else {
      await gridManager.columns.hide(keys);
    }
    if (!mounted) return;
    setState(() => _columnsHidden = !_columnsHidden);
    status.value = _columnsHidden
        ? 'every column hidden — emptyColumnsPlaceholder now replaces the whole table'
        : 'columns restored — table shown again';
  }

  Future<void> _simulateLoading() async {
    gridManager.loading.start();
    status.value = 'setLoading(true): loadingIndicator shown for 2 seconds';
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    gridManager.loading.stop();
    status.value = 'setLoading(false): table restored';
  }

  void _toggleFooterBorderColor() {
    setState(() => _footerBorderColor = !_footerBorderColor);
  }
}

/// Custom [GridSheet.loadingIndicator]: a rotating ticker icon inside a
/// pulsing badge, with a trio of sequentially-fading dots underneath —
/// used instead of a plain [CircularProgressIndicator] to show that
/// `loadingIndicator` accepts any widget, not just the built-in spinner.
class _TickerLoadingWidget extends StatefulWidget {
  const _TickerLoadingWidget();

  @override
  State<_TickerLoadingWidget> createState() => _TickerLoadingWidgetState();
}

class _TickerLoadingWidgetState extends State<_TickerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pulse = 0.88 + 0.12 * (1 - (t - 0.5).abs() * 2);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  ),
                  child: Transform.rotate(
                    angle: t * 2 * math.pi,
                    child: Icon(Icons.sync_outlined,
                        color: colorScheme.primary, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Fetching live ticker data…',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (t + i / 3) % 1.0;
                  final opacity = 0.25 + 0.75 * (1 - (phase - 0.5).abs() * 2);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: opacity.clamp(0.25, 1.0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: colorScheme.primary, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
