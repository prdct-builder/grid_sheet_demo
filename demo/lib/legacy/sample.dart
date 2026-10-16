import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';
import 'package:grid_sheet_demo/design_system/grid_demo_colors.dart';

class GridSheetSample extends StatefulWidget {
  const GridSheetSample({super.key});

  @override
  State<GridSheetSample> createState() => _GridSheetSampleState();
}

class _GridSheetSampleState extends State<GridSheetSample> {
  late GridSheetManager gridManager;

  /// Resolves a column name to its key — the manager's column methods are
  /// key-addressed.
  ValueKey<String> _columnKey(String name) =>
      gridManager.columns.findByNames([name]).single.key;

  final CustomCellsDemoBuilder _cellRenderer = CustomCellsDemoBuilder();

  final TextEditingController _minIdController = TextEditingController();
  final TextEditingController _maxIdController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Lookback window per relative-date preset checkbox. DATE_ADDED is a
  // GridSheetColumnType.datetime() column, so GridSheetUtils.evaluateFilters
  // compares these chronologically (accepts ISO strings or epoch values) —
  // see _applyFilters, which ORs the selected cutoffs together.
  static final Map<String, Duration> _datePresetLookback = {
    'Filter by last week': const Duration(days: 7),
    'Filter by last month': const Duration(days: 30),
    'Filter by last 3 months': const Duration(days: 90),
    'Filter by last year': const Duration(days: 365),
  };

  final Set<String> _selectedDatePresets = {};
  final Set<String> _selectedRiskGroups = {};
  final Set<String> _selectedLocations = {};
  bool _photoOnly = false;

  final int _rowsPerPage = 8;
  bool _showFilterPanel = true;

  GridDemoColors get colors => Theme.of(context).brightness == Brightness.dark
      ? GridDemoColors.dark
      : GridDemoColors.light;

