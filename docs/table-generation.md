# Table generation

Table generation builds a **blank spreadsheet** from a column count and a
row count, without `columns` or `rows` lists. Columns are named A, B, C…
like a spreadsheet, and rows start empty. Builders can customize each
generated column (type, width) or row (height, starting data).

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
  columns: const [],
  rows: const [],
  dynamicGenerationConfiguration: const GridSheetDynamicGenerationConfiguration(
    columnsCount: 8,
    rowsCount: 50,
  ),
)
```

---

## Configuration

`GridSheet.dynamicGenerationConfiguration` (`null` by default, meaning use
`columns` and `rows`):

| Option | Default | Meaning |
| --- | --- | --- |
| `columnsCount` | `5` | How many columns to generate. |
| `rowsCount` | `10` | How many rows to generate. |
| `columnBuilder` | `null` | `(index, column) => GridSheetColumn`: customizes each generated column. |
| `rowBuilder` | `null` | `(index, row) => GridSheetRow`: customizes each generated row. |

---

## Behavior

### What's generated

| | Generated |
| --- | --- |
| Columns | Named and titled `A`, `B`, … `Z`, `AA`, `AB`…; keys `col_0`, `col_1`…; text type, 120 px wide. |
| Rows | Keys `row_0`, `row_1`…; every cell `null`; 30 px tall; state `existing`. |

The generated grid then works like any other: editing, selection,
sorting, export and the rest. For formulas, make a column a formula column
in `columnBuilder` (see [Customization](#customization)).

### Builders

- Return the given column or row unchanged, or `copyWith(...)` any
  property. The **key and index are always reset** to the generated ones.
- A row's `data` must keep `columnsCount` values; a row with a different
  length is replaced by the default row.
- A builder that throws is reported to `GridSheet.onError` (source
  `GridSheetErrorSource.dynamicTableGeneration`), and that column or row
  falls back to the default.

### While generation is on

- `columns` and `rows` are ignored, including new lists passed later.
- The configuration is read **once**, when the grid is created. To
  regenerate with new counts or builders, give the `GridSheet` a new `key`.

---

## Runtime API

`gridManager.config.dynamicGeneration` returns the configuration in use, or
`null`. After creation, change the grid with the usual APIs, for example
`gridManager.rows.insert`, `columns.insertAt` or `cells.update`.

```dart
// Fill column B of the first row.
await gridManager.cells.update(
  rowKey: const ValueKey('row_0'),
  columnKey: const ValueKey('col_1'),
  value: 42,
);
```

---

## Events

None of its own. Builder errors go to `onError`.

---

## Customization

```dart
dynamicGenerationConfiguration: GridSheetDynamicGenerationConfiguration(
  columnsCount: 4,
  rowsCount: 12,
  columnBuilder: (index, column) => switch (index) {
    0 => column.copyWith(title: 'Item', type: const GridSheetColumnType.text(), width: 180),
    3 => column.copyWith(title: 'Total', type: const GridSheetColumnType.formula()),
    _ => column.copyWith(type: const GridSheetColumnType.double(), textAlign: TextAlign.end),
  },
  rowBuilder: (index, row) => row.copyWith(
    data: ['Item ${index + 1}', 0.0, 0.0, '=B${index + 1}*C${index + 1}'],
  ),
),
```

---

## Limitations

- **Created once.** New counts or builders need a new `key`, which starts
  a fresh grid and drops edits.
- **No column or row inputs** while generation is on.
- **Spreadsheet-style names only**; build `columns` yourself for named
  data.

---

## See also

- [Column types](column-types.md)
- [Formula columns](formula-columns.md)
- [Column operations](column-operations.md) · [Row operations](row-operations.md)
