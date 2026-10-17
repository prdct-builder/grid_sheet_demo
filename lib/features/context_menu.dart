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
    "Right-click a cell, a row's index cell, or a column header to open its context menu.",
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
            tooltip: 'Enable right-click menu on row headers',
          ),
          DemoToggleButton(
            label: 'Column',
            icon: Icons.view_column_outlined,
            color: context.accents.teal,
            value: _columnContextMenuEnabled,
            onChanged: _toggleColumnContextMenu,
            tooltip: 'Enable right-click menu on column headers',
          ),
          DemoToggleButton(
            label: 'Cell',
            icon: Icons.grid_on_outlined,
            color: context.accents.deepPurple,
            value: _cellContextMenuEnabled,
            onChanged: _toggleCellContextMenu,
            tooltip: 'Enable right-click menu on cells',
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
        sortable: true,
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

  // Every item closes its menu first (info.close()); the menu doesn't close
  // by itself when an item is tapped.
  Widget _menuTile(GridSheetContextMenuInfo info, IconData icon, String label,
      VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: TextStyle(fontSize: 13, color: color)),
      onTap: () {
        info.close();
        onTap();
      },
    );
  }

  Widget? _buildContextMenu(GridSheetContextMenuInfo info) {
    if (info is GridSheetCellContextInfo) {
      final row = info.row;
      final column = info.column;
      final value = info.cellValue?.toString() ?? '';
      return _menuCard([
        _menuTile(info, Icons.copy, 'Copy value', () {
          Clipboard.setData(ClipboardData(text: value));
          status.value = 'Cell menu → Copy: "$value" copied to clipboard';
        }, color: context.accents.blue),
        _menuTile(info, Icons.delete_outline, 'Clear cell', () async {
          await info.gridManager.cells.clearRange(
            startRowKey: row.key,
            endRowKey: row.key,
            startColumnKey: column.key,
            endColumnKey: column.key,
          );
          status.value =
              'Cell menu → Clear: ${column.title} cleared on row ${row.index + 1}';
        }, color: context.accents.red),
        _menuTile(info, Icons.edit_note_outlined, 'Set to "TBD"', () {
          info.gridManager.cells
              .update(rowKey: row.key, columnKey: column.key, value: 'TBD');
          status.value = 'Cell menu → ${column.title} set to "TBD"';
        }, color: context.accents.green),
      ]);
    }

    if (info is GridSheetRowContextInfo) {
      // Right-clicking inside the selection acts on all of it; otherwise
      // only on the row that was clicked.
      final keys = info.isSelected ? info.selectedRowKeys : [info.rowKey];
      final what = keys.length == 1 ? 'row' : '${keys.length} rows';
      return _menuCard([
        _menuTile(
          info,
          Icons.copy_all_outlined,
          'Duplicate $what',
          () => _duplicateRows(keys, after: info.rowKey),
          color: context.accents.blue,
        ),
        _menuTile(
          info,
          Icons.delete_outline,
          'Delete $what',
          () => _deleteRows(keys),
          color: context.accents.red,
        ),
      ]);
    }

    if (info is GridSheetColumnContextInfo) {
      final keys = info.isSelected ? info.selectedColumnKeys : [info.columnKey];
      return _menuCard([
        _menuTile(
          info,
          Icons.arrow_upward,
          'Sort ${info.columnTitle} ascending',
          () => _sortColumn(info.columnKey, GridSheetSortDirection.asc),
          color: context.accents.blue,
        ),
        _menuTile(
          info,
          Icons.arrow_downward,
          'Sort ${info.columnTitle} descending',
          () => _sortColumn(info.columnKey, GridSheetSortDirection.desc),
          color: context.accents.blue,
        ),
        _menuTile(
          info,
          Icons.visibility_off_outlined,
          keys.length == 1 ? 'Hide column' : 'Hide ${keys.length} columns',
          () => _hideColumns(keys),
          color: context.accents.orange,
        ),
      ]);
    }

    return null;
  }

  void _toggleRowContextMenu(bool value) {
    setState(() => _rowContextMenuEnabled = value);
    status.value = value
        ? 'enableRowContextMenu: ON — right-click a row header again.'
        : 'enableRowContextMenu: OFF — right-clicking a row header does nothing now.';
  }

  void _toggleColumnContextMenu(bool value) {
    setState(() => _columnContextMenuEnabled = value);
    status.value = value
        ? 'enableColumnContextMenu: ON — right-click a column header again.'
        : 'enableColumnContextMenu: OFF — right-clicking a column header does nothing now.';
  }

  void _toggleCellContextMenu(bool value) {
    setState(() => _cellContextMenuEnabled = value);
    status.value = value
        ? 'enableCellContextMenu: ON — right-click a cell again.'
        : 'enableCellContextMenu: OFF — right-clicking a cell does nothing now.';
  }

  Future<void> _duplicateRows(List<ValueKey<String>> keys,
      {required ValueKey<String> after}) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    // The copies go right below the row that was right-clicked.
    await gridManager.rows.duplicateAt(
      after,
      keys,
      [for (final (i, _) in keys.indexed) ValueKey('ctxmenu_dup_${stamp}_$i')],
      position: GridSheetRowInsertPosition.below,
    );
    if (!mounted) return;
    status.value = 'Row menu → Duplicate: ${keys.length} row(s) duplicated';
  }

  Future<void> _deleteRows(List<ValueKey<String>> keys) async {
    await gridManager.rows.delete(keys);
    if (!mounted) return;
    status.value = 'Row menu → Delete: ${keys.length} row(s) removed';
  }

  Future<void> _sortColumn(
      ValueKey<String> key, GridSheetSortDirection direction) async {
    await gridManager.sorting.sortBy(key, direction: direction);
    if (!mounted) return;
    final title = gridManager.columns.find(key)?.title ?? '';
    status.value = 'Column menu → Sort $title ${direction.name}';
  }

  Future<void> _hideColumns(List<ValueKey<String>> keys) async {
    final titles = [
      for (final key in keys) gridManager.columns.find(key)?.title ?? '',
    ];
    await gridManager.columns.hide(keys);
    if (!mounted) return;
    status.value = 'Column menu → Hide: ${titles.join(", ")}';
  }
}
