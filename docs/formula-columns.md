# Formula columns

A **formula column** holds spreadsheet-style formulas such as `=QTY * PRICE`
or `=SUM(D1:D5)`. Each cell shows the computed result, recomputes when a
cell it depends on changes, and shows its formula while being edited.

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
  columns: [
    GridSheetColumn(key: const ValueKey('qty'), index: 0, name: 'QTY', title: 'Qty',
        type: const GridSheetColumnType.integer()),
    GridSheetColumn(key: const ValueKey('price'), index: 1, name: 'PRICE', title: 'Price',
        type: const GridSheetColumnType.double()),
    GridSheetColumn(key: const ValueKey('total'), index: 2, name: 'TOTAL', title: 'Total',
        type: const GridSheetColumnType.formula()),
  ],
  rows: [
    GridSheetRow(key: const ValueKey('r0'), index: 0, data: [4, 65.0, '=QTY * PRICE']),
    GridSheetRow(key: const ValueKey('r1'), index: 1, data: [2, 210.0, '=QTY * PRICE']),
  ],
)
```

A value starting with `=` in a formula column is a formula; anything else is
a plain value.

---

## Configuration

| Option | Default | Meaning |
| --- | --- | --- |
| `GridSheetColumnType.formula({showFormulaOnFocus})` | `showFormulaOnFocus: true` | Makes the column a formula column. With `showFormulaOnFocus`, a cell shows its formula text while being edited, and its result otherwise; with `false`, it always shows the result. |
| `GridSheet.evaluator` | `GridSheetExpressionEvaluator()` | The expression evaluator used for conditional formatting and conditional editing. Formulas use the built-in formula engine. |

---

## Behavior

### References

| Write | Refers to |
| --- | --- |
| `QTY` (a column name) | That column, in the **same row**. |
| `B` (a column letter) | That column, in the same row. |
| `QTY3` (name + row number) | That column in row 3. |
| `B3` (A1 notation) | Column B, row 3. |
| `D1:D5` / `QTY1:QTY5` | The cells from row 1 to row 5 of that column. |
| `D:D` / `QTY:QTY` / `A:C` | Whole columns, every row. |

Column names are uppercase letters and underscores: `QTY`, `UNIT_PRICE`.
Column letters count the grid's
columns from the left: `A` is the first. Row numbers count the scrollable
rows from the top: `1` is the first.

### When rows move

A row-numbered reference keeps pointing at the **same row** when rows are
sorted, reordered, inserted or deleted, as in a spreadsheet. The row
numbers in the formula are rewritten to follow it, and the focused cell
shows the new text:

| Formula | Change | Becomes |
| --- | --- | --- |
| `=B1 * C1` in the first row | Its row moves to second place | `=B2 * C2` |
| `=SUM(D1:D3)` below three rows | A row is inserted inside the range | `=SUM(D1:D4)` |
| `=SUM(D1:D3)` below three rows | The range's first row is deleted | `=SUM(D1:D2)` |
| `=B1 * 2` in another row | Row 1 is deleted | `=#REF! * 2`, shown as `#REF!` |

Column names without a row number (`=QTY * UNIT_PRICE`) always use the
formula's own row, and whole-column ranges always cover every row, so
neither needs rewriting.

### Operators

| Operators | Meaning |
| --- | --- |
| `+` `-` `*` `/` | Arithmetic, with the usual precedence and parentheses. |

