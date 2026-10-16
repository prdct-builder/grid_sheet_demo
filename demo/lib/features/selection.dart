import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class SelectionEvents extends StatefulWidget {
  const SelectionEvents({super.key});

  @override
  State<SelectionEvents> createState() => _SelectionEventsState();
}

class _SelectionEventsState extends State<SelectionEvents> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'onRowsSelected, onColumnsSelected and onCellsSelected fire live as you click rows, headers or cells. '
    'AGE is a hidden column by default.',
  );
  bool _showBorderOnSelection = true;
  bool _selectionIncludesFrozenCells = false;
  double _selectionBorderWidth = 2;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Selection Events',
      description:
          'onRowsSelected, onColumnsSelected and onCellsSelected fire live as you click rows, headers or cells. '
          'The status bar below the grid mirrors exactly what each callback receives.',
      icon: Icons.touch_app_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Border On Selection',
            icon: Icons.border_style,
            color: context.accents.indigo,
            value: _showBorderOnSelection,
            onChanged: (v) => setState(() => _showBorderOnSelection = v),
            tooltip: 'Draw a border around the current selection',
          ),
          DemoActionButton(
            label: 'Border Width: ${_selectionBorderWidth.toInt()}px',
            icon: Icons.line_weight,
            color: context.accents.purple,
            onPressed: () {
              setState(() {
                _selectionBorderWidth = _selectionBorderWidth == 2 ? 5 : 2;
              });
            },
            tooltip: 'Toggle the selection border\'s thickness',
          ),
          DemoToggleButton(
            label: 'Include Frozen (PLAYER)',
            icon: Icons.ac_unit,
            color: context.accents.blue,
            value: _selectionIncludesFrozenCells,
            onChanged: (v) => setState(() => _selectionIncludesFrozenCells = v),
            tooltip: 'Include the pinned PLAYER column in selection events',
          ),
          DemoActionButton(
            label: 'Rows Data',
            icon: Icons.table_rows_outlined,
            color: context.accents.teal,
            onPressed: _showSelectedRowsData,
            tooltip: 'Show the selected rows\' data (selectedRowsData)',
          ),
          DemoActionButton(
            label: 'Columns Data',
            icon: Icons.view_column_outlined,
            color: context.accents.teal,
            onPressed: _showSelectedColumnsData,
            tooltip: 'Show the selected columns\' data (selectedColumnsData)',
          ),
          DemoActionButton(
            label: 'Cells Data',
            icon: Icons.grid_on_outlined,
            color: context.accents.teal,
            onPressed: _showSelectedCellsData,
            tooltip: 'Show the selected cells\' data (selectedCellsData)',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        indexColumn: GridSheetColumn(
          key: const ValueKey('unused'),
          index: -1,
          name: 'unused',
          title: '',
          type: GridSheetColumnType.text(),
          width: 56,
        ),
        configuration: GridSheetConfiguration(
          enableRowSelectionOnFirstColumnTap: true,
          enableColumnSelection: true,
          enableCellSelection: true,
          enableMultiSelection: true,
          showBorderOnSelection: _showBorderOnSelection,
          selectionIncludesPinnedLeftCells: _selectionIncludesFrozenCells,
        ),
        styleConfiguration: styleConfig(context)
            .copyWith(selectionBorderWidth: _selectionBorderWidth),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
        onRowsSelected: (event) {
          status.value =
              'onRowsSelected: ${event.selectedRowKeys.length} row(s) selected';
        },
        onColumnsSelected: (event) {
          status.value =
              'onColumnsSelected: ${event.selectedColumnNames.length} column(s) selected';
        },
        onCellsSelected: (event) {
          status.value =
              'onCellsSelected: ${event.selectedCells.length} cell(s) selected';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['PLAYER', 'TEAM', 'POSITION', 'GOALS', 'AGE'];
    const titles = ['Player', 'Team', 'Position', 'Goals', 'Age'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.integer(),
    ];
    const widths = [
      140.0,
      100.0,
      120.0,
      80.0,
      80.0,
    ];

    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        sortable: true,
        width: widths[i],
        pinnedLeft: i == 0,
        visible: names[i] == 'AGE' ? false : true,
        textAlign: types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Amara Diallo', 'Falcons', 'Forward', 18, 24],
      ['Ravi Shankar', 'Tigers', 'Midfielder', 9, 27],
      ['Elena Petrova', 'Wolves', 'Defender', 3, 22],
      ['Carlos Mendez', 'Falcons', 'Forward', 21, 29],
      ['Sofia Bianchi', 'Tigers', 'Goalkeeper', 0, 31],
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

  void _showSelectedRowsData() {
    final selectedRows = gridManager.selection.rows;
    if (selectedRows.isEmpty) {
      showDemoSnackBar(context, 'Select one or more rows first');
      return;
    }
    final data = gridManager.selection.rowsData;
    showDemoDialog(context, 'SelectedRowsData', data.join('\n\n'));
  }

  void _showSelectedColumnsData() {
    final selectedColumns = gridManager.selection.columnsData();
    if (selectedColumns.isEmpty) {
      showDemoSnackBar(context, 'Select one or more columns first');
      return;
    }
    final data = gridManager.selection.columnsData();
    showDemoDialog(context, 'SelectedColumnsData', data.toString());
  }

  void _showSelectedCellsData() {
    final selectedCells = gridManager.selection.cells;
    if (selectedCells.isEmpty) {
      showDemoSnackBar(context, 'Select one or more cells first');
      return;
    }
    final data = gridManager.selection.cellsData;
    showDemoDialog(context, 'SelectedCellsData', data.toString());
  }
}