  @override
  void dispose() {
    _minIdController.dispose();
    _maxIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<GridSheetColumn> gridColumns() {
    return [
      GridSheetColumn(
        key: const ValueKey('col_1'),
        index: 0,
        name: 'PHOTO',
        title: 'Photo',
        description: 'GridSheetColumnType.custom() — avatar image cell',
        type: GridSheetColumnType.custom(),
        width: 80,
        hasTextController: false,
      ),
      GridSheetColumn(
        key: const ValueKey('col_2'),
        index: 1,
        name: 'ID',
        title: 'ID',
        description: 'GridSheetColumnType.integer() — registry number',
        type: GridSheetColumnType.integer(),
        width: 80,
        sortable: true,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_3'),
        index: 2,
        name: 'FIRST_NAME',
        title: 'First Name',
        description: 'GridSheetColumnType.text() — free-form string input',
        type: GridSheetColumnType.text(),
        width: 110,
        sortable: true,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_4'),
        index: 3,
        name: 'LAST_NAME',
        title: 'Last Name',
        description: 'GridSheetColumnType.text() — free-form string input',
        type: GridSheetColumnType.text(),
        width: 110,
        sortable: true,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_5'),
        index: 4,
        name: 'EMAIL',
        title: 'Email',
        description: 'GridSheetColumnType.text() — email address',
        type: GridSheetColumnType.text(),
        width: 180,
        sortable: true,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_6'),
        index: 5,
        name: 'LOCATION',
        title: 'Location',
        description: 'GridSheetColumnType.custom() — link-styled location text',
        type: GridSheetColumnType.custom(),
        width: 120,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_7'),
        index: 6,
        name: 'DATE_ADDED',
        title: 'Date Added',
        description: 'GridSheetColumnType.datetime() — date & time values',
        type: GridSheetColumnType.datetime(),
        width: 120,
        hasTextController: false,
        sortable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_8'),
        index: 7,
        name: 'RISK_GROUP',
        title: 'Risk Group',
        description: 'GridSheetColumnType.dropdown() — constrained option list',
        type: GridSheetColumnType.text(),
        width: 120,
        hasTextController: false,
      ),
      GridSheetColumn(
        key: const ValueKey('col_10'),
        index: 9,
        name: 'NOTES',
        title: 'Notes',
        description:
            'GridSheetColumnType.text() — internal notes, hidden by default',
        type: GridSheetColumnType.text(),
        width: 200,
        visible: false,
      ),
      GridSheetColumn(
        key: const ValueKey('col_11'),
        index: 10,
        name: 'CREATED_BY',
        title: 'Created By',
        description:
            'GridSheetColumnType.text() — record owner, hidden by default',
        type: GridSheetColumnType.text(),
        width: 120,
        visible: false,
      ),
      GridSheetColumn(
        key: const ValueKey('col_9'),
        index: 8,
        name: 'ACTIONS',
        title: '',
        description: 'GridSheetColumnType.custom() — insert/edit/delete icons',
        type: GridSheetColumnType.custom(),
        width: 30,
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<GridSheetRow> gridRows() {
    final now = DateTime.now();

    // (first, last, email) — 32 people, purely for name/email variety.
    const people = [
      ('Angel', 'Lane', 'grolschie@mac.com'),
      ('Arlene', 'Warren', 'mthurn@optonline.net'),
      ('Ann', 'Richards', 'raines@optonline.net'),
      ('Shane', 'Edwards', 'wkrebs@verizon.net'),
      ('Victoria', 'Fox', 'doormat@att.net'),
      ('Mitchell', 'Warren', 'amaranth@outlook.com'),
      ('Shawn', 'Warren', 'sabren@comcast.net'),
      ('Max', 'Hawkins', 'zeitlin@sbcglobal.net'),
      ('Esther', 'Edwards', 'juliano@yahoo.ca'),
      ('Debra', 'Fox', 'dgatwood@msn.com'),
      ('James', 'Carter', 'jcarter@gmail.com'),
      ('Linda', 'Brooks', 'lbrooks@yahoo.com'),
      ('Robert', 'Nguyen', 'rnguyen@outlook.com'),
      ('Patricia', 'Diaz', 'pdiaz@hotmail.com'),
      ('Michael', 'Price', 'mprice@aol.com'),
      ('Barbara', 'Reed', 'breed@comcast.net'),
      ('William', 'Chen', 'wchen@icloud.com'),
      ('Susan', 'Ortiz', 'sortiz@yahoo.com'),
      ('David', 'Kim', 'dkim@gmail.com'),
      ('Nancy', 'Ward', 'nward@verizon.net'),
      ('Charles', 'Ellis', 'cellis@outlook.com'),
      ('Karen', 'Foster', 'kfoster@mac.com'),
      ('Joseph', 'Bell', 'jbell@att.net'),
      ('Betty', 'Chavez', 'bchavez@sbcglobal.net'),
      ('Thomas', 'Reyes', 'treyes@msn.com'),
      ('Sandra', 'Ross', 'sross@gmail.com'),
      ('Daniel', 'Wood', 'dwood@optonline.net'),
      ('Donna', 'Powell', 'dpowell@yahoo.com'),
      ('Paul', 'Hughes', 'phughes@comcast.net'),
      ('Carol', 'Simmons', 'csimmons@outlook.com'),
      ('Mark', 'Foster', 'mfoster@icloud.com'),
      ('Ruth', 'Sanders', 'rsanders@gmail.com'),
    ];

    // Rows 0-26 are 9 (risk, location) cells x 3 rows each, at increasing
    // recency (<=7d, <=30d, <=90d). Rows 27-31 are filler: comma-joined
    // multi-location cells and dates beyond a year.
    //
    // Every filter in the panel is AND'd together (see _applyFilters /
    // filtering_impl.dart's _applyFiltersToRow), so picking one value from
    // each of Risk Group + Location + a Date preset only returns rows where
    // ALL of them co-occur. The 3-rows-per-cell layout guarantees that
    // co-occurrence for every (risk, location) pair, at every date preset —
    // including "last week" alone, the tightest one — instead of leaving it
    // to chance which combinations happen to line up.
    const risks = [
      'Normal', 'Normal', 'Normal', //
      'Normal', 'Normal', 'Normal', //
      'Normal', 'Normal', 'Normal', //
      'Low Risk', 'Low Risk', 'Low Risk', //
      'Low Risk', 'Low Risk', 'Low Risk', //
      'Low Risk', 'Low Risk', 'Low Risk', //
      'High Risk', 'High Risk', 'High Risk', //
      'High Risk', 'High Risk', 'High Risk', //
      'High Risk', 'High Risk', 'High Risk', //
      'Normal', 'Low Risk', 'High Risk', 'Normal', 'Low Risk',
    ];

    const locations = [
      'Downtown', 'Downtown', 'Downtown', //
      'Uptown', 'Uptown', 'Uptown', //
      'Riverside', 'Riverside', 'Riverside', //
      'Downtown', 'Downtown', 'Downtown', //
      'Uptown', 'Uptown', 'Uptown', //
      'Riverside', 'Riverside', 'Riverside', //
      'Downtown', 'Downtown', 'Downtown', //
      'Uptown', 'Uptown', 'Uptown', //
      'Riverside', 'Riverside', 'Riverside', //
      'Uptown, Downtown',
      'Riverside, Downtown',
      'Uptown, Riverside',
      'Uptown, Riverside',
      'Downtown',
    ];

    const daysAgo = [
      2, 15, 45, //
      4, 18, 55, //
      6, 22, 65, //
      1, 12, 40, //
      3, 20, 50, //
      5, 25, 60, //
      7, 28, 70, //
      2, 16, 80, //
      6, 24, 85, //
      10, 200, 400, 500, 600, // 400+ sit beyond every date preset on purpose
    ];

    // The 3rd (oldest) row of 5 of the 9 cells has no photo, so "Only show
    // those with a photo" combined with any risk/location/date-preset
    // selection still matches — the <=7d row in every cell always keeps one.
    const noPhotoIndices = {2, 8, 14, 20, 26};

    return List<GridSheetRow>.generate(people.length, (i) {
      final (first, last, email) = people[i];
      final initials =
          noPhotoIndices.contains(i) ? '' : '${first[0]}${last[0]}';

      return GridSheetRow(
        key: ValueKey('row_$i'),
        index: i,
        height: 40,
        data: [
          initials,
          10000 + i * 2500,
          first,
          last,
          email,
          locations[i],
          now.subtract(Duration(days: daysAgo[i])),
          risks[i],
          '',
          '',
          'system',
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.mainContainerColor,
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.childContainerColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showFilterPanel) ...[
              _buildFilterPanel(),
              const SizedBox(width: 20),
            ],
            Expanded(child: _buildMainWidget()),
          ],
        ),
      ),
    );
  }

  Future<void> _applyFilters() async {
    final minText = _minIdController.text.trim();
    final maxText = _maxIdController.text.trim();
    if (minText.isNotEmpty && maxText.isNotEmpty) {
      await gridManager.filters.add(
        {
          _columnKey('ID'): ['$minText-$maxText']
        },
        comparison: GridSheetFilterComparison.between,
      );
    } else if (minText.isNotEmpty) {
      await gridManager.filters.add(
        {
          _columnKey('ID'): [minText]
        },
        comparison: GridSheetFilterComparison.greaterThanOrEqual,
      );
    } else if (maxText.isNotEmpty) {
      await gridManager.filters.add(
        {
          _columnKey('ID'): [maxText]
        },
        comparison: GridSheetFilterComparison.lessThanOrEqual,
      );
    } else {
      await gridManager.filters.clear(_columnKey('ID'));
    }

    // Each selected preset contributes its own cutoff; OR'ing them (the
    // engine tries every value in the list per column) means checking both
    // "last week" and "last year" simply resolves to the earlier cutoff.
    if (_selectedDatePresets.isNotEmpty) {
      final now = DateTime.now();
      final cutoffs = _selectedDatePresets
          .map((label) =>
              now.subtract(_datePresetLookback[label]!).toIso8601String())
          .toList();
      await gridManager.filters.add(
        {_columnKey('DATE_ADDED'): cutoffs},
        comparison: GridSheetFilterComparison.greaterThanOrEqual,
      );
    } else {
      await gridManager.filters.clear(_columnKey('DATE_ADDED'));
    }

    if (_selectedRiskGroups.isNotEmpty) {
      await gridManager.filters.add(
        {_columnKey('RISK_GROUP'): _selectedRiskGroups.toList()},
        comparison: GridSheetFilterComparison.exact,
      );
    } else {
      await gridManager.filters.clear(_columnKey('RISK_GROUP'));
    }

    // LOCATION cells can hold comma-joined values (e.g. "Uptown, Downtown"),
    // so membership needs a substring match rather than exact equality.
    if (_selectedLocations.isNotEmpty) {
      await gridManager.filters.add(
        {_columnKey('LOCATION'): _selectedLocations.toList()},
        comparison: GridSheetFilterComparison.contains,
      );
    } else {
      await gridManager.filters.clear(_columnKey('LOCATION'));
    }

    if (_photoOnly) {
      await gridManager.filters.add({
        _columnKey('PHOTO'): [GridSheetConstants.noBlanksText],
      });
    } else {
      await gridManager.filters.clear(_columnKey('PHOTO'));
    }
  }

  Future<void> _clearFilters() async {
    await gridManager.filters.clearAll();
    setState(() {
      _selectedDatePresets.clear();
      _selectedRiskGroups.clear();
      _selectedLocations.clear();
      _photoOnly = false;
      _minIdController.clear();
      _maxIdController.clear();
    });
  }

  Widget _buildFilterPanel() {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall!.copyWith(color: colors.onPrimary);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.filterPanelColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Filtering',
              style: style.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID', style: style),
                  const SizedBox(height: 8),
                  _numberRangeFilter(),
                  const SizedBox(height: 16),
                  Text('Date Added', style: style),
                  const SizedBox(height: 8),
                  ..._datePresetLookback.keys.map((label) => _filterCheckbox(
                        label,
                        selected: _selectedDatePresets.contains(label),
                        onTap: () => setState(() {
                          if (!_selectedDatePresets.remove(label)) {
                            _selectedDatePresets.add(label);
                          }
                        }),
                      )),
                  const SizedBox(height: 8),
                  Text('Risk Group', style: style),
                  const SizedBox(height: 8),
                  ...['Normal', 'Low Risk', 'High Risk']
                      .map((label) => _filterCheckbox(
                            label,
                            selected: _selectedRiskGroups.contains(label),
                            onTap: () => setState(() {
                              if (!_selectedRiskGroups.remove(label)) {
                                _selectedRiskGroups.add(label);
                              }
                            }),
                          )),
                  const SizedBox(height: 8),
                  Text('Location', style: style),
                  const SizedBox(height: 8),
                  ...['Downtown', 'Uptown', 'Riverside']
                      .map((label) => _filterCheckbox(
                            label,
                            selected: _selectedLocations.contains(label),
                            onTap: () => setState(() {
                              if (!_selectedLocations.remove(label)) {
                                _selectedLocations.add(label);
                              }
                            }),
                          )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Only show with a photo', style: style),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: _photoOnly,
                          activeThumbColor: colors.onPrimary,
                          inactiveThumbColor: colors.onPrimaryMuted,
                          inactiveTrackColor:
                              colors.onPrimary.withValues(alpha: 0.2),
                          onChanged: (val) => setState(() => _photoOnly = val),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: colors.onPrimary),
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.childContainerColor,
                  foregroundColor: colors.primary,
                ),
                onPressed: _applyFilters,
                child: const Text('APPLY'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberRangeFilter() {
    InputDecoration decoration(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: colors.onPrimaryMuted),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.rowBorderColor),
          ),
        );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minIdController,
            style: TextStyle(fontSize: 12, color: colors.onPrimary),
            keyboardType: TextInputType.number,
            decoration: decoration('Min'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _maxIdController,
            style: TextStyle(fontSize: 12, color: colors.onPrimary),
            keyboardType: TextInputType.number,
            decoration: decoration('Max'),
          ),
        ),
      ],
    );
  }

  Widget _filterCheckbox(String label,
      {required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: selected ? colors.onPrimary : colors.onPrimaryMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 12, color: colors.onPrimary))),
          ],
        ),
      ),
    );
  }

  Widget _buildMainWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.gridBorderColor),
            ),
            // The grid content is clipped in its own inset ClipRRect (radius
            // reduced by the border width) rather than via this Container's
            // clipBehavior, so its flush, square-cornered background can
            // never paint over — and hide — the rounded border above it.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                color: colors.gridBackgroundColor,
                child: _buildGridSheet(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridSheet() {
    return GridSheet(
      columns: gridColumns(),
      rows: gridRows(),
      topBarBuilder: (gridManager) => _buildSearchBar(),
      onCellsSelected: (event) {},
      animationConfiguration: GridSheetAnimationConfiguration(enabled: true),
      configuration: GridSheetConfiguration(
        showColumnBorders: false,
        showRowBorders: false,
        rowsPerPage: _rowsPerPage,
        enableRowSelectionOnFirstColumnTap: true,
        enableMultiSelection: true,
      ),
      styleConfiguration: GridSheetStyleConfiguration(
        gridBackgroundColor: colors.gridBackgroundColor,
        headerColor: colors.headerColor,
        filterColor: colors.filterColor,
        rowColor: colors.rowColor,
        selectionColor: colors.selectionColor,
        gridBorderColor: Colors.transparent,
        rowBorderColor: colors.rowBorderColor,
        columnBorderColor: colors.columnBorderColor,
        headerTextStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
        cellTextStyle: TextStyle(fontSize: 12, color: colors.primary),
      ),
      cellBuilder: (cell) {
        switch (cell.kind) {
          case GridSheetCellKind.selectAll:
            return _cellRenderer.buildSelectAll(context, cell);
          case GridSheetCellKind.indexing:
            return _cellRenderer.buildIndexes(context, cell);
          case GridSheetCellKind.header:
            return _cellRenderer.buildHeader(context, cell);
          case GridSheetCellKind.filter:
            return _cellRenderer.buildFilter(context, cell.column, cell);
          case GridSheetCellKind.row:
            return _cellRenderer.buildCell(
                context, cell.column, cell.row!, cell);
        }
      },
      onLoaded: (event) {
        gridManager = event.gridManager;
        recordGridLoadTime();
      },
    );
  }

  Future<void> _addNewRecord() async {
    final cols = gridColumns();
    final newRow = GridSheetRow(
      key: ValueKey('row_new_${DateTime.now().microsecondsSinceEpoch}'),
      index: 0,
      data: List<dynamic>.filled(cols.length, ''),
      height: 40,
      state: GridSheetRowState.inserted,
    );
    await gridManager.rows.insert([newRow]);
  }

  Future<void> _exportCsv() async {
    final csv = gridManager.data.toCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Exported ${gridManager.rows.filteredCount} rows to clipboard as CSV'),
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary, foregroundColor: Colors.white),
          onPressed: _addNewRecord,
          icon: const Icon(Icons.add),
          label: const Text('New'),
        ),
        const SizedBox(width: 12),
        _iconButton(Icons.file_download_outlined, _exportCsv, 'export to csv'),
        const Spacer(),
        LoadTimeLabel(
            style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        _iconButton(
          Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          () {
            final goingDark = Theme.of(context).brightness != Brightness.dark;
            // appThemeMode is the ValueNotifier<ThemeMode> declared alongside
            // GridSheetApp (e.g. in main.dart) and passed to MaterialApp.themeMode.
            appThemeMode.value = goingDark ? ThemeMode.dark : ThemeMode.light;
          },
          Theme.of(context).brightness == Brightness.dark ? 'light' : 'dark',
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.gridBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.gridBorderColor),
        ),
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, color: colors.textPrimary, size: 20),
        ),
      ),
    );
  }

  Future<void> _applySearch(String value) async {
    final query = value.trim();
    // addFilters ANDs across columns (see _applyFiltersToRow in
    // filtering_impl.dart), so there's no single-call way to OR a search
    // term across multiple columns — this scopes the search box to FIRST_NAME.
    if (query.isEmpty) {
      await gridManager.filters.clear(_columnKey('FIRST_NAME'));
    } else {
      await gridManager.filters.add(
        {
          _columnKey('FIRST_NAME'): [query]
        },
        comparison: GridSheetFilterComparison.contains,
      );
    }
  }

  void _showFilterSettings() {
    setState(() => _showFilterPanel = !_showFilterPanel);
  }

  void _showColumnSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: gridManager.columns.all.map((col) {
                  return CheckboxListTile(
                    title: Text(col.title.isEmpty ? col.name : col.title),
                    value: col.visible,
                    onChanged: (checked) async {
                      if (checked == true) {
                        await gridManager.columns.show(gridManager.columns
                            .findByNames([col.name])
                            .map((c) => c.key)
                            .toList());
                      } else {
                        await gridManager.columns.hide(gridManager.columns
                            .findByNames([col.name])
                            .map((c) => c.key)
                            .toList());
                      }
                      setSheetState(() {});
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _iconButton(Icons.tune, _showFilterSettings, 'show/hide filters'),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search..',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.rowBorderColor),
                ),
              ),
              onSubmitted: _applySearch,
              onChanged: _applySearch,
            ),
          ),
          const Spacer(),
          _iconButton(
            Icons.view_column_outlined,
            _showColumnSettings,
            'show/hide columns',
          ),
        ],
      ),
    );
  }
}

