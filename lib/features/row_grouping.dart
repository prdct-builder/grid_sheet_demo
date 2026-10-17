import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheet.groupingConfiguration] (`.rows`): orders grouped by one
/// or more levels under collapsible headers, with per-group sums, averages
/// and a grand total, plus runtime control through
/// `gridManager.grouping.rows`.
class RowGrouping extends StatefulWidget {
  const RowGrouping({super.key});

  @override
  State<RowGrouping> createState() => _RowGroupingState();
}

const _region = ValueKey<String>('col_region');
const _category = ValueKey<String>('col_category');
const _product = ValueKey<String>('col_product');
const _date = ValueKey<String>('col_date');
const _qty = ValueKey<String>('col_qty');
const _amount = ValueKey<String>('col_amount');

/// The grouping layouts the "Group by" button cycles through.
final _layouts = <(String, List<GridSheetGroupDescriptor>)>[
  (
    'Region',
    const [GridSheetGroupDescriptor(columnKey: _region, title: 'Region')],
  ),
  (
    'Region › Category',
    const [
      GridSheetGroupDescriptor(columnKey: _region, title: 'Region'),
      GridSheetGroupDescriptor(columnKey: _category),
    ],
  ),
  (
    'Quarter',
    [
      GridSheetGroupDescriptor.date(_date, GridSheetGroupDatePart.quarter,
          title: 'Quarter'),
    ],
  ),
  (
    'Amount range',
    [
      GridSheetGroupDescriptor.range(_amount, [500, 2000],
          labels: ['Small (< 500)', 'Medium (500 – 2,000)', 'Large (≥ 2,000)'],
          title: 'Order size'),
    ],
  ),
  (
    'Category by total',
    const [
      GridSheetGroupDescriptor(
        columnKey: _category,
        title: 'Category',
        sort: GridSheetGroupSort.aggregate('sum:col_amount'),
      ),
    ],
  ),
];

class _RowGroupingState extends State<RowGrouping> {
  final _gridKey = GlobalKey<GridSheetState>();
  final ValueNotifier<String> status = ValueNotifier(
    'Rows are grouped by region. Tap a group header to collapse it; the '
    'checkbox on a header selects all of its rows.',
  );

  bool _enabled = true;
  int _layout = 0;
  bool _subtotals = false;
  bool _grandTotal = true;
  bool _columnGrouping = false;

