import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheet.groupingConfiguration] (`.columns`): nested header bands
/// over related columns, collapsible to a summary column, with runtime
/// control through `gridManager.grouping.columns`.
class ColumnGrouping extends StatefulWidget {
  const ColumnGrouping({super.key});

  @override
  State<ColumnGrouping> createState() => _ColumnGroupingState();
}

const _rep = ValueKey<String>('col_rep');
const _email = ValueKey<String>('col_email');
const _city = ValueKey<String>('col_city');
const _country = ValueKey<String>('col_country');
const _q1 = ValueKey<String>('col_q1');
const _q2 = ValueKey<String>('col_q2');
const _q3 = ValueKey<String>('col_q3');
const _q4 = ValueKey<String>('col_q4');
const _total = ValueKey<String>('col_total');
const _target = ValueKey<String>('col_target');
const _team = ValueKey<String>('col_team');

const _groups = [
  GridSheetColumnGroupDescriptor(
    id: 'contact',
    title: 'Contact',
    columnKeys: [_email],
    groups: [
      GridSheetColumnGroupDescriptor(
        id: 'location',
        title: 'Location',
        columnKeys: [_city, _country],
      ),
    ],
  ),
  GridSheetColumnGroupDescriptor(
    id: 'sales',
    title: 'Sales 2025',
    columnKeys: [_q1, _q2, _q3, _q4, _total],
    // Collapsed, the band keeps only the yearly total.
    collapsedColumnKeys: [_total],
  ),
];

class _ColumnGroupingState extends State<ColumnGrouping> {
  final _gridKey = GlobalKey<GridSheetState>();
  final ValueNotifier<String> status = ValueNotifier(
    'Tap a band to collapse it: "Sales 2025" keeps only its Total column; '
    '"Contact" keeps its first column.',
  );

