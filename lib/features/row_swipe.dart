import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class RowSwipe extends StatefulWidget {
  const RowSwipe({super.key});

  @override
  State<RowSwipe> createState() => _RowSwipeState();
}

class _RowSwipeState extends State<RowSwipe> {
  final ValueNotifier<String> status = ValueNotifier(
    'Swipe a row right to save, left for actions (touch, or mouse if enabled)',
  );

  /// Master switch. Toggling it at runtime keeps the rows (and any cell being
  /// edited); only the swipe gesture turns on and off.
  bool _swipeEnabled = true;

  /// Start side: "Save". Slides back by default.
  bool _startSide = true;
  bool _startHoldOpen = false;

  /// End side: "Edit / Delete" actions. Held open by default so the actions
  /// can be tapped.
  bool _endSide = true;
  bool _endHoldOpen = true;

  /// Full swipe: start saves (async, awaited), end deletes the row.
  bool _fullSwipe = true;

  bool _allowMouse = true;

  /// Autofill shows a fill handle on the selected cell. Dragging the handle
  /// fills cells and never swipes the row.
  bool _autoFill = false;

  /// Demonstrates the end side's canSwipe: capital cities can't be swiped
  /// for delete (the start side still saves them).
  bool _protectCapitals = false;

  /// The Rating column is a Slider. Wrapped in GridSheetRowSwipeExclusion it
  /// keeps its drag; unwrapped, a sideways drag on it swipes the row instead.
  bool _sliderExclusion = true;

