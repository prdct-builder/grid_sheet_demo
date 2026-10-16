import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../design_system/app_theme.dart';
import '../design_system/design_system.dart';

/// One page that shows GridSheet's main features together on a realistic
/// dataset — built for recording the README's demo video (route
/// `/showcase`).
///
/// Suggested recording flow:
/// 1. Scroll through 5,000 orders (row and column virtualization), past the
///    pinned ORDER and PAID columns.
/// 2. Sort by Total, filter Region, then type in Search.
/// 3. Edit a Qty cell, then drag the fill handle down (autofill).
/// 4. Turn on "Group by region": collapse a group, read the subtotals.
/// 5. Turn on "Row details" and expand a row.
/// 6. Swipe a row left to delete it, then tap UNDO.
/// 7. Select a few rows, "Delete selected", then UNDO.
/// 8. Switch to "Cards" (form layout), then toggle dark mode.
class ShowcaseGridSheet extends StatefulWidget {
  const ShowcaseGridSheet({super.key});

  @override
  State<ShowcaseGridSheet> createState() => _ShowcaseGridSheetState();
}

const _order = ValueKey<String>('col_order');
const _customer = ValueKey<String>('col_customer');
const _region = ValueKey<String>('col_region');
const _product = ValueKey<String>('col_product');
const _status = ValueKey<String>('col_status');
const _date = ValueKey<String>('col_date');
const _qty = ValueKey<String>('col_qty');
const _price = ValueKey<String>('col_price');
const _total = ValueKey<String>('col_total');
const _paid = ValueKey<String>('col_paid');

class _ShowcaseGridSheetState extends State<ShowcaseGridSheet> {
  static const _rowCount = 120;

  final _gridKey = GlobalKey<GridSheetState>();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  late final List<GridSheetRow> _rows = _buildRows();
  late final List<GridSheetColumn> _columns = _buildColumns();

  bool _grouped = false;
  GridSheetViewMode _viewMode = GridSheetViewMode.table;
  int _nextOrder = _rowCount + 1;

