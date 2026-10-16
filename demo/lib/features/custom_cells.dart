import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/design_system.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';

class CustomCells extends StatefulWidget {
  const CustomCells({super.key});

  @override
  State<CustomCells> createState() => _CustomCellsState();
}

class _CustomCellsState extends State<CustomCells> {
  late final GridSheetManager gridManager;
  late IGridSheetCustomCellBuilder _cellBuilder;
  final ValueNotifier<String> status = ValueNotifier('');

  late List<List<dynamic>> rows;

  bool _enableRowHover = false;
  bool _enableRowGrouping = false;
  bool _enableColumnGrouping = false;

  static ValueKey<String> _columnKey(int index) =>
      ValueKey('${GridSheetConstants.columnCopyKeyStartsWith}$index');

  @override
  void initState() {
    super.initState();
    _cellBuilder = CustomCellsBuilder();
  }

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build style configuration based on current theme
    final styleConfiguration = styleConfig(context, colorEvenOdd: false);

    return FeaturePageTemplate(
      title: 'Custom Cells',
      description:
          'GridSheet.cellBuilder fully overrides index, header, filter, and row cells with any custom '
          'widget, replacing the default text/editing rendering entirely. The Phones column stores '
          'a 3-item list per cell, edited through three text fields and saved as a new list.',
      icon: Icons.widgets_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Row Hover',
            icon: Icons.ads_click,
            color: context.accents.orange,
            value: _enableRowHover,
            onChanged: _toggleRowHover,
            tooltip: 'Toggle whether rows highlight on hover',
          ),
          DemoToggleButton(
            label: 'Row Grouping',
            icon: Icons.account_tree_outlined,
            color: context.accents.deepPurple,
            value: _enableRowGrouping,
            onChanged: _toggleRowGrouping,
            tooltip: 'Group the products by status, with custom group cells',
          ),
          DemoToggleButton(
            label: 'Column Grouping',
            icon: Icons.view_column_outlined,
            color: context.accents.teal,
            value: _enableColumnGrouping,
            onChanged: _toggleColumnGrouping,
            tooltip: 'Group the columns under custom header bands',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _getColumns(),
        rows: _getRows(),
        configuration: GridSheetConfiguration(
          showColumnFilters: true,
          enableRowSelectionOnFirstColumnTap: true,
          enableMultiSelection: true,
          enableRowHover: _enableRowHover,
        ),
        styleConfiguration: styleConfiguration,
        scrollConfiguration: scrollConfig(context),
        // Row Grouping groups the rows by STATUS (group cells built by
        // buildGroupCell); Column Grouping adds header bands (built by
        // buildColumnGroupBand). A side left null is off.
        groupingConfiguration: GridSheetGroupingConfiguration(
          enabled: _enableRowGrouping || _enableColumnGrouping,
          columns: _enableColumnGrouping
              ? GridSheetColumnGroupingConfiguration(
                  groups: _columnGroups,
                  cellBuilder: (band) => buildColumnGroupBand(context, band),
                )
              : null,
          rows: !_enableRowGrouping
              ? null
              : GridSheetRowGroupingConfiguration(
                  groupBy: [
                    GridSheetRowGroupDescriptor(
                        columnKey: _columnKey(7)), // STATUS
                  ],
                  aggregates: [
                    GridSheetAggregateSpec.sum(_columnKey(3)), // QUANTITY
                    GridSheetAggregateSpec.average(_columnKey(4)), // PRICE
                  ],
                  showGrandTotal: true,
                  labelColumnSpan: 3,
                  cellBuilder: (cell) => buildGroupCell(context, cell),
                ),
          onExpansionChanged: (event) {
            final grouping = event.gridManager.grouping;
            final isRows = event.axis == GridSheetGroupAxis.rows;
            final group = event.groupId == null
                ? null
                : isRows
                    ? grouping.rows.find(event.groupId!)
                    : grouping.columns.find(event.groupId!);
            status.value = group == null
                ? '${isRows ? 'Row' : 'Column'} groups expanded or collapsed.'
                : '${group.label}: ${event.expanded! ? 'expanded' : 'collapsed'}';
          },
        ),
        onLoaded: (event) => gridManager = event.gridManager,
        onColumnsSelected: (event) {
          status.value =
              'onColumnsSelected: ${event.selectedColumnNames.join(", ")}';
        },
        onRowsSelected: (event) {
          status.value =
              'onRowsSelected: ${event.selectedRowKeys.length} row(s)';
        },
        onCellsSelected: (event) {
          status.value =
              'onCellsSelected: ${event.selectedCells.length} cell(s)';
        },
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
        cellBuilder: (cell) {
          switch (cell.kind) {
            case GridSheetCellKind.selectAll:
              return _cellBuilder.buildSelectAll(context, cell);
            case GridSheetCellKind.indexing:
              return _cellBuilder.buildIndexes(context, cell);
            case GridSheetCellKind.header:
              return _cellBuilder.buildHeader(context, cell);
            case GridSheetCellKind.filter:
              return _cellBuilder.buildFilter(context, cell.column, cell);
            case GridSheetCellKind.row:
              final row = cell.row!;
              final column = cell.column;
              return _cellBuilder.buildCell(context, column, row, cell);
          }
        },
      ),
    );
  }

  List<GridSheetColumn> _getColumns() {
    const titles = [
      'Product',
      'Supplier',
      'Contact',
      'Quantity',
      'Price',
      'Rating',
      'Restock Date',
      'Status',
      'In Stock',
      'Phones',
      'Actions',
    ];
    const names = [
      'PRODUCT',
      'SUPPLIER',
      'CONTACT',
      'QUANTITY',
      'PRICE',
      'RATING',
      'RESTOCK_DATE',
      'STATUS',
      'IN_STOCK',
      'PHONES',
      'ACTIONS',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.double(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.datetime(),
      GridSheetColumnType.text(),
      GridSheetColumnType.boolean(),
      GridSheetColumnType.custom(),
      GridSheetColumnType.text(),
    ];
    const widths = [
      160.0,
      160.0,
      190.0,
      120.0,
      110.0,
      120.0,
      140.0,
      130.0,
      100.0,
      360.0,
      110.0,
    ];

    return List.generate(titles.length, (i) {
      final key = '${GridSheetConstants.columnCopyKeyStartsWith}$i';
      return GridSheetColumn(
        key: ValueKey<String>(key),
        title: titles[i],
        name: names[i],
        type: types[i],
        width: widths[i],
        visible: true,
        textAlign: types[i].kind == GridSheetColumnKind.double ||
                types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
        index: i,
        resizable: true,
        sortable: true,
        pinnedRight: names[i] == 'ACTIONS',
        hasTextController: names[i] == 'PRODUCT',
        filterHint: 'Search..',
      );
    });
  }

  List<GridSheetRow> _getRows() {
    rows = [
      [
        'Office Chair',
        'ErgoDesk Co.',
        'Maria Chen|maria.chen@ergodesk.com',
        25,
        149.99,
        4,
        '2026-02-20',
        'Available',
        true,
        ['+91 98480 12345', '+91 99887 76655', null],
        ''
      ],
      [
        'LED Monitor 27"',
        'ViewTech',
        'James Patel|james.patel@viewtech.io',
        12,
        299.50,
        5,
        '2026-02-21',
        'Available',
        true,
        ['+1 415 555 0100', null, null],
        ''
      ],
      [
        'Notebook Pack (12)',
        'Moleskine',
        'Sofia Rossi|sofia.rossi@moleskine.com',
        200,
        2.50,
        4,
        '2026-02-22',
        'Available',
        true,
        ['+44 20 7946 0958', '+44 7700 900123', '+44 7700 900456'],
        ''
      ],
      [
        'Desk Lamp',
        'Ikea',
        'Lars Andersson|lars.andersson@ikea.com',
        0,
        49.99,
        3,
        '2026-02-19',
        'Out of Stock',
        false,
        [null, null, null],
        ''
      ],
      [
        'Bookshelf',
        'Herman Miller',
        'Emily Carter|emily.carter@hermanmiller.com',
        8,
        199.00,
        5,
        '2026-02-18',
        'Low Stock',
        true,
        ['+91 90000 11111', null, null],
        ''
      ],
      [
        'Pen Set (10ct)',
        'Pilot',
        'Kenji Sato|kenji.sato@pilotpen.com',
        500,
        5.99,
        4,
        '2026-02-22',
        'Available',
        true,
        ['+49 30 123456', '+49 151 2345678', null],
        ''
      ],
      [
        'Laptop Stand',
        'Twelve South',
        'Ava Thompson|ava.thompson@twelvesouth.com',
        6,
        45.00,
        5,
        '2026-02-20',
        'Low Stock',
        true,
        ['+1 212 555 0199', null, null],
        ''
      ],
      [
        'Whiteboard 4x3',
        'Quartet',
        'Daniel Kim|daniel.kim@quartet.com',
        0,
        89.99,
        3,
        '2026-02-17',
        'Out of Stock',
        false,
        ['+81 3 1234 5678', '+81 90 1234 5678', null],
        ''
      ],
    ];

    return rows.asMap().entries.map((e) {
      final index = e.key;
      final rowData = e.value;
      final key = '${GridSheetConstants.rowKeyStartsWith}$index';

      final row = GridSheetRow(
        key: ValueKey<String>(key),
        index: index,
        data: rowData,
        height: Constants.rowHeight,
      );

      return row;
    }).toList();
  }

  void _toggleRowHover(bool value) {
    setState(() => _enableRowHover = value);
  }

  // PRODUCT, SUPPLIER and CONTACT under "Product"; QUANTITY, PRICE and
  // RATING under "Inventory", split into nested "Stock" and "Quality"
  // bands; RESTOCK_DATE, STATUS and IN_STOCK under "Fulfilment". PHONES and
  // ACTIONS stay ungrouped.
  List<GridSheetColumnGroupDescriptor> get _columnGroups => [
        GridSheetColumnGroupDescriptor(
          id: 'product',
          title: 'Product',
          columnKeys: [_columnKey(0), _columnKey(1), _columnKey(2)],
        ),
        GridSheetColumnGroupDescriptor(
          id: 'inventory',
          title: 'Inventory',
          // Collapsed, Inventory keeps only QUANTITY.
          collapsedColumnKeys: [_columnKey(3)],
          groups: [
            GridSheetColumnGroupDescriptor(
              id: 'stock',
              title: 'Stock',
              columnKeys: [_columnKey(3), _columnKey(4)],
              collapsible: false,
            ),
            GridSheetColumnGroupDescriptor(
              id: 'quality',
              title: 'Quality',
              columnKeys: [_columnKey(5)],
              collapsible: false,
            ),
          ],
        ),
        GridSheetColumnGroupDescriptor(
          id: 'fulfilment',
          title: 'Fulfilment',
          columnKeys: [_columnKey(6), _columnKey(7), _columnKey(8)],
          collapsedColumnKeys: [_columnKey(7)],
        ),
      ];

  void _toggleColumnGrouping(bool value) {
    setState(() => _enableColumnGrouping = value);
    status.value = value
        ? 'Columns grouped under custom bands from '
            'groupingConfiguration.columns.cellBuilder — tap a band\'s arrow '
            'to collapse it.'
        : 'Column grouping off.';
  }

  void _toggleRowGrouping(bool value) {
    setState(() => _enableRowGrouping = value);
    status.value = value
        ? 'Products grouped by status — the group header, quantity total and '
            'average price are custom cells from groupingConfiguration.rows.cellBuilder.'
        : 'Row grouping off — the plain custom-cell table.';
  }
}

