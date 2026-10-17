# Custom cells

`GridSheet.cellBuilder` lets you draw any cell yourself: data cells,
headers, filter fields, index cells and the select-all corner. Return a
widget to replace the built-in one, or `null` to keep it. Group headers and
column-group bands have builders of their own.

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
  cellBuilder: (cell) {
    if (cell.kind == GridSheetCellKind.row && cell.column.name == 'STATUS') {
      final status = '${cell.row!.data[cell.column.index]}';
      return Chip(label: Text(status));
    }
    return null; // every other cell keeps its built-in look
  },
)
```

---

## Configuration

| Option | Called for |
| --- | --- |
| `GridSheet.cellBuilder` | Every cell of the table: `GridSheetCellBuilder = Widget? Function(GridSheetCellContext cell)`. |
| `GridSheetRowGroupingConfiguration.cellBuilder` | Row-group header and summary cells. See [Row grouping](row-grouping.md). |
| `GridSheetColumnGroupingConfiguration.cellBuilder` | Column-group bands. See [Column grouping](column-grouping.md). |

### Cell kinds

`cell.kind` says which cell is being built:

| `GridSheetCellKind` | The cell | `cell.row` |
| --- | --- | --- |
| `row` | A data cell. | The row |
| `header` | A column header. | `null` |
| `filter` | A column's filter field (with `showColumnFilters`). | `null` |
| `indexing` | An index cell. | The row |
| `selectAll` | The index column's header, where the Select All checkbox goes. Only built when that checkbox would show. | `null` |

### GridSheetCellContext

| Member | Description |
| --- | --- |
| `context` | The `BuildContext`, for themes and dialogs. |
| `kind` | The cell kind, above. |
| `column` | The cell's column. |
| `row` / `rowIndex` | The row, and its displayed number (as in the index column); `null` for headers, filters and select-all. |
| `columnIndex` | `column.index`: the column's slot in `row.data`. |
| `gridManager` | The grid, for reading and changing it. |
| `textStyle` | The style the cell would use, conditional formatting included. Data cells only. |
| `defaultCellWidget` | The built-in widget, to wrap or reuse. Data cells only. |
| `filterController` | The filter field's text, kept in step with the active filter. Filter cells only. |
| `onFilterChanged(filters)` | Applies filters, like `filters.add`. Filter cells only. |
| `onToggleSelectAllRows(bool)` | Selects or deselects every row. Select-all cell only. |
| `onToggleSelectAllColumns(bool)` | Selects or deselects every visible column; `null` without `enableColumnSelection`. Select-all cell only. |
| `onToggleRowExpansion()` / `isRowExpanded` | Opens or closes the row's expansion panel. Cells with a row, while row expansion is on. |
| `columnSortState` | The column's sort, if sorted. Header cells only. |
| `evaluator` | The grid's expression evaluator. |

---

## Behavior

- **`null` keeps the built-in cell.** Return a widget only for the cells
  you want to change.
- **Selection still works.** A tap on your data cell selects it as usual,
  even where your widget handles the tap too. See [Selection](selection.md).
- **Editing is yours.** A custom data cell doesn't get the built-in text
  field. To change values, write them through the API (below).
- **A throwing builder falls back.** If `cellBuilder` throws, the grid uses
  its own widget for that cell and reports the error to `onError`
  (`GridSheetErrorSource.cellBuilder`).
- **Builders run often.** Keep them cheap: no heavy work or allocations
  that could be done once.

### Writing values from a custom cell

Write through `gridManager.cells.update`, never by changing `row.data` in
place. The grid then marks the row modified, recomputes formulas, fires
`onCellValueChanged` and records the change for undo:

```dart
Checkbox(
  value: cell.row!.data[cell.column.index] == true,
  onChanged: (value) => cell.gridManager.cells.update(
    rowKey: cell.row!.key,
    columnKey: cell.column.key,
    value: value,
  ),
),
```

For a list or object value, write a **new** instance; editing the stored
one in place is invisible to the grid.

### A text field in a custom cell

Use the cell's own controller, so it stays in step with the value:

```dart
final controller = cell.gridManager.cells.controller(
  rowKey: cell.row!.key,
  columnKey: cell.column.key,
  initialText: '${cell.row!.data[cell.column.index] ?? ''}',
);
```

---

## Runtime API

There's no API on `gridManager` for cell builders: they're set on the
widget. A builder reaches the grid through `cell.gridManager`, for example
`cells.update`, `selection.containsRow`, `filters.add` and
`cursor.isRowHovered`.

---

## Events

None of their own. Writes from a custom cell fire `onCellValueChanged`, and
selections fire the selection events, as usual.

---

## Customization

### Organizing builders: IGridSheetCustomCellBuilder

For many custom cells, implement `IGridSheetCustomCellBuilder`, one method
per kind, and dispatch to it:

```dart
class MyCells implements IGridSheetCustomCellBuilder {
  @override
  Widget buildSelectAll(BuildContext context, GridSheetCellContext cell) => ...;
  @override
  Widget buildIndexes(BuildContext context, GridSheetCellContext cell) => ...;
  @override
  Widget buildHeader(BuildContext context, GridSheetCellContext cell) => ...;
  @override
  Widget buildFilter(BuildContext context, GridSheetColumn column, GridSheetCellContext cell) => ...;
  @override
  Widget buildCell(BuildContext context, GridSheetColumn column, GridSheetRow row, GridSheetCellContext cell) => ...;
}

final builder = MyCells();

cellBuilder: (cell) => switch (cell.kind) {
  GridSheetCellKind.selectAll => builder.buildSelectAll(cell.context, cell),
  GridSheetCellKind.indexing => builder.buildIndexes(cell.context, cell),
  GridSheetCellKind.header => builder.buildHeader(cell.context, cell),
  GridSheetCellKind.filter => builder.buildFilter(cell.context, cell.column, cell),
  GridSheetCellKind.row => builder.buildCell(cell.context, cell.column, cell.row!, cell),
},
```

### A custom filter

A filter cell can use any input. Keep `filterController` in step, and apply
the filter with `filters.add` (or `onFilterChanged`):

```dart
DropdownButton<String?>(
  value: cell.filterController!.text.isEmpty ? null : cell.filterController!.text,
  items: [
    const DropdownMenuItem(value: null, child: Text('All')),
    for (final v in values) DropdownMenuItem(value: v, child: Text(v)),
  ],
  onChanged: (value) {
    if (value == null) {
      cell.gridManager.filters.clear(cell.column.key);
    } else {
      cell.gridManager.filters.add({cell.column.key: [value]});
    }
  },
),
```

### Showing something only on hover

With `enableRowHover`, `gridManager.cursor.isRowHovered(rowKey)` tells a
cell whether its row is under the pointer:

```dart
if (!cell.gridManager.cursor.isRowHovered(cell.row!.key)) return const SizedBox.shrink();
return Row(children: [editButton, deleteButton]);
```

---

## Limitations

- **Text operations don't know your values.** Copy writes a value's
  `toString()`; paste, find-and-replace and `cells.clear` store text in its
  place. Parse such values yourself.
- **Custom data cells have no built-in editor.** Write values through
  `cells.update`.
- **`selectAll` is only built when the Select All checkbox would show**:
  with an index column, row selection and multi-selection on.

---

## See also

- [Column types](column-types.md): the `custom()` type
- [Dropdown cells](dropdown-cells.md)
- [Row grouping](row-grouping.md) · [Column grouping](column-grouping.md)
- [Custom wrappers](wrappers.md): wrapping rows, headers and filters
- [Selection](selection.md)
