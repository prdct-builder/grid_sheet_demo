import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';
import 'package:grid_sheet_demo/design_system/grid_demo_colors.dart';

/// Frosted-glass wrapper used throughout this page — blurs whatever is
/// painted behind it, then lays a translucent tint, a light-catching
/// hairline border, and a soft top-left sheen on top. Self-contained here
/// rather than pulled from a shared design system, since this class manages
/// its own [GridDemoColors] rather than the app-wide `HomePalette`.
class _Glassmorphism extends StatelessWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  // Stacking many concurrent `BackdropFilter`s is the single most expensive
  // thing you can do to Flutter Web's CanvasKit renderer — each one is a
  // full offscreen saveLayer + blur pass, and having several on screen at
  // once (sidebar + header + several toolbar buttons + the grid card, say)
  // has been observed to trigger intermittent Skia shader-compile failures
  // under GPU/driver pressure. Small, always-on chrome (toolbar pills, the
  // search box) should pass `blur: false` — same tint/border/sheen look,
  // just without its own blur pass — and only the few large, structurally
  // important surfaces (sidebar, grid card) should actually blur.
  final bool blur;

  const _Glassmorphism({
    required this.child,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blurSigma = 22,
    this.padding,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Flutter can only paint a rounded border with a single
        // uniform color (a per-side "light source" border throws at
        // paint time on rounded corners) — the diagonal sheen layer
        // below carries the top-left-lit look instead.
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // A BoxDecoration silently drops `color` whenever `gradient` is
      // also set, so the theme tint and the sheen are painted as
      // separate stacked layers instead — otherwise the tint never
      // actually renders.
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(color: color)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );

    if (!blur) {
      return ClipRRect(borderRadius: borderRadius, child: content);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}

/// Soft color blobs behind the page — `BackdropFilter` only refracts pixels
/// already painted behind it, so a flat `mainContainerColor` alone gives
/// frosted-flat, not frosted-glass. This gives every [_Glassmorphism] layer above
/// something to actually blur.
class _GlassmorphismBackdrop extends StatelessWidget {
  final GridDemoColors colors;

  const _GlassmorphismBackdrop({required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: colors.mainContainerColor.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            top: -100,
            left: -60,
            child: _blob(colors.primary, 360, 0.20),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: _blob(colors.linkColor, 420, 0.14),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }
}

/// Rotating accent palette for initials avatars (people + suppliers alike),
/// so any name reads as a distinct color at a glance without a legend.
const List<Color> _avatarPalette = [
  Color(0xFF8B5CF6), // purple
  Color(0xFFEC6FA0), // pink
  Color(0xFFF5A742), // orange
  Color(0xFF3DCB83), // green
  Color(0xFF4A90D9), // blue
  Color(0xFF6C63C7), // indigo
  Color(0xFF34B3A6), // teal
];

class GlassmorphismGridSheet extends StatefulWidget {
  const GlassmorphismGridSheet({super.key});

  @override
  State<GlassmorphismGridSheet> createState() => _GlassmorphismGridSheetState();
}

class _GlassmorphismGridSheetState extends State<GlassmorphismGridSheet> {
  late GridSheetManager gridManager;

  /// Resolves a column name to its key — the manager's column methods are
  /// key-addressed.
  ValueKey<String> _columnKey(String name) =>
      gridManager.columns.findByNames([name]).single.key;

  final CustomCellsDemoBuilder _cellRenderer = CustomCellsDemoBuilder();

  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _selectedDepartments = {};
  final Set<String> _selectedStatuses = {};

  final int _rowsPerPage = 10;

  static const List<String> _departments = [
    'Engineering',
    'Design',
    'Marketing',
    'Finance',
    'HR',
    'Sales',
    'Support',
  ];
  static const List<String> _statuses = ['Active', 'Pending', 'Inactive'];

  GridDemoColors get colors => GridDemoColors.dark;

  @override
  void dispose() {
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<GridSheetColumn> gridColumns() {
    return [
      GridSheetColumn(
        key: const ValueKey('col_id'),
        index: 0,
        name: 'ID',
        title: 'ID',
        type: GridSheetColumnType.integer(),
        width: 60,
        sortable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_name'),
        index: 1,
        name: 'NAME',
        title: 'Name',
        type: GridSheetColumnType.custom(),
        width: 150,
        sortable: true,
        resizable: true,
        hasTextController: false,
      ),
      GridSheetColumn(
        key: const ValueKey('col_email'),
        index: 2,
        name: 'EMAIL',
        title: 'Email',
        type: GridSheetColumnType.text(),
        width: 200,
        sortable: true,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_department'),
        index: 3,
        name: 'DEPARTMENT',
        title: 'Department',
        type: GridSheetColumnType.text(),
        width: 110,
        sortable: true,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_role'),
        index: 4,
        name: 'ROLE',
        title: 'Role',
        type: GridSheetColumnType.text(),
        width: 140,
        sortable: true,
        resizable: true,
      ),
      GridSheetColumn(
        key: const ValueKey('col_status'),
        index: 5,
        name: 'STATUS',
        title: 'Status',
        type: GridSheetColumnType.text(),
        width: 100,
        hasTextController: false,
      ),
      GridSheetColumn(
        key: const ValueKey('col_join_date'),
        index: 6,
        name: 'JOIN_DATE',
        title: 'Join Date',
        type: GridSheetColumnType.datetime(),
        width: 100,
        sortable: true,
        hasTextController: false,
      ),
      GridSheetColumn(
        key: const ValueKey('col_salary'),
        index: 7,
        name: 'SALARY',
        title: 'Salary',
        type: GridSheetColumnType.integer(),
        width: 90,
        sortable: true,
        textAlign: TextAlign.right,
        maxStretchWidth: 100,
      ),
      GridSheetColumn(
        key: const ValueKey('col_actions'),
        index: 8,
        name: 'ACTIONS',
        title: 'Actions',
        type: GridSheetColumnType.custom(),
        width: 75,
        textAlign: TextAlign.center,
        // Not pinnedRight: pinning interacted badly with the glass card's
        // ClipRRect/BackdropFilter — the pinned column painted outside the
        // card's clipped, blurred bounds instead of staying inside it.
      ),
    ];
  }

  List<GridSheetRow> gridRows() {
    const firstNames = [
      'Aarav', 'Priya', 'Rohan', 'Sneha', 'Vikram', 'Meera', 'Arjun',
      'Kavya', //
      'Ishaan', 'Ananya', 'Kabir', 'Diya', 'Rahul', 'Neha', 'Aditya',
      'Pooja', //
      'Karan', 'Riya', 'Aryan', 'Tanya', 'Yash', 'Simran', 'Dev', 'Anika', //
      'Vivaan', 'Mira', 'Rohit', 'Sara', 'Nikhil', 'Isha', 'Manav', 'Trisha', //
      'Aakash', 'Radha', 'Sameer', 'Divya', 'Harsh', 'Nidhi', 'Om', 'Kiara', //
      'Ravi', 'Alia',
    ];
    const lastNames = [
      'Shah', 'Reddy', 'Kapoor', 'Nair', 'Kumar', 'Yadav', 'Bansal',
      'Thomas', //
      'Mehta', 'Singh', 'Verma', 'Iyer', 'Joshi', 'Gupta', 'Rao', 'Malhotra', //
      'Sharma', 'Chopra', 'Desai', 'Pillai',
    ];

    // (department, role) — cycled by row index so every department gets
    // several rows, matching how sample.png's table spans varied teams.
    const deptRoles = [
      ('Engineering', 'Software Engineer'),
      ('Engineering', 'DevOps Engineer'),
      ('Engineering', 'QA Engineer'),
      ('Design', 'UI/UX Designer'),
      ('Design', 'Product Designer'),
      ('Marketing', 'Marketing Manager'),
      ('Marketing', 'Content Strategist'),
      ('Finance', 'Financial Analyst'),
      ('Finance', 'Accountant'),
      ('HR', 'HR Manager'),
      ('HR', 'Recruiter'),
      ('Sales', 'Sales Executive'),
      ('Sales', 'Account Manager'),
      ('Support', 'Support Specialist'),
    ];

    // Mostly 'Active', with 'Pending'/'Inactive' sprinkled in — mirrors
    // sample.png's mix without every third row being an exception.
    const statusCycle = [
      'Active', 'Active', 'Active', 'Pending', //
      'Active', 'Inactive', 'Active', 'Active', //
    ];

    const baseSalaryByRole = {
      'Software Engineer': 95000,
      'DevOps Engineer': 98000,
      'QA Engineer': 78000,
      'UI/UX Designer': 85000,
      'Product Designer': 88000,
      'Marketing Manager': 75000,
      'Content Strategist': 62000,
      'Financial Analyst': 70000,
      'Accountant': 64000,
      'HR Manager': 65000,
      'Recruiter': 58000,
      'Sales Executive': 60000,
      'Account Manager': 68000,
      'Support Specialist': 55000,
    };

    final now = DateTime.now();

    return List<GridSheetRow>.generate(42, (i) {
      final first = firstNames[i % firstNames.length];
      final last = lastNames[(i * 3 + 7) % lastNames.length];
      final (department, role) = deptRoles[i % deptRoles.length];
      final status = statusCycle[i % statusCycle.length];
      final joinDate = now.subtract(Duration(days: 30 + (i * 17) % 700));
      final salary = baseSalaryByRole[role]! + (i % 7) * 1500;

      return GridSheetRow(
        key: ValueKey('row_$i'),
        index: i,
        height: 44,
        data: [
          1000 + i,
          '$first $last',
          '${first.toLowerCase()}.${last.toLowerCase()}@example.com',
          department,
          role,
          status,
          joinDate,
          salary,
          '',
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/branding/bg_image.webp',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: _GlassmorphismBackdrop(colors: colors)),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMainColumn()),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Main column: page header, toolbar, then the grid card.
  // ---------------------------------------------------------------------

  Widget _buildMainColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(),
        const SizedBox(height: 12),
        _buildToolbar(),
        const SizedBox(height: 8),
        Expanded(
          child: _Glassmorphism(
            blurSigma: 4,
            color: colors.gridBackgroundColor.withValues(alpha: 0.20),
            child: _buildGridSheet(),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GridSheet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage and explore your data efficiently',
                style: TextStyle(fontSize: 13, color: colors.onPrimaryMuted),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 220,
          height: 36,
          child: _Glassmorphism(
            color: colors.childContainerColor.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(10),
            blur: false,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // _Glassmorphism's Stack places a non-positioned child at the
            // default top-left, so without this the field (and its cursor)
            // sits pinned to the top of the 36px-tall pill instead of
            // centered in it.
            child: Center(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: colors.onPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle:
                      TextStyle(color: colors.onPrimaryMuted, fontSize: 12),
                  isDense: true,
                  icon: Icon(Icons.search,
                      size: 16, color: colors.onPrimaryMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: _applySearch,
                onChanged: _applySearch,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildAvatar(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Text(
        'GS',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Toolbar — Add New / Export on the left, Filter / Columns on the right.
  // ---------------------------------------------------------------------

  Widget _buildToolbar() {
    return Row(
      children: [
        _gradientButton(
          icon: Icons.add,
          label: 'New',
          onTap: _addNewRecord,
        ),
        const SizedBox(width: 10),
        _glassPillButton(
          icon: Icons.file_download_outlined,
          label: 'Export',
          onTap: _exportCsv,
        ),
        const Spacer(),
        MenuAnchor(
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
            elevation: WidgetStatePropertyAll(0),
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          builder: (context, controller, child) {
            return _glassPillButton(
              icon: Icons.filter_list,
              label: 'Filter',
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            );
          },
          menuChildren: [_buildFilterMenu()],
        ),
        const SizedBox(width: 10),
        _glassPillButton(
          icon: Icons.view_column_outlined,
          label: 'Columns',
          onTap: _showColumnSettings,
        ),
      ],
    );
  }

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF4A90D9)],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _Glassmorphism(
      color: colors.gridBackgroundColor.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(10),
      blurSigma: 4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: colors.onPrimary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 15, color: colors.onPrimaryMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Filter popover — replaces the old sidebar filter panel now that the
  // sidebar is app navigation. Department + Status checkboxes and a
  // salary range, matching the columns actually in this table.
  // ---------------------------------------------------------------------

  Widget _buildFilterMenu() {
    final sectionLabelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: colors.onPrimaryMuted,
    );

    return SizedBox(
      width: 260,
      child: _Glassmorphism(
        color: colors.filterPanelColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        blurSigma: 24,
        padding: const EdgeInsets.all(14),
        child: StatefulBuilder(
          builder: (context, setMenuState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SALARY', style: sectionLabelStyle),
                const SizedBox(height: 8),
                _numberRangeFilter(),
                const SizedBox(height: 14),
                Text('DEPARTMENT', style: sectionLabelStyle),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _departments
                          .map((label) => _filterCheckbox(
                                label,
                                selected: _selectedDepartments.contains(label),
                                onTap: () => setMenuState(() {
                                  setState(() {
                                    if (!_selectedDepartments.remove(label)) {
                                      _selectedDepartments.add(label);
                                    }
                                  });
                                }),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('STATUS', style: sectionLabelStyle),
                const SizedBox(height: 4),
                ..._statuses.map((label) => _filterCheckbox(
                      label,
                      selected: _selectedStatuses.contains(label),
                      onTap: () => setMenuState(() {
                        setState(() {
                          if (!_selectedStatuses.remove(label)) {
                            _selectedStatuses.add(label);
                          }
                        });
                      }),
                    )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: colors.onPrimary),
                      onPressed: () => setMenuState(() => _clearFilters()),
                      child: const Text('Clear'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colors.childContainerColor.withValues(alpha: 0.9),
                        foregroundColor: colors.primary,
                      ),
                      onPressed: _applyFilters,
                      child: const Text('APPLY'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _numberRangeFilter() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: colors.rowBorderColor.withValues(alpha: 0.35),
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(
        color: colors.primary.withValues(alpha: 0.6),
      ),
    );

    InputDecoration decoration(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: colors.onPrimaryMuted),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: border,
          enabledBorder: border,
          focusedBorder: focusedBorder,
        );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minSalaryController,
            style: TextStyle(fontSize: 12, color: colors.onPrimary),
            keyboardType: TextInputType.number,
            decoration: decoration('Min'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _maxSalaryController,
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

  Future<void> _applyFilters() async {
    final minText = _minSalaryController.text.trim();
    final maxText = _maxSalaryController.text.trim();
    if (minText.isNotEmpty && maxText.isNotEmpty) {
      await gridManager.filters.add(
        {
          _columnKey('SALARY'): ['$minText-$maxText']
        },
        comparison: GridSheetFilterComparison.between,
      );
    } else if (minText.isNotEmpty) {
      await gridManager.filters.add(
        {
          _columnKey('SALARY'): [minText]
        },
        comparison: GridSheetFilterComparison.greaterThanOrEqual,
      );
    } else if (maxText.isNotEmpty) {
      await gridManager.filters.add(
        {
          _columnKey('SALARY'): [maxText]
        },
        comparison: GridSheetFilterComparison.lessThanOrEqual,
      );
    } else {
      await gridManager.filters.clear(_columnKey('SALARY'));
    }

    if (_selectedDepartments.isNotEmpty) {
      await gridManager.filters.add(
        {_columnKey('DEPARTMENT'): _selectedDepartments.toList()},
        comparison: GridSheetFilterComparison.exact,
      );
    } else {
      await gridManager.filters.clear(_columnKey('DEPARTMENT'));
    }

    if (_selectedStatuses.isNotEmpty) {
      await gridManager.filters.add(
        {_columnKey('STATUS'): _selectedStatuses.toList()},
        comparison: GridSheetFilterComparison.exact,
      );
    } else {
      await gridManager.filters.clear(_columnKey('STATUS'));
    }
  }

  Future<void> _clearFilters() async {
    await gridManager.filters.clearAll();
    setState(() {
      _selectedDepartments.clear();
      _selectedStatuses.clear();
      _minSalaryController.clear();
      _maxSalaryController.clear();
    });
  }

  Future<void> _applySearch(String value) async {
    final query = value.trim();
    // addFilters ANDs across columns (see _applyFiltersToRow in
    // filtering_impl.dart), so there's no single-call way to OR a search
    // term across multiple columns — this scopes the search box to NAME.
    if (query.isEmpty) {
      await gridManager.filters.clear(_columnKey('NAME'));
    } else {
      await gridManager.filters.add(
        {
          _columnKey('NAME'): [query]
        },
        comparison: GridSheetFilterComparison.contains,
      );
    }
  }

  // ---------------------------------------------------------------------
  // Grid + pagination footer.
  // ---------------------------------------------------------------------

  Widget _buildGridSheet() {
    return GridSheet(
      columns: gridColumns(),
      rows: gridRows(),
      configuration: GridSheetConfiguration(
        showColumnBorders: false,
        showRowBorders: false,
        rowsPerPage: _rowsPerPage,
        enableRowSelectionOnFirstColumnTap: true,
        enableMultiSelection: true,
        enableDefaultPagination: false,
        enableCustomPagination: true,
        stretchColumnsToFillWidth: true,
      ),
      styleConfiguration: GridSheetStyleConfiguration(
        gridBackgroundColor: Colors.transparent,
        gridBorderColor: Colors.transparent,
        headerColor: Colors.transparent,
        filterColor: Colors.transparent,
        rowColor: Colors.transparent,
        selectionColor: colors.selectionColor.withValues(alpha: 0.5),
        rowBorderColor: colors.rowBorderColor.withValues(alpha: 0.20),
        columnBorderColor: colors.columnBorderColor.withValues(alpha: 0.20),
        headerTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
      bottomBarBuilder: (manager) => _buildPaginationFooter(manager),
      onLoaded: (event) {
        gridManager = event.gridManager;
        recordGridLoadTime();
      },
    );
  }

  Widget _buildPaginationFooter(GridSheetManager manager) {
    final total = manager.rows.filteredCount;
    final perPage = manager.pagination.rowsPerPage;
    final current = manager.pagination.current;
    final totalPages =
        manager.pagination.totalPages == 0 ? 1 : manager.pagination.totalPages;
    final startRow = total == 0 ? 0 : (current - 1) * perPage + 1;
    final endRow =
        total == 0 ? 0 : startRow + manager.rows.currentPageCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.rowBorderColor.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Showing $startRow to $endRow of $total entries',
            style: TextStyle(fontSize: 12, color: colors.onPrimaryMuted),
          ),
          const Spacer(),
          _pageArrow(Icons.chevron_left,
              current > 1 ? () => manager.pagination.previous() : null),
          ..._pageNumbers(current, totalPages).map((page) => page == -1
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('…'),
                )
              : _pageNumberButton(
                  page, page == current, () => manager.pagination.goTo(page))),
          _pageArrow(Icons.chevron_right,
              current < totalPages ? () => manager.pagination.next() : null),
          const SizedBox(width: 16),
          _rowsPerPageDropdown(manager),
        ],
      ),
    );
  }

  /// Compact page-number list with an ellipsis for gaps, e.g. `1 … 4 5 6 … 16`.
  List<int> _pageNumbers(int current, int total) {
    if (total <= 7) return List.generate(total, (i) => i + 1);

    final pages = <int>{1, total, current};
    if (current > 1) pages.add(current - 1);
    if (current < total) pages.add(current + 1);
    final sorted = pages.toList()..sort();

    final result = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(-1);
      result.add(sorted[i]);
    }
    return result;
  }

  Widget _pageArrow(IconData icon, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: colors.onPrimaryMuted,
      onPressed: onTap,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _pageNumberButton(int page, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : colors.onPrimaryMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowsPerPageDropdown(GridSheetManager manager) {
    const options = [10, 25, 50];

    // Same glass-pill shell as _glassPillButton (Filter/Columns/Export) so
    // the footer's dropdown reads as part of the same button family instead
    // of a bare stock DropdownButton.
    return _Glassmorphism(
      color: colors.gridBackgroundColor.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(10),
      blurSigma: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: manager.pagination.rowsPerPage,
            isDense: true,
            dropdownColor: colors.filterPanelColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
            style: TextStyle(
              fontSize: 13,
              color: colors.onPrimary,
              fontWeight: FontWeight.w500,
            ),
            icon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.expand_more,
                  size: 15, color: colors.onPrimaryMuted),
            ),
            selectedItemBuilder: (context) => options
                .map((n) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.table_rows_outlined,
                            size: 15, color: colors.onPrimary),
                        const SizedBox(width: 6),
                        Text('$n / page'),
                      ],
                    ))
                .toList(),
            items: options
                .map(
                    (n) => DropdownMenuItem(value: n, child: Text('$n / page')))
                .toList(),
            onChanged: (value) {
              if (value != null) manager.pagination.setRowsPerPage(value);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addNewRecord() async {
    // Blank strings on every column broke the STATUS pill, the NAME avatar,
    // and SALARY/JOIN_DATE formatting (they expect an int/DateTime, not
    // ''), so the inserted row rendered wrong instead of just empty. Seed
    // it with values that render correctly and are obviously placeholders,
    // ready to edit in place.
    final existingIds =
        gridManager.rows.all.map((row) => row.data[0] as int).toList();
    final nextId = existingIds.isEmpty
        ? 1000
        : existingIds.reduce((a, b) => a > b ? a : b) + 1;

    final newRow = GridSheetRow(
      key: ValueKey('row_new_${DateTime.now().microsecondsSinceEpoch}'),
      index: 0,
      data: [
        nextId,
        'New Employee',
        '',
        'Engineering',
        'New Hire',
        'Active',
        DateTime.now(),
        50000,
        '',
      ],
      height: 44,
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

  void _showColumnSettings() {
    showModalBottomSheet<void>(
      backgroundColor: colors.filterPanelColor.withValues(alpha: 0.9),
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: _Glassmorphism(
                color: colors.filterPanelColor.withValues(alpha: 0.9),
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
              ),
            );
          },
        );
      },
    );
  }
}

class CustomCellsDemoBuilder implements IGridSheetCustomCellBuilder {
  CustomCellsDemoBuilder();

  GridDemoColors _getColors(BuildContext context) => GridDemoColors.dark;

  @override
  Widget buildSelectAll(BuildContext context, GridSheetCellContext cell) {
    final theme = Theme.of(context);

    GridSheetManager? manager = cell.gridManager;
    final visibleRows = manager.config.grid.selectOnlyCurrentPageRows
        ? manager.rows.currentPage
        : manager.rows.all;

    final allSelected =
        visibleRows.isNotEmpty && visibleRows.every((row) => row.isSelected);

    return Center(
      child: Tooltip(
        message: allSelected ? 'Deselect all rows' : 'Select all rows',
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
            activeColor: theme.colorScheme.primary,
            checkColor: theme.colorScheme.onPrimary,
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.colorScheme.primary;
              }
              return Colors.transparent;
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
          activeColor: theme.colorScheme.primary,
          checkColor: theme.colorScheme.onPrimary,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return theme.colorScheme.primary;
            }
            return Colors.transparent;
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
    // Filtering lives in the toolbar's "Filter" popover instead of a
    // per-column filter row (showColumnFilters defaults to false, so this
    // is never actually shown — kept only to satisfy the interface).
    return const SizedBox.shrink();
  }

  @override
  Widget buildCell(
    BuildContext context,
    GridSheetColumn column,
    GridSheetRow row,
    GridSheetCellContext cell,
  ) {
    switch (column.name) {
      case 'NAME':
        return _buildNameCell(context, row.data[column.index].toString());
      case 'STATUS':
        return _buildStatusChip(row.data[column.index].toString(), column);
      case 'SALARY':
        return _buildSalaryText(context, cell, row.data[column.index]);
      case 'ACTIONS':
        return _buildActionEvents(context, cell, row);
      default:
        return _buildTextWidget(context, cell, column, row);
    }
  }

  Widget _buildNameCell(BuildContext context, String name) {
    final colors = _getColors(context);
    final avatarColor =
        _avatarPalette[name.hashCode.abs() % _avatarPalette.length];
    final initials = _initialsFor(name);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: avatarColor),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  Widget _buildStatusChip(String status, GridSheetColumn column) {
    final color = switch (status) {
      'Active' => const Color(0xFF3DCB83),
      'Pending' => const Color(0xFFF5A742),
      'Inactive' => const Color(0xFF8B5CF6),
      _ => const Color(0xFF9AA0B4),
    };

    // A soft tinted pill instead of a solid saturated block — the glass
    // panels around it are all translucent, so a fully opaque chip reads as
    // a flat sticker glued on top rather than part of the same surface.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 22,
        width: column.width - 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color.lerp(color, Colors.white, 0.25),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSalaryText(
    BuildContext context,
    GridSheetCellContext cell,
    Object? rawValue,
  ) {
    final colors = _getColors(context);
    final salary = num.tryParse(rawValue.toString())?.toInt() ?? 0;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '\$${_withThousandsSeparator(salary)}',
        style: (cell.textStyle ?? const TextStyle(fontSize: 12)).copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _withThousandsSeparator(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

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
        ),
        textAlign: column.textAlign,
      ),
    );
  }

  Widget _buildActionEvents(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
  ) {
    final colors = _getColors(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('View => ${row.data[1]}'),
              duration: const Duration(seconds: 1),
            ),
          ),
          child: Icon(Icons.remove_red_eye_outlined,
              size: 16, color: colors.textSecondary),
        ),
        const SizedBox(width: 12),
        Builder(
          builder: (menuContext) {
            return InkWell(
              onTap: () => _showCellMenu(
                menuContext,
                cell,
                row,
              ),
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Future<void> _showCellMenu(
    BuildContext context,
    dynamic cell,
    dynamic row,
  ) async {
    final colors = _getColors(context);

    final RenderBox button = context.findRenderObject() as RenderBox;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset position = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    final value = await showMenu<String>(
      context: context,
      color: colors.filterPanelColor.withValues(alpha: 0.9),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        position.dx + button.size.width,
        position.dy,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'row_height',
          child: Text('Row height'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );

    if (value == null || !context.mounted) return;

    switch (value) {
      case 'delete':
        cell.gridManager?.rows.delete([row.key]);
        break;

      case 'row_height':
        _showRowHeightDialog(context, cell, row);
        break;
    }
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