/// Foreground and background colors of a STATUS value — shared by the row
/// cells' status chip and the group headers.
(Color, Color) statusColors(BuildContext context, String status) {
  final colors = context.colors;
  return switch (status) {
    'Available' => (colors.success, colors.successSubtleBg),
    'Out of Stock' => (colors.danger, colors.dangerSubtleBg),
    'Low Stock' => (colors.warning, colors.warningSubtleBg),
    _ => (colors.textSecondary, colors.surfaceSubtle),
  };
}

/// Custom cells for the row-group lines, through
/// [GridSheetRowGroupingConfiguration.cellBuilder]: the header label reuses
/// the STATUS chip look, and the aggregates render as badges. Cells it
/// returns `null` for keep the built-in look.
Widget? buildGroupCell(
    BuildContext context, GridSheetRowGroupCellContext cell) {
  switch (cell.kind) {
    case GridSheetRowGroupCellKind.headerLabel:
      final (Color fg, Color bg) = statusColors(context, cell.label);
      final onSelectionChanged = cell.onSelectionChanged;
      return Row(
        children: [
          const SizedBox(width: 4),
          InkResponse(
            radius: 14,
            onTap: cell.onToggleExpansion,
            child: Icon(
              cell.isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 20,
              color: fg,
            ),
          ),
          if (onSelectionChanged != null)
            Checkbox(
              splashRadius: 0,
              tristate: true,
              value: cell.isSelected,
              shape: CircleBorder(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) => onSelectionChanged(cell.isSelected != true),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: ThemeBorders.roundedMd,
            ),
            child: Text(
              cell.label,
              style: TextTypography.label.copyWith(color: fg),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${cell.count} product${cell.count == 1 ? '' : 's'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextTypography.caption
                  .copyWith(color: context.colors.textSecondary),
            ),
          ),
        ],
      );
    case GridSheetRowGroupCellKind.headerAggregate:
    case GridSheetRowGroupCellKind.summaryAggregate:
      if (cell.aggregates.isEmpty) return const SizedBox.shrink();
      final result = cell.aggregates.first;
      final value = result.value;
      final text = switch (value) {
        null => '–',
        num n when result.spec.aggregator.id == 'avg' =>
          'avg \$${n.toStringAsFixed(2)}',
        num n => 'Σ ${n.round()}',
        _ => '$value',
      };
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: context.colors.surfaceSubtle,
            borderRadius: ThemeBorders.roundedMd,
          ),
          child: Text(text, style: TextTypography.label),
        ),
      );
    default:
      return null;
  }
}

