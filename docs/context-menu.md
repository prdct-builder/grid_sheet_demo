# Context menus

Right-click a cell, a row's index cell or a column header to open **your
own menu** at the pointer. The grid works out what was clicked and hands
your builder that cell, row or column, with the current selection; you
build the items and run the actions. It also positions the popup and draws
its shadow and backdrop.

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
  configuration: const GridSheetConfiguration(enableCellContextMenu: true),
  contextMenuBuilder: (info) {
    if (info is! GridSheetCellContextInfo) return null;
    return SizedBox(
      width: 200,
      child: ListTile(
        leading: const Icon(Icons.clear),
        title: const Text('Clear cell'),
        onTap: () => info.gridManager.cells.update(
            rowKey: info.rowKey, columnKey: info.columnKey, value: null),
      ),
    );
  },
)
```

---

## Configuration

### Turning menus on

| `GridSheetConfiguration` option | Default | Opens on |
| --- | --- | --- |
| `enableCellContextMenu` | `false` | Data cells. |
| `enableRowContextMenu` | `false` | The index cell (and data cells, when the cell menu is off). |
| `enableColumnContextMenu` | `false` | Column headers. |

A menu also needs `GridSheet.contextMenuBuilder`; without it, nothing
opens.

### The builder

`GridSheet.contextMenuBuilder: Widget? Function(GridSheetContextMenuInfo info)`.
Return the menu's content, or `null` to show nothing for this click.

### GridSheetContextMenuConfiguration

`GridSheet.contextMenuConfiguration` styles the popup around your content:

| Option | Default | Meaning |
| --- | --- | --- |
| `elevation` | `8` | The popup's shadow. |
| `borderRadius` | `4` | The popup's corners. |
| `backgroundColor` | `null` (theme card color) | The popup's background. |
| `backdropColor` | transparent | A full-screen scrim behind the popup; tapping it closes the menu. |

---

## Behavior

### Which menu opens

| Enabled | Index cell | Data cell | Header |
| --- | --- | --- | --- |
| Row and cell | Row menu | Cell menu | |
| Row only | Row menu | Row menu | |
| Cell only | Cell menu | Cell menu | |
| Column | | | Column menu |

Check `info.target` (`GridSheetContextMenuTarget.cell`, `.row`, `.column`)
or the info's type to tell them apart.

### Opening and closing

- Menus open on a **secondary click** (right-click, or a two-finger
  trackpad click).
- Right-clicking a data cell with the cell menu on also selects that cell.
- The popup opens at the pointer and is moved to stay on screen.
- It closes on a tap or right-click outside it, on Escape, and whenever the
  grid's rows or columns change (an edit, delete, sort, filter or reorder),
  so it never acts on stale data.
- Tapping an item doesn't close it; call `info.close()` from the item. See
  [Runtime API](#runtime-api).

---

## Runtime API

The builder's `info` is the API: it carries the grid and what was clicked.

**All menus** (`GridSheetContextMenuInfo`):

| Field | Description |
| --- | --- |
| `target` | `cell`, `row` or `column`. |
| `gridManager` | The grid, to run actions. |
| `globalPosition` / `localPosition` | Where the click happened. |
| `selectedRowKeys` / `selectedColumnKeys` / `selectedCellKeys` | The selection at click time. |
| `close()` | Closes this menu. Does nothing once it's closed, or after another menu has opened. |

**Cell** (`GridSheetCellContextInfo`): `rowKey`, `columnKey`, `columnName`,
`row`, `column`, `cellValue`, `isSelected`, `clickedRowAsMap`, and
`selectedCellsData` (`{columnName: [values]}`).

**Row** (`GridSheetRowContextInfo`): `rowKey`, `row`, `rowState`,
`isSelected`, `clickedRowAsMap`, and `selectedRowsData`.

**Column** (`GridSheetColumnContextInfo`): `columnKey`, `column`,
`columnName`, `columnTitle`, `isSelected`, `clickedColumnValues`, and
`selectedColumnsData`.

### Acting on the selection or the clicked item

Use `isSelected` to choose: act on the whole selection when the user
right-clicked inside it, otherwise on the clicked item.

```dart
contextMenuBuilder: (info) => switch (info) {
  GridSheetColumnContextInfo() => MenuItem(
      label: 'Hide',
      onTap: () => info.gridManager.columns.hide(
          info.isSelected ? info.selectedColumnKeys : [info.columnKey]),
    ),
  GridSheetRowContextInfo() => MenuItem(
      label: 'Delete',
      onTap: () => info.gridManager.rows.delete(
          info.isSelected ? info.selectedRowKeys : [info.rowKey]),
    ),
  GridSheetCellContextInfo() => MenuItem(
      label: 'Copy',
      onTap: () {
        info.close(); // copying doesn't change the grid, so close the menu here
        Clipboard.setData(ClipboardData(text: '${info.cellValue ?? ''}'));
      },
    ),
  _ => null,
},
```

---

## Events

None of its own. Actions you run fire their usual events, such as
`onCellValueChanged` for an edit.

---

## Customization

- **Content**: any widget. Give it a fixed width (a `SizedBox`), since the
  popup sizes to its content.
- **Per-row or per-column items**: build different items from the info, for
  example "Restore" for `rowState == GridSheetRowState.deleted`, or "Sort"
  only when `column.sortable`.
- **Chrome**: `GridSheetContextMenuConfiguration`, for example a dimmed
  backdrop:

```dart
contextMenuConfiguration: GridSheetContextMenuConfiguration(
  elevation: 2,
  borderRadius: BorderRadius.circular(8),
  backdropColor: Colors.black26,
),
```

---

## Limitations

- **No long-press.** Menus open on a secondary click only; on touch-only
  devices, offer the same actions elsewhere (a toolbar or a swipe).
- **No empty-space menu.** Clicks outside cells and headers don't open a
  menu.
- **No built-in items.** The grid ships no default menu; you build every
  item.

---

## See also

- [Selection](selection.md): the selection the menu acts on
- [Row operations](row-operations.md) · [Column operations](column-operations.md) ·
  [Cell operations](cell-operations.md)
- [Styling](styling.md)
