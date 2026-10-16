import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class SnapshotDemo extends StatefulWidget {
  const SnapshotDemo({super.key});

  @override
  State<SnapshotDemo> createState() => _SnapshotDemoState();
}

class _SnapshotDemoState extends State<SnapshotDemo> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'Edit a cell, insert a row, or delete one — then Create Snapshot to checkpoint the current state.',
  );

  GridSheetSnapshot? _snapshot;
  int _newRowCount = 0;
  bool _stretchColumns = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Snapshot & Restore',
      description:
          'createSnapshot() captures the entire grid state — rows, columns, sort, filters, and more — '
          'into one immutable object; restoreSnapshot() replaces the live state with it in a single '
          'call, the basis for undo/redo.',
      icon: Icons.camera_alt_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Insert Row',
            icon: Icons.add,
            color: context.accents.teal,
            onPressed: _insertRow,
            tooltip: 'Insert a new blank row',
          ),
          DemoActionButton(
            label: 'Delete Selected',
            icon: Icons.delete_outline,
            color: context.accents.red,
            onPressed: _deleteSelectedRows,
            tooltip: 'Permanently remove the selected row(s)',
          ),
          DemoActionButton(
            label: 'Create Snapshot',
            icon: Icons.camera_alt_outlined,
            color: context.accents.green,
            onPressed: _createSnapshot,
            tooltip: 'Checkpoint the entire current grid state',
          ),
          DemoActionButton(
            label: 'Restore Snapshot',
            icon: Icons.settings_backup_restore,
            color: context.accents.blue,
            onPressed: _restoreSnapshot,
            tooltip:
                'Jump back to the last checkpoint, discarding later changes',
          ),
          DemoToggleButton(
            label: 'Stretch Columns',
            icon: Icons.fit_screen_outlined,
            color: context.accents.purple,
            value: _stretchColumns,
            onChanged: _toggleStretchColumns,
            tooltip: 'Grow columns to fill leftover width',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: GridSheetConfiguration(
          showColumnFilters: true,
          stretchColumnsToFillWidth: _stretchColumns,
        ),
        styleConfiguration: styleConfig(context),
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
              icon: Icon(Icons.edit, color: context.accents.orange, size: 16),
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
        onLoaded: (event) => gridManager = event.gridManager,
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['ITEM', 'CATEGORY', 'AMOUNT', 'APPROVED'];
    const titles = ['Item', 'Category', 'Amount', 'Approved'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(options: ['Travel', 'Supplies', 'Software', 'Meals']),
      GridSheetColumnType.double(),
      GridSheetColumnType.boolean(),
    ];
    const widths = [180.0, 100.0, 100.0, 120.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_${i + 1}'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        sortable: true,
        width: widths[i],
        hasTextController: types[i].kind != GridSheetColumnKind.dropdown &&
            types[i].kind != GridSheetColumnKind.boolean,
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Flight to Denver', 'Travel', 480.00, true],
      ['Notebooks & pens', 'Supplies', 24.50, true],
      ['Design software license', 'Software', 199.00, false],
      ['Team lunch', 'Meals', 86.30, true],
      ['Conference hotel', 'Travel', 612.75, false],
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

  void _createSnapshot() {
    _snapshot = gridManager.snapshots.create();
    status.value =
        'createSnapshot(): checkpoint saved (${gridManager.rows.count} rows).';
  }

  Future<void> _restoreSnapshot() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      showDemoSnackBar(context, 'Create a snapshot first');
      return;
    }
    await gridManager.snapshots.restore(snapshot);
    status.value =
        'restoreSnapshot(): reverted to the saved checkpoint — later changes discarded.';
  }

  Future<void> _insertRow() async {
    _newRowCount++;
    final row = GridSheetRow(
      key: ValueKey('row_new_$_newRowCount'),
      index: gridManager.rows.count,
      data: ['New expense $_newRowCount', 'Supplies', 0.0, false],
      state: GridSheetRowState.inserted,
      height: Constants.rowHeight,
    );
    await gridManager.rows.insert([row]);
    status.value = 'insertRows(): added "${row.data[0]}" (marked inserted).';
  }

  Future<void> _deleteSelectedRows() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select one or more rows first');
      return;
    }
    await gridManager.rows.delete(keys);
    status.value = 'deleteRows(): removed ${keys.length} row(s).';
  }

  void _toggleStretchColumns(bool value) {
    setState(() => _stretchColumns = value);
    status.value = value
        ? 'stretchColumnsToFillWidth: on — try creating or restoring a snapshot while columns are stretched.'
        : 'stretchColumnsToFillWidth: off — columns back to their configured width.';
  }
}
