import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/demo/constants.dart';

import '../demo/demo_helpers.dart';
import '../design_system/design_system.dart';

class Autofill extends StatefulWidget {
  const Autofill({super.key});

  @override
  State<Autofill> createState() => _AutofillState();
}

class _AutofillState extends State<Autofill> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'Select a cell, then drag the small blue handle at its corner to auto-fill neighbours.',
  );
  bool _circleHandle = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Autofill (Drag-to-Copy)',
      icon: Icons.auto_fix_high_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Fill Column',
            icon: Icons.south,
            color: context.accents.blue,
            onPressed: _runVerticalAutofillDemo,
            tooltip: 'Autofill Units Sold downward, continuing the pattern',
          ),
          DemoActionButton(
            label: 'Fill Row',
            icon: Icons.east,
            color: context.accents.teal,
            onPressed: _runHorizontalAutofillDemo,
            tooltip:
                'Autofill row 1 rightward from Units Sold: Target is filled, '
                'Growth % is skipped (different type)',
          ),
          DemoActionButton(
            label: _circleHandle ? 'Handle: Circle' : 'Handle: Square',
            icon: _circleHandle ? Icons.circle : Icons.crop_square,
            color: context.accents.purple,
            onPressed: () => setState(() => _circleHandle = !_circleHandle),
            tooltip: 'Switch the fill handle\'s shape',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(
          enableCellSelection: true,
          enableMultiSelection: true,
        ),
        autoFillConfiguration: GridSheetAutoFillConfiguration(
          enabled: true,
          fillHandleSize: 4,
          fillHandleColor: context.accents.blue,
          fillHandleShape: _circleHandle ? BoxShape.circle : BoxShape.rectangle,
          showPreviewOverlay: true,
          enablePatternDetection: true,
          enforceTypeMatching: true,
        ),
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
    const names = [
      'WEEK',
      'UNITS_SOLD',
      'TARGET',
      'GROWTH_PCT',
      'QUARTER_LABEL',
    ];
    const titles = [
      'Week',
      'Units Sold',
      'Target',
      'Growth %',
      'Quarter Label'
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.double(),
      GridSheetColumnType.text(),
    ];
    const widths = [120.0, 120.0, 120.0, 120.0, 120.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        textAlign: types[i].kind == GridSheetColumnKind.text
            ? TextAlign.left
            : TextAlign.right,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Week 1', 100, null, 1.5, 'Q1'],
      ['Week 2', null, null, null, null],
      ['Week 3', null, null, null, null],
      ['Week 4', null, null, null, null],
      ['Week 5', null, null, null, null],
      ['Week 6', null, null, null, null],
      ['Week 7', null, null, null, null],
      ['Week 8', null, null, null, null],
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

  Future<void> _runVerticalAutofillDemo() async {
    await gridManager.cells.autoFillVertical(
      startRowKey: const ValueKey('row_0'),
      endRowKey: const ValueKey('row_7'),
      columnKey: const ValueKey('col_1'),
      sourceValues: const [100, 118],
      enablePatternDetection: true,
    );
    status.value =
        'cells.autoFillVertical(): continued "Units Sold" 100 → 118 → … down the column';
  }

  Future<void> _runHorizontalAutofillDemo() async {
    await gridManager.cells.autoFillHorizontal(
      startRowKey: const ValueKey('row_0'),
      endRowKey: const ValueKey('row_0'),
      startColumnKey: const ValueKey('col_1'),
      endColumnKey: const ValueKey('col_3'),
      sourceValues: const [100],
      enablePatternDetection: true,
    );
    status.value =
        'cells.autoFillHorizontal(): copied 100 into Target on row 1; '
        'Growth % was skipped because enforceTypeMatching only fills columns of '
        "the source's type";
  }
}
