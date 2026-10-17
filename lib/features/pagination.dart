import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Which of the three ways [GridSheet] can page through data this demo is
/// currently showing.
enum _PaginationMode { clientSide, serverSide, infiniteScroll }

class Pagination extends StatefulWidget {
  const Pagination({super.key});

  @override
  State<Pagination> createState() => _PaginationState();
}

class _PaginationState extends State<Pagination> {
  /// Stands in for a real backend: a larger dataset that [_fetchServerPage]
  /// slices per-request, with a simulated network delay, for both the
  /// server-side and infinite-scroll modes. Generated once and cached so
  /// "the server" doesn't reshuffle its own data between requests.
  static const int _serverRowCount = 500;
  late final List<GridSheetRow> _serverDataset = _generateRows(_serverRowCount);

  late GridSheetManager gridManager;
  final ValueNotifier<String> status =
      ValueNotifier('Page 1 loaded — 8 rows per page, 40 rows total.');
  bool _selectOnlyPageRows = true;
  bool _selectColumnAcrossAllPages = false;
  bool _useCustomPaginationBar = false;
  bool _compactPagination = false;
  _PaginationMode _mode = _PaginationMode.clientSide;

  @override
  void dispose() {
    _removePageListener();
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInfinite = _mode == _PaginationMode.infiniteScroll;
    final isServer = _mode == _PaginationMode.serverSide;
    final isRemote = isServer || isInfinite;

    return FeaturePageTemplate(
      title: 'Pagination',
      icon: Icons.view_carousel_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: 'First Page',
            icon: Icons.first_page,
            color: context.accents.blue,
            onPressed: () => _goToPage(1),
            tooltip: 'Jump to page 1',
          ),
          DemoActionButton(
            label: 'Previous',
            icon: Icons.chevron_left,
            color: context.accents.blue,
            onPressed: _previousPage,
            tooltip: 'Go to the previous page',
          ),
          DemoActionButton(
            label: 'Next',
            icon: Icons.chevron_right,
            color: context.accents.blue,
            onPressed: _nextPage,
            tooltip: 'Go to the next page',
          ),
          DemoActionButton(
            label: '15 / page',
            icon: Icons.filter_none,
            color: context.accents.teal,
            onPressed: () => _changePageSize(15),
            tooltip: 'Show 15 rows per page',
          ),
          DemoToggleButton(
            label: 'Client-Side',
            icon: Icons.storage_outlined,
            color: context.accents.green,
            value: _mode == _PaginationMode.clientSide,
            onChanged: (_) => _setMode(_PaginationMode.clientSide),
            tooltip: 'Page through rows already loaded in memory',
          ),
          DemoToggleButton(
            label: 'Server-Side',
            icon: Icons.cloud_sync_outlined,
            color: context.accents.amber,
            value: _mode == _PaginationMode.serverSide,
            onChanged: (_) => _setMode(_PaginationMode.serverSide),
            tooltip: 'Fetch each page on demand via onPageChange',
          ),
          DemoToggleButton(
            label: 'Infinite Scroll',
            icon: Icons.all_inclusive,
            color: context.accents.deepOrange,
            value: _mode == _PaginationMode.infiniteScroll,
            onChanged: (_) => _setMode(_PaginationMode.infiniteScroll),
            tooltip: 'Load more rows automatically while scrolling',
          ),
          DemoToggleButton(
            label: 'Select Only Page Rows',
            icon: Icons.check_box_outlined,
            color: context.accents.deepPurple,
            value: _selectOnlyPageRows,
            onChanged: _toggleSelectOnlyPageRows,
            tooltip: 'Header checkbox selects only this page, not every row',
          ),
          DemoToggleButton(
            label: 'Select Column Across Pages',
            icon: Icons.view_column_outlined,
            color: context.accents.pink,
            value: _selectColumnAcrossAllPages,
            onChanged: _toggleSelectColumnAcrossAllPages,
            tooltip: 'Column-select data spans every page, not just this one',
          ),
          DemoToggleButton(
            label: 'Custom Pagination Bar',
            icon: Icons.dashboard_customize_outlined,
            color: context.accents.indigo,
            value: _useCustomPaginationBar,
            onChanged: _toggleCustomPaginationBar,
            tooltip: 'Swap the default footer for a restyled pagination bar',
          ),
          DemoToggleButton(
            label: 'Compact Pagination',
            icon: Icons.compress_outlined,
            color: context.accents.brown,
            value: _compactPagination,
            onChanged: _toggleCompactPagination,
            tooltip: 'GridSheetPagination.compactMode: true — an icon-only, '
                'space-saving layout. Requires the custom pagination bar, '
                'so enabling this also turns that on.',
          ),
        ],
      ),
      grid: GridSheet(
        // Every one of these is only read once, at construction — the mode
        // and the custom-bar toggle both need a fresh GridSheet element to
        // actually take effect, hence the key derived from both.
        key: ValueKey('pagination-$_mode-$_useCustomPaginationBar'),
        columns: _columns(),
        // Server-side/infinite-scroll start empty; onLoaded's initial fetch
        // (isInitialLoad, internal to the package) populates the first page
        // via onPageChange below, the same seam a real backend would use.
        rows:
            _mode == _PaginationMode.clientSide ? _generateRows(40) : const [],
        configuration: GridSheetConfiguration(
          enableDefaultPagination: !isInfinite && !_useCustomPaginationBar,
          enableCustomPagination: !isInfinite && _useCustomPaginationBar,
          serverSidePagination: isServer,
          infiniteScroll: isInfinite,
          rowsPerPage: 8,
          enableMultiSelection: true,
          enableRowSelectionOnFirstColumnTap: true,
          enableColumnSelection: true,
          selectOnlyCurrentPageRows: _selectOnlyPageRows,
          selectColumnAcrossAllPages: _selectColumnAcrossAllPages,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        onPageChange: isRemote ? _fetchServerPage : null,
        bottomBarBuilder: (!isInfinite && _useCustomPaginationBar)
            ? (manager) => GridSheetPagination(
                  gridManager: manager,
                  compactMode: _compactPagination,
                  maxPageButtons: 3,
                  showRowsPerPageSelector: false,
                  paginationConfiguration: PaginationConfiguration(
                    backgroundColor: context.colors.surfaceSubtle,
                    selectionColor: context.colors.primary,
                    selectedTextColor: context.colors.onPrimary,
                    borderColor: context.colors.border,
                    disabledColor: context.colors.textMuted,
                    textStyle: TextTypography.body
                        .copyWith(color: context.colors.textPrimary),
                  ),
                )
            : null,
        onLoaded: (event) => gridManager = event.gridManager,
        onColumnsSelected: (event) {
          if (event.names.isEmpty) return;
          final colName = event.names.first;
          final count = event.data[colName]?.length ?? 0;
          status.value =
              'onColumnsSelected: "$colName" data has $count value(s)';
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['ID', 'CUSTOMER', 'REGION', 'AMOUNT'];
    const titles = ['ID', 'Customer', 'Region', 'Amount'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
    ];
    const widths = [100.0, 120.0, 100.0, 100.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        sortable: true,
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  static List<GridSheetRow> _generateRows(int count) {
    const regions = ['North', 'South', 'East', 'West'];
    return List.generate(count, (i) {
      return GridSheetRow(
        key: ValueKey('row_$i'),
        index: i,
        data: [
          'INV-${1000 + i}',
          'Customer ${i + 1}',
          regions[i % regions.length],
          150.0 + (i * 12.5),
        ],
        height: Constants.rowHeight,
      );
    });
  }

  /// Stands in for a REST/GraphQL call: waits a bit (simulated latency),
  /// then slices [_serverDataset] using [request.offset]/[request.rowsPerPage]
  /// — exactly the same shape [GridSheet.onPageChange] expects a real
  /// backend to fill in for both server-side pagination and infinite scroll.
  Future<GridSheetPageData> _fetchServerPage(
      GridSheetPageRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final start = request.offset.clamp(0, _serverDataset.length);
    final end = (start + request.rowsPerPage).clamp(0, _serverDataset.length);

    if (mounted) {
      status.value = 'onPageChange(offset: $start, rowsPerPage: '
          '${request.rowsPerPage}): fetched ${end - start} row(s) from the '
          'simulated server ($_serverRowCount total)';
    }

    return GridSheetPageData(
      // Fresh copies, never the shared _serverDataset instances directly —
      // GridSheet disposes every row it owns (including each row's
      // rebuildNotifier) when its State is torn down, e.g. when this demo's
      // mode-switch ValueKey mounts a brand-new GridSheet element. Handing
      // out the same cached row objects to more than one GridSheet (or
      // across successive fetches) means the second one to build inherits
      // an already-disposed notifier and crashes.
      rows:
          _serverDataset.sublist(start, end).map((r) => r.copyWith()).toList(),
      totalCount: _serverDataset.length,
    );
  }

  void _setMode(_PaginationMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    status.value = switch (mode) {
      _PaginationMode.clientSide =>
        'Client-side: all 40 rows already loaded in memory.',
      _PaginationMode.serverSide =>
        'Server-side: each page is now fetched on demand via onPageChange.',
      _PaginationMode.infiniteScroll =>
        'Infinite scroll: scroll near the bottom to load more rows automatically.',
    };
  }

  Future<void> _goToPage(int page) async {
    await gridManager.pagination.goTo(page);
    if (!mounted) return;
    status.value =
        'pagination.goTo($page): now on page ${gridManager.pagination.current} of ${gridManager.pagination.totalPages}';
  }

  void _nextPage() {
    final before = gridManager.pagination.current;
    if (before >= gridManager.pagination.totalPages) {
      status.value = 'pagination.next(): already on the last page';
      return;
    }
    gridManager.pagination.next();
    _reportPageChange('pagination.next()', before);
  }

  void _previousPage() {
    final before = gridManager.pagination.current;
    if (before <= 1) {
      status.value = 'pagination.previous(): already on the first page';
      return;
    }
    gridManager.pagination.previous();
    _reportPageChange('pagination.previous()', before);
  }

  // Waits for a pending page change, if any, before the status is set.
  VoidCallback? _pageListener;

  // Reports the page after next()/previous(). Client-side, the page changes
  // at once; server-side, next()/previous() fetch it asynchronously, so the
  // status waits for the grid to report the new page.
  void _reportPageChange(String call, int before) {
    final pagination = gridManager.pagination;
    void report() => status.value = '$call: now on page '
        '${pagination.current} of ${pagination.totalPages}';

    _removePageListener();
    if (pagination.current != before) {
      report();
      return;
    }
    status.value = '$call: loading…';
    void listener() {
      if (!mounted || pagination.current == before) return;
      _removePageListener();
      report();
    }

    _pageListener = listener;
    gridManager.addListener(listener);
  }

  void _removePageListener() {
    final listener = _pageListener;
    if (listener == null) return;
    gridManager.removeListener(listener);
    _pageListener = null;
  }

  Future<void> _changePageSize(int size) async {
    await gridManager.pagination.setRowsPerPage(size);
    if (!mounted) return;
    status.value =
        'pagination.setRowsPerPage($size): ${gridManager.pagination.totalPages} page(s) total';
  }

  void _toggleSelectOnlyPageRows(bool value) {
    setState(() => _selectOnlyPageRows = value);
    status.value =
        'selectOnlyCurrentPageRows: $value — tick the header checkbox to '
        'select ${value ? "only this page's" : "every filtered"} row(s)';
  }

  void _toggleSelectColumnAcrossAllPages(bool value) {
    setState(() => _selectColumnAcrossAllPages = value);
    status.value = 'selectColumnAcrossAllPages: $value — tap a column header '
        'to see the event data span '
        '${value ? "all 40 rows" : "just this page"}';
  }

  void _toggleCustomPaginationBar(bool value) {
    setState(() => _useCustomPaginationBar = value);
    status.value = value
        ? 'enableCustomPagination: true — the footer below is now a fully '
            'custom GridSheetPagination bar, restyled via PaginationConfiguration'
        : 'enableDefaultPagination: true — back to the built-in footer';
  }

  void _toggleCompactPagination(bool value) {
    setState(() {
      _compactPagination = value;
      // compactMode only exists on the custom GridSheetPagination bar (the
      // built-in default footer doesn't expose it), so switching this on
      // needs the custom bar switched on too, or there'd be nothing to see.
      if (value) _useCustomPaginationBar = true;
    });
    status.value = value
        ? 'compactMode: true — icon-only pagination controls, no text labels'
        : 'compactMode: false — back to the full-labeled pagination bar';
  }
}