/// Custom column-group bands, through
/// [GridSheetColumnGroupingConfiguration.cellBuilder]: an accent stripe and
/// icon per group, the title, how many columns the band spans, and a
/// collapse button when the group can collapse.
Widget buildColumnGroupBand(
    BuildContext context, GridSheetColumnGroupCellContext band) {
  final accents = context.accents;
  final (Color accent, IconData icon) = switch (band.group.id) {
    'product' => (accents.blue, Icons.inventory_2_outlined),
    'inventory' => (accents.teal, Icons.warehouse_outlined),
    'stock' => (accents.green, Icons.stacked_bar_chart),
    'quality' => (accents.amber, Icons.star_outline),
    _ => (accents.deepPurple, Icons.local_shipping_outlined),
  };
  final onToggle = band.onToggleExpansion;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: accent.withAlpha(28),
      border: BorderDirectional(top: BorderSide(color: accent, width: 3)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            band.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextTypography.label.copyWith(color: accent),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${band.columns.length} col${band.columns.length == 1 ? '' : 's'}',
          style: TextTypography.labelSmall
              .copyWith(color: context.colors.textSecondary),
        ),
        const Spacer(),
        if (onToggle != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            iconSize: 18,
            tooltip: band.isExpanded ? 'Collapse' : 'Expand',
            onPressed: onToggle,
            icon: Icon(
              band.isExpanded ? Icons.unfold_less : Icons.unfold_more,
              color: accent,
            ),
          ),
      ],
    ),
  );
}

