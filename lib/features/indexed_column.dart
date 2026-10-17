import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class IndexColumnDemo extends StatefulWidget {
  const IndexColumnDemo({super.key});

  @override
  State<IndexColumnDemo> createState() => _IndexColumnDemoState();
}

class _IndexColumnDemoState extends State<IndexColumnDemo> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'GridSheet.indexColumn configures the built-in row-number column — only '
    'title/width/pinnedRight/textAlign/visible are honored from it.',
  );

  bool _visible = true;
  bool _pinnedRight = false;
  bool _rowStateColor = false;
  bool _rowStateIcon = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Index Column',
      icon: Icons.format_list_numbered_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Visible',
            icon: Icons.visibility_outlined,
            color: context.accents.blue,
            value: _visible,
            onChanged: _toggleVisible,
            tooltip:
                'GridSheetColumn.visible: false hides the index column, same as passing null',
          ),
          DemoToggleButton(
            label: 'Pinned Right',
            icon: Icons.push_pin_outlined,
            color: context.accents.deepPurple,
            value: _pinnedRight,
            onChanged: _togglePinnedRight,
            tooltip:
                'GridSheetColumn.pinnedRight: true pins the index column to the right instead of the left',
          ),
          DemoToggleButton(
            label: 'Row State Color',
            icon: Icons.color_lens,
            color: context.accents.yellow,
            value: _rowStateColor,
            onChanged: _toggleRowStateColor,
            tooltip:
                'Display a color in the index column when the row is modified.',
          ),
          DemoToggleButton(
            label: 'Row State Icon',
            icon: Icons.edit,
            color: context.accents.red,
            value: _rowStateIcon,
            onChanged: _toggleRowStateIcon,
            tooltip:
                'Display an icon in the index column when the row is modified.',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        indexColumn: GridSheetColumn(
          key: const ValueKey('unused'),
          index: -1,
          name: 'unused',
          title: 'S.No',
          type: GridSheetColumnType.text(),
          width: 56,
          visible: _visible,
          pinnedRight: _pinnedRight,
        ),
        configuration: const GridSheetConfiguration(
          enableCellSelection: true,
          enableRowSelectionOnFirstColumnTap: true,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
        onRowsSelected: (event) {
          status.value =
              'Selected ${event.keys.length} row(s) — rows are selected from the '
              'index column, left or right; with it hidden, a cell tap selects '
              'the cell instead.';
        },
        rowStateIndicatorBuilder: (row) {
          if (!row.isModified) return null; // default look

          return GridSheetRowStateIndicator(
            color: _rowStateColor
                ? context.accents.yellow.withValues(alpha: 0.25)
                : null,
            icon: _rowStateIcon
                ? Icon(Icons.edit, color: context.accents.orange, size: 16)
                : null,
          );
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['TASK', 'ASSIGNEE', 'PRIORITY'];
    const titles = ['Task', 'Assignee', 'Priority'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(options: ['Low', 'Medium', 'High']),
    ];
    const widths = [220.0, 140.0, 120.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Design onboarding flow', 'Ava', 'High'],
      ['Fix checkout bug', 'Liam', 'High'],
      ['Write release notes', 'Noah', 'Medium'],
      ['Update dependencies', 'Maya', 'Low'],
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

  void _toggleVisible(bool value) {
    setState(() => _visible = value);
    status.value = value
        ? 'visible: true — the index column is shown again.'
        : 'visible: false — the index column is hidden, same as passing indexColumn: null.';
  }

  void _togglePinnedRight(bool value) {
    setState(() => _pinnedRight = value);
    status.value = value
        ? 'pinnedRight: true — the index column moved to the right edge.'
        : 'pinnedRight: false — the index column is back on the left.';
  }

  void _toggleRowStateColor(bool value) {
    setState(() => _rowStateColor = value);
    status.value = value
        ? 'rowStateIndicatorBuilder color — modified rows are highlighted in the index column.'
        : 'rowStateIndicatorBuilder color — modified rows are no longer highlighted in the index column.';
  }

  void _toggleRowStateIcon(bool value) {
    setState(() => _rowStateIcon = value);
    status.value = value
        ? 'rowStateIndicatorBuilder icon — modified rows show an icon in the index column.'
        : 'rowStateIndicatorBuilder icon — modified rows no longer show an icon in the index column.';
  }
}
