# Conditional editability

`GridSheetColumn.conditionalEditExpression` decides, cell by cell, whether a
column can be edited, from the values in the same row: a discount editable
only on approved orders, notes locked once an order is rejected. The rule
updates as soon as the values it reads change.

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
GridSheetColumn(
  key: const ValueKey('discount'),
  index: 3,
  name: 'DISCOUNT',
  title: 'Discount %',
  type: const GridSheetColumnType.double(),
  conditionalEditExpression: 'STATUS == "Approved"',
),
```

A Discount cell can be edited only in rows whose `STATUS` is `"Approved"`.

---

## Configuration

| Property | Default | Meaning |
| --- | --- | --- |
| `GridSheetColumn.conditionalEditExpression` | `null` | An expression evaluated for each cell of the column; the cell can be edited only where it's `true`. `null` (or blank) leaves the column's editability to `editable` alone. |
| `GridSheetColumn.editable` | `true` | Must be `true` for the expression to matter: a column with `editable: false` is read-only whatever the expression says. |
| `GridSheet.evaluator` | `GridSheetExpressionEvaluator()` | Evaluates the expressions. See [Customization](#customization). |

---

## Behavior

### What the expression can use

The same names as conditional formatting:

| Name | Value |
| --- | --- |
| Any column's `name` | That column's value in the row. |
| `_cell_value` | The value of the cell being checked. |
| `_column_name` / `_column_index` | That cell's column. |
| `_row_state` | `"existing"`, `"inserted"`, `"modified"` or `"deleted"`. |
| `_today` | Midnight today, as a date. |

With comparison (`==`, `!=`, `>`, `<`, `>=`, `<=`), logical (`&&`, `||`,
`!`) and arithmetic operators:

```dart
'STATUS == "Approved"'
'STATUS != "Rejected"'
'AMOUNT > 1000 && CUSTOMER_TYPE == "Premium"'
'_row_state == "inserted"'          // only new rows
'DUE >= _today'                     // only rows not past due
```

Only `true` allows editing; anything else (`false`, `null`, an error) makes
the cell read-only.

### When it's checked

- Every time the cell is drawn, so a cell locks or unlocks as soon as a
  value it reads changes, in the same row, by typing or by the API.
- On **every write**, not only typing: `cells.update`, `updateAll`, paste,
  fill, autofill, find-and-replace and undo all skip a cell whose
  expression isn't `true`.

A read-only cell shows its value as text and can still be selected and
copied.

---

## Runtime API

There's no API on `gridManager` for the expression; it's part of the
column. Change it by passing new `columns`, or a copy made with
`column.copyWith(conditionalEditExpression: ...)`.

Changing the values it reads does take effect at once:

```dart
// Unlock Discount on every row.
gridManager.cells.updateAll([
  for (final row in gridManager.rows.all)
    GridSheetCellUpdate(rowKey: row.key, columnKey: statusKey, value: 'Approved'),
]);
```

---

## Events

None of its own. A write a locked cell refuses fires no
`onCellValueChanged`.

---

## Customization

`GridSheet.evaluator` evaluates every `conditionalEditExpression` (and
every conditional format rule). Implement `GridSheetEvaluator` to add your
own names or logic, and delegate the rest:

```dart
class PermissionEvaluator implements GridSheetEvaluator {
  PermissionEvaluator(this.user);
  final User user;
  static const _default = GridSheetExpressionEvaluator();

  @override
  dynamic evaluate(String expression, Map<String, dynamic> context) {
    if (expression == 'canEdit') return user.isAdmin || context['OWNER'] == user.id;
    return _default.evaluate(expression, context);
  }
}

GridSheet(evaluator: PermissionEvaluator(currentUser), ...)
```

To show which cells are locked, add a conditional format rule with the
opposite expression; see [Conditional formatting](conditional-format.md).

---

## Limitations

- **No feedback on a refused write.** An API write to a locked cell is
  skipped silently. Check the expression's inputs first if you need to
  know.
- **`editable: false` always wins.** The expression can only narrow a
  column that's editable.

---

## See also

- [Column types](column-types.md): `editable` and `hasTextController`
- [Conditional formatting](conditional-format.md): the same expressions
- [Cell operations](cell-operations.md)
