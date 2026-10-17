import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates multi-column sorting.
class Sorting extends StatefulWidget {
  const Sorting({super.key});

  @override
  State<Sorting> createState() => _SortingState();
}

class _SortingState extends State<Sorting> {
  late GridSheetManager gridManager;

  /// Resolves a column name to its key — the manager's column methods are
  /// key-addressed.
  ValueKey<String> _columnKey(String name) =>
      gridManager.columns.findByNames([name]).single.key;

  final ValueNotifier<String> status = ValueNotifier(
    'Double-tap a sortable header to sort. Double-tap a second header to add a secondary sort key.',
  );
  bool _useCustomSortIcon = true;
  bool _useCustomSportOrder = false;

  // Ranks sports by event order in a typical Olympic program instead of
  // alphabetically — proof sorting.setComparator can encode any domain-specific
  // ordering, not just A→Z.
  static const _sportRank = {
    'Gymnastics': 0,
    'Swimming': 1,
    'Athletics': 2,
  };

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Sorting',
      icon: Icons.swap_vert_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'Sort Medals ↓',
            icon: Icons.arrow_downward,
            color: context.accents.red,
            onPressed: _sortByMedalsDesc,
            tooltip: 'Sort MEDALS descending',
          ),
          DemoActionButton(
            label: 'Sort Country → Medals ↓',
            icon: Icons.layers_outlined,
            color: context.accents.blue,
            onPressed: _sortByCountryThenMedals,
            tooltip: 'Programmatic multi-column sort: COUNTRY asc, '
                'then MEDALS desc as the tiebreaker',
          ),
          DemoActionButton(
            label: 'Clear Sort',
            icon: Icons.clear,
            color: context.accents.neutral,
            onPressed: _clearSort,
            tooltip: 'Restore the original row order',
          ),
          DemoActionButton(
            label: 'Show Active Sort',
            icon: Icons.visibility_outlined,
            color: context.accents.teal,
            onPressed: _showActiveSortKeys,
            tooltip: 'Read gridManager.sorting.keys and print the current '
                'sort state',
          ),
          DemoToggleButton(
            label: 'Custom Sort Icon',
            icon: Icons.star,
            color: context.accents.pink,
            value: _useCustomSortIcon,
            onChanged: _toggleCustomSortIcon,
            tooltip: 'Switch to colored arrow icons with a priority number',
          ),
          DemoToggleButton(
            label: 'Custom Sport Order',
            icon: Icons.sports_gymnastics,
            color: context.accents.orange,
            value: _useCustomSportOrder,
            onChanged: _toggleCustomSportOrder,
            tooltip: 'sorting.setComparator on SPORT: rank by Olympic event '
                'order instead of alphabetically',
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
        sortIconBuilder: (column, direction, priority) {
          if (!_useCustomSortIcon) return null; // fall back to the default icon
          final isAsc = direction == GridSheetSortDirection.asc;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 15,
                color: isAsc ? context.accents.green : context.accents.red,
              ),
              Text(
                ' $priority',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['ATHLETE', 'SPORT', 'COUNTRY', 'MEDALS'];
    const titles = ['Athlete', 'Sport', 'Country', 'Medals'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
    ];
    const widths = [120.0, 120.0, 120.0, 120.0];
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
      ['Amara Diallo', 'Swimming', 'France', 5],
      ['Ravi Shankar', 'Athletics', 'India', 2],
      ['Amara Diallo', 'Athletics', 'France', 2],
      ['Wei Zhang', 'Swimming', 'China', 6],
      ['Elena Petrova', 'Gymnastics', 'Russia', 1],
      ['Carlos Mendez', 'Swimming', 'Spain', 3],
      ['Sofia Bianchi', 'Athletics', 'Italy', 3],
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

  Future<void> _sortByMedalsDesc() async {
    await gridManager.sorting
        .sortBy(_columnKey('MEDALS'), direction: GridSheetSortDirection.desc);
    status.value = 'sorting.sortBy("MEDALS", desc): highest medal count first';
  }

  Future<void> _clearSort() async {
    await gridManager.sorting.clear();
    status.value = 'sorting.clear(): restored original order';
  }

  Future<void> _sortByCountryThenMedals() async {
    // sorting.clear() first so this always starts a fresh two-key sort rather than
    // appending on top of whatever a header double-tap already set.
    await gridManager.sorting.clear();
    await gridManager.sorting.sortBy(_columnKey('COUNTRY'));
    await gridManager.sorting
        .sortBy(_columnKey('MEDALS'), direction: GridSheetSortDirection.desc);
    status.value =
        'sorting.sortBy("COUNTRY") then sorting.sortBy("MEDALS", desc): '
        'grouped by country, highest medal count first within each group';
  }

  void _showActiveSortKeys() {
    final keys = gridManager.sorting.keys;
    status.value = keys.isEmpty
        ? 'sorting.keys: [] — no active sort'
        : 'sorting.keys: ${keys.map((k) => '${k.name} ${k.direction.name}').join(', ')}';
  }

  void _toggleCustomSortIcon(bool value) {
    setState(() => _useCustomSortIcon = value);
    status.value = value
        ? 'sortIconBuilder: custom colored arrows with priority number'
        : 'sortIconBuilder returns null: falling back to the default sort icon';
  }

  void _toggleCustomSportOrder(bool value) {
    setState(() => _useCustomSportOrder = value);
    gridManager.sorting.setComparator(
      _columnKey('SPORT'),
      value
          ? (a, b, {required rowA, required rowB, required column}) {
              final rankA = _sportRank[a] ?? _sportRank.length;
              final rankB = _sportRank[b] ?? _sportRank.length;
              return rankA.compareTo(rankB);
            }
          : null,
    );
    status.value = value
        ? 'sorting.setComparator("SPORT", ...): sorts by Olympic event order '
            '(Gymnastics, Swimming, Athletics) instead of A→Z'
        : 'sorting.setComparator("SPORT", null): back to the default '
            'alphabetical comparator';
  }
}