Comparison, text-joining and logical operators aren't supported in
formulas yet; see [Limitations](#limitations). Use the functions below
instead, for example `CONCAT` to join text and `AND` / `OR` / `NOT` with
`IF`.

### Functions

| Kind | Functions |
| --- | --- |
| Aggregate | `SUM`, `AVERAGE` (`AVG`), `MIN`, `MAX`, `COUNT`, `MEDIAN`, `MODE`, `STDEV` |
| Math | `ABS`, `ROUND`, `CEILING` (`CEIL`), `FLOOR`, `MOD`, `POWER` (`POW`), `SQRT` |
| Logic | `IF`, `IFERROR`, `AND`, `OR`, `NOT`, `ISBLANK`, `ISNUMBER`, `ISTEXT` |
| Text | `CONCAT`, `LEFT`, `RIGHT`, `MID`, `LEN`, `LOWER`, `UPPER`, `TRIM` |
| Date | `TODAY`, `NOW`, `YEAR`, `MONTH`, `DAY` |

```dart
'=IF(DISCOUNTED, PRICE * 0.9, PRICE)'
'=ROUND(PRICE * 1.18, 2)'
'=IFERROR(TOTAL / QTY, 0)'
'=SUM(D1:D5)'
```

### Recalculation

- Changing a cell recomputes the formulas that depend on it, and the ones
  that depend on those, and nothing else.
- Formulas recompute for the **current page** right away; formulas on
  other pages are brought up to date when shown, or read through
  `cells.value` and `data.toMaps` / `toLists` / `toCsv`.
- With `cellChangeFlashEnabled`, recomputed cells flash. See
  [Column animation](column-animation.md).

### Editing

- With `showFormulaOnFocus`, a focused formula cell shows its formula; edit
  it and leave the cell to apply it.
- Typing a value that doesn't start with `=` replaces the formula with that
  value.
- Undo restores a cell's formula, not only its result.

### Errors

A formula that can't be computed shows an error value instead of a result:

| Value | Cause |
| --- | --- |
| `#ERROR!` | The formula doesn't parse, or a function got bad arguments. |
| `#DIV/0!` | Division by zero. |
| `#REF!` | A reference to a cell that doesn't exist, or to a row that was deleted. |
| `#CIRCULAR!` | The formula depends on itself, directly or through others. |

Failures are also reported to `GridSheet.onError` with
`GridSheetErrorSource.formulaEvaluation`. A formula that simply doesn't
parse is only printed to the debug console when there's no `onError`.

### Sorting and filtering

Sorting and filtering use the computed results, so a filter like
`TOTAL = 260` matches the cells showing 260.

---

## Runtime API

`gridManager.formulas` (`GridSheetFormulasAPI`):

| Member | Description |
| --- | --- |
| `of({rowKey, columnKey})` | The cell's formula text, or `null` when it holds a plain value. |
| `evaluate(formula)` | Evaluates a formula of literal values: `evaluate('=SUM(1,2,3)')` is `6`. |
| `refreshAll()` | Recomputes every out-of-date formula in the grid, not just the current page. Call it before reading `rows.all` data directly. |

To set a formula, write its text like any value:

```dart
gridManager.cells.update(rowKey: rowKey, columnKey: totalKey, value: '=QTY * PRICE');
gridManager.formulas.of(rowKey: rowKey, columnKey: totalKey); // '=QTY * PRICE'
gridManager.cells.value(rowKey, totalKey);                    // the result
```

`data.toCsv(includeFormulas: true)` exports the formula text instead of the
results. See [Data export & statistics](export-stats.md).

---

## Events

No events of their own. Writing a formula fires `onCellValueChanged` with
the computed result as `newValue`, and a recomputed dependent fires it too.
Errors go to `onError` (`GridSheetErrorSource.formulaEvaluation`).

---

## Customization

- **Showing the result while editing**: `GridSheetColumnType.formula(showFormulaOnFocus: false)`.
- **Formatting results**: use a `cellBuilder` (see
  [Custom cells](custom-cells.md)) or conditional formatting (see
  [Conditional formatting](conditional-format.md)); the stored result is a
  plain number or text.

---

## Limitations

- **No comparison, text-joining or logical operators.** `>`, `<`, `==`,
  `!=`, `&`, `&&` and `||` aren't evaluated in formulas: `=IF(QTY > 5, …)`
  gives `#ERROR!`. Use functions instead (`CONCAT`, `AND`, `OR`, `NOT`).
- **Ranges after a sort.** A range follows its rows; when a sort scatters
  them, it covers the span from the first to the last of them. Whole-column
  ranges (`D:D`) are unaffected.
- **Pinned rows aren't in the formula engine.** A formula in a pinned row
  isn't computed, and formulas can't refer to pinned rows. See
  [Fixed rows](fixed-rows.md).
- **Uppercase names only.** References are read in uppercase: a column
  named `qty` can't be referenced; name it `QTY`.

---

## See also

- [Column types](column-types.md)
- [Cell operations](cell-operations.md): writing values, undo
- [Conditional formatting](conditional-format.md) · [Conditional editability](conditional-edit.md): expressions
- [Data export & statistics](export-stats.md): exporting formulas
