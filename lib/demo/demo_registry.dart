import 'package:flutter/material.dart';

import 'package:grid_sheet_demo/features/autofill.dart';
import 'package:grid_sheet_demo/features/cell_operations.dart';
import 'package:grid_sheet_demo/features/column_animation.dart';
import 'package:grid_sheet_demo/features/column_grouping.dart';
import 'package:grid_sheet_demo/features/column_operations.dart';
import 'package:grid_sheet_demo/features/column_types.dart';
import 'package:grid_sheet_demo/features/conditional_edit.dart';
import 'package:grid_sheet_demo/features/conditional_formatting.dart';
import 'package:grid_sheet_demo/features/context_menu.dart';
import 'package:grid_sheet_demo/features/custom_cells.dart';
import 'package:grid_sheet_demo/features/export_stats.dart';
import 'package:grid_sheet_demo/features/dropdown_cells.dart';
import 'package:grid_sheet_demo/features/filters.dart';
import 'package:grid_sheet_demo/features/form_layout.dart';
import 'package:grid_sheet_demo/features/formula_columns.dart';
import 'package:grid_sheet_demo/features/fixed_columns.dart';
import 'package:grid_sheet_demo/features/fixed_rows.dart';
import 'package:grid_sheet_demo/features/indexed_column.dart';
import 'package:grid_sheet_demo/features/layout_widgets.dart';
import 'package:grid_sheet_demo/features/modal_dialog.dart';
import 'package:grid_sheet_demo/features/pivot.dart';
import 'package:grid_sheet_demo/features/row_grouping.dart';
import 'package:grid_sheet_demo/features/row_swipe.dart';
import 'package:grid_sheet_demo/features/search.dart';
import 'package:grid_sheet_demo/features/pagination.dart';
import 'package:grid_sheet_demo/features/reload.dart';
import 'package:grid_sheet_demo/features/row_expansion.dart';
import 'package:grid_sheet_demo/features/row_operations.dart';
import 'package:grid_sheet_demo/features/row_separator.dart';
import 'package:grid_sheet_demo/features/rtl_support.dart';
import 'package:grid_sheet_demo/features/scrollbar.dart';
import 'package:grid_sheet_demo/features/selection.dart';
import 'package:grid_sheet_demo/features/snapshot.dart';
import 'package:grid_sheet_demo/features/sorting.dart';
import 'package:grid_sheet_demo/features/table_generation.dart';
import 'package:grid_sheet_demo/features/style_config.dart';
import 'package:grid_sheet_demo/features/wrappers.dart';

import 'demo_item.dart';

/// URL path prefix every demo is deep-linkable under, e.g.
/// `/gridsheet/column-types`. Shared by `grid_sheet_main.dart`'s router and
/// by [DemoItem.id]-to-URL resolution so the two can never drift apart.
const String demoRoutePrefix = '/gridsheet';

/// The `grid_sheet` package version this demo showcases — shown on the
/// dashboard header. Keep in sync with the `grid_sheet: ^x.y.z` dependency
/// in `pubspec.yaml` (there's no runtime API to read a dependency's
/// resolved version, so it's hand-pinned here).
const String gridSheetVersion = '3.0.0';

/// Single source of truth for every feature demo shown on the dashboard,
/// sorted by [DemoItem.title] (ascending) so the grid always reads
/// alphabetically regardless of the declaration order below.
///
/// To add a new demo: build the widget in `features/`, then add one [DemoItem]
/// entry to [_unsortedDemoRegistry]. No other file needs to change.
final List<DemoItem> demoRegistry = List<DemoItem>.unmodifiable(
  _unsortedDemoRegistry.toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())),
);

