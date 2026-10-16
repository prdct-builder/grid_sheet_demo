import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';
import '../design_system/app_theme.dart';

class ColumnTypes extends StatefulWidget {
  const ColumnTypes({super.key});

  @override
  State<ColumnTypes> createState() => _ColumnTypesState();
}

class _ColumnTypesState extends State<ColumnTypes> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier('');

  bool _editable = true;

  // GridSheetColumn.editable is only read once, at initial mount (see
  // GridSheet's _initData()) — reassigning this key forces a brand-new
  // GridSheet element so the toggle below actually takes effect, the same
  // trick column_animation.dart uses for its config-changing toggles.
  GlobalKey<GridSheetState> _gridKey = GlobalKey<GridSheetState>();

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Column Types',
      description:
          'One GridSheet, eight different GridSheetColumnType values — text, integer, double, boolean, '
          'datetime, dropdown, formula and custom — each rendered with its native editor. Hover a column '
          'header to see its GridSheetColumn.description tooltip.',
      icon: Icons.view_column_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Editable',
            icon: Icons.edit_outlined,
            color: context.accents.blue,
            value: _editable,
            onChanged: _toggleEditable,
            tooltip: 'Toggle whether every column is editable',
          ),
        ],
      ),
      grid: GridSheet(
        key: _gridKey,
        columns: _columns(),
        rows: _rows(),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) {
          gridManager = event.gridManager;
          recordGridLoadTime();
        },
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const keys = [
      'col_text',
      'col_integer',
      'col_double',
      'col_boolean',
      'col_datetime',
      'col_dropdown',
      'col_formula',
      'col_custom',
    ];
    const names = [
      'EMPLOYEE_NAME',
      'AGE',
      'SALARY',
      'IS_ACTIVE',
      'JOIN_DATE',
      'DEPARTMENT',
      'ANNUAL_SALARY',
      'PASSWORD',
    ];
    const titles = [
      'Employee (text)',
      'Age (integer)',
      'Salary (double)',
      'Active (boolean)',
      'Join date (datetime)',
      'Department (dropdown)',
      'Annual (formula)',
      'Password (custom)',
    ];
    const descriptions = [
      'GridSheetColumnType.text() — free-form string input',
      'GridSheetColumnType.integer() — whole numbers only',
      'GridSheetColumnType.double() — decimal numbers',
      'GridSheetColumnType.boolean() — renders as a checkbox',
      'GridSheetColumnType.datetime() — date & time values',
      'GridSheetColumnType.dropdown(options: [...]) — constrained option list',
      'GridSheetColumnType.formula() — Excel-style expression',
      'GridSheetColumnType.custom() — free-form typed value',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.double(),
      GridSheetColumnType.boolean(),
      GridSheetColumnType.datetime(),
      GridSheetColumnType.dropdown(options: ['Engineering', 'Design', 'Sales', 'Support']),
      GridSheetColumnType.formula(),
      GridSheetColumnType.custom(),
    ];
    const widths = [150.0, 100.0, 130.0, 110.0, 160.0, 160.0, 170.0, 140.0];
    const sortables = [true, true, true, false, true, false, false, false];
    const resizes = [true, true, true, false, false, false, false, false];
    const textAligns = [
      TextAlign.left,
      TextAlign.right,
      TextAlign.right,
      TextAlign.left,
      TextAlign.left,
      TextAlign.left,
      TextAlign.right,
      TextAlign.left,
    ];
    const hasTextControllers = [
      true,
      true,
      true,
      false,
      false,
      false,
      true,
      true,
    ];

    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey(keys[i]),
        index: i,
        name: names[i],
        title: titles[i],
        description: descriptions[i],
        type: types[i],
        width: widths[i],
        sortable: sortables[i],
        resizable: resizes[i],
        textAlign: textAligns[i],
        hasTextController: hasTextControllers[i],
        editable: _editable,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      [
        'Ava Thompson',
        29,
        78500.0,
        true,
        '2021-03-14',
        'Engineering',
        '=C1 * 12',
        '••••'
      ],
      [
        'Liam Chen',
        34,
        92500.0,
        true,
        '2019-07-01',
        'Design',
        '=C2 * 12',
        '•••••'
      ],
      [
        'Noah Patel',
        41,
        68000.0,
        false,
        '2016-11-23',
        'Sales',
        '=C3 * 12',
        '•••'
      ],
      [
        'Maya Rodriguez',
        26,
        71500.0,
        true,
        '2022-05-09',
        'Support',
        '=C4 * 12',
        '••••'
      ],
      [
        'Ethan Kim',
        37,
        105000.0,
        true,
        '2018-01-30',
        'Engineering',
        '=C5 * 12',
        '•••••'
      ],
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

  void _toggleEditable(bool value) {
    setState(() {
      _editable = value;
      _gridKey = GlobalKey<GridSheetState>();
    });
    status.value = value
        ? 'editable: true — every column\'s native editor is now interactive.'
        : 'editable: false — every column is now read-only, regardless of type.';
  }
}