  late final List<GridSheetRow> _rows = _buildRows();

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  GridSheetRowGroupingAPI? get _grouping =>
      _gridKey.currentState?.grouping.rows;

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Row Grouping',
      icon: Icons.account_tree_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Enabled',
            icon: Icons.account_tree_outlined,
            color: context.accents.deepPurple,
            value: _enabled,
            onChanged: _toggleEnabled,
            tooltip: 'Turn row grouping on or off',
          ),
          DemoActionButton(
            label: 'Group by: ${_layouts[_layout].$1}',
            icon: Icons.layers_outlined,
            color: context.accents.indigo,
            onPressed: _cycleLayout,
            tooltip: 'Cycle through grouping levels',
          ),
          DemoActionButton(
            label: 'Expand all',
            icon: Icons.unfold_more,
            color: context.accents.teal,
            onPressed: () => _grouping?.expandAll(),
            tooltip: 'gridManager.grouping.rows.expandAll()',
          ),
          DemoActionButton(
            label: 'Collapse all',
            icon: Icons.unfold_less,
            color: context.accents.teal,
            onPressed: () => _grouping?.collapseAll(),
            tooltip: 'gridManager.grouping.rows.collapseAll()',
          ),
          DemoToggleButton(
            label: 'Subtotals',
            icon: Icons.functions,
            color: context.accents.orange,
            value: _subtotals,
            onChanged: (value) {
              setState(() => _subtotals = value);
              status.value = value
                  ? 'Aggregates now also show on a subtotal line after each group.'
                  : 'Aggregates show on the group headers only.';
            },
            tooltip: 'Show a subtotal line after each group',
          ),
          DemoToggleButton(
            label: 'Grand total',
            icon: Icons.summarize_outlined,
            color: context.accents.green,
            value: _grandTotal,
            onChanged: (value) => setState(() => _grandTotal = value),
            tooltip: 'Show a grand-total line at the end',
          ),
          DemoToggleButton(
            label: 'Column Grouping',
            icon: Icons.view_column_outlined,
            color: context.accents.purple,
            value: _columnGrouping,
            onChanged: (value) {
              setState(() => _columnGrouping = value);
              status.value = value
                  ? 'Header bands added: tap "Order details" to collapse it to '
                      'Region and Category; the group lines follow the columns.'
                  : 'Column grouping off.';
            },
            tooltip: 'Add header bands over the columns, alongside row groups',
          ),
        ],
      ),
      grid: GridSheet(
        key: _gridKey,
        columns: _columns(),
        rows: _rows,
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        configuration: const GridSheetConfiguration(
          enableRowSelectionOnFirstColumnTap: true,
          enableMultiSelection: true,
          showColumnFilters: true,
        ),
        // One configuration for both axes: a side left null is off.
        groupingConfiguration: GridSheetGroupingConfiguration(
          enabled: _enabled || _columnGrouping,
          rows: !_enabled
              ? null
              : GridSheetRowGroupingConfiguration(
                  groupBy: _layouts[_layout].$2,
                  aggregates: const [
                    GridSheetAggregateSpec.sum(_qty, label: 'Qty'),
                    GridSheetAggregateSpec.sum(_amount, label: 'Total'),
                    GridSheetAggregateSpec.average(_amount, label: 'Avg'),
                  ],
                  aggregatePosition: _subtotals
                      ? GridSheetRowGroupAggregatePosition.both
                      : GridSheetRowGroupAggregatePosition.header,
                  showGrandTotal: _grandTotal,
                  labelColumnSpan: 2,
                ),
          columns: !_columnGrouping
              ? null
              : const GridSheetColumnGroupingConfiguration(
                  groups: [
                    GridSheetColumnGroupDescriptor(
                      id: 'order',
                      title: 'Order details',
                      columnKeys: [_region, _category, _product, _date],
                      // Keep the two columns the group label spans.
                      collapsedColumnKeys: [_region, _category],
                    ),
                    GridSheetColumnGroupDescriptor(
                      id: 'figures',
                      title: 'Figures',
                      columnKeys: [_qty, _amount],
                      collapsible: false,
                    ),
                  ],
                ),
          onExpansionChanged: (event) {
            if (event.axis != GridSheetGroupAxis.rows) return;
            final group = event.groupId == null
                ? null
                : event.gridManager.grouping.rows.find(event.groupId!);
            status.value = group != null
                ? '${event.expanded! ? 'Expanded' : 'Collapsed'} "${group.label}" '
                    '(${group.count} orders).'
                : 'Changed expansion of every group.';
          },
        ),
        onRowsSelected: (event) {
          status.value = '${event.gridManager.selection.rowKeys.length} '
              'order(s) selected.';
        },
      ),
    );
  }

  void _toggleEnabled(bool value) {
    setState(() => _enabled = value);
    status.value = value
        ? 'Grouping enabled — rows are gathered under group headers.'
        : 'Grouping disabled — the grid shows the plain row list, and '
            'gridManager.grouping.rows calls do nothing.';
  }

  void _cycleLayout() {
    setState(() => _layout = (_layout + 1) % _layouts.length);
    status.value = 'Grouped by ${_layouts[_layout].$1}. Sorting any column '
        'orders the rows inside each group.';
  }

  List<GridSheetColumn> _columns() {
    const specs = [
      (_region, 'REGION', 'Region', GridSheetColumnType.text(), 140.0),
      (_category, 'CATEGORY', 'Category', GridSheetColumnType.text(), 150.0),
      (_product, 'PRODUCT', 'Product', GridSheetColumnType.text(), 200.0),
      (_date, 'ORDER_DATE', 'Order Date', GridSheetColumnType.text(), 140.0),
      (_qty, 'QTY', 'Qty', GridSheetColumnType.integer(), 160.0),
      (_amount, 'AMOUNT', 'Amount', GridSheetColumnType.double(), 260.0),
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
          textAlign: type.kind == GridSheetColumnKind.text
              ? TextAlign.left
              : TextAlign.right,
          sortable: true,
        ),
    ];
  }

  List<GridSheetRow> _buildRows() {
    final raw = [
      ['Europe', 'Hardware', 'Mechanical Keyboard', '2024-01-14', 12, 1068.0],
      ['Europe', 'Hardware', 'Monitor Arm', '2024-02-03', 4, 216.0],
      ['Europe', 'Software', 'Design Suite License', '2024-04-22', 10, 2990.0],
      ['Europe', 'Services', 'Onboarding Workshop', '2024-07-09', 1, 1500.0],
      ['North America', 'Hardware', 'USB-C Hub', '2024-01-30', 40, 1580.0],
      ['North America', 'Hardware', 'Wireless Mouse', '2024-03-11', 25, 624.75],
      ['North America', 'Software', 'Analytics Add-on', '2024-05-18', 3, 897.0],
      ['North America', 'Services', 'Premium Support', '2024-08-02', 2, 4200.0],
      [
        'North America',
        'Software',
        'Design Suite License',
        '2024-10-27',
        6,
        1794.0
      ],
      ['Asia Pacific', 'Hardware', 'Docking Station', '2024-02-19', 8, 1432.0],
      ['Asia Pacific', 'Services', 'Data Migration', '2024-06-05', 1, 3800.0],
      ['Asia Pacific', 'Software', 'Analytics Add-on', '2024-09-14', 5, 1495.0],
      ['Asia Pacific', 'Hardware', 'Cable Organizer', '2024-11-21', 60, 419.4],
      ['Latin America', 'Hardware', 'Wrist Rest', '2024-03-27', 30, 427.5],
      [
        'Latin America',
        'Software',
        'Design Suite License',
        '2024-07-15',
        2,
        598.0
      ],
      [
        'Latin America',
        'Services',
        'Onboarding Workshop',
        '2024-12-03',
        1,
        1500.0
      ],
    ];
    return [
      for (final (i, data) in raw.indexed)
        GridSheetRow(
          key: ValueKey('row_$i'),
          index: i,
          data: data,
          height: Constants.rowHeight,
        ),
    ];
  }
}
