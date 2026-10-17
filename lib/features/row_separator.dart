import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheet.rowSeparatorBuilder]: a subtotal banner rendered
/// below the last line item of each order, spanning the grid's full width —
/// including under the pinned ORDER column — rather than being confined to
/// the scrollable fields the way [GridSheet.rowExpandedBuilder]'s
/// panel is.
class RowSeparators extends StatefulWidget {
  const RowSeparators({super.key});

  @override
  State<RowSeparators> createState() => _RowSeparatorsState();
}

class _RowSeparatorsState extends State<RowSeparators> {
  final ValueNotifier<String> status = ValueNotifier(
    'rowSeparatorBuilder inserts a subtotal banner after each order\'s last '
    'line item — notice it spans under the pinned ORDER column too.',
  );

  bool _enabled = true;

  static const _cyclableHeights = [36.0, 56.0, 80.0];
  double _separatorHeight = _cyclableHeights[0];

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Row Separators',
      icon: Icons.horizontal_rule_rounded,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Enabled',
            icon: Icons.horizontal_rule_rounded,
            color: context.accents.deepPurple,
            value: _enabled,
            onChanged: _toggleEnabled,
            tooltip: 'Toggle whether subtotal banners render at all',
          ),
          DemoActionButton(
            label: '${_separatorHeight.toInt()}px',
            icon: Icons.height_outlined,
            color: context.accents.teal,
            onPressed: _cycleHeight,
            tooltip: 'Cycle the subtotal banner\'s declared height',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows,
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        rowSeparatorBuilder: !_enabled
            ? null
            : (context, row, manager) {
                // Totals come from the grid's current rows, so edits, sorting
                // and filtering are reflected.
                final summary = _summaryAt(manager.rows.currentPage, row);
                if (summary == null) return null;
                return GridSheetRowSeparator(
                  height: _separatorHeight,
                  widget: _SubtotalBanner(summary: summary),
                );
              },
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  void _toggleEnabled(bool value) {
    setState(() => _enabled = value);
    status.value = value
        ? 'rowSeparatorBuilder enabled — a subtotal banner follows each order\'s last item.'
        : 'rowSeparatorBuilder returns null for every row — no banners, rows pack tight.';
  }

  void _cycleHeight() {
    final next = (_cyclableHeights.indexOf(_separatorHeight) + 1) %
        _cyclableHeights.length;
    setState(() => _separatorHeight = _cyclableHeights[next]);
    status.value =
        'Banner height: ${_separatorHeight.toInt()}px — declared up front via '
        'GridSheetRowSeparator.height, the same way the virtualized row list '
        'needs every row\'s exact extent before laying it out.';
  }

  List<GridSheetColumn> _columns() {
    const names = ['ORDER', 'ITEM', 'QTY', 'UNIT_PRICE', 'LINE_TOTAL'];
    const titles = ['Order', 'Item', 'Qty', 'Unit Price', 'Line Total'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.double(),
      GridSheetColumnType.formula(),
    ];
    const widths = [110.0, 220.0, 90.0, 130.0, 130.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        pinnedLeft: i == 0,
        // ORDER identifies the group rowSeparatorBuilder subtotals by, and
        // LINE_TOTAL is the formula QTY * UNIT_PRICE — neither is hand-edited.
        editable: i != 0 && i != 4,
      );
    });
  }

  // Built once, so rebuilding the page doesn't hand the grid a new list.
  late final List<GridSheetRow> _rows = _buildRows();

  List<GridSheetRow> _buildRows() {
    const lineTotal = '=QTY*UNIT_PRICE';
    final raw = [
      ['A-1001', 'Wireless Mouse', 2, 24.99, lineTotal],
      ['A-1001', 'USB-C Hub', 1, 39.50, lineTotal],
      ['A-1002', 'Mechanical Keyboard', 1, 89.00, lineTotal],
      ['A-1002', 'Wrist Rest', 1, 14.25, lineTotal],
      ['A-1002', 'Cable Organizer', 3, 6.99, lineTotal],
      ['A-1003', 'Monitor Arm', 2, 54.00, lineTotal],
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

  /// The subtotal for [row]'s order when [row] is that order's last line
  /// item in [rows] (the grid's current page, in display order), else
  /// `null`. Orders are consecutive rows sharing the ORDER value
  /// (`data[0]`). Totals are QTY * UNIT_PRICE from the current data, so
  /// edits show up at once.
  _OrderSummary? _summaryAt(List<GridSheetRow> rows, GridSheetRow row) {
    final i = rows.indexWhere((r) => r.key == row.key);
    if (i < 0) return null;
    final orderId = rows[i].data[0];
    final isLastInOrder =
        i == rows.length - 1 || rows[i + 1].data[0] != orderId;
    if (!isLastInOrder) return null;

    var start = i;
    while (start > 0 && rows[start - 1].data[0] == orderId) {
      start--;
    }
    final itemsInOrder = rows.sublist(start, i + 1);
    double number(Object? value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return _OrderSummary(
      orderId: '$orderId',
      total: itemsInOrder.fold(
          0.0, (sum, r) => sum + number(r.data[2]) * number(r.data[3])),
      itemCount: itemsInOrder.length,
    );
  }
}

class _OrderSummary {
  final String orderId;
  final double total;
  final int itemCount;

  const _OrderSummary({
    required this.orderId,
    required this.total,
    required this.itemCount,
  });
}

class _SubtotalBanner extends StatelessWidget {
  final _OrderSummary summary;

  const _SubtotalBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ThemeSpacing.lg),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
      ),
      child: Text(
        '${summary.orderId} total: \$${summary.total.toStringAsFixed(2)} · '
        '${summary.itemCount} item${summary.itemCount == 1 ? '' : 's'}',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
