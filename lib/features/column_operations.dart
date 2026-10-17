import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class ColumnOperations extends StatefulWidget {
  const ColumnOperations({super.key});

  @override
  State<ColumnOperations> createState() => _ColumnOperationsState();
}

class _ColumnOperationsState extends State<ColumnOperations> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier('');
  int _extraColumnCount = 0;
  // Read at click time: the grid also clears the selection itself (after a
  // delete, reorder or filter) without calling onColumnsSelected.
  List<GridSheetColumn> get _selectedColumns => gridManager.selection.columns;
  bool _insertBeforeSelection = false;
  bool _showColumnHeaderRow = true;
  bool _customResizeHandle = false;
  bool _customDragFeedback = false;
  bool _stretchColumns = false;
  bool _enableUndoDelete = true;
  bool _wrapEnabled = false;

  GridSheetColumnInsertPosition get _insertPosition => _insertBeforeSelection
      ? GridSheetColumnInsertPosition.before
      : GridSheetColumnInsertPosition.after;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Column Operations',
      icon: Icons.settings_input_component_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Before Selection',
            icon: Icons.horizontal_distribute,
            color: context.accents.indigo,
            value: _insertBeforeSelection,
            onChanged: _toggleInsertPosition,
            tooltip: 'Insert the new column before (vs. after) the selection',
          ),
          DemoActionButton(
            label: 'Insert',
            icon: Icons.add_box_outlined,
            color: context.accents.green,
            onPressed: _insertColumn,
            tooltip: 'Insert a new blank column',
          ),
          DemoToggleButton(
            label: 'Undo Delete',
            icon: Icons.settings_backup_restore,
            color: context.accents.deepOrange,
            value: _enableUndoDelete,
            onChanged: _toggleUndoDelete,
            tooltip:
                'Enable enableUndoDelete — deleting columns shows a dismissible UNDO prompt instead of deleting immediately',
          ),
          DemoActionButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            color: context.accents.red,
            onPressed: _deleteSelectedColumns,
            tooltip: _enableUndoDelete
                ? 'Remove the selected column(s) — shows an UNDO prompt for 5 seconds'
                : 'Permanently remove the selected column',
          ),
          DemoActionButton(
            label: 'Hide',
            icon: Icons.visibility_off_outlined,
            color: context.accents.orange,
            onPressed: _hideSelectedColumns,
            tooltip: 'Hide the selected column',
          ),
          DemoActionButton(
            label: 'Show All',
            icon: Icons.visibility_outlined,
            color: context.accents.neutral,
            onPressed: _showAllColumns,
            tooltip: 'Make every hidden column visible again',
          ),
          DemoActionButton(
            label: 'Rename',
            icon: Icons.drive_file_rename_outline,
            color: context.accents.indigo,
            onPressed: _renameSelectedColumn,
            tooltip: 'Rename the selected column\'s title',
          ),
          DemoActionButton(
            label: 'Auto-fit Width',
            icon: Icons.fit_screen_outlined,
            color: context.accents.purple,
            onPressed: _autoFitSelectedColumns,
            tooltip:
                'Resize the selected (or all) columns to fit their content',
          ),
          DemoActionButton(
            label: _stretchColumns
                ? 'Stretch Columns: On'
                : 'Stretch Columns: Off',
            icon: Icons.fit_screen_outlined,
            color: context.accents.purple,
            onPressed: () => setState(() => _stretchColumns = !_stretchColumns),
            tooltip: 'Grow columns to fill leftover width',
          ),
          DemoToggleButton(
            label: 'Column Header',
            icon: Icons.view_headline,
            color: context.accents.teal,
            value: _showColumnHeaderRow,
            onChanged: _toggleShowColumnHeaderRow,
            tooltip: 'Show or hide the column header row',
          ),
          DemoActionButton(
            label: _customResizeHandle
                ? 'Resize Handle: Custom'
                : 'Resize Handle: Default',
            icon: Icons.drag_indicator,
            color: context.accents.pink,
            onPressed: () =>
                setState(() => _customResizeHandle = !_customResizeHandle),
            tooltip: 'Switch the column resize handle\'s style',
          ),
          DemoActionButton(
            label: _customDragFeedback
                ? 'Drag Feedback: Bold'
                : 'Drag Feedback: Subtle',
            icon: Icons.layers_outlined,
            color: context.accents.deepOrange,
            onPressed: () =>
                setState(() => _customDragFeedback = !_customDragFeedback),
            tooltip: 'Switch the drag-reorder feedback\'s elevation/opacity',
          ),
          DemoToggleButton(
            label: 'Wrap Text',
            icon: Icons.wrap_text,
            color: context.accents.blue,
            value: _wrapEnabled,
            onChanged: _toggleWrap,
            tooltip:
                'Toggle GridSheetColumn.wrap for the selected column(s) via '
                'columns.setWrap — all columns if none selected. Off (the '
                'default) truncates overflowing text with an ellipsis; on, '
                'text wraps and fills the row height.',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _initialColumns(),
        rows: _initialRows(),
        configuration: GridSheetConfiguration(
          enableMultiSelection: true,
          enableColumnSelection: true,
          enableColumnReorder: true,
          columnInsertPosition: _insertPosition,
          showColumnHeaderRow: _showColumnHeaderRow,
          stretchColumnsToFillWidth: _stretchColumns,
          enableUndoDelete: _enableUndoDelete,
        ),
        styleConfiguration: styleConfig(context).copyWith(
          resizeHandleColor: _customResizeHandle ? context.accents.pink : null,
          resizeHandleThickness: _customResizeHandle ? 5 : null,
          columnDragFeedbackElevation: _customDragFeedback ? 20 : null,
          dragFeedbackOpacity: _customDragFeedback ? 0.6 : null,
        ),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
        onColumnReorder: (event) {
          status.value = 'onColumnReorder: ${event.fromKey.value} took '
              '${event.toKey.value}\'s place (index ${event.fromIndex} '
              '→ ${event.toIndex})';
        },
        onColumnsSelected: (event) {
          status.value = 'Selected columns: ${event.names.join(", ")}';
        },
      ),
    );
  }

  List<GridSheetColumn> _initialColumns() {
    const names = [
      'PRODUCT',
      'CATEGORY',
      'PRICE',
      'STOCK',
      'SUPPLIER',
      'STATUS',
      'LAST_UPDATED',
    ];
    const titles = [
      'Product',
      'Category',
      'Price',
      'Stock',
      'Supplier',
      'Status',
      'Last Updated',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.datetime(),
    ];
    const widths = [160.0, 120.0, 80.0, 80.0, 120.0, 100.0, 140.0];
    const maxStretchWidths = [null, null, null, 90.0, null, 100.0, null];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        maxStretchWidth: maxStretchWidths[i],
        editable: names[i] != 'PRODUCT',
        sortable: true,
        resizable: true,
        textAlign: types[i].kind == GridSheetColumnKind.double ||
                types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _initialRows() {
    final raw = [
      [
        'Wireless Mouse',
        'Electronics',
        24.99,
        120,
        'Logitech',
        'Available',
        '2025-01-10'
      ],
      [
        'Standing Desk',
        'Furniture',
        349.00,
        18,
        'UpRise',
        'Low Stock',
        '2025-02-15'
      ],
      [
        'Notebook Pack',
        'Stationery',
        6.50,
        300,
        'Moleskine',
        'Available',
        '2025-03-01'
      ],
      [
        'Mechanical Keyboard',
        'Electronics',
        89.99,
        64,
        'Keychron',
        'Available',
        '2025-01-28'
      ],
      [
        'Office Chair',
        'Furniture',
        210.00,
        40,
        'Herman Miller',
        'Available',
        '2025-02-20'
      ],
      ['Desk Lamp', 'Furniture', 32.75, 90, 'Ikea', 'Available', '2025-03-12'],
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

  void _toggleInsertPosition(bool value) {
    setState(() => _insertBeforeSelection = value);
    status.value = 'columnInsertPosition: '
        '${value ? "before" : "after"}';
  }

  void _toggleShowColumnHeaderRow(bool value) {
    setState(() => _showColumnHeaderRow = value);
    status.value = 'showColumnHeaderRow: $value';
  }

  void _toggleUndoDelete(bool value) {
    setState(() => _enableUndoDelete = value);
    gridManager.config.updateGrid(
      gridManager.config.grid.copyWith(enableUndoDelete: value),
    );

    status.value = value
        ? 'enableUndoDelete: true — deleting columns now shows an UNDO prompt for 5 seconds'
        : 'enableUndoDelete: false — deleting columns is immediate and permanent';
  }

  void _toggleWrap(bool value) {
    setState(() => _wrapEnabled = value);
    final columns = _selectedColumns.isNotEmpty
        ? _selectedColumns
        : gridManager.columns.inScope(scope: GridSheetColumnScope.visible);
    gridManager.columns.setWrap(columns.map((c) => c.key).toList(), value);
    status.value = value
        ? 'columns.setWrap(..., true): text now wraps and fills the row height'
        : 'columns.setWrap(..., false): text now single-line, ellipsized on overflow';
  }

  Future<void> _insertColumn() async {
    _extraColumnCount++;
    final newColumn = GridSheetColumn(
      key: ValueKey('col_new_$_extraColumnCount'),
      index: gridManager.columns.count,
      name: 'NEW_COL_$_extraColumnCount',
      title: 'New Column $_extraColumnCount',
      type: GridSheetColumnType.text(),
      width: 150,
      sortable: true,
      resizable: true,
    );
    // GridSheetConfiguration.columnInsertPosition (set below from
    // _insertPosition) already governs where this lands.
    await gridManager.columns.insert([newColumn]);
    status.value = 'columns.insert(): added "${newColumn.title}"';
  }

  Future<void> _deleteSelectedColumns() async {
    final keys = gridManager.selection.columnKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select one or more columns first');
      return;
    }
    await gridManager.columns.delete(keys);
    status.value = 'columns.delete(): removed ${keys.length} column(s)';
  }

  Future<void> _hideSelectedColumns() async {
    final columns = _selectedColumns;
    if (columns.isEmpty) {
      showDemoSnackBar(context, 'Select a column first');
      return;
    }
    await gridManager.columns.hide(columns.map((c) => c.key).toList());
    status.value =
        'columns.hide(): hid ${columns.map((c) => c.name).join(", ")}';
  }

  Future<void> _showAllColumns() async {
    await gridManager.columns
        .show(gridManager.columns.all.map((c) => c.key).toList());
    status.value = 'columns.show(): all columns visible again';
  }

  Future<void> _renameSelectedColumn() async {
    final selected = _selectedColumns;
    if (selected.isEmpty) {
      showDemoSnackBar(context, 'Select a column first');
      return;
    }
    final column = selected.first;
    final newTitle =
        await showDemoInputDialog(context, 'New title for "${column.title}"');
    if (newTitle == null || newTitle.isEmpty) return;
    await gridManager.columns.rename({
      column.key: (newName: column.name, newTitle: newTitle),
    });
    status.value = 'columns.rename(): "${column.title}" → "$newTitle"';
  }

  Future<void> _autoFitSelectedColumns() async {
    final selected = _selectedColumns;
    final columns = selected.isNotEmpty
        ? selected
        : gridManager.columns.inScope(scope: GridSheetColumnScope.visible);
    await gridManager.columns.autoFitWidths(columns.map((c) => c.key).toList());
    status.value =
        'columns.autoFitWidths(): resized ${columns.map((c) => c.name).join(", ")}';
  }
}
