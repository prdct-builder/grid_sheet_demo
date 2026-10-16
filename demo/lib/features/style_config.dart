import 'package:flutter/material.dart';
import 'package:grid_sheet/grid_sheet.dart';

import '../demo/demo_helpers.dart';
import '../demo/constants.dart';
import '../design_system/design_system.dart';

class StyleLayoutConfiguration extends StatefulWidget {
  const StyleLayoutConfiguration({super.key});

  @override
  State<StyleLayoutConfiguration> createState() =>
      _StyleLayoutConfigurationState();
}

class _StyleLayoutConfigurationState extends State<StyleLayoutConfiguration> {
  late GridSheetManager gridManager;
  final ValueNotifier<String> status = ValueNotifier(
    'Layout toggles use gridManager.updateConfiguration; style toggles rebuild the '
    'GridSheetStyleConfiguration passed to the widget.',
  );

  // ---- Layout Configuration state (applied via GridSheetManager) ----
  bool _showRowBorders = true;
  bool _showColumnBorders = true;
  bool _showHeaderRowBorder = true;
  bool _showFilterRowBorder = true;

  // ---- Style Configuration state (applied by rebuilding the widget) ----
  int _themePresetIndex = 0;
  bool _boldHeader = true;
  double _cellFontSize = 14;
  double _borderWidth = 1;
  bool _customTextFieldBorder = false;

  static const List<_ThemePreset> _presets = [
    _ThemePreset(
      label: 'Default',
      light: _ThemeColors(
        background: Color(0xFFFFFFFF),
        header: Color(0xFFEEF0F7),
        selection: Color(0xFFE8ECFB),
        border: Color(0xFFE4E7F0),
        text: Color(0xFF2A2E43),
        radius: 4,
      ),
      dark: _ThemeColors(
        background: Color(0xFF1C1E2A),
        header: Color(0xFF262938),
        selection: Color(0xFF252C50),
        border: Color(0xFF3A3D4F),
        text: Color(0xFFEDEEF5),
        radius: 4,
      ),
    ),
    _ThemePreset(
      label: 'Ocean',
      light: _ThemeColors(
        background: Color(0xFFF3FAFB),
        header: Color(0xFFCFEFF3),
        selection: Color(0xFF80DEEA),
        border: Color(0xFF4DD0E1),
        text: Color(0xFF0B2E33),
        radius: 12,
      ),
      dark: _ThemeColors(
        background: Color(0xFF0D2A30),
        header: Color(0xFF123B42),
        selection: Color(0xFF26C6DA),
        border: Color(0xFF1E4E56),
        text: Color(0xFFD6F5F8),
        radius: 12,
      ),
    ),
    _ThemePreset(
      label: 'Sunset',
      light: _ThemeColors(
        background: Color(0xFFFFF8F2),
        header: Color(0xFFFFE0C2),
        selection: Color(0xFFFFCC80),
        border: Color(0xFFFFA726),
        text: Color(0xFF3D2B1F),
        radius: 0,
      ),
      dark: _ThemeColors(
        background: Color(0xFF2A1F1A),
        header: Color(0xFF3D2B1F),
        selection: Color(0xFFFFA726),
        border: Color(0xFF4A3527),
        text: Color(0xFFFDE7D9),
        radius: 0,
      ),
    ),
    _ThemePreset(
      label: 'Financial',
      light: _ThemeColors(
        background: Colors.white,
        header: Color(0xFFF0F2F5),
        selection: Color(0xFFA5D6A7),
        border: Color(0xFFD0D5DA),
        text: Color(0xFF0D1B0F),
        radius: 2,
      ),
      dark: _ThemeColors(
        background: Color(0xFF0D1117),
        header: Color(0xFF161B22),
        selection: Color(0xFF238636),
        border: Color(0xFF21262D),
        text: Color(0xFF00E676),
        radius: 2,
      ),
    ),
    _ThemePreset(
      label: 'Midnight',
      light: _ThemeColors(
        background: Color(0xFFF5F3FF),
        header: Color(0xFFE6E0FA),
        selection: Color(0xFFB39DDB),
        border: Color(0xFFD1C4E9),
        text: Color(0xFF1F1330),
        radius: 10,
      ),
      dark: _ThemeColors(
        background: Color(0xFF12131C),
        header: Color(0xFF1D1F2E),
        selection: Color(0xFF7C4DFF),
        border: Color(0xFF2A2C40),
        text: Color(0xFFE4DEFF),
        radius: 10,
      ),
    ),
  ];

