import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Showcases pinning ("freezing") columns to either edge of the grid so
/// they stay visible while the rest of the table scrolls horizontally —
/// both declaratively (`GridSheetColumn(pinnedLeft: true)` /
/// `GridSheetColumn(pinnedRight: true)` at construction) and
/// programmatically via `GridSheetManager.pinColumns(leftKeys:, rightKeys:)`.
/// `clearPinColumns` unpins both sides at once, while
/// `unpinColumns(keys)` unpins specific columns without disturbing the
/// rest. The vertical scrollbar renders after the pinned-right pane, at
/// the true right edge of the grid. Also demonstrates
/// `GridSheetStyleConfiguration.pinnedLeftDividerColor`/
/// `pinnedRightDividerColor`/`pinnedColumnsDividerWidth`, the divider drawn
/// at each pin boundary, and `pinnedLeftColumnColor`/`pinnedRightColumnColor`,
/// a dedicated background tint for each pane.
///
/// Also demonstrates the pinned-column features shipped since:
/// `insertColumnsAt(band: .left/.right)` (inserting straight into a
/// pane instead of the scrollable section) and
/// `enableReorderOnPinnedLeftColumns`/`enableReorderOnPinnedRightColumns`
/// (drag-to-reorder within a pane — the pre-existing `reorderColumns`
/// programmatic API is unaffected by this flag and continues to work on
/// any column).
class FixedColumns extends StatefulWidget {
  const FixedColumns({super.key});

  @override
  State<FixedColumns> createState() => _FixedColumnsState();
}

