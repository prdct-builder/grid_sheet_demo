# Styling

The grid's look comes from two objects. **`GridSheetStyleConfiguration`**
holds colors, border widths, text styles and corner radius.
**`GridSheetConfiguration`** decides which borders are drawn at all, plus
row hover and the header and filter heights. Together they cover themes
from plain spreadsheets to card-style dashboards, in light and dark mode.

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
  configuration: const GridSheetConfiguration(enableRowHover: true, showColumnBorders: false),
  styleConfiguration: GridSheetStyleConfiguration(
    headerColor: Colors.indigo.shade50,
    evenRowColor: Colors.white,
    oddRowColor: Colors.grey.shade50,
    hoverColorOnRow: Colors.indigo.shade50,
    selectionColor: Colors.indigo,
    gridBorderRadius: BorderRadius.circular(8),
    headerTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    cellTextStyle: const TextStyle(fontSize: 14),
  ),
)
```

---

## Configuration

### GridSheetStyleConfiguration

`GridSheet.styleConfiguration`.

**Backgrounds**

| Option | Default | Meaning |
| --- | --- | --- |
| `gridBackgroundColor` | `#FFFBFE` | Behind everything, including empty space below the rows. |
| `headerColor` | `#EEEEEE` | The column header row. |
| `filterColor` | `#EEEEEE` | The filter row. |
| `rowColor` | white | Data rows. |
| `evenRowColor` / `oddRowColor` | `null` (`rowColor`) | Zebra stripes. |
| `topPinnedRowColor` / `bottomPinnedRowColor` | `null` | Rows pinned to the top or bottom. |
| `pinnedLeftColumnColor` / `pinnedRightColumnColor` | `null` | Cells in pinned columns. |
| `hoverColorOnRow` | `null` (`selectionColor`) | The hovered row; needs `enableRowHover`. |
| `selectionColor` | blue | Selected rows, columns and cells. |
| `loadingOverlayColor` | 30 % black | Behind the loading indicator. |

**Borders**

| Option | Default | Meaning |
| --- | --- | --- |
| `gridBorderColor` / `gridBorderWidth` | `#E0E0E0` / `1` | The outer border. |
| `gridBorderRadius` | `BorderRadius.zero` | The grid's corners. |
| `rowBorderColor` / `rowBorderWidth` | `#E0E0E0` / `1` | Lines between rows. |
| `columnBorderColor` / `columnBorderWidth` | `#E0E0E0` / `1` | Lines between columns. |
| `headerRowBorderColor` | `#E0E0E0` | Below the header row. |
| `filterRowBorderColor` | `#E0E0E0` | Below the filter row. |
| `bottomBarBorderColor` | `#E0E0E0` | Above the pagination bar. |
| `cellTextFieldBorderColor` / `cellTextFieldBorderWidth` | `#E0E0E0` / `1` | The outline of a cell being edited. |
| `selectionBorderWidth` | `2` | Selection borders, drag feedback and drop lines. |
| `pinnedLeftDividerColor` / `pinnedRightDividerColor` | `null` (none) | A divider between pinned and scrollable columns. |
| `pinnedColumnsDividerWidth` | `1` | Its width. |
| `pinnedTopDividerColor` / `pinnedBottomDividerColor` | `null` (none) | A divider between pinned and scrollable rows. |
| `pinnedRowsDividerWidth` | `1` | Its width. |

**Text**

| Option | Default | Meaning |
| --- | --- | --- |
| `cellTextStyle` | `null` (theme `bodyMedium`) | Cell text, and the measure for auto-fitting column widths. |
| `headerTextStyle` | `null` (theme `labelSmall`) | Header titles, and the measure for auto-fitting. |

**Interaction**

| Option | Default | Meaning |
| --- | --- | --- |
| `ascendingSortIconColor` / `descendingSortIconColor` | green / red | The sort arrows. |
| `resizeHandleColor` / `resizeHandleThickness` | `null` (`selectionColor`) / `3` | The line shown while resizing. |
| `rowDragIndicatorColor` | `null` (`selectionColor`) | The drag handle in the index column. |
| `columnDragFeedbackElevation` / `rowDragFeedbackElevation` | `8` | The shadow of a dragged column or row. |
| `dragFeedbackOpacity` | `0.35` | The placeholder left behind while dragging. |
| `leftPadding` / `rightPadding` | `0` | Space for [wrappers](wrappers.md); used only when a wrapper is set. |

