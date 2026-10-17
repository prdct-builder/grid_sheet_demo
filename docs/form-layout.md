# Form layout

The form layout shows each row as a **card** of `label : value` fields
instead of a table row, which suits phones and narrow panels. It can switch
in by itself below a width, or always be on. Cards edit, select, reorder,
search and format like the table, through the same cells and the same
`gridManager`. You can add a top and bottom bar to each card, or build the
whole card yourself.

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
  viewMode: GridSheetViewMode.responsive, // cards below 600 px, table above
)
```

---

## Configuration

### View mode

`GridSheet.viewMode`:

| `GridSheetViewMode` | Shows |
| --- | --- |
| `auto` (default) | The table (or the pivot table when one is configured). |
| `responsive` | Cards below `formConfiguration.breakpoint`, the table above. |
| `form` | Always cards. |
| `table` | Always the table. |
| `pivot` | The pivot table. See [Pivot](pivot.md). |

The form layout is opt-in: with the default `auto`, a grid shows its table
at any width.

### GridSheetFormConfiguration

`GridSheet.formConfiguration`:

| Option | Default | Meaning |
| --- | --- | --- |
| `breakpoint` | `600` | The width below which `responsive` shows cards, measured on the grid itself, not the screen. |
| `enableGridView` | `false` | Lays cards out in several columns (masonry) instead of one list. |
| `maxGridColumns` | `4` | The most columns in grid view. |
| `minGridCardWidth` | `340` | The width budgeted per column: columns = grid width ÷ this, up to `maxGridColumns`. |
| `maxHeight` | `null` | Caps each card's height; longer content scrolls inside the card. |
| `labelBuilder` | `null` (`Text(column.title)`) | Builds each field's label. |
| `topBarBuilder` / `bottomBarBuilder` | `null` | Builds a widget above / below each card's fields. |
| `formBuilder` | `null` | Builds the card's content yourself, replacing the fields. |
| `cardWrapper` | `null` | Replaces the built-in `Card` around the content. |
| `cardDragPreviewBuilder` | `null` | The preview that follows the pointer while a card is dragged. |

---

## Behavior

### Cards

- One card per row, with one field per **visible** column, in column
  order. Hidden columns are left out.
- Fields use the same cells as the table: text fields, dropdowns, read-only
  values and your `cellBuilder` widgets, with the same editing rules.
- Cards size to their content; in grid view each column of the masonry
  sizes on its own, with no shared row height.
- Cards are built lazily as they scroll into view.

### What carries over from the table

| Feature | In the form layout |
| --- | --- |
| Editing, validation, formulas, undo | Same as the table. |
| Search, filters, sorting | Applied to the cards. With no header or filter row, set them through `gridManager` or your own controls. |
| Pagination | The pagination bar still shows; cards are paged. |
| Selection | Tap a card to select its row when `enableRowSelectionOnFirstColumnTap` is on (a card has no index cell); `enableMultiSelection` selects several. |
| Row reorder | Long-press a card and drag (`enableRowReorder`). A card-sized gap shows where it lands. |
| Conditional formatting | Row rules tint the whole card; cell rules color their field. |
| Row grouping | Cards are listed under their group headers, in one list. |
| Pinned rows | Pinned-top cards sit in a band above the scrolling cards and pinned-bottom cards in a band below, staying put. A band takes at most about a third of the height and scrolls inside itself beyond that. Pinned cards can't be dragged. |
| Row animation | `animateRowsOnSortOrFilter` reveals cards top to bottom. |
| RTL | Cards, fields and the scrollbar mirror. |

Switching between table and form keeps the data, edits, selection, sort and
filters.

---

## Runtime API

| Member | Description |
| --- | --- |
| `gridManager.config.viewMode` | The current view mode. |
| `gridManager.config.setViewMode(mode)` | Switches the view mode. |
| `gridManager.config.form` | The current form configuration. |

```dart
IconButton(
  icon: const Icon(Icons.view_agenda),
  onPressed: () => gridManager.config.setViewMode(GridSheetViewMode.form),
),
```

Sorting, filtering and searching in the form layout go through
`gridManager.sorting`, `filters` and `search`, as they would for the table.

---

## Events

No events of its own; edits, selection and reorders fire the usual
callbacks (`onCellValueChanged`, `onRowsSelected`, `onRowReorder`).

---

## Customization

### Labels and bars

```dart
formConfiguration: GridSheetFormConfiguration(
  labelBuilder: (column) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(iconFor(column.name), size: 14),
    const SizedBox(width: 4),
    Text(column.title),
  ]),
  topBarBuilder: (context, row, grid) => ListTile(
    title: Text('${row.data[0]}'),
    trailing: IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () => grid.rows.delete([row.key]),
    ),
  ),
),
```

### Your own card content

`formBuilder(context, row, columns, gridManager)` replaces the fields. The
built-in card, its selection border, the bars and `maxHeight` still apply;
`labelBuilder` doesn't.

```dart
formBuilder: (context, row, columns, grid) => ListTile(
  title: Text('${row.data[1]}'),
  subtitle: Text('${row.data[2]} · ${row.data[3]}'),
),
```

### Your own card chrome

`cardWrapper(context, child, details)` replaces the `Card` around the
content. `details` has `row`, `hovered` (needs `enableRowHover`),
`selected` and `gridManager`. Return `child` unchanged for no chrome at all.

```dart
cardWrapper: (context, child, details) => Container(
  decoration: BoxDecoration(
    border: Border(left: BorderSide(
        color: details.selected ? Colors.purple : Colors.grey.shade300, width: 3)),
  ),
  child: child,
),
```

### Drag preview

`cardDragPreviewBuilder` gets the built-in preview in
`details.defaultPreview`; return it, wrap it, or return your own. It's shown
in the app's overlay, so give a custom one a size and its own `Material`.

---

## Limitations

- **No header or filter row.** Provide sort, filter and search controls
  yourself.
- **No column group bands or pinned columns** in cards; columns are just
  fields.
- **One list while grouped**: grid view is ignored for grouped rows.

---

## See also

- [Custom cells](custom-cells.md): cells shared by table and form
- [Conditional formatting](conditional-format.md)
- [Search](search.md) · [Row grouping](row-grouping.md)
- [Pivot](pivot.md): the other view mode
