import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class CustomWrappers extends StatefulWidget {
  const CustomWrappers({super.key});

  @override
  State<CustomWrappers> createState() => _CustomWrappersState();
}

class _CustomWrappersState extends State<CustomWrappers> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'headerWrapper, filterWrapper and rowWrapper decorate each section with a floating card — '
    'no cell content was touched to achieve this look.',
  );

  // Wrappers need matching horizontal padding on the style configuration
  // to avoid clipping/overflow, per the package README.
  static const double _leftPadding = 8;
  static const double _rightPadding = 8;

  bool _headerWrapperEnabled = true;
  bool _filterWrapperEnabled = true;
  bool _rowWrapperEnabled = true;

  /// Draws a dotted separator under each wrapped row with
  /// GridSheetDashedBorder, the way a host would use it in any decoration.
  bool _dottedRows = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FeaturePageTemplate(
      title: 'Custom Wrappers',
      description:
          'headerWrapper, filterWrapper and rowWrapper let you wrap each section in its own container — cards, '
          'borders, shadows, rounded corners — while leaving the underlying cell widgets completely untouched. '
          'Dotted shows GridSheetDashedBorder, a dotted/dashed border usable in any BoxDecoration.',
      icon: Icons.dashboard_customize_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Header',
            icon: Icons.view_headline,
            color: context.accents.indigo,
            value: _headerWrapperEnabled,
            onChanged: _toggleHeaderWrapper,
            tooltip: 'Wrap the header section in a floating card',
          ),
          DemoToggleButton(
            label: 'Filter',
            icon: Icons.filter_list_outlined,
            color: context.accents.teal,
            value: _filterWrapperEnabled,
            onChanged: _toggleFilterWrapper,
            tooltip: 'Wrap the filter row in a floating card',
          ),
          DemoToggleButton(
            label: 'Row',
            icon: Icons.table_rows_outlined,
            color: context.accents.deepPurple,
            value: _rowWrapperEnabled,
            onChanged: _toggleRowWrapper,
            tooltip: 'Wrap each data row in a floating card',
          ),
          DemoToggleButton(
            label: 'Dotted',
            icon: Icons.more_horiz,
            color: context.accents.orange,
            value: _dottedRows,
            onChanged: _toggleDottedRows,
            tooltip: 'Dotted separator under each row (GridSheetDashedBorder, '
                'used inside the row wrapper)',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(
          enableCellSelection: true,
          showColumnFilters: true,
          showColumnBorders: false,
          showRowBorders: false,
          filterHeight: 40,
          enableRowHover: true,
          enableRowSelectionOnFirstColumnTap: true,
        ),
        styleConfiguration: GridSheetStyleConfiguration(
          gridBackgroundColor: colorScheme.surfaceContainerLow,
          headerColor: Colors.green[300]!,
          filterColor: Colors.grey[300]!,
          rowColor: colorScheme.surface,
          evenRowColor: colorScheme.surface,
          oddRowColor: colorScheme.surface,
          selectionColor: Colors.transparent,
          gridBorderColor: Colors.transparent,
          rowBorderColor: colorScheme.outlineVariant,
          columnBorderColor: colorScheme.outlineVariant,
          gridBorderRadius: ThemeBorders.roundedMd,
          headerTextStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: colorScheme.primary,
          ),
          // Horizontal padding is required whenever wrappers are supplied,
          // otherwise the wrapped cards clip against the grid edges.
          leftPadding: _leftPadding,
          rightPadding: _rightPadding,
        ),
        scrollConfiguration: scrollConfig(context),
        headerWrapper: !_headerWrapperEnabled
            ? null
            : (context, child, details) {
                final isPinnedLeft = details.pinnedLeft;
                return Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    left: isPinnedLeft ? _leftPadding : 0,
                    right: isPinnedLeft ? 0 : _rightPadding,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: isPinnedLeft
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                    ),
                    child: ClipRRect(
                      borderRadius: isPinnedLeft
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                      child: child,
                    ),
                  ),
                );
              },
        filterWrapper: !_filterWrapperEnabled
            ? null
            : (context, child, details) {
                final isPinnedLeft = details.pinnedLeft;
                return Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    left: isPinnedLeft ? _leftPadding : 0,
                    right: isPinnedLeft ? 0 : _rightPadding,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: isPinnedLeft
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                    ),
                    child: ClipRRect(
                      borderRadius: isPinnedLeft
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                      child: child,
                    ),
                  ),
                );
              },
        rowWrapper: !_rowWrapperEnabled
            ? null
            : (context, child, details) {
                final isPinnedLeft = details.pinnedLeft;
                final isHovered = details.hovered;
                final isSelected = details.selected;
                final isActive = isHovered || isSelected;

                return Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    left: isPinnedLeft ? _leftPadding : 0,
                    right: isPinnedLeft ? 0 : _rightPadding,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE8F0FE)
                          : isHovered
                              ? const Color(0xFFF5F7F7)
                              : Colors.transparent,
                      // GridSheetDashedBorder works anywhere a Border does.
                      border: _dottedRows
                          ? GridSheetDashedBorder.dotted(
                              bottom: BorderSide(
                                color: colorScheme.outline,
                                width: 1.5,
                              ),
                              spacing: 3,
                            )
                          : null,
                      borderRadius: isPinnedLeft
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                      boxShadow: isActive
                          ? [
                              if (isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.50),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              else
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: isPinnedLeft
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                      child: child,
                    ),
                  ),
                );
              },
        onLoaded: (event) => gridManager = event.gridManager,
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['PROJECT', 'OWNER', 'STATUS', 'PROGRESS'];
    const titles = ['Project', 'Owner', 'Status', 'Progress %'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(options: ['On Track', 'At Risk', 'Blocked', 'Done']),
      GridSheetColumnType.integer(),
    ];
    const widths = [170.0, 170.0, 170.0, 170.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        hasTextController: types[i].kind == GridSheetColumnKind.text,
        textAlign: types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
        sortable: true,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Website Redesign', 'Ava Thompson', 'On Track', 72],
      ['Mobile App v2', 'Liam Chen', 'At Risk', 48],
      ['API Migration', 'Noah Patel', 'Blocked', 20],
      ['Data Warehouse', 'Maya Rodriguez', 'On Track', 90],
      ['Design System', 'Ethan Kim', 'Done', 100],
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

  void _toggleHeaderWrapper(bool value) {
    setState(() => _headerWrapperEnabled = value);
    status.value = value
        ? 'headerWrapper ON — the header section is wrapped in a floating card again.'
        : 'headerWrapper OFF — null, back to the built-in header look.';
  }

  void _toggleFilterWrapper(bool value) {
    setState(() => _filterWrapperEnabled = value);
    status.value = value
        ? 'filterWrapper ON — the filter row is wrapped in a floating card again.'
        : 'filterWrapper OFF — null, back to the built-in filter row look.';
  }

  void _toggleRowWrapper(bool value) {
    setState(() {
      _rowWrapperEnabled = value;
      // The dotted line is drawn by the row wrapper, so it goes with it.
      if (!value) _dottedRows = false;
    });
    status.value = value
        ? 'rowWrapper ON — each data row is wrapped in a floating card again.'
        : 'rowWrapper OFF — null, back to the built-in row look.';
  }

  void _toggleDottedRows(bool value) {
    setState(() {
      _dottedRows = value;
      // The dotted line is drawn by the row wrapper.
      if (value) _rowWrapperEnabled = true;
    });
    status.value = value
        ? 'Dotted rows: GridSheetDashedBorder.dotted(bottom: ...) in the '
            'BoxDecoration of the row wrapper.'
        : 'Dotted rows off.';
  }
}