  @override
  void dispose() {
    status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_themePresetIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? preset.dark : preset.light;
    return FeaturePageTemplate(
      title: 'Style & Layout Configuration',
      description:
          'GridSheetConfiguration controls structural layout toggles, while GridSheetStyleConfiguration '
          'controls the visual theme — colors, border radius, and text styles, each with its own light '
          'and dark variant.',
      icon: Icons.tune_outlined,
      status: status,
      toolbar: DemoToolbar(
        sections: [
          DemoActionButton(
            label: _showRowBorders ? 'Row Borders: On' : 'Row Borders: Off',
            icon: Icons.horizontal_rule,
            color: context.accents.blue,
            onPressed: () => setState(() {
              _showRowBorders = !_showRowBorders;
              _applyLayoutChange('showRowBorders = $_showRowBorders');
            }),
            tooltip: 'Toggle horizontal row borders',
          ),
          DemoActionButton(
            label: _showColumnBorders ? 'Col Borders: On' : 'Col Borders: Off',
            icon: Icons.view_column_outlined,
            color: context.accents.blue,
            onPressed: () => setState(() {
              _showColumnBorders = !_showColumnBorders;
              _applyLayoutChange('showColumnBorders = $_showColumnBorders');
            }),
            tooltip: 'Toggle vertical column borders',
          ),
          DemoActionButton(
            label: _showHeaderRowBorder
                ? 'Header Border: On'
                : 'Header Border: Off',
            icon: Icons.border_bottom,
            color: context.accents.blue,
            onPressed: () => setState(() {
              _showHeaderRowBorder = !_showHeaderRowBorder;
              _applyLayoutChange('showHeaderRowBorder = $_showHeaderRowBorder');
            }),
            tooltip:
                'Toggle the border below the header row, independently of showRowBorders',
          ),
          DemoActionButton(
            label: _showFilterRowBorder
                ? 'Filter Border: On'
                : 'Filter Border: Off',
            icon: Icons.border_bottom,
            color: context.accents.blue,
            onPressed: () => setState(() {
              _showFilterRowBorder = !_showFilterRowBorder;
              _applyLayoutChange('showFilterRowBorder = $_showFilterRowBorder');
            }),
            tooltip:
                'Toggle the border below the filter row, independently of showRowBorders',
          ),
          for (var i = 0; i < _presets.length; i++)
            DemoActionButton(
              label: _presets[i].label,
              icon: _themePresetIndex == i
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: context.accents.purple,
              onPressed: () {
                setState(() => _themePresetIndex = i);
                status.value =
                    'styleConfiguration rebuilt with the "${_presets[i].label}" preset';
              },
              tooltip: 'Apply the "${_presets[i].label}" color preset',
            ),
          DemoActionButton(
            label: _boldHeader ? 'Header: Bold' : 'Header: Regular',
            icon: Icons.format_bold,
            color: context.accents.indigo,
            onPressed: () {
              setState(() => _boldHeader = !_boldHeader);
              status.value = 'headerTextStyle fontWeight toggled';
            },
            tooltip: 'Switch the header text weight',
          ),
          DemoActionButton(
            label: _cellFontSize == 14 ? 'Cell Text: 14px' : 'Cell Text: 17px',
            icon: Icons.text_fields,
            color: context.accents.indigo,
            onPressed: () {
              setState(() => _cellFontSize = _cellFontSize == 14 ? 17 : 14);
              status.value = 'cellTextStyle fontSize = $_cellFontSize';
            },
            tooltip: 'Switch the cell text\'s font size',
          ),
          DemoActionButton(
            label: 'Border Width: ${_borderWidth.toInt()}px',
            icon: Icons.border_horizontal,
            color: context.accents.blue,
            onPressed: () {
              setState(() => _borderWidth = _borderWidth == 1 ? 3 : 1);
              status.value =
                  'gridBorderWidth/columnBorderWidth/rowBorderWidth = $_borderWidth';
            },
            tooltip: 'Switch every border\'s thickness',
          ),
          DemoActionButton(
            label: _customTextFieldBorder
                ? 'Cell Editor Border: Custom'
                : 'Cell Editor Border: Default',
            icon: Icons.border_color_outlined,
            color: context.accents.pink,
            onPressed: () {
              setState(() => _customTextFieldBorder = !_customTextFieldBorder);
              status.value = _customTextFieldBorder
                  ? 'cellTextFieldBorderColor/Width now independent of rowBorderColor — double-click a cell to see it.'
                  : 'cellTextFieldBorderColor/Width back to matching the theme border color.';
            },
            tooltip: 'Give the cell editor\'s outline its own color',
          ),
        ],
      ),
      grid: GridSheet(
        columns: _columns(),
        rows: _rows(),
        configuration: const GridSheetConfiguration(
          enableCellSelection: true,
          showRowBorders: true,
          showColumnBorders: true,
          showHeaderRowBorder: true,
          showFilterRowBorder: true,
          showColumnHeaderRow: true,
          showBorderOnSelection: false,
          enableRowHover: true,
          showColumnFilters: true,
        ),
        styleConfiguration: GridSheetStyleConfiguration(
          gridBackgroundColor: colors.background,
          headerColor: colors.header,
          filterColor: colors.header.withValues(alpha: 0.6),
          rowColor: colors.background,
          evenRowColor: colors.background,
          oddRowColor: colors.background,
          hoverColorOnRow: colors.selection.withValues(alpha: 0.3),
          selectionColor: colors.selection,
          gridBorderColor: colors.border,
          gridBorderWidth: _borderWidth,
          rowBorderColor: colors.border,
          rowBorderWidth: _borderWidth,
          // Distinct from rowBorderColor so the header/filter separators
          // are visibly styled independently of the plain row borders.
          headerRowBorderColor: colors.selection,
          filterRowBorderColor: colors.text.withValues(alpha: 0.4),
          columnBorderColor: colors.border,
          columnBorderWidth: _borderWidth,
          cellTextFieldBorderColor:
              _customTextFieldBorder ? colors.selection : colors.border,
          cellTextFieldBorderWidth: _borderWidth,
          gridBorderRadius: BorderRadius.all(Radius.circular(colors.radius)),
          headerTextStyle: TextStyle(
              fontWeight: _boldHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: colors.text),
          cellTextStyle: TextStyle(fontSize: _cellFontSize, color: colors.text),
        ),
        scrollConfiguration: scrollConfig(context),
        onLoaded: (event) => gridManager = event.gridManager,
      ),
    );
  }

