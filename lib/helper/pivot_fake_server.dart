import 'package:flutter/foundation.dart';
import 'package:grid_sheet/grid_sheet.dart';

/// An in-memory stand-in for a backend, answering the grid as a real one
/// would: a page of rows for `GridSheet.onPageChange`, the pivot's summary
/// for `GridSheet.onPivotRequest`, and a cell's rows for drill-down.
///
/// A real server does the same in its query language — for SQL, one query
/// per summary:
///
/// ```sql
/// SELECT region, date_trunc('year', order_date), SUM(amount)
/// FROM orders WHERE ...filters...
/// GROUP BY ROLLUP(region), ROLLUP(date_trunc('year', order_date))
/// ```
class PivotFakeServer {
  PivotFakeServer(this.columns, this.rows);

  /// The table's columns (for filter names and data indexes).
  final List<GridSheetColumn> columns;

  /// Every row "in the database".
  final List<GridSheetRow> rows;

  /// How long each call takes, so the loading indicator shows.
  static const latency = Duration(milliseconds: 400);

  int _index(ValueKey<String> key) =>
      columns.firstWhere((c) => c.key == key).index;

  // The rows matching the request's filters: a column's values are OR-ed,
  // matched as case-insensitive "contains".
  List<GridSheetRow> _filtered(Map<String, List<dynamic>> filters) => [
        for (final row in rows)
          if (filters.entries.every((filter) {
            final index = columns.firstWhere((c) => c.name == filter.key).index;
            final cell = '${row.data[index] ?? ''}'.toLowerCase();
            return filter.value.any((v) => cell.contains('$v'.toLowerCase()));
          }))
            row,
      ];

  /// A page of rows (`GridSheet.onPageChange`).
  Future<GridSheetPageData> page(GridSheetPageRequest request) async {
    await Future<void>.delayed(latency);
    final matching = _filtered(request.filters);
    return GridSheetPageData(
      rows: matching.skip(request.offset).take(request.rowsPerPage).toList(),
      totalCount: matching.length,
    );
  }

  /// The pivot's summary (`GridSheet.onPivotRequest`): for each grouping
  /// set, each group's values, keyed by one of the group's own values —
  /// the grid buckets that key with the field's bucketer, so a date field
  /// can return any date in the period.
  Future<GridSheetPivotData> pivot(GridSheetPivotRequest request) async {
    await Future<void>.delayed(latency);
    final matching = _filtered(request.filters);
    final values = request.configuration.values;
    final cells = <GridSheetPivotCellData>[];
    for (final set in request.groupingSets) {
      final fields = [...set.rowFields, ...set.columnFields];
      // "GROUP BY" this set's fields.
      final groups = <String, List<GridSheetRow>>{};
      for (final row in matching) {
        final id = [
          for (final f in fields)
            f.bucketer.bucketOf(row.data[_index(f.columnKey)], row).id,
        ].join('\u0000');
        (groups[id] ??= []).add(row);
      }
      for (final group in groups.values) {
        final first = group.first;
        cells.add(GridSheetPivotCellData(
          rowGroupKeys: [
            for (final f in set.rowFields) first.data[_index(f.columnKey)]
          ],
          columnGroupKeys: [
            for (final f in set.columnFields) first.data[_index(f.columnKey)],
          ],
          values: {
            for (final spec in values)
              spec.id: () {
                final sum = spec.aggregator.createAccumulator();
                for (final row in group) {
                  sum.add(row.data[_index(spec.columnKey)]);
                }
                return sum.result;
              }(),
          },
        ));
      }
    }
    return GridSheetPivotData(cells: cells);
  }

  /// The rows behind a pivot cell, from the keys the grid reports
  /// (`GridSheetPivotCellTappedEvent.rowGroupKeys`/`columnGroupKeys`).
  Future<List<GridSheetRow>> rowsAt(
    GridSheetPivotConfiguration configuration,
    List<Object?> rowGroupKeys,
    List<Object?> columnGroupKeys, {
    Map<String, List<dynamic>> filters = const {},
  }) async {
    await Future<void>.delayed(latency);
    final match = [
      for (final (i, key) in rowGroupKeys.indexed)
        (configuration.rowFields[i], key),
      for (final (i, key) in columnGroupKeys.indexed)
        (configuration.columnFields[i], key),
    ];
    String bucket(
            GridSheetGroupDescriptor field, Object? value, GridSheetRow row) =>
        field.bucketer.bucketOf(value, row).id;
    return [
      for (final row in _filtered(filters))
        if (match.every((m) =>
            bucket(m.$1, row.data[_index(m.$1.columnKey)], row) ==
            bucket(m.$1, m.$2, row)))
          row,
    ];
  }

  @override
  String toString() => describeIdentity(this);
}
