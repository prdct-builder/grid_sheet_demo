import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class DropdownCells extends StatefulWidget {
  const DropdownCells({super.key});

  @override
  State<DropdownCells> createState() => _DropdownCellsState();
}

class _DropdownCellsState extends State<DropdownCells> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'Tap a STATUS or PRIORITY cell to open the popup menu. The LOCKED_STATUS column is read-only by design.',
  );

  bool _lockArchived = true;

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
      title: 'Dropdown Cell Type',
      description:
          'GridSheetColumnType.dropdown() renders a Material popup menu constrained to dropdownOptions, with a '
          'checkmark on the current value. Setting editable: false renders plain read-only text with no arrow.',
      icon: Icons.arrow_drop_down_circle_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Locked',
            icon: Icons.lock_outline,
            color: context.accents.red,
            value: _lockArchived,
            onChanged: _toggleLockArchived,
            tooltip: 'Toggle whether the Archived dropdown is read-only',
          ),
        ],
      ),
      grid: GridSheet(
        key: _gridKey,
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(enableCellSelection: true),
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
    const names = ['TICKET', 'STATUS', 'PRIORITY', 'LOCKED_STATUS'];
    final titles = [
      'Ticket',
      'Status (editable dropdown)',
      'Priority (editable dropdown)',
      _lockArchived
          ? 'Archived (read-only dropdown)'
          : 'Archived (editable dropdown)',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(
          options: ['Open', 'In Progress', 'Resolved', 'Closed']),
      GridSheetColumnType.dropdown(
          options: ['Low', 'Medium', 'High', 'Critical']),
      GridSheetColumnType.dropdown(options: ['Yes', 'No']),
    ];
    const widths = [130.0, 210.0, 210.0, 220.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_${i + 1}'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        editable: i == 3 ? !_lockArchived : true,
        hasTextController: types[i].kind != GridSheetColumnKind.dropdown,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['TCK-201', 'Open', 'High', 'No'],
      ['TCK-202', 'In Progress', 'Critical', 'No'],
      ['TCK-203', 'Resolved', 'Medium', 'Yes'],
      ['TCK-204', 'Closed', 'Low', 'Yes'],
      ['TCK-205', 'Open', 'Medium', 'No'],
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

  void _toggleLockArchived(bool value) {
    setState(() {
      _lockArchived = value;
      _gridKey = GlobalKey<GridSheetState>();
    });
    status.value = value
        ? 'Archived is locked again — editable: false renders plain read-only text with no arrow.'
        : 'Archived unlocked — editable: true, so it now opens the same popup menu as Status/Priority.';
  }
}
