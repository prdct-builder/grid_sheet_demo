import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class ConditionalFormatting extends StatefulWidget {
  const ConditionalFormatting({super.key});

  @override
  State<ConditionalFormatting> createState() => _ConditionalFormattingState();
}

class _ConditionalFormattingState extends State<ConditionalFormatting> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier('');
  bool _rowRuleOn = true;
  bool _columnRuleOn = true;
  bool _cellRuleOn = true;
  bool _includePinnedCells = false;
  bool _pinFirstRow = false;
  bool _formView = false;
  bool _stopIfTrueOn = false;
  bool _wholeColumnRuleOn = false;
  bool _rowStateRuleOn = false;
  bool _columnIndexRuleOn = false;
  bool _crossColumnRuleOn = false;
  bool _textOnlyRuleOn = false;
  bool _stockLevelsRuleOn = false;
  bool _restockOverdueRuleOn = false;
  bool _noExpressionRuleOn = false;
  int _newRowCount = 0;

  // Cycled by the "Price limit" button, which swaps _cellRule for one with
  // the new limit via updateConditionalFormatRules.
  static const _priceLimits = [150, 250, 100];
  int _priceLimitIndex = 0;
  late GridSheetConditionalFormatRule _cellRule = _priceRule(_priceLimits[0]);

  static final _rowRule = GridSheetConditionalFormatRule(
    name: 'LowStockRow',
    scope: GridSheetFormatScope.row,
    expression: 'STOCK < 20 ? "#FFCDD2" : null',
    textStyle: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
  );

  // Highest-priority when active (inserted at atIndex: 0): matches the same
  // low-stock rows as _rowRule but only sets a background, leaving textStyle
  // unset. With stopIfTrue: true, that gap is never filled by _rowRule's
  // bold red text below it — rows show the plain yellow background only.
  static final _stopIfTrueRule = GridSheetConditionalFormatRule(
    name: 'StopIfTrueDemo',
    scope: GridSheetFormatScope.row,
    expression: 'STOCK < 20 ? "#FFF9C4" : null',
    stopIfTrue: true,
  );

  static final _columnRule = GridSheetConditionalFormatRule(
    name: 'CATEGORY',
    scope: GridSheetFormatScope.cell,
    expression: 'CATEGORY == "Electronics" ? "#C8E6C9" : null',
    textStyle: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
  );

  static GridSheetConditionalFormatRule _priceRule(int limit) =>
      GridSheetConditionalFormatRule(
        name: 'PRICE',
        scope: GridSheetFormatScope.cell,
        expression: 'PRICE > $limit ? "#FFE0B2" : null',
        textStyle:
            TextStyle(color: Color(0xFFE65100), fontStyle: FontStyle.italic),
      );

  // Cell scope with an expression that's always a color (no ternary/null
  // branch) — every cell in the column is formatted unconditionally,
  // regardless of its value, unlike _columnRule above which only colors rows
  // where CATEGORY == "Electronics".
  static final _wholeColumnRule = GridSheetConditionalFormatRule(
    name: 'PRODUCT',
    scope: GridSheetFormatScope.cell,
    expression: '"#E1F5FE"',
    textStyle: TextStyle(color: Color(0xFF01579B)),
  );

  // One expression, several colors: nested ternaries pick a color per value.
  static final _stockLevelsRule = GridSheetConditionalFormatRule(
    name: 'STOCK',
    scope: GridSheetFormatScope.cell,
    expression: 'STOCK < 10 ? "#FFCDD2" : '
        'STOCK < 50 ? "#FFE0B2" : "#C8E6C9"',
  );

  // Dates compare directly against `_today` (midnight today), another date
  // column, or an ISO date string like "2024-06-01".
  static final _restockOverdueRule = GridSheetConditionalFormatRule(
    name: 'RESTOCK',
    scope: GridSheetFormatScope.cell,
    expression: 'RESTOCK < _today ? "#FFCDD2" : null',
    textStyle: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
  );

  // No expression at all: matches every cell the rule covers, so its
  // textStyle applies to the whole CATEGORY column.
  static final _noExpressionRule = GridSheetConditionalFormatRule(
    name: 'CATEGORY',
    scope: GridSheetFormatScope.cell,
    textStyle: TextStyle(fontStyle: FontStyle.italic),
  );

  // Uses the `_row_state` extra value — not a column, so only reachable via
  // extraValues(). Row scope: applies to every cell of a row in that state.
  //
  // Inserted at atIndex: 0 (see _toggleRowStateRule) so it outranks
  // _rowRule/_columnRule/_cellRule's value-based colors, and stopIfTrue:
  // true so, once a row's state matches, none of those lower-priority rules
  // are considered for it at all — otherwise a newly inserted row (STOCK:
  // 0, i.e. < 20) would still show _rowRule's low-stock red, since list
  // order alone (without stopIfTrue) only fills in gaps this rule left
  // unset, and this rule already claims the background.
  static final _rowStateRule = GridSheetConditionalFormatRule(
    name: 'RowStateDemo',
    scope: GridSheetFormatScope.row,
    expression: '_row_state == "inserted" ? "#C8E6C9" : '
        '_row_state == "modified" ? "#FFF9C4" : '
        '_row_state == "deleted" ? "#FFCDD2" : null',
    textStyle: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
    stopIfTrue: true,
  );

  // Uses the `_column_index` extra value to zebra-stripe by column instead of
  // by row — row scope, but the expression is re-evaluated per cell with a
  // different _column_index each time, so it can vary within a single row.
  static final _columnIndexRule = GridSheetConditionalFormatRule(
    name: 'ColumnIndexStripe',
    scope: GridSheetFormatScope.row,
    expression: '_column_index % 2 == 0 ? "#F5F5F5" : null',
  );

  // Uses `_column_name` + `_cell_value` together in a single row-scope rule to
  // do what would otherwise take two separate cell-scope rules
  // (_columnRule-style, one per column) — no name-matching restriction, so
  // one rule can branch on which column it's currently formatting.
  static final _crossColumnRule = GridSheetConditionalFormatRule(
    name: 'CrossColumnDemo',
    scope: GridSheetFormatScope.row,
    expression: '(_column_name == "STOCK" && _cell_value < 20) || '
        '(_column_name == "PRICE" && _cell_value > 150) ? "#B3E5FC" : null',
  );

  // An expression that returns `true` (not a color) matches with no
  // background, so only textStyle applies: well-stocked items get bold,
  // underlined green text and keep their normal row color.
  static final _textOnlyRule = GridSheetConditionalFormatRule(
    name: 'STOCK',
    scope: GridSheetFormatScope.cell,
    expression: 'STOCK >= 100',
    textStyle: TextStyle(
      color: Color(0xFF1B5E20),
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    ),
  );

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Conditional Formatting',
      description:
          'Format rules: each rule\'s expression returns a color (match with that background), true '
          '(match, text style only) or null (no match); list order is priority. Covers row and cell scopes, '
          'whole columns, multi-color, date and text-only rules, the _row_state/_column_name/_column_index/'
          '_cell_value/_today variables, stopIfTrue, priority, pinned cells, form view and re-applying rules.',
      icon: Icons.palette_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: _rowRuleOn ? 'Stock<20: ON' : 'Stock<20: OFF',
            icon: Icons.table_rows_outlined,
            color: context.accents.red,
            onPressed: () =>
                _toggleRule(_rowRule, _rowRuleOn, (v) => _rowRuleOn = v),
            tooltip: 'Toggle the row-scope low-stock highlight rule',
          ),
          DemoActionButton(
            label: _columnRuleOn ? 'Electronics: ON' : 'Electronics: OFF',
            icon: Icons.view_column_outlined,
            color: context.accents.green,
            onPressed: () => _toggleRule(
                _columnRule, _columnRuleOn, (v) => _columnRuleOn = v),
            tooltip: 'Toggle the CATEGORY == Electronics highlight rule',
          ),
          DemoActionButton(
            label: _cellRuleOn
                ? 'Price>${_priceLimits[_priceLimitIndex]}: ON'
                : 'Price>${_priceLimits[_priceLimitIndex]}: OFF',
            icon: Icons.grid_on_outlined,
            color: context.accents.orange,
            onPressed: () =>
                _toggleRule(_cellRule, _cellRuleOn, (v) => _cellRuleOn = v),
            tooltip: 'Toggle the cell-scope high-price highlight rule',
          ),
          DemoActionButton(
            label: 'Price limit: ${_priceLimits[_priceLimitIndex]}',
            icon: Icons.tune,
            color: context.accents.orange,
            onPressed: _cyclePriceLimit,
            tooltip: 'Update a rule in place: replace the price rule with one '
                'using the next limit (150 → 250 → 100)',
          ),
          DemoActionButton(
            label:
                _stockLevelsRuleOn ? 'Stock levels: ON' : 'Stock levels: OFF',
            icon: Icons.signal_cellular_alt,
            color: context.accents.amber,
            onPressed: () => _toggleRule(_stockLevelsRule, _stockLevelsRuleOn,
                (v) => _stockLevelsRuleOn = v),
            tooltip: 'One expression, three colors: red < 10, amber < 50, '
                'green otherwise',
          ),
          DemoActionButton(
            label: _restockOverdueRuleOn
                ? 'Restock overdue: ON'
                : 'Restock overdue: OFF',
            icon: Icons.event_busy,
            color: context.accents.red,
            onPressed: () => _toggleRule(_restockOverdueRule,
                _restockOverdueRuleOn, (v) => _restockOverdueRuleOn = v),
            tooltip: 'Date rule: RESTOCK < _today — restock dates already '
                'past are red',
          ),
          DemoActionButton(
            label: _wholeColumnRuleOn
                ? 'Whole PRODUCT col: ON'
                : 'Whole PRODUCT col: OFF',
            icon: Icons.format_color_fill,
            color: context.accents.teal,
            onPressed: () => _toggleRule(_wholeColumnRule, _wholeColumnRuleOn,
                (v) => _wholeColumnRuleOn = v),
            tooltip: 'Cell-scope rule with an unconditional color '
                'expression — formats every cell in the column, not just '
                'ones matching a condition',
          ),
          DemoActionButton(
            label: _textOnlyRuleOn
                ? 'Stock>=100 text: ON'
                : 'Stock>=100 text: OFF',
            icon: Icons.format_bold,
            color: context.accents.green,
            onPressed: () => _toggleRule(
                _textOnlyRule, _textOnlyRuleOn, (v) => _textOnlyRuleOn = v),
            tooltip:
                'expression returning true + textStyle — bold green text for stock '
                '>= 100, with no background color',
          ),
          DemoActionButton(
            label: _noExpressionRuleOn
                ? 'Italic CATEGORY: ON'
                : 'Italic CATEGORY: OFF',
            icon: Icons.format_italic,
            color: context.accents.neutral,
            onPressed: () => _toggleRule(_noExpressionRule, _noExpressionRuleOn,
                (v) => _noExpressionRuleOn = v),
            tooltip: 'A rule with no expression matches every cell it '
                'covers — italic text for the whole CATEGORY column',
          ),
          DemoToggleButton(
            label: 'stopIfTrue (Stock<20)',
            icon: Icons.block_flipped,
            color: context.accents.purple,
            value: _stopIfTrueOn,
            onChanged: (v) => _toggleStopIfTrue(v),
            tooltip: 'Add a higher-priority rule that blocks later text styles',
          ),
          DemoActionButton(
            label: 'Reverse priority',
            icon: Icons.swap_vert,
            color: context.accents.purple,
            onPressed: _reversePriority,
            tooltip: 'List order is priority: reverse it and watch cells two '
                'rules both color (e.g. a low-stock Electronics row) switch',
          ),
          DemoActionButton(
            label: _rowStateRuleOn ? 'Row State: ON' : 'Row State: OFF',
            icon: Icons.fiber_new_outlined,
            color: context.accents.pink,
            onPressed: () => _toggleRowStateRule(!_rowStateRuleOn),
            tooltip: 'extraValues["_row_state"] — colors inserted/modified/'
                'deleted rows, taking priority over the value-based rules '
                'below (atIndex: 0 + stopIfTrue). Insert or edit a row to '
                'see it.',
          ),
          DemoActionButton(
            label: 'Insert Row',
            icon: Icons.add,
            color: context.accents.teal,
            onPressed: _insertRow,
            tooltip: 'Insert a blank row (state: inserted) to trigger the '
                'Row State rule above',
          ),
          DemoActionButton(
            label: 'Delete Selected',
            icon: Icons.delete_outline,
            color: context.accents.red,
            onPressed: _deleteSelectedRows,
            tooltip: 'Mark selected row(s) deleted to trigger the Row State '
                'rule above',
          ),
          DemoActionButton(
            label:
                _columnIndexRuleOn ? 'Column Stripe: ON' : 'Column Stripe: OFF',
            icon: Icons.view_week_outlined,
            color: context.accents.neutral,
            onPressed: () => _toggleRule(_columnIndexRule, _columnIndexRuleOn,
                (v) => _columnIndexRuleOn = v),
            tooltip: 'extraValues["_column_index"] — shades every other '
                'column',
          ),
          DemoActionButton(
            label:
                _crossColumnRuleOn ? 'Cross-Column: ON' : 'Cross-Column: OFF',
            icon: Icons.compare_arrows,
            color: context.accents.amber,
            onPressed: () => _toggleRule(_crossColumnRule, _crossColumnRuleOn,
                (v) => _crossColumnRuleOn = v),
            tooltip: 'extraValues["_column_name"] + ["_cell_value"] in one '
                'row-scope rule — branches per column without a separate '
                'rule for each',
          ),
          DemoToggleButton(
            label: 'Pin first row',
            icon: Icons.push_pin_outlined,
            color: context.accents.blue,
            value: _pinFirstRow,
            onChanged: _togglePinFirstRow,
            tooltip: 'Pin the first row to the top — pinned rows are left '
                'unformatted unless "Include pinned" is on',
          ),
          DemoToggleButton(
            label: 'Include pinned',
            icon: Icons.ac_unit,
            color: context.accents.blue,
            value: _includePinnedCells,
            onChanged: (v) {
              setState(() => _includePinnedCells = v);
              status.value = 'conditionalFormatIncludesPinnedLeftCells / '
                  'conditionalFormatIncludesPinnedTopCells: $v';
            },
            tooltip: 'Apply rules to the pinned PRODUCT column and a pinned '
                'top row too',
          ),
          DemoToggleButton(
            label: 'Form view',
            icon: Icons.view_agenda_outlined,
            color: context.accents.teal,
            value: _formView,
            onChanged: (v) {
              setState(() => _formView = v);
              status.value = v
                  ? 'Form view: row rules color each card, cell rules '
                      'color their field'
                  : 'Table view';
            },
            tooltip: 'Show rows as cards — the same rules apply there too',
          ),
          DemoActionButton(
            label: 'Re-apply rules',
            icon: Icons.refresh,
            color: context.accents.indigo,
            onPressed: _reapplyRules,
            tooltip: 'updateConditionalFormatRules(conditionalFormatRules) '
                're-evaluates every rule — use it when a rule depends on '
                'something outside the grid (e.g. today at midnight)',
          ),
          DemoActionButton(
            label: 'Get Style Map',
            icon: Icons.data_object_outlined,
            color: context.accents.indigo,
            onPressed: _showStyleMap,
            tooltip: 'Inspect every cell\'s currently applied formatting',
          ),
          DemoActionButton(
            label: 'Clear all rules',
            icon: Icons.format_clear,
            color: context.accents.red,
            onPressed: _clearAllRules,
            tooltip: 'clearConditionalFormatRules() — removes every rule',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: GridSheetConfiguration(
          enableCellSelection: true,
          conditionalFormatIncludesPinnedLeftCells: _includePinnedCells,
          conditionalFormatIncludesPinnedTopCells: _includePinnedCells,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        formConfiguration: GridSheetFormConfiguration(
          viewMode:
              _formView ? GridSheetViewMode.form : GridSheetViewMode.table,
        ),
        conditionalFormatRules: [_rowRule, _columnRule, _cellRule],
        onLoaded: (event) {
          gridManager = event.gridManager;
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['PRODUCT', 'CATEGORY', 'PRICE', 'STOCK', 'RESTOCK'];
    const titles = ['Product', 'Category', 'Price', 'Stock', 'Restock by'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.integer(),
      GridSheetColumnType.datetime(),
    ];
    const widths = [160.0, 100.0, 100.0, 100.0, 200.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        pinnedLeft: i == 0,
        textAlign: types[i].kind == GridSheetColumnKind.text
            ? TextAlign.left
            : TextAlign.right,
      );
    });
  }

  List<GridSheetRow> _rows() {
    // Restock dates relative to today, so the "Restock overdue" rule always
    // has some past and some future dates to tell apart.
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime inDays(int days) => today.add(Duration(days: days));
    final raw = [
      ['Wireless Mouse', 'Electronics', 24.99, 120, inDays(14)],
      ['Standing Desk', 'Furniture', 349.00, 8, inDays(-5)],
      ['Notebook Pack', 'Stationery', 6.50, 300, inDays(30)],
      ['Mechanical Keyboard', 'Electronics', 89.99, 15, inDays(-1)],
      ['Office Chair', 'Furniture', 210.00, 40, inDays(3)],
      ['Desk Lamp', 'Furniture', 32.75, 6, inDays(-12)],
      ['4K Monitor', 'Electronics', 289.00, 22, inDays(7)],
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

  // Rules are removed by equality, not name, so two rules on the same
  // column (e.g. the STOCK text-only and stock-levels rules) toggle
  // independently.
  Future<void> _toggleRule(
    GridSheetConditionalFormatRule rule,
    bool currentlyOn,
    void Function(bool) setOn,
  ) async {
    final rules = List<GridSheetConditionalFormatRule>.from(
      gridManager.formatting.rules,
    );

    if (currentlyOn) {
      rules.remove(rule);
      status.value = 'updateConditionalFormatRules(): "${rule.name}" removed';
    } else {
      rules.add(rule);
      status.value = 'updateConditionalFormatRules(): "${rule.name}" added';
    }

    await gridManager.formatting.setRules(rules);

    setState(() => setOn(!currentlyOn));
  }

  Future<void> _cyclePriceLimit() async {
    final previous = _cellRule;
    _priceLimitIndex = (_priceLimitIndex + 1) % _priceLimits.length;
    final limit = _priceLimits[_priceLimitIndex];
    final next = _priceRule(limit);

    if (_cellRuleOn) {
      // Replace the rule where it sits, keeping its priority.
      final rules = [
        for (final rule in gridManager.formatting.rules)
          rule == previous ? next : rule,
      ];
      await gridManager.formatting.setRules(rules);
    }
    setState(() => _cellRule = next);
    status.value = 'updateConditionalFormatRules(): price rule is now '
        'PRICE > $limit${_cellRuleOn ? '' : ' (turn it on to see it)'}';
  }

  Future<void> _reversePriority() async {
    final rules = gridManager.formatting.rules.reversed.toList();
    await gridManager.formatting.setRules(rules);
    status.value = 'updateConditionalFormatRules(): priority reversed — '
        'now ${rules.map((r) => r.name).join(' > ')}';
  }

  Future<void> _reapplyRules() async {
    final changed =
        await gridManager.formatting.setRules(gridManager.formatting.rules);
    status.value = 'updateConditionalFormatRules(same rules): re-applied '
        '(rules changed: $changed)';
  }

  Future<void> _clearAllRules() async {
    await gridManager.formatting.clear();
    setState(() {
      _rowRuleOn = false;
      _columnRuleOn = false;
      _cellRuleOn = false;
      _stopIfTrueOn = false;
      _wholeColumnRuleOn = false;
      _rowStateRuleOn = false;
      _columnIndexRuleOn = false;
      _crossColumnRuleOn = false;
      _textOnlyRuleOn = false;
      _stockLevelsRuleOn = false;
      _restockOverdueRuleOn = false;
      _noExpressionRuleOn = false;
    });
    status.value = 'clearConditionalFormatRules(): all rules removed';
  }

  Future<void> _togglePinFirstRow(bool pin) async {
    if (pin) {
      await gridManager.rows.pinTo(1, 0);
    } else {
      await gridManager.rows.unpinAll();
    }
    setState(() => _pinFirstRow = pin);
    status.value = pin
        ? 'pinRowsTo(1, 0): first row pinned — formatted only with '
            '"Include pinned" on'
        : 'clearPinRows(): first row unpinned';
  }

  Future<void> _toggleRowStateRule(bool enable) async {
    final rules = List<GridSheetConditionalFormatRule>.from(
      gridManager.formatting.rules,
    );

    rules.removeWhere((rule) => rule.name == _rowStateRule.name);

    if (enable) {
      rules.insert(0, _rowStateRule);

      status.value = 'updateConditionalFormatRules(): '
          '"${_rowStateRule.name}" added at priority 0 with stopIfTrue: true — '
          'outranks and blocks the value-based rules below for any row not in '
          'the "existing" state';
    } else {
      status.value = 'updateConditionalFormatRules(): '
          '"${_rowStateRule.name}" removed';
    }

    await gridManager.formatting.setRules(rules);

    setState(() => _rowStateRuleOn = enable);
  }

  Future<void> _toggleStopIfTrue(bool enable) async {
    final rules = List<GridSheetConditionalFormatRule>.from(
      gridManager.formatting.rules,
    );

    rules.removeWhere((rule) => rule.name == _stopIfTrueRule.name);

    if (enable) {
      rules.insert(0, _stopIfTrueRule);

      status.value = 'updateConditionalFormatRules(): '
          '"${_stopIfTrueRule.name}" added at priority 0 with stopIfTrue: true — '
          'blocks LowStockRow\'s text style from filling the gap';
    } else {
      status.value = 'updateConditionalFormatRules(): '
          '"${_stopIfTrueRule.name}" removed — LowStockRow\'s bold red text '
          'shows again';
    }

    await gridManager.formatting.setRules(rules);

    setState(() => _stopIfTrueOn = enable);
  }

  Future<void> _insertRow() async {
    _newRowCount++;
    final row = GridSheetRow(
      key: ValueKey('row_new_$_newRowCount'),
      index: gridManager.rows.count,
      data: ['New Item $_newRowCount', 'Electronics', 0.0, 0, null],
      state: GridSheetRowState.inserted,
      height: Constants.rowHeight,
    );
    await gridManager.rows.insert([row]);
    status.value = 'insertRows(): added "${row.data[0]}" (_row_state: '
        'inserted)';
  }

  Future<void> _deleteSelectedRows() async {
    final keys = gridManager.selection.rowKeys;
    if (keys.isEmpty) {
      showDemoSnackBar(context, 'Select one or more rows first');
      return;
    }
    await gridManager.rows.delete(keys);
    status.value = 'deleteRows(): marked ${keys.length} row(s) '
        'deleted (_row_state: deleted)';
  }

  void _showStyleMap() {
    final styleMap = gridManager.formatting.styles(
      includePinnedBands: {GridSheetPinnedRowBand.top},
    );
    showDemoDialog(
      context,
      'conditionalFormattingStyles()',
      styleMap.isEmpty
          ? 'No cells currently have conditional formatting applied.'
          : styleMap.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
    );
    status.value =
        'conditionalFormattingStyles(): ${styleMap.length} formatted cell(s)';
  }
}
