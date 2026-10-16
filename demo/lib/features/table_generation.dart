import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheet.dynamicGenerationConfiguration]
/// (`GridSheetDynamicGenerationConfiguration`) — auto-generating columns and rows
/// instead of supplying `columns`/`rows` explicitly.
class TableGeneration extends StatefulWidget {
  const TableGeneration({super.key});

  @override
  State<TableGeneration> createState() => _TableGenerationState();
}

class _TableGenerationState extends State<TableGeneration> {
  final ValueNotifier<String> status = ValueNotifier(
    'dynamicGenerationConfiguration generates columns/rows automatically — '
    'no columns/rows list needed.',
  );

  int _columnsCount = 4;
  int _rowsCount = 6;
  GridSheetColumnType _columnType = GridSheetColumnType.text();
  bool _alternateRowHeights = false;
  bool _alternateColumnWidths = false;

  static const _cyclableTypes = [
    GridSheetColumnType.text(),
    GridSheetColumnType.integer(),
    GridSheetColumnType.boolean(),
    GridSheetColumnType.double(),
  ];

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Dynamic Table Generation',
      description:
          'GridSheetDynamicGenerationConfiguration auto-generates a blank grid of a given size, with '
          'columnBuilder/rowBuilder to customize any generated column or row beyond the defaults.',
      icon: Icons.grid_4x4_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Columns: $_columnsCount',
            icon: Icons.remove,
            color: context.accents.blue,
            onPressed: () => _changeColumnsCount(-1),
            tooltip: 'Generate one fewer column',
          ),
          DemoActionButton(
            label: '+1 Column',
            icon: Icons.add,
            color: context.accents.blue,
            onPressed: () => _changeColumnsCount(1),
            tooltip: 'Generate one more column',
          ),
          DemoActionButton(
            label: 'Rows: $_rowsCount',
            icon: Icons.remove,
            color: context.accents.teal,
            onPressed: () => _changeRowsCount(-1),
            tooltip: 'Generate one fewer row',
          ),
          DemoActionButton(
            label: '+1 Row',
            icon: Icons.add,
            color: context.accents.teal,
            onPressed: () => _changeRowsCount(1),
            tooltip: 'Generate one more row',
          ),
          DemoActionButton(
            label: 'Type: ${_columnType.kind.name}',
            icon: Icons.swap_horiz,
            color: context.accents.purple,
            onPressed: _cycleColumnType,
            tooltip: 'Cycle the generated columns\' type',
          ),
          DemoActionButton(
            label: _alternateColumnWidths
                ? 'Column widths: alternating'
                : 'Column widths: uniform',
            icon: Icons.width_wide_outlined,
            color: context.accents.yellow,
            onPressed: _toggleAlternateColumnHeights,
            tooltip:
                'Use columnBuilder to make every other generated column wider',
          ),
          DemoActionButton(
            label: _alternateRowHeights
                ? 'Row heights: alternating'
                : 'Row heights: uniform',
            icon: Icons.height,
            color: context.accents.orange,
            onPressed: _toggleAlternateRowHeights,
            tooltip: 'Use rowBuilder to make every other generated row taller',
          ),
        ],
      ),
      grid: GridSheet(
        // dynamicGenerationConfiguration is only read at initState, so a
        // structural change here must force a brand-new GridSheet element —
        // a key derived from the settings does that.
        key: ValueKey(
            '$_columnsCount-$_rowsCount-$_columnType-$_alternateColumnWidths-$_alternateRowHeights'),
        columns: const [],
        rows: const [],
        configuration: GridSheetConfiguration(
          enableCellSelection: true,
        ),
        dynamicGenerationConfiguration: GridSheetDynamicGenerationConfiguration(
          columnsCount: _columnsCount,
          rowsCount: _rowsCount,
          columnBuilder: (index, column) => column.copyWith(
            type: _columnType,
            textAlign: isNumericColumn
                ? TextAlign.end
                : isBooleanColumn
                    ? TextAlign.center
                    : TextAlign.start,
            width: _alternateColumnWidths && index.isOdd ? 120 : 80,
          ),
          rowBuilder: (index, row) => _alternateRowHeights && index.isOdd
              ? row.copyWith(height: 45)
              : row,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
      ),
    );
  }

  bool get isNumericColumn {
    return _columnType.kind == GridSheetColumnKind.integer ||
        _columnType.kind == GridSheetColumnKind.double;
  }

  bool get isBooleanColumn {
    return _columnType.kind == GridSheetColumnKind.boolean;
  }

  void _changeColumnsCount(int delta) {
    setState(() => _columnsCount = (_columnsCount + delta).clamp(1, 10));
    status.value = 'columnsCount: $_columnsCount';
  }

  void _changeRowsCount(int delta) {
    setState(() => _rowsCount = (_rowsCount + delta).clamp(1, 30));
    status.value = 'rowsCount: $_rowsCount';
  }

  void _cycleColumnType() {
    final nextIndex =
        (_cyclableTypes.indexOf(_columnType) + 1) % _cyclableTypes.length;
    setState(() => _columnType = _cyclableTypes[nextIndex]);
    status.value = 'type: ${_columnType.kind.name}';
  }

  void _toggleAlternateRowHeights() {
    setState(() => _alternateRowHeights = !_alternateRowHeights);
    status.value = _alternateRowHeights
        ? 'rowBuilder: every other row is taller (height: 45)'
        : 'rowBuilder: all rows use the default height again';
  }

  void _toggleAlternateColumnHeights() {
    setState(() => _alternateColumnWidths = !_alternateColumnWidths);
    status.value = _alternateColumnWidths
        ? 'columnBuilder: every other column is wider (width: 120)'
        : 'columnBuilder: all columns use the default width again';
  }
}
