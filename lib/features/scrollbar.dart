import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class ScrollsConfiguration extends StatefulWidget {
  const ScrollsConfiguration({super.key});

  @override
  State<ScrollsConfiguration> createState() => _ScrollsConfigurationState();
}

class _ScrollsConfigurationState extends State<ScrollsConfiguration> {
  // Set once the grid has loaded; the external scrollbars need it.
  GridSheetManager? _gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'This dataset is intentionally wide and tall — scroll in both directions to see the '
    'configured scrollbar.',
  );

  double _thickness = 10.0;
  Radius _radius = const Radius.circular(4);
  bool _thumbVisibility = true;
  bool _trackVisibility = true;
  bool _customColors = false;
  bool _customWidget = false;
  bool _showVerticalScrollbar = true;
  bool _showHorizontalScrollbar = true;
  GridSheetVerticalScrollbarPlacement _verticalPlacement =
      GridSheetVerticalScrollbarPlacement.afterLastColumn;
  // Both scrollbars drawn by GridSheetScrollbar widgets outside the grid.
  bool _external = false;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = _gridManager;
    return FeaturePageTemplate(
      title: 'Scroll Configuration',
      icon: Icons.view_sidebar_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: _external ? 'Scrollbars: External' : 'Scrollbars: Inside',
            icon: Icons.open_in_full,
            color: context.accents.indigo,
            onPressed: () {
              setState(() => _external = !_external);
              status.value = _external
                  ? 'external placements — the grid draws no scrollbars; GridSheetScrollbar widgets '
                      'outside it (right of the grid, and below it at full width) scroll the rows and columns.'
                  : 'Scrollbars back inside the grid.';
            },
            tooltip:
                'Move both scrollbars outside the grid with GridSheetScrollbar',
          ),
          DemoActionButton(
            label: 'Thin (6px)',
            icon: Icons.horizontal_rule,
            color: context.accents.blue,
            onPressed: () => setState(() => _thickness = 6.0),
            tooltip: 'Set the scrollbar thickness to 6px',
          ),
          DemoActionButton(
            label: 'Thick (16px)',
            icon: Icons.drag_handle,
            color: context.accents.blue,
            onPressed: () => setState(() => _thickness = 16.0),
            tooltip: 'Set the scrollbar thickness to 16px',
          ),
          DemoActionButton(
            label: 'Rounded',
            icon: Icons.rounded_corner,
            color: context.accents.teal,
            onPressed: () => setState(() => _radius = const Radius.circular(8)),
            tooltip: 'Give the scrollbar thumb rounded corners',
          ),
          DemoActionButton(
            label: 'Square',
            icon: Icons.crop_square,
            color: context.accents.teal,
            onPressed: () => setState(() => _radius = Radius.zero),
            tooltip: 'Give the scrollbar thumb square corners',
          ),
          DemoActionButton(
            label: _thumbVisibility ? 'Thumb: Always' : 'Thumb: On Hover',
            icon: Icons.visibility_outlined,
            color: context.accents.orange,
            onPressed: () =>
                setState(() => _thumbVisibility = !_thumbVisibility),
            tooltip: 'Toggle whether the thumb always shows or only on hover',
          ),
          DemoActionButton(
            label: _trackVisibility ? 'Track: Shown' : 'Track: Hidden',
            icon: Icons.linear_scale,
            color: context.accents.purple,
            onPressed: () =>
                setState(() => _trackVisibility = !_trackVisibility),
            tooltip: 'Toggle whether the scrollbar track is visible',
          ),
          DemoActionButton(
            label: _customColors ? 'Colors: Custom' : 'Colors: Default',
            icon: Icons.palette_outlined,
            color: context.accents.pink,
            onPressed: () => setState(() => _customColors = !_customColors),
            tooltip: 'Switch the scrollbar\'s thumb/track colors',
          ),
          DemoActionButton(
            label: _showHorizontalScrollbar
                ? 'Horizontal Scroll: Enabled'
                : 'Horizontal Scroll: Disabled',
            icon: Icons.swap_horiz,
            color: context.accents.green,
            onPressed: () => setState(
                () => _showHorizontalScrollbar = !_showHorizontalScrollbar),
            tooltip: 'Enable or disable horizontal scrolling entirely',
          ),
          DemoActionButton(
            label: _showVerticalScrollbar
                ? 'Vertical Scroll: Enabled'
                : 'Vertical Scroll: Disabled',
            icon: Icons.height,
            color: context.accents.green,
            onPressed: () => setState(
                () => _showVerticalScrollbar = !_showVerticalScrollbar),
            tooltip: 'Enable or disable vertical scrolling entirely',
          ),
          DemoActionButton(
            label: _verticalPlacement ==
                    GridSheetVerticalScrollbarPlacement.overlay
                ? 'V-Scrollbar: Overlay'
                : 'V-Scrollbar: After Last Column',
            icon: Icons.vertical_align_center,
            color: context.accents.indigo,
            onPressed: () {
              setState(() {
                _verticalPlacement = _verticalPlacement ==
                        GridSheetVerticalScrollbarPlacement.overlay
                    ? GridSheetVerticalScrollbarPlacement.afterLastColumn
                    : GridSheetVerticalScrollbarPlacement.overlay;
              });
              status.value = _verticalPlacement ==
                      GridSheetVerticalScrollbarPlacement.overlay
                  ? 'verticalScrollbarPlacement: overlay — last column now extends to the edge; the scrollbar draws on top of it.'
                  : 'verticalScrollbarPlacement: afterLastColumn — space is reserved after the last column for the scrollbar.';
            },
            tooltip: 'Switch where the vertical scrollbar sits',
          ),
          DemoActionButton(
            label: _customWidget ? 'Widget: RawScrollbar' : 'Widget: Default',
            icon: Icons.widgets_outlined,
            color: context.accents.deepPurple,
            onPressed: () => setState(() => _customWidget = !_customWidget),
            tooltip:
                'Replace the scrollbar widget entirely via scrollbarBuilder',
          ),
        ],
      ),
      // The grid keeps its place in the tree either way, so switching the
      // scrollbars outside doesn't reset it.
      grid: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GridSheet(
                    columns: _columns(),
                    rows: _rows(),
                    configuration: const GridSheetConfiguration(
                      showColumnFilters: true,
                    ),
                    styleConfiguration: styleConfig(context),
                    onLoaded: (event) =>
                        setState(() => _gridManager = event.gridManager),
                    scrollConfiguration: scrollConfig(context).copyWith(
                      radius: _radius,
                      thickness: _thickness,
                      thumbVisibility: _thumbVisibility,
                      trackVisibility: _trackVisibility,
                      thumbColor: _customColors ? context.accents.pink : null,
                      trackColor: _customColors
                          ? context.accents.pink.withValues(alpha: 0.15)
                          : null,
                      scrollbarBuilder: _customWidget
                          ? (context, child, controller, axis) {
                              return RawScrollbar(
                                controller: controller,
                                thumbColor: context.accents.deepPurple,
                                trackColor: context.accents.deepPurple
                                    .withValues(alpha: 0.1),
                                trackVisibility: true,
                                thumbVisibility: true,
                                thickness: 14,
                                radius: const Radius.circular(20),
                                // The row list sits inside the horizontal
                                // scroll view, so a horizontal notification
                                // arrives at depth 0 (Flutter's default
                                // predicate) and a vertical one at depth 1
                                // — see GridSheetScrollbarBuilder.
                                notificationPredicate: axis == Axis.vertical
                                    ? (notif) =>
                                        notif.metrics.axis == Axis.vertical &&
                                        notif.depth == 1
                                    : defaultScrollNotificationPredicate,
                                child: child,
                              );
                            }
                          : null,
                      showVerticalScrollbar: _showVerticalScrollbar,
                      showHorizontalScrollbar: _showHorizontalScrollbar,
                      verticalScrollbarPlacement: _external
                          ? GridSheetVerticalScrollbarPlacement.external
                          : _verticalPlacement,
                      horizontalScrollbarPlacement: _external
                          ? GridSheetHorizontalScrollbarPlacement.external
                          : GridSheetHorizontalScrollbarPlacement.bottom,
                    ),
                  ),
                ),
                if (_external && manager != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    // Any length works: this one is 60% of the grid's
                    // height, centered beside it.
                    child: FractionallySizedBox(
                      heightFactor: 0.6,
                      child: GridSheetScrollbar(
                        gridManager: manager,
                        axis: Axis.vertical,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 60% of the grid's width, centered below it.
          if (_external && manager != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: GridSheetScrollbar(
                  gridManager: manager,
                  axis: Axis.horizontal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = [
      'EMPLOYEE',
      'DEPARTMENT',
      'REGION',
      'PROJECT',
      'ROLE',
      'HOURS_LOGGED',
      'BUDGET',
      'EFFICIENCY_PCT',
      'STATUS',
      'LAST_REVIEW',
    ];
    const titles = [
      'Employee',
      'Department',
      'Region',
      'Project',
      'Role',
      'Hours Logged',
      'Budget',
      'Efficiency %',
      'Status',
      'Last Review',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.double(),
      GridSheetColumnType.double(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
    ];
    const widths = [
      160.0,
      160.0,
      160.0,
      160.0,
      160.0,
      160.0,
      160.0,
      160.0,
      160.0,
      160.0,
    ];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : TextAlign.left,
        pinnedLeft: i == 0,
      );
    });
  }

  List<GridSheetRow> _rows() {
    // Generated from a departments/regions/statuses rotation + linear
    // formulas per column (Employee N, hours = 120 + N*3.5, budget = 5000 +
    // N*275, efficiency = clamp(60 + N*1.3, 0, 100)) — baked into literal
    // values here to match every other demo page's raw-list + .asMap()
    // .entries.map() row-building shape.
    final raw = [
      [
        'Employee 1',
        'Engineering',
        'North',
        'Project A',
        'Lead',
        120.0,
        5000.0,
        60.0,
        'Active',
        '2024-01-15'
      ],
      [
        'Employee 2',
        'Design',
        'South',
        'Project B',
        'Contributor',
        123.5,
        5275.0,
        61.3,
        'On Leave',
        '2025-02-15'
      ],
      [
        'Employee 3',
        'Sales',
        'East',
        'Project C',
        'Contributor',
        127.0,
        5550.0,
        62.6,
        'Remote',
        '2024-03-15'
      ],
      [
        'Employee 4',
        'Support',
        'West',
        'Project D',
        'Lead',
        130.5,
        5825.0,
        63.9,
        'Active',
        '2025-04-15'
      ],
      [
        'Employee 5',
        'Marketing',
        'North',
        'Project E',
        'Contributor',
        134.0,
        6100.0,
        65.2,
        'On Leave',
        '2024-05-15'
      ],
      [
        'Employee 6',
        'Engineering',
        'South',
        'Project F',
        'Contributor',
        137.5,
        6375.0,
        66.5,
        'Remote',
        '2025-06-15'
      ],
      [
        'Employee 7',
        'Design',
        'East',
        'Project A',
        'Lead',
        141.0,
        6650.0,
        67.8,
        'Active',
        '2024-07-15'
      ],
      [
        'Employee 8',
        'Sales',
        'West',
        'Project B',
        'Contributor',
        144.5,
        6925.0,
        69.1,
        'On Leave',
        '2025-08-15'
      ],
      [
        'Employee 9',
        'Support',
        'North',
        'Project C',
        'Contributor',
        148.0,
        7200.0,
        70.4,
        'Remote',
        '2024-09-15'
      ],
      [
        'Employee 10',
        'Marketing',
        'South',
        'Project D',
        'Lead',
        151.5,
        7475.0,
        71.7,
        'Active',
        '2025-01-15'
      ],
      [
        'Employee 11',
        'Engineering',
        'East',
        'Project E',
        'Contributor',
        155.0,
        7750.0,
        73.0,
        'On Leave',
        '2024-02-15'
      ],
      [
        'Employee 12',
        'Design',
        'West',
        'Project F',
        'Contributor',
        158.5,
        8025.0,
        74.3,
        'Remote',
        '2025-03-15'
      ],
      [
        'Employee 13',
        'Sales',
        'North',
        'Project A',
        'Lead',
        162.0,
        8300.0,
        75.6,
        'Active',
        '2024-04-15'
      ],
      [
        'Employee 14',
        'Support',
        'South',
        'Project B',
        'Contributor',
        165.5,
        8575.0,
        76.9,
        'On Leave',
        '2025-05-15'
      ],
      [
        'Employee 15',
        'Marketing',
        'East',
        'Project C',
        'Contributor',
        169.0,
        8850.0,
        78.2,
        'Remote',
        '2024-06-15'
      ],
      [
        'Employee 16',
        'Engineering',
        'West',
        'Project D',
        'Lead',
        172.5,
        9125.0,
        79.5,
        'Active',
        '2025-07-15'
      ],
      [
        'Employee 17',
        'Design',
        'North',
        'Project E',
        'Contributor',
        176.0,
        9400.0,
        80.8,
        'On Leave',
        '2024-08-15'
      ],
      [
        'Employee 18',
        'Sales',
        'South',
        'Project F',
        'Contributor',
        179.5,
        9675.0,
        82.1,
        'Remote',
        '2025-09-15'
      ],
      [
        'Employee 19',
        'Support',
        'East',
        'Project A',
        'Lead',
        183.0,
        9950.0,
        83.4,
        'Active',
        '2024-01-15'
      ],
      [
        'Employee 20',
        'Marketing',
        'West',
        'Project B',
        'Contributor',
        186.5,
        10225.0,
        84.7,
        'On Leave',
        '2025-02-15'
      ],
      [
        'Employee 21',
        'Engineering',
        'North',
        'Project C',
        'Contributor',
        190.0,
        10500.0,
        86.0,
        'Remote',
        '2024-03-15'
      ],
      [
        'Employee 22',
        'Design',
        'South',
        'Project D',
        'Lead',
        193.5,
        10775.0,
        87.3,
        'Active',
        '2025-04-15'
      ],
      [
        'Employee 23',
        'Sales',
        'East',
        'Project E',
        'Contributor',
        197.0,
        11050.0,
        88.6,
        'On Leave',
        '2024-05-15'
      ],
      [
        'Employee 24',
        'Support',
        'West',
        'Project F',
        'Contributor',
        200.5,
        11325.0,
        89.9,
        'Remote',
        '2025-06-15'
      ],
      [
        'Employee 25',
        'Marketing',
        'North',
        'Project A',
        'Lead',
        204.0,
        11600.0,
        91.2,
        'Active',
        '2024-07-15'
      ],
      [
        'Employee 26',
        'Engineering',
        'South',
        'Project B',
        'Contributor',
        207.5,
        11875.0,
        92.5,
        'On Leave',
        '2025-08-15'
      ],
      [
        'Employee 27',
        'Design',
        'East',
        'Project C',
        'Contributor',
        211.0,
        12150.0,
        93.8,
        'Remote',
        '2024-09-15'
      ],
      [
        'Employee 28',
        'Sales',
        'West',
        'Project D',
        'Lead',
        214.5,
        12425.0,
        95.1,
        'Active',
        '2025-01-15'
      ],
    ];
    return raw.asMap().entries.map((e) {
      return GridSheetRow(
        key: ValueKey('row_${e.key}'),
        index: e.key,
        data: e.value,
        height: Constants.rowHeight,
      );
    }).toList();
  }
}
