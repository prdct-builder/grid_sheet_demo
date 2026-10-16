import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates GridSheetManager.addFilters — per-column filtering, distinct
/// from the cross-column Overall Search demo (search.dart).
///
/// Four things are covered:
/// 1. The basics: contains/exact toolbar filters, clearing filters, moving
///    the filter row above the header, showing/hiding it, and customizing
///    the blanks/non-blanks keywords (all extracted from the former
///    "Sorting & Filtering" demo — sorting now has its own page, sorting.dart).
/// 2. Every [GridSheetFilterComparison] mode, tried live against any column
///    and value via the picker below the toolbar — not just contains/exact.
///    The picker defaults to [GridSheetFilterComparison.auto], so typing an
///    operator straight into the value field (e.g. `>100`, `=Apple`,
///    `app%`) works with no comparison chosen at all.
/// 3. Combining multiple values within a single filter using
///    [GridSheetConstants]'s `||` (OR), `&&` (AND), and `..` (between)
///    delimiters — the quick-add buttons build these directly.
class Filters extends StatefulWidget {
  const Filters({super.key});

  @override
  State<Filters> createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  late GridSheetManager gridManager;

  /// Resolves a column name to its key — the manager's column methods are
  /// key-addressed.
  ValueKey<String> _columnKey(String name) =>
      gridManager.columns.findByNames([name]).single.key;

  final ValueNotifier<String> status = ValueNotifier(
    'Use the toolbar for quick examples, or the picker below — it defaults '
    "to auto, so try typing e.g. '>100' with no comparison chosen.",
  );
  bool _filterAbove = false;
  String _blanksText = GridSheetConstants.blanksText;
  String _noBlanksText = GridSheetConstants.noBlanksText;
  bool _showColumnFilters = true;
  final double _comparisonHeight = 36.0;

  static const _columnNames = ['ATHLETE', 'SPORT', 'COUNTRY', 'MEDALS'];
  String _pickerColumn = _columnNames.first;
  GridSheetFilterComparison _pickerComparison = GridSheetFilterComparison.auto;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  bool get _pickerIsRange =>
      _pickerComparison == GridSheetFilterComparison.between ||
      _pickerComparison == GridSheetFilterComparison.notBetween;

