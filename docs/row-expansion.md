# Row expansion

Row expansion opens a detail panel **below a row**, inside the grid: a
chevron in the index column expands the row to show its fields as a
label-and-field form, ready to edit. Several rows can be open at once, and
the panel can be replaced by your own widget.

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
  rowExpansionConfiguration: const GridSheetRowExpansionConfiguration(enabled: true),
)
```

---

## Configuration

`GridSheet.rowExpansionConfiguration` takes a
`GridSheetRowExpansionConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `enabled` | `false` | Shows the expand chevron in the index column. |
| `panelHeight` | `300` | The panel's height. A taller form scrolls inside it. |
| `animationDuration` | `200 ms` | The open and close animation. |
| `backgroundColor` | `null` (the row color) | The panel's background. |
| `icon` | `Icons.chevron_right` | The chevron; it rotates as the row opens. |
| `showOnlyEditableColumns` | `true` | Shows only editable columns in the built-in form. `false` shows every visible column. |

On `GridSheet`:

| Option | Meaning |
| --- | --- |
| `rowExpandedBuilder` | Replaces the built-in form with your own panel. |
| `rowStateIndicatorBuilder` | Its icon and color also mark edited fields in the form. |

---

## Behavior

- **Tap the chevron** next to a row's number to open its panel; tap again
  to close it. Any number of rows can be open.
- The panel spans the grid's full width (pinned and scrollable columns
  alike), and pushes the rows below it down.
- The built-in form lists the row's fields as label and editor pairs,
  using each column's type: text fields, dropdowns, read-only text. Edits
  write the cells like any edit: change tracking, formulas,
  `onCellValueChanged` and undo all apply.
- Fields that were edited show the modified-field icon: `Icons.edit` by
  default, or the icon and color from `rowStateIndicatorBuilder`.
- Pinned rows expand like any other row.
- An open panel stays open through edits; it follows its row by key.

---

## Runtime API

There's no API on `gridManager` to open or close panels. A custom cell can
toggle its row's panel: when expansion is on, every cell with a row gets
`cell.onToggleRowExpansion` and `cell.isRowExpanded`:

```dart
cellBuilder: (cell) {
  if (cell.kind != GridSheetCellKind.row || cell.column.name != 'STAGE') return null;
  return Row(children: [
    IconButton(
      icon: Icon(cell.isRowExpanded == true ? Icons.expand_less : Icons.expand_more),
      onPressed: cell.onToggleRowExpansion,
    ),
    Expanded(child: cell.defaultCellWidget!),
  ]);
},
```

---

## Events

No events of its own. Edits in the panel fire `onCellValueChanged`.

---

## Customization

### Your own panel

`GridSheet.rowExpandedBuilder` builds the panel for each open row, with the
row, the columns and the grid. Save edits through `gridManager`:

```dart
rowExpandedBuilder: (context, row, columns, gridManager) => Padding(
  padding: const EdgeInsets.all(12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('${row.data[0]}', style: Theme.of(context).textTheme.titleMedium),
      Text('Notes: ${row.data[5] ?? '—'}'),
      TextButton(
        onPressed: () => gridManager.cells.update(
            rowKey: row.key, columnKey: stageKey, value: 'Hired'),
        child: const Text('Mark hired'),
      ),
    ],
  ),
),
```

### Hiding the built-in chevron

A `cellBuilder` that returns a widget for `GridSheetCellKind.indexing`
replaces the index cell, chevron included. Pair it with a toggle in another
column (above) to move expansion there.

---

## Limitations

- **The built-in chevron lives in the index column.** With no index column,
  use a custom cell with `onToggleRowExpansion` to expand rows.
- **No API to open or close panels**, or to read which are open, outside a
  cell builder.
- **The panel has a fixed height** (`panelHeight`); content scrolls inside
  it.

---

## See also

- [Index column](index-column.md): the chevron's column, and row state marks
- [Custom cells](custom-cells.md)
- [Form layout](form-layout.md): the form view of the whole grid
- [Row separators](row-separator.md): other content below rows
