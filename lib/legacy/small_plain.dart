import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';
import '../design_system/design_system.dart';

class SmallPlainGridSheet extends StatefulWidget {
  const SmallPlainGridSheet({super.key});

  @override
  State<SmallPlainGridSheet> createState() => _SmallPlainGridSheetState();
}

class _SmallPlainGridSheetState extends State<SmallPlainGridSheet> {
  late final GridSheetManager gridManager;

  late List<String> _columns;
  late List<List<dynamic>> _rows;

  late Map<String, double> _columnWidths;
  late Map<String, String> _columnActualNames;
  late Map<String, GridSheetColumnType> _columnTypes;

  @override
  void initState() {
    super.initState();

    _mockData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridSheet(
      columns: _getColumns(),
      rows: _getRows(),
      indexColumn: null,
      configuration: GridSheetConfiguration(
        enableDefaultPagination: false,
        showColumnFilters: true,
        enableRowReorder: true,
        enableRowResize: true,
      ),
      styleConfiguration: styleConfig(context),
      onLoaded: (event) {
        gridManager = event.gridManager;
        log('Table initialized!', name: 'GridSheetTableDemo');
      },
    );
  }

  GridSheetStyleConfiguration styleConfig(
    BuildContext context, {
    bool colorEvenOdd = true,
  }) {
    final colors = context.colors;

    return GridSheetStyleConfiguration(
      gridBackgroundColor: colors.surface,
      headerColor: colors.surfaceSubtle,
      filterColor: colors.surfaceSubtle,
      rowColor: colors.surface,
      evenRowColor: colorEvenOdd ? colors.canvas : null,
      oddRowColor: colorEvenOdd ? colors.surface : null,
      selectionColor: colors.primary,
      gridBorderColor: colors.border,
      headerRowBorderColor: colors.border,
      filterRowBorderColor: colors.border,
      rowBorderColor: colors.border,
      columnBorderColor: colors.border,
      headerTextStyle: TextTypography.label,
      gridBorderRadius: ThemeBorders.roundedSm,
      cellTextFieldBorderColor: colors.border,
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
        editable: false,
        resizable: true,
        hasTextController: false,
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
        height: 40.0,
      );

      return row;
    }).toList();
  }

  void _mockData() {
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
      'Department': 160,
      'Designation': 140,
      'Country': 140,
      'State': 100,
      'Active': 100,
      'Experience': 100,
      'Salary': 120,
      'Bonus': 120,
      'Remarks': 160,
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
      [
        5,
        'Daniel Wilson',
        'Sales',
        'Lead',
        'Australia',
        'DL',
        true,
        6.0,
        72000.0,
        8000.0,
        'Top Performer'
      ],
      [
        6,
        'Olivia Taylor',
        'Support',
        'Consultant',
        'India',
        'AP',
        false,
        1.0,
        35000.0,
        2000.0,
        'Normal'
      ],
      [
        7,
        'James Anderson',
        'Engineering',
        'Developer',
        'US',
        'TS',
        true,
        7.0,
        85000.0,
        9000.0,
        'Excellent'
      ],
      [
        8,
        'Isabella Thomas',
        'Finance',
        'Analyst',
        'Canada',
        'KA',
        true,
        2.0,
        47000.0,
        3500.0,
        'Good'
      ],
      [
        9,
        'Benjamin Harris',
        'HR',
        'Manager',
        'Germany',
        'MH',
        false,
        8.0,
        90000.0,
        10000.0,
        'Top Performer'
      ],
      [
        10,
        'Mia Martin',
        'Marketing',
        'Executive',
        'Australia',
        'DL',
        true,
        3.0,
        52000.0,
        4500.0,
        'Normal'
      ],
      [
        11,
        'William Garcia',
        'Engineering',
        'Lead',
        'India',
        'AP',
        true,
        9.0,
        95000.0,
        12000.0,
        'Excellent'
      ],
      [
        12,
        'Charlotte Martinez',
        'Support',
        'Consultant',
        'US',
        'TS',
        false,
        2.0,
        40000.0,
        2500.0,
        'Average'
      ],
      [
        13,
        'Henry Robinson',
        'Sales',
        'Executive',
        'Canada',
        'KA',
        true,
        5.0,
        61000.0,
        6000.0,
        'Good'
      ],
      [
        14,
        'Amelia Clark',
        'Finance',
        'Manager',
        'Germany',
        'MH',
        true,
        7.0,
        87000.0,
        9500.0,
        'Top Performer'
      ],
      [
        15,
        'Alexander Rodriguez',
        'Engineering',
        'Developer',
        'Australia',
        'DL',
        false,
        4.0,
        58000.0,
        4200.0,
        'Normal'
      ],
      [
        16,
        'Evelyn Lewis',
        'HR',
        'Executive',
        'India',
        'AP',
        true,
        6.0,
        62000.0,
        5200.0,
        'Good'
      ],
      [
        17,
        'Michael Walker',
        'Marketing',
        'Consultant',
        'US',
        'TS',
        true,
        3.0,
        53000.0,
        4100.0,
        'Excellent'
      ],
      [
        18,
        'Abigail Hall',
        'Sales',
        'Lead',
        'Canada',
        'KA',
        false,
        8.0,
        91000.0,
        9800.0,
        'Top Performer'
      ],
      [
        19,
        'Daniel Allen',
        'Support',
        'Developer',
        'Germany',
        'MH',
        true,
        2.0,
        48000.0,
        3600.0,
        'Normal'
      ],
      [
        20,
        'Emily Young',
        'Engineering',
        'Manager',
        'Australia',
        'DL',
        true,
        10.0,
        105000.0,
        15000.0,
        'Excellent'
      ],
      [
        21,
        'Matthew Hernandez',
        'Finance',
        'Analyst',
        'India',
        'AP',
        true,
        4.0,
        56000.0,
        4300.0,
        'Good'
      ],
      [
        22,
        'Harper King',
        'Marketing',
        'Executive',
        'US',
        'TS',
        false,
        1.0,
        37000.0,
        1800.0,
        'Average'
      ],
      [
        23,
        'Joseph Wright',
        'Engineering',
        'Developer',
        'Canada',
        'KA',
        true,
        5.0,
        68000.0,
        7500.0,
        'Excellent'
      ],
      [
        24,
        'Ella Lopez',
        'HR',
        'Consultant',
        'Germany',
        'MH',
        true,
        6.0,
        71000.0,
        8200.0,
        'Good'
      ],
      [
        25,
        'David Hill',
        'Sales',
        'Manager',
        'Australia',
        'DL',
        false,
        7.0,
        83000.0,
        9100.0,
        'Top Performer'
      ],
      [
        26,
        'Scarlett Scott',
        'Finance',
        'Lead',
        'India',
        'AP',
        true,
        3.0,
        52000.0,
        3400.0,
        'Normal'
      ],
      [
        27,
        'Christopher Green',
        'Support',
        'Executive',
        'US',
        'TS',
        true,
        4.0,
        55000.0,
        4600.0,
        'Good'
      ],
      [
        28,
        'Victoria Adams',
        'Engineering',
        'Developer',
        'Canada',
        'KA',
        false,
        2.0,
        49000.0,
        3000.0,
        'Average'
      ],
      [
        29,
        'Andrew Baker',
        'Marketing',
        'Manager',
        'Germany',
        'MH',
        true,
        8.0,
        92000.0,
        11000.0,
        'Excellent'
      ],
      [
        30,
        'Grace Nelson',
        'HR',
        'Lead',
        'Australia',
        'DL',
        true,
        5.0,
        69000.0,
        7000.0,
        'Top Performer'
      ],
      [
        31,
        'Joshua Carter',
        'Engineering',
        'Developer',
        'India',
        'AP',
        true,
        3.0,
        54000.0,
        3900.0,
        'Good'
      ],
      [
        32,
        'Lily Mitchell',
        'Finance',
        'Analyst',
        'US',
        'TS',
        false,
        2.0,
        46000.0,
        2800.0,
        'Normal'
      ],
      [
        33,
        'Ryan Perez',
        'Sales',
        'Executive',
        'Canada',
        'KA',
        true,
        6.0,
        76000.0,
        8300.0,
        'Excellent'
      ],
      [
        34,
        'Hannah Roberts',
        'Marketing',
        'Consultant',
        'Germany',
        'MH',
        true,
        4.0,
        59000.0,
        5000.0,
        'Good'
      ],
      [
        35,
        'Nathan Turner',
        'Support',
        'Lead',
        'Australia',
        'DL',
        false,
        7.0,
        81000.0,
        9200.0,
        'Top Performer'
      ],
      [
        36,
        'Zoe Phillips',
        'HR',
        'Manager',
        'India',
        'AP',
        true,
        5.0,
        70000.0,
        7600.0,
        'Excellent'
      ],
    ];
  }
}
