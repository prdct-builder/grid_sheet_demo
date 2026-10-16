import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheetManager.search] — a global, cross-column search
/// distinct from per-column filters (see the Sorting & Filtering demo).
///
/// Each search term becomes a chip. Adding another chip cascades: it
/// narrows the currently-visible rows further, requiring every term to
/// match *somewhere* in the row (not necessarily the same cell).
///
/// A single term can also combine alternatives with [GridSheetConstants]'s
/// `||`/`&&` delimiters — `'Mechanic||Electrician'` (OR: either matches) or
/// `'23&&Mechanic'` (AND: both must match, in any cell) — which is how you
/// widen or combine within one chip instead of only narrowing across chips.
/// A term can also be a `low..high` numeric range (e.g. `'20..30'`), matched
/// against any cell that parses as a number. The quick-add buttons below
/// build these directly; the free-typed field accepts the same syntax.
class OverallSearch extends StatefulWidget {
  const OverallSearch({super.key});

  @override
  State<OverallSearch> createState() => _OverallSearchState();
}

class _OverallSearchState extends State<OverallSearch> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'Type a term and press Enter, or use the quick-add buttons, to build up '
    'a cascading search — each chip narrows the results further.',
  );
  final TextEditingController _inputController = TextEditingController();
  final List<dynamic> _items = [];
  bool _exactCase = false;

  @override
  void dispose() {
    status.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Overall Search',
      description:
          'GridSheetManager.search(values) searches every cell in every row, cascading across multiple '
          'terms and supporting ||/&&/.. syntax for OR, AND, and numeric ranges within a single term.',
      icon: Icons.travel_explore_outlined,
      status: status,
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DemoToolbar(
            sections: [
              DemoActionButton(
                label: "Add 'Mechanic'",
                icon: Icons.add,
                color: context.accents.blue,
                onPressed: () => _addItem('Mechanic'),
                tooltip: "search: add 'Mechanic' to the search",
              ),
              DemoActionButton(
                label: "Add 'John'",
                icon: Icons.add,
                color: context.accents.purple,
                onPressed: () => _addItem('John'),
                tooltip: "search: add 'John' to the search",
              ),
              DemoActionButton(
                label: 'Add 23',
                icon: Icons.add,
                color: context.accents.teal,
                onPressed: () => _addItem(23),
                tooltip: 'search: add the number 23 to the search',
              ),
              DemoActionButton(
                label: "Add 'Mechanic OR Electrician'",
                icon: Icons.call_split,
                color: context.accents.indigo,
                onPressed: () => _addItem(
                    'Mechanic${GridSheetConstants.delimiterOR}Electrician'),
                tooltip: "search: one chip combining two alternatives with "
                    "'||' — matches rows with either role",
              ),
              DemoActionButton(
                label: "Add '23 AND Mechanic'",
                icon: Icons.join_inner,
                color: context.accents.amber,
                onPressed: () =>
                    _addItem('23${GridSheetConstants.delimiterAND}Mechanic'),
                tooltip: "search: one chip requiring both terms with '&&' — "
                    "matches rows with both, in any cell",
              ),
              DemoActionButton(
                label: "Add '20..30' (age range)",
                icon: Icons.linear_scale,
                color: context.accents.pink,
                onPressed: () =>
                    _addItem('20${GridSheetConstants.delimiterBetween}30'),
                tooltip: "search: a 'low..high' numeric range — matches "
                    "any row with a cell numerically between 20 and 30",
              ),
              DemoToggleButton(
                label: 'Match Case',
                icon: Icons.text_fields,
                color: context.accents.deepOrange,
                value: _exactCase,
                onChanged: _toggleMatchCase,
                tooltip: 'search(exactCase: true)',
              ),
              DemoActionButton(
                label: 'Clear Search',
                icon: Icons.clear_all,
                color: context.accents.neutral,
                onPressed: _clearAll,
                tooltip: 'clearSearch(): remove every chip and show all rows',
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
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(enableCellSelection: true),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
      ),
    );
  }

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
            controller: _inputController,
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
                borderSide: BorderSide(
                  color: colors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: ThemeBorders.roundedSm,
                borderSide: BorderSide(
                  color: colors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: ThemeBorders.roundedSm,
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (value) {
              _addItem(value);
              _inputController.clear();
            },
          ),
        ),
        if (_items.isEmpty)
          Text(
            'No search items yet.',
            style: TextTypography.caption.copyWith(color: colors.textMuted),
          )
        else
          for (final item in _items)
            Chip(
              label: Text(
                _displayTerm(item),
                style: TextTypography.bodyMedium
                    .copyWith(color: colors.textPrimary),
              ),
              labelPadding: EdgeInsets.only(right: 8),
              deleteIconColor: colors.danger,
              onDeleted: () => _removeTerm(item),
              visualDensity: VisualDensity.compact,
            ),
      ],
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['NAME', 'ROLE', 'AGE', 'DEPARTMENT'];
    const titles = ['Name', 'Role', 'Age', 'Department'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.text(),
    ];
    const widths = [160.0, 140.0, 100.0, 160.0];

    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        sortable: true,
        textAlign: types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['John Smith', 'Mechanic', 23, 'Workshop'],
      ['John Doe', 'Electrician', 40, 'Facilities'],
      ['Amy Johnson', 'Mechanic', 31, 'Workshop'],
      ['Ben Carter', 'Plumber', 23, 'Facilities'],
      ['John Carter', 'Mechanic', 45, 'Workshop'],
      ['Maria Lopez', 'Nurse', 29, 'Clinic'],
      ['Chris Evans', 'Mechanic', 23, 'Workshop'],
      ['Dana White', 'Electrician', 23, 'Facilities'],
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

  Future<void> _addItem(dynamic value) async {
    final isBlank = value is String && value.trim().isEmpty;
    if (isBlank) return;

    setState(() => _items.add(value is String ? value.trim() : value));
    await gridManager.search.apply(_items, exactMatch: _exactCase);
    _reportStatus('search($_items)');
  }

  Future<void> _removeTerm(dynamic term) async {
    setState(() => _items.remove(term));
    if (_items.isEmpty) {
      await gridManager.search.clear();
      status.value = 'clearSearch(): all rows visible again';
      return;
    }
    await gridManager.search.apply(_items, exactMatch: _exactCase);
    _reportStatus('search($_items)');
  }

  Future<void> _clearAll() async {
    setState(() => _items.clear());
    _inputController.clear();
    await gridManager.search.clear();
    status.value = 'clearSearch(): all rows visible again';
  }

  Future<void> _toggleMatchCase(bool value) async {
    setState(() => _exactCase = value);
    if (_items.isNotEmpty) {
      await gridManager.search.apply(_items, exactMatch: _exactCase);
      _reportStatus('search($_items, exactCase: $_exactCase)');
    } else {
      status.value = 'exactCase: $_exactCase — add a term to see it apply';
    }
  }

  /// Renders a raw search term for the chip label — swaps the `||`/`&&`/`..`
  /// delimiters actually sent to [GridSheetManager.search] for readable
  /// ' OR '/' AND '/' to ' text. Purely presentational: [_items] still
  /// stores the raw term, so chip removal and re-searching are unaffected.
  String _displayTerm(dynamic item) {
    if (item is! String) return '$item';
    return item
        .replaceAll(GridSheetConstants.delimiterOR, ' OR ')
        .replaceAll(GridSheetConstants.delimiterAND, ' AND ')
        .replaceAll(GridSheetConstants.delimiterBetween, ' to ');
  }

  void _reportStatus(String call) {
    status.value =
        '$call — ${gridManager.rows.filteredCount} of ${gridManager.rows.count} rows match';
  }
}
