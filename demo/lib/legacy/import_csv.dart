import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';

class ImportCSVGridSheet extends StatefulWidget {
  const ImportCSVGridSheet({super.key});

  @override
  State<ImportCSVGridSheet> createState() => _ImportCSVGridSheetState();
}

class _ImportCSVGridSheetState extends State<ImportCSVGridSheet> {
  late GridSheetManager gridManager;

  late List<String> _columns;
  late List<List<dynamic>> _rows;

  late Map<String, double> _columnWidths;
  late Map<String, String> _columnActualNames;
  late Map<String, GridSheetColumnType> _columnTypes;

  bool _isImporting = false;
  int _gridInstanceKey = 0;

  @override
  void initState() {
    super.initState();

    _mockData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<GridSheetColumn> get columns => _getColumns();
  List<GridSheetRow> get rows => _getRows();

  @override
  Widget build(BuildContext context) {
    // Build style configuration based on current theme
    final styleConfiguration = _buildStyleConfiguration(context);

    return Stack(
      children: [
        GridSheet(
          key: ValueKey<int>(_gridInstanceKey),
          columns: columns,
          rows: rows,
          loadingIndicator: _ImportTickerLoadingWidget(),
          configuration: GridSheetConfiguration(
            showColumnFilters: true,
          ),
          styleConfiguration: styleConfiguration,
          onLoaded: (event) {
            gridManager = event.gridManager;
            log('Table initialized!', name: 'GridSheetTableDemo');
            recordGridLoadTime();
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _isImporting ? null : _importCsv,
            tooltip: 'Import CSV',
            child: _isImporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_upload),
          ),
        ),
      ],
    );
  }