### GridSheetConfiguration (layout)

| Option | Default | Meaning |
| --- | --- | --- |
| `showRowBorders` | `true` | Lines between rows. |
| `showColumnBorders` | `true` | Lines between columns. |
| `showHeaderRowBorder` | `true` | The line below the header, separate from row borders. |
| `showFilterRowBorder` | `true` | The line below the filter row. |
| `showBottomBarBorder` | `true` | The line above the pagination bar. |
| `showBorderOnSelection` | `true` | Selection (and hover) as a border; `false` fills the background instead. |
| `enableRowHover` | `false` | Highlights the row under the pointer. |
| `showColumnHeaderRow` | `true` | Shows the header row. |
| `headerHeight` / `filterHeight` | `50` / `30` | Header and filter row heights. |

Row heights come from each `GridSheetRow.height`; column widths from
`GridSheetColumn.width`.

---

## Behavior

### Which background wins

For a row, the first that applies:

1. Selection, then hover, as a fill when `showBorderOnSelection` is
   `false` (as a border otherwise, over the colors below)
2. A row-scoped [conditional format](conditional-format.md)
3. `pinnedRightColumnColor` / `pinnedLeftColumnColor`, in those columns
4. `topPinnedRowColor` / `bottomPinnedRowColor`
5. `evenRowColor` / `oddRowColor`
6. `rowColor`

Cell-scoped conditional formats are painted by their own cells. Pinned
rows stripe by their position inside their own band.

### Dividers

Pinned dividers take real space between the sections instead of being
drawn over cells, and appear only when that side has pinned columns or
rows. With no color set, nothing is drawn and no space is taken.

### Dark mode

The defaults are light colors. For dark mode, pass a configuration built
from the theme:

```dart
final scheme = Theme.of(context).colorScheme;
styleConfiguration: GridSheetStyleConfiguration(
  gridBackgroundColor: scheme.surface,
  rowColor: scheme.surface,
  headerColor: scheme.surfaceContainerHigh,
  filterColor: scheme.surfaceContainer,
  gridBorderColor: scheme.outlineVariant,
  rowBorderColor: scheme.outlineVariant,
  columnBorderColor: scheme.outlineVariant,
  selectionColor: scheme.primary,
  cellTextStyle: TextStyle(color: scheme.onSurface),
  headerTextStyle: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
),
```

Building it in `build` follows theme changes automatically.

---

## Runtime API

| Member | Description |
| --- | --- |
| `gridManager.config.style` | The current style configuration (read-only). |
| `gridManager.config.grid` / `updateGrid(configuration)` | Reads or changes the layout flags at runtime. |

Change styling by passing a new `styleConfiguration` (rows and edits are
kept). Toggle borders and hover without rebuilding the parent:

```dart
gridManager.config.updateGrid(
  gridManager.config.grid.copyWith(showColumnBorders: false),
);
```

A change made with `updateGrid` stays when the parent later passes a
different `configuration`: only the fields the parent changed take its
new values.

---

## Events

None.

---

## Customization

- **One cell or column**: [Custom cells](custom-cells.md) or
  [conditional formatting](conditional-format.md).
- **Row and header decoration** (cards, shadows, rounded rows):
  [Wrappers](wrappers.md).
- **Row state colors** (inserted, modified, deleted):
  `rowStateIndicatorBuilder`; see [Index column](index-column.md).
- **Scrollbars**: [Scrollbar](scrollbar.md). **Context menu** chrome:
  [Context menu](context-menu.md). **Pagination bar**:
  `PaginationConfiguration`; see [Pagination](pagination.md).
- `copyWith` changes a few fields of an existing configuration:

```dart
final compact = baseStyle.copyWith(cellTextStyle: const TextStyle(fontSize: 12));
```

---

## Limitations

- **No theme extension.** The grid doesn't read `ThemeData` colors itself;
  build the configuration from the theme as above.
- **One text style per grid.** For per-column fonts or colors, use a custom
  cell or conditional formatting.
- **Shared line width.** The lines below the header and filter rows use
  `rowBorderWidth`; only their colors are separate.

---

## See also

- [Wrappers](wrappers.md) · [Custom cells](custom-cells.md)
- [Conditional formatting](conditional-format.md)
- [Scrollbar](scrollbar.md) · [Fixed columns](fixed-columns.md) ·
  [Fixed rows](fixed-rows.md)
