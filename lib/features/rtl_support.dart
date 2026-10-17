import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Showcases right-to-left (RTL) layout support via `GridSheet.direction`.
/// Toggling direction mirrors column order, header/cell alignment, borders,
/// pin sides (`pinnedLeft`/`pinnedRight` stay logical — "reading-start"/
/// "reading-end" — flipping which physical edge they render at), resize and
/// drag-to-fill handles, column drag-to-reorder, horizontal scrolling and
/// virtualization, pagination icons, sort-icon placement, and the
/// row-expansion chevron — all together, live. Column identity (keys, sort
/// state, filters, selection) always stays keyed to logical position, never
/// physical screen position.
class RtlSupport extends StatefulWidget {
  const RtlSupport({super.key});

  @override
  State<RtlSupport> createState() => _RtlSupportState();
}

class _RtlSupportState extends State<RtlSupport> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status =
      ValueNotifier('direction: GridSheetDirection.rightToLeft');
  GridSheetDirection _direction = GridSheetDirection.rightToLeft;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Right-to-Left (RTL) Support',
      icon: Icons.format_textdirection_r_to_l,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'RTL',
            icon: Icons.format_textdirection_r_to_l,
            color: context.accents.indigo,
            value: _direction == GridSheetDirection.rightToLeft,
            onChanged: _toggleDirection,
            tooltip: 'Switch the whole grid between left-to-right and '
                'right-to-left layout',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        direction: _direction,
        configuration: const GridSheetConfiguration(
          enableColumnReorder: true,
          enableCellNavigation: true,
          enableCellSelection: true,
          showColumnFilters: true,
          rowsPerPage: 5,
        ),
        rowExpansionConfiguration:
            const GridSheetRowExpansionConfiguration(enabled: true),
        autoFillConfiguration:
            const GridSheetAutoFillConfiguration(enabled: true),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
        rowStateIndicatorBuilder: (row) {
          if (row.isModified) {
            return GridSheetRowStateIndicator(
              icon: Icon(Icons.edit, color: context.accents.orange, size: 14),
            );
          }
          return null;
        },
        onCellsSelected: (event) {
          status.value = 'Selected: ${event.cells.length} cell(s) — '
              'still keyed to the same columns regardless of direction';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = [
      'ID',
      'NAME',
      'DEPARTMENT',
      'SALARY',
      'STATUS',
    ];
    const titles = [
      'ID',
      'Name',
      'Department',
      'Salary',
      'Status',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.text(),
    ];
    const widths = [90.0, 170.0, 150.0, 120.0, 110.0];

    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        sortable: true,
        resizable: true,
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.end
            : TextAlign.start,
        pinnedLeft: i == 0,
        pinnedRight: i == names.length - 1,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = <List<Object?>>[
      ['EMP-001', 'Alice Johnson', 'Engineering', 95000.0, 'Active'],
      ['EMP-002', 'Bob Smith', 'Engineering', 118000.0, 'Active'],
      ['EMP-003', 'ليلى أحمد', 'Sales', 88000.0, 'On Leave'],
      ['EMP-004', 'David Lee', 'Sales', 102000.0, 'Active'],
      ['EMP-005', 'דוד כהן', 'Marketing', 76000.0, 'Active'],
      ['EMP-006', 'Frank Miller', 'Marketing', 71000.0, 'Inactive'],
      ['EMP-007', 'Grace Kim', 'HR', 68000.0, 'Active'],
      ['EMP-008', 'سارة محمد', 'Finance', 99000.0, 'Active'],
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

  void _toggleDirection(bool value) {
    setState(() => _direction = value
        ? GridSheetDirection.rightToLeft
        : GridSheetDirection.leftToRight);
    status.value = 'direction: '
        '${_direction == GridSheetDirection.rightToLeft ? 'GridSheetDirection.rightToLeft' : 'GridSheetDirection.leftToRight'}';
  }
}
