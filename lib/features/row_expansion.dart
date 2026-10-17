import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class RowExpansion extends StatefulWidget {
  const RowExpansion({super.key});

  @override
  State<RowExpansion> createState() => _RowExpansionState();
}

class _RowExpansionState extends State<RowExpansion> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'Tap the chevron in the serial-number column to expand a row and reveal every field in a detail panel.',
  );

  bool _enabled = true;
  bool _showOnlyEditableColumns = false;
  bool _expandToggleOnStageColumn = false;
  bool _hideIndexChevron = false;

  static const _cyclablePanelHeights = [180.0, 220.0, 300.0];
  double _panelHeight = _cyclablePanelHeights[1];

  static const _cyclableDurations = [
    Duration(milliseconds: 150),
    Duration(milliseconds: 200),
    Duration(milliseconds: 350),
  ];
  Duration _animationDuration = _cyclableDurations[1];

  // Drive rowStateIndicatorBuilder below — both the row's own state icon
  // (serial-number column) and the row-expansion panel's per-field
  // modified indicator share this same builder, so cycling
  // either one here updates both places at once.
  static const _cyclableIndicatorIcons = [
    (icon: Icons.edit, label: 'Edit'),
    (icon: Icons.warning_amber_rounded, label: 'Warning'),
    (icon: Icons.priority_high_rounded, label: 'Priority'),
  ];
  int _indicatorIconIndex = 0;

  static const _cyclableIndicatorColorLabels = ['Orange', 'Red', 'Purple'];
  int _indicatorColorIndex = 0;

  Color _indicatorColor(BuildContext context) {
    switch (_indicatorColorIndex) {
      case 1:
        return context.accents.red;
      case 2:
        return context.accents.purple;
      default:
        return context.accents.orange;
    }
  }

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageTemplate(
      title: 'Row Expansion',
      icon: Icons.unfold_more_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoToggleButton(
            label: 'Enabled',
            icon: Icons.unfold_more_outlined,
            color: context.accents.deepPurple,
            value: _enabled,
            onChanged: _toggleEnabled,
            tooltip: 'Toggle whether rows can expand at all',
          ),
          DemoToggleButton(
            label: 'Editable Only',
            icon: Icons.edit_outlined,
            color: context.accents.blue,
            value: _showOnlyEditableColumns,
            onChanged: _toggleShowOnlyEditableColumns,
            tooltip: 'Hide read-only fields from the expanded panel',
          ),
          DemoToggleButton(
            label: 'Toggle in Stage',
            icon: Icons.unfold_more_double_outlined,
            color: context.accents.pink,
            value: _expandToggleOnStageColumn,
            onChanged: _toggleExpandToggleOnStageColumn,
            tooltip:
                'Relocate the expand/collapse toggle into the Stage column '
                'via cellBuilder, using GridSheetCellContext.onToggleRowExpansion/'
                'isRowExpanded — the serial-number chevron still works too',
          ),
          DemoToggleButton(
            label: 'Hide Index Chevron',
            icon: Icons.visibility_off_outlined,
            color: context.accents.neutral,
            value: _hideIndexChevron,
            onChanged: _toggleHideIndexChevron,
            tooltip: 'Suppress the built-in chevron by returning a non-null '
                'cellBuilder widget for GridSheetCellKind.indexing — pair '
                'with "Toggle in Stage" to move expansion there entirely',
          ),
          DemoActionButton(
            label: '${_panelHeight.toInt()}px',
            icon: Icons.height_outlined,
            color: context.accents.teal,
            onPressed: _cyclePanelHeight,
            tooltip: 'Cycle the expanded panel\'s height',
          ),
          DemoActionButton(
            label: '${_animationDuration.inMilliseconds}ms',
            icon: Icons.timer_outlined,
            color: context.accents.orange,
            onPressed: _cycleAnimationDuration,
            tooltip: 'Cycle the expand/collapse animation\'s duration',
          ),
          DemoActionButton(
            label:
                'Icon: ${_cyclableIndicatorIcons[_indicatorIconIndex].label}',
            icon: _cyclableIndicatorIcons[_indicatorIconIndex].icon,
            color: _indicatorColor(context),
            onPressed: _cycleIndicatorIcon,
            tooltip: 'Cycle the modified-row indicator icon',
          ),
          DemoActionButton(
            label:
                'Color: ${_cyclableIndicatorColorLabels[_indicatorColorIndex]}',
            icon: Icons.palette_outlined,
            color: _indicatorColor(context),
            onPressed: _cycleIndicatorColor,
            tooltip: 'Cycle the modified-row indicator color',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(
            enableRowSelectionOnFirstColumnTap: true),
        rowExpansionConfiguration: GridSheetRowExpansionConfiguration(
          enabled: _enabled,
          panelHeight: _panelHeight,
          animationDuration: _animationDuration,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          icon: Icons.chevron_right,
          showOnlyEditableColumns: _showOnlyEditableColumns,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        cellBuilder: (!_expandToggleOnStageColumn && !_hideIndexChevron)
            ? null
            : (cell) {
                if (_hideIndexChevron &&
                    cell.kind == GridSheetCellKind.indexing) {
                  return Text('${cell.rowIndex}', style: cell.textStyle);
                }
                if (!_expandToggleOnStageColumn ||
                    cell.kind != GridSheetCellKind.row ||
                    cell.column.name != 'STAGE') {
                  return null; // fall back to the default cell everywhere else
                }
                return Row(
                  children: [
                    GestureDetector(
                      onTap: cell.onToggleRowExpansion,
                      child: Icon(
                        cell.isRowExpanded == true
                            ? Icons.expand_more
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: context.accents.pink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: cell.defaultCellWidget!),
                  ],
                );
              },
        onLoaded: (event) => gridManager = event.gridManager,
        onCellValueChanged: (event) {
          status.value =
              '${event.title}: ${event.oldValue} → ${event.newValue}';
        },
        rowStateIndicatorBuilder: (row) {
          if (row.isModified) {
            return GridSheetRowStateIndicator(
              color: _indicatorColor(context),
              icon: Icon(_cyclableIndicatorIcons[_indicatorIconIndex].icon,
                  size: 12),
            );
          }
          return null; // default look
        },
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['CANDIDATE', 'ROLE', 'STAGE', 'EMAIL', 'PHONE', 'NOTES'];
    const titles = [
      'Candidate',
      'Role',
      'Stage',
      'Email',
      'Phone',
      'Interviewer Notes',
    ];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.dropdown(
          options: ['Screening', 'Interview', 'Offer', 'Hired']),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
    ];
    const widths = [140.0, 160.0, 140.0, 200.0, 120.0, 300.0];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_${i + 1}'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        editable: i != 3,
        hasTextController: types[i].kind != GridSheetColumnKind.dropdown,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = [
      [
        'Ava Thompson',
        'Frontend Engineer',
        'Interview',
        'ava.t@example.com',
        '+1 555-0110',
        'Strong React portfolio, good communicator.'
      ],
      [
        'Liam Chen',
        'Backend Engineer',
        'Offer',
        'liam.c@example.com',
        '+1 555-0142',
        'Excellent systems design round.'
      ],
      [
        'Noah Patel',
        'Product Designer',
        'Screening',
        'noah.p@example.com',
        '+1 555-0177',
        'Awaiting portfolio review.'
      ],
      [
        'Maya Rodriguez',
        'Data Analyst',
        'Hired',
        'maya.r@example.com',
        '+1 555-0193',
        'Started onboarding on Monday.'
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

  void _toggleEnabled(bool value) {
    setState(() => _enabled = value);
    status.value = value
        ? 'Row expansion enabled — tap the chevron to expand a row.'
        : 'Row expansion disabled — the chevron is hidden.';
  }

  void _toggleShowOnlyEditableColumns(bool value) {
    setState(() => _showOnlyEditableColumns = value);
    status.value = value
        ? 'showOnlyEditableColumns: ON — the panel now hides read-only fields like Email.'
        : 'showOnlyEditableColumns: OFF — the panel shows every visible column.';
  }

  void _toggleExpandToggleOnStageColumn(bool value) {
    setState(() => _expandToggleOnStageColumn = value);
    status.value = value
        ? 'cellBuilder now adds an expand/collapse icon to the Stage column too, '
            'wired to GridSheetCellContext.onToggleRowExpansion/isRowExpanded.'
        : 'Stage column back to its default dropdown cell — the serial-number '
            'chevron is the only toggle again.';
  }

  void _toggleHideIndexChevron(bool value) {
    setState(() => _hideIndexChevron = value);
    status.value = value
        ? 'Serial-number column now shows a plain row number — cellBuilder '
            'returns a non-null widget for GridSheetCellKind.indexing, so the '
            'built-in chevron never gets built. Tapping it still selects the '
            'row; enable "Toggle in Stage" too to expand from there instead.'
        : 'Serial-number column back to its default row number + chevron.';
  }

  void _cyclePanelHeight() {
    final next = (_cyclablePanelHeights.indexOf(_panelHeight) + 1) %
        _cyclablePanelHeights.length;
    setState(() => _panelHeight = _cyclablePanelHeights[next]);
    status.value = 'panelHeight: ${_panelHeight.toInt()}px';
  }

  void _cycleAnimationDuration() {
    final next = (_cyclableDurations.indexOf(_animationDuration) + 1) %
        _cyclableDurations.length;
    setState(() => _animationDuration = _cyclableDurations[next]);
    status.value = 'animationDuration: ${_animationDuration.inMilliseconds}ms';
  }

  void _cycleIndicatorIcon() {
    setState(() => _indicatorIconIndex =
        (_indicatorIconIndex + 1) % _cyclableIndicatorIcons.length);
    status.value =
        'rowStateIndicatorBuilder icon:${_cyclableIndicatorIcons[_indicatorIconIndex].label} '
        '— shown on modified rows and their changed fields in the panel.';
  }

  void _cycleIndicatorColor() {
    setState(() => _indicatorColorIndex =
        (_indicatorColorIndex + 1) % _cyclableIndicatorColorLabels.length);
    status.value =
        'rowStateIndicatorBuilder color:${_cyclableIndicatorColorLabels[_indicatorColorIndex]} '
        '— shown on modified rows and their changed fields in the panel.';
  }
}