  @override
  void dispose() {
    status.dispose();
    _valueController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Filters',
      description:
          'GridSheetManager.addFilters(values, comparison: ...) filters a single column by operator, '
          'auto-detecting one from the typed value or combining several with ||/&&/.. syntax.',
      icon: Icons.filter_alt_outlined,
      status: status,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DemoToolbar(
            sections: [
              DemoActionButton(
                label: _showColumnFilters ? 'Filters: On' : 'Filters: Off',
                icon: Icons.filter_alt_outlined,
                color: context.accents.teal,
                onPressed: () => setState(() {
                  _showColumnFilters = !_showColumnFilters;
                  _updateFiltersVisibility(
                      'showColumnFilters = $_showColumnFilters');
                }),
                tooltip: 'Show or hide the column filter row',
              ),
              DemoActionButton(
                label: 'Clear Filters',
                icon: Icons.filter_alt_off_outlined,
                color: context.accents.neutral,
                onPressed: _clearFilters,
                tooltip: 'Remove every active filter',
              ),
              DemoToggleButton(
                label: 'Filter Above Header',
                icon: Icons.vertical_align_top,
                color: context.accents.deepOrange,
                value: _filterAbove,
                onChanged: _toggleFilterPosition,
                tooltip: 'Move the filter row above the column headers',
              ),
              DemoActionButton(
                label: 'Country Contains',
                icon: Icons.search,
                color: context.accents.blue,
                onPressed: _filterCountryContains,
                tooltip: 'Filter COUNTRY by partial text match',
              ),
              DemoActionButton(
                label: 'Sport Exact',
                icon: Icons.check,
                color: context.accents.green,
                onPressed: _filterSportExact,
                tooltip: 'Filter SPORT by exact text match',
              ),
              DemoActionButton(
                label: "Sport: Swimming OR Athletics",
                icon: Icons.call_split,
                color: context.accents.indigo,
                onPressed: _filterSportOr,
                tooltip: "addFilters with '||' — one filter value combining "
                    "two alternatives (matches either)",
              ),
              DemoActionButton(
                label: "Athlete: Amara AND Diallo",
                icon: Icons.join_inner,
                color: context.accents.amber,
                onPressed: _filterAthleteAnd,
                tooltip: "addFilters with '&&' — one filter value requiring "
                    "both substrings, in the same cell",
              ),
              DemoActionButton(
                label: "Medals: 2..5",
                icon: Icons.linear_scale,
                color: context.accents.pink,
                onPressed: _filterMedalsBetween,
                tooltip: "addFilters with comparison: between and a "
                    "'low..high' value — MEDALS from 2 to 5 inclusive",
              ),
              DemoActionButton(
                label: 'Blanks: "$_blanksText"',
                icon: Icons.edit_note,
                color: context.accents.brown,
                onPressed: _customizeBlanksKeyword,
                tooltip: 'Change the keyword that filters for blank values',
              ),
              DemoActionButton(
                label: 'Non-Blanks: "$_noBlanksText"',
                icon: Icons.edit_note,
                color: context.accents.brown,
                onPressed: _customizeNonBlanksKeyword,
                tooltip: 'Change the keyword that filters for non-blank values',
              ),
            ],
          ),
          const SizedBox(height: ThemeSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: ThemeSpacing.sm),
            child: _buildComparisonPicker(context),
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: GridSheetConfiguration(
          showColumnFilters: true,
          enableCellSelection: true,
          filterPosition: _filterAbove
              ? GridSheetFilterPosition.above
              : GridSheetFilterPosition.below,
          blanksText: _blanksText,
          noBlanksText: _noBlanksText,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
      ),
    );
  }

  /// Lets the host pick any [GridSheetFilterComparison] — not just the
  /// contains/exact/OR/AND/between examples the toolbar buttons above
  /// demonstrate — and try it live against any column and value(s).
  Widget _buildComparisonPicker(BuildContext context) {
    final colors = context.colors;
    final dropdownDecoration = BoxDecoration(
      color: colors.surfaceSubtle,
      borderRadius: ThemeBorders.roundedSm,
      border: Border.all(color: colors.border),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          key: const Key('picker_column'),
          height: _comparisonHeight,
          decoration: dropdownDecoration,
          child: _compactDropdown<String>(
            value: _pickerColumn,
            values: _columnNames,
            labelBuilder: (name) => name,
            onChanged: (value) {
              setState(() => _pickerColumn = value);
            },
          ),
        ),
        Container(
          key: const Key('picker_comparison'),
          height: _comparisonHeight,
          decoration: dropdownDecoration,
          child: _compactDropdown<GridSheetFilterComparison>(
            value: _pickerComparison,
            values: GridSheetFilterComparison.values,
            labelBuilder: _comparisonLabel,
            onChanged: (value) {
              setState(() => _pickerComparison = value);
            },
          ),
        ),
        if (_pickerIsRange) ...[
          _pickerValueField(context, _minController, 'Min', 'picker_min'),
          _pickerValueField(context, _maxController, 'Max', 'picker_max'),
        ] else
          _pickerValueField(
            context,
            _valueController,
            _pickerComparison == GridSheetFilterComparison.auto
                ? 'e.g. >100, =Apple, app%'
                : 'Value',
            'picker_value',
          ),
        DemoActionButton(
          label: 'Apply Filter',
          icon: Icons.play_arrow,
          color: context.accents.blue,
          onPressed: _applyCustomFilter,
          tooltip: 'addFilters with the selected column, comparison, and '
              'value(s)',
        ),
      ],
    );
  }

  Widget _pickerValueField(
    BuildContext context,
    TextEditingController controller,
    String hint,
    String key,
  ) {
    final colors = context.colors;
    return SizedBox(
      key: Key(key),
      width: 120,
      height: _comparisonHeight,
      child: TextField(
        controller: controller,
        style: TextTypography.bodyMedium.copyWith(color: colors.textPrimary),
        cursorColor: colors.primary,
        textAlignVertical: TextAlignVertical.center,
        onSubmitted: (_) => _applyCustomFilter(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextTypography.bodyMedium.copyWith(color: colors.textMuted),
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
      ),
    );
  }

  Widget _compactDropdown<T>({
    required T value,
    required List<T> values,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    final colors = context.colors;

    return PopupMenuButton<T>(
      initialValue: value,
      tooltip: '',
      color: colors.surface,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 120,
        maxHeight: 300,
      ),
      itemBuilder: (context) {
        return values.map((item) {
          return PopupMenuItem<T>(
            value: item,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              labelBuilder(item),
              style: TextTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          );
        }).toList();
      },
      onSelected: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelBuilder(value),
              style: TextTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  static String _comparisonLabel(GridSheetFilterComparison c) {
    switch (c) {
      case GridSheetFilterComparison.auto:
        return 'Auto (typed operators)';
      case GridSheetFilterComparison.contains:
        return 'Contains';
      case GridSheetFilterComparison.exact:
        return 'Exact Match (=)';
      case GridSheetFilterComparison.notEquals:
        return 'Not Equal';
      case GridSheetFilterComparison.greaterThan:
        return 'Greater Than (>)';
      case GridSheetFilterComparison.greaterThanOrEqual:
        return 'Greater or Equal (>=)';
      case GridSheetFilterComparison.lessThan:
        return 'Less Than (<)';
      case GridSheetFilterComparison.lessThanOrEqual:
        return 'Less or Equal (<=)';
      case GridSheetFilterComparison.between:
        return 'Between (..)';
      case GridSheetFilterComparison.notBetween:
        return 'Not Between (!..)';
      case GridSheetFilterComparison.notContains:
        return 'Does Not Contain';
      case GridSheetFilterComparison.startsWith:
        return 'Starts With';
      case GridSheetFilterComparison.endsWith:
        return 'Ends With';
      // Not offered in the picker below (see the dropdown's `items`
      // filtering) — kept here only so this switch stays exhaustive.
      case GridSheetFilterComparison.like:
        return 'Like';
      case GridSheetFilterComparison.notLike:
        return 'Not Like';
    }
  }

  List<GridSheetColumn> _columns() {
    const titles = ['Athlete', 'Sport', 'Country', 'Medals'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
    ];
    const widths = [130.0, 120.0, 120.0, 100.0];
    return List.generate(_columnNames.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: _columnNames[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        textAlign: types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _rows() {
    // Deliberately includes: two blank COUNTRY cells (blanks/non-blanks
    // demo), an 'Amara Diallo' pair (AND-within-one-cell demo), a
    // Swimming/Athletics split (OR demo), and a medal spread from 1-6
    // (between/greater-than/less-than demos).
    final raw = [
      ['Amara Diallo', 'Swimming', 'France', 5],
      ['Ravi Shankar', 'Athletics', 'India', 2],
      ['Amara Diallo', 'Athletics', 'France', 2],
      ['Wei Zhang', 'Swimming', 'China', 6],
      ['Elena Petrova', 'Gymnastics', '', 1],
      ['Carlos Mendez', 'Swimming', 'Spain', 3],
      ['Sofia Bianchi', 'Athletics', '', 3],
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

  void _toggleFilterPosition(bool value) {
    setState(() => _filterAbove = value);
    status.value =
        'filterPosition: ${value ? "above" : "below"} the header row';
  }

  Future<void> _customizeBlanksKeyword() async {
    final value = await showDemoInputDialog(context, 'blanksText',
        initialValue: _blanksText);
    if (value == null || value.isEmpty) return;
    setState(() => _blanksText = value);
    status.value =
        'blanksText: type "$value" into a filter cell to show only blank values';
  }

  Future<void> _customizeNonBlanksKeyword() async {
    final value = await showDemoInputDialog(context, 'noBlanksText',
        initialValue: _noBlanksText);
    if (value == null || value.isEmpty) return;
    setState(() => _noBlanksText = value);
    status.value =
        'noBlanksText: type "$value" into a filter cell to show only non-blank values';
  }

  Future<void> _filterCountryContains() async {
    final value = await showDemoInputDialog(context, 'Country contains');
    if (value == null || value.isEmpty) return;
    await gridManager.filters.add({
      _columnKey('COUNTRY'): [value]
    }, comparison: GridSheetFilterComparison.contains);
    status.value = 'addFilters(contains): COUNTRY contains "$value"';
  }

  Future<void> _filterSportExact() async {
    final value = await showDemoInputDialog(context, 'Sport is exactly');
    if (value == null || value.isEmpty) return;
    await gridManager.filters.add({
      _columnKey('SPORT'): [value]
    }, comparison: GridSheetFilterComparison.exact);
    status.value = 'addFilters(exact): SPORT == "$value"';
  }

  Future<void> _filterSportOr() async {
    final value = 'Swimming${GridSheetConstants.delimiterOR}Athletics';
    await gridManager.filters.add({
      _columnKey('SPORT'): [value]
    }, comparison: GridSheetFilterComparison.contains);
    _reportFilterStatus("addFilters({'SPORT': ['$value']})");
  }

  Future<void> _filterAthleteAnd() async {
    final value = 'Amara${GridSheetConstants.delimiterAND}Diallo';
    await gridManager.filters.add({
      _columnKey('ATHLETE'): [value]
    }, comparison: GridSheetFilterComparison.contains);
    _reportFilterStatus("addFilters({'ATHLETE': ['$value']})");
  }

  Future<void> _filterMedalsBetween() async {
    final value = '2${GridSheetConstants.delimiterBetween}5';
    await gridManager.filters.add({
      _columnKey('MEDALS'): [value]
    }, comparison: GridSheetFilterComparison.between);
    _reportFilterStatus(
        "addFilters({'MEDALS': ['$value']}, comparison: between)");
  }

  Future<void> _clearFilters() async {
    await gridManager.filters.clearAll();
    status.value = 'clearFilters(): all rows visible again';
  }

  void _updateFiltersVisibility(String label) {
    gridManager.config.updateGrid(
      gridManager.config.grid.copyWith(
        showColumnFilters: _showColumnFilters,
      ),
    );
    status.value = 'updateConfiguration(): $label';
  }

  Future<void> _applyCustomFilter() async {
    final String value;
    if (_pickerIsRange) {
      final min = _minController.text.trim();
      final max = _maxController.text.trim();
      if (min.isEmpty || max.isEmpty) return;
      value = '$min${GridSheetConstants.delimiterBetween}$max';
    } else {
      value = _valueController.text.trim();
      if (value.isEmpty) return;
    }

    await gridManager.filters.add({
      _columnKey(_pickerColumn): [value]
    }, comparison: _pickerComparison);
    _reportFilterStatus(
        "addFilters({'$_pickerColumn': ['$value']}, comparison: ${_pickerComparison.name})");
  }

  void _reportFilterStatus(String call) {
    status.value =
        '$call — ${gridManager.rows.filteredCount} of ${gridManager.rows.count} rows match';
  }
}
