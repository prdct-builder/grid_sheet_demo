# Dropdown cells

A **dropdown column** limits its cells to a fixed list of options. Each cell
shows its value with an arrow; a tap opens a menu of the options, and the
choice is written like any edit.

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
  key: const ValueKey('status'),
  index: 1,
  name: 'STATUS',
  title: 'Status',
  type: const GridSheetColumnType.dropdown(
    options: ['Open', 'In Progress', 'Resolved', 'Closed'],
  ),
),
```

---

## Configuration

| Property | Default | Meaning |
| --- | --- | --- |
| `GridSheetColumnType.dropdown(options: [...])` | required `options` | Makes the column a dropdown with these options, in this order. |
| `GridSheetColumn.editable` | `true` | `false` shows the value as plain text, with no arrow and no menu. |
| `GridSheetColumn.conditionalEditExpression` | `null` | Locks the dropdown per row. See [Conditional editability](conditional-edit.md). |
| `GridSheetColumn.hasTextController` | `true` | Not used by dropdown cells; set it to `false` to skip creating text controllers for the column. |

`column.dropdownOptions` reads a column's options back.

---

## Behavior

- **Tap the dropdown to open the menu.** The menu opens below the cell,
  between 150 and 320 px wide, shows up to six options before scrolling,
  and checks the current value.
- **Choosing an option writes it** like an edit: the row becomes modified,
  formulas recompute, `onCellValueChanged` fires and the change can be
  undone. Choosing the current value changes nothing.
- **Selection.** A tap on the dropdown opens it without selecting the cell;
  a tap on the cell's outer padding selects it. See
  [Selection](selection.md#where-a-tap-selects).
- **Read-only dropdowns** (`editable: false`, an expression that's not
  `true`, or no options) show plain text.
- **Values outside the options** (from data or the API) are shown as they
  are, and stay until the user picks an option.
- Sorting and filtering treat dropdown values as text.

---

## Runtime API

Dropdown values are plain strings, read and written through
`gridManager.cells`:

```dart
gridManager.cells.update(rowKey: rowKey, columnKey: statusKey, value: 'Resolved');
gridManager.cells.value(rowKey, statusKey); // 'Resolved'

final column = gridManager.columns.find(statusKey);
column?.dropdownOptions; // ['Open', 'In Progress', 'Resolved', 'Closed']
```

The API doesn't check values against the options. To change the options,
replace the column (new `columns`, or
`column.copyWith(type: const GridSheetColumnType.dropdown(options: [...]))`).

---

## Events

No events of its own. Choosing an option fires `onCellValueChanged`.

---

## Customization

For a different editor (a searchable picker, chips, a segmented control),
build the cell yourself with `GridSheet.cellBuilder` and write the choice
with `cells.update`. See [Custom cells](custom-cells.md). A custom filter
cell can offer the options as a dropdown too.

---

## Limitations

- **One value per cell.** There's no multi-select dropdown.
- **The options are fixed per column**, not per row.
- **The API accepts any value**, not only the options.

---

## See also

- [Column types](column-types.md)
- [Conditional editability](conditional-edit.md)
- [Custom cells](custom-cells.md)
- [Selection](selection.md)
