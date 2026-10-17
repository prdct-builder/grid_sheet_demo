// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';

class TestingGridSheetFeatures extends StatefulWidget {
  final GridSheetManager gridManager;

  const TestingGridSheetFeatures({super.key, required this.gridManager});

  @override
  State<TestingGridSheetFeatures> createState() =>
      _TestingGridSheetFeaturesState();
}

class _TestingGridSheetFeaturesState extends State<TestingGridSheetFeatures> {
  GridSheetSnapshot? _snapshot;

  late GridSheetManager gridManager;

  /// Resolves a user-typed column name to its key (the manager's column
  /// methods are key-addressed), or `null` if no column has that name.
  ValueKey<String>? _columnKey(String name) {
    final matches = gridManager.columns.findByNames([name]);
    return matches.isEmpty ? null : matches.first.key;
  }

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    gridManager = widget.gridManager;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSection('Theme', [
                const LoadTimeLabel(),
                _buildThemeToggleButton(),
                _buildButton(
                  'Save',
                  Icons.save,
                  Colors.pink,
                  () => commitChanges(),
                ),
              ]),
              _buildDivider(),
              _buildSection('Row Operations', [
                _buildButton(
                  'Insert Row',
                  Icons.add,
                  Colors.green,
                  () => _insertRow(context),
                ),
                _buildButton(
                  'Delete Row',
                  Icons.delete,
                  Colors.red,
                  () => _deleteSelectedRows(context),
                ),
                _buildButton(
                  'Duplicate Row',
                  Icons.copy,
                  Colors.blue,
                  () => _duplicateSelectedRows(context),
                ),
                _buildButton(
                  'Update Row',
                  Icons.edit,
                  Colors.orange,
                  () => _updateRow(context),
                ),
                _buildButton(
                  'Select All Rows',
                  Icons.select_all,
                  Colors.purple,
                  () => _selectAllRows(),
                ),
                _buildButton(
                  'Deselect Rows',
                  Icons.clear,
                  Colors.grey,
                  () => _deselectAllRows(),
                ),
              ]),
              _buildDivider(),
              _buildSection('Column Operations', [
                _buildButton(
                  'Insert Column',
                  Icons.view_column,
                  Colors.green,
                  () => _insertColumn(context),
                ),
                _buildButton(
                  'Delete Column',
                  Icons.delete_sweep,
                  Colors.red,
                  () => _deleteSelectedColumns(context),
                ),
                _buildButton(
                  'Hide Column',
                  Icons.visibility_off,
                  Colors.orange,
                  () => _hideColumn(context),
                ),
                _buildButton(
                  'Show Column',
                  Icons.visibility,
                  Colors.green,
                  () => _showColumn(context),
                ),
                _buildButton(
                  'Freeze Columns',
                  Icons.lock,
                  Colors.blue,
                  () => _freezeColumns(context),
                ),
                _buildButton(
                  'Auto-fit Width',
                  Icons.fit_screen,
                  Colors.purple,
                  () => _autoFitColumn(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Cell Operations', [
                _buildButton(
                  'Update Cell',
                  Icons.edit_note,
                  Colors.blue,
                  () => _updateCell(context),
                ),
                _buildButton(
                  'Clear Cells',
                  Icons.clear_all,
                  Colors.red,
                  () => _clearSelectedCells(),
                ),
                _buildButton(
                  'Fill Cells',
                  Icons.format_color_fill,
                  Colors.green,
                  () => _fillCells(context),
                ),
                _buildButton(
                  'Find & Replace',
                  Icons.find_replace,
                  Colors.orange,
                  () => _findAndReplace(context),
                ),
                _buildButton(
                  'Copy',
                  Icons.content_copy,
                  Colors.purple,
                  () => _copyCells(),
                ),
                _buildButton(
                  'Paste',
                  Icons.content_paste,
                  Colors.purple,
                  () => _pasteCells(),
                ),
              ]),
              _buildDivider(),
              _buildSection('Sorting', [
                _buildButton(
                  'Sort Asc',
                  Icons.arrow_upward,
                  Colors.green,
                  () => _sortColumn(context, GridSheetSortDirection.asc),
                ),
                _buildButton(
                  'Sort Desc',
                  Icons.arrow_downward,
                  Colors.red,
                  () => _sortColumn(context, GridSheetSortDirection.desc),
                ),
                _buildButton(
                  'Clear Sort',
                  Icons.clear,
                  Colors.grey,
                  () => _clearSort(),
                ),
              ]),
              _buildDivider(),
              _buildSection('Filtering', [
                _buildButton(
                  'Apply Filter',
                  Icons.filter_alt,
                  Colors.blue,
                  () => _applyFilter(context),
                ),
                _buildButton(
                  'Filter Contains',
                  Icons.search,
                  Colors.green,
                  () => _filterContains(context),
                ),
                _buildButton(
                  'Filter Equals',
                  Icons.check,
                  Colors.orange,
                  () => _filterEquals(context),
                ),
                _buildButton(
                  'Clear Filter',
                  Icons.filter_alt_off,
                  Colors.red,
                  () => _clearFilter(context),
                ),
                _buildButton(
                  'Clear All Filters',
                  Icons.clear_all,
                  Colors.red,
                  () => _clearAllFilters(),
                ),
              ]),
              _buildDivider(),
              _buildSection('Pagination', [
                _buildButton(
                  'First Page',
                  Icons.first_page,
                  Colors.blue,
                  () => _goToPage(1),
                ),
                _buildButton(
                  'Previous',
                  Icons.chevron_left,
                  Colors.blue,
                  () => _previousPage(),
                ),
                _buildButton(
                  'Next',
                  Icons.chevron_right,
                  Colors.blue,
                  () => _nextPage(),
                ),
                _buildButton(
                  'Last Page',
                  Icons.last_page,
                  Colors.blue,
                  () => _goToLastPage(),
                ),
                _buildButton(
                  'Go To Page',
                  Icons.pages,
                  Colors.purple,
                  () => _goToPageDialog(context),
                ),
                _buildButton(
                  'Change Per Page',
                  Icons.numbers,
                  Colors.orange,
                  () => _changeRowsPerPage(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Selection', [
                _buildButton(
                  'Select All Cells',
                  Icons.select_all,
                  Colors.purple,
                  () => _selectAllCells(),
                ),
                _buildButton(
                  'Deselect All',
                  Icons.deselect,
                  Colors.grey,
                  () => _deselectAll(),
                ),
                _buildButton(
                  'Select Row Range',
                  Icons.table_rows,
                  Colors.blue,
                  () => _selectRowRange(context),
                ),
                _buildButton(
                  'Select Column',
                  Icons.view_column,
                  Colors.green,
                  () => _selectColumn(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Conditional Formatting', [
                _buildButton(
                  'Add Rule',
                  Icons.format_paint,
                  Colors.green,
                  () => _addFormatRule(context),
                ),
                _buildButton(
                  'Clear All Rules',
                  Icons.delete_sweep,
                  Colors.red,
                  () => _clearAllFormatRules(),
                ),
                _buildButton(
                  'Highlight Rows',
                  Icons.highlight,
                  Colors.yellow,
                  () => _highlightRows(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Row Heights', [
                _buildButton(
                  'Set Row Height',
                  Icons.height,
                  Colors.blue,
                  () => _setRowHeight(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Column Width', [
                _buildButton(
                  'Set Width',
                  Icons.width_full,
                  Colors.blue,
                  () => _setColumnWidth(context),
                ),
                _buildButton(
                  'Get Widths',
                  Icons.info,
                  Colors.purple,
                  () => _getColumnWidths(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Column Reorder', [
                _buildButton(
                  'Rename Columns',
                  Icons.edit,
                  Colors.red,
                  () => _renameColumns(context),
                ),
                _buildButton(
                  'Reorder Columns',
                  Icons.swap_horiz,
                  Colors.blue,
                  () => _reorderColumns(context),
                ),
                _buildButton(
                  'Reset Order',
                  Icons.restore,
                  Colors.orange,
                  () => _resetColumnOrder(),
                ),
                _buildButton(
                  'Set Order',
                  Icons.reorder,
                  Colors.green,
                  () => _setColumnOrder(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Row Reorder', [
                _buildButton(
                  'Reorder Rows',
                  Icons.swap_vert,
                  Colors.blue,
                  () => _reorderRows(context),
                ),
                _buildButton(
                  'Reorder by Keys',
                  Icons.vpn_key,
                  Colors.indigo,
                  () => _reorderRowsByKeys(context),
                ),
                _buildButton(
                  'Reset Row Order',
                  Icons.restore,
                  Colors.orange,
                  () => _resetRowOrder(),
                ),
              ]),
              _buildDivider(),
              _buildSection('Layout', [
                _buildButton(
                  'Toggle Filters',
                  Icons.filter_list,
                  Colors.teal,
                  () => _toggleLayoutFlag(
                    (c) => c.copyWith(showColumnFilters: !c.showColumnFilters),
                  ),
                ),
                _buildButton(
                  'Toggle Header',
                  Icons.view_headline,
                  Colors.indigo,
                  () => _toggleLayoutFlag(
                    (c) =>
                        c.copyWith(showColumnHeaderRow: !c.showColumnHeaderRow),
                  ),
                ),
                _buildButton(
                  'Toggle Col Reorder',
                  Icons.swap_horiz,
                  Colors.blue,
                  () => _toggleLayoutFlag(
                    (c) =>
                        c.copyWith(enableColumnReorder: !c.enableColumnReorder),
                  ),
                ),
                _buildButton(
                  'Toggle Row Reorder',
                  Icons.swap_vert,
                  Colors.blue,
                  () => _toggleLayoutFlag(
                    (c) => c.copyWith(enableRowReorder: !c.enableRowReorder),
                  ),
                ),
                _buildButton(
                  'Toggle Row Hover',
                  Icons.mouse,
                  Colors.purple,
                  () => _toggleLayoutFlag(
                    (c) => c.copyWith(enableRowHover: !c.enableRowHover),
                  ),
                ),
                _buildButton(
                  'Toggle Row Borders',
                  Icons.border_horizontal,
                  Colors.grey,
                  () => _toggleLayoutFlag(
                    (c) => c.copyWith(showRowBorders: !c.showRowBorders),
                  ),
                ),
                _buildButton(
                  'Toggle Col Borders',
                  Icons.border_vertical,
                  Colors.grey,
                  () => _toggleLayoutFlag(
                    (c) => c.copyWith(showColumnBorders: !c.showColumnBorders),
                  ),
                ),
              ]),
              _buildDivider(),
              _buildSection('Reload', [
                _buildButton(
                  'Reload',
                  Icons.refresh,
                  Colors.teal,
                  () => _reload(context),
                ),
                _buildButton(
                  'Start Auto',
                  Icons.play_circle_outline,
                  Colors.green,
                  () => _startAutoReload(context),
                ),
                _buildButton(
                  'Stop Auto',
                  Icons.pause_circle_outline,
                  Colors.red,
                  () => _stopAutoReload(context),
                ),
                _buildButton(
                  'Auto Status',
                  Icons.info_outline,
                  Colors.blue,
                  () => _showAutoReloadStatus(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Export', [
                _buildButton(
                  'Export CSV',
                  Icons.file_download,
                  Colors.green,
                  () => _exportCSV(context),
                ),
                _buildButton(
                  'Export JSON',
                  Icons.data_object,
                  Colors.blue,
                  () => _exportJSON(context),
                ),
                _buildButton(
                  'Export Page JSON',
                  Icons.data_object,
                  Colors.blue,
                  () => _exportCurrentPageJSON(context),
                ),
                _buildButton(
                  'Get Changed',
                  Icons.compare_arrows,
                  Colors.orange,
                  () => _getChangedRows(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Statistics', [
                _buildButton(
                  'Column Stats',
                  Icons.analytics,
                  Colors.purple,
                  () => _getColumnStats(context),
                ),
                _buildButton(
                  'Row Count',
                  Icons.numbers,
                  Colors.blue,
                  () => _showRowCount(context),
                ),
                _buildButton(
                  'Selection Info',
                  Icons.info,
                  Colors.green,
                  () => _showSelectionInfo(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Snapshot', [
                _buildButton(
                  'Create Snapshot',
                  Icons.camera_alt,
                  Colors.blue,
                  () => _createSnapshot(context),
                ),
                _buildButton(
                  'Restore Snapshot',
                  Icons.restore_page,
                  Colors.orange,
                  () => _restoreSnapshot(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Undo', [
                _buildButton(
                  'Undo Row',
                  Icons.undo,
                  Colors.orange,
                  () => _undoSelectedRow(context),
                ),
                _buildButton(
                  'Undo All',
                  Icons.restore_page,
                  Colors.red,
                  () => _undoAllChanges(context),
                ),
              ]),
              _buildDivider(),
              _buildSection('Advanced', [
                _buildButton(
                  'Find Cells',
                  Icons.search,
                  Colors.purple,
                  () => _findCells(context),
                ),
                _buildButton(
                  'Group By',
                  Icons.group_work,
                  Colors.green,
                  () => _groupByColumn(context),
                ),
                _buildButton(
                  'Clear Range',
                  Icons.clear_all,
                  Colors.red,
                  () => _clearCellRange(context),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleButton() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (_, themeMode, __) {
        final isDark = themeMode == ThemeMode.dark;
        return _buildButton(
          isDark ? 'Light Mode' : 'Dark Mode',
          isDark ? Icons.light_mode : Icons.dark_mode,
          Colors.indigo,
          () {
            appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
          },
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Text(title,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ),
        Row(children: buttons),
      ],
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: label,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 26),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 32),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Future<void> commitChanges() async {
    final insertedMaps = gridManager.data.toMaps(
      gridManager.changes.inserted,
    );
    final modifiedMaps = gridManager.data.toMaps(
      gridManager.changes.modified,
    );
    final deletedMaps = gridManager.data.toMaps(gridManager.changes.deleted);

    log('Inserted: $insertedMaps, length: ${insertedMaps.length}',
        name: 'GridSheetTestingToolbar');
    log('Modified: $modifiedMaps, length: ${modifiedMaps.length}',
        name: 'GridSheetTestingToolbar');
    log('Deleted: $deletedMaps, length: ${deletedMaps.length}',
        name: 'GridSheetTestingToolbar');
  }

  void _insertRow(BuildContext context) async {
    final int rowsCount = gridManager.rows.all.length;
    final key = '${GridSheetConstants.rowKeyStartsWith}${rowsCount + 1}';
    final row = GridSheetRow(
      key: ValueKey(key),
      index: rowsCount,
      data: List.filled(gridManager.columns.count, null),
      state: GridSheetRowState.inserted,
    );

    final insertIndex = gridManager.selection.rowIndex;
    final targetKey = insertIndex < gridManager.rows.all.length
        ? gridManager.rows.all[insertIndex].key
        : null;
    await gridManager.rows.insertAt(targetKey, [row]);
    if (!context.mounted) return;
    _showSnackBar(context, 'Row inserted');
  }

  void _deleteSelectedRows(BuildContext context) async {
    if (gridManager.selection.rowKeys.isEmpty) {
      _showSnackBar(context, 'No rows selected');
      return;
    }
    final deleted = await gridManager.rows.delete(
      gridManager.selection.rowKeys.toList(),
    );
    if (!context.mounted) return;
    _showSnackBar(context, '${deleted.length} rows deleted');
  }

  void _duplicateSelectedRows(BuildContext context) async {
    List<ValueKey<String>> selectedRowKeys = gridManager.selection.rowKeys;
    if (selectedRowKeys.isEmpty) {
      _showSnackBar(context, 'No rows selected');
      return;
    }

    List<ValueKey<String>> newRowKeys = [];
    final int rowsCount = gridManager.rows.all.length;
    for (int index = 0; index < selectedRowKeys.length; index++) {
      final key =
          '${GridSheetConstants.rowCopyKeyStartsWith}${rowsCount + index + 1}';
      newRowKeys.add(ValueKey(key));
    }

    await gridManager.rows.duplicate(selectedRowKeys, newRowKeys);
    if (!context.mounted) return;
    _showSnackBar(context, 'Rows duplicated');
  }

  void _updateRow(BuildContext context) async {
    if (gridManager.selection.rowKeys.isEmpty) {
      _showSnackBar(context, 'Select a row first');
      return;
    }
    final rowKey = gridManager.selection.rowKeys.last;
    final row = gridManager.rows.find(rowKey);
    if (row != null) {
      final newData = List.filled(row.data.length, 'Updated');
      gridManager.rows.update(rowKey, newData);
      _showSnackBar(context, 'Row updated');
    }
  }

  void _selectAllRows() {
    final allKeys = gridManager.rows.all.map((r) => r.key).toList();
    gridManager.selection.selectRows(allKeys);
  }

  void _deselectAllRows() {
    final allKeys = gridManager.selection.rowKeys.toList();
    gridManager.selection.deselectRows(allKeys);
  }

  // ==================== COLUMN OPERATIONS ====================

  void _insertColumn(BuildContext context) async {
    final int colsCount = gridManager.columns.count;
    final key = '${GridSheetConstants.columnCopyKeyStartsWith}${colsCount + 1}';
    final newColumn = GridSheetColumn(
      key: ValueKey(key),
      name: 'NewColumn',
      title: 'New Column',
      index: colsCount,
      width: 150,
      type: GridSheetColumnType.formula(),
    );
    await gridManager.columns.insertAt(
      null,
      [newColumn],
      defaultValues: ['=SUM(E1:F3)'],
    );
    if (!context.mounted) return;
    _showSnackBar(context, 'Column inserted');
  }

  void _deleteSelectedColumns(BuildContext context) async {
    if (gridManager.selection.columnKeys.isEmpty) {
      _showSnackBar(context, 'No columns selected');
      return;
    }
    final deleted = await gridManager.columns.delete(
      gridManager.selection.columnKeys,
    );
    if (!context.mounted) return;
    _showSnackBar(context, '${deleted.length} columns deleted');
  }

  void _hideColumn(BuildContext context) async {
    final name = await _showInputDialog(context, 'Enter column name to hide');
    if (name != null && name.isNotEmpty) {
      await gridManager.columns.hide(
          gridManager.columns.findByNames([name]).map((c) => c.key).toList());
      if (!context.mounted) return;
      _showSnackBar(context, 'Column hidden');
    }
  }

  void _showColumn(BuildContext context) async {
    final name = await _showInputDialog(context, 'Enter column name to show');
    if (name != null && name.isNotEmpty) {
      await gridManager.columns.show(
          gridManager.columns.findByNames([name]).map((c) => c.key).toList());
      if (!context.mounted) return;
      _showSnackBar(context, 'Column shown');
    }
  }

  void _freezeColumns(BuildContext context) async {
    final indexStr = await _showInputDialog(
      context,
      'Enter column index to freeze up to',
    );
    if (indexStr != null && indexStr.isNotEmpty) {
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < gridManager.columns.count) {
        final result = await gridManager.columns.pin(
          leftKeys: gridManager.columns.all
              .take(index + 1)
              .map((c) => c.key)
              .toList(),
        );
        if (!context.mounted) return;
        _showSnackBar(context, result ?? 'Columns frozen');
      }
    }
  }

  void _autoFitColumn(BuildContext context) async {
    final name = await _showInputDialog(
      context,
      'Enter column name to auto-fit',
    );
    if (!context.mounted) return;
    if (name != null && name.isNotEmpty) {
      gridManager.columns.autoFitWidths(
          gridManager.columns.findByNames([name]).map((c) => c.key).toList());
      _showSnackBar(context, 'Column width auto-fitted');
    }
  }

  void _updateCell(BuildContext context) async {
    if (gridManager.selection.cellKeys.isEmpty) {
      _showSnackBar(context, 'Select a cell first');
      return;
    }
    final cellKey = gridManager.selection.cellKeys.first;
    final value = await _showInputDialog(context, 'Enter new value');
    if (!context.mounted) return;
    if (value != null) {
      gridManager.cells.update(
        rowKey: cellKey.rowKey,
        columnKey: cellKey.columnKey,
        value: value,
      );
      _showSnackBar(context, 'Cell updated');
    }
  }

  void _clearSelectedCells() {
    gridManager.cells.clear(gridManager.selection.cellKeys.toList());
  }

  void _fillCells(BuildContext context) async {
    if (gridManager.selection.cellKeys.isEmpty) {
      _showSnackBar(context, 'Select cells first');
      return;
    }
    final value = await _showInputDialog(context, 'Enter fill value');
    if (!context.mounted) return;
    if (value != null) {
      List<GridSheetCellUpdate> updates = [];
      for (var key in gridManager.selection.cellKeys) {
        updates.add(
          GridSheetCellUpdate(
            rowKey: key.rowKey,
            columnKey: key.columnKey,
            value: value,
          ),
        );
      }
      gridManager.cells.updateAll(updates);
      _showSnackBar(context, 'Cells filled');
    }
  }

  void _findAndReplace(BuildContext context) async {
    final find = await _showInputDialog(context, 'Find value');
    if (find == null || find.isEmpty) return;
    if (!context.mounted) return;

    final replace = await _showInputDialog(context, 'Replace with');
    if (replace == null) return;
    if (!context.mounted) return;

    final count = await gridManager.cells.findAndReplace(
      findValue: find,
      replaceValue: replace,
      matchCase: false,
      exactMatch: false,
    );
    if (!context.mounted) return;
    _showSnackBar(context, '$count cells replaced');
  }

  // Writes the selected cells to the system clipboard.
  Future<void> _copyCells() async {
    await gridManager.cells.copy();
  }

  // Pastes the system clipboard's text, starting at the first selected cell.
  Future<void> _pasteCells() async {
    final selected = gridManager.selection.cellKeys;
    if (selected.isEmpty) return;
    await gridManager.cells.paste(
      startRowKey: selected.first.rowKey,
      startColumnKey: selected.first.columnKey,
    );
  }

  // ==================== SORTING ====================
  void _sortColumn(
    BuildContext context,
    GridSheetSortDirection direction,
  ) async {
    final name = await _showInputDialog(context, 'Enter column name to sort');
    final key = name == null ? null : _columnKey(name);
    if (key != null) {
      await gridManager.sorting.sortBy(key, direction: direction);
      if (!context.mounted) return;
      _showSnackBar(context, 'Column sorted');
    }
  }

  void _clearSort() async {
    await gridManager.sorting.clear();
  }

  // ==================== FILTERING ====================
  void _applyFilter(BuildContext context) async {
    final column = await _showInputDialog(context, 'Column name');
    final key = column == null ? null : _columnKey(column);
    if (key == null) return;
    if (!context.mounted) return;

    final value = await _showInputDialog(context, 'Filter value');
    if (value == null) return;

    await gridManager.filters.add({
      key: [value],
    });
    if (!context.mounted) return;
    _showSnackBar(context, 'filter applied => $column: $value');
  }

  void _filterContains(BuildContext context) async {
    final column = await _showInputDialog(context, 'Column name');
    final key = column == null ? null : _columnKey(column);
    if (key == null) return;
    if (!context.mounted) return;

    final value = await _showInputDialog(context, 'Contains value');
    if (value == null) return;

    await gridManager.filters.add({
      key: [value],
    }, comparison: GridSheetFilterComparison.contains);
    if (!context.mounted) return;
    _showSnackBar(context, 'filter applied => $column: $value');
  }

  void _filterEquals(BuildContext context) async {
    final column = await _showInputDialog(context, 'Column name');
    final key = column == null ? null : _columnKey(column);
    if (key == null) return;
    if (!context.mounted) return;

    final value = await _showInputDialog(context, 'Equals value');
    if (value == null) return;

    await gridManager.filters.add({
      key: [value],
    }, comparison: GridSheetFilterComparison.exact);
    if (!context.mounted) return;
    _showSnackBar(context, 'filter applied => $column: $value');
  }

  void _clearFilter(BuildContext context) async {
    final name = await _showInputDialog(context, 'Column name to clear filter');
    final key = name == null ? null : _columnKey(name);
    if (key != null) {
      await gridManager.filters.clear(key);
      if (!context.mounted) return;
      _showSnackBar(context, 'filter cleared => $name');
    }
  }

  void _clearAllFilters() async {
    await gridManager.filters.clearAll();
  }

  // ==================== PAGINATION ====================

  void _goToPage(int page) async {
    await gridManager.pagination.goTo(page);
  }

  void _previousPage() {
    gridManager.pagination.previous();
  }

  void _nextPage() {
    gridManager.pagination.next();
  }

  void _goToLastPage() async {
    await gridManager.pagination.goTo(gridManager.pagination.totalPages);
  }

  void _goToPageDialog(BuildContext context) async {
    final pageStr = await _showInputDialog(
      context,
      'Enter page number (1-${gridManager.pagination.totalPages})',
    );
    if (pageStr != null && pageStr.isNotEmpty) {
      final page = int.tryParse(pageStr);
      if (page != null) {
        await gridManager.pagination.goTo(page);
      }
    }
  }

  void _changeRowsPerPage(BuildContext context) async {
    final countStr = await _showInputDialog(context, 'Rows per page');
    if (countStr != null && countStr.isNotEmpty) {
      final count = int.tryParse(countStr);
      if (count != null && count > 0) {
        await gridManager.pagination.setRowsPerPage(count);
        if (!context.mounted) return;
        _showSnackBar(context, 'Rows per page changed to $count');
      }
    }
  }

  // ==================== SELECTION ====================

  void _selectAllCells() {
    final allCells = <GridSheetCell>[];
    for (final row in gridManager.rows.all) {
      for (final column in gridManager.columns.all) {
        allCells.add(GridSheetCell(row.key, column.key));
      }
    }
    gridManager.selection.selectCells(allCells);
  }

  void _deselectAll() {
    gridManager.selection.deselectRows(gridManager.selection.rowKeys.toList());
    gridManager.selection
        .deselectColumns(gridManager.selection.columnKeys.toList());
    gridManager.selection
        .deselectCells(gridManager.selection.cellKeys.toList());
  }

  void _selectRowRange(BuildContext context) async {
    final startStr = await _showInputDialog(context, 'Start row index');
    if (startStr == null) return;
    if (!context.mounted) return;

    final endStr = await _showInputDialog(context, 'End row index');
    if (endStr == null) return;
    if (!context.mounted) return;

    final start = int.tryParse(startStr);
    final end = int.tryParse(endStr);

    if (start != null &&
        end != null &&
        start >= 0 &&
        start < gridManager.rows.all.length &&
        end >= 0 &&
        end < gridManager.rows.all.length) {
      final range = gridManager.rows.range(
        gridManager.rows.all[start].key,
        gridManager.rows.all[end].key,
      );
      gridManager.selection.selectRows(range.map((r) => r.key).toList());
      _showSnackBar(context, '${range.length} rows selected');
    }
  }

  void _selectColumn(BuildContext context) async {
    final name = await _showInputDialog(context, 'Column name to select');
    if (!context.mounted) return;
    if (name != null && name.isNotEmpty) {
      final columns = gridManager.columns.findByNames([name]);
      if (columns.isNotEmpty) {
        gridManager.selection.selectColumns([columns.first.key]);
        _showSnackBar(context, 'Column selected');
      }
    }
  }

  // ==================== CONDITIONAL FORMATTING ====================

  void _addFormatRule(BuildContext context) async {
    final expression = await _showInputDialog(
      context,
      'Expression (e.g., value > 100)',
    );
    if (expression == null || expression.isEmpty) return;

    final rule = GridSheetConditionalFormatRule(
      name: 'TestRule',
      scope: GridSheetFormatScope.row,
      expression: expression,
    );

    await gridManager.formatting.add(rule);
    if (!context.mounted) return;
    _showSnackBar(context, 'Format rule added');
  }

  void _clearAllFormatRules() async {
    await gridManager.formatting.clear();
  }

  void _highlightRows(BuildContext context) async {
    final valueStr = await _showInputDialog(
      context,
      'Highlight rows where any value contains',
    );
    if (valueStr == null || valueStr.isEmpty) return;

    final rule = GridSheetConditionalFormatRule(
      name: 'HighlightRule',
      scope: GridSheetFormatScope.row,
      expression: 'value == "$valueStr" ? "#00FF00" : null',
    );

    await gridManager.formatting.add(rule);
    if (!context.mounted) return;
    _showSnackBar(context, 'Highlight rule added');
  }

  // ==================== ROW HEIGHTS ====================

  void _setRowHeight(BuildContext context) async {
    if (gridManager.selection.rowKeys.isEmpty) {
      _showSnackBar(context, 'Select rows first');
      return;
    }

    final heightStr = await _showInputDialog(context, 'Enter row height');
    if (heightStr != null && heightStr.isNotEmpty) {
      final height = double.tryParse(heightStr);
      if (height != null) {
        final heights = <ValueKey<String>, double>{};
        for (final key in gridManager.selection.rowKeys) {
          heights[key] = height;
        }
        await gridManager.rows.setHeights(heights);
        if (!context.mounted) return;
        _showSnackBar(context, 'Row heights updated');
      }
    }
  }

  // ==================== COLUMN WIDTH ====================

  void _setColumnWidth(BuildContext context) async {
    final name = await _showInputDialog(context, 'Column name');
    if (name == null || name.isEmpty) return;
    if (!context.mounted) return;

    final widthStr = await _showInputDialog(context, 'Enter width');
    if (!context.mounted) return;
    if (widthStr != null && widthStr.isNotEmpty) {
      final width = double.tryParse(widthStr);
      if (width != null) {
        final key = _columnKey(name);
        if (key == null) return;
        gridManager.columns.setWidths({key: width});
        _showSnackBar(context, 'Column width set');
      }
    }
  }

  void _getColumnWidths(BuildContext context) {
    final widths = gridManager.columns.widths;
    _showDialog(context, 'Column Widths', widths.toString());
  }

  // ==================== COLUMN REORDER ====================

  void _reorderColumns(BuildContext context) async {
    final fromStr = await _showInputDialog(context, 'From index');
    if (fromStr == null) return;
    if (!context.mounted) return;

    final toStr = await _showInputDialog(context, 'To index');
    if (toStr == null) return;
    if (!context.mounted) return;

    final from = int.tryParse(fromStr);
    final to = int.tryParse(toStr);

    if (from != null &&
        to != null &&
        from >= 0 &&
        from < gridManager.columns.count &&
        to >= 0 &&
        to < gridManager.columns.count) {
      gridManager.columns.reorder(
        fromKey: gridManager.columns.all[from].key,
        toKey: gridManager.columns.all[to].key,
      );
      _showSnackBar(context, 'Columns reordered');
    }
  }

  void _resetColumnOrder() async {
    await gridManager.columns.resetOrder();
  }

  void _setColumnOrder(BuildContext context) async {
    final names = await _showInputDialog(
      context,
      'Column names (comma-separated)',
    );
    if (!context.mounted) return;
    if (names != null && names.isNotEmpty) {
      final nameList = names.split(',').map((n) => n.trim()).toList();
      gridManager.columns.setOrder(
          gridManager.columns.findByNames(nameList).map((c) => c.key).toList());
      _showSnackBar(context, 'Column order set');
    }
  }

  void _renameColumns(BuildContext context) async {
    final fromStr = await _showInputDialog(context, 'Rename column of');
    if (fromStr == null) return;
    if (!context.mounted) return;

    final toStr = await _showInputDialog(context, 'Rename column to');
    if (toStr == null) return;
    if (!context.mounted) return;

    final key = _columnKey(fromStr);
    if (key == null) return;
    gridManager.columns.rename({key: (newName: toStr, newTitle: toStr)});
    _showSnackBar(context, 'Columns renamed');
  }

  // ==================== ROW REORDER ====================

  void _reorderRows(BuildContext context) async {
    final fromStr = await _showInputDialog(context, 'From row index');
    if (fromStr == null) return;
    if (!context.mounted) return;

    final toStr = await _showInputDialog(context, 'To row index');
    if (toStr == null) return;
    if (!context.mounted) return;

    final from = int.tryParse(fromStr);
    final to = int.tryParse(toStr);

    if (from != null &&
        to != null &&
        from >= 0 &&
        from < gridManager.rows.all.length &&
        to >= 0 &&
        to < gridManager.rows.all.length) {
      gridManager.rows.reorder(
        fromKey: gridManager.rows.all[from].key,
        toKey: gridManager.rows.all[to].key,
      );
      _showSnackBar(context, 'Rows reordered ($from → $to)');
    }
  }

  void _reorderRowsByKeys(BuildContext context) async {
    final fromStr =
        await _showInputDialog(context, 'From row key (e.g. row_0)');
    if (fromStr == null || fromStr.isEmpty) return;
    if (!context.mounted) return;

    final toStr = await _showInputDialog(context, 'To row key (e.g. row_2)');
    if (toStr == null || toStr.isEmpty) return;
    if (!context.mounted) return;

    gridManager.rows.reorder(
      fromKey: ValueKey(fromStr),
      toKey: ValueKey(toStr),
    );
    _showSnackBar(context, 'Rows reordered ($fromStr → $toStr)');
  }

  void _resetRowOrder() {
    gridManager.rows.resetOrder();
  }

  // ==================== LAYOUT CONFIG ====================

  void _toggleLayoutFlag(
    GridSheetConfiguration Function(GridSheetConfiguration) updater,
  ) {
    gridManager.config.updateGrid(
      updater(gridManager.config.grid),
    );
  }

  // ==================== RELOAD ====================

  void _reload(BuildContext context) async {
    await gridManager.reload();
    if (!context.mounted) return;
    _showSnackBar(context, 'Grid reloaded');
  }

  void _startAutoReload(BuildContext context) {
    if (gridManager.autoReload.isActive) {
      _showSnackBar(context, 'Auto-reload is already active');
      return;
    }
    gridManager.autoReload.start();
    _showSnackBar(
      context,
      gridManager.autoReload.isActive
          ? 'Auto-reload started'
          : 'No reloadConfiguration set — auto-reload has no effect',
    );
  }

  void _stopAutoReload(BuildContext context) {
    if (!gridManager.autoReload.isActive) {
      _showSnackBar(context, 'Auto-reload is not active');
      return;
    }
    gridManager.autoReload.stop();
    _showSnackBar(context, 'Auto-reload stopped');
  }

  void _showAutoReloadStatus(BuildContext context) {
    final active = gridManager.autoReload.isActive;
    _showDialog(
      context,
      'Auto-Reload Status',
      active
          ? 'Active — schedule is running.'
          : 'Inactive — no schedule running.',
    );
  }

  // ==================== EXPORT ====================

  void _exportCSV(BuildContext context) {
    final csv = gridManager.data.toCsv();
    Clipboard.setData(ClipboardData(text: csv));
    _showSnackBar(context, 'CSV copied to clipboard');
  }

  void _exportJSON(BuildContext context) {
    final data = gridManager.data.toMaps(gridManager.rows.filtered);
    _showDialog(context, 'Export JSON', data.toString());
  }

  void _exportCurrentPageJSON(BuildContext context) {
    final data = gridManager.data.toMaps(gridManager.rows.currentPage);
    _showDialog(context, 'Export Page JSON', data.toString());
  }

  void _getChangedRows(BuildContext context) {
    final inserted = gridManager.changes.inserted.length;
    final modified = gridManager.changes.modified.length;
    final deleted = gridManager.changes.deleted.length;

    _showDialog(
      context,
      'Changed Rows',
      'Inserted: $inserted\nModified: $modified\nDeleted: $deleted',
    );
  }

  // ==================== STATISTICS ====================

  void _getColumnStats(BuildContext context) async {
    final name = await _showInputDialog(context, 'Column name for statistics');
    if (!context.mounted) return;
    final key = name == null ? null : _columnKey(name);
    if (key != null) {
      final stats = gridManager.data.statistics(key);
      _showDialog(context, 'Column Statistics', stats.toString());
    }
  }

  void _showRowCount(BuildContext context) {
    _showDialog(
      context,
      'Row Count',
      'Total: ${gridManager.rows.all.length}\n'
          'Filtered: ${gridManager.rows.filteredCount}\n'
          'Current Page: ${gridManager.rows.currentPage.length}',
    );
  }

  void _showSelectionInfo(BuildContext context) {
    _showDialog(
      context,
      'Selection Info',
      'Rows: ${gridManager.selection.rowKeys.length}\n'
          'Columns: ${gridManager.selection.columnKeys.length}\n'
          'Cells: ${gridManager.selection.cellKeys.length}',
    );
  }

  // ==================== SNAPSHOT ====================
  void _createSnapshot(BuildContext context) {
    setState(() {
      _snapshot = gridManager.snapshots.create();
    });
    _showSnackBar(context, 'Snapshot created');
  }

  void _restoreSnapshot(BuildContext context) async {
    if (_snapshot != null) {
      await gridManager.snapshots.restore(_snapshot!);
      if (!context.mounted) return;
      _showSnackBar(context, 'Snapshot restored');
    } else {
      _showSnackBar(context, 'No snapshot available');
    }
  }

  void _undoSelectedRow(BuildContext context) async {
    if (gridManager.selection.rowKeys.isEmpty) {
      _showSnackBar(context, 'Select a row first');
      return;
    }

    final rowKeys = gridManager.selection.rowKeys;
    await gridManager.changes.undo(rowKeys);
    if (!context.mounted) return;
    _showSnackBar(context, 'Row changes undone');
  }

  void _undoAllChanges(BuildContext context) async {
    if (gridManager.changes.all.isEmpty) {
      _showSnackBar(context, 'No changes to undo');
      return;
    }

    await gridManager.changes.undoAll();
    if (!context.mounted) return;
    _showSnackBar(context, 'All changes undone');
  }

  // ==================== ADVANCED ====================

  void _findCells(BuildContext context) async {
    final value = await _showInputDialog(context, 'Find value');
    if (value == null || value.isEmpty) return;
    if (!context.mounted) return;

    final cells = gridManager.cells.find(
      predicate: (cellValue, row, column) {
        return cellValue?.toString().contains(value) ?? false;
      },
    );

    _showDialog(context, 'Found Cells', '${cells.length} cells found');
  }

  void _groupByColumn(BuildContext context) async {
    final name = await _showInputDialog(context, 'Column name to group by');
    if (!context.mounted) return;
    final key = name == null ? null : _columnKey(name);
    if (key != null) {
      final groups = gridManager.data.groupBy(key);
      _showDialog(context, 'Groups', '${groups.length} unique groups found');
    }
  }

  void _clearCellRange(BuildContext context) async {
    final startRowStr = await _showInputDialog(context, 'Start row index');
    if (startRowStr == null) return;
    if (!context.mounted) return;

    final endRowStr = await _showInputDialog(context, 'End row index');
    if (endRowStr == null) return;
    if (!context.mounted) return;

    final startColStr = await _showInputDialog(context, 'Start column index');
    if (startColStr == null) return;
    if (!context.mounted) return;

    final endColStr = await _showInputDialog(context, 'End column index');
    if (endColStr == null) return;

    final startRow = int.tryParse(startRowStr);
    final endRow = int.tryParse(endRowStr);
    final startCol = int.tryParse(startColStr);
    final endCol = int.tryParse(endColStr);

    if (startRow != null &&
        endRow != null &&
        startCol != null &&
        endCol != null) {
      await gridManager.cells.clearRange(
        startRowKey: gridManager.rows.at(startRow).key,
        endRowKey: gridManager.rows.at(endRow).key,
        startColumnKey: gridManager.columns.at(startCol).key,
        endColumnKey: gridManager.columns.at(endCol).key,
      );
      if (!context.mounted) return;
      _showSnackBar(context, 'Cell range cleared');
    }
  }

  // ==================== HELPER METHODS ====================

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showInputDialog(BuildContext context, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
