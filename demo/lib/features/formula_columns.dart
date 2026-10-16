import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class FormulaColumn extends StatefulWidget {
  const FormulaColumn({super.key});

  @override
  State<FormulaColumn> createState() => _FormulaColumnState();
}

class _FormulaColumnState extends State<FormulaColumn> {
  late GridSheetManager gridManager;

  /// Resolves a column name to its key — the manager's column methods are
  /// key-addressed.
  ValueKey<String> _columnKey(String name) =>
      gridManager.columns.findByNames([name]).single.key;

  final ValueNotifier<String> status = ValueNotifier(
    'Edit a quantity or unit price — the TOTAL formula column recalculates automatically. '
    'Select a row and try "Insert Row" or drag-reorder (serial-number cell) to see whether '
    'RUNNING_TOTAL/MINIMUM keep summing the right range afterward.',
  );
  int _newRowCount = 0;
  bool _insertAboveSelection = false;

  GridSheetRowInsertPosition get _insertPosition => _insertAboveSelection
      ? GridSheetRowInsertPosition.above
      : GridSheetRowInsertPosition.below;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Formula Columns',
      description:
          'GridSheetColumnType.formula() supports Excel-style expressions such as =B1 * C1 or =SUM(D1:D5). '
          'Dependent cells re-evaluate automatically whenever a referenced source cell changes.',
      icon: Icons.functions_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Insert Row',
            icon: Icons.add,
            color: context.accents.green,
            onPressed: _insertRow,
            tooltip: 'Insert a blank row and watch the range formulas after it',
          ),
          DemoToggleButton(
            label: 'Above Selection',
            icon: Icons.vertical_align_top,
            color: context.accents.indigo,
            value: _insertAboveSelection,
            onChanged: _toggleInsertPosition,
            tooltip: 'Insert the new row above (vs. below) the selection',
          ),
          DemoActionButton(
            label: 'Filter TOTAL =',
            icon: Icons.filter_alt_outlined,
            color: context.accents.blue,
            onPressed: _filterByFormulaResult,
            tooltip: 'Show only rows where the TOTAL formula equals a value',
          ),
          DemoActionButton(
            label: 'Clear Filters',
            icon: Icons.filter_alt_off_outlined,
            color: context.accents.neutral,
            onPressed: _clearFilters,
            tooltip: 'Remove every active filter',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: GridSheetConfiguration(
          enableCellSelection: true,
          showColumnFilters: true,
          enableRowSelectionOnFirstColumnTap: true,
          enableRowReorder: true,
          rowInsertPosition: _insertPosition,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue} (dependent formulas updated)';
        },
        onRowReorder: (event) {
          status.value =
              'onRowReorder: index ${event.fromIndex} → ${event.toIndex} — check RUNNING_TOTAL/MINIMUM below: '
              'still the correct SUM(D1:D_n)/MIN(B1:B_n) range, or now off by one row?';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = [
      'ITEM',
      'QTY',
      'UNIT_PRICE',
      'TOTAL',
      'RUNNING_TOTAL',
      'MINIMUM',
    ];
    const titles = [
      'Item',
      'Qty',
      'Unit Price',
      'Total (formula)',
      'Running Sum (formula)',
      'Minimum Qty (formula)',
    ];
    const descriptions = [
      null,
      null,
      null,
      '=QTY * UNIT_PRICE — recalculates whenever either input cell changes',
      '=SUM(D1:D_n) — an aggregate formula referencing a cell range',
      '=MIN(D1:D_n) — an aggregate formula referencing a cell range',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.double(),
      GridSheetColumnType.formula(),
      GridSheetColumnType.formula(),
      GridSheetColumnType.formula(),
    ];
    const widths = [120.0, 90.0, 100.0, 150.0, 190.0, 180.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_${i + 1}'),
        index: i,
        name: names[i],
        title: titles[i],
        description: descriptions[i],
        type: types[i],
        width: widths[i],
        editable: i != 5,
        textAlign: types[i].kind == GridSheetColumnKind.text
            ? TextAlign.left
            : TextAlign.right,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Keyboard', 4, 65.0, '=B1 * C1', '=SUM(D1:D1)', '=MIN(B1:B1)'],
      ['Monitor', 2, 210.0, '=B2 * C2', '=SUM(D1:D2)', '=MIN(B1:B2)'],
      ['Webcam', 6, 45.5, '=B3 * C3', '=SUM(D1:D3)', '=MIN(B1:B3)'],
      ['Desk Mat', 10, 12.75, '=B4 * C4', '=SUM(D1:D4)', '=MIN(B1:B4)'],
      ['Dock Station', 3, 89.0, '=B5 * C5', '=SUM(D1:D5)', '=MIN(B1:B5)'],
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

  Future<void> _filterByFormulaResult() async {
    final value =
        await showDemoInputDialog(context, 'Show rows where TOTAL equals');
    if (value == null || value.isEmpty) return;
    final numeric = double.tryParse(value);
    await gridManager.filters.add(
      {
        _columnKey('TOTAL'): [numeric ?? value]
      },
      comparison: GridSheetFilterComparison.exact,
    );
    status.value =
        'addFilters(): filtered TOTAL == $value (works on computed formula values)';
  }

  Future<void> _clearFilters() async {
    await gridManager.filters.clearAll();
    status.value = 'clearFilters(): showing every row again';
  }

  void _toggleInsertPosition(bool value) {
    setState(() => _insertAboveSelection = value);
    status.value = 'rowInsertPosition: ${value ? "above" : "below"}';
  }

  Future<void> _insertRow() async {
    _newRowCount++;
    // Deliberately no TOTAL/RUNNING_TOTAL/MINIMUM formula on the new row —
    // its final physical position depends on which row was selected, so any
    // literal =B_n*C_n string authored here could easily point at the wrong
    // row. The point of this button is to watch the *existing* formula rows
    // around it (their =SUM(D1:D_n)/=MIN(B1:B_n) strings were written before
    // this insert happened) and see whether they still resolve correctly.
    final row = GridSheetRow(
      key: ValueKey('row_new_$_newRowCount'),
      index: gridManager.rows.count,
      data: ['New Item $_newRowCount', 1, 0.0, null, null, null],
      state: GridSheetRowState.inserted,
      height: Constants.rowHeight,
    );
    await gridManager.rows.insert([row]);
    status.value =
        'insertRows(): added a blank row (no formula) — now check RUNNING_TOTAL/MINIMUM on the '
        'rows after it: still summing the original range, or off by one?';
  }
}