  GridSheetStyleConfiguration _buildStyleConfiguration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridSheetStyleConfiguration(
      gridBackgroundColor: colorScheme.surface,
      headerColor: Colors.green[300]!,
      filterColor: colorScheme.surface,
      rowColor: colorScheme.surface,
      evenRowColor: isDark
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      oddRowColor: colorScheme.surface,
      selectionColor: colorScheme.primary,
      gridBorderColor: colorScheme.outlineVariant,
      rowBorderColor: colorScheme.outlineVariant,
      columnBorderColor: colorScheme.outlineVariant,
      filterRowBorderColor: colorScheme.outlineVariant,
      headerRowBorderColor: colorScheme.outlineVariant,
    );
  }

  List<GridSheetColumn> _getColumns() {
    return _columns.asMap().entries.map((e) {
      final column = e.value;
      final index = e.key;
      final key = '${GridSheetConstants.columnCopyKeyStartsWith}$index';

      final actualName = _columnActualNames[column] ?? column;
      final maxWidth = _columnWidths[column] ?? 120.0;
      final type = _columnTypes[column] ?? GridSheetColumnType.text();

      TextAlign alignment = TextAlign.left;
      if (type.kind == GridSheetColumnKind.integer ||
          type.kind == GridSheetColumnKind.double) {
        alignment = TextAlign.right;
      }

      return GridSheetColumn(
        key: ValueKey<String>(key),
        index: index,
        title: column,
        name: actualName,
        type: type,
        width: maxWidth,
        visible: actualName != 'ID',
        textAlign: alignment,
        resizable: true,
      );
    }).toList();
  }

  List<GridSheetRow> _getRows() {
    return _rows.asMap().entries.map((e) {
      final index = e.key;
      final rowData = e.value;
      final key = '${GridSheetConstants.rowKeyStartsWith}$index';

      final row = GridSheetRow(
        key: ValueKey<String>(key),
        index: index,
        data: rowData,
      );

      return row;
    }).toList();
  }

  _mockData() {
    _columns = [
      'Id',
      'Name',
      'Department',
      'Designation',
      'Country',
      'State',
      'Active',
      'Experience',
      'Salary',
      'Bonus',
      'Remarks',
    ];

    _columnActualNames = {
      for (var col in _columns) col: col.replaceAll(' ', '').toUpperCase(),
    };

    _columnWidths = {
      'Id': 50,
      'Name': 150,
      'Department': 200,
      'Designation': 200,
      'Country': 200,
      'State': 100,
      'Active': 100,
      'Experience': 200,
      'Salary': 200,
      'Bonus': 200,
      'Remarks': 200,
    };

    _columnTypes = {
      'Id': GridSheetColumnType.integer(),
      'Name': GridSheetColumnType.text(),
      'Department': GridSheetColumnType.text(),
      'Designation': GridSheetColumnType.text(),
      'Country': GridSheetColumnType.text(),
      'State': GridSheetColumnType.text(),
      'Active': GridSheetColumnType.boolean(),
      'Experience': GridSheetColumnType.double(),
      'Salary': GridSheetColumnType.double(),
      'Bonus': GridSheetColumnType.double(),
      'Remarks': GridSheetColumnType.text(),
    };

    _rows = [
      [
        1,
        'John Smith',
        'Engineering',
        'Developer',
        'India',
        'AP',
        true,
        2.0,
        50000.0,
        5000.0,
        'Good'
      ],
      [
        2,
        'Emma Davis',
        'HR',
        'Manager',
        'US',
        'TS',
        true,
        5.0,
        65000.0,
        7000.0,
        'Excellent'
      ],
      [
        3,
        'Michael Lee',
        'Finance',
        'Analyst',
        'Canada',
        'KA',
        false,
        3.0,
        45000.0,
        3000.0,
        'Average'
      ],
      [
        4,
        'Sophia Brown',
        'Marketing',
        'Executive',
        'Germany',
        'MH',
        true,
        4.0,
        55000.0,
        4000.0,
        'Good'
      ],
    ];
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showMessage('Could not read the selected file.');
        return;
      }

      setState(() => _isImporting = true);

      final content = utf8.decode(bytes);
      final table = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(content, eol: '\n');

      if (table.isEmpty) {
        _showMessage('CSV file is empty.');
        setState(() => _isImporting = false);
        return;
      }

      final header = table.first.map((e) => e.toString().trim()).toList();
      final dataRows = table.skip(1).toList();

      _loadFromCsv(header, dataRows);

      setState(() => _isImporting = false);
      _showMessage('Imported ${dataRows.length} rows from ${file.name}.');
    } catch (e) {
      setState(() => _isImporting = false);
      _showMessage('Failed to import CSV: $e');
    }
  }

  void _loadFromCsv(List<String> header, List<List<dynamic>> dataRows) {
    // Infer a type per column by inspecting the first non-empty value found
    // for that column across the data rows.
    final inferredTypes = <String, GridSheetColumnType>{};
    for (var colIndex = 0; colIndex < header.length; colIndex++) {
      final columnName = header[colIndex];
      GridSheetColumnType type = GridSheetColumnType.text();

      for (final row in dataRows) {
        if (colIndex >= row.length) continue;
        final raw = row[colIndex]?.toString().trim() ?? '';
        if (raw.isEmpty) continue;

        if (raw.toLowerCase() == 'true' || raw.toLowerCase() == 'false') {
          type = GridSheetColumnType.boolean();
        } else if (int.tryParse(raw) != null) {
          type = GridSheetColumnType.integer();
        } else if (double.tryParse(raw) != null) {
          type = GridSheetColumnType.double();
        } else {
          type = GridSheetColumnType.text();
        }
        break; // stop at first non-empty value found
      }

      inferredTypes[columnName] = type;
    }

    // Convert each raw cell to the matching Dart type for its column.
    final typedRows = dataRows.map((row) {
      return List<dynamic>.generate(header.length, (colIndex) {
        final columnName = header[colIndex];
        final type = inferredTypes[columnName] ?? const GridSheetColumnType.text();
        final raw =
            colIndex < row.length ? (row[colIndex]?.toString() ?? '') : '';

        switch (type.kind) {
          case GridSheetColumnKind.integer:
            return int.tryParse(raw.trim()) ?? 0;
          case GridSheetColumnKind.double:
            return double.tryParse(raw.trim()) ?? 0.0;
          case GridSheetColumnKind.boolean:
            return raw.trim().toLowerCase() == 'true';
          default:
            return raw;
        }
      });
    }).toList();

    setState(() {
      _columns = header;
      _columnActualNames = {
        for (var col in header) col: col.replaceAll(' ', '').toUpperCase(),
      };
      _columnWidths = {
        for (var col in header) col: 150.0,
      };
      _columnTypes = inferredTypes;
      _rows = typedRows;
      _gridInstanceKey++;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Custom [GridSheet.loadingIndicator]: a rotating ticker icon inside a
/// pulsing badge, with a trio of sequentially-fading dots underneath —
/// used instead of a plain [CircularProgressIndicator] to show that
/// `loadingIndicator` accepts any widget, not just the built-in spinner.
class _ImportTickerLoadingWidget extends StatefulWidget {
  const _ImportTickerLoadingWidget();

  @override
  State<_ImportTickerLoadingWidget> createState() =>
      _ImportTickerLoadingWidgetState();
}

class _ImportTickerLoadingWidgetState extends State<_ImportTickerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pulse = 0.88 + 0.12 * (1 - (t - 0.5).abs() * 2);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  ),
                  child: Transform.rotate(
                    angle: t * 2 * math.pi,
                    child: Icon(Icons.sync_outlined,
                        color: colorScheme.primary, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Fetching live ticker data…',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (t + i / 3) % 1.0;
                  final opacity = 0.25 + 0.75 * (1 - (phase - 0.5).abs() * 2);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: opacity.clamp(0.25, 1.0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: colorScheme.primary, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
