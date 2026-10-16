# Column types

Every column has a **type** that decides how its values are stored, edited,
parsed, sorted and filtered: text, integer, double, boolean, date and time,
dropdown, formula, or custom. This page covers the types and the column
properties that shape how a column looks and edits.

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
    GridSheetColumn(key: const ValueKey('name'), index: 0, name: 'name', title: 'Name'),
    GridSheetColumn(
      key: const ValueKey('age'),
      index: 1,
      name: 'age',
      title: 'Age',
      type: const GridSheetColumnType.integer(),
      textAlign: TextAlign.right,
    ),
    GridSheetColumn(
      key: const ValueKey('dept'),
      index: 2,
      name: 'dept',
      title: 'Department',
      type: const GridSheetColumnType.dropdown(options: ['Engineering', 'Sales']),
    ),
  ],
  rows: [
    GridSheetRow(key: const ValueKey('r0'), index: 0, data: ['Ava', 29, 'Engineering']),
  ],
)
```

A column without a `type` is text. `index` is the column's slot in each
row's `data` list.

---

## Configuration

### The types

`GridSheetColumn.type` takes one of these constructors:

| Constructor | Stores | Editor | Typed text is stored as |
| --- | --- | --- | --- |
| `GridSheetColumnType.text()` | `String` | Text field | The text |
| `GridSheetColumnType.integer()` | `int` | Text field; digits and `-` only; numeric keyboard | `int`, if it parses |
| `GridSheetColumnType.double()` | `double` | Text field; digits, `-` and `.` only; decimal keyboard | `double`, if it parses |
| `GridSheetColumnType.boolean()` | `bool` | Text field | `true` / `false`, if it parses |
| `GridSheetColumnType.datetime()` | `DateTime` | Text field | `DateTime`, if it parses as ISO 8601 (`2024-03-14`, `2024-03-14T09:30`) |
| `GridSheetColumnType.dropdown(options: [...])` | `String` | Popup menu of `options` | The chosen option |
| `GridSheetColumnType.formula({showFormulaOnFocus = true})` | The computed result | Text field showing the formula | A formula when it starts with `=`; see [Formula columns](formula-columns.md) |
| `GridSheetColumnType.custom()` | Anything | Text field, or your own cell | The text; a custom column can't convert text back |

Text that doesn't parse for its type is kept as the text, and blank text is
stored as `null`.

### Column properties

All on `GridSheetColumn`. Only `key`, `index`, `name` and `title` are
required.

| Property | Default | Meaning |
| --- | --- | --- |
| `key` | — | A stable `ValueKey<String>` the API addresses the column by. |
| `index` | — | The column's slot in each row's `data`. |
| `name` | — | The column's name in expressions, filters sent to a server, CSV headers and data maps. |
| `title` | — | The header text. |
| `type` | `text()` | The column type, above. |
| `description` | `null` | A tooltip on the header, for abbreviated titles. |
| `width` | `120` | Width in logical pixels. |
| `textAlign` | `TextAlign.start` | Alignment of the header and cells. Numbers usually read better right-aligned. |
| `editable` | `true` | Whether cells can be edited. `false` makes the column read-only, whatever its type. |
| `hasTextController` | `true` | Whether cells are edited through a text field. `false` shows the value as read-only text, for columns edited another way (a dropdown, or your own widget). |
| `sortable` | `false` | Whether tapping the header sorts. See [Sorting](sorting.md). |
| `resizable` | `false` | Whether the header edge can be dragged, and whether `columns.setWidths` may resize it. |
| `visible` | `true` | Whether the column is shown. See [Column operations](column-operations.md). |
| `pinnedLeft` / `pinnedRight` | `false` | Pins the column to a side. See [Fixed columns](fixed-columns.md). |
| `wrap` | `false` | Wraps long text instead of truncating it with an ellipsis. |
| `showOverflowTooltip` | `false` | Shows the full value on hover when it's cut off. |
| `maxStretchWidth` | `null` | The most this column grows under `stretchColumnsToFillWidth`. |
| `filterHint` | `'Search..'` | The hint in the column's filter field. See [Filters](filters.md). |
| `conditionalEditExpression` | `null` | An expression deciding per cell whether it can be edited. See [Conditional editability](conditional-edit.md). |

---

## Behavior

### Editing and parsing

What the user types is converted by the column's type when it's stored:

```dart
// In an integer column:
'42'   → 42      (int)
' 42 ' → 42      (trimmed)
'4x2'  → can't be typed: only digits and '-' are accepted
''     → null

