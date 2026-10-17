import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Showcases pinning ("freezing") rows to a non-scrolling band above or
/// below the grid so they stay visible while the rest of the rows scroll
/// vertically underneath — the row-axis counterpart to [FrozenColumns] via
/// `GridSheetColumn.pinnedLeft`/`pinnedRight`.
///
/// Demonstrates both declarative pinning
/// (`GridSheetRow(pinnedTop: true)`/`pinnedBottom: true` at construction —
/// used here for a running "TOTALS" summary row pinned to the bottom) and
/// programmatic pinning via `GridSheetManager.rows.pinTo(topCount,
/// bottomCount)` (resolves keys for you from whatever's currently
/// first/last in the scrollable section), and `rows.pin` (pin
/// specific, already-known rows — here, whatever the user has selected).
/// `rows.unpin`/`rows.unpinAll` reverse it; `rows.pinnedTop`/`rows.pinnedBottom`
/// surface the actual pinned `GridSheetRow` objects, shown in the status
/// line after every pin call (map them with `.key` if you just
/// need their keys). Also demonstrates `GridSheetConfiguration.selectionIncludesPinnedTopCells`/
/// `selectionIncludesPinnedBottomCells` (try selecting a column with column
/// selection enabled) and `GridSheetStyleConfiguration.pinnedTopDividerColor`/
/// `pinnedBottomDividerColor`/`pinnedRowsDividerWidth` — the row-axis mirror
/// of the pinned-column dividers on the Pinned Columns demo page.
///
/// Also demonstrates the pinned-row features shipped since: `rows.hide`/
/// `rows.show` on the TOTALS row by key,
/// `rows.insertAt(band: .top/.bottom)`
/// (inserting straight into a band instead of the scrollable section),
/// `enableReorderOnPinnedTopRows`/`enableReorderOnPinnedBottomRows`
/// (drag-to-reorder within a band), `GridSheetAutoFillConfiguration
/// .enableOnPinnedTopRows`/`enableOnPinnedBottomRows` (the autofill
/// fill-handle drag, scoped to a single band), and
/// `GridSheetRowExpansionConfiguration.enabled` (the expand/collapse chevron
/// works on a pinned row exactly as it already does on a scrollable one —
/// unlike reorder/autofill, this needs no dedicated pinned-row opt-in flag,
/// since the toggle is entirely funneled through `cellBuilder`/
/// `GridSheetCellContext.onToggleRowExpansion`, which a host can already
/// gate on `row.pinnedTop`/`pinnedBottom` itself if it wants pinned rows
/// excluded). Surfaces the remaining documented v1 limitations:
/// pinned rows are excluded from keyboard navigation and the formula
/// engine.
class FixedRows extends StatefulWidget {
  const FixedRows({super.key});

  @override
  State<FixedRows> createState() => _FixedRowsState();
}