final List<DemoItem> _unsortedDemoRegistry = <DemoItem>[
  DemoItem(
    id: 'column-types',
    title: 'Column Types',
    icon: Icons.view_column_outlined,
    description: 'Eight column types, each with its own native editor.',
    fullDescription:
        'One table, eight different column types — text, integer, double, boolean, date/time, '
        'dropdown, formula and custom — each rendered with its own native editor.',
    sourcePath: 'lib/features/column_types.dart',
    builder: (_) => const ColumnTypes(),
  ),
  DemoItem(
    id: 'column-animation',
    title: 'Column Animation',
    icon: Icons.view_carousel_outlined,
    description: 'Opt-in reveal, replay, and cell-flash animations.',
    fullDescription:
        'Four opt-in animations bundled together — column reveal on mount/page-change, row reveal on '
        'sort/filter, cell-change flash, and column show/hide fade.',
    sourcePath: 'lib/features/column_animation.dart',
    builder: (_) => const ColumnAnimation(),
  ),
  DemoItem(
    id: 'column-operations',
    title: 'Column Operations',
    icon: Icons.settings_input_component_outlined,
    description: 'Insert, delete, resize, reorder columns and more..',
    fullDescription:
        'Insert, delete, hide/show, rename, reorder, and auto-fit columns from the toolbar. A dragged '
        'header lifts and opens a dotted gap of its exact width where it will land.',
    sourcePath: 'lib/features/column_operations.dart',
    builder: (_) => const ColumnOperations(),
  ),
  DemoItem(
    id: 'fixed-columns',
    title: 'Fixed Columns',
    icon: Icons.push_pin_outlined,
    description: 'Pin columns so they stay put while you scroll.',
    fullDescription:
        'Pin columns so they stay put while the rest of the table scrolls horizontally underneath.',
    sourcePath: 'lib/features/fixed_columns.dart',
    builder: (_) => const FixedColumns(),
  ),
  DemoItem(
    id: 'fixed-rows',
    title: 'Fixed Rows',
    icon: Icons.vertical_align_center_outlined,
    description: 'Pin rows so they stay put while you scroll.',
    fullDescription:
        'Pin rows to a band above or below the grid so they stay put while the rest of the rows '
        'scroll vertically underneath — the row-axis counterpart to Frozen Columns.',
    sourcePath: 'lib/features/fixed_rows.dart',
    builder: (_) => const FixedRows(),
  ),
  DemoItem(
    id: 'index-column',
    title: 'Index Column',
    icon: Icons.format_list_numbered_outlined,
    description: 'Configure or hide the built-in row-number column.',
    fullDescription:
        'GridSheet.indexColumn configures the built-in row-number column — title, width, pin side, and '
        'visibility — as a single synthetic GridSheetColumn.',
    sourcePath: 'lib/features/indexed_column.dart',
    builder: (_) => const IndexColumnDemo(),
  ),
  DemoItem(
    id: 'row-operations',
    title: 'Row Operations',
    icon: Icons.table_rows_outlined,
    description: 'Insert, delete, duplicate, resize, reorder rows and more..',
    fullDescription:
        'Insert, delete, duplicate, and bulk-update rows from the toolbar. Long-press a row number to drag '
        'it; the row lifts and a dotted gap of its exact height opens where it will land.',
    sourcePath: 'lib/features/row_operations.dart',
    builder: (_) => const RowOperations(),
  ),
  DemoItem(
    id: 'rtl-support',
    title: 'Right-to-Left (RTL) Support',
    icon: Icons.format_textdirection_r_to_l,
    description: 'Toggle RTL and watch the whole grid mirror live.',
    fullDescription:
        'GridSheet.direction mirrors the whole grid — column order, pin sides, scrolling, and icons — for '
        'RTL layouts, while column identity stays keyed to logical position.',
    sourcePath: 'lib/features/rtl_support.dart',
    builder: (_) => const RtlSupport(),
  ),
  DemoItem(
    id: 'cell-operations',
    title: 'Cell Operations',
    icon: Icons.grid_on_outlined,
    description: 'Update, clear, fill, and search cells in bulk.',
    fullDescription:
        'Update, clear, fill, and search selected cells in bulk from the toolbar — like copy/paste and '
        'find & replace in a spreadsheet.',
    sourcePath: 'lib/features/cell_operations.dart',
    builder: (_) => const CellOperations(),
  ),
  DemoItem(
    id: 'custom-cells',
    title: 'Custom Cells',
    icon: Icons.widgets_outlined,
    description: 'Fully custom cell widgets — chips, checkboxes, and more.',
    fullDescription:
        'Row numbers, headers, filters, and cells all use custom widgets — status chips, checkboxes, a '
        'date picker, row actions. Row Grouping groups products by status with custom headers.',
    sourcePath: 'lib/features/custom_cells.dart',
    builder: (_) => const CustomCells(),
  ),
  DemoItem(
    id: 'autofill',
    title: 'Autofill',
    icon: Icons.auto_fix_high_outlined,
    description: 'Autofill handle to drag-copy cell values.',
    fullDescription:
        'An autofill handle at a selection\'s corner drag-copies values, or continues a detected '
        'numeric/date pattern into neighboring cells.',
    sourcePath: 'lib/features/autofill.dart',
    builder: (_) => const Autofill(),
  ),
  DemoItem(
    id: 'formula-columns',
    title: 'Formula Columns',
    icon: Icons.functions_outlined,
    description: 'Excel-style formulas that recalculate automatically.',
    fullDescription:
        'Formula columns support Excel-style expressions like =B1 * C1 or =SUM(D1:D5), recalculating '
        'automatically when referenced cells change.',
    sourcePath: 'lib/features/formula_columns.dart',
    builder: (_) => const FormulaColumn(),
  ),
  DemoItem(
    id: 'conditional-format',
    title: 'Conditional Formatting',
    icon: Icons.palette_outlined,
    description: 'Rule-based styling for rows, columns, and cells.',
    fullDescription:
        'Rule-based styling for rows, columns, or cells, each driven by a simple true/false condition on '
        'column values.',
    sourcePath: 'lib/features/conditional_formatting.dart',
    builder: (_) => const ConditionalFormatting(),
  ),
  DemoItem(
    id: 'conditional-edit',
    title: 'Conditional Editability',
    icon: Icons.rule_outlined,
    description: 'Cells become editable based on the given conditions.',
    fullDescription:
        'A per-row condition decides whether a cell can be edited — e.g. DISCOUNT only becomes editable '
        'once STATUS is Approved.',
    sourcePath: 'lib/features/conditional_edit.dart',
    builder: (_) => const ConditionalEdit(),
  ),
  DemoItem(
    id: 'dropdown-cells',
    title: 'Dropdown Cell Type',
    icon: Icons.arrow_drop_down_circle_outlined,
    description: 'Dropdown editor limited to a fixed list of options.',
    fullDescription:
        'Dropdown columns render a popup menu limited to a fixed list of options, or plain text when '
        'marked read-only.',
    sourcePath: 'lib/features/dropdown_cells.dart',
    builder: (_) => const DropdownCells(),
  ),
  DemoItem(
    id: 'sorting',
    title: 'Sorting',
    icon: Icons.swap_vert_outlined,
    description: 'Sort multiple columns on double-tap a header',
    fullDescription:
        'Sort multiple columns at once (double-tap a header), with numbered icons showing sort priority.',
    sourcePath: 'lib/features/sorting.dart',
    builder: (_) => const Sorting(),
  ),
  DemoItem(
    id: 'filters',
    title: 'Filters',
    icon: Icons.filter_alt_outlined,
    description:
        'Advanced column filtering with comparisons, text matching, ranges, and AND/OR conditions.',
    fullDescription:
        'GridSheetManager.filters.add(values, comparison: ...) supports comparisons, text matching, '
        'ranges, and combined AND/OR conditions per column.',
    sourcePath: 'lib/features/filters.dart',
    builder: (_) => const Filters(),
  ),
  DemoItem(
    id: 'search',
    title: 'Overall Search',
    icon: Icons.travel_explore_outlined,
    description:
        'Searches the table across every cell, cascading as you add items.',
    fullDescription:
        'GridSheetManager.search(values) searches every cell in every row, cascading as more terms are '
        'added.',
    sourcePath: 'lib/features/search.dart',
    builder: (_) => const OverallSearch(),
  ),
  DemoItem(
    id: 'pagination',
    title: 'Pagination',
    icon: Icons.view_carousel_outlined,
    description:
        'Page through large tables, including server-side and infinite scroll.',
    fullDescription:
        'A built-in (or fully custom) pagination footer for paging through in-memory, server-side, or '
        'infinite-scroll data.',
    sourcePath: 'lib/features/pagination.dart',
    builder: (_) => const Pagination(),
  ),
  DemoItem(
    id: 'row-expansion',
    title: 'Row Expansion',
    icon: Icons.unfold_more_outlined,
    description: 'Expand any row to reveal extra details inline.',
    fullDescription:
        'Expand any row to reveal an inline detail panel beneath it. That panel reuses the exact same '
        'cells as the table, so dropdowns, editability, and formatting all stay consistent.',
    sourcePath: 'lib/features/row_expansion.dart',
    builder: (_) => const RowExpansion(),
  ),
  DemoItem(
    id: 'row-separator',
    title: 'Row Separators',
    icon: Icons.horizontal_rule_rounded,
    description: 'Insert a custom full-width widget between rows.',
    fullDescription:
        'rowSeparatorBuilder renders a full-width widget below a row, spanning pinned columns too — here, '
        'a subtotal banner after each order\'s last line item.',
    sourcePath: 'lib/features/row_separator.dart',
    builder: (_) => const RowSeparators(),
  ),
  DemoItem(
    id: 'row-grouping',
    title: 'Row Grouping',
    icon: Icons.account_tree_outlined,
    description:
        'Group rows under collapsible headers with subtotals and a grand total.',
    fullDescription:
        'groupingConfiguration.rows nests rows under collapsible headers by value, date, range or custom '
        'logic, with per-group aggregates, subtotals and an optional grand total.',
    sourcePath: 'lib/features/row_grouping.dart',
    builder: (_) => const RowGrouping(),
  ),
  DemoItem(
    id: 'pivot',
    title: 'Pivot Table',
    icon: Icons.pivot_table_chart_outlined,
    description: 'Summarize rows, with totals and averages.',
    fullDescription:
        'pivotConfiguration summarizes rows by row and column fields with sums, averages, counts or custom '
        'aggregators, plus totals. "Server rows" pages the rows and summarizes them server-side.',
    sourcePath: 'lib/features/pivot.dart',
    builder: (_) => const PivotDemo(),
  ),
  DemoItem(
    id: 'column-grouping',
    title: 'Column Grouping',
    icon: Icons.view_column_outlined,
    description: 'Nested, collapsible header bands over related columns.',
    fullDescription:
        'groupingConfiguration.columns adds nested header bands over related columns that collapse to '
        'fewer columns (here, Sales 2025 collapses to its Total).',
    sourcePath: 'lib/features/column_grouping.dart',
    builder: (_) => const ColumnGrouping(),
  ),
  DemoItem(
    id: 'row-swipe',
    title: 'Row Swipe',
    icon: Icons.swipe,
    description:
        'Swipe rows to reveal actions, hold them open, or full-swipe to save or delete.',
    fullDescription:
        'rowSwipeConfiguration reveals action strips when a row is dragged sideways; each side can hold '
        'open or run an action on a full swipe (here: start saves, end deletes).',
    sourcePath: 'lib/features/row_swipe.dart',
    builder: (_) => const RowSwipe(),
  ),
  DemoItem(
    id: 'selection',
    title: 'Selection Events',
    icon: Icons.touch_app_outlined,
    description:
        'Get notified instantly when rows, columns, or cells are selected.',
    fullDescription:
        'Live events fire as you click rows, headers, or cells. The panel below the table mirrors exactly '
        'what gets selected, in real time.',
    sourcePath: 'lib/features/selection.dart',
    builder: (_) => const SelectionEvents(),
  ),
  DemoItem(
    id: 'snapshot',
    title: 'Snapshot & Restore',
    icon: Icons.camera_alt_outlined,
    description: 'Checkpoint the grid state and jump back to it on demand.',
    fullDescription:
        'snapshots.create()/snapshots.restore() checkpoint the entire grid state and jump back to it in one '
        'call — the basis for undo/redo.',
    sourcePath: 'lib/features/snapshot.dart',
    builder: (_) => const SnapshotDemo(),
  ),
  DemoItem(
    id: 'wrappers',
    title: 'Custom Wrappers',
    icon: Icons.dashboard_customize_outlined,
    description: 'Wrap headers, filters, and rows in custom containers.',
    fullDescription:
        'Wrap the header, filter row, or each row in its own container — cards, borders, shadows, rounded '
        'corners — while leaving the cells inside untouched.',
    sourcePath: 'lib/features/wrappers.dart',
    builder: (_) => const CustomWrappers(),
  ),
  DemoItem(
    id: 'export-stats',
    title: 'Data Export & Statistics',
    icon: Icons.insights_outlined,
    description: 'Export table data to CSV and calculate column statistics.',
    fullDescription:
        'Export the table to CSV or structured data, and calculate sum, average, min, max, or median for '
        'any numeric column.',
    sourcePath: 'lib/features/export_stats.dart',
    builder: (_) => const DataExportStats(),
  ),
  DemoItem(
    id: 'styling',
    title: 'Style & Layout Configuration',
    icon: Icons.tune_outlined,
    description: 'Structural and visual theme configuration.',
    fullDescription:
        'Structural toggles (borders, header, hover, selection outline) and a visual theme (colors, '
        'corner rounding, text styles), each with its own light/dark variant.',
    sourcePath: 'lib/features/style_config.dart',
    builder: (_) => const StyleLayoutConfiguration(),
  ),
  DemoItem(
    id: 'context-menu',
    title: 'Context Menus',
    icon: Icons.more_vert_outlined,
    description: 'Right-click a cell, row, or column header for quick actions.',
    fullDescription:
        'Right-click a cell, row, or column header to build any custom menu you like — here, a small menu '
        'wired to real actions: copy, clear, duplicate, delete, sort, and hide.',
    sourcePath: 'lib/features/context_menu.dart',
    builder: (_) => const ContextMenu(),
  ),
  DemoItem(
    id: 'scrollbar',
    title: 'Scroll Configuration',
    icon: Icons.view_sidebar_outlined,
    description: 'Customize scrollbar thickness and visibility.',
    fullDescription:
        "Control the scrollbar's visibility, thickness, and corner rounding for both axes.",
    sourcePath: 'lib/features/scrollbar.dart',
    builder: (_) => const ScrollsConfiguration(),
  ),
  DemoItem(
    id: 'dialog',
    title: 'Table in Dialog',
    icon: Icons.open_in_new,
    description: 'A resizable dialog exercising the gridsheet table.',
    fullDescription:
        'A GridSheet inside a Dialog you can drag-resize from the corner grip, sized to its exact column '
        'widths so you can see when the horizontal scrollbar kicks in.',
    sourcePath: 'lib/features/modal_dialog.dart',
    builder: (_) => const DialogGridDemo(),
  ),
  DemoItem(
    id: 'layout-widgets',
    title: 'Layout Widgets',
    icon: Icons.dashboard_customize_outlined,
    description:
        'Add custom header, footer, empty-state, no-columns, and loading views.',
    fullDescription:
        'Add custom header/footer content around the table, plus custom empty-state, no-columns, and '
        'loading views.',
    sourcePath: 'lib/features/layout_widgets.dart',
    builder: (_) => const LayoutWidgets(),
  ),
  DemoItem(
    id: 'reload',
    title: 'Reload',
    icon: Icons.sync_outlined,
    description:
        'Manual and scheduled auto-reload of grid data via rowsLoader.',
    fullDescription:
        'GridSheetManager.reload() re-fetches rows through rowsLoader, either manually or on a scheduled '
        'auto-reload interval.',
    sourcePath: 'lib/features/reload.dart',
    builder: (_) => const ReloadDemo(),
  ),
  DemoItem(
    id: 'form-layout',
    title: 'Form Layout',
    icon: Icons.view_agenda_outlined,
    description: 'Card-based form layout for narrow/mobile viewports.',
    fullDescription:
        'viewMode: form or responsive shows rows as "label : value" cards on narrow/mobile viewports, '
        'reusing the table\'s cell rendering, selection, and editing.',
    sourcePath: 'lib/features/form_layout.dart',
    builder: (_) => const FormLayoutDemo(),
  ),
  DemoItem(
    id: 'table-generation',
    title: 'Dynamic Table Generation',
    icon: Icons.grid_4x4_outlined,
    description: 'Auto-generate large synthetic tables to test performance.',
    fullDescription:
        'Instantly generates a blank synthetic table with any number of columns and rows, for prototypes '
        'or performance testing.',
    sourcePath: 'lib/features/table_generation.dart',
    builder: (_) => const TableGeneration(),
  ),
];

/// Looks up a registered demo by its route id, or `null` for an unknown
/// (stale or mistyped) `/demo/<id>` deep link.
DemoItem? findDemoById(String id) {
  for (final item in demoRegistry) {
    if (item.id == id) return item;
  }
  return null;
}
