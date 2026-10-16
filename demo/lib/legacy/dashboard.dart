import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';

/// Reserved status hue — never reused for series/brand identity, always
/// paired with an icon and a label so meaning never rides on color alone.
const _statusGood = Color(0xFF0CA30C);

/// A dashboard page showcasing three independent [GridSheet] tables, each
/// hosted inside its own card with a header that exposes column-visibility
/// controls and CRUD row operations.
class TableDashboardExample extends StatelessWidget {
  const TableDashboardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const _DashboardHeader(),
                _DashboardTableCard(
                  staggerIndex: 0,
                  icon: Icons.groups_rounded,
                  accentColor: const Color(0xFF6C5CE7),
                  title: 'Team Directory',
                  subtitle: 'Employee roster and organizational data',
                  dataset: _employeeDataset,
                ),
                _DashboardTableCard(
                  staggerIndex: 1,
                  icon: Icons.point_of_sale_rounded,
                  accentColor: const Color(0xFF00B894),
                  title: 'Sales Orders',
                  subtitle: 'Recent customer orders and revenue',
                  dataset: _salesDataset,
                ),
                _DashboardTableCard(
                  staggerIndex: 2,
                  icon: Icons.inventory_2_rounded,
                  accentColor: const Color(0xFFE17055),
                  title: 'Inventory',
                  subtitle: 'Stock levels across warehouses',
                  dataset: _inventoryDataset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const brand = Color(0xFF2A78D6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPERATIONS',
                style: textTheme.labelSmall?.copyWith(
                  color: brand,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Table Dashboard',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Team, sales and inventory data at a glance — toggle columns '
                'or manage rows directly from each card.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _LiveBadge(),
        const SizedBox(width: 8),
        const LoadTimeLabel(),
        _ThemeToggleButton(colorScheme: colorScheme),
      ],
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _statusGood,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Live data',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ThemeToggleButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (_, themeMode, __) {
        final isDark = themeMode == ThemeMode.dark;
        return Tooltip(
          message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () =>
                appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Reusable dashboard table card
// ============================================================================

class _DashboardTableCard extends StatefulWidget {
  final int staggerIndex;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final _TableDataset dataset;

  const _DashboardTableCard({
    required this.staggerIndex,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.dataset,
  });

  @override
  State<_DashboardTableCard> createState() => _DashboardTableCardState();
}

class _DashboardTableCardState extends State<_DashboardTableCard> {
  late GridSheetManager _gridManager;
  bool _loaded = false;
  bool _hovering = false;
  int _rowCount = 0;

  @override
  void initState() {
    super.initState();
    _rowCount = widget.dataset.sampleRows().length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _FadeSlideIn(
      delay: Duration(milliseconds: 90 * widget.staggerIndex),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow
                    .withValues(alpha: _hovering ? 0.16 : 0.07),
                blurRadius: _hovering ? 26 : 14,
                offset: Offset(0, _hovering ? 12 : 6),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colorScheme),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                SizedBox(height: 220, child: _buildGrid(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            widget.accentColor.withValues(alpha: 0.10),
            colorScheme.surface,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, color: widget.accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _CountChip(
                        key: ValueKey(_rowCount),
                        count: _rowCount,
                        color: widget.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (_loaded)
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                _ColumnVisibilityButton(
                  managerGetter: () => _gridManager,
                  accentColor: widget.accentColor,
                ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: colorScheme.outlineVariant,
                ),
                _HoverIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Add row',
                  color: widget.accentColor,
                  onPressed: _addRow,
                ),
                _HoverIconButton(
                  icon: Icons.copy_all_rounded,
                  tooltip: 'Duplicate selected',
                  color: colorScheme.tertiary,
                  onPressed: _duplicateRows,
                ),
                _HoverIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete selected',
                  color: colorScheme.error,
                  onPressed: _deleteRows,
                ),
                _HoverIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh data',
                  color: colorScheme.primary,
                  onPressed: _refresh,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridSheet(
      columns: _buildColumns(),
      rows: _buildRows(widget.dataset.sampleRows()),
      rowsLoader: () async => _buildRows(widget.dataset.sampleRows()),
      conditionalFormatRules: widget.dataset.formatRules(isDark),
      configuration: GridSheetConfiguration(
        rowsPerPage: 5,
        enableMultiSelection: true,
        enableCellSelection: true,
        enableColumnSelection: true,
        enableRowSelectionOnFirstColumnTap: true,
        enableColumnReorder: true,
        enableRowReorder: true,
        enableRowResize: false,
        showColumnBorders: false,
      ),
      autoFillConfiguration: const GridSheetAutoFillConfiguration(
        enabled: true,
      ),
      styleConfiguration: GridSheetStyleConfiguration(
        gridBackgroundColor: colorScheme.surface,
        gridBorderColor: Colors.transparent,
        gridBorderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        headerColor: colorScheme.surfaceContainerHighest,
        filterColor: colorScheme.surfaceContainerHighest,
        rowColor: colorScheme.surface,
        evenRowColor: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        oddRowColor: colorScheme.surface,
        hoverColorOnRow: widget.accentColor.withValues(alpha: 0.06),
        selectionColor: widget.accentColor,
        rowBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.4),
        columnBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.4),
        leftPadding: 10,
        rightPadding: 10,
      ),
      onLoaded: (event) {
        _gridManager = event.gridManager;
        setState(() {
          _loaded = true;
          _rowCount = _gridManager.rows.all.length;
        });
        recordGridLoadTime();
      },
    );
  }

  List<GridSheetColumn> _buildColumns() {
    final specs = widget.dataset.columns;
    return List.generate(specs.length, (index) {
      final spec = specs[index];
      return GridSheetColumn(
        key: ValueKey(
          '${GridSheetConstants.columnCopyKeyStartsWith}${widget.title}_$index',
        ),
        index: index,
        name: spec.name,
        title: spec.title,
        description: spec.description,
        type: spec.type,
        width: spec.width,
        textAlign: spec.align,
        pinnedLeft: spec.pinnedLeft,
        editable: spec.editable,
        sortable: true,
        resizable: true,
        hasTextController: spec.type.kind != GridSheetColumnKind.boolean,
      );
    });
  }

  List<GridSheetRow> _buildRows(List<List<dynamic>> rawRows) {
    return List.generate(rawRows.length, (index) {
      return GridSheetRow(
        key: ValueKey('${GridSheetConstants.rowKeyStartsWith}$index'),
        index: index,
        data: rawRows[index],
        height: 30,
      );
    });
  }

  dynamic _defaultValueFor(GridSheetColumn column) {
    switch (column.type.kind) {
      case GridSheetColumnKind.boolean:
        return false;
      case GridSheetColumnKind.integer:
        return 0;
      case GridSheetColumnKind.double:
        return 0.0;
      case GridSheetColumnKind.dropdown:
        final options = column.dropdownOptions!;
        return options.isNotEmpty ? options.first : null;
      case GridSheetColumnKind.datetime:
      case GridSheetColumnKind.formula:
        return null;
      case GridSheetColumnKind.text:
      case GridSheetColumnKind.custom:
        return '';
    }
  }

  Future<void> _addRow() async {
    final data = _buildColumns().map(_defaultValueFor).toList();
    final row = GridSheetRow(
      key: ValueKey(
        '${GridSheetConstants.rowKeyStartsWith}new_${_rowCount + 1}',
      ),
      index: 0,
      data: data,
      state: GridSheetRowState.inserted,
      height: 30,
    );
    await _gridManager.rows.insertAt(
      _gridManager.rows.all.isNotEmpty ? _gridManager.rows.all.first.key : null,
      [row],
    );
    if (!mounted) return;
    setState(() => _rowCount = _gridManager.rows.all.length);
    _snack('New row added');
  }

  Future<void> _deleteRows() async {
    final keys = _gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      _snack('Select one or more rows to delete');
      return;
    }
    final deleted = await _gridManager.rows.delete(keys.toList());
    if (!mounted) return;
    setState(() => _rowCount = _gridManager.rows.all.length);
    _snack('${deleted.length} row${deleted.length == 1 ? '' : 's'} deleted');
  }

  Future<void> _duplicateRows() async {
    final keys = _gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      _snack('Select one or more rows to duplicate');
      return;
    }
    final newKeys = List.generate(
      keys.length,
      (_) => ValueKey<String>(
        '${GridSheetConstants.rowCopyKeyStartsWith}${_rowCount + 1}',
      ),
    );
    await _gridManager.rows.duplicate(keys.toList(), newKeys);
    if (!mounted) return;
    setState(() => _rowCount = _gridManager.rows.all.length);
    _snack('Row${keys.length == 1 ? '' : 's'} duplicated');
  }

  Future<void> _refresh() async {
    final hidden = _gridManager.columns.hidden.map((c) => c.key).toList();
    if (hidden.isNotEmpty) {
      await _gridManager.columns.show(hidden);
    }
    await _gridManager.reload();
    if (!mounted) return;
    setState(() => _rowCount = _gridManager.rows.all.length);
    _snack('Data refreshed');
  }

  void _snack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: widget.accentColor,
      ),
    );
  }
}