  bool _enabled = true;
  bool _pinRep = true;
  bool _rowGrouping = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  GridSheetColumnGroupingAPI? get _grouping =>
      _gridKey.currentState?.grouping.columns;

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Column Grouping',
      icon: Icons.view_column_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Enabled',
            icon: Icons.view_column_outlined,
            color: context.accents.deepPurple,
            value: _enabled,
            onChanged: (value) {
              setState(() => _enabled = value);
              status.value = value
                  ? 'Column grouping enabled.'
                  : 'Column grouping disabled — no bands, every column shown, '
                      'and gridManager.grouping.columns calls do nothing.';
            },
            tooltip: 'Turn column grouping on or off',
          ),
          DemoActionButton(
            label: 'Collapse all',
            icon: Icons.unfold_less,
            color: context.accents.teal,
            onPressed: () => _grouping?.collapseAll(),
            tooltip: 'gridManager.grouping.columns.collapseAll()',
          ),
          DemoActionButton(
            label: 'Expand all',
            icon: Icons.unfold_more,
            color: context.accents.teal,
            onPressed: () => _grouping?.expandAll(),
            tooltip: 'gridManager.grouping.columns.expandAll()',
          ),
          DemoToggleButton(
            label: 'Pin Rep',
            icon: Icons.push_pin_outlined,
            color: context.accents.orange,
            value: _pinRep,
            onChanged: _togglePin,
            tooltip: 'Pin or unpin the Rep column',
          ),
          DemoToggleButton(
            label: 'Row Grouping',
            icon: Icons.account_tree_outlined,
            color: context.accents.indigo,
            value: _rowGrouping,
            onChanged: (value) {
              setState(() => _rowGrouping = value);
              status.value = value
                  ? 'Rows grouped by team, with quarterly subtotals under the '
                      'Sales band — collapse the band and the Total subtotal stays.'
                  : 'Row grouping off.';
            },
            tooltip: 'Group the reps by team, alongside the column bands',
          ),
        ],
      ),
      grid: GridSheet(
        key: _gridKey,
        columns: _columns(),
        rows: _rows(),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        configuration: const GridSheetConfiguration(
          enableColumnReorder: true,
        ),
        // One configuration for both axes: a side left null is off.
        groupingConfiguration: GridSheetGroupingConfiguration(
          enabled: _enabled || _rowGrouping,
          columns: _enabled
              ? const GridSheetColumnGroupingConfiguration(groups: _groups)
              : null,
          rows: !_rowGrouping
              ? null
              : const GridSheetRowGroupingConfiguration(
                  groupBy: [
                    GridSheetGroupDescriptor(columnKey: _team, title: 'Team'),
                  ],
                  aggregates: [
                    GridSheetAggregateSpec.sum(_q1, label: 'Σ'),
                    GridSheetAggregateSpec.sum(_q2, label: 'Σ'),
                    GridSheetAggregateSpec.sum(_q3, label: 'Σ'),
                    GridSheetAggregateSpec.sum(_q4, label: 'Σ'),
                    GridSheetAggregateSpec.sum(_total, label: 'Σ'),
                  ],
                  showGrandTotal: true,
                ),
          onExpansionChanged: (event) {
            if (event.axis != GridSheetGroupAxis.columns) return;
            final group = event.groupId == null
                ? null
                : event.gridManager.grouping.columns.find(event.groupId!);
            status.value = group != null
                ? '${event.expanded! ? 'Expanded' : 'Collapsed'} "${group.label}".'
                : 'Changed expansion of every group.';
          },
        ),
      ),
    );
  }

  Future<void> _togglePin(bool value) async {
    setState(() => _pinRep = value);
    final manager = _gridKey.currentState;
    if (manager == null) return;
    if (value) {
      await manager.columns.pin(leftKeys: const [_rep]);
    } else {
      await manager.columns.unpin(const [_rep]);
    }
    status.value = value
        ? 'Rep is pinned; the bands stay over their own columns.'
        : 'Rep scrolls with the other columns.';
  }

  List<GridSheetColumn> _columns() {
    const specs = [
      (_rep, 'REP', 'Rep', GridSheetColumnType.text(), 150.0),
      (_email, 'EMAIL', 'Email', GridSheetColumnType.text(), 220.0),
      (_city, 'CITY', 'City', GridSheetColumnType.text(), 130.0),
      (_country, 'COUNTRY', 'Country', GridSheetColumnType.text(), 130.0),
      (_q1, 'Q1', 'Q1', GridSheetColumnType.integer(), 100.0),
      (_q2, 'Q2', 'Q2', GridSheetColumnType.integer(), 100.0),
      (_q3, 'Q3', 'Q3', GridSheetColumnType.integer(), 100.0),
      (_q4, 'Q4', 'Q4', GridSheetColumnType.integer(), 100.0),
      (_total, 'TOTAL', 'Total', GridSheetColumnType.integer(), 120.0),
      (_target, 'TARGET', 'Target', GridSheetColumnType.integer(), 120.0),
      (_team, 'TEAM', 'Team', GridSheetColumnType.text(), 120.0),
    ];
    return [
      for (final (i, (key, name, title, type, width)) in specs.indexed)
        GridSheetColumn(
          key: key,
          index: i,
          name: name,
          title: title,
          type: type,
          width: width,
          sortable: true,
          resizable: true,
          pinnedLeft: key == _rep && _pinRep,
          textAlign: type.kind == GridSheetColumnKind.integer
              ? TextAlign.right
              : TextAlign.left,
        ),
    ];
  }

  List<GridSheetRow> _rows() {
    const teams = [
      'Americas',
      'EMEA',
      'APAC',
      'EMEA',
      'EMEA',
      'APAC',
      'EMEA',
      'APAC'
    ];
    const reps = [
      ('Ana Lima', 'ana@acme.io', 'São Paulo', 'Brazil'),
      ('Ben Okafor', 'ben@acme.io', 'Lagos', 'Nigeria'),
      ('Chen Wei', 'chen@acme.io', 'Shanghai', 'China'),
      ('Dana Cohen', 'dana@acme.io', 'Tel Aviv', 'Israel'),
      ('Elena Petrova', 'elena@acme.io', 'Sofia', 'Bulgaria'),
      ('Farah Khan', 'farah@acme.io', 'Karachi', 'Pakistan'),
      ('Gustav Berg', 'gustav@acme.io', 'Oslo', 'Norway'),
      ('Hana Sato', 'hana@acme.io', 'Osaka', 'Japan'),
    ];
    return [
      for (final (i, (name, email, city, country)) in reps.indexed)
        () {
          final quarters = [
            for (var q = 0; q < 4; q++) 20 + (i * 7 + q * 5) % 30
          ];
          final total = quarters.fold<int>(0, (a, b) => a + b);
          return GridSheetRow(
            key: ValueKey('row_$i'),
            index: i,
            data: [
              name,
              email,
              city,
              country,
              ...quarters,
              total,
              100,
              teams[i],
            ],
            height: Constants.rowHeight,
          );
        }(),
    ];
  }
}