class CustomCellsBuilder implements IGridSheetCustomCellBuilder {
  CustomCellsBuilder();

  @override
  Widget buildSelectAll(BuildContext context, GridSheetCellContext cell) {
    final manager = cell.gridManager;
    final visibleRows = manager.config.grid.selectOnlyCurrentPageRows
        ? manager.rows.currentPage
        : manager.rows.filtered;

    final selectedCount = visibleRows.where((row) => row.isSelected).length;
    final allSelected =
        visibleRows.isNotEmpty && selectedCount == visibleRows.length;
    final someSelected = selectedCount > 0 && !allSelected;

    final tooltipMessage =
        allSelected ? 'Deselect all rows' : 'Select all rows';

    return Center(
      child: Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 500),
        child: Checkbox(
          splashRadius: 0,
          value: allSelected ? true : (someSelected ? null : false),
          tristate: true,
          shape: CircleBorder(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (_) => cell.onToggleSelectAllRows?.call(!allSelected),
        ),
      ),
    );
  }

  @override
  Widget buildIndexes(BuildContext context, GridSheetCellContext cell) {
    final value = cell.rowIndex!.toString();
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.bodySmall,
        ),
        Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: cell.gridManager.selection.containsRow(cell.row!.key),
            splashRadius: 0,
            shape: const CircleBorder(),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (checked) {
              if (checked == true) {
                cell.gridManager.selection.selectRows([cell.row!.key]);
              } else {
                cell.gridManager.selection.deselectRows([cell.row!.key]);
              }
            },
          ),
        )
      ],
    );
  }

  @override
  Widget buildHeader(BuildContext context, GridSheetCellContext cell) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            cell.column.title,
            style: theme.textTheme.labelSmall!.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.menu, size: 16),
      ],
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
    } else if (column.name == 'ACTIONS') {
      return SizedBox.shrink();
    } else {
      final theme = Theme.of(context);

      final values = cell.gridManager.rows.all
          .map((row) => row.data[column.index])
          .where((e) => e != null)
          .map((e) => e.toString())
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
            cell.gridManager.filters.add({
              column.key: [value],
            });
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
    switch (column.name) {
      case 'STATUS':
        return _buildStatusChip(
            context, row.data[column.index].toString(), cell);
      case 'SUPPLIER':
        return _buildSupplierChip(context, row.data[column.index].toString());
      case 'CONTACT':
        return _buildContactCell(context, row.data[column.index].toString());
      case 'QUANTITY':
        return _buildQuantityGauge(context, row.data[column.index]);
      case 'PRICE':
        return _buildPriceBadge(context, row.data[column.index]);
      case 'RATING':
        return _buildRatingStars(context, row.data[column.index]);
      case 'PHONES':
        return _ListItemFields(
          key: ValueKey(row.key),
          cell: cell,
          row: row,
          column: column,
          hintPrefix: 'Phone',
        );
      case 'ACTIONS':
        return _buildActionEvents(context, cell, row, column);
    }

    return getCellWidget(cell, context, row, column);
  }

  Widget getCellWidget(
    GridSheetCellContext cell,
    BuildContext context,
    GridSheetRow row,
    GridSheetColumn column,
  ) {
    switch (column.type.kind) {
      case GridSheetColumnKind.boolean:
        return _buildCheckbox(cell, row, column);
      case GridSheetColumnKind.datetime:
        return _buildDateCell(context, cell, row, column);
      default:
        return _buildTextCell(context, cell, row, column);
    }
  }

  Widget _buildCheckbox(
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn col,
  ) {
    return Center(
      child: Transform.scale(
        scale: 0.8,
        child: Checkbox(
          splashRadius: 0,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          value: row.data[col.index] == true,
          onChanged: (value) {
            final newValue = value ?? false;
            cell.gridManager.cells.update(
              rowKey: row.key,
              columnKey: col.key,
              value: newValue,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextCell(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn col,
  ) {
    return _buildTextFieldWidget(context, cell, row, col);
  }

  Widget _buildDateCell(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn col,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        InkWell(
          child: const Icon(Icons.calendar_month_rounded, size: 20),
          onTap: () {
            final pickedDate = showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            pickedDate.then((value) {
              if (value == null) return;
              final formattedDate =
                  '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
              cell.gridManager.cells.update(
                rowKey: row.key,
                columnKey: col.key,
                value: formattedDate,
              );
            });
          },
        ),
        Expanded(child: _buildTextCell(context, cell, row, col)),
      ],
    );
  }

  Widget _buildTextFieldWidget(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn col,
  ) {
    final theme = Theme.of(context);
    final manager = cell.gridManager;
    final rowKey = row.key;
    final initialText = row.data[col.index]?.toString() ?? '';

    final controller = manager.cells.controller(
      rowKey: rowKey,
      columnKey: col.key,
      initialText: initialText,
    );

    if (controller == null) {
      return _buildTextWidget(context, cell, row, col);
    }

    // IMPORTANT: keep controller aligned with model (same pattern as default cell).
    if (controller.text != initialText) {
      controller.text = initialText;
    }

    final styleConfiguration = cell.gridManager.config.style;

    return TextField(
      controller: controller,
      textAlign: col.textAlign,
      style: cell.textStyle ?? theme.textTheme.bodySmall,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        filled: false,
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: styleConfiguration.rowBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: styleConfiguration.rowBorderColor, width: 1),
        ),
        border: OutlineInputBorder(
          borderSide:
              BorderSide(color: styleConfiguration.rowBorderColor, width: 1),
        ),
      ),
      onChanged: (value) {
        // Keep row.data in sync via manager so grid state updates correctly.
        cell.gridManager.cells.update(
          rowKey: row.key,
          columnKey: col.key,
          value: value,
        );
      },
    );
  }

  Widget _buildTextWidget(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn col,
  ) {
    final theme = Theme.of(context);

    return Align(
      alignment: col.textAlign == TextAlign.right
          ? Alignment.centerRight
          : col.textAlign == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft,
      child: Text(
        row.data[col.index].toString(),
        overflow: TextOverflow.ellipsis,
        style: cell.textStyle ?? theme.textTheme.bodySmall,
        textAlign: col.textAlign,
      ),
    );
  }

  Widget _buildStatusChip(
      BuildContext context, String status, GridSheetCellContext cell) {
    final (Color fg, Color bg) = statusColors(context, status);

    return SizedBox(
      height: 24,
      width: cell.column.width - 4,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: ThemeBorders.roundedMd,
        ),
        child: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextTypography.label.copyWith(color: fg),
        ),
      ),
    );
  }

  /// Initials-avatar "assignee chip" — a distinct accent color per supplier
  /// (stable across rebuilds via `supplier.hashCode`) so the column reads at
  /// a glance without needing a legend.
  Widget _buildSupplierChip(BuildContext context, String supplier) {
    final colors = context.colors;
    final accents = context.accents;
    final palette = [
      accents.blue,
      accents.teal,
      accents.purple,
      accents.pink,
      accents.deepPurple,
      accents.orange,
      accents.brown,
      accents.indigo,
    ];
    final color = palette[supplier.hashCode.abs() % palette.length];
    final initials = supplier
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withValues(alpha: 0.16),
          child: Text(
            initials,
            style: TextTypography.labelSmall.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            supplier,
            overflow: TextOverflow.ellipsis,
            style: TextTypography.body.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCell(BuildContext context, String rawValue) {
    final colors = context.colors;
    final parts = rawValue.split('|');
    final name = parts.isNotEmpty ? parts[0] : '';
    final email = parts.length > 1 ? parts[1] : '';

    return Padding(
      padding: EdgeInsets.only(left: 2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextTypography.label.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 1),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextTypography.labelSmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Stock-level gauge — a mini filled bar under the raw count, color-coded
  /// with the same success/warning/danger thresholds as the STATUS chip, so
  /// the two columns visibly agree with each other.
  Widget _buildQuantityGauge(BuildContext context, dynamic rawValue) {
    final colors = context.colors;
    final quantity = num.tryParse(rawValue.toString())?.toInt() ?? 0;
    const scaleMax = 250;
    final fraction = (quantity / scaleMax).clamp(0.0, 1.0);
    final color = quantity == 0
        ? colors.danger
        : quantity < 10
            ? colors.warning
            : colors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$quantity',
              style: TextTypography.bodyStrong.copyWith(color: color)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: ThemeBorders.roundedXs,
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(color: colors.border),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Price badge — a bordered pill with a tag icon, distinguishing a
  /// currency value from a plain numeric column at a glance.
  Widget _buildPriceBadge(BuildContext context, dynamic rawValue) {
    final colors = context.colors;
    final price = num.tryParse(rawValue.toString())?.toDouble() ?? 0.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: ThemeBorders.roundedSm,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sell_outlined, size: 12, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style:
                  TextTypography.bodyStrong.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  /// Star rating — five icons, filled up to [rawValue] (clamped to 0-5),
  /// the same at-a-glance pattern as the STOCK gauge and STATUS chip but
  /// for a bounded 1-5 scale rather than an open-ended count or enum.
  Widget _buildRatingStars(BuildContext context, dynamic rawValue) {
    final colors = context.colors;
    final accents = context.accents;
    final rating =
        (num.tryParse(rawValue.toString())?.toInt() ?? 0).clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: i <= rating ? accents.amber : colors.border,
          ),
      ],
    );
  }

  /// Insert/edit/delete icons for a row.
  ///
  /// When [GridSheetConfiguration.enableRowHover] is off, the icons are
  /// always shown (there's no hover state to key off of). When it's on,
  /// they're hidden by default and only appear while that row is hovered —
  /// demonstrates [GridSheetManager.isRowHovered].
  Widget _buildActionEvents(BuildContext context, GridSheetCellContext cell,
      GridSheetRow row, GridSheetColumn col) {
    final manager = cell.gridManager;
    final hoverGatingEnabled = manager.config.grid.enableRowHover;
    final isHovered = manager.cursor.isRowHovered(row.key);
    if (hoverGatingEnabled && !isHovered) {
      return const SizedBox.shrink();
    }

    final accents = context.accents;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        InkWell(
          child: Icon(Icons.add, color: accents.blue, size: 20),
          onTap: () {
            debugPrint('insert => ${row.data}');
          },
        ),
        InkWell(
          child: Icon(Icons.edit, color: accents.amber, size: 18),
          onTap: () {
            debugPrint('edit => ${row.data}');
          },
        ),
        InkWell(
          child: Icon(Icons.delete, color: accents.red, size: 18),
          onTap: () {
            debugPrint('delete => ${row.data}');
          },
        ),
      ],
    );
  }
}

