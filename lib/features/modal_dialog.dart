import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// A grid inside a resizable [Dialog]: sizing a grid to its columns,
/// growing columns to fill extra width
/// (`GridSheetConfiguration.stretchColumnsToFillWidth`,
/// `GridSheetColumn.maxStretchWidth`), and how the vertical scrollbar's
/// strip (`GridSheetScrollBarConfiguration.showVerticalScrollbar`/
/// `showHorizontalScrollbar`/`verticalScrollbarPlacement`) changes the width
/// the columns get.
///
/// Shows a 4-column, 10-row GridSheet inside a resizable [Dialog] whose
/// initial content width is pinned to the exact sum of the column widths
/// plus the scrollbar gutter — no serial-number column and no pinned
/// columns, so that width maps 1:1 onto the grid's scrollable section.
/// Dragging the corner grip wider than that sum leaves blank space past the
/// last column unless Stretch Columns is on, in which case they grow to
/// fill it (see `stretchColumnsToFillWidth`'s own doc comment for exactly
/// how). The vertical-scrollbar toggle independently forces (or avoids) the
/// grid's own vertical scrollbar via row count, to confirm it never
/// influences the horizontal boundary. The scroll-config toggles below that
/// exercise the actual `GridSheetScrollBarConfiguration` fields: disabling
/// vertical scrolling or switching to `overlay` placement collapses the
/// gutter to zero, which the "Scrollbar gutter" readout mirrors.
class DialogGridDemo extends StatefulWidget {
  const DialogGridDemo({super.key});

  @override
  State<DialogGridDemo> createState() => _DialogGridDemoState();
}

class _DialogGridDemoState extends State<DialogGridDemo> {
  static const List<double> _columnWidths = [120, 120, 120, 120];
  // Must match the rows' own height (see _rows()), or the computed
  // dialog height won't fit them.
  static final double _rowHeight = Constants.rowHeight;
  static const double _headerHeight = 50;
  static const double _bottomBarHeight = 72;
  static const int _rowCount = 10;
  // Fewer rows than _rowCount fit in this height, so the grid's own
  // vertical SingleChildScrollView is forced to scroll (and its Scrollbar
  // to paint) without touching column widths or the dialog width at all —
  // keeps the vertical axis independent of the horizontal test above.
  static const int _visibleRowsWithScrollbar = 4;

  // Mirrors the private `_verticalScrollbarGutter = thickness + 4.0` gutter
  // the package reserves internally (grid_sheet_impl.dart, via
  // _computeVerticalScrollbarGutter) so the vertical scrollbar never
  // overlaps the last column. It isn't exported, so it's replicated here
  // purely to size this harness right against the boundary that fix cares
  // about. Zero whenever the real config wouldn't reserve space either —
  // i.e. vertical scrolling disabled, or placement set to overlay.
  // The thickness this demo's scrollConfig() uses (ThemeBorders.radiusMd);
  // the package default is 6.
  static const double _scrollbarThickness = ThemeBorders.radiusMd;
  static const double _kScrollbarExtraPadding = 4.0;
  double get _gutter {
    final reservesSpace = _showVerticalScrollbar &&
        _verticalPlacement ==
            GridSheetVerticalScrollbarPlacement.afterLastColumn;
    return reservesSpace ? _scrollbarThickness + _kScrollbarExtraPadding : 0.0;
  }

  // GridSheetStyleConfiguration.columnBorderWidth default — every column,
  // including the last, paints its own right border when showColumnBorders
  // is on (the demo's GridSheetConfiguration doesn't turn it off), so that's
  // one column's worth of extra width per column, not just (count - 1).
  // Without this, the dialog is a few pixels too narrow for its own "exact
  // fit" content and a horizontal scrollbar shows up despite the width mode
  // claiming an exact match.
  static const double _columnBorderWidth = 1.0;
  double get _columnBordersWidth => _columnWidths.length * _columnBorderWidth;

  final ValueNotifier<String> status =
      ValueNotifier('Open the dialog, then drag its corner to resize.');

