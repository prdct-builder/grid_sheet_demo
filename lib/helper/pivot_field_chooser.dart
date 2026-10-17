import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

/// Where a field sits in a pivot: down the side (rows), across the top
/// (columns), or summarized where they meet (values).
enum PivotArea { rowArea, columnArea, valueArea }

/// A pivot field chooser, like Excel's PivotTable Fields pane — built only
/// on grid_sheet's public types, so an app can copy it or design its own.
///
/// It edits a [GridSheetPivotConfiguration] and reports each change to
/// [onChanged]; wire that to the grid:
///
/// ```dart
/// PivotFieldChooser(
///   fields: columns,
///   configuration: gridKey.currentState!.pivot.configuration!,
///   onChanged: (c) => setState(() => gridKey.currentState!.pivot.setConfiguration(c)),
/// )
/// ```
///
/// Drag a field into Rows, Columns or Values (or use its menu), drag entries
/// between areas or onto one another to reorder, and use an entry's menu to
/// pick a date part, how a value is summarized, or to remove it. A field is
/// on one axis at a time: adding it to Rows takes it out of Columns.
class PivotFieldChooser extends StatelessWidget {
  const PivotFieldChooser({
    super.key,
    required this.fields,
    required this.configuration,
    required this.onChanged,
  });

  /// The columns that can be pivoted.
  final List<GridSheetColumn> fields;

  /// The configuration shown.
  final GridSheetPivotConfiguration configuration;

  /// Called with the configuration after a change.
  final ValueChanged<GridSheetPivotConfiguration> onChanged;

  GridSheetColumn? _field(ValueKey<String> key) =>
      fields.where((f) => f.key == key).firstOrNull;

  String _title(ValueKey<String> key) => _field(key)?.title ?? key.value;

  bool _isDate(ValueKey<String> key) =>
      _field(key)?.type.kind == GridSheetColumnKind.datetime;

  bool _isNumeric(ValueKey<String> key) => switch (_field(key)?.type.kind) {
        GridSheetColumnKind.integer || GridSheetColumnKind.double => true,
        _ => false,
      };

  // ── Changes ──────────────────────────────────────────────────────────────

  List<Object> _entries(PivotArea area) => switch (area) {
        PivotArea.rowArea => configuration.rowFields,
        PivotArea.columnArea => configuration.columnFields,
        PivotArea.valueArea => configuration.values,
      };

  ValueKey<String> _keyOf(Object entry) => switch (entry) {
        GridSheetGroupDescriptor(:final columnKey) => columnKey,
        GridSheetAggregateSpec(:final columnKey) => columnKey,
        _ => throw ArgumentError(entry),
      };

  // [entry] converted for [area]: a field keeps its grouping between Rows
  // and Columns; a new one groups dates by year and sums numbers.
  Object _entryFor(PivotArea area, ValueKey<String> key, Object? from) {
    if (area == PivotArea.valueArea) {
      if (from is GridSheetAggregateSpec) return from;
      return GridSheetAggregateSpec(
        columnKey: key,
        aggregator: _isNumeric(key)
            ? GridSheetAggregators.sum
            : GridSheetAggregators.count,
      );
    }
    if (from is GridSheetGroupDescriptor) return from;
    return _isDate(key)
        ? GridSheetGroupDescriptor.date(key, GridSheetGroupDatePart.year,
            title: _title(key))
        : GridSheetGroupDescriptor(
            columnKey: key,
            title: _title(key),
            sort: const GridSheetGroupSort.value());
  }

  GridSheetPivotConfiguration _with(Map<PivotArea, List<Object>> areas) =>
      configuration.copyWith(
        rowFields: List.unmodifiable(areas[PivotArea.rowArea]!.cast()),
        columnFields: List.unmodifiable(areas[PivotArea.columnArea]!.cast()),
        values: List.unmodifiable(areas[PivotArea.valueArea]!.cast()),
      );

  Map<PivotArea, List<Object>> get _areas => {
        for (final a in PivotArea.values) a: [..._entries(a)]
      };

  /// Puts the field [key] (or the entry [from] at [fromIndex] of [fromArea])
  /// into [area] before [index] (at the end by default).
  void _place(PivotArea area, ValueKey<String> key,
      {PivotArea? fromArea, int? fromIndex, int? index}) {
    final areas = _areas;
    Object? from;
    if (fromArea != null && fromIndex != null) {
      from = areas[fromArea]!.removeAt(fromIndex);
      if (fromArea == area && index != null && fromIndex < index) index--;
    }
    final entry = _entryFor(area, key, from);
    final target = areas[area]!;
    if (area == PivotArea.valueArea) {
      // The same summary twice would be one column.
      final id = (entry as GridSheetAggregateSpec).id;
      if (target.any((e) => (e as GridSheetAggregateSpec).id == id)) return;
    } else {
      // One axis at a time.
      for (final axis in [PivotArea.rowArea, PivotArea.columnArea]) {
        final list = areas[axis]!;
        for (var i = list.length - 1; i >= 0; i--) {
          if (_keyOf(list[i]) == key) {
            list.removeAt(i);
            if (axis == area && index != null && i < index) index--;
          }
        }
      }
    }
    target.insert((index ?? target.length).clamp(0, target.length), entry);
    onChanged(_with(areas));
  }

