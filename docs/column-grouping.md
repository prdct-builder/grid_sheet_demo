# Column grouping

Column grouping adds **header bands** above related columns ("Contact",
"Sales 2025"), nested as deep as you like. A band can collapse its columns
down to a summary column, such as a yearly total, and expand them again.

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
  groupingConfiguration: const GridSheetGroupingConfiguration(
    enabled: true,
    columns: GridSheetColumnGroupingConfiguration(
      groups: [
        GridSheetColumnGroupDescriptor(
          id: 'sales',
          title: 'Sales 2025',
          columnKeys: [q1Key, q2Key, q3Key, q4Key, totalKey],
          collapsedColumnKeys: [totalKey], // collapsed: only the total
        ),
      ],
    ),
  ),
)
```

---

## Configuration

`GridSheet.groupingConfiguration` (`GridSheetGroupingConfiguration`) holds
both column and row grouping; see [Row grouping](row-grouping.md#configuration)
for its shared options (`enabled`, `expandedByDefault`, `onExpansionChanged`).

### GridSheetColumnGroupingConfiguration

| Option | Default | Meaning |
| --- | --- | --- |
| `groups` | `[]` | The outermost groups. |
| `cellBuilder` | `null` | Builds bands yourself. See [Customization](#customization). |

### GridSheetColumnGroupDescriptor

| Field | Default | Meaning |
| --- | --- | --- |
| `id` | required | A stable id, unique across the configuration; used for expansion and the API. |
| `title` | required | The band's text. |
| `columnKeys` | `[]` | The group's own columns. |
| `groups` | `[]` | Nested groups, shown as bands below this one. |
| `collapsible` | `true` | Whether the band has a chevron to collapse the group. |
| `collapsedColumnKeys` | the group's first column | The columns that stay visible while collapsed. |

```dart
GridSheetColumnGroupDescriptor(
  id: 'contact',
  title: 'Contact',
  columnKeys: [emailKey],
  groups: [
    GridSheetColumnGroupDescriptor(id: 'location', title: 'Location', columnKeys: [cityKey, countryKey]),
  ],
),
```

---

## Behavior

- **Bands** sit above the column headers, one row per nesting level, each as
  tall as the header row and in the header's colors. Columns in no group
  get an empty band.
- **Collapsing** a group hides its columns except `collapsedColumnKeys`;
  tap the band's chevron to collapse or expand. Collapsed columns keep
  their data and their `visible` setting.
- **Split bands.** A band spans its columns in display order. If they
  aren't side by side (after a reorder, or across pinned sections), each run
  of adjacent columns gets its own band with the same title.
- A column belongs to at most one group per level.
- Column grouping works with pinned columns, column reorder, resizing,
  hiding and RTL, and alongside row grouping: row-group aggregates follow
  their columns, so a collapsed band still shows its summary column's
  aggregates.
- **Exports** of the visible columns (the default) leave collapsed columns
  out; `GridSheetColumnScope.all` includes them.

---

## Runtime API

`gridManager.grouping.columns` (`GridSheetColumnGroupingAPI`):

| Member | Description |
| --- | --- |
| `isActive` | Whether bands are shown. |
| `groups` / `setGroups(groups)` | The groups; an empty list removes the bands. |
| `find(groupId)` / `groupOf(columnKey)` | A group by id, or the innermost group of a column. |
| `isExpanded(id)` / `expand(ids)` / `collapse(ids)` / `toggle(id)` | One group's expansion. |
| `expandAll()` / `collapseAll()` | Every group's expansion. `collapseAll` skips groups that aren't collapsible. |

```dart
gridManager.grouping.columns.collapse(['sales']);
gridManager.grouping.columns.isExpanded('sales'); // false
```

Calls do nothing while grouping is disabled.

---

## Events

`GridSheetGroupingConfiguration.onExpansionChanged` fires with
`axis: GridSheetGroupAxis.columns` when bands collapse or expand. See
[Row grouping](row-grouping.md#events) for the event.

---

## Customization

`GridSheetColumnGroupingConfiguration.cellBuilder` builds a band; return
`null` to keep the built-in one. The context has the `group`, its `title`,
the `columns` it spans, `isExpanded` and `onToggleExpansion` (`null` when
the group can't collapse):

```dart
cellBuilder: (band) => Container(
  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.teal, width: 3))),
  child: Row(children: [
    Text(band.title),
    const Spacer(),
    if (band.onToggleExpansion != null)
      IconButton(
        icon: Icon(band.isExpanded ? Icons.unfold_less : Icons.unfold_more),
        onPressed: band.onToggleExpansion,
      ),
  ]),
),
```

---

## Limitations

- **Bands have the header row's height.**
- **The form layout doesn't show the bands.**
- **One group per level** for each column.

---

## See also

- [Row grouping](row-grouping.md)
- [Fixed columns](fixed-columns.md) · [Column operations](column-operations.md)
- [Custom cells](custom-cells.md)
