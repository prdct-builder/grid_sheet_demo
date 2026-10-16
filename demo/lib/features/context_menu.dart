import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class ContextMenu extends StatefulWidget {
  const ContextMenu({super.key});

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'Right-click (or long-press on touch) a cell, a row header, or a column header to open its context menu.',
  );

  bool _rowContextMenuEnabled = true;
  bool _columnContextMenuEnabled = true;
  bool _cellContextMenuEnabled = true;
  bool _customChrome = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Context Menus',
      description:
          'contextMenuBuilder builds a fully custom right-click/long-press menu for a cell, row, or '
          'column target, with contextMenuConfiguration controlling its surrounding chrome.',
      icon: Icons.more_vert_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Row',
            icon: Icons.table_rows_outlined,
            color: context.accents.blue,
            value: _rowContextMenuEnabled,
            onChanged: _toggleRowContextMenu,
            tooltip: 'Enable right-click/long-press menu on row headers',
          ),
          DemoToggleButton(
            label: 'Column',
            icon: Icons.view_column_outlined,
            color: context.accents.teal,
            value: _columnContextMenuEnabled,
            onChanged: _toggleColumnContextMenu,
            tooltip: 'Enable right-click/long-press menu on column headers',
          ),
          DemoToggleButton(
            label: 'Cell',
            icon: Icons.grid_on_outlined,
            color: context.accents.deepPurple,
            value: _cellContextMenuEnabled,
            onChanged: _toggleCellContextMenu,
            tooltip: 'Enable right-click/long-press menu on cells',
          ),
          DemoActionButton(
            label: _customChrome ? 'Chrome: Custom' : 'Chrome: Default',
            icon: Icons.filter_none,
            color: context.accents.pink,
            onPressed: () => setState(() => _customChrome = !_customChrome),
            tooltip: 'Switch the menu\'s elevation, radius, and backdrop style',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: GridSheetConfiguration(
          enableCellSelection: true,
          enableRowSelectionOnFirstColumnTap: true,
          enableColumnSelection: true,
          enableMultiSelection: true,
          enableRowContextMenu: _rowContextMenuEnabled,
          enableColumnContextMenu: _columnContextMenuEnabled,
          enableCellContextMenu: _cellContextMenuEnabled,
          rowInsertPosition: GridSheetRowInsertPosition.below,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        contextMenuBuilder: _buildContextMenu,
        contextMenuConfiguration: _customChrome
            ? GridSheetContextMenuConfiguration(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.black54,
                backdropColor: Colors.black38,
              )
            : const GridSheetContextMenuConfiguration(),
        onLoaded: (event) => gridManager = event.gridManager,
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['TASK', 'OWNER', 'STATUS', 'DUE'];
    const titles = ['Task', 'Owner', 'Status', 'Due Date'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(options: ['Open', 'In Progress', 'Done']),
      GridSheetColumnType.text(),
    ];
    const widths = [200.0, 140.0, 140.0, 140.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        hasTextController: types[i].kind != GridSheetColumnKind.dropdown,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Design homepage banner', 'Ava Thompson', 'In Progress', '2026-07-10'],
      ['Fix login redirect bug', 'Liam Chen', 'Open', '2026-07-08'],
      ['Write API documentation', 'Noah Patel', 'Done', '2026-07-01'],
      ['Set up analytics dashboard', 'Maya Rodriguez', 'Open', '2026-07-15'],
      ['Review pull requests', 'Ethan Kim', 'In Progress', '2026-07-06'],
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

  Widget _menuCard(List<Widget> tiles) {
    return SizedBox(
      width: 240,
      child: Column(mainAxisSize: MainAxisSize.min, children: tiles),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: TextStyle(fontSize: 13, color: color)),
      onTap: onTap,
    );
  }

  Widget? _buildContextMenu(dynamic info) {
    if (info.target == GridSheetContextMenuTarget.cell) {
      final cellInfo = info as GridSheetCellContextInfo;
      final row = cellInfo.row;
      final column = cellInfo.column;
      final value = row.data[column.index]?.toString() ?? '';
      return _menuCard([
        _menuTile(Icons.copy, 'Copy value', () {
          Clipboard.setData(ClipboardData(text: value));
          status.value = 'Cell menu → Copy: "$value" copied to clipboard';
        }, color: context.accents.blue),
        _menuTile(Icons.delete_outline, 'Clear cell', () async {
          await cellInfo.gridManager.cells.clearRange(
            startRowKey: row.key,
            endRowKey: row.key,
            startColumnKey: column.key,
            endColumnKey: column.key,
          );
          status.value =
              'Cell menu → Clear: ${column.title} cleared on row ${row.index + 1}';
        }, color: context.accents.red),
        _menuTile(Icons.content_paste_outlined, 'Paste "TBD"', () {
          cellInfo.gridManager.cells
              .update(rowKey: row.key, columnKey: column.key, value: 'TBD');
          status.value = 'Cell menu → Paste: ${column.title} set to "TBD"';
        }, color: context.accents.green),
      ]);
    }

    if (info.target == GridSheetContextMenuTarget.row) {
      return _menuCard([
        _menuTile(
          Icons.copy_all_outlined,
          'Duplicate selected row(s)',
          _duplicateSelectedRows,
          color: context.accents.blue,
        ),
        _menuTile(
          Icons.delete_outline,
          'Delete selected row(s)',
          _deleteSelectedRows,
          color: context.accents.red,
        ),
      ]);
    }

    if (info.target == GridSheetContextMenuTarget.column) {
      return _menuCard([
        _menuTile(
          Icons.sort,
          'Sort ascending',
          _sortFirstColumnAscending,
          color: context.accents.blue,
        ),
        _menuTile(
          Icons.visibility_off_outlined,
          'Hide column',
          _hideSelectedColumns,
          color: context.accents.orange,
        ),
      ]);
    }

    return null;
  }

  void _toggleRowContextMenu(bool value) {
    setState(() => _rowContextMenuEnabled = value);
    status.value = value
        ? 'enableRowContextMenu: ON — right-click (long-press) a row header again.'
        : 'enableRowContextMenu: OFF — right-clicking a row header does nothing now.';
  }

  void _toggleColumnContextMenu(bool value) {
    setState(() => _columnContextMenuEnabled = value);
    status.value = value
        ? 'enableColumnContextMenu: ON — right-click (long-press) a column header again.'
        : 'enableColumnContextMenu: OFF — right-clicking a column header does nothing now.';
  }

  void _toggleCellContextMenu(bool value) {
    setState(() => _cellContextMenuEnabled = value);
    status.value = value
        ? 'enableCellContextMenu: ON — right-click (long-press) a cell again.'
        : 'enableCellContextMenu: OFF — right-clicking a cell does nothing now.';
  }

  Future<void> _duplicateSelectedRows() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      status.value = 'Row menu → select a row first';
      return;
    }
    final source =
        gridManager.rows.all.where((r) => keys.contains(r.key)).toList();
    final baseIndex = gridManager.rows.count;
    final duplicates = source.asMap().entries.map((entry) {
      final r = entry.value;
      return GridSheetRow(
        key: ValueKey(
            'ctxmenu_dup_${DateTime.now().microsecondsSinceEpoch}_${r.index}'),
        index: baseIndex + entry.key,
        data: List.from(r.data),
        height: r.height,
        state: GridSheetRowState.inserted,
      );
    }).toList();
    // GridSheetConfiguration.rowInsertPosition is set to .below above —
    // ensures duplicates land right after the originals.
    await gridManager.rows.insert(duplicates);
    if (!mounted) return;
    status.value =
        'Row menu → Duplicate: ${duplicates.length} row(s) duplicated';
  }

  Future<void> _deleteSelectedRows() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      status.value = 'Row menu → select a row first';
      return;
    }
    await gridManager.rows.delete(keys);
    if (!mounted) return;
    status.value = 'Row menu → Delete: ${keys.length} row(s) removed';
  }

  Future<void> _sortFirstColumnAscending() async {
    final columns = gridManager.columns.all;
    if (columns.isEmpty) return;
    await gridManager.sorting
        .sortBy(columns.first.key, direction: GridSheetSortDirection.asc);
    if (!mounted) return;
    status.value = 'Column menu → Sort ascending applied';
  }

  Future<void> _hideSelectedColumns() async {
    final keys = gridManager.selection.columnKeys;
    if (keys.isEmpty) {
      status.value = 'Column menu → select a column first';
      return;
    }
    final names = gridManager.columns.all
        .where((c) => keys.contains(c.key))
        .map((c) => c.name)
        .toList();
    await gridManager.columns.hide(keys.toList());
    if (!mounted) return;
    status.value = 'Column menu → Hide: ${names.join(", ")}';
  }
}
