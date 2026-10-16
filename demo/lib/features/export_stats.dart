import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class DataExportStats extends StatefulWidget {
  const DataExportStats({super.key});

  @override
  State<DataExportStats> createState() => _DataExportStatsState();
}

class _DataExportStatsState extends State<DataExportStats> {
  late GridSheetManager gridManager;

  /// Resolves a column name to its key — the manager's column methods are
  /// key-addressed.
  ValueKey<String> _columnKey(String name) =>
      gridManager.columns.findByNames([name]).single.key;

  final ValueNotifier<String> status = ValueNotifier('');

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Data Export & Statistics',
      description:
          'Export the grid to CSV or a list of maps, and compute sum/average/min/max/median for any numeric '
          'column with columnStatistics — handy for footers, dashboards, or downstream reporting.',
      icon: Icons.insights_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Export CSV',
            icon: Icons.table_chart_outlined,
            color: context.accents.green,
            onPressed: _exportCSV,
            tooltip: 'Copy the grid to the clipboard as CSV',
          ),
          DemoActionButton(
            label: 'Export CSV (Formulas)',
            icon: Icons.functions_outlined,
            color: context.accents.teal,
            onPressed: _exportCSVWithFormulas,
            tooltip: 'Copy to CSV keeping formula text instead of results',
          ),
          DemoActionButton(
            label: 'Export JSON',
            icon: Icons.data_object_outlined,
            color: context.accents.blue,
            onPressed: _exportJSON,
            tooltip: 'Convert every row to a list of maps',
          ),
          DemoActionButton(
            label: 'Salary Stats',
            icon: Icons.bar_chart_outlined,
            color: context.accents.purple,
            onPressed: _showSalaryStatistics,
            tooltip: 'Show sum/average/min/max/median for SALARY',
          ),
          DemoActionButton(
            label: 'Row Counts',
            icon: Icons.numbers_outlined,
            color: context.accents.orange,
            onPressed: _showRowCounts,
            tooltip: 'Show total, filtered, and current-page row counts',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(showColumnFilters: true),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['NAME', 'DEPARTMENT', 'SALARY', 'BONUS'];
    const titles = ['Name', 'Department', 'Salary', 'Bonus'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.formula(),
    ];
    const widths = [140.0, 120.0, 100.0, 100.0];
    const textAligns = [
      TextAlign.left,
      TextAlign.left,
      TextAlign.right,
      TextAlign.right,
    ];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_${i + 1}'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        textAlign: textAligns[i],
        sortable: i == 2,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Ava Thompson', 'Engineering', 78500.0, '=C1 * 0.1'],
      ['Liam Chen', 'Design', 92500.0, '=C2 * 0.1'],
      ['Noah Patel', 'Sales', 68000.0, '=C3 * 0.1'],
      ['Maya Rodriguez', 'Support', 71500.0, '=C4 * 0.1'],
      ['Ethan Kim', 'Engineering', 105000.0, '=C5 * 0.1'],
      ['Sofia Bianchi', 'Sales', 59500.0, '=C6 * 0.1'],
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

  void _exportCSV() {
    final csv = gridManager.data.toCsv(
        includeHeaders: true, columnScope: GridSheetColumnScope.visible);
    Clipboard.setData(ClipboardData(text: csv));
    showDemoSnackBar(context, 'CSV copied to clipboard');
    status.value = 'exportToCSV(): ${csv.split("\n").length} line(s) copied';
  }

  void _exportCSVWithFormulas() {
    // BONUS keeps its live "=C1 * 0.1" formula text instead of the
    // evaluated value — unlike the default exportToCSV() call above, which
    // always exports the computed result.
    final csv = gridManager.data.toCsv(
      includeHeaders: true,
      columnScope: GridSheetColumnScope.visible,
      includeFormulas: true,
    );
    Clipboard.setData(ClipboardData(text: csv));
    showDemoSnackBar(context, 'CSV (with formulas) copied to clipboard');
    status.value = 'exportToCSV(includeFormulas: true): '
        '${csv.split("\n").length} line(s) copied';
  }

  void _exportJSON() {
    final data = gridManager.data.toMaps(gridManager.rows.filtered);
    showDemoDialog(context, 'toRowDataMaps()', data.toString());
    status.value = 'toRowDataMaps(): converted ${data.length} row(s) to maps';
  }

  void _showSalaryStatistics() {
    final stats = gridManager.data.statistics(_columnKey('SALARY'));
    showDemoDialog(context, 'columnStatistics("SALARY")', stats.toString());
    status.value =
        'columnStatistics(): sum / average / min / max / median computed';
  }

  void _showRowCounts() {
    showDemoDialog(
      context,
      'Row Counts',
      'Total rows: ${gridManager.rows.count}\n'
          'Filtered rows: ${gridManager.rows.filteredCount}\n'
          'Current page rows: ${gridManager.rows.currentPageCount}',
    );
  }
}
