import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';
import '../helper/pivot_fake_server.dart';
import '../helper/pivot_field_chooser.dart';

/// Demonstrates [GridSheet.pivotConfiguration]: sales summarized by row
/// fields down the side and column fields across the top, with totals,
/// subtotals and averages, switched on and off through [GridSheet.viewMode].
///
/// Everything after the first build goes through [GridSheetManager.pivot]:
/// the [PivotFieldChooser] panel (an app-side widget built on the public
/// API) and the toolbar toggles both call `pivot.setConfiguration`.
class PivotDemo extends StatefulWidget {
  const PivotDemo({super.key});

  @override
  State<PivotDemo> createState() => _PivotDemoState();
}

const _region = ValueKey<String>('col_region');
const _category = ValueKey<String>('col_category');
const _product = ValueKey<String>('col_product');
const _date = ValueKey<String>('col_date');
const _qty = ValueKey<String>('col_qty');
const _amount = ValueKey<String>('col_amount');

/// Sales by region › category and quarter, summing the amount: 40 lines and
/// 24 quarters, so the pivot scrolls both ways.
final _initial = GridSheetPivotConfiguration(
  rowFields: [
    GridSheetGroupDescriptor(
        columnKey: _region,
        title: 'Region',
        sort: const GridSheetGroupSort.value()),
    GridSheetGroupDescriptor(
        columnKey: _category,
        title: 'Category',
        sort: const GridSheetGroupSort.value()),
  ],
  columnFields: [
    GridSheetGroupDescriptor.date(_date, GridSheetGroupDatePart.quarter,
        title: 'Order Date'),
  ],
  values: const [GridSheetAggregateSpec.sum(_amount)],
);

/// Below this width the field chooser opens as a bottom sheet.
const _sidePanelMinWidth = 1000.0;

class _PivotDemoState extends State<PivotDemo> {
  // One grid per data source: switching makes a new grid.
  final _clientGridKey = GlobalKey<GridSheetState>();
  final _serverGridKey = GlobalKey<GridSheetState>();
  GlobalKey<GridSheetState> get _gridKey =>
      _serverRows ? _serverGridKey : _clientGridKey;

  // Whether the rows come from the (fake) server: onPageChange pages them
  // and onPivotRequest summarizes them.
  bool _serverRows = false;
  late final _backend = PivotFakeServer(_columns, _data);
  Map<String, List<dynamic>> _serverFilters = const {};
  // What a new grid starts with: the fields as they were when switching.
  GridSheetPivotConfiguration _start = _initial;
  final ValueNotifier<String> status = ValueNotifier(
    '1,500 orders by region › category and quarter — scroll both ways. Drag '
    'fields in the Pivot fields panel (Group by Month for 72 columns), tap a '
    'header to sort the groups by it, a value to see the orders behind it, a '
    'chevron to expand a group — or switch to the table to filter the rows '
    'the pivot summarizes.',
  );

  bool _pivot = true;

  late final List<GridSheetColumn> _columns = _gridColumns();
  late final List<GridSheetRow> _data = _buildRows();

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  GridSheetPivotAPI? get _api => _gridKey.currentState?.pivot;

  /// The grid's configuration: [_initial] until the first change.
  GridSheetPivotConfiguration get _current => _api?.configuration ?? _initial;

  // Every change goes to the grid; setState repaints the panel and toggles.
  void _apply(GridSheetPivotConfiguration configuration) {
    _api?.setConfiguration(configuration);
    setState(() {});
  }

  void _onFieldsChanged(GridSheetPivotConfiguration configuration) {
    _apply(configuration);
    String titles(List<GridSheetGroupDescriptor> fields) => fields.isEmpty
        ? '—'
        : fields
            .map((f) =>
                f.title ??
                _columns.firstWhere((c) => c.key == f.columnKey).title)
            .join(' › ');
    status.value = 'Rows: ${titles(configuration.rowFields)} · Columns: '
        '${titles(configuration.columnFields)} · Values: '
        '${configuration.values.isEmpty ? '— (add one to see the pivot)' : configuration.values.map((v) => '${v.displayLabel} of ${_columns.firstWhere((c) => c.key == v.columnKey).title}').join(', ')}';
  }

  PivotFieldChooser _chooser(
          void Function(GridSheetPivotConfiguration) onChanged) =>
      PivotFieldChooser(
        fields: _columns,
        configuration: _current,
        onChanged: onChanged,
      );