  void _remove(PivotArea area, int index) {
    final areas = _areas;
    areas[area]!.removeAt(index);
    onChanged(_with(areas));
  }

  void _replace(PivotArea area, int index, Object entry) {
    final areas = _areas;
    areas[area]![index] = entry;
    onChanged(_with(areas));
  }

  // ── View ─────────────────────────────────────────────────────────────────

  static const _areaTitles = {
    PivotArea.rowArea: 'Rows',
    PivotArea.columnArea: 'Columns',
    PivotArea.valueArea: 'Values',
  };

  static const _areaIcons = {
    PivotArea.rowArea: Icons.table_rows_outlined,
    PivotArea.columnArea: Icons.view_column_outlined,
    PivotArea.valueArea: Icons.functions,
  };

  String _entryLabel(Object entry) => switch (entry) {
        GridSheetAggregateSpec() =>
          '${entry.displayLabel} of ${_title(entry.columnKey)}',
        GridSheetGroupDescriptor(
          bucketer: GridSheetGroupDateBucketer(:final part)
        ) =>
          '${_title(entry.columnKey)} (${_datePartLabel(part)})',
        GridSheetGroupDescriptor() => _title(entry.columnKey),
        _ => '$entry',
      };

  static String _datePartLabel(GridSheetGroupDatePart part) => switch (part) {
        GridSheetGroupDatePart.year => 'Year',
        GridSheetGroupDatePart.quarter => 'Quarter',
        GridSheetGroupDatePart.month => 'Month',
        GridSheetGroupDatePart.day => 'Day',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Pivot fields', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final field in fields) _fieldTile(context, field),
          for (final area in PivotArea.values) ...[
            const SizedBox(height: 12),
            _areaSection(context, area),
          ],
        ],
      ),
    );
  }

  Widget _fieldTile(BuildContext context, GridSheetColumn field) {
    final used = [
      for (final area in PivotArea.values)
        if (_entries(area).any((e) => _keyOf(e) == field.key))
          _areaTitles[area]!,
    ];
    final tile = _Tile(
      icon: switch (field.type.kind) {
        GridSheetColumnKind.datetime => Icons.event_outlined,
        GridSheetColumnKind.integer ||
        GridSheetColumnKind.double =>
          Icons.numbers,
        _ => Icons.text_fields,
      },
      label: field.title,
      detail: used.join(', '),
      menu: PopupMenuButton<PivotArea>(
        key: ValueKey('pivot-field-menu-${field.key.value}'),
        tooltip: 'Add ${field.title} to…',
        icon: const Icon(Icons.add, size: 18),
        onSelected: (area) => _place(area, field.key),
        itemBuilder: (_) => [
          for (final area in PivotArea.values)
            PopupMenuItem(
                value: area, child: Text('Add to ${_areaTitles[area]}')),
        ],
      ),
    );
    return _draggable(
      key: ValueKey('pivot-field-${field.key.value}'),
      data: _PivotDrag(field.key),
      label: field.title,
      child: tile,
    );
  }

  Widget _areaSection(BuildContext context, PivotArea area) {
    final theme = Theme.of(context);
    final entries = _entries(area);
    return DragTarget<_PivotDrag>(
      key: ValueKey('pivot-area-${area.name}'),
      onAcceptWithDetails: (d) => _place(area, d.data.key,
          fromArea: d.data.area, fromIndex: d.data.index),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(_areaIcons[area], size: 16),
              const SizedBox(width: 6),
              Text(_areaTitles[area]!, style: theme.textTheme.labelLarge),
            ]),
            const SizedBox(height: 6),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Drag fields here',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ),
            for (final (i, entry) in entries.indexed)
              _entryTile(context, area, i, entry),
          ],
        ),
      ),
    );
  }

  Widget _entryTile(
      BuildContext context, PivotArea area, int index, Object entry) {
    final key = _keyOf(entry);
    final label = _entryLabel(entry);
    final count = _entries(area).length;
    final menu = PopupMenuButton<VoidCallback>(
      key: ValueKey('pivot-entry-menu-${area.name}-$index'),
      tooltip: 'Options for $label',
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (entry is GridSheetAggregateSpec)
          for (final (aggregator, name) in const [
            (GridSheetAggregators.sum, 'Sum'),
            (GridSheetAggregators.count, 'Count'),
            (GridSheetAggregators.average, 'Average'),
            (GridSheetAggregators.min, 'Min'),
            (GridSheetAggregators.max, 'Max'),
          ])
            CheckedPopupMenuItem(
              checked: entry.aggregator.id == aggregator.id,
              value: () => _replace(
                  area,
                  index,
                  GridSheetAggregateSpec(
                      columnKey: key, aggregator: aggregator)),
              child: Text('Summarize by $name'),
            ),
        if (entry is GridSheetGroupDescriptor && _isDate(key))
          for (final part in GridSheetGroupDatePart.values)
            CheckedPopupMenuItem(
              checked: switch (entry.bucketer) {
                GridSheetGroupDateBucketer(part: final p) => p == part,
                _ => false,
              },
              value: () => _replace(area, index,
                  GridSheetGroupDescriptor.date(key, part, title: _title(key))),
              child: Text('Group by ${_datePartLabel(part)}'),
            ),
        const PopupMenuDivider(),
        if (index > 0)
          PopupMenuItem(
            value: () => _place(area, key,
                fromArea: area, fromIndex: index, index: index - 1),
            child: const Text('Move up'),
          ),
        if (index < count - 1)
          PopupMenuItem(
            value: () => _place(area, key,
                fromArea: area, fromIndex: index, index: index + 2),
            child: const Text('Move down'),
          ),
        for (final to in PivotArea.values)
          if (to != area)
            PopupMenuItem(
              value: () => _place(to, key, fromArea: area, fromIndex: index),
              child: Text('Move to ${_areaTitles[to]}'),
            ),
        PopupMenuItem(
          value: () => _remove(area, index),
          child: const Text('Remove'),
        ),
      ],
    );
    // Dropping onto an entry puts the field before it.
    return DragTarget<_PivotDrag>(
      onAcceptWithDetails: (d) => _place(area, d.data.key,
          fromArea: d.data.area, fromIndex: d.data.index, index: index),
      builder: (context, candidates, _) => Container(
        decoration: candidates.isEmpty
            ? null
            : BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2))),
        child: _draggable(
          key: ValueKey('pivot-entry-${area.name}-$index'),
          data: _PivotDrag(key, area: area, index: index),
          label: label,
          child: _Tile(
            icon: Icons.drag_indicator,
            label: label,
            menu: menu,
          ),
        ),
      ),
    );
  }

  // Draggable by pointer kind, not platform — on the web one browser can
  // get both: a mouse, trackpad or stylus drags at once; a finger
  // long-presses, so the panel still scrolls under it.
  static Widget _draggable({
    required Key key,
    required _PivotDrag data,
    required String label,
    required Widget child,
  }) {
    final feedback = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label),
      ),
    );
    final dimmed = Opacity(opacity: 0.4, child: child);
    return _TouchDraggable(
      key: key,
      data: data,
      feedback: feedback,
      childWhenDragging: dimmed,
      child: _PointerDraggable(
        data: data,
        feedback: feedback,
        childWhenDragging: dimmed,
        child: child,
      ),
    );
  }
}

