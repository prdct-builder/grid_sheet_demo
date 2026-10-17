import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

/// Demonstrates [GridSheetAnimationConfiguration]'s four opt-in animations:
/// the column reveal on mount/pagination, row reveal on sort/filter,
/// cell-change flash, and column visibility fade.
class ColumnAnimation extends StatefulWidget {
  const ColumnAnimation({super.key});

  @override
  State<ColumnAnimation> createState() => _ColumnAnimationState();
}

class _ColumnAnimationState extends State<ColumnAnimation> {
  final ValueNotifier<String> status = ValueNotifier(
    'animationConfiguration.enabled is on — the frozen ID column and '
    'then the scrollable columns slide/fade in left to right on mount, '
    'and again on every page change (replayOnPageChange).',
  );

  // A handle for the "live" demo actions below (bump a cell, show/hide a
  // column). Every toggle just passes a new animationConfiguration; the
  // grid follows it without being recreated.
  final GlobalKey<GridSheetState> _gridKey = GlobalKey<GridSheetState>();

  // The column reveal. Replay turns it off for one frame and back on, which
  // plays it again.
  bool _revealEnabled = true;

  bool _replayOnPageChange = true;
  bool _animateRowsOnSortOrFilter = false;
  bool _cellChangeFlashEnabled = false;
  bool _columnVisibilityFadeEnabled = false;

  bool _statusColumnHidden = false;
  int _bumpCounter = 0;
  bool _customTransition = false;
  bool _customFlash = false;

