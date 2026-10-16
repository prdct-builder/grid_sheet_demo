// Core widgets
export 'src/core/grid_sheet.dart';
export 'src/core/grid_sheet_manager.dart';
export 'src/core/grid_sheet_scrollbar.dart' hide GridSheetScrollRelay;
export 'src/core/facets/api/rows.dart';
export 'src/core/facets/api/config.dart';
export 'src/core/facets/api/auto_reload.dart';
export 'src/core/facets/api/snapshots.dart';
export 'src/core/facets/api/changes.dart';
export 'src/core/facets/api/history.dart';
export 'src/core/facets/api/formatting.dart';
export 'src/core/facets/api/formulas.dart';
export 'src/core/facets/api/sorting.dart';
export 'src/core/facets/api/pagination.dart';
export 'src/core/facets/api/search.dart';
export 'src/core/facets/api/cursor.dart';
export 'src/core/facets/api/data.dart';
export 'src/core/facets/api/filters.dart';
export 'src/core/facets/api/selection.dart';
export 'src/core/facets/api/cells.dart';
export 'src/core/facets/api/columns.dart';
export 'src/core/facets/api/loading.dart';
export 'src/core/facets/api/row_grouping.dart';
export 'src/core/facets/api/column_grouping.dart';
export 'src/core/facets/api/grouping.dart';
export 'src/core/facets/api/pivot.dart';
export 'src/core/grid_sheet_custom_cell_builder.dart';
export 'src/models/grid_sheet_row.dart' hide GridSheetRowInternals;
export 'src/models/grid_sheet_column.dart';
export 'src/models/grid_sheet_cell.dart' hide GridSheetCellSelectionState;
export 'src/models/grid_sheet_page_data.dart';
export 'src/models/grid_sheet_pivot_data.dart';

// Localization
export 'src/localization/grid_sheet_localizations.dart';

// Enums, Utilities & Configuration
export 'src/utils/grid_sheet_enums.dart'
    hide
        GridSheetFormulaTokenType,
        FormulaErrorType,
        GridSheetFillDirection,
        GridSheetBooleanColumnType,
        GridSheetDateTimeColumnType,
        GridSheetDoubleColumnType,
        GridSheetIntegerColumnType,
        GridSheetTextColumnType,
        GridSheetFormulaColumnType,
        GridSheetDropdownColumnType,
        GridSheetCustomColumnType;
export 'src/utils/grid_sheet_expression.dart';
export 'src/utils/grid_sheet_constants.dart';
export 'src/utils/grid_sheet_data_source.dart';
export 'src/utils/grid_sheet_dashed_border.dart';

// Configuration and Styling
export 'src/configuration/reload_configuration.dart';
export 'src/configuration/gridsheet_configuration.dart';
export 'src/configuration/style_configuration.dart';
export 'src/configuration/scroll_configuration.dart';
export 'src/configuration/autofill_configuration.dart';
export 'src/configuration/animation_configuration.dart';
export 'src/configuration/row_expansion_configuration.dart';
export 'src/configuration/form_configuration.dart';
export 'src/configuration/dynamic_generation_configuration.dart';
export 'src/configuration/context_menu_configuration.dart';
export 'src/configuration/row_swipe_configuration.dart';
export 'src/configuration/pivot_configuration.dart';
export 'src/features/pivot/pivot_engine.dart'
    show GridSheetPivotColumn, GridSheetPivotLine;
export 'src/configuration/row_grouping_configuration.dart'
    hide GridSheetGroupSortInternals;
export 'src/configuration/column_grouping_configuration.dart';
export 'src/configuration/grouping_configuration.dart';

// Features and Interactivity
export 'src/core/grid_sheet_events.dart';
export 'src/core/grid_sheet_typedefs.dart';
export 'src/models/grid_sheet_snapshot.dart';
export 'src/features/context_menu.dart';
export 'src/features/conditional_format.dart'
    hide GridSheetEvaluatedFormatCache;
export 'src/features/sorting.dart' hide GridSheetSorter, GridSheetSortValue;
export 'src/features/pagination.dart';
export 'src/features/row_overlay.dart';
export 'src/features/cell_audit_trail.dart';
export 'src/features/row_swipe.dart' show GridSheetRowSwipeExclusion;

// Row and column grouping. The node model (GridSheetGroupNode) is shared
// by both axes; engines, controllers and views stay internal.
export 'src/features/grouping/grouping.dart' show GridSheetGroupNode;
export 'src/features/grouping/aggregation.dart';
export 'src/features/grouping/row_group.dart';
export 'src/features/grouping/row_group_bucketers.dart'
    hide GridSheetGroupDateBucketerInternals;
export 'src/features/grouping/row_group_cell.dart'
    show GridSheetRowGroupCellContext;
export 'src/features/grouping/column_group_cell.dart'
    show GridSheetColumnGroupAccessors, GridSheetColumnGroupCellContext;
export 'src/features/grouping/grouped_data.dart';