class _FixedColumnsState extends State<FixedColumns> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier('');
  bool _selectionIncludesFrozenCells = false;
  bool _formatIncludesFrozenCells = false;
  bool _selectionIncludesPinnedRightCells = false;
  bool _formatIncludesPinnedRightCells = false;
  bool _showLeftDivider = true;
  bool _showRightDivider = true;
  bool _showPinnedColumnColor = false;
  bool _enableReorderPinned = false;
  int _insertedColumnCounter = 0;

  static const _cyclableDividerWidths = [2.0, 6.0, 12.0];
  double _dividerWidth = _cyclableDividerWidths[0];

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Pinned Columns',
      description:
          'GridSheetColumn.pinnedLeft/pinnedRight freeze columns to either edge so they stay put while '
          'the rest of the table scrolls underneath.',
      icon: Icons.push_pin_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Pin First 2',
            icon: Icons.vertical_split_outlined,
            color: context.accents.indigo,
            onPressed: () => _pinUpTo(gridManager.columns.at(1).key),
            tooltip: 'Pin the first 2 columns to the left by key',
          ),
          DemoActionButton(
            label: 'ID + Name + Dept',
            icon: Icons.push_pin_outlined,
            color: context.accents.teal,
            onPressed: () => _pinByName(['ID', 'NAME', 'DEPARTMENT']),
            tooltip: 'Pin ID, NAME, and DEPARTMENT to the left by name',
          ),
          DemoActionButton(
            label: 'Pin Last 2',
            icon: Icons.vertical_split_outlined,
            color: context.accents.indigo,
            onPressed: () => _pinRightFrom(gridManager.columns.at(8).key),
            tooltip: 'Pin the last 2 columns to the right by key',
          ),
          DemoActionButton(
            label: 'Pin Status Right',
            icon: Icons.push_pin_outlined,
            color: context.accents.teal,
            onPressed: () => _pinRightByName(['STATUS']),
            tooltip: 'Pin STATUS to the right by name',
          ),
          DemoActionButton(
            label: 'Clear Pins',
            icon: Icons.push_pin_outlined,
            color: context.accents.red,
            onPressed: _clearPins,
            tooltip: 'Unpin every pinned column',
          ),
          DemoToggleButton(
            label: 'Left Selection',
            icon: Icons.highlight_alt_outlined,
            color: context.accents.deepPurple,
            value: _selectionIncludesFrozenCells,
            onChanged: _toggleSelectionIncludesFrozen,
            tooltip: 'Include left-pinned columns when selecting',
          ),
          DemoToggleButton(
            label: 'Left Formatting',
            icon: Icons.palette_outlined,
            color: context.accents.brown,
            value: _formatIncludesFrozenCells,
            onChanged: _toggleFormatIncludesFrozen,
            tooltip: 'Apply conditional formatting to left-pinned columns too',
          ),
          DemoToggleButton(
            label: 'Right Selection',
            icon: Icons.highlight_alt_outlined,
            color: context.accents.deepPurple,
            value: _selectionIncludesPinnedRightCells,
            onChanged: _toggleSelectionIncludesPinnedRight,
            tooltip: 'Include right-pinned columns when selecting',
          ),
          DemoToggleButton(
            label: 'Right Formatting',
            icon: Icons.palette_outlined,
            color: context.accents.brown,
            value: _formatIncludesPinnedRightCells,
            onChanged: _toggleFormatIncludesPinnedRight,
            tooltip: 'Apply conditional formatting to right-pinned columns too',
          ),
          DemoToggleButton(
            label: 'Left Divider',
            icon: Icons.border_left_outlined,
            color: context.accents.indigo,
            value: _showLeftDivider,
            onChanged: _toggleShowLeftDivider,
            tooltip:
                'GridSheetStyleConfiguration.pinnedLeftDividerColor — divider '
                'at the pinned-left/scrollable boundary',
          ),
          DemoToggleButton(
            label: 'Right Divider',
            icon: Icons.border_right_outlined,
            color: context.accents.pink,
            value: _showRightDivider,
            onChanged: _toggleShowRightDivider,
            tooltip:
                'GridSheetStyleConfiguration.pinnedRightDividerColor — divider '
                'at the scrollable/pinned-right boundary, styled independently '
                'of the left one',
          ),
          DemoActionButton(
            label: 'Divider: ${_dividerWidth.toInt()}px',
            icon: Icons.line_weight_outlined,
            color: context.accents.teal,
            onPressed: _cycleDividerWidth,
            tooltip:
                'Cycle GridSheetStyleConfiguration.pinnedColumnsDividerWidth — '
                'shared by both dividers, reserves real width rather than '
                'overlaying either pane\'s cells',
          ),
          DemoToggleButton(
            label: 'Pane Color',
            icon: Icons.format_color_fill_outlined,
            color: context.accents.amber,
            value: _showPinnedColumnColor,
            onChanged: _togglePinnedColumnColor,
            tooltip: 'pinnedLeftColumnColor/pinnedRightColumnColor — a '
                'dedicated background tint for each pinned pane',
          ),
          DemoActionButton(
            label: 'Unpin ID',
            icon: Icons.push_pin_outlined,
            color: context.accents.red,
            onPressed: _unpinId,
            tooltip: 'unpinColumns([col_0]) — unpins just the ID column, '
                'leaving any other pins untouched',
          ),
          DemoActionButton(
            label: 'Insert Left Column',
            icon: Icons.playlist_add_outlined,
            color: context.accents.green,
            onPressed: _insertIntoLeftPane,
            tooltip: 'insertColumnsAt(band: .left) — inserts a new column '
                'directly into the pinned-left pane, before a given key',
          ),
          DemoActionButton(
            label: 'Insert Right Column',
            icon: Icons.playlist_add_outlined,
            color: context.accents.green,
            onPressed: _insertIntoRightPane,
            tooltip: 'insertColumnsAt(band: .right) — inserts '
                'at the start of the pinned-right pane',
          ),
          DemoToggleButton(
            label: 'Reorder Pinned',
            icon: Icons.swap_horiz_outlined,
            color: context.accents.blue,
            value: _enableReorderPinned,
            onChanged: _toggleReorderPinned,
            tooltip: 'enableReorderOnPinnedLeftColumns/RightColumns — drag '
                'a pinned column header onto another header in the same '
                'pane to reorder it; dragging across a pane boundary is '
                'always rejected. The programmatic reorderColumns API is '
                'unaffected by this toggle.',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _initialColumns(),
        rows: _initialRows(),
        configuration: GridSheetConfiguration(
          enableRowSelectionOnFirstColumnTap: true,
          enableColumnSelection: true,
          showColumnFilters: true,
          enableCellNavigation: true,
          selectionIncludesPinnedLeftCells: _selectionIncludesFrozenCells,
          conditionalFormatIncludesPinnedLeftCells: _formatIncludesFrozenCells,
          selectionIncludesPinnedRightCells: _selectionIncludesPinnedRightCells,
          conditionalFormatIncludesPinnedRightCells:
              _formatIncludesPinnedRightCells,
          enableReorderOnPinnedLeftColumns: _enableReorderPinned,
          enableReorderOnPinnedRightColumns: _enableReorderPinned,
        ),
        conditionalFormatRules: [
          GridSheetConditionalFormatRule(
            name: 'SALARY',
            scope: GridSheetFormatScope.row,
            expression: 'SALARY > 100000 ? "#C8E6C9" : null',
            textStyle: const TextStyle(
                color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
          ),
        ],
        styleConfiguration: styleConfig(context).copyWith(
          pinnedLeftDividerColor:
              _showLeftDivider ? context.accents.indigo : null,
          pinnedRightDividerColor:
              _showRightDivider ? context.accents.pink : null,
          pinnedColumnsDividerWidth: _dividerWidth,
          pinnedLeftColumnColor: _showPinnedColumnColor
              ? context.accents.amber.withValues(alpha: 0.12)
              : null,
          pinnedRightColumnColor: _showPinnedColumnColor
              ? context.accents.amber.withValues(alpha: 0.20)
              : null,
        ),
        scrollConfiguration: scrollConfig(context),
        loadingIndicator: Center(
          child: const CircularProgressIndicator(strokeWidth: 2.5),
        ),
        onLoaded: (event) => gridManager = event.gridManager,
        onColumnsSelected: (event) {
          status.value =
              'Selected columns: ${event.selectedColumnNames.join(", ")}';
        },
      ),
    );
  }

  List<GridSheetColumn> _initialColumns() {
    const names = [
      'ID',
      'NAME',
      'DEPARTMENT',
      'ROLE',
      'EMAIL',
      'PHONE',
      'LOCATION',
      'SALARY',
      'STATUS',
      'NOTES',
    ];
    const titles = [
      'ID',
      'Name',
      'Department',
      'Role',
      'Email',
      'Phone',
      'Location',
      'Salary',
      'Status',
      'Notes',
    ];
    const widths = [
      80.0,
      150.0,
      140.0,
      170.0,
      210.0,
      140.0,
      130.0,
      110.0,
      80.0,
      220.0,
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
    ];
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
        // ID is frozen declaratively, right from construction — the
        // simplest way to pin a column that should always stay put.
        pinnedLeft: i == 0,
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _initialRows() {
    final raw = [
      [
        'EMP-001',
        'Alice Johnson',
        'Engineering',
        'Software Engineer',
        'alice.johnson@example.com',
        '+1 555-0101',
        'Toronto',
        95000.0,
        'Active',
        'Leads the platform team.'
      ],
      [
        'EMP-002',
        'Bob Smith',
        'Engineering',
        'Senior Engineer',
        'bob.smith@example.com',
        '+1 555-0102',
        'Toronto',
        118000.0,
        'Active',
        ''
      ],
      [
        'EMP-003',
        'Carol Davis',
        'Engineering',
        'Software Engineer',
        'carol.davis@example.com',
        '+1 555-0103',
        'Vancouver',
        89000.0,
        'On Leave',
        'Returning next month.'
      ],
      [
        'EMP-004',
        'David Lee',
        'Sales',
        'Sales Manager',
        'david.lee@example.com',
        '+1 555-0104',
        'Chicago',
        102000.0,
        'Active',
        'Exceeded quarterly target.'
      ],
      [
        'EMP-005',
        'Emma Wilson',
        'Sales',
        'Account Executive',
        'emma.wilson@example.com',
        '+1 555-0105',
        'Chicago',
        76000.0,
        'Active',
        ''
      ],
      [
        'EMP-006',
        'Frank Miller',
        'Sales',
        'Account Executive',
        'frank.miller@example.com',
        '+1 555-0106',
        'Austin',
        71000.0,
        'Inactive',
        ''
      ],
      [
        'EMP-007',
        'Grace Kim',
        'Marketing',
        'Marketing Specialist',
        'grace.kim@example.com',
        '+1 555-0107',
        'Seattle',
        68000.0,
        'Active',
        ''
      ],
      [
        'EMP-008',
        'Henry Chen',
        'Marketing',
        'Marketing Manager',
        'henry.chen@example.com',
        '+1 555-0108',
        'Seattle',
        99000.0,
        'Active',
        'Owns the brand campaigns.'
      ],
      [
        'EMP-009',
        'Ivy Patel',
        'HR',
        'HR Coordinator',
        'ivy.patel@example.com',
        '+1 555-0109',
        'Denver',
        62000.0,
        'Active',
        ''
      ],
      [
        'EMP-010',
        'Jack Brown',
        'HR',
        'HR Manager',
        'jack.brown@example.com',
        '+1 555-0110',
        'Denver',
        91000.0,
        'On Leave',
        ''
      ],
      [
        'EMP-011',
        'Karen White',
        'Finance',
        'Financial Analyst',
        'karen.white@example.com',
        '+1 555-0111',
        'Denver',
        78000.0,
        'Active',
        ''
      ],
      [
        'EMP-012',
        'Leo Green',
        'Finance',
        'Finance Manager',
        'leo.green@example.com',
        '+1 555-0112',
        'Denver',
        95000.0,
        'Active',
        'Exceeded annual target.'
      ],
      [
        'EMP-013',
        'Mia Scott',
        'Engineering',
        'Software Engineer',
        'mia.scott@example.com',
        '+1 555-0113',
        'Denver',
        82000.0,
        'Active',
        ''
      ],
      [
        'EMP-014',
        'Noah Adams',
        'Engineering',
        'Senior Engineer',
        'noah.adams@example.com',
        '+1 555-0114',
        'Denver',
        88000.0,
        'Active',
        ''
      ],
      [
        'EMP-015',
        'Olivia Baker',
        'Engineering',
        'Software Engineer',
        'olivia.baker@example.com',
        '+1 555-0115',
        'Denver',
        85000.0,
        'Active',
        ''
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

  static const _simulatedPinLatency = Duration(milliseconds: 400);

  Future<void> _pinUpTo(ValueKey<String> targetColumnKey) async {
    gridManager.loading.start();
    await Future.delayed(_simulatedPinLatency);
    if (!mounted) return;
    final targetIndex =
        gridManager.columns.all.indexWhere((c) => c.key == targetColumnKey);
    final leftKeys = targetIndex == -1
        ? <ValueKey<String>>[]
        : gridManager.columns.all
            .take(targetIndex + 1)
            .map((c) => c.key)
            .toList();
    final error = await gridManager.columns.pin(leftKeys: leftKeys);
    _reportPinResult(
        'pinColumns(leftKeys: up to ${targetColumnKey.value})', error);
  }

  Future<void> _pinByName(List<String> names) async {
    gridManager.loading.start();
    await Future.delayed(_simulatedPinLatency);
    if (!mounted) return;
    final error = await gridManager.columns.pin(
        leftKeys:
            gridManager.columns.findByNames(names).map((c) => c.key).toList());
    _reportPinResult('pinColumns(leftKeys: ${names.join(", ")})', error);
  }

  Future<void> _clearPins() async {
    gridManager.loading.start();
    await Future.delayed(_simulatedPinLatency);
    if (!mounted) return;
    await gridManager.columns.unpinAll();
    status.value = 'clearPinColumns(): pinned left: '
        '${gridManager.columns.pinnedLeft.map((c) => c.name).join(", ")}, '
        'pinned right: '
        '${gridManager.columns.pinnedRight.map((c) => c.name).join(", ")}';
  }

  void _reportPinResult(String call, String? error) {
    if (error != null) {
      status.value = '$call failed: $error';
      return;
    }
    status.value = '$call → pinned: '
        '${gridManager.columns.pinnedLeft.map((c) => c.name).join(", ")}';
  }

  Future<void> _pinRightFrom(ValueKey<String> targetColumnKey) async {
    gridManager.loading.start();
    await Future.delayed(_simulatedPinLatency);
    if (!mounted) return;
    final targetIndex =
        gridManager.columns.all.indexWhere((c) => c.key == targetColumnKey);
    final rightKeys = targetIndex == -1
        ? <ValueKey<String>>[]
        : gridManager.columns.all.skip(targetIndex).map((c) => c.key).toList();
    final error = await gridManager.columns.pin(rightKeys: rightKeys);
    _reportPinRightResult(
        'pinColumns(rightKeys: from ${targetColumnKey.value})', error);
  }

  Future<void> _pinRightByName(List<String> names) async {
    gridManager.loading.start();
    await Future.delayed(_simulatedPinLatency);
    if (!mounted) return;
    final error = await gridManager.columns.pin(
        rightKeys:
            gridManager.columns.findByNames(names).map((c) => c.key).toList());
    _reportPinRightResult('pinColumns(rightKeys: ${names.join(", ")})', error);
  }

  void _reportPinRightResult(String call, String? error) {
    if (error != null) {
      status.value = '$call failed: $error';
      return;
    }
    status.value = '$call → pinned right: '
        '${gridManager.columns.pinnedRight.map((c) => c.name).join(", ")}';
  }

  void _toggleSelectionIncludesFrozen(bool value) {
    setState(() => _selectionIncludesFrozenCells = value);
    status.value = 'selectionIncludesPinnedLeftCells: $value';
  }

  void _toggleFormatIncludesFrozen(bool value) {
    setState(() => _formatIncludesFrozenCells = value);
    status.value = 'conditionalFormatIncludesPinnedLeftCells: $value';
  }

  void _toggleSelectionIncludesPinnedRight(bool value) {
    setState(() => _selectionIncludesPinnedRightCells = value);
    status.value = 'selectionIncludesPinnedRightCells: $value';
  }

  void _toggleFormatIncludesPinnedRight(bool value) {
    setState(() => _formatIncludesPinnedRightCells = value);
    status.value = 'conditionalFormatIncludesPinnedRightCells: $value';
  }

  void _toggleShowLeftDivider(bool value) {
    setState(() => _showLeftDivider = value);
    status.value = 'pinnedLeftDividerColor: ${value ? 'indigo' : 'null'}';
  }

  void _toggleShowRightDivider(bool value) {
    setState(() => _showRightDivider = value);
    status.value = 'pinnedRightDividerColor: ${value ? 'pink' : 'null'}';
  }

  void _cycleDividerWidth() {
    final next = (_cyclableDividerWidths.indexOf(_dividerWidth) + 1) %
        _cyclableDividerWidths.length;
    setState(() => _dividerWidth = _cyclableDividerWidths[next]);
    status.value = 'pinnedColumnsDividerWidth: ${_dividerWidth.toInt()}px';
  }

  void _togglePinnedColumnColor(bool value) {
    setState(() => _showPinnedColumnColor = value);
    status.value = 'pinnedLeftColumnColor/pinnedRightColumnColor: '
        '${value ? 'amber tint' : 'null'}';
  }

  Future<void> _unpinId() async {
    const idKey = ValueKey('col_0');
    await gridManager.columns.unpin([idKey]);
    if (!mounted) return;
    status.value = 'unpinColumns([col_0]) → pinned left: '
        '${gridManager.columns.pinnedLeft.map((c) => c.name).join(", ")}, '
        'pinned right: '
        '${gridManager.columns.pinnedRight.map((c) => c.name).join(", ")}';
  }

  // A fresh column for the two "insert into pane" demo buttons — carries a
  // default value for every existing row via `defaultValues`, matching
  // _initialColumns()'s column count.
  GridSheetColumn _newDemoColumn(String label) {
    final n = ++_insertedColumnCounter;
    return GridSheetColumn(
      key: ValueKey('inserted_col_$n'),
      index: 0,
      name: 'EXTRA_$n',
      title: '$label $n',
      width: 130.0,
      resizable: true,
    );
  }

  Future<void> _insertIntoLeftPane() async {
    // null appends to the end of the pinned-left band.
    await gridManager.columns.insertAt(
      null,
      [_newDemoColumn('Extra Left')],
      defaultValues: const [''],
      band: GridSheetColumnBand.left,
    );
    if (!mounted) return;
    status.value = 'insertColumnsAt(null, ..., band: .left) → pinned left now '
        'has ${gridManager.columns.pinnedLeft.length} column(s)';
  }

  Future<void> _insertIntoRightPane() async {
    final firstRight = gridManager.columns.pinnedRight.isNotEmpty
        ? gridManager.columns.pinnedRight.first.key
        : null;
    await gridManager.columns.insertAt(
      firstRight,
      [_newDemoColumn('Extra Right')],
      defaultValues: const [''],
      band: GridSheetColumnBand.right,
    );
    if (!mounted) return;
    status.value = 'insertColumnsAt($firstRight, ..., band: .right) → pinned '
        'right now has ${gridManager.columns.pinnedRight.length} column(s)';
  }

  void _toggleReorderPinned(bool value) {
    setState(() => _enableReorderPinned = value);
    status.value = 'enableReorderOnPinnedLeftColumns/RightColumns: $value — '
        "drag a pinned column header onto another header in the same pane; "
        "it won't cross panes";
  }
}