  static const _cyclableDurations = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 900),
    Duration(milliseconds: 1500),
  ];
  Duration _duration = _cyclableDurations[1];

  static const _cyclableSlideDistances = [16.0, 24.0, 48.0];
  double _slideDistance = _cyclableSlideDistances[1];

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Column Animation',
      icon: Icons.view_carousel_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: '${_duration.inMilliseconds}ms',
            icon: Icons.timer_outlined,
            color: context.accents.blue,
            onPressed: _cycleDuration,
            tooltip: 'Cycle the reveal animation\'s duration',
          ),
          DemoActionButton(
            label: '${_slideDistance.toInt()}px',
            icon: Icons.swap_horiz,
            color: context.accents.teal,
            onPressed: _cycleSlideDistance,
            tooltip: 'Cycle the reveal animation\'s slide distance',
          ),
          DemoActionButton(
            label: 'Replay',
            icon: Icons.replay_outlined,
            color: context.accents.deepPurple,
            onPressed: _replay,
            tooltip: 'Replay the column reveal (turns enabled off and back on)',
          ),
          DemoToggleButton(
            label: 'Replay On Page Change',
            icon: Icons.repeat_outlined,
            color: context.accents.indigo,
            value: _replayOnPageChange,
            onChanged: _toggleReplayOnPageChange,
            tooltip: 'Replay the reveal animation every time the page changes',
          ),
          DemoToggleButton(
            label: 'On Sort/Filter',
            icon: Icons.swap_vert_outlined,
            color: context.accents.pink,
            value: _animateRowsOnSortOrFilter,
            onChanged: _toggleRevealRowsOnSortOrFilter,
            tooltip: 'Replay a row reveal cascade after sorting or filtering',
          ),
          DemoToggleButton(
            label: 'On Value Change',
            icon: Icons.flash_on_outlined,
            color: context.accents.amber,
            value: _cellChangeFlashEnabled,
            onChanged: _toggleCellChangeFlash,
            tooltip: 'Flash a cell briefly whenever its value changes',
          ),
          DemoActionButton(
            label: 'Bump a Cell',
            icon: Icons.bolt_outlined,
            color: context.accents.amber,
            onPressed: _bumpCell,
            tooltip: 'Change a Salary cell to trigger the flash',
          ),
          DemoToggleButton(
            label: 'On Show',
            icon: Icons.visibility_outlined,
            color: context.accents.green,
            value: _columnVisibilityFadeEnabled,
            onChanged: _toggleColumnVisibilityFade,
            tooltip: 'Fade columns in/out when hidden or shown',
          ),
          DemoActionButton(
            label: _statusColumnHidden ? 'Show Status' : 'Hide Status',
            icon: _statusColumnHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: context.accents.green,
            onPressed: _toggleStatusColumn,
            tooltip: 'Show or hide the STATUS column',
          ),
          DemoActionButton(
            label:
                _customTransition ? 'Transition: Scale' : 'Transition: Slide',
            icon: Icons.zoom_out_map_outlined,
            color: context.accents.deepOrange,
            onPressed: () {
              setState(() {
                _customTransition = !_customTransition;
              });
              status.value = _customTransition
                  ? 'revealTransitionBuilder: custom scale+fade in place of the built-in slide+fade.'
                  : 'revealTransitionBuilder: null — back to the built-in slide+fade.';
            },
            tooltip: 'Switch the reveal animation\'s transition style',
          ),
          DemoActionButton(
            label: _customFlash ? 'Flash: Border Pulse' : 'Flash: Fill',
            icon: Icons.border_color_outlined,
            color: context.accents.pink,
            onPressed: () {
              setState(() {
                _customFlash = !_customFlash;
              });
              status.value = _customFlash
                  ? 'cellFlashBuilder: custom pulsing border in place of the built-in color fill.'
                  : 'cellFlashBuilder: null — back to the built-in color fill.';
            },
            tooltip: 'Switch the cell-change flash\'s visual style',
          ),
        ],
      ),
      grid: GridSheet(
        key: _gridKey,
        columns: _columns(),
        rows: _rows(),
        animationConfiguration: GridSheetAnimationConfiguration(
          enabled: _revealEnabled,
          animationDuration: _duration,
          slideDistance: _slideDistance,
          replayOnPageChange: _replayOnPageChange,
          animateRowsOnSortOrFilter: _animateRowsOnSortOrFilter,
          cellChangeFlashEnabled: _cellChangeFlashEnabled,
          columnVisibilityFadeEnabled: _columnVisibilityFadeEnabled,
          revealTransitionBuilder: _customTransition
              ? (context, child, progress, axis) {
                  return Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.7 + 0.3 * progress,
                      child: child,
                    ),
                  );
                }
              : null,
          cellFlashBuilder: _customFlash
              ? (context, progress) {
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.accents.pink
                                .withValues(alpha: progress),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              : null,
        ),
        configuration: GridSheetConfiguration(
          rowsPerPage: 5,
          showColumnFilters: true,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = [
      'ID',
      'NAME',
      'DEPARTMENT',
      'ROLE',
      'LOCATION',
      'STATUS',
      'SALARY',
      'JOINED',
    ];
    const titles = [
      'ID',
      'Name',
      'Department',
      'Role',
      'Location',
      'Status',
      'Salary',
      'Joined',
    ];
    const types = [
      GridSheetColumnType.integer(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.datetime(),
    ];
    const widths = [60.0, 140.0, 120.0, 140.0, 100.0, 80.0, 80.0, 120.0];

    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        sortable: true,
        pinnedLeft: i < 1,
        textAlign: types[i].kind == GridSheetColumnKind.double ||
                types[i].kind == GridSheetColumnKind.integer
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      [
        2,
        'Ava Thompson',
        'Engineering',
        'Backend Developer',
        'Remote',
        'Active',
        92000.0,
        '2022-03-14'
      ],
      [
        4,
        'Liam Chen',
        'Engineering',
        'Frontend Developer',
        'New York',
        'Active',
        88000.0,
        '2021-11-02'
      ],
      [
        6,
        'Sofia Rossi',
        'Design',
        'Product Designer',
        'Milan',
        'Active',
        79000.0,
        '2023-01-20'
      ],
      [
        8,
        'Noah Patel',
        'Sales',
        'Account Executive',
        'London',
        'On Leave',
        65000.0,
        '2020-06-09'
      ],
      [
        10,
        'Emma Garcia',
        'Marketing',
        'Content Strategist',
        'Remote',
        'Active',
        71000.0,
        '2022-09-30'
      ],
      [
        1,
        'Oliver Kim',
        'Engineering',
        'DevOps Engineer',
        'Seoul',
        'Active',
        95000.0,
        '2019-04-18'
      ],
      [
        3,
        'Mia Johansson',
        'Support',
        'Support Lead',
        'Stockholm',
        'Active',
        68000.0,
        '2023-07-05'
      ],
      [
        5,
        'Lucas Müller',
        'Finance',
        'Financial Analyst',
        'Berlin',
        'Active',
        74000.0,
        '2021-02-11'
      ],
      [
        7,
        'Zara Ahmed',
        'Engineering',
        'QA Engineer',
        'Remote',
        'Active',
        70000.0,
        '2022-12-01'
      ],
      [
        9,
        'Ethan Brown',
        'Sales',
        'Sales Manager',
        'Toronto',
        'Active',
        98000.0,
        '2018-10-22'
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

  void _replay() {
    // Turning `enabled` back on plays the reveal once.
    setState(() => _revealEnabled = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _revealEnabled = true);
    });
    status.value = 'Replaying — enabled was turned off and back on, which '
        'plays the reveal again.';
  }

  void _cycleDuration() {
    final next =
        (_cyclableDurations.indexOf(_duration) + 1) % _cyclableDurations.length;
    setState(() {
      _duration = _cyclableDurations[next];
    });
    status.value = 'animationDuration: ${_duration.inMilliseconds}ms';
  }

  void _cycleSlideDistance() {
    final next = (_cyclableSlideDistances.indexOf(_slideDistance) + 1) %
        _cyclableSlideDistances.length;
    setState(() {
      _slideDistance = _cyclableSlideDistances[next];
    });
    status.value = 'slideDistance: ${_slideDistance}px';
  }

  void _toggleReplayOnPageChange(bool value) {
    setState(() {
      _replayOnPageChange = value;
    });
    status.value = value
        ? 'replayOnPageChange: ON — use the pagination footer below to flip '
            'pages and watch the columns cascade in again.'
        : 'replayOnPageChange: OFF — changing pages no longer replays the reveal.';
  }

  void _toggleRevealRowsOnSortOrFilter(bool value) {
    setState(() {
      _animateRowsOnSortOrFilter = value;
    });
    status.value = value
        ? 'animateRowsOnSortOrFilter: ON — click a sortable column header '
            '(e.g. Name or Salary) and watch the rows cascade back in.'
        : 'animateRowsOnSortOrFilter: OFF — sorting reorders rows instantly.';
  }

  void _toggleCellChangeFlash(bool value) {
    setState(() {
      _cellChangeFlashEnabled = value;
    });
    status.value = value
        ? 'cellChangeFlashEnabled: ON — use "Bump a Cell" below (or edit '
            'any cell directly) to see the flash.'
        : 'cellChangeFlashEnabled: OFF — cell edits no longer flash.';
  }

  void _bumpCell() {
    final manager = _gridKey.currentState;
    if (manager == null) return;
    _bumpCounter++;
    final rowIndex = _bumpCounter % 10;
    manager.cells.update(
      rowKey: ValueKey('row_$rowIndex'),
      columnKey: const ValueKey('col_6'), // Salary column
      value: 60000.0 + _bumpCounter * 137,
    );
    status.value = 'Bumped the Salary cell on row ${rowIndex + 1}'
        '${_cellChangeFlashEnabled ? ' — watch it flash.' : ' (enable Cell Flash above to see it flash).'}';
  }

  void _toggleColumnVisibilityFade(bool value) {
    setState(() {
      _columnVisibilityFadeEnabled = value;
    });
    status.value = value
        ? 'columnVisibilityFadeEnabled: ON — hide then show the Status '
            'column below to see it fade+shrink out, and fade+grow back in.'
        : 'columnVisibilityFadeEnabled: OFF — hiding/showing is instant.';
  }

  void _toggleStatusColumn() {
    final manager = _gridKey.currentState;
    if (manager == null) return;
    final hide = !_statusColumnHidden;
    setState(() => _statusColumnHidden = hide);
    if (hide) {
      manager.columns.hide(
          manager.columns.findByNames(['STATUS']).map((c) => c.key).toList());
      status.value = 'Status column hidden'
          '${_columnVisibilityFadeEnabled ? ' — fading out, columns to the right sliding left.' : ' (enable Column Fade above to see it fade out).'}';
    } else {
      manager.columns.show(
          manager.columns.findByNames(['STATUS']).map((c) => c.key).toList());
      status.value = 'Status column shown'
          '${_columnVisibilityFadeEnabled ? ' — fading in.' : ' (enable Column Fade above to see it fade in).'}';
    }
  }
}