  List<GridSheetColumn> _columns() {
    const names = ['METRIC', 'REGION', 'VALUE', 'TARGET'];
    const titles = ['Metric', 'Region', 'Value', 'Target'];
    const types = [
      GridSheetColumnType.text(),
      GridSheetColumnType.text(),
      GridSheetColumnType.double(),
      GridSheetColumnType.double(),
    ];
    const widths = [
      160.0,
      120.0,
      100.0,
      100.0,
    ];
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

  List<GridSheetRow> _rows() {
    final raw = [
      ['Conversion Rate', 'North', 3.8, 4.0],
      ['Churn Rate', 'South', 1.9, 1.5],
      ['Avg. Order Value', 'East', 82.4, 90.0],
      ['NPS Score', 'West', 44.0, 50.0],
      ['Response Time (hr)', 'North', 2.1, 1.8],
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

  void _applyLayoutChange(String label) {
    gridManager.config.updateGrid(
      gridManager.config.grid.copyWith(
        showRowBorders: _showRowBorders,
        showColumnBorders: _showColumnBorders,
        showHeaderRowBorder: _showHeaderRowBorder,
        showFilterRowBorder: _showFilterRowBorder,
      ),
    );
    status.value = 'updateConfiguration: $label';
  }
}

class _ThemePreset {
  final String label;
  final _ThemeColors light;
  final _ThemeColors dark;

  const _ThemePreset({
    required this.label,
    required this.light,
    required this.dark,
  });
}

class _ThemeColors {
  final Color background;
  final Color header;
  final Color selection;
  final Color border;
  final Color text;
  final double radius;

  const _ThemeColors({
    required this.background,
    required this.header,
    required this.selection,
    required this.border,
    required this.text,
    required this.radius,
  });
}
