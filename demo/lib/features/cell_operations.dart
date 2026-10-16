import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class CellOperations extends StatefulWidget {
  const CellOperations({super.key});

  @override
  State<CellOperations> createState() => _CellOperationsState();
}

class _CellOperationsState extends State<CellOperations> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier('');
  List<GridSheetCell> _selectedCells = [];
  bool _enableCellNavigation = true;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Cell Operations',
      description:
          'Update, clear, fill and search individual cells with GridSheetManager. Select cells in the grid, '
          'then use the toolbar for bulk actions — mirrors clipboard-style copy/paste and find & replace.',
      icon: Icons.grid_on_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Fill Cells',
            icon: Icons.format_color_fill,
            color: context.accents.green,
            onPressed: _fillSelectedCells,
            tooltip: 'Set the selected cells to one value',
          ),
          DemoActionButton(
            label: 'Copy Selected',
            icon: Icons.content_copy,
            color: context.accents.purple,
            onPressed: _copySelectedCells,
            tooltip: 'Copy the selected cell values to the clipboard',
          ),
          DemoActionButton(
            label: 'Find Cells',
            icon: Icons.search,
            color: context.accents.blue,
            onPressed: _findCells,
            tooltip: 'Count cells whose value contains some text',
          ),
          DemoActionButton(
            label: 'Find & Replace',
            icon: Icons.find_replace,
            color: context.accents.orange,
            onPressed: _findAndReplace,
            tooltip: 'Replace every matching cell value grid-wide',
          ),
          DemoActionButton(
            label: 'Clear Cells',
            icon: Icons.clear_all,
            color: context.accents.red,
            onPressed: _clearSelectedCells,
            tooltip: 'Clear the value of every selected cell',
          ),
          DemoToggleButton(
            label: 'Cell Navigation',
            icon: Icons.keyboard_alt_outlined,
            color: context.accents.deepPurple,
            value: _enableCellNavigation,
            onChanged: _toggleCellNavigation,
            tooltip: 'Toggle moving between cells with arrow keys/tab',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: GridSheetConfiguration(
          enableCellSelection: true,
          enableMultiSelection: true,
          enableCellNavigation: _enableCellNavigation,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
        onCellsSelected: (event) {
          _selectedCells = event.selectedCells;
          status.value = 'Selected ${event.selectedCells.length} cell(s)';
        },
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['CITY', 'COUNTRY', 'POPULATION_M', 'IS_CAPITAL'];
    const titles = ['City', 'Country', 'Population (M)', 'Capital?'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.boolean(),
    ];
    const widths = [100.0, 100.0, 140.0, 100.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        hasTextController: types[i].kind != GridSheetColumnKind.boolean,
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Tokyo', 'Japan', 37.4, true],
      ['Delhi', 'India', 32.9, true],
      ['Shanghai', 'China', 28.5, false],
      ['Cairo', 'Egypt', 21.3, true],
      ['Mexico City', 'Mexico', 22.1, true],
      ['Mumbai', 'India', 20.9, false],
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

  void _toggleCellNavigation(bool value) {
    setState(() => _enableCellNavigation = value);
    status.value = 'enableCellNavigation: $value '
        '(arrow keys/tab ${value ? "move between" : "do not move between"} cells)';
  }

  Future<void> _clearSelectedCells() async {
    if (_selectedCells.isEmpty) {
      showDemoSnackBar(context, 'Select one or more cells first');
      return;
    }
    for (final cell in _selectedCells) {
      final row = gridManager.rows.find(cell.rowKey);
      final column = gridManager.columns.find(cell.columnKey);
      if (row == null || column == null) continue;
      await gridManager.cells.clearRange(
        startRowKey: row.key,
        endRowKey: row.key,
        startColumnKey: column.key,
        endColumnKey: column.key,
      );
      if (!mounted) return;
    }
    status.value = 'clearCellRange(): cleared ${_selectedCells.length} cell(s)';
  }

  Future<void> _fillSelectedCells() async {
    if (_selectedCells.isEmpty) {
      showDemoSnackBar(context, 'Select one or more cells first');
      return;
    }
    final value = await showDemoInputDialog(context, 'Fill value');
    if (value == null || value.isEmpty) return;
    if (!mounted) return;
    for (final cell in _selectedCells) {
      gridManager.cells
          .update(rowKey: cell.rowKey, columnKey: cell.columnKey, value: value);
    }
    status.value =
        'updateCellValue(): filled ${_selectedCells.length} cell(s) with "$value"';
  }

  Future<void> _findAndReplace() async {
    final find = await showDemoInputDialog(context, 'Find value');
    if (find == null || find.isEmpty) return;
    if (!mounted) return;
    final replace = await showDemoInputDialog(context, 'Replace with');
    if (replace == null) return;
    if (!mounted) return;
    final count = await gridManager.cells.findAndReplace(
        findValue: find, replaceValue: replace, exactMatch: false);
    if (!mounted) return;
    status.value =
        'findAndReplace(): $count occurrence(s) of "$find" → "$replace"';
  }

  Future<void> _findCells() async {
    final value = await showDemoInputDialog(context, 'Find cells containing');
    if (value == null || value.isEmpty) return;
    if (!mounted) return;
    final cells = gridManager.cells.find(
      predicate: (cellValue, row, column) =>
          cellValue?.toString().toLowerCase().contains(value.toLowerCase()) ??
          false,
    );
    showDemoDialog(context, 'Find Cells',
        '${cells.length} matching cell(s) found for "$value"');
  }

  void _copySelectedCells() {
    if (_selectedCells.isEmpty) {
      showDemoSnackBar(context, 'Select one or more cells first');
      return;
    }
    final values = _selectedCells
        .map((cell) =>
            gridManager.cells.value(cell.rowKey, cell.columnKey)?.toString() ??
            '')
        .join('\t');
    Clipboard.setData(ClipboardData(text: values));
    status.value =
        'Copied ${_selectedCells.length} cell value(s) to clipboard (tab-delimited)';
  }
}