class CustomCellsDemoBuilder implements IGridSheetCustomCellBuilder {
  CustomCellsDemoBuilder();

  GridDemoColors _getColors(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? GridDemoColors.dark
          : GridDemoColors.light;

  @override
  Widget buildSelectAll(BuildContext context, GridSheetCellContext cell) {
    final theme = Theme.of(context);

    GridSheetManager? manager = cell.gridManager;
    final visibleRows = manager.config.grid.selectOnlyCurrentPageRows
        ? manager.rows.currentPage
        : manager.rows.all;

    final allSelected =
        visibleRows.isNotEmpty && visibleRows.every((row) => row.isSelected);

    String tooltipMessage;
    if (allSelected) {
      tooltipMessage = 'Deselect all rows';
    } else {
      tooltipMessage = 'Select all rows';
    }

    return Center(
      child: Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 500),
        child: Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: allSelected,
            onChanged: (value) {
              cell.onToggleSelectAllRows?.call(value!);
            },
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: allSelected
                  ? theme.colorScheme.primary
                  : Colors.grey.shade400,
              width: 1.5,
            ),
            activeColor: theme.colorScheme.primary,
            checkColor: theme.colorScheme.onPrimary,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.colorScheme.primary;
              }
              return theme.colorScheme.onPrimary;
            }),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildIndexes(BuildContext context, GridSheetCellContext cell) {
    final theme = Theme.of(context);
    final row = cell.row!;
    final value = row.isSelected;

    return Center(
      child: Transform.scale(
        scale: 0.8,
        child: Checkbox(
          value: value,
          onChanged: (checked) {
            final boolValue = checked ?? false;
            row.isSelected = boolValue;

            if (boolValue) {
              cell.gridManager.selection.selectRows([row.key]);
            } else {
              cell.gridManager.selection.deselectRows([row.key]);
            }
          },
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          side: BorderSide(
            color: value ? theme.colorScheme.primary : Colors.grey.shade400,
            width: 1.5,
          ),
          activeColor: theme.colorScheme.primary,
          checkColor: theme.colorScheme.onPrimary,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return theme.colorScheme.primary;
            }
            return theme.colorScheme.onPrimary;
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
    );
  }

  @override
  Widget buildHeader(BuildContext context, GridSheetCellContext cell) {
    return Text(
      cell.column.title,
      style: cell.textStyle,
    );
  }

  @override
  Widget buildFilter(
    BuildContext context,
    GridSheetColumn column,
    GridSheetCellContext cell,
  ) {
    Widget child;

    if (column.index == -1) {
      child = Center(
        child: InkWell(
          onTap: () {
            cell.gridManager.filters.clearAll();
          },
          child: Icon(Icons.clear_all, size: 20),
        ),
      );
    } else {
      final theme = Theme.of(context);

      final values = cell.gridManager.rows.all
          .map((row) => row.data[column.index])
          .where((e) => e != null)
          .map((e) => e is DateTime ? _formatDate(e) : e.toString())
          .toSet()
          .toList()
        ..sort();

      child = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          hint: Text("All", style: theme.textTheme.bodySmall),
          value: cell.filterController!.text.isEmpty
              ? null
              : cell.filterController!.text,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text("All", style: theme.textTheme.bodySmall),
            ),
            ...values.map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: theme.textTheme.bodySmall),
              ),
            ),
          ],
          onChanged: (value) {
            cell.filterController!.text = value!;
            cell.gridManager.filters.add(
              {
                column.key: [value]
              },
              comparison: column.type.kind == GridSheetColumnKind.datetime
                  ? GridSheetFilterComparison.exact
                  : GridSheetFilterComparison.contains,
            );
          },
        ),
      );
    }

    return child;
  }

  @override
  Widget buildCell(
    BuildContext context,
    GridSheetColumn column,
    GridSheetRow row,
    GridSheetCellContext cell,
  ) {
    if (column.name == 'PHOTO') {
      return _buildPictureWidget(context, column, row);
    } else if (column.name == 'LOCATION') {
      return _buildLocationWidget(context, cell, column, row);
    } else if (column.name == 'RISK_GROUP') {
      return _buildStatusChip(row.data[column.index], cell);
    } else if (column.name == 'ACTIONS') {
      return _buildActionEvents(context, cell, column, row);
    }

    return _buildTextWidget(context, cell, column, row);
  }

  Widget _buildPictureWidget(
    BuildContext context,
    GridSheetColumn column,
    GridSheetRow row,
  ) {
    final url = 'https://i.pravatar.cc/${150 + (row.index)}';

    return ClipOval(
      child: SizedBox(
        width: 28,
        height: 28,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return Container(
              color: _getColors(context).primary.withValues(alpha: 0.08),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: _getColors(context).primary.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: Icon(
                Icons.person,
                size: 16,
                color: _getColors(context).primary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationWidget(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetColumn column,
    GridSheetRow row,
  ) {
    final theme = Theme.of(context);

    final style = cell.textStyle ?? theme.textTheme.bodySmall;
    final value = row.data[column.index];

    return InkWell(
      onTap: () => debugPrint('EVENT: locationLinkTapped -> $value'),
      child: Text(
        value,
        style: style!.copyWith(color: _getColors(context).linkColor),
      ),
    );
  }

  // Widget _buildGroupWidget(
  //   BuildContext context,
  //   GridSheetCellContext cell,
  //   GridSheetColumn column,
  //   GridSheetRow row,
  // ) {
  //   final theme = Theme.of(context);

  //   final style = cell.textStyle ?? theme.textTheme.bodySmall;
  //   final value = row.data[column.index];

  //   return Row(
  //     children: [
  //       Container(
  //         width: 8,
  //         height: 8,
  //         decoration: BoxDecoration(
  //           color: _dotColor(context, value),
  //           shape: BoxShape.circle,
  //         ),
  //       ),
  //       const SizedBox(width: 4),
  //       Text(
  //         value,
  //         style: style!.copyWith(color: _getColors(context).textPrimary),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTextWidget(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetColumn column,
    GridSheetRow row,
  ) {
    final theme = Theme.of(context);

    final style = cell.textStyle ?? theme.textTheme.bodySmall;
    final rawValue = row.data[column.index];
    final displayValue =
        rawValue is DateTime ? _formatDate(rawValue) : rawValue.toString();

    return Align(
      alignment: column.textAlign == TextAlign.right
          ? Alignment.centerRight
          : column.textAlign == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft,
      child: Text(
        displayValue,
        overflow: TextOverflow.ellipsis,
        style: style!.copyWith(
          color: _getColors(context).textPrimary,
          fontWeight: column.name == 'ID' ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: column.textAlign,
      ),
    );
  }

  Widget _buildStatusChip(String status, GridSheetCellContext cell) {
    final color = switch (status) {
      'Normal' => Colors.green,
      'Low Risk' => Colors.orange,
      'High Risk' => Colors.red,
      _ => Colors.grey,
    };

    return SizedBox(
      height: 24,
      width: cell.column.width - 4,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionEvents(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetColumn column,
    GridSheetRow row,
  ) {
    return SizedBox(
      width: 32,
      child: PopupMenuButton<String>(
        tooltip: '',
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 18,
          color: _getColors(context).textSecondary,
        ),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'row_height',
            child: Text('Row height'),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'delete':
              cell.gridManager.rows.delete([row.key]);
              break;
            case 'row_height':
              _showRowHeightDialog(context, cell, row);
              break;
          }
        },
      ),
    );
  }

  Future<void> _showRowHeightDialog(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
  ) async {
    final controller =
        TextEditingController(text: row.height.toStringAsFixed(0));

    final newHeight = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Row height'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height (px)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(double.tryParse(controller.text.trim())),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newHeight == null || newHeight <= 0) return;
    await cell.gridManager.rows.setHeights({row.key: newHeight});
  }

  String _formatDate(DateTime date) {
    String pad2(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${pad2(date.month)}-${pad2(date.day)}';
  }
}