/// A list cell built entirely by the host: the PHONES column stores a
/// fixed-size list (3 items, e.g. `['+91 98480 12345', null, null]`) and
/// shows one text field per item, side by side. Widen the column to give
/// the fields more room.
///
/// The whole list is one cell (one row key + column key); its items have no
/// keys of their own. Each edit writes a *new* list through
/// `gridManager.cells.update` rather than changing the stored list in place,
/// so the grid sees the change: the row is marked modified,
/// `onCellValueChanged` fires with the old and new lists, and undo can
/// restore the old one. The stored list is what the grid exports
/// (`gridManager.data.toMap` gives `'PHONES': [..., ..., ...]`).
///
/// The grid's text-based bulk operations don't know about the list: copy
/// writes its `toString()`, while paste, `cells.findAndReplace` and
/// `cells.clear` store a `String` in its place. This widget treats any
/// non-list value as empty fields.
class _ListItemFields extends StatefulWidget {
  const _ListItemFields({
    super.key,
    required this.cell,
    required this.row,
    required this.column,
    required this.hintPrefix,
  });

  static const int size = 3;

  final GridSheetCellContext cell;
  final GridSheetRow row;
  final GridSheetColumn column;
  final String hintPrefix;

  @override
  State<_ListItemFields> createState() => _ListItemFieldsState();
}

