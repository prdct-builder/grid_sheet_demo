import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class ConditionalEdit extends StatefulWidget {
  const ConditionalEdit({super.key});

  @override
  State<ConditionalEdit> createState() => _ConditionalEditState();
}

class _ConditionalEditState extends State<ConditionalEdit> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'DISCOUNT is only editable when STATUS is "Approved" — try editing a Pending or Rejected row.',
  );

  static const _rowKeys = [
    ValueKey('row_0'),
    ValueKey('row_1'),
    ValueKey('row_2'),
    ValueKey('row_3'),
    ValueKey('row_4'),
  ];
  static const _statusColumnKey = ValueKey('col_2');
  static const _resetStatuses = [
    'Approved',
    'Pending',
    'Rejected',
    'Approved',
    'Pending',
  ];

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Conditional Cell Editability',
      icon: Icons.rule_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Approve All',
            icon: Icons.check_circle_outline,
            color: context.accents.green,
            onPressed: () => _setAllStatus('Approved'),
            tooltip: 'Set every row\'s STATUS to Approved, unlocking DISCOUNT',
          ),
          DemoActionButton(
            label: 'Reject All',
            icon: Icons.cancel_outlined,
            color: context.accents.red,
            onPressed: () => _setAllStatus('Rejected'),
            tooltip: 'Set every row\'s STATUS to Rejected, locking NOTES',
          ),
          DemoActionButton(
            label: 'Reset',
            icon: Icons.restart_alt_outlined,
            color: context.accents.neutral,
            onPressed: _resetStatus,
            tooltip: 'Restore each row\'s original STATUS value',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(enableCellSelection: true),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['ORDER_ID', 'STATUS', 'AMOUNT', 'DISCOUNT', 'NOTES'];
    const titles = [
      'Order ID',
      'Status',
      'Amount',
      'Discount % (editable only when Approved)',
      'Notes (locked once Rejected)',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(
          options: ['Approved', 'Pending', 'Rejected']),
      GridSheetColumnType.double(),
      GridSheetColumnType.double(),
      GridSheetColumnType.text(),
    ];
    const widths = [120.0, 140.0, 120.0, 260.0, 220.0];
    const conditionalEditExpressions = [
      null,
      null,
      null,
      'STATUS == "Approved"',
      'STATUS != "Rejected"',
    ];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_${i + 1}'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        editable: i != 0,
        hasTextController: types[i].kind != GridSheetColumnKind.dropdown,
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : TextAlign.left,
        conditionalEditExpression: conditionalEditExpressions[i],
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['ORD-1001', 'Approved', 420.0, 5.0, 'Standard shipping'],
      ['ORD-1002', 'Pending', 128.5, 0.0, 'Awaiting manager review'],
      ['ORD-1003', 'Rejected', 76.0, 0.0, 'Duplicate order'],
      ['ORD-1004', 'Approved', 899.99, 10.0, 'Bulk order'],
      ['ORD-1005', 'Pending', 54.25, 0.0, 'Payment verification'],
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

  void _setAllStatus(String value) {
    gridManager.cells.updateAll([
      for (final rowKey in _rowKeys)
        GridSheetCellUpdate(
            rowKey: rowKey, columnKey: _statusColumnKey, value: value),
    ]);
    status.value =
        'STATUS set to "$value" on every row — watch DISCOUNT and NOTES follow the conditionalEditExpression.';
  }

  void _resetStatus() {
    gridManager.cells.updateAll([
      for (var i = 0; i < _rowKeys.length; i++)
        GridSheetCellUpdate(
            rowKey: _rowKeys[i],
            columnKey: _statusColumnKey,
            value: _resetStatuses[i]),
    ]);
    status.value = 'STATUS reset to the original per-row values.';
  }
}
