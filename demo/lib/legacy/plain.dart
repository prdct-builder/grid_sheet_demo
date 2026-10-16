import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';

class PlainGridSheet extends StatefulWidget {
  const PlainGridSheet({super.key});

  @override
  State<PlainGridSheet> createState() => _PlainGridSheetState();
}

class _PlainGridSheetState extends State<PlainGridSheet> {
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

  List<GridSheetColumn> get columns => _getColumns();
  List<GridSheetRow> get rows => _getRows();

  @override
  Widget build(BuildContext context) {
    // Build style configuration based on current theme
    final styleConfiguration = _buildStyleConfiguration(context);

    return GridSheet(
      columns: columns,
      rows: rows,
      configuration: GridSheetConfiguration(
        enableDefaultPagination: false,
        showColumnFilters: true,
      ),
      styleConfiguration: styleConfiguration,
      onLoaded: (event) {
        gridManager = event.gridManager;
        log('Table initialized!', name: 'GridSheetTableDemo');
        recordGridLoadTime();
      },
    );
  }

  GridSheetStyleConfiguration _buildStyleConfiguration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridSheetStyleConfiguration(
      gridBackgroundColor: colorScheme.surface,
      headerColor: Colors.green[300]!,
      filterColor: Colors.white30,
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
      [
        37,
        'Aaron Campbell',
        'Engineering',
        'Developer',
        'US',
        'TS',
        true,
        1.0,
        42000.0,
        2000.0,
        'Average'
      ],
      [
        38,
        'Penelope Parker',
        'Finance',
        'Executive',
        'Canada',
        'KA',
        false,
        3.0,
        53000.0,
        4100.0,
        'Normal'
      ],
      [
        39,
        'Christian Evans',
        'Marketing',
        'Lead',
        'Germany',
        'MH',
        true,
        8.0,
        94000.0,
        11500.0,
        'Excellent'
      ],
      [
        40,
        'Layla Edwards',
        'Sales',
        'Consultant',
        'Australia',
        'DL',
        true,
        2.0,
        50000.0,
        3200.0,
        'Good'
      ],
      [
        41,
        'Jonathan Collins',
        'Engineering',
        'Manager',
        'India',
        'AP',
        true,
        9.0,
        98000.0,
        13000.0,
        'Top Performer'
      ],
      [
        42,
        'Nora Stewart',
        'Support',
        'Executive',
        'US',
        'TS',
        false,
        4.0,
        57000.0,
        4700.0,
        'Good'
      ],
      [
        43,
        'Isaac Sanchez',
        'Finance',
        'Developer',
        'Canada',
        'KA',
        true,
        6.0,
        73000.0,
        8100.0,
        'Excellent'
      ],
      [
        44,
        'Mila Morris',
        'Marketing',
        'Manager',
        'Germany',
        'MH',
        true,
        7.0,
        86000.0,
        9800.0,
        'Top Performer'
      ],
      [
        45,
        'Gabriel Rogers',
        'Sales',
        'Lead',
        'Australia',
        'DL',
        false,
        5.0,
        67000.0,
        6400.0,
        'Normal'
      ],
      [
        46,
        'Aurora Reed',
        'HR',
        'Consultant',
        'India',
        'AP',
        true,
        2.0,
        44000.0,
        2600.0,
        'Average'
      ],
      [
        47,
        'Julian Cook',
        'Engineering',
        'Developer',
        'US',
        'TS',
        true,
        3.0,
        56000.0,
        4300.0,
        'Good'
      ],
      [
        48,
        'Savannah Morgan',
        'Support',
        'Executive',
        'Canada',
        'KA',
        false,
        1.0,
        39000.0,
        1700.0,
        'Normal'
      ],
      [
        49,
        'Levi Bell',
        'Finance',
        'Lead',
        'Germany',
        'MH',
        true,
        8.0,
        91000.0,
        10400.0,
        'Excellent'
      ],
      [
        50,
        'Claire Murphy',
        'Marketing',
        'Developer',
        'Australia',
        'DL',
        true,
        4.0,
        60000.0,
        5200.0,
        'Good'
      ],
      [
        51,
        'Thomas Bailey',
        'Sales',
        'Executive',
        'India',
        'AP',
        true,
        5.0,
        68000.0,
        6200.0,
        'Good'
      ],
      [
        52,
        'Lucy Rivera',
        'HR',
        'Consultant',
        'US',
        'TS',
        false,
        2.0,
        43000.0,
        2400.0,
        'Average'
      ],
      [
        53,
        'Jack Cooper',
        'Engineering',
        'Developer',
        'Canada',
        'KA',
        true,
        6.0,
        78000.0,
        8600.0,
        'Excellent'
      ],
      [
        54,
        'Aria Richardson',
        'Finance',
        'Manager',
        'Germany',
        'MH',
        true,
        7.0,
        89000.0,
        10200.0,
        'Top Performer'
      ],
      [
        55,
        'Sebastian Cox',
        'Marketing',
        'Lead',
        'Australia',
        'DL',
        false,
        4.0,
        61000.0,
        4800.0,
        'Normal'
      ],
      [
        56,
        'Chloe Howard',
        'Support',
        'Executive',
        'India',
        'AP',
        true,
        3.0,
        54000.0,
        3900.0,
        'Good'
      ],
      [
        57,
        'Owen Ward',
        'Engineering',
        'Developer',
        'US',
        'TS',
        true,
        8.0,
        93000.0,
        11100.0,
        'Excellent'
      ],
      [
        58,
        'Luna Torres',
        'Finance',
        'Analyst',
        'Canada',
        'KA',
        false,
        1.0,
        41000.0,
        1900.0,
        'Normal'
      ],
      [
        59,
        'Dylan Peterson',
        'Sales',
        'Manager',
        'Germany',
        'MH',
        true,
        9.0,
        101000.0,
        14500.0,
        'Top Performer'
      ],
      [
        60,
        'Ellie Gray',
        'Marketing',
        'Consultant',
        'Australia',
        'DL',
        true,
        5.0,
        69000.0,
        6700.0,
        'Good'
      ],
      [
        61,
        'Wyatt Ramirez',
        'Support',
        'Lead',
        'India',
        'AP',
        false,
        6.0,
        74000.0,
        8100.0,
        'Excellent'
      ],
      [
        62,
        'Nora James',
        'HR',
        'Executive',
        'US',
        'TS',
        true,
        2.0,
        47000.0,
        2800.0,
        'Average'
      ],
      [
        63,
        'Isaiah Watson',
        'Engineering',
        'Developer',
        'Canada',
        'KA',
        true,
        7.0,
        85000.0,
        9700.0,
        'Excellent'
      ],
      [
        64,
        'Hazel Brooks',
        'Finance',
        'Lead',
        'Germany',
        'MH',
        false,
        3.0,
        56000.0,
        4200.0,
        'Normal'
      ],
      [
        65,
        'Leo Kelly',
        'Marketing',
        'Manager',
        'Australia',
        'DL',
        true,
        8.0,
        96000.0,
        11800.0,
        'Top Performer'
      ],
      [
        66,
        'Violet Sanders',
        'Sales',
        'Executive',
        'India',
        'AP',
        true,
        4.0,
        62000.0,
        5100.0,
        'Good'
      ],
      [
        67,
        'Lincoln Price',
        'Engineering',
        'Consultant',
        'US',
        'TS',
        false,
        5.0,
        71000.0,
        6900.0,
        'Excellent'
      ],
      [
        68,
        'Stella Bennett',
        'Support',
        'Developer',
        'Canada',
        'KA',
        true,
        1.0,
        39000.0,
        1500.0,
        'Average'
      ],
      [
        69,
        'Hunter Wood',
        'Finance',
        'Manager',
        'Germany',
        'MH',
        true,
        9.0,
        104000.0,
        15200.0,
        'Top Performer'
      ],
      [
        70,
        'Paisley Barnes',
        'Marketing',
        'Lead',
        'Australia',
        'DL',
        false,
        6.0,
        79000.0,
        8700.0,
        'Good'
      ],
      [
        71,
        'Eli Ross',
        'Sales',
        'Developer',
        'India',
        'AP',
        true,
        3.0,
        55000.0,
        3600.0,
        'Normal'
      ],
      [
        72,
        'Skylar Henderson',
        'HR',
        'Executive',
        'US',
        'TS',
        true,
        2.0,
        46000.0,
        2500.0,
        'Average'
      ],
      [
        73,
        'Maverick Coleman',
        'Engineering',
        'Manager',
        'Canada',
        'KA',
        false,
        10.0,
        115000.0,
        18000.0,
        'Top Performer'
      ],
      [
        74,
        'Bella Jenkins',
        'Finance',
        'Consultant',
        'Germany',
        'MH',
        true,
        4.0,
        63000.0,
        5400.0,
        'Good'
      ],
      [
        75,
        'Ezra Perry',
        'Support',
        'Lead',
        'Australia',
        'DL',
        true,
        7.0,
        88000.0,
        9900.0,
        'Excellent'
      ],
      [
        76,
        'Aurora Powell',
        'Marketing',
        'Executive',
        'India',
        'AP',
        false,
        1.0,
        40000.0,
        1700.0,
        'Normal'
      ],
      [
        77,
        'Landon Long',
        'Engineering',
        'Developer',
        'US',
        'TS',
        true,
        5.0,
        70000.0,
        7200.0,
        'Good'
      ],
      [
        78,
        'Grace Patterson',
        'Sales',
        'Manager',
        'Canada',
        'KA',
        true,
        8.0,
        97000.0,
        12100.0,
        'Top Performer'
      ],
      [
        79,
        'Jeremiah Hughes',
        'Finance',
        'Lead',
        'Germany',
        'MH',
        false,
        6.0,
        76000.0,
        8300.0,
        'Excellent'
      ],
      [
        80,
        'Alice Flores',
        'HR',
        'Consultant',
        'Australia',
        'DL',
        true,
        2.0,
        48000.0,
        2900.0,
        'Average'
      ],
      [
        81,
        'Adrian Washington',
        'Engineering',
        'Executive',
        'India',
        'AP',
        true,
        4.0,
        61000.0,
        4700.0,
        'Good'
      ],
      [
        82,
        'Naomi Butler',
        'Marketing',
        'Developer',
        'US',
        'TS',
        false,
        3.0,
        53000.0,
        3400.0,
        'Normal'
      ],
      [
        83,
        'Easton Simmons',
        'Support',
        'Manager',
        'Canada',
        'KA',
        true,
        9.0,
        102000.0,
        14900.0,
        'Top Performer'
      ],
      [
        84,
        'Caroline Foster',
        'Finance',
        'Executive',
        'Germany',
        'MH',
        true,
        5.0,
        68000.0,
        6300.0,
        'Good'
      ],
      [
        85,
        'Robert Gonzales',
        'Sales',
        'Lead',
        'Australia',
        'DL',
        false,
        7.0,
        84000.0,
        9200.0,
        'Excellent'
      ],
      [
        86,
        'Genesis Bryant',
        'HR',
        'Developer',
        'India',
        'AP',
        true,
        1.0,
        41000.0,
        1800.0,
        'Average'
      ],
      [
        87,
        'Angel Alexander',
        'Engineering',
        'Consultant',
        'US',
        'TS',
        true,
        6.0,
        77000.0,
        8500.0,
        'Good'
      ],
      [
        88,
        'Sarah Russell',
        'Marketing',
        'Manager',
        'Canada',
        'KA',
        false,
        8.0,
        94000.0,
        11300.0,
        'Top Performer'
      ],
      [
        89,
        'Connor Griffin',
        'Finance',
        'Executive',
        'Germany',
        'MH',
        true,
        4.0,
        59000.0,
        4500.0,
        'Normal'
      ],
      [
        90,
        'Autumn Diaz',
        'Support',
        'Lead',
        'Australia',
        'DL',
        true,
        5.0,
        72000.0,
        7400.0,
        'Excellent'
      ],
      [
        91,
        'Jordan Hayes',
        'Engineering',
        'Developer',
        'India',
        'AP',
        false,
        2.0,
        47000.0,
        2600.0,
        'Average'
      ],
      [
        92,
        'Kennedy Myers',
        'Sales',
        'Consultant',
        'US',
        'TS',
        true,
        7.0,
        86000.0,
        9700.0,
        'Excellent'
      ],
      [
        93,
        'Charles Ford',
        'Finance',
        'Manager',
        'Canada',
        'KA',
        true,
        9.0,
        108000.0,
        16000.0,
        'Top Performer'
      ],
      [
        94,
        'Madelyn Hamilton',
        'Marketing',
        'Executive',
        'Germany',
        'MH',
        false,
        3.0,
        52000.0,
        3200.0,
        'Normal'
      ],
      [
        95,
        'Josiah Graham',
        'Support',
        'Developer',
        'Australia',
        'DL',
        true,
        4.0,
        60000.0,
        4900.0,
        'Good'
      ],
      [
        96,
        'Ruby Sullivan',
        'HR',
        'Lead',
        'India',
        'AP',
        true,
        6.0,
        78000.0,
        8600.0,
        'Excellent'
      ],
      [
        97,
        'Elias Wallace',
        'Engineering',
        'Manager',
        'US',
        'TS',
        false,
        10.0,
        118000.0,
        19000.0,
        'Top Performer'
      ],
      [
        98,
        'Claire Woods',
        'Finance',
        'Consultant',
        'Canada',
        'KA',
        true,
        5.0,
        69000.0,
        6100.0,
        'Good'
      ],
      [
        99,
        'Nathan West',
        'Sales',
        'Executive',
        'Germany',
        'MH',
        true,
        2.0,
        45000.0,
        2200.0,
        'Average'
      ],
      [
        100,
        'Scott Ginther',
        'Engineering',
        'Manager',
        'India',
        'AP',
        true,
        10.0,
        120000.0,
        20000.0,
        'Top Performer'
      ],
    ];
  }
}