// In a datetime column:
'2024-03-14'       → DateTime(2024, 3, 14)
'14/03/2024'       → '14/03/2024' (kept as text: not ISO 8601)
```

The same conversion applies to paste (`cells.pasteText`) and
find-and-replace (`cells.findAndReplace`). `cells.update` and
`cells.updateAll` store the value exactly as given, so pass the type the
column holds (`42`, not `'42'`).

### Sorting

Sorting follows the stored values, not the type: numbers sort before dates,
dates before booleans, booleans before text, and blank values last. Text
sorts case-insensitively and naturally (`item 9` before `item 10`), and text
that holds a number (`'10'`) sorts as that number. See [Sorting](sorting.md).

### Filtering

Integer and double columns filter by number (`>10`, `5-20`), date and time
columns by date, and everything else by text. See [Filters](filters.md).

### Checking a type

Compare a column's **kind**, not its type, since `==` on a type also
compares its settings (a dropdown's options, a formula's
`showFormulaOnFocus`):

```dart
if (column.type.kind == GridSheetColumnKind.integer) { ... }

switch (column.type.kind) {
  case GridSheetColumnKind.text:
  case GridSheetColumnKind.dropdown:
    ...
}
```

A dropdown's options are also readable as `column.dropdownOptions`, and a
formula column's setting as `column.showFormulaOnFocus`.

---

## Runtime API

A column's type is set when it's defined. To change it, replace the column:
pass new `columns` to the `GridSheet`, or edit a copy with
`column.copyWith(type: ...)`.

Columns are read through `gridManager.columns`:

```dart
final column = gridManager.columns.find(const ValueKey('age'));
column?.type.kind; // GridSheetColumnKind.integer
```

Values are read and written through `gridManager.cells`. `update` stores
what you pass as is, so pass the column's type:

```dart
gridManager.cells.update(rowKey: rowKey, columnKey: ageKey, value: 42);
gridManager.cells.value(rowKey, ageKey); // 42
```

See [Cell operations](cell-operations.md) and [Column operations](column-operations.md).

---

## Events

No events of its own. An edit in any column fires
`GridSheet.onCellValueChanged`, with `oldValue` and `newValue` as stored:
typed (`42`, not `'42'`) for an integer column. See
[Cell operations](cell-operations.md).

---

## Customization

- **Your own cell widget.** `GridSheet.cellBuilder` replaces how any cell
  is drawn, and is how a `custom()` column usually gets its look. See
  [Custom cells](custom-cells.md).
- **A dropdown's options** come from the type:
  `GridSheetColumnType.dropdown(options: [...])`. See
  [Dropdown cells](dropdown-cells.md).
- **Number and date display.** Values show as their `toString()`. Format
  them with a `cellBuilder`, or store preformatted text in a text column.

---

## Limitations

- **Booleans show as text.** A boolean column shows `true` / `false` and
  edits through a text field. For a checkbox, build one with
  `cellBuilder`.
- **Dates show as `DateTime.toString()`** (`2024-03-14 00:00:00.000`), and
  only ISO 8601 text parses. A date stored as text (`'2024-03-14'`) stays
  text until it's edited.
- **Custom values don't round-trip through text.** Copying a list value
  copies its text, and pasting that text stores a `String`.
- **`hasTextController: false` makes text cells read-only.** Only dropdown
  cells and your own cells stay editable without one.

---

## See also

- [Formula columns](formula-columns.md)
- [Dropdown cells](dropdown-cells.md)
- [Custom cells](custom-cells.md)
- [Conditional editability](conditional-edit.md)
- [Cell operations](cell-operations.md)
- [Sorting](sorting.md) · [Filters](filters.md)
