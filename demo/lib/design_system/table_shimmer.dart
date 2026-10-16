import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'theme_properties.dart';

/* @Developed By Mazhar
    => A responsive table shimmer widget that fills the entire screen
       Automatically calculates rows and columns based on available space */
class TableShimmer extends StatefulWidget {
  final bool showHeader;
  final bool showFooter;
  final double minRowHeight;
  final double minColumnWidth;
  final double headerHeight;
  final double footerHeight;
  final double columnSpacing;
  final double rowSpacing;
  final Color baseColor;
  final Color highlightColor;
  final Duration animationDuration;
  final int count;
  final List<double> columnWidths;

  const TableShimmer({
    super.key,
    this.count = 0,
    this.showHeader = true,
    this.showFooter = true,
    this.headerHeight = 40.0,
    this.minRowHeight = 25.0,
    this.footerHeight = 32.0,
    this.minColumnWidth = 60.0,
    this.columnSpacing = 4.0,
    this.rowSpacing = 4.0,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.animationDuration = const Duration(milliseconds: 1500),
    this.columnWidths = const [],
  });

  @override
  State<TableShimmer> createState() => _TableShimmerState();
}

class _TableShimmerState extends State<TableShimmer>
    with SingleTickerProviderStateMixin {
  bool isTableRows = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Map<String, dynamic> drilldownsConfiguration;
  late bool isWorksheet = false;

  final double _horSpacing = 4;

  @override
  void initState() {
    super.initState();
    isTableRows = widget.count > 0 && !widget.showHeader && !widget.showFooter;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0 + 2.0 * _animationController.value,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isTableRows = widget.count > 0 && !widget.showHeader && !widget.showFooter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = isTableRows ? EdgeInsets.zero : EdgeInsets.all(4);
        final availableWidth = constraints.maxWidth - padding.horizontal;
        final availableHeight = constraints.maxHeight - padding.vertical;

        final columnCount = isTableRows
            ? widget.count
            : _calculateOptimalColumns(availableWidth);
        final rowCount = _calculateOptimalRows(availableHeight);

        return Padding(
          padding: padding,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /* columns */
                  if (widget.showHeader)
                    _buildRow(
                      columnCount: columnCount,
                      height: widget.headerHeight,
                    ),
                  /* Rows */
                  Expanded(
                    child: Column(
                      children: List.generate(
                        rowCount,
                        (index) => Expanded(
                          child: _buildRow(
                            columnCount: columnCount,
                            height: widget.minRowHeight,
                            rowIndex: index,
                          ),
                        ),
                      ),
                    ),
                  ),
                  /* Footer */
                  if (widget.showFooter)
                    _buildRow(columnCount: 1, height: widget.footerHeight),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRow({
    required int columnCount,
    required double height,
    int? rowIndex,
  }) {
    if (isTableRows) {
      return _buildInsideTable(columnCount: columnCount, height: height);
    } else {
      return _buildOnLoad(columnCount: columnCount, height: height);
    }
  }

  Widget _buildOnLoad({required int columnCount, required double height}) {
    return Row(
      children: List.generate(
        columnCount,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _horSpacing,
            ),
            child: _buildShimmerItem(height: height, maxWidth: double.infinity),
          ),
        ),
      ),
    );
  }

  Widget _buildInsideTable({required int columnCount, required double height}) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: double.infinity,
        child: Row(
          children: List.generate(
            columnCount,
            (index) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _horSpacing,
                vertical: _horSpacing * 2,
              ),
              child: _buildTableShimmerItem(index: index, height: height),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableShimmerItem({
    required int index,
    required double height,
  }) {
    double? maxWidth = widget.columnWidths[index];

    /* Adding padding to each column cell, so that's why reducing padding width here */
    maxWidth -= _horSpacing * 2;
    return _buildShimmerItem(height: height, maxWidth: maxWidth);
  }

  Widget _buildShimmerItem({
    required double height,
    required double maxWidth,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (maxWidth <= 0) {
          // Ensure width is not zero to avoid division by zero
          return Container(
            height: height,
            width: maxWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: widget.baseColor,
            ),
          );
        }

        double animatedValue = _animation.value;
        double begin = -2.0 + (4.0 * animatedValue);
        double end = begin + 1.0;

        return Container(
          height: height,
          width: maxWidth,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.all(Radius.circular(8)),
            gradient: LinearGradient(
              begin: Alignment(begin, 0),
              end: Alignment(end, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.2, 0.4, 1.0],
            ),
          ),
        );
      },
    );
  }

  int _calculateOptimalColumns(double availableWidth) {
    int optimalColumns =
        (availableWidth / (widget.minColumnWidth + widget.columnSpacing))
            .floor();
    optimalColumns = math.max(3, math.min(8, optimalColumns));

    return optimalColumns;
  }

  int _calculateOptimalRows(double availableHeight) {
    double availableForRows =
        availableHeight - widget.headerHeight - widget.footerHeight;
    int optimalRows = (availableForRows / widget.minRowHeight).floor();
    optimalRows = math.max(8, math.min(30, optimalRows));

    return (optimalRows);
  }
}

/* Preset configurations for common use cases */
class TableShimmerPresets {
  /* Full screen table shimmer with default settings */
  static Widget fullScreen() {
    return const TableShimmer();
  }

  /* Compact version with smaller rows */
  static Widget compact() {
    return const TableShimmer(
      minRowHeight: 22.0,
      headerHeight: 32.0,
      rowSpacing: 6.0,
      columnSpacing: 6.0,
    );
  }

  /* Dense version with minimal spacing */
  static Widget dense() {
    return const TableShimmer(
      minRowHeight: 20.0,
      headerHeight: 28.0,
      rowSpacing: 4.0,
      columnSpacing: 4.0,
    );
  }

  /* Large version with bigger elements */
  static Widget large() {
    return const TableShimmer(
      minRowHeight: 35.0,
      headerHeight: 50.0,
      rowSpacing: 12.0,
      columnSpacing: 12.0,
    );
  }

  /* Themed from the app's own ThemeProperties (context.colors), instead of
     a hand-picked light/dark color pair, so the shimmer always matches
     whatever theme is active — including any future palette change — with
     no separate copy to keep in sync. */
  static Widget themed({
    required BuildContext context,
    bool showHeader = true,
    bool showFooter = true,
    int colsCount = 0,
    List<double> colWidths = const [],
  }) {
    final palette = context.colors;
    final baseColor = palette.surfaceSubtle;
    final highlightColor = palette.surfaceHover;

    return TableShimmer(
      showHeader: showHeader,
      showFooter: showFooter,
      count: colsCount,
      baseColor: baseColor,
      highlightColor: highlightColor,
      columnWidths: colWidths,
    );
  }

  static Widget custom({
    int? columns,
    int? rows,
    double? rowHeight,
  }) {
    return TableShimmer(
      minRowHeight: rowHeight ?? 40.0,
    );
  }
}

extension TableShimmerExtension on bool {
  Widget tableShimmer({
    Widget? shimmer,
    required Widget child,
  }) {
    return this ? (shimmer ?? const TableShimmer()) : child;
  }
}