  bool _withVerticalScrollbar = false;
  bool _showVerticalScrollbar = true;
  bool _showHorizontalScrollbar = true;
  GridSheetVerticalScrollbarPlacement _verticalPlacement =
      GridSheetVerticalScrollbarPlacement.afterLastColumn;
  bool _stretchColumns = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  double get _columnSum => _columnWidths.fold(0.0, (a, b) => a + b);

  double get _dialogContentWidth => _columnSum + _columnBordersWidth + _gutter;

  double get _dialogContentHeight {
    final visibleRows =
        _withVerticalScrollbar ? _visibleRowsWithScrollbar : _rowCount;
    return _headerHeight + (_rowHeight * visibleRows) + _bottomBarHeight;
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Table in Dialog',
      icon: Icons.open_in_new,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Force Row Overflow',
            icon: Icons.swap_vert,
            color: context.accents.teal,
            value: _withVerticalScrollbar,
            onChanged: (value) =>
                setState(() => _withVerticalScrollbar = value),
            tooltip:
                'Start the dialog short enough to force vertical scrolling',
          ),
          DemoActionButton(
            label: _showVerticalScrollbar
                ? 'V-Scroll: Enabled'
                : 'V-Scroll: Disabled',
            icon: Icons.height,
            color: context.accents.green,
            onPressed: () => setState(
                () => _showVerticalScrollbar = !_showVerticalScrollbar),
            tooltip: 'Toggle showVerticalScrollbar',
          ),
          DemoActionButton(
            label: _showHorizontalScrollbar
                ? 'H-Scroll: Enabled'
                : 'H-Scroll: Disabled',
            icon: Icons.swap_horiz,
            color: context.accents.green,
            onPressed: () => setState(
                () => _showHorizontalScrollbar = !_showHorizontalScrollbar),
            tooltip: 'Toggle showHorizontalScrollbar',
          ),
          DemoActionButton(
            label: _verticalPlacement ==
                    GridSheetVerticalScrollbarPlacement.overlay
                ? 'V-Scrollbar: Overlay'
                : 'V-Scrollbar: After Last Column',
            icon: Icons.vertical_align_center,
            color: context.accents.indigo,
            onPressed: () => setState(() {
              _verticalPlacement = _verticalPlacement ==
                      GridSheetVerticalScrollbarPlacement.overlay
                  ? GridSheetVerticalScrollbarPlacement.afterLastColumn
                  : GridSheetVerticalScrollbarPlacement.overlay;
            }),
            tooltip: 'Switch where the vertical scrollbar sits',
          ),
          DemoActionButton(
            label: _stretchColumns
                ? 'Stretch Columns: On'
                : 'Stretch Columns: Off',
            icon: Icons.fit_screen_outlined,
            color: context.accents.purple,
            onPressed: () => setState(() => _stretchColumns = !_stretchColumns),
            tooltip: 'Grow columns to fill the dialog when resized wider',
          ),
          DemoActionButton(
            label: 'Open Dialog',
            icon: Icons.open_in_new,
            color: context.accents.orange,
            onPressed: () => _openDialog(context),
            tooltip: 'Open the resizable dialog with the settings above',
          ),
        ],
      ),
      grid: _buildPreviewPane(context),
    );
  }

  Widget _buildPreviewPane(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.aspect_ratio, size: 32, color: colors.textMuted),
          const SizedBox(height: ThemeSpacing.md),
          _InfoRow(
              label:
                  'Dialog content width (sum of column widths + borders + gutter)',
              value: '${_dialogContentWidth.toStringAsFixed(0)}px'),
          _InfoRow(
              label: 'Dialog content height',
              value: '${_dialogContentHeight.toStringAsFixed(0)}px'),
        ],
      ),
    );
  }

  // Initial size only — once open, the user can drag the corner grip to
  // resize freely (see _ResizeHandle below), independent of the
  // row-overflow toggle that only decides where the dialog *starts*.
  static const double _minDialogWidth = 240.0;
  static const double _minDialogHeight = 180.0;
  static const double _dialogInset = ThemeSpacing.xl;

  void _openDialog(BuildContext context) {
    double dialogWidth = _dialogContentWidth;
    double dialogHeight = _dialogContentHeight;

    status.value = 'Opened dialog: width=${dialogWidth.toStringAsFixed(0)}px, '
        'height=${dialogHeight.toStringAsFixed(0)}px, '
        'vertical scrollbar ${_withVerticalScrollbar ? 'forced ON' : 'OFF'}, '
        'gutter=${_gutter.toStringAsFixed(0)}px. Drag the corner grip to resize.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final screenSize = MediaQuery.of(context).size;
          final maxWidth = screenSize.width - _dialogInset * 2;
          final maxHeight = screenSize.height - _dialogInset * 2;

          return Dialog(
            insetPadding: const EdgeInsets.all(_dialogInset),
            shape: RoundedRectangleBorder(borderRadius: ThemeBorders.roundedLg),
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(ThemeBorders.radiusLg)),
                          child: GridSheet(
                            columns: _columns(),
                            rows: _rows(),
                            indexColumn: null,
                            configuration: GridSheetConfiguration(
                              showColumnFilters: false,
                              headerHeight: _headerHeight,
                              stretchColumnsToFillWidth: _stretchColumns,
                            ),
                            styleConfiguration: styleConfig(dialogContext),
                            scrollConfiguration: scrollConfig(context).copyWith(
                              showVerticalScrollbar: _showVerticalScrollbar,
                              showHorizontalScrollbar: _showHorizontalScrollbar,
                              verticalScrollbarPlacement: _verticalPlacement,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeSpacing.xxl,
                          vertical: ThemeSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _ResizeHandle(
                      onPanUpdate: (details) {
                        setDialogState(() {
                          dialogWidth = (dialogWidth + details.delta.dx)
                              .clamp(_minDialogWidth, maxWidth);
                          dialogHeight = (dialogHeight + details.delta.dy)
                              .clamp(_minDialogHeight, maxHeight);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['EMPLOYEE', 'DEPARTMENT', 'ROLE', 'STATUS'];
    const titles = ['Employee', 'Department', 'Role', 'Status'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
    ];
    // Status holds a short fixed word, so it's capped — with Stretch Columns
    // on, the other three absorb its share of the leftover width instead.
    const maxStretchWidths = [null, null, null, 110.0];
    // Widths come from _columnWidths (a class-level field, not a local
    // const) because _columnSum/_dialogContentWidth/_gutter elsewhere in
    // this file also depend on it to size the dialog itself pixel-exactly.
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: _columnWidths[i],
        maxStretchWidth: maxStretchWidths[i],
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      ['Employee 1', 'Engineering', 'Lead', 'Active'],
      ['Employee 2', 'Design', 'Contributor', 'On Leave'],
      ['Employee 3', 'Sales', 'Manager', 'Remote'],
      ['Employee 4', 'Support', 'Lead', 'Active'],
      ['Employee 5', 'Engineering', 'Contributor', 'On Leave'],
      ['Employee 6', 'Design', 'Manager', 'Remote'],
      ['Employee 7', 'Sales', 'Lead', 'Active'],
      ['Employee 8', 'Support', 'Contributor', 'On Leave'],
      ['Employee 9', 'Engineering', 'Manager', 'Remote'],
      ['Employee 10', 'Design', 'Lead', 'Active'],
    ];
    return raw.asMap().entries.map((e) {
      return GridSheetRow(
        key: ValueKey('row_${e.key}'),
        index: e.key,
        data: e.value,
        height: _rowHeight,
      );
    }).toList();
  }
}

/// Drag grip pinned to the dialog's bottom-right corner so its size can be
/// adjusted freely after opening, on top of whatever the row-overflow
/// toggle picked as the starting size.
class _ResizeHandle extends StatelessWidget {
  final GestureDragUpdateCallback onPanUpdate;

  const _ResizeHandle({required this.onPanUpdate});

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.open_in_full_rounded, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style:
                  TextTypography.label.copyWith(color: colors.textSecondary)),
          Text(value,
              style: TextTypography.code.copyWith(color: colors.textPrimary)),
        ],
      ),
    );
  }
}
