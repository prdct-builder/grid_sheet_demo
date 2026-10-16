import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class RowOperations extends StatefulWidget {
  const RowOperations({super.key});

  @override
  State<RowOperations> createState() => _RowOperationsState();
}

class _RowOperationsState extends State<RowOperations> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier('');
  int _newRowCount = 0;
  List<GridSheetRow> _selectedRows = [];
  bool _insertAboveSelection = false;

  bool _enableRowHover = true;
  bool _customResizeHandle = false;
  bool _customDragFeedback = false;
  bool _customDragPreview = false;
  bool _customHover = false;
  bool _showOverflowTooltip = false;
  bool _enableUndoDelete = true;

  // GridSheetColumn.showOverflowTooltip is only read once, at initial mount
  // (see GridSheet's _initData()) — reassigning this key forces a brand-new
  // GridSheet element so the toggle below actually takes effect, the same
  // trick column_animation.dart uses for its config-changing toggles.
  GlobalKey<GridSheetState> _gridKey = GlobalKey<GridSheetState>();

  GridSheetRowInsertPosition get _insertPosition => _insertAboveSelection
      ? GridSheetRowInsertPosition.above
      : GridSheetRowInsertPosition.below;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Row Operations',
      description:
          'GridSheetManager exposes row CRUD — insert, delete, hide/show, duplicate, bulk-update — plus '
          'stable-key drag-to-reorder and drag-to-resize directly on the grid. While dragging, the row '
          'lifts and a dotted gap of its exact height opens where it will land; drop on the lower half of the '
          'last row to move a row to the end.',
      icon: Icons.table_rows_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Insert Row',
            icon: Icons.add,
            color: context.accents.green,
            onPressed: _insertRow,
            tooltip: 'Insert a new blank row, marked as inserted',
          ),
          DemoToggleButton(
            label: 'Above Selection',
            icon: Icons.vertical_align_top,
            color: context.accents.indigo,
            value: _insertAboveSelection,
            onChanged: _toggleInsertPosition,
            tooltip: 'Insert/duplicate above (vs. below) the selection',
          ),
          DemoActionButton(
            label: 'Duplicate',
            icon: Icons.copy_all_outlined,
            color: context.accents.blue,
            onPressed: _duplicateSelectedRows,
            tooltip: 'Duplicate the selected row(s)',
          ),
          DemoActionButton(
            label: 'Mark Done',
            icon: Icons.check_circle_outline,
            color: context.accents.teal,
            onPressed: _markSelectedDone,
            tooltip: 'Set DONE to true on the selected row(s)',
          ),
          DemoActionButton(
            label: 'Set Row Height',
            icon: Icons.height,
            color: context.accents.amber,
            onPressed: _selectedRowHeight,
            tooltip: 'Set the selected row(s) to a fixed height',
          ),
          DemoActionButton(
            label: 'Auto-fit Height',
            icon: Icons.unfold_more,
            color: context.accents.amber,
            onPressed: _autoFitSelectedRowHeights,
            tooltip:
                'Resize the selected (or all) rows to fit their wrapped content',
          ),
          DemoActionButton(
            label: 'Select All',
            icon: Icons.select_all,
            color: context.accents.purple,
            onPressed: _selectAllRows,
            tooltip: 'Select every row in the grid',
          ),
          DemoActionButton(
            label: 'Deselect',
            icon: Icons.clear,
            color: context.accents.neutral,
            onPressed: _deselectRows,
            tooltip: 'Clear the current row selection',
          ),
          DemoActionButton(
            label: 'Undo Changes',
            icon: Icons.undo,
            color: context.accents.deepOrange,
            onPressed: _undoSelectedRow,
            tooltip: 'Revert the selected row(s) to their original values',
          ),
          DemoActionButton(
            label: 'Delete Selected',
            icon: Icons.delete_outline,
            color: context.accents.red,
            onPressed: _deleteSelectedRows,
            tooltip: _enableUndoDelete
                ? 'Remove the selected row(s) — shows an UNDO prompt for 5 seconds'
                : 'Permanently remove the selected row(s)',
          ),
          DemoToggleButton(
            label: 'Undo Delete',
            icon: Icons.settings_backup_restore,
            color: context.accents.deepOrange,
            value: _enableUndoDelete,
            onChanged: _toggleUndoDelete,
            tooltip:
                'Enable enableUndoDelete — deleting rows shows a dismissible UNDO prompt instead of deleting immediately',
          ),
          DemoActionButton(
            label: 'Hide Selected',
            icon: Icons.visibility_off_outlined,
            color: context.accents.brown,
            onPressed: _hideSelectedRows,
            tooltip: 'hideRows(selectedRowKeys) — hides the selected '
                'row(s) instead of deleting them; their data is preserved',
          ),
          DemoActionButton(
            label: 'Show All',
            icon: Icons.visibility_outlined,
            color: context.accents.brown,
            onPressed: _showAllRows,
            tooltip: 'showAllRows() — restores every row hidden via '
                '"Hide Selected"',
          ),
          DemoActionButton(
            label: _enableRowHover ? 'Row Hover: On' : 'Row Hover: Off',
            icon: Icons.ads_click,
            color: context.accents.orange,
            onPressed: () => setState(() {
              _enableRowHover = !_enableRowHover;
              _enableRowHoverOption('enableRowHover = $_enableRowHover');
            }),
            tooltip: 'Toggle whether rows highlight on hover',
          ),
          DemoActionButton(
            label:
                _customHover ? 'Hover Color: Custom' : 'Hover Color: Default',
            icon: Icons.border_outer,
            color: context.accents.teal,
            onPressed: () => setState(() => _customHover = !_customHover),
            tooltip: 'Switch the row hover color',
          ),
          DemoActionButton(
            label: _customResizeHandle
                ? 'Resize Handle: Custom'
                : 'Resize Handle: Default',
            icon: Icons.drag_indicator,
            color: context.accents.pink,
            onPressed: () =>
                setState(() => _customResizeHandle = !_customResizeHandle),
            tooltip: 'Switch the row resize handle\'s style',
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
            label: 'Custom Drag Preview',
            icon: Icons.open_with,
            color: context.accents.deepOrange,
            value: _customDragPreview,
            onChanged: (value) {
              setState(() => _customDragPreview = value);
              status.value = value
                  ? 'rowDragPreviewBuilder: dragging a row now shows a "Moving: <task>" chip.'
                  : 'rowDragPreviewBuilder: null — the built-in preview (the row\'s values on one line).';
            },
            tooltip:
                'Replace the preview shown under the pointer while dragging a row (rowDragPreviewBuilder)',
          ),
          DemoToggleButton(
            label: 'Overflow Tooltip',
            icon: Icons.info_outline,
            color: context.accents.deepPurple,
            value: _showOverflowTooltip,
            onChanged: _toggleOverflowTooltip,
            tooltip:
                'Toggle showOverflowTooltip on TASK/DESCRIPTION — ASSIGNEE/PRIORITY/DONE '
                'always have it off since those short values can never overflow',
          ),
        ],
      ),
      grid: GridSheet(
        key: _gridKey,
        columns: _columns(),
        rows: _rows(),
        configuration: GridSheetConfiguration(
          enableRowSelectionOnFirstColumnTap: true,
          enableMultiSelection: true,
          enableRowReorder: true,
          enableRowResize: true,
          enableRowHover: true,
          rowInsertPosition: _insertPosition,
          enableUndoDelete: _enableUndoDelete,
        ),
        styleConfiguration: styleConfig(context).copyWith(
          resizeHandleColor: _customResizeHandle ? context.accents.pink : null,
          resizeHandleThickness: _customResizeHandle ? 5 : null,
          rowDragFeedbackElevation: _customDragFeedback ? 20 : null,
          dragFeedbackOpacity: _customDragFeedback ? 0.6 : null,
          hoverColorOnRow: _customHover ? context.accents.teal : null,
        ),
        scrollConfiguration: scrollConfig(context),
        rowStateIndicatorBuilder: (row) {
          if (row.isInserted) {
            return GridSheetRowStateIndicator(
              color: context.accents.green.withValues(alpha: 0.08),
              icon:
                  Icon(Icons.fiber_new, color: context.accents.green, size: 16),
            );
          }
          if (row.isModified) {
            return GridSheetRowStateIndicator(
              color: context.accents.orange.withValues(alpha: 0.08),
              icon: Icon(Icons.edit, color: context.accents.orange, size: 15),
            );
          }
          if (row.isDeleted) {
            return GridSheetRowStateIndicator(
              color: context.accents.red.withValues(alpha: 0.08),
              icon: Icon(Icons.delete, color: context.accents.red, size: 16),
            );
          }
          return null; // default look
        },
        rowDragPreviewBuilder: _customDragPreview ? _buildDragPreview : null,
        onLoaded: (event) => gridManager = event.gridManager,
        onRowReorder: (event) {
          status.value = 'onRowReorder: ${event.fromRowKey.value} dropped at '
              '${event.toRowKey.value} (insert index ${event.fromIndex} → '
              '${event.toIndex})';
        },
        onRowsSelected: (event) {
          _selectedRows = event.selectedRows;
          status.value = 'Selected ${event.selectedRowKeys.length} row(s)';
        },
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  // A compact chip naming the task, in place of the built-in one-line copy
  // of the row's values (details.defaultPreview, which a builder could
  // also wrap instead).
  Widget _buildDragPreview(
      BuildContext context, GridSheetRowDragPreviewDetails details) {
    final task = details.row.data.isEmpty ? '' : '${details.row.data.first}';
    return Material(
      elevation: 8,
      color: context.accents.deepOrange,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_with, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Moving: $task',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['TASK', 'ASSIGNEE', 'PRIORITY', 'DESCRIPTION', 'DONE'];
    const titles = ['Task', 'Assignee', 'Priority', 'Description', 'Done'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(options: ['Low', 'Medium', 'High']),
      GridSheetColumnType.text(),
      GridSheetColumnType.boolean(),
    ];
    const widths = [220.0, 120.0, 120.0, 220.0, 120.0];
    // TASK/DESCRIPTION hold long free-form text that can genuinely overflow
    // its column width, so their tooltip is toggleable below. ASSIGNEE,
    // PRIORITY and DONE always hold short fixed values that can never
    // overflow — showOverflowTooltip is left off for them permanently,
    // skipping the per-cell overflow measurement entirely.
    final showOverflowTooltips = [
      _showOverflowTooltip,
      false,
      false,
      _showOverflowTooltip,
      false,
    ];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        editable: i == 3 ? false : true,
        hasTextController: types[i].kind == GridSheetColumnKind.text,
        showOverflowTooltip: showOverflowTooltips[i],
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      [
        'Design onboarding flow for new users with improved navigation and welcome experience with smooth transitions.',
        'Ava',
        'High',
        'Create a smoother onboarding journey with better user guidance and interactive tutorials',
        false
      ],
      [
        'Fix checkout bug causing payment failures during order confirmation process',
        'Liam',
        'High',
        'Resolve payment issues affecting customers during final checkout confirmation and order completion',
        true
      ],
      [
        'Write comprehensive release notes covering new features, bug fixes, and improvements',
        'Noah',
        'Medium',
        'Document all product updates including features fixes improvements and important changes',
        false
      ],
      [
        'Update project dependencies to the latest stable versions and resolve compatibility issues',
        'Maya',
        'Low',
        'Upgrade libraries carefully while maintaining application stability. Test thoroughly to ensure no regressions occur',
        true
      ],
      [
        'Perform a complete QA regression pass across all major application features and workflows.',
        'Ethan',
        'Medium',
        'Test application workflows thoroughly to identify defects.',
        false
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

  void _toggleInsertPosition(bool value) {
    setState(() => _insertAboveSelection = value);
    status.value = 'rowInsertPosition: ${value ? "above" : "below"}';
  }

  void _toggleOverflowTooltip(bool value) {
    setState(() {
      _showOverflowTooltip = value;
      _gridKey = GlobalKey<GridSheetState>();
    });
    status.value = value
        ? 'showOverflowTooltip: true on TASK/DESCRIPTION — hover a truncated cell to see the full value.'
        : 'showOverflowTooltip: false on TASK/DESCRIPTION — no tooltip on hover, skips the per-cell overflow measurement.';
  }

  Future<void> _insertRow() async {
    _newRowCount++;
    final row = GridSheetRow(
      key: ValueKey('row_new_$_newRowCount'),
      index: gridManager.rows.count,
      data: [
        'New task $_newRowCount',
        'Unassigned',
        'Low',
        'Description for new task',
        false
      ],
      state: GridSheetRowState.inserted,
      height: Constants.rowHeight,
    );
    // GridSheetConfiguration.rowInsertPosition (set below from
    // _insertPosition) already governs where this lands.
    await gridManager.rows.insert([row]);
    status.value =
        'insertRows(): added "New task $_newRowCount" (marked inserted)';
  }

  Future<void> _deleteSelectedRows() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select one or more rows first');
      return;
    }
    await gridManager.rows.delete(keys);
    status.value = 'deleteRows(): removed ${keys.length} row(s)';
  }

  Future<void> _hideSelectedRows() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select one or more rows first');
      return;
    }
    await gridManager.rows.hide(keys);
    status.value = 'hideRows(): hid ${keys.length} row(s) — '
        '${gridManager.rows.hidden.length} hidden in total';
  }

  Future<void> _showAllRows() async {
    final hiddenCount = gridManager.rows.hidden.length;
    if (hiddenCount == 0) {
      showDemoSnackBar(context, 'No rows are currently hidden');
      return;
    }
    await gridManager.rows.showAll();
    status.value = 'showAllRows(): restored $hiddenCount row(s)';
  }

  Future<void> _duplicateSelectedRows() async {
    final selected = _selectedRows;
    if (selected.isEmpty) {
      showDemoSnackBar(context, 'Select a row to duplicate');
      return;
    }
    final duplicates = selected.map((row) {
      _newRowCount++;
      return GridSheetRow(
        key: ValueKey('row_dup_$_newRowCount'),
        index: gridManager.rows.count,
        data: List.from(row.data),
        height: row.height,
        state: GridSheetRowState.inserted,
      );
    }).toList();
    await gridManager.rows.insert(duplicates);
    status.value = 'insertRows(): duplicated ${duplicates.length} row(s)';
  }

  Future<void> _markSelectedDone() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select a row first');
      return;
    }
    for (final row in _selectedRows) {
      final newData = List.from(row.data);
      newData[4] = true;
      gridManager.rows.update(row.key, newData);
    }
    status.value = 'updateRowData(): marked ${keys.length} row(s) done';
  }

  void _selectAllRows() {
    final allKeys = gridManager.rows.all.map((r) => r.key).toList();
    gridManager.selection.selectRows(allKeys);
    status.value = 'selectRows(): selected all ${allKeys.length} rows';
  }

  void _deselectRows() {
    gridManager.selection.deselectRows(gridManager.selection.rowKeys);
    status.value = 'deselectRows(): cleared row selection';
  }

  Future<void> _undoSelectedRow() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select a modified/inserted row first');
      return;
    }
    await gridManager.changes.undo(keys);
    status.value = 'undoRowChanges(): reverted ${keys.length} row(s)';
  }

  void _selectedRowHeight() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select a row first');
      return;
    }
    final heights = <ValueKey<String>, double>{};
    for (final key in keys) {
      heights[key] = Constants.rowHeight * 2;
    }
    await gridManager.rows.setHeights(heights);
    status.value =
        'Row height updated to ${(Constants.rowHeight * 2)} for ${keys.length} selected row(s)';
  }

  Future<void> _autoFitSelectedRowHeights() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      status.value = 'autoFitRowHeights(): a row should be selected';
      return;
    }
    await gridManager.rows.autoFitHeights(keys);
    status.value = 'autoFitRowHeights(): resized ${keys.length} row(s)';
  }

  void _toggleUndoDelete(bool value) {
    setState(() => _enableUndoDelete = value);
    gridManager.config.updateGrid(
      gridManager.config.grid.copyWith(
        enableUndoDelete: value,
      ),
    );
    status.value = value
        ? 'enableUndoDelete: true — deleting rows now shows an UNDO prompt for 5 seconds'
        : 'enableUndoDelete: false — deleting rows is immediate and permanent';
  }

  void _enableRowHoverOption(String label) {
    gridManager.config.updateGrid(
      gridManager.config.grid.copyWith(
        enableRowHover: _enableRowHover,
      ),
    );
    status.value = 'updateConfiguration: $label';
  }
}