// Starts a drag at once, for a mouse, trackpad or stylus only.
class _PointerDraggable extends Draggable<_PivotDrag> {
  const _PointerDraggable({
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.child,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
          GestureMultiDragStartCallback onStart) =>
      ImmediateMultiDragGestureRecognizer(
        supportedDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
        },
        allowedButtonsFilter: allowedButtonsFilter,
      )..onStart = onStart;
}

// Starts a drag after a long press, for touch only.
class _TouchDraggable extends LongPressDraggable<_PivotDrag> {
  const _TouchDraggable({
    super.key,
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.child,
  });

  @override
  DelayedMultiDragGestureRecognizer createRecognizer(
          GestureMultiDragStartCallback onStart) =>
      DelayedMultiDragGestureRecognizer(
        delay: delay,
        supportedDevices: {PointerDeviceKind.touch},
        allowedButtonsFilter: allowedButtonsFilter,
      )..onStart = onStart;
}

// What's being dragged: a field from the list, or an entry of an area.
class _PivotDrag {
  const _PivotDrag(this.key, {this.area, this.index});

  final ValueKey<String> key;
  final PivotArea? area;
  final int? index;
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.menu,
    this.detail = '',
  });

  final IconData icon;
  final String label;
  final String detail;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
          ),
          if (detail.isNotEmpty)
            Text(detail,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          menu,
        ],
      ),
    );
  }
}