class _FixedRowsState extends State<FixedRows> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier('');
  bool _selectionIncludesPinnedTopCells = false;
  bool _selectionIncludesPinnedBottomCells = false;
  bool _showTopDivider = false;
  bool _showBottomDivider = false;
  bool _totalsRowHidden = false;
  bool _enableReorderPinned = false;
  bool _autofillOnPinned = false;
  bool _rowExpansionEnabled = false;
  int _insertedRowCounter = 0;

  static const _cyclableDividerWidths = [2.0, 6.0, 12.0];
  double _dividerWidth = _cyclableDividerWidths[0];

  static const _simulatedPinLatency = Duration(milliseconds: 400);

  // Shows the loading indicator for a simulated server round trip, then runs
  // [action]. Every loading.start() is paired with a loading.stop(): loads
  // are counted, so the indicator stays until each one is stopped.
  Future<T?> _withSimulatedLatency<T>(Future<T> Function() action) async {
    gridManager.loading.start();
    try {
      await Future.delayed(_simulatedPinLatency);
      if (!mounted) return null;
      return await action();
    } finally {
      if (mounted) gridManager.loading.stop();
    }
  }

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Fixed Rows',
      icon: Icons.vertical_align_center_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Pin First 2',
            icon: Icons.arrow_upward_outlined,
            color: context.accents.indigo,
            onPressed: () => _pinFirst(2),
            tooltip: 'rows.pinTo(2, 0) — resolves the current first 2 '
                'scrollable rows\' keys for you',
          ),
          DemoActionButton(
            label: 'Pin Last 2',
            icon: Icons.arrow_downward_outlined,
            color: context.accents.indigo,
            onPressed: () => _pinLast(2),
            tooltip: 'rows.pinTo(0, 2)',
          ),
          DemoToggleButton(
            label: 'Top Divider',
            icon: Icons.border_top_outlined,
            color: context.accents.indigo,
            value: _showTopDivider,
            onChanged: _toggleShowTopDivider,
            tooltip: 'GridSheetStyleConfiguration.pinnedTopDividerColor — '
                'divider at the pinned-top/scrollable boundary',
          ),
          DemoToggleButton(
            label: 'Bottom Divider',
            icon: Icons.border_bottom_outlined,
            color: context.accents.pink,
            value: _showBottomDivider,
            onChanged: _toggleShowBottomDivider,
            tooltip: 'GridSheetStyleConfiguration.pinnedBottomDividerColor '
                '— divider at the scrollable/pinned-bottom boundary, styled '
                'independently of the top one',
          ),
          DemoActionButton(
            label: 'Divider: ${_dividerWidth.toInt()}px',
            icon: Icons.line_weight_outlined,
            color: context.accents.teal,
            onPressed: _cycleDividerWidth,
            tooltip:
                'Cycle GridSheetStyleConfiguration.pinnedRowsDividerWidth — '
                'shared by both dividers, reserves real height rather than '
                'overlaying either band\'s cells',
          ),
          DemoActionButton(
            label: 'Pin Selected',
            icon: Icons.push_pin_outlined,
            color: context.accents.teal,
            onPressed: _pinSelected,
            tooltip: 'rows.pin(topKeys: selectedRowKeys) — pin specific, '
                'already-known rows (select some rows first)',
          ),
          DemoActionButton(
            label: 'Insert Top Row',
            icon: Icons.playlist_add_outlined,
            color: context.accents.green,
            onPressed: _insertIntoTopBand,
            tooltip: 'rows.insertAt(band: .top) — inserts a new row '
                'directly into the pinned-top band, before a given key',
          ),
          DemoActionButton(
            label: 'Insert Bottom Row',
            icon: Icons.playlist_add_outlined,
            color: context.accents.green,
            onPressed: _insertIntoBottomBand,
            tooltip: 'rows.insertAt(band: .bottom) — inserts '
                'before TOTALS in the pinned-bottom band',
          ),
          DemoActionButton(
            label: 'Clear Pins',
            icon: Icons.push_pin_outlined,
            color: context.accents.red,
            onPressed: _clearPins,
            tooltip: 'rows.unpinAll() — the declaratively-pinned TOTALS row '
                'unpins too',
          ),
          DemoToggleButton(
            label: 'Top Selection',
            icon: Icons.highlight_alt_outlined,
            color: context.accents.deepPurple,
            value: _selectionIncludesPinnedTopCells,
            onChanged: _toggleSelectionIncludesPinnedTop,
            tooltip: 'selectionIncludesPinnedTopCells — include the '
                'pinned-top row when a column is selected (try clicking a '
                'column header)',
          ),
          DemoToggleButton(
            label: 'Bottom Selection',
            icon: Icons.highlight_alt_outlined,
            color: context.accents.deepPurple,
            value: _selectionIncludesPinnedBottomCells,
            onChanged: _toggleSelectionIncludesPinnedBottom,
            tooltip: 'selectionIncludesPinnedBottomCells — include the '
                'pinned-bottom TOTALS row when a column is selected',
          ),
          DemoToggleButton(
            label: 'Hide Totals',
            icon: Icons.visibility_off_outlined,
            color: context.accents.brown,
            value: _totalsRowHidden,
            onChanged: _toggleHideTotals,
            tooltip: 'rows.hide/rows.show([row_totals]) — a pinned row can '
                'be hidden too; it stays pinned (rows.pinnedBottom still '
                'reports it), just not rendered',
          ),
          DemoToggleButton(
            label: 'Reorder Pinned',
            icon: Icons.swap_vert_outlined,
            color: context.accents.blue,
            value: _enableReorderPinned,
            onChanged: _toggleReorderPinned,
            tooltip: 'enableReorderOnPinnedTopRows/BottomRows — drag a '
                'pinned row onto another row in the same band to reorder '
                'it; dragging across a band boundary is always rejected',
          ),
          DemoToggleButton(
            label: 'Autofill Pinned',
            icon: Icons.gesture_outlined,
            color: context.accents.orange,
            value: _autofillOnPinned,
            onChanged: _toggleAutofillPinned,
            tooltip: 'autoFillConfiguration.enableOnPinnedTopRows/'
                'BottomRows — select a pinned row\'s cell and drag its fill '
                'handle within its own band',
          ),
          DemoToggleButton(
            label: 'Row Expansion',
            icon: Icons.unfold_more_outlined,
            color: context.accents.purple,
            value: _rowExpansionEnabled,
            onChanged: _toggleRowExpansion,
            tooltip: 'rowExpansionConfiguration.enabled — tap the chevron '
                "next to a pinned row's number to expand it inline",
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _initialRows(),
        configuration: GridSheetConfiguration(
          enableRowSelectionOnFirstColumnTap: true,
          enableColumnSelection: true,
          enableMultiSelection: true,
          enableCellNavigation: true,
          enableCellSelection: true,
          showColumnFilters: true,
          rowsPerPage: 8,
          selectionIncludesPinnedTopCells: _selectionIncludesPinnedTopCells,
          selectionIncludesPinnedBottomCells:
              _selectionIncludesPinnedBottomCells,
          enableReorderOnPinnedTopRows: _enableReorderPinned,
          enableReorderOnPinnedBottomRows: _enableReorderPinned,
        ),
        styleConfiguration: styleConfig(context).copyWith(
          pinnedTopDividerColor:
              _showTopDivider ? context.accents.indigo : null,
          pinnedBottomDividerColor:
              _showBottomDivider ? context.accents.pink : null,
          pinnedRowsDividerWidth: _dividerWidth,
        ),
        autoFillConfiguration: GridSheetAutoFillConfiguration(
          // Always on for the scrollable rows; the toggle adds the pinned bands.
          enabled: true,
          enableOnPinnedTopRows: _autofillOnPinned,
          enableOnPinnedBottomRows: _autofillOnPinned,
        ),
        rowExpansionConfiguration: GridSheetRowExpansionConfiguration(
          enabled: _rowExpansionEnabled,
        ),
        scrollConfiguration: scrollConfig(context),
        loadingIndicator: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        onLoaded: (event) => gridManager = event.gridManager,
        onRowsSelected: (event) {
          status.value = 'Selected rows: ${event.keys.length}';
        },
        onColumnsSelected: (event) {
          status.value = 'Selected column: ${event.names.join(", ")}';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['PRODUCT', 'CATEGORY', 'QTY', 'UNIT_PRICE', 'REVENUE'];
    const titles = ['Product', 'Category', 'Qty', 'Unit Price', 'Revenue'];
    const widths = [190.0, 150.0, 90.0, 120.0, 130.0];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.double(),
      GridSheetColumnType.double(),
    ];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        sortable: true,
        resizable: true,
        textAlign: types[i].kind == GridSheetColumnKind.text
            ? TextAlign.left
            : TextAlign.right,
      );
    });
  }

  List<GridSheetRow> _initialRows() {
    final raw = <List<dynamic>>[
      ['Wireless Mouse', 'Accessories', 240, 19.99, 4797.60],
      ['Mechanical Keyboard', 'Accessories', 130, 79.99, 10398.70],
      ['27" Monitor', 'Displays', 65, 219.00, 14235.00],
      ['USB-C Hub', 'Accessories', 310, 24.50, 7595.00],
      ['Webcam 1080p', 'Accessories', 180, 34.99, 6298.20],
      ['Laptop Stand', 'Accessories', 210, 29.00, 6090.00],
      ['Noise-Cancelling Headset', 'Audio', 95, 89.00, 8455.00],
      ['Desk Lamp', 'Office', 150, 22.75, 3412.50],
      ['Ergonomic Chair', 'Office', 40, 249.00, 9960.00],
      ['Standing Desk', 'Office', 25, 399.00, 9975.00],
      ['External SSD 1TB', 'Storage', 88, 109.00, 9592.00],
      ['Portable Charger', 'Accessories', 260, 27.99, 7277.40],
      ['34" Ultrawide Monitor', 'Displays', 22, 449.00, 9878.00],
      ['Docking Station', 'Accessories', 70, 159.00, 11130.00],
      ['Bluetooth Speaker', 'Audio', 140, 45.00, 6300.00],
    ];
    final rows = raw.asMap().entries.map((e) {
      return GridSheetRow(
        key: ValueKey('row_${e.key}'),
        index: e.key,
        data: e.value,
        height: Constants.rowHeight,
      );
    }).toList();

    final totalRevenue =
        raw.fold<double>(0, (sum, r) => sum + (r.last as double));
    // Pinned declaratively, right from construction — a running summary
    // row that should always stay visible regardless of how far the user
    // scrolls. Note it's excluded from the formula engine in v1, so REVENUE
    // here is a plain precomputed value, not a live `=SUM(...)` formula.
    rows.add(
      GridSheetRow(
        key: const ValueKey('row_totals'),
        index: raw.length,
        data: ['TOTALS', '', '', '', totalRevenue],
        height: Constants.rowHeight,
        pinnedBottom: true,
      ),
    );
    return rows;
  }

  Future<void> _pinFirst(int count) async {
    final error =
        await _withSimulatedLatency(() => gridManager.rows.pinTo(count, 0));
    if (!mounted) return;
    _reportPinResult('rows.pinTo($count, 0)', error);
  }

  Future<void> _pinLast(int count) async {
    final error =
        await _withSimulatedLatency(() => gridManager.rows.pinTo(0, count));
    if (!mounted) return;
    _reportPinResult('rows.pinTo(0, $count)', error);
  }

  Future<void> _pinSelected() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      status.value = 'Select one or more rows first.';
      return;
    }
    final error =
        await _withSimulatedLatency(() => gridManager.rows.pin(topKeys: keys));
    if (!mounted) return;
    _reportPinResult('rows.pin(topKeys: ${keys.length} row(s))', error);
  }

  Future<void> _clearPins() async {
    await _withSimulatedLatency(gridManager.rows.unpinAll);
    if (!mounted) return;
    _reportPinnedRowData('rows.unpinAll()');
  }

  void _reportPinResult(String call, String? error) {
    if (error != null) {
      status.value = '$call failed: $error';
      return;
    }
    _reportPinnedRowData(call);
  }

  // Reads the actual pinned GridSheetRow objects via rows.pinnedTop/
  // rows.pinnedBottom and shows their PRODUCT names, proving these getters
  // hand back real row data rather than requiring a manual findRow lookup
  // per key.
  void _reportPinnedRowData(String call) {
    final topNames =
        gridManager.rows.pinnedTop.map((r) => r.data.first).join(', ');
    final bottomNames =
        gridManager.rows.pinnedBottom.map((r) => r.data.first).join(', ');
    status.value = '$call → top: [$topNames], bottom: [$bottomNames]';
  }

  void _toggleSelectionIncludesPinnedTop(bool value) {
    setState(() => _selectionIncludesPinnedTopCells = value);
    status.value = 'selectionIncludesPinnedTopCells: $value';
  }

  void _toggleSelectionIncludesPinnedBottom(bool value) {
    setState(() => _selectionIncludesPinnedBottomCells = value);
    status.value = 'selectionIncludesPinnedBottomCells: $value';
  }

  void _toggleShowTopDivider(bool value) {
    setState(() => _showTopDivider = value);
    status.value = 'pinnedTopDividerColor: ${value ? 'indigo' : 'null'}';
  }

  void _toggleShowBottomDivider(bool value) {
    setState(() => _showBottomDivider = value);
    status.value = 'pinnedBottomDividerColor: ${value ? 'pink' : 'null'}';
  }

  void _cycleDividerWidth() {
    final next = (_cyclableDividerWidths.indexOf(_dividerWidth) + 1) %
        _cyclableDividerWidths.length;
    setState(() => _dividerWidth = _cyclableDividerWidths[next]);
    status.value = 'pinnedRowsDividerWidth: ${_dividerWidth.toInt()}px';
  }

  Future<void> _toggleHideTotals(bool hide) async {
    const totalsKey = ValueKey('row_totals');
    if (hide) {
      await gridManager.rows.hide(const [totalsKey]);
    } else {
      await gridManager.rows.show(const [totalsKey]);
    }
    if (!mounted) return;
    setState(() => _totalsRowHidden = hide);
    status.value = hide
        ? 'rows.hide([row_totals]) — still pinned '
            '(rows.pinnedBottom still reports it), just not rendered'
        : 'rows.show([row_totals])';
  }

  // A fresh row for the two "insert into band" demo buttons — the column
  // count matches _columns() (PRODUCT/CATEGORY/QTY/UNIT_PRICE/REVENUE).
  // pinnedTop/pinnedBottom are left unset: rows.insertAt's band:
  // param forces them to match the target band regardless of what's
  // passed in.
  GridSheetRow _newDemoRow(String label) {
    final n = ++_insertedRowCounter;
    return GridSheetRow(
      key: ValueKey('inserted_row_$n'),
      index: 0,
      data: ['$label $n', 'Inserted', 1, 0.0, 0.0],
      height: Constants.rowHeight,
    );
  }

  Future<void> _insertIntoTopBand() async {
    // null appends to the end of the pinned-top band.
    await gridManager.rows.insertAt(null, [_newDemoRow('New Top Item')],
        band: GridSheetRowBand.top);
    if (!mounted) return;
    status.value = 'rows.insertAt(null, ..., band: .top) → top band now has '
        '${gridManager.rows.pinnedTop.length} row(s)';
  }

  Future<void> _insertIntoBottomBand() async {
    // Puts the new row before whatever's currently first in the
    // pinned-bottom band — here, that's the declaratively-pinned TOTALS row.
    final firstBottom = gridManager.rows.pinnedBottom.isNotEmpty
        ? gridManager.rows.pinnedBottom.first.key
        : null;
    await gridManager.rows.insertAt(
        firstBottom, [_newDemoRow('New Bottom Item')],
        band: GridSheetRowBand.bottom);
    if (!mounted) return;
    status.value = 'rows.insertAt($firstBottom, ..., band: .bottom) → bottom '
        'band now has ${gridManager.rows.pinnedBottom.length} row(s)';
  }

  void _toggleReorderPinned(bool value) {
    setState(() => _enableReorderPinned = value);
    status.value =
        'enableReorderOnPinnedTopRows/BottomRows: $value — drag a pinned '
        "row onto another row in the same band; it won't cross bands";
  }

  void _toggleAutofillPinned(bool value) {
    setState(() => _autofillOnPinned = value);
    status.value = 'autoFillConfiguration.enableOnPinnedTopRows/'
        'BottomRows: $value — select a pinned cell, then drag its fill '
        'handle within its own band (scrollable rows always autofill)';
  }

  void _toggleRowExpansion(bool value) {
    setState(() => _rowExpansionEnabled = value);
    status.value = 'rowExpansionConfiguration.enabled: $value — tap the '
        "chevron next to a row's number to expand it, pinned or not";
  }
}
