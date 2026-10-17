import 'package:flutter/material.dart';
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
  // Read at click time: the grid also clears the selection itself (after a
  // delete, sort or filter) without calling onCellsSelected.
  List<GridSheetCell> get _selectedCells => gridManager.selection.cellKeys;
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
          status.value = 'Selected ${event.cells.length} cell(s)';
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
    final cells = _selectedCells;
    if (cells.isEmpty) {
      showDemoSnackBar(context, 'Select one or more cells first');
      return;
    }
    gridManager.cells.clear(cells);
    status.value = 'cells.clear(): cleared ${cells.length} cell(s)';
  }

  Future<void> _fillSelectedCells() async {
    if (_selectedCells.isEmpty) {
      showDemoSnackBar(context, 'Select one or more cells first');
      return;
    }
    final value = await showDemoInputDialog(context, 'Fill value');
    if (value == null || value.isEmpty) return;
    if (!mounted) return;
    final cells = _selectedCells;
    // cells.updateAll stores values as given, so convert the typed text to
    // each column's type first ("42" becomes 42.0 in a double column).
    gridManager.cells.updateAll([
      for (final cell in cells)
        GridSheetCellUpdate(
          rowKey: cell.rowKey,
          columnKey: cell.columnKey,
          value: _valueFor(gridManager.columns.find(cell.columnKey), value),
        ),
    ]);
    status.value =
        'cells.updateAll(): filled ${cells.length} cell(s) with "$value"';
  }

  // [text] converted to [column]'s type, or left as text when it doesn't
  // parse (or the column holds text).
  static dynamic _valueFor(GridSheetColumn? column, String text) {
    final trimmed = text.trim();
    return switch (column?.type.kind) {
      GridSheetColumnKind.integer => int.tryParse(trimmed) ?? text,
      GridSheetColumnKind.double => double.tryParse(trimmed) ?? text,
      GridSheetColumnKind.boolean =>
        bool.tryParse(trimmed.toLowerCase()) ?? text,
      GridSheetColumnKind.datetime => DateTime.tryParse(trimmed) ?? text,
      _ => text,
    };
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

  Future<void> _copySelectedCells() async {
    final count = _selectedCells.length;
    if (count == 0) {
      showDemoSnackBar(context, 'Select one or more cells first');
      return;
    }
    // One line per row and one field per column, in display order, quoted
    // where needed — ready to paste into a spreadsheet.
    await gridManager.cells.copy();
    if (!mounted) return;
    status.value = 'cells.copy(): copied $count cell(s) to the clipboard';
  }
}
