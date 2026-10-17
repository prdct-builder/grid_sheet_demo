import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';
import 'package:grid_sheet_demo/design_system/table_shimmer.dart';

class GridSheetShimmer extends StatefulWidget {
  const GridSheetShimmer({super.key});

  @override
  State<GridSheetShimmer> createState() => _GridSheetShimmerState();
}

class _GridSheetShimmerState extends State<GridSheetShimmer> {
  final int _columnsCount = 8;
  final int _rowsCount = 8;

  // Shows the shimmer (via emptyRowsPlaceholder, since rowsCount: 0 keeps the
  // generated columns/headers but produces zero rows) for the first 5
  // seconds, then switches to the real generated rows.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final styleConfiguration = _buildStyleConfig(context);

    return RepaintBoundary(
      child: Column(
        children: [
          Expanded(
            child: GridSheet(
              // dynamicGenerationConfiguration is captured once at initState
              // and never resynced on rebuild (see GridSheet's own
              // _syncConfigsOnRebuild dartdoc) — a distinct key per loading
              // phase forces a fresh GridSheet element, and with it a fresh
              // initState read of the now-real rowsCount, once _loading
              // flips.
              key: ValueKey(_loading ? 'shimmer-loading' : 'shimmer-loaded'),
              columns: [],
              rows: [],
              dynamicGenerationConfiguration:
                  GridSheetDynamicGenerationConfiguration(
                columnsCount: _columnsCount,
                rowsCount: _loading ? 0 : _rowsCount,
              ),
              configuration: GridSheetConfiguration(
                showColumnFilters: true,
              ),
              styleConfiguration: styleConfiguration,
              emptyRowsPlaceholder: TableShimmerPresets.themed(
                context: context,
                showHeader: false,
                showFooter: false,
                // +1 for the serial-number column generateWidths adds up
                // front — colsCount must match colWidths.length, or the
                // last data column silently gets no shimmer cell at all.
                colsCount: _columnsCount + 1,
                colWidths: generateWidths(_columnsCount),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<double> generateWidths(int count) {
    if (count <= 0) return [];

    return [
      60.0, // serial number col
      ...List.filled(count, 120.0),
    ];
  }

  GridSheetStyleConfiguration _buildStyleConfig(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridSheetStyleConfiguration(
      gridBorderRadius: BorderRadiusGeometry.circular(4),
      gridBackgroundColor: colorScheme.surface,
      headerColor: colorScheme.surfaceContainerHighest,
      filterColor: colorScheme.surfaceContainerHighest,
      rowColor: colorScheme.surface,
      evenRowColor: isDark
          ? colorScheme.surfaceContainerLow
          : colorScheme.surfaceContainerLowest,
      oddRowColor: colorScheme.surface,
      selectionColor: colorScheme.primary,
      gridBorderColor: colorScheme.outlineVariant,
      rowBorderColor: colorScheme.outlineVariant,
      columnBorderColor: colorScheme.outlineVariant,
      headerRowBorderColor: colorScheme.outlineVariant,
      filterRowBorderColor: colorScheme.outlineVariant,
      cellTextFieldBorderColor: colorScheme.outlineVariant,
    );
  }
}