  /// Wide table overflows the viewport, so swipes in the scrollable pane are
  /// only claimed at the scroll edges. Narrow table fits: both directions
  /// swipe anywhere.
  bool _wideTable = true;

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  Set<PointerDeviceKind> get _kinds => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        if (_allowMouse) PointerDeviceKind.mouse,
      };

  static GridSheetRowSwipeRelease _release(bool holdOpen) => holdOpen
      ? GridSheetRowSwipeRelease.holdOpen
      : GridSheetRowSwipeRelease.slideBack;

  String _city(GridSheetManager manager, ValueKey<String> key) =>
      manager.rows.find(key)?.data.first.toString() ?? key.value;

  DemoToggleButton _toggle({
    required String label,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String tooltip,
    required String Function(bool v) message,
  }) =>
      DemoToggleButton(
        label: label,
        icon: icon,
        color: color,
        value: value,
        onChanged: (v) {
          setState(() => onChanged(v));
          status.value = message(v);
        },
        tooltip: tooltip,
      );

  @override
  Widget build(BuildContext context) {
    final accents = context.accents;
    return FeaturePageTemplate(
      title: 'Row Swipe',
      icon: Icons.swipe,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          _toggle(
            label: 'Swipe',
            icon: Icons.swipe,
            color: accents.teal,
            value: _swipeEnabled,
            onChanged: (v) => _swipeEnabled = v,
            tooltip: 'Turn row swiping on or off at runtime',
            message: (v) => 'enabled: $v (rows and cell edits are kept)',
          ),
          _toggle(
            label: 'Start Side',
            icon: Icons.swipe_right_alt,
            color: accents.green,
            value: _startSide,
            onChanged: (v) => _startSide = v,
            tooltip: 'Drag toward the end to reveal Save',
            message: (v) => 'start: ${v ? "Save side" : "null (off)"}',
          ),
          _toggle(
            label: 'Start Hold Open',
            icon: Icons.push_pin_outlined,
            color: accents.green,
            value: _startHoldOpen,
            onChanged: (v) => _startHoldOpen = v,
            tooltip: 'Start side: hold open (tap Save) or slide back',
            message: (v) => 'start.release: ${_release(v).name}',
          ),
          _toggle(
            label: 'End Side',
            icon: Icons.swipe_left_alt,
            color: accents.red,
            value: _endSide,
            onChanged: (v) => _endSide = v,
            tooltip: 'Drag toward the start to reveal Edit / Delete',
            message: (v) => 'end: ${v ? "Edit / Delete side" : "null (off)"}',
          ),
          _toggle(
            label: 'End Hold Open',
            icon: Icons.push_pin_outlined,
            color: accents.red,
            value: _endHoldOpen,
            onChanged: (v) => _endHoldOpen = v,
            tooltip: 'End side: hold open (tap actions) or slide back',
            message: (v) => 'end.release: ${_release(v).name}',
          ),
          _toggle(
            label: 'Full Swipe',
            icon: Icons.keyboard_double_arrow_right,
            color: accents.deepOrange,
            value: _fullSwipe,
            onChanged: (v) => _fullSwipe = v,
            tooltip: 'Swipe all the way: start saves, end deletes',
            message: (v) =>
                'onFullSwipe: ${v ? "start saves, end deletes" : "null (off)"}',
          ),
          _toggle(
            label: 'Mouse Drag',
            icon: Icons.mouse_outlined,
            color: accents.purple,
            value: _allowMouse,
            onChanged: (v) => _allowMouse = v,
            tooltip: 'Allow swiping with a mouse (touch/stylus always work)',
            message: (v) => 'allowedPointerKinds: '
                '${v ? "touch, stylus, mouse" : "touch, stylus"}',
          ),
          _toggle(
            label: 'Wide Table',
            icon: Icons.width_full,
            color: accents.blue,
            value: _wideTable,
            onChanged: (v) => _wideTable = v,
            tooltip: 'Overflowing table vs. a table that fits the viewport',
            message: (v) => v
                ? 'Wide table: swipes claimed only at the scroll edges'
                : 'Narrow table: both directions swipe anywhere',
          ),
          _toggle(
            label: 'Autofill',
            icon: Icons.format_color_fill,
            color: accents.orange,
            value: _autoFill,
            onChanged: (v) => _autoFill = v,
            tooltip: 'Show the fill handle; dragging it never swipes the row',
            message: (v) => v
                ? 'Autofill on: select a cell, then drag its fill handle'
                : 'Autofill off',
          ),
          _toggle(
            label: 'Protect Capitals',
            icon: Icons.lock_outline,
            color: accents.indigo,
            value: _protectCapitals,
            onChanged: (v) => _protectCapitals = v,
            tooltip: "End side's canSwipe refuses capital cities",
            message: (v) => v
                ? 'end.canSwipe: capitals can\'t be swiped for delete'
                : 'end.canSwipe: null (every row swipes)',
          ),
          _toggle(
            label: 'Slider Exclusion',
            icon: Icons.tune,
            color: accents.pink,
            value: _sliderExclusion,
            onChanged: (v) => _sliderExclusion = v,
            tooltip: 'Wrap the Rating slider in GridSheetRowSwipeExclusion',
            message: (v) => v
                ? 'Rating slider wrapped: dragging it moves the slider'
                : 'Rating slider unwrapped: dragging it swipes the row',
          ),
        ],
      ),
      grid: GridSheet(
        // Columns/rows are read once by the grid, so switch tables by key.
        key: ValueKey('swipe_grid_$_wideTable'),
        columns: _columns(),
        rows: _rows(),
        // The fill handle needs cell selection.
        configuration: GridSheetConfiguration(enableCellSelection: _autoFill),
        autoFillConfiguration: GridSheetAutoFillConfiguration(
          enabled: _autoFill,
        ),
        styleConfiguration: styleConfig(context),
        scrollConfiguration: scrollConfig(context),
        cellBuilder: _buildCell,
        rowSwipeConfiguration: GridSheetRowSwipeConfiguration(
          enabled: _swipeEnabled,
          start: _startSide ? _saveSide(accents) : null,
          end: _endSide ? _actionsSide(accents) : null,
        ),
      ),
    );
  }

  // ── Rating cell: a Slider ─────────────────────────────────────────────────

  /// Renders RATING as a Slider; every other cell uses the default.
  Widget? _buildCell(GridSheetCellContext cell) {
    final row = cell.row;
    if (cell.kind != GridSheetCellKind.row ||
        row == null ||
        cell.column.name != _ratingName) {
      return null;
    }
    final value = (row.data[cell.column.index] as num).toDouble();
    final slider = SliderTheme(
      data: SliderTheme.of(cell.context).copyWith(
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: Slider(
        value: value,
        onChanged: (v) {
          cell.gridManager.cells.update(
            rowKey: row.key,
            columnKey: cell.column.key,
            value: v,
          );
          status.value = 'Rating ${row.data.first}: ${v.toStringAsFixed(2)}';
        },
      ),
    );
    // A Slider runs its own horizontal drag, which the row swipe would
    // otherwise claim first.
    return _sliderExclusion
        ? GridSheetRowSwipeExclusion(child: slider)
        : slider;
  }

  // ── Start side: Save ─────────────────────────────────────────────────────

  GridSheetRowSwipeSideConfiguration _saveSide(ThemeAccents accents) {
    return GridSheetRowSwipeSideConfiguration(
      release: _release(_startHoldOpen),
      revealExtent: 96,
      allowedPointerKinds: _kinds,
      onFullSwipe: _fullSwipe ? (e) => _save(e.gridManager, e.key) : null,
      revealBuilder: (context, details) => ColoredBox(
        color: accents.green,
        child: _startHoldOpen && !details.fullSwipeReached
            ? TextButton.icon(
                onPressed: () async {
                  details.close();
                  await _save(details.gridManager, details.rowKey);
                },
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: const Text('Save', style: _actionText),
              )
            : _stripLabel(
                Icons.save_outlined,
                details.fullSwipeReached ? 'Release to save' : 'Save',
                showText: details.revealedExtent > 64,
              ),
      ),
      onSwipeStart: (e) => status.value =
          'start.onSwipeStart: ${_city(e.gridManager, e.key)}',
      onSwipeEnd: (e) => status.value =
          'start.onSwipeEnd: released at ${e.revealedExtent.toStringAsFixed(0)}px, '
              'velocity ${e.velocity.toStringAsFixed(0)}',
    );
  }

  /// A full swipe's operation can be async: the row stays slid out until it
  /// finishes, then slides back because the row still exists.
  Future<void> _save(GridSheetManager manager, ValueKey<String> key) async {
    final city = _city(manager, key);
    status.value = 'Saving $city…';
    await Future<void>.delayed(const Duration(milliseconds: 600));
    status.value = 'Saved $city';
  }

  // ── End side: Edit / Delete ──────────────────────────────────────────────

  GridSheetRowSwipeSideConfiguration _actionsSide(ThemeAccents accents) {
    return GridSheetRowSwipeSideConfiguration(
      release: _release(_endHoldOpen),
      revealExtent: 160,
      allowedPointerKinds: _kinds,
      canSwipe: _protectCapitals ? (row) => row.data[3] != true : null,
      onFullSwipe: _fullSwipe ? (e) => _delete(e.gridManager, e.key) : null,
      revealBuilder: (context, details) {
        if (details.fullSwipeReached) {
          return ColoredBox(
            color: accents.red,
            child: _stripLabel(Icons.delete_outline, 'Release to delete'),
          );
        }
        // Each action takes half the strip; it only becomes tappable once
        // the row is held open.
        return Row(
          children: [
            Expanded(
              child: _action(
                color: accents.blue,
                icon: Icons.edit_outlined,
                label: 'Edit',
                showText: details.revealedExtent > 120,
                onTap: () {
                  status.value =
                      'Edit ${_city(details.gridManager, details.rowKey)}';
                  details.close();
                },
              ),
            ),
            Expanded(
              child: _action(
                color: accents.red,
                icon: Icons.delete_outline,
                label: 'Delete',
                showText: details.revealedExtent > 120,
                onTap: () => _delete(details.gridManager, details.rowKey),
              ),
            ),
          ],
        );
      },
      onSwipeStart: (e) =>
          status.value = 'end.onSwipeStart: ${_city(e.gridManager, e.key)}',
      onSwipeEnd: (e) => status.value =
          'end.onSwipeEnd: released at ${e.revealedExtent.toStringAsFixed(0)}px, '
              'velocity ${e.velocity.toStringAsFixed(0)}',
    );
  }

  /// Deleting the row removes it from the grid, so after a full swipe it
  /// stays gone instead of sliding back.
  Future<void> _delete(GridSheetManager manager, ValueKey<String> key) async {
    final city = _city(manager, key);
    await manager.rows.delete([key]);
    status.value = 'Deleted $city';
  }

  // ── Strip pieces ─────────────────────────────────────────────────────────

  static const _actionText = TextStyle(color: Colors.white, fontSize: 11);

  Widget _stripLabel(IconData icon, String text, {bool showText = true}) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              if (showText) ...[
                const SizedBox(width: 6),
                Text(text, style: _actionText),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _action({
    required Color color,
    required IconData icon,
    required String label,
    required bool showText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                if (showText) Text(label, style: _actionText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Data ────────────────────────────────────────────────────────────────

  /// RATING (index 4) is rendered as a Slider by [_buildCell].
  static const _ratingName = 'RATING';
  static const _baseNames = [
    'CITY',
    'COUNTRY',
    'POPULATION_M',
    'IS_CAPITAL',
    _ratingName,
  ];
  static const _baseTitles = [
    'City',
    'Country',
    'Population (M)',
    'Capital?',
    'Rating',
  ];
  static const _baseTypes = [
    GridSheetColumnType.text(),
    GridSheetColumnType.text(),
    GridSheetColumnType.double(),
    GridSheetColumnType.boolean(),
    GridSheetColumnType.double(),
  ];
  static const _baseWidths = [100.0, 100.0, 140.0, 100.0, 160.0];
  static const _ratings = [0.9, 0.7, 0.6, 0.8, 0.5, 0.4];

  static const _wideNames = [
    'AREA_KM2',
    'DENSITY',
    'TIMEZONE',
    'REGION',
    'FOUNDED'
  ];
  static const _wideTitles = [
    'Area (km²)',
    'Density',
    'Timezone',
    'Region',
    'Founded'
  ];
  static const _wideTypes = [
    GridSheetColumnType.double(),
    GridSheetColumnType.double(),
    GridSheetColumnType.text(),
    GridSheetColumnType.text(),
    GridSheetColumnType.text(),
  ];
  static const _wideWidths = [140.0, 120.0, 160.0, 160.0, 140.0];

  List<GridSheetColumn> _columns() {
    final names = [..._baseNames, if (_wideTable) ..._wideNames];
    final titles = [..._baseTitles, if (_wideTable) ..._wideTitles];
    final types = [..._baseTypes, if (_wideTable) ..._wideTypes];
    final widths = [..._baseWidths, if (_wideTable) ..._wideWidths];
    return List.generate(names.length, (i) {
      return GridSheetColumn(
        key: ValueKey('col_$i'),
        index: i,
        name: names[i],
        title: titles[i],
        type: types[i],
        width: widths[i],
        hasTextController: types[i].kind != GridSheetColumnKind.boolean &&
            names[i] != _ratingName,
        textAlign: types[i].kind == GridSheetColumnKind.double
            ? TextAlign.right
            : TextAlign.left,
      );
    });
  }

  List<GridSheetRow> _rows() {
    final raw = <List<Object>>[
      ['Tokyo', 'Japan', 37.4, true, 2194.0, 6349.0, 'UTC+9', 'Kanto', '1457'],
      [
        'Delhi',
        'India',
        32.9,
        true,
        1484.0,
        11312.0,
        'UTC+5:30',
        'North',
        '736'
      ],
      [
        'Shanghai',
        'China',
        28.5,
        false,
        6341.0,
        3854.0,
        'UTC+8',
        'East',
        '751'
      ],
      [
        'Cairo',
        'Egypt',
        21.3,
        true,
        3085.0,
        6903.0,
        'UTC+2',
        'Nile Delta',
        '969'
      ],
      [
        'Mexico City',
        'Mexico',
        22.1,
        true,
        1485.0,
        6000.0,
        'UTC-6',
        'Central',
        '1325'
      ],
      [
        'Mumbai',
        'India',
        20.9,
        false,
        603.0,
        20694.0,
        'UTC+5:30',
        'West',
        '1507'
      ],
    ];
    return raw.asMap().entries.map((e) {
      // raw holds the 4 base values, then the wide ones; RATING goes between.
      final base = e.value.take(4);
      final wide = e.value.skip(4);
      return GridSheetRow(
        key: ValueKey('row_${e.key}'),
        index: e.key,
        data: [...base, _ratings[e.key], if (_wideTable) ...wide],
        height: Constants.rowHeight,
      );
    }).toList();
  }
}