  void _openChooserSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _chooser((c) {
              _onFieldsChanged(c);
              setSheetState(() {});
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final sidePanel =
        _pivot && MediaQuery.sizeOf(context).width >= _sidePanelMinWidth;
    final grid = GridSheet(
      key: _gridKey,
      columns: _columns,
      rows: _serverRows ? const [] : _data,
      styleConfiguration: styleConfig(context),
      scrollConfiguration: scrollConfig(context),
      configuration: _serverRows
          ? const GridSheetConfiguration(
              showColumnFilters: true,
              enableCellSelection: true,
              enableMultiSelection: true,
              serverSidePagination: true,
              rowsPerPage: 10)
          : const GridSheetConfiguration(
              showColumnFilters: true,
              enableCellSelection: true,
              enableMultiSelection: true),
      viewMode: _pivot ? GridSheetViewMode.pivot : GridSheetViewMode.table,
      // Passed when the grid is made: later changes go through
      // gridManager.pivot.
      pivotConfiguration: _start,
      onPageChange: _serverRows ? _backend.page : null,
      onPivotRequest: _serverRows ? _onPivotRequest : null,
      loadingIndicator:
          _serverRows ? const Center(child: CircularProgressIndicator()) : null,
      onError: (event) => status.value = event.message ?? '${event.error}',
      onPivotCellTapped: _showDrillDown,
    );
    return FeaturePageTemplate(
      title: 'Pivot Table',
      icon: Icons.pivot_table_chart_outlined,
      status: status,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DemoToolbar(
            sections: [
              DemoToggleButton(
                label: 'Pivot',
                icon: Icons.pivot_table_chart_outlined,
                color: context.accents.deepPurple,
                value: _pivot,
                onChanged: _togglePivot,
                tooltip: 'Switch GridSheet.viewMode between pivot and table',
              ),
              DemoActionButton(
                label: 'Expand all',
                icon: Icons.unfold_more,
                color: context.accents.teal,
                onPressed: () => _api?.expandAll(),
                tooltip: 'gridManager.pivot.expandAll()',
              ),
              DemoActionButton(
                label: 'Collapse all',
                icon: Icons.unfold_less,
                color: context.accents.teal,
                onPressed: () => _api?.collapseAll(),
                tooltip: 'gridManager.pivot.collapseAll()',
              ),
              if (_pivot && !sidePanel)
                DemoActionButton(
                  label: 'Fields',
                  icon: Icons.tune,
                  color: context.accents.indigo,
                  onPressed: _openChooserSheet,
                  tooltip: 'Choose the row, column and value fields',
                ),
              DemoActionButton(
                label: 'Reset fields',
                icon: Icons.restart_alt,
                color: context.accents.indigo,
                onPressed: () {
                  _apply(_initial);
                  status.value =
                      'Back to sales by region › category and quarter.';
                },
                tooltip: 'gridManager.pivot.setConfiguration(initial)',
              ),
              DemoActionButton(
                label: 'Clear sort',
                icon: Icons.sort,
                color: context.accents.teal,
                onPressed: () {
                  _api?.clearSort();
                  status.value = 'Row groups back in the row fields\' order.';
                },
                tooltip: 'gridManager.pivot.clearSort() — tap a header to sort',
              ),
              DemoActionButton(
                label: 'Export CSV',
                icon: Icons.download_outlined,
                color: context.accents.green,
                onPressed: _exportCsv,
                tooltip: 'gridManager.pivot.toCsv()',
              ),
              DemoActionButton(
                label: 'Copy selection',
                icon: Icons.copy_outlined,
                color: context.accents.green,
                onPressed: _copySelection,
                tooltip: 'gridManager.pivot.copy() — select pivot cells '
                    'first',
              ),
              DemoToggleButton(
                label: 'Highlight',
                icon: Icons.format_color_fill,
                color: context.accents.orange,
                value: current.conditionalFormatRules.isNotEmpty,
                onChanged: _toggleHighlight,
                tooltip: 'gridManager.pivot.formatting.setRules: bold totals, '
                    'large amounts in green',
              ),
              _toggle(
                context,
                'Row grand total',
                Icons.view_week_outlined,
                current.showRowGrandTotal,
                (v) => current.copyWith(showRowGrandTotal: v),
                'A Grand Total column at the right (showRowGrandTotal)',
              ),
              _toggle(
                context,
                'Column grand total',
                Icons.summarize_outlined,
                current.showColumnGrandTotal,
                (v) => current.copyWith(showColumnGrandTotal: v),
                'A Grand Total line at the bottom (showColumnGrandTotal)',
              ),
              _toggle(
                context,
                'Row subtotals',
                Icons.account_tree_outlined,
                current.showRowSubtotals,
                (v) => current.copyWith(showRowSubtotals: v),
                'Values on outer row groups (showRowSubtotals)',
              ),
              _toggle(
                context,
                'Column subtotals',
                Icons.calendar_view_week,
                current.showColumnSubtotals,
                (v) => current.copyWith(showColumnSubtotals: v),
                'A Total column in each outer column group '
                    '(showColumnSubtotals)',
              ),
              _toggle(
                context,
                'Row average',
                Icons.trending_flat,
                current.showRowAverage,
                (v) => current.copyWith(showRowAverage: v),
                'An Average column at the right (showRowAverage)',
              ),
              _toggle(
                context,
                'Column average',
                Icons.align_vertical_bottom,
                current.showColumnAverage,
                (v) => current.copyWith(showColumnAverage: v),
                'An Average line at the bottom (showColumnAverage)',
              ),
              DemoToggleButton(
                label: 'Server rows',
                icon: Icons.cloud_outlined,
                color: context.accents.deepPurple,
                value: _serverRows,
                onChanged: _toggleServerRows,
                tooltip: 'Page the rows with onPageChange and summarize them '
                    'with onPivotRequest, from an in-memory fake server',
              ),
            ],
          ),
        ],
      ),
      grid: sidePanel
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: grid),
                const SizedBox(width: 12),
                SizedBox(width: 300, child: _chooser(_onFieldsChanged)),
              ],
            )
          : grid,
    );
  }

  // The summary from the "server"; the filters are kept for drill-down.
  Future<GridSheetPivotData> _onPivotRequest(
      GridSheetPivotRequest request) async {
    _serverFilters = request.filters;
    final data = await _backend.pivot(request);
    if (mounted) {
      status.value = 'onPivotRequest: the server summarized '
          '${request.groupingSets.length} grouping sets into '
          '${data.cells.length} cells.';
    }
    return data;
  }

  // Drill-down: the orders behind the tapped value — given on the client,
  // fetched by the cell's keys from the server.
  Future<void> _showDrillDown(GridSheetPivotCellTappedEvent event) async {
    final where = [
      event.line.label,
      if (event.column != null) event.column!.path.join(' › '),
    ].join(' · ');
    var rows = event.rows;
    if (_serverRows) {
      status.value = '$where: asking the server for its orders…';
      rows = await _backend.rowsAt(
          _current, event.rowGroupKeys, event.columnGroupKeys,
          filters: _serverFilters);
      if (!mounted) return;
    }
    final products = {for (final row in rows) row.data[2]};
    final count = rows.length;
    status.value = count == 0
        ? '$where: no orders.'
        : '$where: $count order${count == 1 ? '' : 's'} — '
            '${products.take(4).join(', ')}${products.length > 4 ? ', …' : ''}';
  }

  Widget _toggle(BuildContext context, String label, IconData icon, bool value,
      GridSheetPivotConfiguration Function(bool) change, String tooltip) {
    return DemoToggleButton(
      label: label,
      icon: icon,
      color: context.accents.blue,
      value: value,
      onChanged: (v) {
        _apply(change(v));
        status.value = '$label ${v ? 'on' : 'off'}.';
      },
      tooltip: tooltip,
    );
  }

  void _toggleServerRows(bool value) {
    setState(() {
      _start = _current;
      _serverRows = value;
    });
    status.value = value
        ? 'Rows from the server: the table shows a page at a time '
            '(onPageChange), and the server summarizes all of them for the '
            'pivot (onPivotRequest). Tap a value to fetch its orders by the '
            'cell\'s keys.'
        : 'Rows on the client: the grid summarizes them itself.';
  }

  // Copies the selected pivot cells to the system clipboard, as a
  // spreadsheet pastes them.
  Future<void> _copySelection() async {
    final text = await _api?.copy(includeHeaders: true) ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      status.value = 'Select pivot cells first.';
      return;
    }
    final lines = text.split('\n');
    status.value = 'Copied ${lines.length - 1} line(s): '
        '${lines.take(2).join(' ⏎ ')}${lines.length > 2 ? ' …' : ''}';
  }

  // Pivot formatting rules: a cell rule targets a value by its id
  // ('sum:amount'); expressions read the pivot's variables.
  static const _highlightRules = [
    GridSheetConditionalFormatRule(
      name: 'totals',
      expression: '_line_kind == "grandTotal" || _column_kind == "grandTotal"',
      textStyle: TextStyle(fontWeight: FontWeight.bold),
    ),
    GridSheetConditionalFormatRule(
      name: 'sum:col_amount',
      scope: GridSheetFormatScope.cell,
      expression: '_column_kind == "bucket" && _cell_value >= 5000 '
          '? "#C8E6C9" : null',
    ),
  ];

  Future<void> _toggleHighlight(bool value) async {
    await _api?.formatting.setRules(value ? _highlightRules : const []);
    setState(() {});
    status.value = value
        ? 'Totals in bold; quarters with 5,000 or more in green '
            '(gridManager.pivot.formatting).'
        : 'Highlight off.';
  }

  void _togglePivot(bool value) {
    setState(() => _pivot = value);
    status.value = value
        ? 'viewMode: pivot — the rows below are summarized. Filters set in '
            'the table still apply.'
        : 'viewMode: table — the rows as they are. Filter them, then switch '
            'back: the pivot summarizes only what is shown.';
  }

  void _exportCsv() {
    final csv = _api?.toCsv() ?? '';
    final lines = csv.split('\n');
    status.value = csv.isEmpty
        ? 'Switch to the pivot to export it.'
        : 'CSV (${lines.length} lines): ${lines.take(2).join(' ⏎ ')} …';
  }

  List<GridSheetColumn> _gridColumns() {
    const specs = [
      (_region, 'REGION', 'Region', GridSheetColumnType.text(), 140.0),
      (_category, 'CATEGORY', 'Category', GridSheetColumnType.text(), 150.0),
      (_product, 'PRODUCT', 'Product', GridSheetColumnType.text(), 200.0),
      (
        _date,
        'ORDER_DATE',
        'Order Date',
        GridSheetColumnType.datetime(),
        140.0
      ),
      (_qty, 'QTY', 'Qty', GridSheetColumnType.integer(), 100.0),
      (_amount, 'AMOUNT', 'Amount', GridSheetColumnType.double(), 140.0),
    ];
    return [
      for (final (i, (key, name, title, type, width)) in specs.indexed)
        GridSheetColumn(
          key: key,
          index: i,
          name: name,
          title: title,
          type: type,
          width: width,
          textAlign: switch (type.kind) {
            GridSheetColumnKind.integer ||
            GridSheetColumnKind.double =>
              TextAlign.right,
            _ => TextAlign.left,
          },
          sortable: true,
          // Resizable here, so the pivot's columns are too.
          resizable: true,
        ),
    ];
  }

  // 1,500 orders over 2020–2025, generated from a fixed seed so the demo
  // shows the same numbers every time.
  List<GridSheetRow> _buildRows() {
    const regions = [
      'Africa',
      'Asia Pacific',
      'Europe',
      'Latin America',
      'Middle East',
      'Nordics',
      'North America',
      'Oceania',
    ];
    // Category → (product, unit price).
    const catalog = {
      'Hardware': [
        ('Mechanical Keyboard', 89.0),
        ('Monitor Arm', 54.0),
        ('USB-C Hub', 39.5),
        ('Wireless Mouse', 24.99),
        ('Docking Station', 179.0),
        ('Cable Organizer', 6.99),
        ('Wrist Rest', 14.25),
        ('4K Monitor', 349.0),
      ],
      'Software': [
        ('Design Suite License', 299.0),
        ('Analytics Add-on', 299.0),
        ('Security Suite', 149.0),
        ('Backup Service', 79.0),
        ('Project Tracker', 59.0),
      ],
      'Services': [
        ('Onboarding Workshop', 1500.0),
        ('Premium Support', 2100.0),
        ('Data Migration', 3800.0),
        ('Training Day', 950.0),
        ('Consulting Hours', 180.0),
      ],
      'Cloud': [
        ('Storage Plan', 12.0),
        ('Compute Credits', 0.5),
        ('CDN Bandwidth', 0.08),
        ('Managed Database', 220.0),
        ('Edge Functions', 0.02),
      ],
    };
    final categories = catalog.keys.toList();
    final random = math.Random(2024);
    final first = DateTime(2020);
    final days = DateTime(2025, 12, 31).difference(first).inDays;
    String two(int n) => n.toString().padLeft(2, '0');

    return [
      for (var i = 0; i < 1500; i++)
        () {
          final category = categories[random.nextInt(categories.length)];
          final (product, price) =
              catalog[category]![random.nextInt(catalog[category]!.length)];
          final date = first.add(Duration(days: random.nextInt(days + 1)));
          final qty = switch (category) {
            'Services' => 1 + random.nextInt(3),
            'Cloud' => 100 * (1 + random.nextInt(50)),
            _ => 1 + random.nextInt(60),
          };
          return GridSheetRow(
            key: ValueKey('row_$i'),
            index: i,
            data: [
              regions[random.nextInt(regions.length)],
              category,
              product,
              '${date.year}-${two(date.month)}-${two(date.day)}',
              qty,
              ((qty * price) * 100).roundToDouble() / 100,
            ],
            height: Constants.rowHeight,
          );
        }(),
    ];
  }
}
