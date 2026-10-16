import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

void main() {
  runApp(const GridSheetApp());
}

class GridSheetApp extends StatefulWidget {
  const GridSheetApp({super.key});

  @override
  State<GridSheetApp> createState() => _GridSheetAppState();
}

class _GridSheetAppState extends State<GridSheetApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridSheet Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          sizeConstraints: BoxConstraints.tightFor(
            width: 44,
            height: 44,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          sizeConstraints: BoxConstraints.tightFor(
            width: 44,
            height: 44,
          ),
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleTheme,
          tooltip: _themeMode == ThemeMode.light
              ? 'Switch to dark mode'
              : 'Switch to light mode',
          child: Icon(
            _themeMode == ThemeMode.light
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
          ),
        ),
        body: const GridSheetExample(),
      ),
    );
  }
}

class GridSheetExample extends StatefulWidget {
  const GridSheetExample({super.key});

  @override
  State<GridSheetExample> createState() => _GridSheetExampleState();
}

class _GridSheetExampleState extends State<GridSheetExample> {
  final CellBuilder _cellBuilder = const CellBuilder();

  @override
  Widget build(BuildContext context) {
    final styleConfiguration = _buildStyleConfiguration(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: GridSheet(
          columns: _columns(),
          rows: _rows(),
          configuration: GridSheetConfiguration(
            enableRowSelectionOnFirstColumnTap: true,
            enableMultiSelection: true,
            showColumnBorders: false,
            enableRowReorder: true,
            enableRowResize: true,
          ),
          styleConfiguration: styleConfiguration,
          scrollConfiguration: GridSheetScrollBarConfiguration(
            verticalScrollbarPlacement:
                GridSheetVerticalScrollbarPlacement.overlay,
          ),
          onLoaded: (event) {
            log('Table initialized!', name: 'GridSheetExample');
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
                return null;
              case GridSheetCellKind.row:
                final row = cell.row!;
                final column = cell.column;
                return _cellBuilder.buildCell(context, column, row, cell);
            }
          },
        ),
      ),
    );
  }

  GridSheetStyleConfiguration _buildStyleConfiguration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridSheetStyleConfiguration(
      gridBackgroundColor: colorScheme.surfaceContainerLowest,
      headerColor: colorScheme.surfaceContainerLowest,
      filterColor: colorScheme.surfaceContainerLowest,
      rowColor: colorScheme.surfaceContainerLowest,
      selectionColor: colorScheme.primary,
      gridBorderColor: Colors.transparent,
      rowBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
      columnBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
      headerRowBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  List<GridSheetColumn> _columns() {
    const titles = [
      'ID',
      'Product',
      'Supplier',
      'Contact',
      'Quantity',
      'Price',
      'Rating',
      'In Stock',
      'Status',
      'Actions',
    ];
    const names = [
      'PRODUCT_ID',
      'PRODUCT',
      'SUPPLIER',
      'CONTACT',
      'QUANTITY',
      'PRICE',
      'RATING',
      'IN_STOCK',
      'STATUS',
      'ACTIONS',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.double(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.boolean(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
    ];
    const widths = [
      80.0,
      170.0,
      160.0,
      210.0,
      100.0,
      100.0,
      120.0,
      100.0,
      112.0,
      120.0,
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
        editable: names[i] == 'QUANTITY' || names[i] == 'IN_STOCK',
        textAlign: types[i].kind == GridSheetColumnKind.double ||
                types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
        index: i,
        sortable: true,
        pinnedRight: names[i] == 'ACTIONS',
        hasTextController: names[i] == 'QUANTITY',
      );
    });
  }

  List<GridSheetRow> _rows() {
    final rows = [
      [
        'P101',
        'Office Chair',
        'ErgoDesk Co.',
        'Maria Chen|maria.chen@ergodesk.com',
        25,
        149.99,
        4,
        true,
        'Available',
        '',
      ],
      [
        'P102',
        'LED Monitor 27"',
        'ViewTech',
        'James Patel|james.patel@viewtech.io',
        12,
        299.50,
        5,
        true,
        'Available',
        '',
      ],
      [
        'P103',
        'Notebook Pack (12)',
        'Moleskine',
        'Sofia Rossi|sofia.rossi@moleskine.com',
        200,
        2.50,
        4,
        true,
        'Available',
        '',
      ],
      [
        'P104',
        'Desk Lamp',
        'Ikea',
        'Lars Andersson|lars.andersson@ikea.com',
        0,
        49.99,
        3,
        false,
        'Out of Stock',
        '',
      ],
      [
        'P105',
        'Bookshelf',
        'Herman Miller',
        'Emily Carter|emily.carter@hermanmiller.com',
        8,
        199.00,
        5,
        true,
        'Low Stock',
        '',
      ],
      [
        'P106',
        'Pen Set (10ct)',
        'Pilot',
        'Kenji Sato|kenji.sato@pilotpen.com',
        500,
        5.99,
        4,
        true,
        'Available',
        '',
      ],
      [
        'P107',
        'Laptop Stand',
        'Twelve South',
        'Ava Thompson|ava.thompsons@twelvesouth.com',
        6,
        45.00,
        5,
        true,
        'Low Stock',
        '',
      ],
      [
        'P108',
        'Whiteboard 4x3',
        'Quartet',
        'Daniel Kim|daniel.kim@quartet.com',
        0,
        89.99,
        3,
        false,
        'Out of Stock',
        '',
      ],

      // Additional records
      [
        'P109',
        'Wireless Keyboard',
        'Logitech',
        'Olivia Brown|olivia.brown@logitech.com',
        34,
        79.99,
        5,
        true,
        'Available',
        '',
      ],
      [
        'P110',
        'USB-C Docking Station',
        'Anker',
        'Noah Williams|noah.williams@anker.com',
        9,
        129.00,
        4,
        true,
        'Low Stock',
        '',
      ],
      [
        'P111',
        'Ergonomic Mouse',
        'Microsoft',
        'Emma Wilson|emma.wilson@microsoft.com',
        47,
        59.99,
        4,
        true,
        'Available',
        '',
      ],
      [
        'P112',
        'Standing Desk',
        'FlexiSpot',
        'Liam Anderson|liam.anderson@flexispot.com',
        4,
        449.00,
        5,
        true,
        'Low Stock',
        '',
      ],
      [
        'P113',
        'Webcam Full HD',
        'Logitech',
        'Charlotte Martin|charlotte.martin@logitech.com',
        18,
        69.99,
        4,
        true,
        'Available',
        '',
      ],
      [
        'P114',
        'Filing Cabinet',
        'Steelcase',
        'Ethan Davis|ethan.davis@steelcase.com',
        0,
        179.00,
        4,
        false,
        'Out of Stock',
        '',
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
        height: 40,
      );

      return row;
    }).toList();
  }
}

