import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheetFormConfiguration] — the card-based form layout,
/// shown with `viewMode: form` at any width, or with `viewMode: responsive`
/// below its breakpoint (it's opt-in; the default `auto` shows the table).
/// Most toggles here map to one GridSheetFormConfiguration
/// field; a couple (Row Reorder, Custom Cells) map to a sibling GridSheet
/// param instead, to show those keep working identically in form mode too.
class FormLayoutDemo extends StatefulWidget {
  const FormLayoutDemo({super.key});

  @override
  State<FormLayoutDemo> createState() => _FormLayoutDemoState();
}

class _FormLayoutDemoState extends State<FormLayoutDemo> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'viewMode: form — tap "Mode" for responsive (cards below the 600px '
    'breakpoint, the table above) or table; "Narrow View" shrinks the panel.',
  );

  GridSheetViewMode _mode = GridSheetViewMode.form;
  bool _narrowPreview = false;
  bool _cappedHeight = false;
  bool _gridView = false;
  bool _richCards = false;
  bool _rowReorder = false;
  bool _customDragPreview = false;
  bool _customCard = false;
  bool _customCardWrapper = false;
  bool _customCells = false;
  bool _rowSelectionOnTap = false;
  bool _multiSelect = false;
  bool _cardReveal = false;
  // Direction of the last "Sort by Name"; false until the first sort.
  bool _nameAscending = false;
  bool _onLeaveRule = false;
  bool _statusColorsRule = false;
  bool _salaryRule = false;
  bool _engineeringTextRule = false;
  // GridSheet.direction updates live via didUpdateWidget (see
  // rtl_support.dart).
  GridSheetDirection _direction = GridSheetDirection.leftToRight;

  // GridSheetManager.search — same global, cross-column search as
  // search.dart (see that file for the ||/&&/.. syntax). Not form-specific:
  // it filters gridRows before either view mode ever reads them, so it
  // narrows cards exactly the same way it narrows table rows.
  final TextEditingController _searchInputController = TextEditingController();
  final List<dynamic> _searchItems = [];

  static const double _cardHeightCap = 256;
  static const double _cardRichCardsHeightCap = 290; //290

  // Keeps the same grid (and its state) when "Narrow View" wraps it in a
  // different parent.
  final GlobalKey<GridSheetState> _gridKey = GlobalKey<GridSheetState>();

  @override
  void dispose() {
    status.dispose();
    _searchInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < Constants.mobileBreakpoint;

    final grid = GridSheet(
      key: _gridKey,
      columns: _columns(),
      rows: _rows(),
      indexColumn: null,
      direction: _direction,
      viewMode: _mode,
      formConfiguration: GridSheetFormConfiguration(
        maxHeight: _cappedHeight
            ? _richCards
                ? _cardRichCardsHeightCap
                : _cardHeightCap
            : null,
        enableGridView: _gridView,
        topBarBuilder: _richCards ? _buildTopBar : null,
        bottomBarBuilder: _richCards ? _buildBottomBar : null,
        labelBuilder: _richCards ? _buildLabel : null,
        formBuilder: _customCard ? _buildCustomCard : null,
        cardWrapper: _customCardWrapper ? _buildCustomCardWrapper : null,
        cardDragPreviewBuilder:
            _customDragPreview ? _buildCardDragPreview : null,
      ),
      configuration: GridSheetConfiguration(
        enableRowReorder: _rowReorder,
        enableRowSelectionOnFirstColumnTap: _rowSelectionOnTap,
        enableMultiSelection: _multiSelect,
        enableRowHover: _customCardWrapper,
      ),
      animationConfiguration: GridSheetAnimationConfiguration(
        animateRowsOnSortOrFilter: _cardReveal,
      ),
      styleConfiguration: styleConfig(context, colorEvenOdd: false).copyWith(
        rowColor: colors.canvas,
        gridBorderColor: Colors.transparent,
      ),
      scrollConfiguration: scrollConfig(context),
      cellBuilder: _customCells ? _buildCustomCell : null,
      conditionalFormatRules: _conditionalFormatRules(),
      onLoaded: (event) => gridManager = event.gridManager,
      onRowsSelected: (event) {
        status.value = 'Selected: ${event.keys.length} row(s)';
      },
    );

    return FeaturePageTemplate(
      title: 'Form Layout',
      icon: Icons.view_agenda_outlined,
      status: status,
      gridPadding: _mode == GridSheetViewMode.form ||
              (isMobile && _mode == GridSheetViewMode.responsive)
          ? 0
          : ThemeSpacing.sm,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DemoToolbar(
            sections: [
              DemoActionButton(
                label: 'Mode: ${_modeLabel(_mode)}',
                icon: _modeIcon(_mode),
                color: context.accents.blue,
                onPressed: _cycleMode,
                tooltip: 'Cycle GridSheet.viewMode: form → responsive → table',
              ),
              DemoToggleButton(
                label: 'Capped Height',
                icon: Icons.height,
                color: context.accents.teal,
                value: _cappedHeight,
                onChanged: (value) => setState(() {
                  _cappedHeight = value;
                  status.value = value
                      ? 'maxHeight: ${_richCards ? _cardRichCardsHeightCap : _cardHeightCap} — a card taller than this scrolls internally instead of growing.'
                      : 'maxHeight: null — cards grow to fit all their fields.';
                }),
                tooltip: 'Toggle GridSheetFormConfiguration.maxHeight',
              ),
              DemoToggleButton(
                label: 'Narrow View',
                icon: Icons.smartphone_outlined,
                color: context.accents.blue,
                value: _narrowPreview,
                onChanged: (value) => setState(() {
                  _narrowPreview = value;
                  status.value = value
                      ? 'Grid panel forced to 380px wide — below the 600px responsive breakpoint.'
                      : 'Grid panel back to its normal width.';
                }),
                tooltip:
                    'Force a narrow panel width to preview viewMode: responsive',
              ),
              DemoToggleButton(
                label: 'Grid View',
                icon: Icons.grid_view_outlined,
                color: context.accents.teal,
                value: _gridView,
                onChanged: (value) => setState(() {
                  _gridView = value;
                  status.value = value
                      ? 'enableGridView: ON — up to 4 columns, based on the panel\'s width. Each card sizes '
                          'to its own content (a masonry layout, not a shared row height).'
                      : 'enableGridView: OFF';
                }),
                tooltip: 'Responsive 1-4 column card masonry',
              ),
              DemoToggleButton(
                label: 'Rich Cards',
                icon: Icons.style_outlined,
                color: context.accents.purple,
                value: _richCards,
                onChanged: (value) => setState(() {
                  _richCards = value;
                  status.value = value
                      ? 'topBarBuilder/bottomBarBuilder/labelBuilder now customize each card.'
                      : 'Back to the default label/value text and no top or bottom bar.';
                }),
                tooltip:
                    'Toggle topBarBuilder + bottomBarBuilder + labelBuilder',
              ),
              DemoToggleButton(
                label: 'Custom Card',
                icon: Icons.dashboard_customize_outlined,
                color: context.accents.purple,
                value: _customCard,
                onChanged: (value) => setState(() {
                  _customCard = value;
                  status.value = value
                      ? 'formBuilder now renders every card\'s content — the built-in Card '
                          'chrome and any top/bottom bar still wrap it, but there\'s no default '
                          'label/value field for labelBuilder to style.'
                      : 'Back to the built-in card layout.';
                }),
                tooltip:
                    'Custom content via formBuilder — the built-in Card chrome, top bar, and '
                    'bottom bar still wrap it',
              ),
              DemoToggleButton(
                label: 'Custom Wrapper',
                icon: Icons.crop_free_outlined,
                color: context.accents.purple,
                value: _customCardWrapper,
                onChanged: (value) => setState(() {
                  _customCardWrapper = value;
                  status.value = value
                      ? 'cardWrapper now replaces the built-in Card — a flat left-accent panel '
                          'instead of Material shape/elevation, wrapping the same content.'
                      : 'Back to the built-in Card.';
                }),
                tooltip:
                    'cardWrapper — replace the built-in Card with your own wrapper widget',
              ),
              DemoToggleButton(
                label: 'Row Selection',
                icon: Icons.touch_app_outlined,
                color: context.accents.blue,
                value: _rowSelectionOnTap,
                onChanged: (value) => setState(() {
                  _rowSelectionOnTap = value;
                  status.value = value
                      ? 'enableRowSelectionOnFirstColumnTap: ON — tap a card to select its row.'
                      : 'enableRowSelectionOnFirstColumnTap: OFF — a card has no index cell of its '
                          'own, so tapping it no longer selects anything.';
                }),
                tooltip:
                    'A form card has no index cell — tapping it to select requires this, same as '
                    'a table data cell without one',
              ),
              DemoToggleButton(
                label: 'Multi-Select',
                icon: Icons.checklist_outlined,
                color: context.accents.blue,
                value: _multiSelect,
                onChanged: (value) => setState(() {
                  _multiSelect = value;
                  status.value = value
                      ? 'enableMultiSelection: ON — tap several cards to select them all at once.'
                      : 'enableMultiSelection: OFF — selecting a card deselects any other.';
                }),
                tooltip:
                    'Select more than one card at a time (needs Row Selection ON too)',
              ),
              DemoToggleButton(
                label: 'Row Reorder',
                icon: Icons.drag_indicator_outlined,
                color: context.accents.green,
                value: _rowReorder,
                onChanged: (value) => setState(() {
                  _rowReorder = value;
                  status.value = value
                      ? 'Long-press anywhere on a card and drag to reorder '
                          'it: a dotted, card-sized gap opens where it will land. '
                          'Drop on the lower half of the last card to move '
                          'it to the end.'
                      : 'enableRowReorder: OFF';
                }),
                tooltip: 'Long-press-drag a card to reorder rows',
              ),
              DemoToggleButton(
                label: 'Custom Drag Preview',
                icon: Icons.open_with,
                color: context.accents.green,
                value: _customDragPreview,
                onChanged: (value) => setState(() {
                  _customDragPreview = value;
                  if (value) _rowReorder = true;
                  status.value = value
                      ? 'cardDragPreviewBuilder: the dragged card\'s preview is '
                          'the built-in copy, tilted, with an accent outline. '
                          'Long-press a card and drag it to see it.'
                      : 'cardDragPreviewBuilder: null — the built-in card copy.';
                }),
                tooltip:
                    'Wrap the preview shown while dragging a card (cardDragPreviewBuilder); turns Row Reorder on',
              ),
              DemoToggleButton(
                label: 'Custom Cells',
                icon: Icons.widgets_outlined,
                color: context.accents.indigo,
                value: _customCells,
                onChanged: (value) => setState(() {
                  _customCells = value;
                  status.value = value
                      ? 'GridSheet.cellBuilder now renders Status as a chip and Email with an icon — the '
                          'same custom cells the table would show, since form fields reuse the table\'s own '
                          'cell-rendering pipeline. Try Mode: Table to compare.'
                      : 'cellBuilder: null — Status/Email back to plain editable text.';
                }),
                tooltip:
                    'A cellBuilder\'s custom cells render identically in form and table mode',
              ),
              DemoToggleButton(
                label: 'Card Reveal',
                icon: Icons.auto_awesome_outlined,
                color: context.accents.deepPurple,
                value: _cardReveal,
                onChanged: (value) => setState(() {
                  _cardReveal = value;
                  status.value = value
                      ? 'animateRowsOnSortOrFilter: ON — use "Sort by Name" or search to see cards cascade back in.'
                      : 'animateRowsOnSortOrFilter: OFF — sorting reorders cards instantly.';
                }),
                tooltip:
                    'GridSheetAnimationConfiguration.animateRowsOnSortOrFilter — cards reveal top-to-bottom after a sort or search.',
              ),
              DemoActionButton(
                label:
                    _nameAscending ? 'Sort by Name: Z→A' : 'Sort by Name: A→Z',
                icon: Icons.sort_by_alpha,
                color: context.accents.deepPurple,
                onPressed: _sortByName,
                tooltip:
                    'gridManager.sorting.sortBy(NAME), alternating A→Z and Z→A',
              ),
              DemoToggleButton(
                label: 'RTL',
                icon: Icons.format_textdirection_r_to_l,
                color: context.accents.indigo,
                value: _direction == GridSheetDirection.rightToLeft,
                onChanged: _toggleDirection,
                tooltip:
                    'GridSheet.direction — mirrors card layout, field order, and the scrollbar '
                    'gutter for right-to-left locales, same as the table',
              ),
              DemoToggleButton(
                label: 'On Leave card',
                icon: Icons.beach_access_outlined,
                color: context.accents.amber,
                value: _onLeaveRule,
                onChanged: (value) => _setRule(
                    () => _onLeaveRule = value,
                    'Row rule: STATUS == "On Leave" tints the whole card',
                    value),
                tooltip:
                    'Conditional format, row scope — a row rule colors the '
                    'whole card, like a table row',
              ),
              DemoToggleButton(
                label: 'Status colors',
                icon: Icons.palette_outlined,
                color: context.accents.green,
                value: _statusColorsRule,
                onChanged: (value) => _setRule(
                    () => _statusColorsRule = value,
                    'Cell rule: one expression, a color per STATUS value',
                    value),
                tooltip: 'Conditional format, cell scope — colors just the '
                    'Status field: green/blue/amber by value',
              ),
              DemoToggleButton(
                label: 'Salary > 120k',
                icon: Icons.attach_money,
                color: context.accents.teal,
                value: _salaryRule,
                onChanged: (value) => _setRule(
                    () => _salaryRule = value,
                    'Cell rule: SALARY > 120000 gets a background and bold '
                    'text',
                    value),
                tooltip: 'Conditional format with a background and a '
                    'textStyle on the Salary field',
              ),
              DemoToggleButton(
                label: 'Engineering text',
                icon: Icons.format_bold,
                color: context.accents.indigo,
                value: _engineeringTextRule,
                onChanged: (value) => _setRule(
                    () => _engineeringTextRule = value,
                    'Text-only rule: DEPARTMENT == "Engineering" returns '
                    'true, so only the text style applies',
                    value),
                tooltip: 'Conditional format returning true: bold text, no '
                    'background',
              ),
            ],
          ),
          const SizedBox(height: ThemeSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: ThemeSpacing.sm),
            child: _buildSearchInput(context),
          ),
        ],
      ),
      grid: _narrowPreview
          ? Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 380, child: grid),
            )
          : grid,
    );
  }

  String _modeLabel(GridSheetViewMode mode) => switch (mode) {
        GridSheetViewMode.form => 'Form',
        GridSheetViewMode.responsive => 'Responsive',
        GridSheetViewMode.table => 'Table',
        GridSheetViewMode.auto => 'Auto',
        GridSheetViewMode.pivot => 'Pivot',
      };

  IconData _modeIcon(GridSheetViewMode mode) => switch (mode) {
        GridSheetViewMode.responsive => Icons.devices_outlined,
        GridSheetViewMode.table => Icons.table_rows_outlined,
        GridSheetViewMode.form => Icons.view_agenda_outlined,
        GridSheetViewMode.auto => Icons.auto_awesome_outlined,
        GridSheetViewMode.pivot => Icons.pivot_table_chart_outlined,
      };

  void _toggleDirection(bool value) {
    setState(() {
      _direction = value
          ? GridSheetDirection.rightToLeft
          : GridSheetDirection.leftToRight;
    });
    status.value = value
        ? 'direction: GridSheetDirection.rightToLeft — cards, field order, and the scrollbar '
            'gutter all mirror; column/row identity stays keyed to logical position.'
        : 'direction: GridSheetDirection.leftToRight';
  }

  Future<void> _sortByName() async {
    final ascending = !_nameAscending;
    final nameKey = gridManager.columns.findByNames(['NAME']).single.key;
    await gridManager.sorting.sortBy(
      nameKey,
      direction:
          ascending ? GridSheetSortDirection.asc : GridSheetSortDirection.desc,
    );
    if (!mounted) return;
    setState(() => _nameAscending = ascending);
    status.value = 'sorting.sortBy(NAME, ${ascending ? 'asc' : 'desc'})'
        '${_cardReveal ? ' — cards reveal top to bottom' : ''}';
  }

  void _cycleMode() {
    setState(() {
      _mode = switch (_mode) {
        GridSheetViewMode.form => GridSheetViewMode.responsive,
        GridSheetViewMode.responsive => GridSheetViewMode.table,
        GridSheetViewMode.table ||
        GridSheetViewMode.auto ||
        GridSheetViewMode.pivot =>
          GridSheetViewMode.form,
      };
    });
    status.value = 'viewMode: GridSheetViewMode.${_mode.name}';
  }

  // ---- GridSheetManager.search (Overall Search) — same cascading,
  // ||/&&/.. syntax as search.dart; see that file's doc comment for the
  // full explanation. Narrows cards the same way it narrows table rows,
  // since search filters gridRows before either view mode reads them.

  Widget _buildSearchInput(BuildContext context) {
    final colors = context.colors;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 36,
          child: TextField(
            key: const Key('search_input'),
            controller: _searchInputController,
            style:
                TextTypography.bodyMedium.copyWith(color: colors.textPrimary),
            cursorColor: colors.primary,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Type… (|| = OR, && = AND)',
              hintStyle:
                  TextTypography.bodyMedium.copyWith(color: colors.textMuted),
              prefixIcon: const Icon(Icons.search, size: 16),
              isDense: true,
              filled: true,
              fillColor: colors.surfaceSubtle,
              border: OutlineInputBorder(
                borderRadius: ThemeBorders.roundedSm,
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: ThemeBorders.roundedSm,
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: ThemeBorders.roundedSm,
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
            onSubmitted: (value) {
              _addSearchTerm(value);
              _searchInputController.clear();
            },
          ),
        ),
        if (_searchItems.isEmpty)
          Text(
            'No search items yet.',
            style: TextTypography.caption.copyWith(color: colors.textMuted),
          )
        else
          for (final item in _searchItems)
            Chip(
              label: Text(
                _displaySearchTerm(item),
                style: TextTypography.bodyMedium
                    .copyWith(color: colors.textPrimary),
              ),
              labelPadding: const EdgeInsets.only(right: 8),
              deleteIconColor: colors.danger,
              onDeleted: () => _removeSearchTerm(item),
              visualDensity: VisualDensity.compact,
            ),
      ],
    );
  }

  Future<void> _addSearchTerm(dynamic value) async {
    final isBlank = value is String && value.trim().isEmpty;
    if (isBlank) return;

    setState(() => _searchItems.add(value is String ? value.trim() : value));
    await gridManager.search.apply(_searchItems, exactMatch: false);
    _reportSearchStatus('search.apply($_searchItems)');
  }

  Future<void> _removeSearchTerm(dynamic term) async {
    setState(() => _searchItems.remove(term));
    if (_searchItems.isEmpty) {
      await gridManager.search.clear();
      status.value = 'search.clear(): all rows visible again';
      return;
    }
    await gridManager.search.apply(_searchItems, exactMatch: false);
    _reportSearchStatus('search.apply($_searchItems)');
  }

  String _displaySearchTerm(dynamic item) {
    if (item is! String) return '$item';
    return item
        .replaceAll(GridSheetConstants.delimiterOR, ' OR ')
        .replaceAll(GridSheetConstants.delimiterAND, ' AND ')
        .replaceAll(GridSheetConstants.delimiterBetween, ' to ');
  }

  void _reportSearchStatus(String call) {
    status.value =
        '$call — ${gridManager.rows.filteredCount} of ${gridManager.rows.count} rows match';
  }

  // ---- topBarBuilder/bottomBarBuilder/labelBuilder (Rich Cards) ----

  Widget _buildTopBar(
      BuildContext context, GridSheetRow row, GridSheetManager manager) {
    final empId = row.data[0]?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  empId,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 12,
                  children: [
                    InkWell(
                      onTap: () => debugPrint('view => ${row.data}'),
                      child:
                          const Icon(Icons.remove_red_eye_outlined, size: 18),
                    ),
                    InkWell(
                      onTap: () => debugPrint('edit => ${row.data}'),
                      child: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    Builder(
                      builder: (menuContext) => InkWell(
                        onTap: () => _showRowMenu(menuContext, row, manager),
                        child: const Icon(Icons.more_vert, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(thickness: 1, height: 1),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'Active' => Colors.green,
        'On Leave' => Colors.orange,
        'Remote' => Colors.blue,
        _ => Colors.grey,
      };

  Widget _buildBottomBar(
      BuildContext context, GridSheetRow row, GridSheetManager manager) {
    final colors = context.colors;
    final statusText = row.data[4]?.toString() ?? '';
    final statusColor = _statusColor(statusText);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          Divider(thickness: 1, height: 1),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                border: Border.all(color: colors.border, width: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                spacing: 4,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(GridSheetColumn column) {
    final icon = switch (column.name) {
      'NAME' => Icons.person_outline,
      'ROLE' => Icons.badge_outlined,
      'DEPARTMENT' => Icons.apartment_outlined,
      'STATUS' => Icons.circle_outlined,
      'EMAIL' => Icons.email_outlined,
      'LOCATION' => Icons.location_on_outlined,
      'START_DATE' => Icons.calendar_today_outlined,
      'SALARY' => Icons.payments_outlined,
      _ => Icons.label_outline,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(column.title, style: TextTypography.bodyStrong),
      ],
    );
  }

  // ---- cellBuilder (Custom Cells) — see custom_cells.dart/main.dart for
  // the full IGridSheetCustomCellBuilder pattern; this demo just
  // dispatches inline since it only overrides two columns. Not a form-
  // specific hook: form fields go through _buildExpansionCell, the same
  // GridSheetCellKind.row path table data cells use, so returning a custom
  // widget here replaces a field's value the same way in both modes.
  // Returning null (the default/other columns) falls back to the normal
  // editable cell.

  Widget? _buildCustomCell(GridSheetCellContext cell) {
    if (cell.kind != GridSheetCellKind.row) return null;

    final row = cell.row!;
    final rawValue = row.data[cell.column.index]?.toString() ?? '';

    return switch (cell.column.name) {
      'STATUS' => _buildStatusChipCell(rawValue),
      'EMAIL' => _buildEmailCell(cell.context, rawValue),
      _ => null,
    };
  }

  Widget _buildStatusChipCell(String statusText) {
    final color = _statusColor(statusText);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailCell(BuildContext context, String email) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.email_outlined, size: 14, color: context.accents.indigo),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            email,
            overflow: TextOverflow.ellipsis,
            style: TextTypography.body,
          ),
        ),
      ],
    );
  }

  // ---- formBuilder (Custom Card) ----

  Widget _buildCustomCard(
    BuildContext context,
    GridSheetRow row,
    List<GridSheetColumn> columns,
    GridSheetManager manager,
  ) {
    // Get values from the row.
    final name = row.data[1]?.toString().trim() ?? '';
    final role = row.data[2]?.toString().trim() ?? '';
    final department = row.data[3]?.toString().trim() ?? '';
    final statusText = row.data[4]?.toString().trim() ?? '';
    final email = row.data[5]?.toString().trim() ?? '';

    final statusColor = _statusColor(statusText);

    // Generate initials from the name.
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();

    return ExpansionTile(
      // Header
      tilePadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),

      leading: CircleAvatar(
        radius: 22,
        backgroundColor: statusColor.withValues(
          alpha: 0.15,
        ),
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      title: Text(
        name.isEmpty ? 'Unknown' : name,
        style: TextTypography.bodyStrong,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: TextTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              statusText,
              statusColor,
            ),
          ],
        ),
      ),

      trailing: const Icon(
        Icons.keyboard_arrow_down,
      ),

      // Expanded content
      children: [
        const Divider(
          height: 1,
          thickness: 0.8,
        ),

        const SizedBox(height: 12),

        // Name
        _buildDetailRow(
          icon: Icons.person_outline,
          label: 'Name',
          value: name,
        ),

        const SizedBox(height: 12),

        // Role
        _buildDetailRow(
          icon: Icons.work_outline,
          label: 'Role',
          value: role,
        ),

        const SizedBox(height: 12),

        // Department
        _buildDetailRow(
          icon: Icons.business_outlined,
          label: 'Department',
          value: department,
        ),

        const SizedBox(height: 12),

        // Status
        _buildDetailRow(
          icon: Icons.circle_outlined,
          label: 'Status',
          value: statusText,
          valueColor: statusColor,
        ),

        const SizedBox(height: 12),

        // Email
        _buildDetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: email,
        ),

        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildStatusChip(
    String statusText,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.isEmpty ? 'Unknown' : statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(width: 8),

        // Label + value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextTypography.caption,
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '—' : value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- cardWrapper (Custom Wrapper) — replaces the built-in Card with a
  // flat, no-elevation panel of our own, wrapping whatever content
  // (default fields or formBuilder's) was already built as `body`.

  // Keeps the built-in card copy (details.defaultPreview) and wraps it:
  // tilted slightly, with an accent outline, so it reads as "picked up".
  Widget _buildCardDragPreview(
      BuildContext context, GridSheetRowDragPreviewDetails details) {
    return Transform.rotate(
      angle: -0.03,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: context.accents.green, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: details.defaultPreview,
      ),
    );
  }

  Widget _buildCustomCardWrapper(
    BuildContext context,
    Widget child,
    GridSheetFormCardWrapperDetails details,
  ) {
    final accent = context.accents.purple;
    final isHovered = details.hovered;
    final isSelected = details.selected;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withValues(alpha: 0.08)
            : isHovered
                ? Colors.grey.withValues(alpha: 0.06)
                : context.colors.canvas,
        border: Border(
          left: BorderSide(
            color: isSelected ? accent : Colors.grey.shade300,
            width: 3,
          ),
        ),
      ),
      child: child,
    );
  }

  // ---- Row menu — built entirely in host code, no package hook needed:
  // topBarBuilder already receives the row and the manager, so this is a plain
  // showMenu()/PopupMenuItem call built from it (the previous "⋮" button
  // on each card was a package-provided GridSheet.contextMenuBuilder hook;
  // it's gone now, since the same result is this easy to build directly).

  Future<void> _showRowMenu(BuildContext iconContext, GridSheetRow row,
      GridSheetManager manager) async {
    final box = iconContext.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(iconContext).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final empId = row.data[0]?.toString() ?? '';

    final selected = await showMenu<String>(
      context: iconContext,
      position: position,
      items: [
        PopupMenuItem(
          value: 'active',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 18, color: context.accents.green),
              const SizedBox(width: 8),
              const Text('Mark as Active', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: context.accents.red),
              const SizedBox(width: 8),
              Text('Remove $empId', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );

    switch (selected) {
      case 'active':
        manager.cells.update(
          rowKey: row.key,
          columnKey: _columns()[4].key,
          value: 'Active',
        );
        status.value = 'Row menu → Marked ${row.data[1]} as Active';
      case 'remove':
        await manager.rows.delete([row.key]);
        status.value = 'Row menu → Removed ${row.data[1]}';
    }
  }

  // ---- Data ----

  // Conditional formatting works in cards as in the table: row rules color
  // the whole card, cell rules color their field, and a rule returning
  // `true` applies only its text style.
  List<GridSheetConditionalFormatRule> _conditionalFormatRules() => [
        if (_onLeaveRule)
          const GridSheetConditionalFormatRule(
            name: 'OnLeave',
            expression: 'STATUS == "On Leave" ? "#FFF8E1" : null',
          ),
        if (_statusColorsRule)
          const GridSheetConditionalFormatRule(
            name: 'STATUS',
            scope: GridSheetFormatScope.cell,
            expression: 'STATUS == "Active" ? "#C8E6C9" : '
                'STATUS == "Remote" ? "#BBDEFB" : '
                'STATUS == "On Leave" ? "#FFE0B2" : null',
          ),
        if (_salaryRule)
          const GridSheetConditionalFormatRule(
            name: 'SALARY',
            scope: GridSheetFormatScope.cell,
            expression: 'SALARY > 120000 ? "#E8F5E9" : null',
            textStyle: TextStyle(
                color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
          ),
        if (_engineeringTextRule)
          const GridSheetConditionalFormatRule(
            name: 'DEPARTMENT',
            scope: GridSheetFormatScope.cell,
            expression: 'DEPARTMENT == "Engineering"',
            textStyle: TextStyle(
                color: Color(0xFF3949AB), fontWeight: FontWeight.bold),
          ),
      ];

  void _setRule(void Function() update, String description, bool on) {
    setState(update);
    status.value = on ? description : 'Rule removed';
  }

  List<GridSheetColumn> _columns() {
    const names = [
      'ID',
      'NAME',
      'ROLE',
      'DEPARTMENT',
      'STATUS',
      'EMAIL',
      'LOCATION',
      'START_DATE',
      'SALARY',
    ];
    const titles = [
      'ID',
      'Name',
      'Role',
      'Department',
      'Status',
      'Email',
      'Location',
      'Start Date',
      'Salary',
    ];
    // Appended after Email rather than interleaved, so the existing
    // row.data[1]/[4]/[5]-style index lookups elsewhere on this page
    // (_buildTopBar, _buildBottomBar, _buildCustomCard) stay correct without
    // touching them — column order here must always match _rows()' raw data.
    const types = [
      GridSheetColumnType.text(), // ID
      GridSheetColumnType.text(), // NAME
      GridSheetColumnType.text(), // ROLE
      GridSheetColumnType.text(), // DEPARTMENT
      GridSheetColumnType.text(), // STATUS
      GridSheetColumnType.text(), // EMAIL
      GridSheetColumnType.text(), // LOCATION
      GridSheetColumnType.datetime(), // START_DATE
      GridSheetColumnType.double(), // SALARY
    ];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: 160,
        visible: names[i] != 'ID',
        // Sortable so "Sort by Name" can trigger the Card Reveal cascade.
        sortable: names[i] == 'NAME',
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      [
        'E101',
        'Ava Thompson',
        'Product Designer',
        'Design',
        'Active',
        'ava@acme.dev',
        'San Francisco',
        '2022-03-14',
        96000.0,
      ],
      [
        'E102',
        'Liam Chen',
        'Backend Engineer',
        'Engineering',
        'Remote',
        'liam@acme.dev',
        'Austin',
        '2021-07-01',
        118000.0,
      ],
      [
        'E103',
        'Noah Patel',
        'Engineering Manager',
        'Engineering',
        'Active',
        'noah@acme.dev',
        'Seattle',
        '2019-11-20',
        145000.0,
      ],
      [
        'E104',
        'Maya Rodriguez',
        'Marketing Lead',
        'Marketing',
        'On Leave',
        'maya@acme.dev',
        'New York',
        '2020-05-05',
        102000.0,
      ],
      [
        'E105',
        'Ethan Kim',
        'Sales Rep',
        'Sales',
        'Active',
        'ethan@acme.dev',
        'Chicago',
        '2023-01-09',
        68000.0,
      ],
      [
        'E106',
        'Sofia Alvarez',
        'Frontend Engineer',
        'Engineering',
        'Remote',
        'sofia@acme.dev',
        'Denver',
        '2022-09-18',
        109000.0,
      ],
      [
        'E107',
        'Jack Wilson',
        'HR Specialist',
        'People',
        'Active',
        'jack@acme.dev',
        'Boston',
        '2021-02-28',
        74000.0,
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
}