class _ListItemFieldsState extends State<_ListItemFields> {
  late final List<TextEditingController> _controllers = [
    for (var i = 0; i < _ListItemFields.size; i++)
      TextEditingController(text: _storedText(i)),
  ];

  String _storedText(int i) {
    final value = widget.row.data[widget.column.index];
    if (value is! List || i >= value.length) return '';
    return value[i]?.toString() ?? '';
  }

  @override
  void didUpdateWidget(covariant _ListItemFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pick up changes made elsewhere (undo, updateCellValue from the host).
    // After this widget's own edit the stored text already matches, so the
    // field being typed in is left alone.
    for (var i = 0; i < _controllers.length; i++) {
      final text = _storedText(i);
      if (_controllers[i].text != text) _controllers[i].text = text;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.cell.gridManager.cells.update(
      rowKey: widget.row.key,
      columnKey: widget.column.key,
      // A new list every time; an empty field is stored as null.
      value: [
        for (final controller in _controllers)
          controller.text.isEmpty ? null : controller.text,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderSide: BorderSide(
        color: widget.cell.gridManager.config.style.rowBorderColor,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        spacing: 6,
        children: [
          for (var i = 0; i < _controllers.length; i++)
            Expanded(
              child: TextField(
                controller: _controllers[i],
                keyboardType: TextInputType.phone,
                style: widget.cell.textStyle ?? theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '${widget.hintPrefix} ${i + 1}',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  enabledBorder: border,
                  focusedBorder: border,
                  border: border,
                ),
                onChanged: (_) => _save(),
              ),
            ),
        ],
      ),
    );
  }
}