// ============================================================================
// Small building blocks
// ============================================================================

class _CountChip extends StatelessWidget {
  final int count;
  final Color color;

  const _CountChip({super.key, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count rows',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Icon button with an animated hover-highlight background.
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _hovering
                  ? widget.color.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 18, color: widget.color),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides its child in after an optional [delay], used to
/// stagger the entrance of the dashboard cards.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// A popover, opened from a header icon button, that lists every column
/// with a checkbox bound to [GridSheetColumn.visible] and toggles
/// visibility live via [GridSheetManager.showColumns] / [hideColumns].
class _ColumnVisibilityButton extends StatefulWidget {
  final GridSheetManager Function() managerGetter;
  final Color accentColor;

  const _ColumnVisibilityButton({
    required this.managerGetter,
    required this.accentColor,
  });

  @override
  State<_ColumnVisibilityButton> createState() =>
      _ColumnVisibilityButtonState();
}

class _ColumnVisibilityButtonState extends State<_ColumnVisibilityButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  GridSheetManager get _manager => widget.managerGetter();

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  void _toggleMenu() => _open ? _close() : _openMenu();

  void _openMenu() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _open = false);
  }

  Future<void> _setVisible(GridSheetColumn column, bool visible) async {
    if (visible) {
      await _manager.columns.show(_manager.columns
          .findByNames([column.name])
          .map((c) => c.key)
          .toList());
    } else {
      await _manager.columns.hide(_manager.columns
          .findByNames([column.name])
          .map((c) => c.key)
          .toList());
    }
    _entry?.markNeedsBuild();
  }

  Widget _buildOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    final columns = _manager.columns.all;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.94 + (0.06 * t),
                alignment: Alignment.topRight,
                child: child,
              ),
            ),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainerHigh,
              child: Container(
                width: 240,
                constraints: const BoxConstraints(maxHeight: 320),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 8, 8),
                      child: Row(
                        children: [
                          Text(
                            'COLUMNS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () async {
                              await _manager.columns.show(
                                columns.map((c) => c.key).toList(),
                              );
                              _entry?.markNeedsBuild();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Show all',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.accentColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: columns.length,
                        itemBuilder: (context, i) {
                          final column = columns[i];
                          return CheckboxListTile(
                            value: column.visible,
                            onChanged: (v) => _setVisible(column, v ?? true),
                            title: Text(
                              column.title,
                              style: const TextStyle(fontSize: 13),
                            ),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: widget.accentColor,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CompositedTransformTarget(
      link: _link,
      child: _HoverIconButton(
        icon: Icons.view_column_outlined,
        tooltip: 'Show / hide columns',
        color: _open ? widget.accentColor : colorScheme.onSurfaceVariant,
        onPressed: _toggleMenu,
      ),
    );
  }
}

// ============================================================================
// Sample datasets — each table owns its own columns and rows.
// ============================================================================

class _ColumnSpec {
  final String name;
  final String title;
  final String? description;
  final GridSheetColumnType type;
  final double width;
  final TextAlign align;
  final bool pinnedLeft;
  final bool editable;

  const _ColumnSpec({
    required this.name,
    required this.title,
    this.description,
    required this.type,
    this.width = 130,
    this.align = TextAlign.left,
    this.pinnedLeft = false,
    this.editable = true,
  });
}

class _TableDataset {
  final List<_ColumnSpec> columns;
  final List<List<dynamic>> Function() sampleRows;
  final List<GridSheetConditionalFormatRule> Function(bool isDark) formatRules;

  const _TableDataset({
    required this.columns,
    required this.sampleRows,
    this.formatRules = _noFormatRules,
  });
}

List<GridSheetConditionalFormatRule> _noFormatRules(bool isDark) => const [];

/// Badge text color that stays legible against both the pastel (light
/// mode) and deep-tinted (dark mode) conditional-format backgrounds.
TextStyle _badgeTextStyle(bool isDark) => TextStyle(
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937),
    );

// ---- Team directory -------------------------------------------------------

const _employeeDataset = _TableDataset(
  columns: [
    _ColumnSpec(
      name: 'ID',
      title: 'ID',
      type: GridSheetColumnType.text(),
      width: 90,
      pinnedLeft: true,
      editable: false,
    ),
    _ColumnSpec(
      name: 'NAME',
      title: 'Employee',
      type: GridSheetColumnType.text(),
      width: 170,
    ),
    _ColumnSpec(
      name: 'DEPARTMENT',
      title: 'Department',
      type: GridSheetColumnType.dropdown(options: [
        'Engineering',
        'Design',
        'Marketing',
        'Sales',
        'Finance',
        'Support',
      ]),
      width: 150,
      
    ),
    _ColumnSpec(
      name: 'ROLE',
      title: 'Role',
      type: GridSheetColumnType.text(),
      width: 170,
    ),
    _ColumnSpec(
      name: 'STATUS',
      title: 'Status',
      type: GridSheetColumnType.dropdown(options: ['Active', 'On Leave', 'Remote', 'Terminated']),
      width: 120,
      
    ),
    _ColumnSpec(
      name: 'REMOTE',
      title: 'Remote',
      type: GridSheetColumnType.boolean(),
      width: 90,
      align: TextAlign.center,
    ),
    _ColumnSpec(
      name: 'JOINED',
      title: 'Joined',
      type: GridSheetColumnType.datetime(),
      width: 200,
      editable: false,
    ),
    _ColumnSpec(
      name: 'SALARY',
      title: 'Salary',
      type: GridSheetColumnType.double(),
      width: 120,
      align: TextAlign.right,
    ),
  ],
  sampleRows: _employeeRows,
  formatRules: _employeeFormatRules,
);

List<GridSheetConditionalFormatRule> _employeeFormatRules(bool isDark) => [
      GridSheetConditionalFormatRule(
        name: 'STATUS',
        scope: GridSheetFormatScope.cell,
        expression: isDark
            ? 'STATUS == "Active" ? "#14532D" : '
                '(STATUS == "Remote" ? "#1E3A8A" : '
                '(STATUS == "On Leave" ? "#78350F" : '
                '(STATUS == "Terminated" ? "#7F1D1D" : null)))'
            : 'STATUS == "Active" ? "#DCFCE7" : '
                '(STATUS == "Remote" ? "#DBEAFE" : '
                '(STATUS == "On Leave" ? "#FEF3C7" : '
                '(STATUS == "Terminated" ? "#FEE2E2" : null)))',
        textStyle: _badgeTextStyle(isDark),
      ),
    ];

List<List<dynamic>> _employeeRows() => [
      [
        'EMP-1001',
        'Ava Thompson',
        'Engineering',
        'Senior Engineer',
        'Active',
        true,
        DateTime(2021, 3, 14),
        118000.0,
      ],
      [
        'EMP-1002',
        'Liam Chen',
        'Design',
        'Product Designer',
        'Active',
        false,
        DateTime(2022, 7, 1),
        92000.0,
      ],
      [
        'EMP-1003',
        'Noah Patel',
        'Marketing',
        'Marketing Lead',
        'Remote',
        true,
        DateTime(2020, 11, 23),
        87000.0,
      ],
      [
        'EMP-1004',
        'Emma Rodriguez',
        'Sales',
        'Account Executive',
        'Active',
        false,
        DateTime(2023, 1, 9),
        76000.0,
      ],
      [
        'EMP-1005',
        'Oliver Kim',
        'Finance',
        'Financial Analyst',
        'On Leave',
        false,
        DateTime(2019, 6, 17),
        81000.0,
      ],
    ];

// ---- Sales orders -----------------------------------------------------------

const _salesDataset = _TableDataset(
  columns: [
    _ColumnSpec(
      name: 'ORDERID',
      title: 'Order ID',
      type: GridSheetColumnType.text(),
      width: 100,
      pinnedLeft: true,
      editable: false,
    ),
    _ColumnSpec(
      name: 'CUSTOMER',
      title: 'Customer',
      type: GridSheetColumnType.text(),
      width: 170,
    ),
    _ColumnSpec(
      name: 'PRODUCT',
      title: 'Product',
      type: GridSheetColumnType.text(),
      width: 170,
    ),
    _ColumnSpec(
      name: 'QTY',
      title: 'Qty',
      type: GridSheetColumnType.integer(),
      width: 70,
      align: TextAlign.right,
    ),
    _ColumnSpec(
      name: 'UNITPRICE',
      title: 'Unit Price',
      description: 'Price per unit before tax, in USD.',
      type: GridSheetColumnType.double(),
      width: 110,
      align: TextAlign.right,
    ),
    _ColumnSpec(
      name: 'TOTAL',
      title: 'Total',
      description: 'Automatically calculated as Qty × Unit Price.',
      type: GridSheetColumnType.formula(),
      width: 110,
      align: TextAlign.right,
      editable: false,
    ),
    _ColumnSpec(
      name: 'STATUS',
      title: 'Status',
      type: GridSheetColumnType.dropdown(options: [
        'Pending',
        'Processing',
        'Shipped',
        'Delivered',
        'Cancelled',
      ]),
      width: 130,
      
    ),
    _ColumnSpec(
      name: 'PRIORITY',
      title: 'Priority',
      type: GridSheetColumnType.dropdown(options: ['Low', 'Medium', 'High']),
      width: 100,
      
    ),
  ],
  sampleRows: _salesRows,
  formatRules: _salesFormatRules,
);

List<GridSheetConditionalFormatRule> _salesFormatRules(bool isDark) => [
      GridSheetConditionalFormatRule(
        name: 'STATUS',
        scope: GridSheetFormatScope.cell,
        expression: isDark
            ? 'STATUS == "Delivered" ? "#14532D" : '
                '(STATUS == "Shipped" ? "#1E3A8A" : '
                '(STATUS == "Processing" ? "#78350F" : '
                '(STATUS == "Cancelled" ? "#7F1D1D" : "#374151")))'
            : 'STATUS == "Delivered" ? "#DCFCE7" : '
                '(STATUS == "Shipped" ? "#DBEAFE" : '
                '(STATUS == "Processing" ? "#FEF3C7" : '
                '(STATUS == "Cancelled" ? "#FEE2E2" : "#F3F4F6")))',
        textStyle: _badgeTextStyle(isDark),
      ),
      GridSheetConditionalFormatRule(
        name: 'PRIORITY',
        scope: GridSheetFormatScope.cell,
        expression: isDark
            ? 'PRIORITY == "High" ? "#7F1D1D" : '
                '(PRIORITY == "Medium" ? "#78350F" : "#14532D")'
            : 'PRIORITY == "High" ? "#FEE2E2" : '
                '(PRIORITY == "Medium" ? "#FEF3C7" : "#DCFCE7")',
        textStyle: _badgeTextStyle(isDark),
      ),
    ];

List<List<dynamic>> _salesRows() => [
      [
        'SO-3001',
        'Meridian Corp',
        'Wireless Mouse',
        25,
        14.50,
        '=QTY1 * UNITPRICE1',
        'Delivered',
        'Low',
      ],
      [
        'SO-3002',
        'Bluewave Retail',
        'Mechanical Keyboard',
        12,
        68.00,
        '=QTY2 * UNITPRICE2',
        'Shipped',
        'Medium',
      ],
      [
        'SO-3003',
        'Norton & Fields',
        '27" Monitor',
        8,
        189.99,
        '=QTY3 * UNITPRICE3',
        'Processing',
        'High',
      ],
      [
        'SO-3004',
        'Alpine Traders',
        'USB-C Hub',
        40,
        22.75,
        '=QTY4 * UNITPRICE4',
        'Pending',
        'Low',
      ],
      [
        'SO-3005',
        'Beacon Supplies',
        'Webcam HD',
        15,
        45.00,
        '=QTY5 * UNITPRICE5',
        'Delivered',
        'Medium',
      ],
    ];

// ---- Inventory --------------------------------------------------------------

const _inventoryDataset = _TableDataset(
  columns: [
    _ColumnSpec(
      name: 'SKU',
      title: 'SKU',
      type: GridSheetColumnType.text(),
      width: 100,
      pinnedLeft: true,
      editable: false,
    ),
    _ColumnSpec(
      name: 'PRODUCT',
      title: 'Product',
      type: GridSheetColumnType.text(),
      width: 190,
    ),
    _ColumnSpec(
      name: 'CATEGORY',
      title: 'Category',
      type: GridSheetColumnType.dropdown(options: [
        'Electronics',
        'Home & Kitchen',
        'Sporting Goods',
        'Office Supplies',
      ]),
      width: 150,
      
    ),
    _ColumnSpec(
      name: 'WAREHOUSE',
      title: 'Warehouse',
      type: GridSheetColumnType.dropdown(options: ['North DC', 'South DC', 'East DC', 'West DC']),
      width: 120,
      
    ),
    _ColumnSpec(
      name: 'INSTOCK',
      title: 'In Stock',
      type: GridSheetColumnType.boolean(),
      width: 90,
      align: TextAlign.center,
    ),
    _ColumnSpec(
      name: 'QTYONHAND',
      title: 'Qty On Hand',
      description: 'Current quantity available at the selected warehouse.',
      type: GridSheetColumnType.integer(),
      width: 120,
      align: TextAlign.right,
    ),
    _ColumnSpec(
      name: 'REORDERLEVEL',
      title: 'Reorder Lvl',
      description: 'Minimum stock threshold before a reorder is triggered.',
      type: GridSheetColumnType.integer(),
      width: 120,
      align: TextAlign.right,
    ),
    _ColumnSpec(
      name: 'UNITCOST',
      title: 'Unit Cost',
      type: GridSheetColumnType.double(),
      width: 110,
      align: TextAlign.right,
    ),
  ],
  sampleRows: _inventoryRows,
  formatRules: _inventoryFormatRules,
);

List<GridSheetConditionalFormatRule> _inventoryFormatRules(bool isDark) => [
      GridSheetConditionalFormatRule(
        name: 'INSTOCK',
        scope: GridSheetFormatScope.cell,
        expression: isDark
            ? 'INSTOCK == true ? "#14532D" : "#7F1D1D"'
            : 'INSTOCK == true ? "#DCFCE7" : "#FEE2E2"',
        textStyle: _badgeTextStyle(isDark),
      ),
      GridSheetConditionalFormatRule(
        name: 'QTYONHAND',
        scope: GridSheetFormatScope.row,
        expression: isDark
            ? 'QTYONHAND <= REORDERLEVEL ? "#78350F" : null'
            : 'QTYONHAND <= REORDERLEVEL ? "#FEF3C7" : null',
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
        ),
      ),
    ];

List<List<dynamic>> _inventoryRows() => [
      [
        'SKU-4501',
        'Wireless Mouse',
        'Electronics',
        'North DC',
        true,
        320,
        60,
        7.25,
      ],
      [
        'SKU-4502',
        'Mechanical Keyboard',
        'Electronics',
        'North DC',
        true,
        145,
        40,
        31.10,
      ],
      [
        'SKU-4503',
        '27" Monitor',
        'Electronics',
        'East DC',
        false,
        0,
        25,
        112.00,
      ],
      [
        'SKU-4504',
        'Office Chair',
        'Home & Kitchen',
        'South DC',
        true,
        58,
        20,
        89.50,
      ],
      [
        'SKU-4505',
        'Standing Desk',
        'Home & Kitchen',
        'South DC',
        true,
        22,
        10,
        198.00,
      ],
    ];