class CellBuilder implements IGridSheetCustomCellBuilder {
  const CellBuilder();

  static const _idColumn = 'PRODUCT_ID';
  static const _statusColumn = 'STATUS';
  static const _supplierColumn = 'SUPPLIER';
  static const _contactColumn = 'CONTACT';
  static const _priceColumn = 'PRICE';
  static const _ratingColumn = 'RATING';
  static const _actionsColumn = 'ACTIONS';

  @override
  Widget buildSelectAll(BuildContext context, GridSheetCellContext cell) {
    final gridManager = cell.gridManager;
    final visibleRows = gridManager.config.grid.selectOnlyCurrentPageRows
        ? gridManager.rows.currentPage
        : gridManager.rows.filtered;

    final selectedRowCount = visibleRows.where((row) => row.isSelected).length;
    final allRowsSelected =
        visibleRows.isNotEmpty && selectedRowCount == visibleRows.length;
    final someRowsSelected = selectedRowCount > 0 && !allRowsSelected;

    return Center(
      child: Tooltip(
        message: allRowsSelected ? 'Deselect all rows' : 'Select all rows',
        waitDuration: const Duration(milliseconds: 500),
        child: Transform.scale(
          scale: 0.9,
          child: Checkbox(
            tristate: true,
            value: allRowsSelected ? true : (someRowsSelected ? null : false),
            splashRadius: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (_) =>
                cell.onToggleSelectAllRows?.call(!allRowsSelected),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildIndexes(BuildContext context, GridSheetCellContext cell) {
    final rowNumber = cell.rowIndex!.toString();
    final bodySmallStyle = Theme.of(context).textTheme.bodySmall;
    final isRowSelected = cell.gridManager.selection.containsRow(cell.row!.key);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(rowNumber, style: bodySmallStyle),
        Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: isRowSelected,
            splashRadius: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (checked) {
              final rowKey = cell.row!.key;
              if (checked == true) {
                cell.gridManager.selection.selectRows([rowKey]);
              } else {
                cell.gridManager.selection.deselectRows([rowKey]);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget buildHeader(BuildContext context, GridSheetCellContext cell) {
    final labelStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        );

    return Text(
      cell.column.title,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: labelStyle,
    );
  }

  @override
  Widget buildFilter(
    BuildContext context,
    GridSheetColumn column,
    GridSheetCellContext cell,
  ) {
    // Filtering is not offered for any column in this grid.
    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------
  // Cell dispatch: route each column to either a bespoke widget or the
  // generic renderer for its data type.
  // ---------------------------------------------------------------------

  @override
  Widget buildCell(
    BuildContext context,
    GridSheetColumn column,
    GridSheetRow row,
    GridSheetCellContext cell,
  ) {
    final rawValue = row.data[column.index];

    switch (column.name) {
      case _statusColumn:
        return _buildStatusChip(context, rawValue.toString(), cell);
      case _supplierColumn:
        return _buildSupplierChip(context, rawValue.toString());
      case _contactColumn:
        return _buildContactCell(context, rawValue.toString());
      case _priceColumn:
        return _buildPriceBadge(context, rawValue);
      case _ratingColumn:
        return _buildRatingStars(rawValue);
      case _actionsColumn:
        return _buildActionIcons(row);
      default:
        return _buildGenericCell(context, cell, row, column);
    }
  }

  /// Renders a cell based on its column's data type when no bespoke
  /// widget is registered for that column in [buildCell].
  Widget _buildGenericCell(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn column,
  ) {
    switch (column.type.kind) {
      case GridSheetColumnKind.boolean:
        return _buildCheckboxCell(cell, row, column);
      default:
        return _buildTextCell(context, cell, row, column);
    }
  }

  // ---------------------------------------------------------------------
  // Generic cell renderers, grouped by [GridSheetColumnType].
  // ---------------------------------------------------------------------

  Widget _buildCheckboxCell(
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn column,
  ) {
    final isChecked = row.data[column.index] == true;

    return Center(
      child: Transform.scale(
        scale: 0.8,
        child: Checkbox(
          value: isChecked,
          shape: const CircleBorder(),
          splashRadius: 0,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onChanged: (checked) {
            cell.gridManager.cells.update(
              rowKey: row.key,
              columnKey: column.key,
              value: checked ?? false,
            );
          },
        ),
      ),
    );
  }

  /// Editable columns get a live-editing [TextField]; everything else
  /// falls back to [_buildTextWidget] for a plain, read-only label.
  Widget _buildTextCell(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn column,
  ) {
    if (!column.editable || !column.hasTextController) {
      return _buildTextWidget(context, cell, row, column);
    }
    return _buildEditableTextField(context, cell, row, column);
  }

  Widget _buildEditableTextField(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn column,
  ) {
    final gridManager = cell.gridManager;
    final currentValue = row.data[column.index]?.toString() ?? '';

    final controller = gridManager.cells.controller(
      rowKey: row.key,
      columnKey: column.key,
      initialText: currentValue,
    );
    if (controller == null) {
      return _buildTextWidget(context, cell, row, column);
    }

    // Keep the controller in sync if the underlying model value changed
    // without going through this text field (e.g. an external update).
    if (controller.text != currentValue) {
      controller.text = currentValue;
    }

    final borderColor = gridManager.config.style.rowBorderColor;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
    );

    return TextField(
      controller: controller,
      textAlign: column.textAlign,
      style: cell.textStyle ?? Theme.of(context).textTheme.bodySmall,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        filled: false,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
      onChanged: (value) {
        cell.gridManager.cells.update(
          rowKey: row.key,
          columnKey: column.key,
          value: value,
        );
      },
    );
  }

  Widget _buildTextWidget(
    BuildContext context,
    GridSheetCellContext cell,
    GridSheetRow row,
    GridSheetColumn column,
  ) {
    final alignment = switch (column.textAlign) {
      TextAlign.right => Alignment.centerRight,
      TextAlign.center => Alignment.center,
      _ => Alignment.centerLeft,
    };

    final style = cell.textStyle ?? Theme.of(context).textTheme.bodySmall;

    return Align(
      alignment: alignment,
      child: Text(
        row.data[column.index].toString(),
        overflow: TextOverflow.ellipsis,
        textAlign: column.textAlign,
        style: style!.copyWith(
          fontWeight:
              column.name == _idColumn ? FontWeight.w600 : style.fontWeight,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Bespoke column widgets.
  // ---------------------------------------------------------------------

  /// A pill-shaped status indicator with a colored dot, e.g. "Available"
  /// (green), "Low Stock" (amber), "Out of Stock" (red).
  Widget _buildStatusChip(
    BuildContext context,
    String status,
    GridSheetCellContext cell,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final (Color dotAndTextColor, Color backgroundColor) = switch (status) {
      'Available' => isDarkMode
          ? (const Color(0xFF4ADE80), const Color(0xFF14311F))
          : (const Color(0xFF15803D), const Color(0xFFDCFCE7)),
      'Out of Stock' => isDarkMode
          ? (const Color(0xFFF87171), const Color(0xFF3A1717))
          : (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      'Low Stock' => isDarkMode
          ? (const Color(0xFFFBBF24), const Color(0xFF3A2E10))
          : (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      _ => (colorScheme.onSurfaceVariant, colorScheme.surfaceContainerHighest),
    };

    return SizedBox(
      height: 24,
      width: cell.column.width - 4,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            spacing: 4,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotAndTextColor,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dotAndTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// An initials avatar next to the supplier's name. Each supplier gets a
  /// stable accent color derived from `supplier.hashCode`, so the column
  /// reads at a glance without needing a legend.
  Widget _buildSupplierChip(BuildContext context, String supplier) {
    const accentPalette = [
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.deepPurple,
      Colors.orange,
      Colors.brown,
      Colors.indigo,
    ];
    final accentColor =
        accentPalette[supplier.hashCode.abs() % accentPalette.length];
    final initials = _initialsFor(supplier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: accentColor.withValues(alpha: 0.16),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              height: 1.2,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            supplier,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// Up to two uppercase initials from a name, e.g. "Jane Doe" -> "JD".
  String _initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  /// A contact's name and email, stacked. The two are stored together in
  /// the cell value as `"name|email"`.
  Widget _buildContactCell(BuildContext context, String rawValue) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = rawValue.split('|');
    final name = parts.isNotEmpty ? parts[0] : '';
    final email = parts.length > 1 ? parts[1] : '';

    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              height: 1.2,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
              height: 1.2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// A bordered pill showing a dollar amount, distinguishing a currency
  /// value from a plain number at a glance.
  Widget _buildPriceBadge(BuildContext context, Object? rawValue) {
    final colorScheme = Theme.of(context).colorScheme;
    final price = num.tryParse(rawValue.toString())?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            price.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Five star icons, filled up to the rating (clamped to 0-5).
  Widget _buildRatingStars(Object? rawValue) {
    final rating =
        (num.tryParse(rawValue.toString())?.toInt() ?? 0).clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Icon(
            star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
          ),
      ],
    );
  }

  /// View, delete, and edit icon buttons for a row.
  ///
  /// These currently only log to the console; wire [onTap] up to your own
  /// view/delete/edit handlers to make them functional.
  Widget _buildActionIcons(GridSheetRow row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        InkWell(
          onTap: () => debugPrint('view => ${row.data}'),
          child: const Icon(Icons.remove_red_eye_outlined, size: 18),
        ),
        InkWell(
          onTap: () => debugPrint('delete => ${row.data}'),
          child: const Icon(Icons.delete_outline, size: 18),
        ),
        InkWell(
          onTap: () => debugPrint('edit => ${row.data}'),
          child: const Icon(Icons.edit_outlined, size: 18),
        ),
      ],
    );
  }
}