  GridSheetManager? get _manager => _gridKey.currentState;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.canvas,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _header(context),
            _toolbar(context),
            Expanded(
              child: _grid(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header & toolbar ────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      spacing: 8,
      children: [
        Icon(Icons.grid_on_rounded, color: colors.primary, size: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GridSheet', style: TextTypography.pageTitle),
              Text(
                '${_formatInt(_rowCount)} orders · virtualized · editable · grouped',
                style: TextTypography.caption
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 240,
          height: 36,
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearchChanged,
            style: TextTypography.body,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'search orders…',
              hintStyle:
                  TextTypography.body.copyWith(color: colors.textSecondary),
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: ThemeBorders.roundedMd),
            ),
          ),
        ),
        IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode_outlined,
              size: 24),
          onPressed: () =>
              appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark,
        ),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          spacing: 8,
          children: [
            SegmentedButton<GridSheetViewMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: GridSheetViewMode.table,
                  icon: Icon(Icons.table_rows_outlined, size: 18),
                  label: Text('Table', style: TextTypography.body),
                ),
                ButtonSegment(
                  value: GridSheetViewMode.form,
                  icon: Icon(Icons.view_agenda_outlined, size: 18),
                  label: Text('Cards', style: TextTypography.body),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (value) =>
                  setState(() => _viewMode = value.single),
            ),
            FilterChip(
              showCheckmark: false,
              avatar: const Icon(Icons.account_tree_outlined, size: 18),
              label: const Text('Group by region', style: TextTypography.body),
              selected: _grouped,
              onSelected: (value) => setState(() => _grouped = value),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export CSV', style: TextTypography.body),
              onPressed: _exportCsv,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete selected', style: TextTypography.body),
              onPressed: _deleteSelected,
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add order', style: TextTypography.body),
              onPressed: _addOrder,
            ),
          ],
        ),
      ],
    );
  }

  Widget _grid(BuildContext context) {
    return GridSheet(
      key: _gridKey,
      columns: _columns,
      rows: _rows,
      styleConfiguration: styleConfig(context, colorEvenOdd: false),
      scrollConfiguration: scrollConfig(context),
      configuration: const GridSheetConfiguration(
        showColumnFilters: true,
        enableRowSelectionOnFirstColumnTap: true,
        enableMultiSelection: true,
        enableColumnReorder: true,
        enableUndoDelete: true,
      ),
      autoFillConfiguration:
          const GridSheetAutoFillConfiguration(enabled: true),
      formConfiguration: GridSheetFormConfiguration(
        viewMode: _viewMode,
        enableGridView: true,
        maxHeight: 240,
      ),
      rowExpansionConfiguration: GridSheetRowExpansionConfiguration(
        enabled: true,
        panelHeight: 220,
      ),
      rowSwipeConfiguration: GridSheetRowSwipeConfiguration(
        enabled: true,
        end: GridSheetRowSwipeSideConfiguration(
          revealExtent: 96,
          onFullSwipe: (event) => event.gridManager.rows.delete([event.rowKey]),
          revealBuilder: (context, details) => ColoredBox(
            color: context.colors.danger,
            child: const Center(
              child: Icon(Icons.delete_outline, color: Colors.white),
            ),
          ),
        ),
      ),
      groupingConfiguration: GridSheetGroupingConfiguration(
        enabled: _grouped,
        rows: const GridSheetRowGroupingConfiguration(
          groupBy: [GridSheetRowGroupDescriptor(columnKey: _region)],
          aggregates: [
            GridSheetAggregateSpec.sum(_qty, label: 'Qty'),
            GridSheetAggregateSpec.average(_price, label: 'Avg'),
            GridSheetAggregateSpec.sum(_total, label: 'Total'),
          ],
          showGrandTotal: true,
          labelColumnSpan: 2,
        ),
      ),
      conditionalFormatRules: _formatRules(context),
      cellBuilder: _buildCell,
    );
  }

  /// Soft, theme-aware highlights: faint tints instead of saturated fills,
  /// with a separate palette for dark mode so contrast stays comfortable.
  List<GridSheetConditionalFormatRule> _formatRules(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Cancelled orders: barely-there rose tint, muted slate text.
    final cancelledBg = dark ? '#2A1D21' : '#FCF5F5';
    final cancelledFg =
        dark ? const Color(0xFF8B93A1) : const Color(0xFF8A94A6);

    // High-value orders: gentle mint tint, deep green (light) / bright green (dark).
    final highBg = dark ? '#163222' : '#EDF8F1';
    final highFg = dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    return [
      GridSheetConditionalFormatRule(
        name: 'CancelledRow',
        scope: GridSheetFormatScope.row,
        expression: 'STATUS == "Cancelled" ? "$cancelledBg" : null',
        textStyle: TextStyle(color: cancelledFg),
      ),
      GridSheetConditionalFormatRule(
        name: 'TOTAL',
        scope: GridSheetFormatScope.cell,
        expression: 'TOTAL >= 5000 ? "$highBg" : null',
        textStyle: TextStyle(color: highFg, fontWeight: FontWeight.w600),
      ),
    ];
  }

  /// STATUS as a colored chip and TOTAL as currency; every other cell keeps
  /// the built-in (editable) rendering.
  Widget? _buildCell(GridSheetCellContext cell) {
    final row = cell.row;
    if (cell.kind != GridSheetCellKind.row || row == null) return null;
    final value = row.data[cell.column.index];
    if (cell.column.key == _status) {
      final colors = cell.context.colors;
      final (Color fg, Color bg) = switch (value) {
        'Delivered' => (colors.success, colors.successSubtleBg),
        'Shipped' => (colors.info, colors.infoSubtleBg),
        'Pending' => (colors.warning, colors.warningSubtleBg),
        _ => (colors.danger, colors.dangerSubtleBg),
      };
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: ThemeBorders.roundedMd,
          ),
          child:
              Text('$value', style: TextTypography.label.copyWith(color: fg)),
        ),
      );
    }
    if (cell.column.key == _total && value is num) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '\$${_formatMoney(value)}',
            style: cell.textStyle,
          ),
        ),
      );
    }
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      final manager = _manager;
      if (manager == null) return;
      text.trim().isEmpty
          ? manager.search.clear()
          : manager.search.apply([text.trim()]);
    });
  }

  Future<void> _addOrder() async {
    final manager = _manager;
    if (manager == null) return;
    final number = _nextOrder++;
    await manager.rows.insertAt(
      manager.rows.count > 0 ? manager.rows.at(0).key : null,
      [
        GridSheetRow(
          key: ValueKey('order_$number'),
          index: manager.rows.count,
          data: [
            'SO-$number',
            'New customer',
            'Europe',
            'Standing Desk',
            'Pending',
            DateTime.now().toIso8601String().substring(0, 10),
            1,
            649.0,
            649.0,
            false,
          ],
        ),
      ],
    );
    _snack('Added SO-$number at the top.');
  }

  Future<void> _deleteSelected() async {
    final manager = _manager;
    if (manager == null) return;
    final keys = manager.selection.rowKeys;
    if (keys.isEmpty) {
      _snack('Select rows first — tap the row numbers.');
      return;
    }
    await manager.rows.delete(List.of(keys));
  }

  void _exportCsv() {
    final manager = _manager;
    if (manager == null) return;
    final lines = manager.data.toCsv().split('\n').length - 1;
    _snack('Exported ${_formatInt(lines)} rows to CSV.');
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        width: 360,
      ));
  }

  // ── Data ────────────────────────────────────────────────────────────────

  List<GridSheetColumn> _buildColumns() {
    const specs = [
      (_order, 'ORDER', 'Order', GridSheetColumnType.text(), 150.0),
      (_customer, 'CUSTOMER', 'Customer', GridSheetColumnType.text(), 180.0),
      (_region, 'REGION', 'Region', GridSheetColumnType.text(), 140.0),
      (_product, 'PRODUCT', 'Product', GridSheetColumnType.text(), 180.0),
      (_status, 'STATUS', 'Status', GridSheetColumnType.text(), 130.0),
      (_qty, 'QTY', 'Qty', GridSheetColumnType.integer(), 90.0),
      (_price, 'UNIT_PRICE', 'Unit Price', GridSheetColumnType.double(), 120.0),
      (_total, 'TOTAL', 'Total', GridSheetColumnType.double(), 150.0),
      (_date, 'ORDER_DATE', 'Order Date', GridSheetColumnType.text(), 120.0),
      (_paid, 'PAID', 'Paid', GridSheetColumnType.boolean(), 80.0),
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
          sortable: true,
          resizable: true,
          pinnedLeft: key == _order,
          pinnedRight: key == _paid,
          // ORDER identifies the row; TOTAL is QTY × UNIT_PRICE.
          editable: key != _order && key != _total,
          textAlign: type.kind == GridSheetColumnKind.integer ||
                  type.kind == GridSheetColumnKind.double
              ? TextAlign.right
              : TextAlign.left,
          hasTextController: key != _status && key != _total,
          filterHint: 'Filter…',
        ),
    ];
  }

  List<GridSheetRow> _buildRows() {
    const customers = [
      'Acme Corp', 'Globex', 'Initech', 'Umbrella', 'Stark Industries', //
      'Wayne Enterprises', 'Hooli', 'Vandelay', 'Soylent', 'Wonka Ltd',
      'Cyberdyne', 'Tyrell Corp', 'Pied Piper', 'Aperture', 'Oscorp',
    ];
    const regions = [
      'Europe',
      'North America',
      'Asia Pacific',
      'Latin America'
    ];
    const products = [
      ('Mechanical Keyboard', 89.0), ('4K Monitor', 349.0), //
      ('USB-C Dock', 159.0), ('Standing Desk', 649.0),
      ('Noise-Cancelling Headset', 229.0), ('Webcam Pro', 119.0),
      ('Ergonomic Chair', 499.0), ('Laptop Stand', 49.0),
    ];
    const statuses = ['Delivered', 'Shipped', 'Pending', 'Cancelled'];
    final random = Random(7);
    final start = DateTime(2025, 1, 1);
    return [
      for (var i = 0; i < _rowCount; i++)
        () {
          final (product, price) = products[random.nextInt(products.length)];
          final qty = 1 + random.nextInt(25);
          final status = statuses[random.nextInt(10) < 6
              ? random.nextInt(2)
              : 2 + random.nextInt(2)];
          final date = start.add(Duration(days: random.nextInt(540)));
          return GridSheetRow(
            key: ValueKey('order_${i + 1}'),
            index: i,
            data: [
              'SO-${(i + 1).toString().padLeft(5, '0')}',
              customers[random.nextInt(customers.length)],
              regions[random.nextInt(regions.length)],
              product,
              status,
              qty,
              price,
              qty * price,
              date.toIso8601String().substring(0, 10),
              status == 'Delivered' || random.nextBool(),
            ],
          );
        }(),
    ];
  }

  static String _formatInt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  static String _formatMoney(num n) {
    final fixed = n.toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    return '${_formatInt(int.parse(fixed.substring(0, dot)))}${fixed.substring(dot)}';
  }
}
