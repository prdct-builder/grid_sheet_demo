# Conditional formatting

Conditional formatting colors rows and cells, and changes their text style,
based on their values, like Excel's "Use a formula to determine which cells
to format". Each rule has an expression such as
`STOCK < 20 ? "#FFCDD2" : null`; where it matches, the rule's background and
text style apply. Rules are kept in a priority-ordered list you can change
at runtime.

- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Behavior](#behavior)
- [Runtime API](#runtime-api)
- [Events](#events)
- [Customization](#customization)
- [Limitations](#limitations)
- [See also](#see-also)

---

## Quick start

```dart
GridSheet(
  columns: columns,
  rows: rows,
  conditionalFormatRules: [
    // Rows with low stock: red background, bold red text.
    const GridSheetConditionalFormatRule(
      name: 'low-stock',
      scope: GridSheetFormatScope.row,
      expression: 'STOCK < 20 ? "#FFCDD2" : null',
      textStyle: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
    ),
    // Only the PRICE cells over 150.
    const GridSheetConditionalFormatRule(
      name: 'PRICE',
      scope: GridSheetFormatScope.cell,
      expression: 'PRICE > 150 ? "#FFE0B2" : null',
    ),
  ],
)
```

---

## Configuration

### GridSheetConditionalFormatRule

| Property | Default | Meaning |
| --- | --- | --- |
| `name` | required | For a **cell** rule, the `name` of the column it formats. For a **row** rule, any label. |
| `scope` | `row` | `GridSheetFormatScope.row`: formats every cell of matching rows. `.cell`: formats only the matching cells of the column `name`. |
| `expression` | `null` | Where the rule matches, and with which background. `null` matches every cell the rule covers. |
| `textStyle` | `null` | The text style wherever the rule matches. |
| `stopIfTrue` | `false` | Once this rule matches a cell, lower-priority rules aren't considered for it, as Excel's "Stop If True". |

### Where rules apply

On `GridSheetConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `conditionalFormatIncludesPinnedLeftCells` / `…RightCells` | `false` | Also formats pinned columns. |
| `conditionalFormatIncludesPinnedTopCells` / `…BottomCells` | `false` | Also formats pinned rows. |

Rules are passed as `GridSheet.conditionalFormatRules`, and changed later
through `gridManager.formatting`.

---

## Behavior

### What an expression returns

| Result | Means |
| --- | --- |
| A color string, `"#RRGGBB"` or `"#AARRGGBB"` | Matches, with that background. |
| `true` | Matches with no background: only `textStyle` applies. |
| `null`, `false`, anything else | Doesn't match. |
| (no expression) | Matches every cell the rule covers. |

```dart
// A different color per value
'STOCK < 10 ? "#FFCDD2" : STOCK < 50 ? "#FFE0B2" : "#C8E6C9"'

// Text style only, no background
'STOCK >= 100'

// The whole column (cell scope), whatever the values
'"#E1F5FE"'
```

### What an expression can use

| Name | Value |
| --- | --- |
| Any column's `name` | That column's value in the row. |
| `_cell_value` | The value of the cell being formatted. |
| `_column_name` / `_column_index` | That cell's column name and index. |
| `_row_state` | `"existing"`, `"inserted"`, `"modified"` or `"deleted"`. |
| `_today` | Midnight today, as a date. |

Operators: comparison (`>`, `<`, `>=`, `<=`, `==`, `!=`), logical (`&&`,
`||`, `!`), arithmetic and the ternary `cond ? a : b`. Dates compare with
each other, with `_today` and with ISO date strings
(`RESTOCK < "2024-06-01"`).

A row rule is evaluated once per row, unless it uses `_cell_value`,
`_column_name` or `_column_index`; then it's evaluated for each cell, so
one row rule can format each column differently:

```dart
// One row rule, branching per column
'(_column_name == "STOCK" && _cell_value < 20) || '
'(_column_name == "PRICE" && _cell_value > 150) ? "#B3E5FC" : null'
```

### Priority

The rule list is in **priority order**: the first rule is the highest.
When several rules match a cell:

- For the **same** attribute (the background, or one text style property
  such as the weight), the highest-priority rule wins.
- **Different** attributes merge: one rule's background and another's bold
  text both apply.
- A rule with `stopIfTrue` blocks every lower rule for the cells it matches,
  even for attributes it doesn't set.

Scope doesn't affect priority; only list position does.

### Where rules apply

- Rules don't format pinned columns or rows unless the matching
  `conditionalFormatIncludesPinned…` option is on.
- Selection draws over formatting.
- Rules apply in the form layout too: row rules color the card, cell rules
  color their field.
- A cell rule follows its column through `columns.rename`. A cell rule
  whose `name` matches no column never applies; debug builds print a
  warning.

---

## Runtime API

`gridManager.formatting` (`GridSheetFormattingAPI`):

| Member | Description |
| --- | --- |
| `rules` | The rules, in priority order. |
| `add(rule, {atIndex})` | Adds a rule at the end (lowest priority), or at `atIndex`. |
| `setRules(rules)` | Replaces the whole list, then re-applies every rule. Returns whether the list changed. |
| `clear()` | Removes every rule. |
| `styles({columnScope, rowScope, includePinnedBands})` | The background and text style each formatted cell gets, keyed `rowKey|columnKey`. Cells no rule formats are left out. |

Rules are edited as a list: copy it, change the copy, and hand it back.

```dart
final rules = [...gridManager.formatting.rules];
rules.insert(0, rules.removeAt(2));                              // raise a rule's priority
rules.removeWhere((r) => r.scope == GridSheetFormatScope.row);   // remove row rules
await gridManager.formatting.setRules(rules);

// Re-apply the same rules, e.g. after midnight for a `_today` rule.
await gridManager.formatting.setRules(gridManager.formatting.rules);
```

`styles()` evaluates on each call; use it on demand, for example to carry
the formatting into an export:

```dart
final styles = gridManager.formatting.styles(rowScope: GridSheetRowScope.currentPage);
// {'row_3|col_status': {'bgColor': '#FFFFCDD2', 'color': '#FFB71C1C', 'fontWeight': 700}}
```

---

## Events

None. Formatting updates on its own when values, rows or rules change.

---

## Customization

- **Your own expression logic**: `GridSheet.evaluator` takes a
  `GridSheetEvaluator`, which evaluates every rule's expression (and every
  `conditionalEditExpression`). Delegate what you don't handle to
  `GridSheetExpressionEvaluator`:

  ```dart
  class MyEvaluator implements GridSheetEvaluator {
    static const _default = GridSheetExpressionEvaluator();

    @override
    dynamic evaluate(String expression, Map<String, dynamic> context) {
      if (expression == 'isVip') return vipIds.contains(context['ID']);
      return _default.evaluate(expression, context);
    }
  }
  ```

- **The pivot table** has its own rules; see
  [Pivot](pivot.md#formatting).

---

## Limitations

- **A `_today` rule changes at midnight**, but the grid doesn't notice.
  Call `setRules(gridManager.formatting.rules)` to re-apply it.
- **Deleted rows aren't shown**, so a `_row_state == "deleted"` branch never
  colors anything in the table.
- **Cell rules are matched by column `name`.** A typo, or a name that
  doesn't exist, silently formats nothing in release builds.

---

## See also

- [Conditional editability](conditional-edit.md): the same expressions, for editing
- [Fixed columns](fixed-columns.md) · [Fixed rows](fixed-rows.md)
- [Form layout](form-layout.md)
- [Data export & statistics](export-stats.md)
- [Pivot](pivot.md#formatting)
