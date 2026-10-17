import 'package:flutter/material.dart';

class PracticeExample extends StatefulWidget {
  const PracticeExample({super.key});

  @override
  State<PracticeExample> createState() => _PracticeExampleState();
}

class _PracticeExampleState extends State<PracticeExample> {
  final mainBackgroundColor = Colors.black87;
  final sideBarContainerColor = Colors.black54;
  final largeContainerColor = Colors.black54;
  final mediumContainerColor = Colors.black54;
  final smallContainerColor = Colors.black54;

  final boxShadowColor = Colors.black.withValues(alpha: 0.3);

  final double spacing = 8;
  final double padding = 8;
  final double blurRadius = 8;
  final Offset offset = Offset(0, 4);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mainBackgroundColor,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          spacing: spacing,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //sidebar
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: sideBarContainerColor,
                        borderRadius: BorderRadius.circular(spacing),
                        boxShadow: [
                          BoxShadow(
                            color: boxShadowColor,
                            blurRadius: blurRadius,
                            offset: offset,
                          ),
                        ],
                      ),
                      child: _buildSidebarItems(),
                    ),
                  ),
                ],
              ),
            ),
            //content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: spacing,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: largeContainerColor,
                      borderRadius: BorderRadius.circular(spacing),
                      boxShadow: [
                        BoxShadow(
                          color: boxShadowColor,
                          blurRadius: blurRadius,
                          offset: offset,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    spacing: spacing,
                    children: [
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: smallContainerColor,
                            borderRadius: BorderRadius.circular(spacing),
                            boxShadow: [
                              BoxShadow(
                                color: boxShadowColor,
                                blurRadius: blurRadius,
                                offset: offset,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: smallContainerColor,
                            borderRadius: BorderRadius.circular(spacing),
                            boxShadow: [
                              BoxShadow(
                                color: boxShadowColor,
                                blurRadius: blurRadius,
                                offset: offset,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: smallContainerColor,
                            borderRadius: BorderRadius.circular(spacing),
                            boxShadow: [
                              BoxShadow(
                                color: boxShadowColor,
                                blurRadius: blurRadius,
                                offset: offset,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: spacing,
                    children: [
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: smallContainerColor,
                            borderRadius: BorderRadius.circular(spacing),
                            boxShadow: [
                              BoxShadow(
                                color: boxShadowColor,
                                blurRadius: blurRadius,
                                offset: offset,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: smallContainerColor,
                            borderRadius: BorderRadius.circular(spacing),
                            boxShadow: [
                              BoxShadow(
                                color: boxShadowColor,
                                blurRadius: blurRadius,
                                offset: offset,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: smallContainerColor,
                            borderRadius: BorderRadius.circular(spacing),
                            boxShadow: [
                              BoxShadow(
                                color: boxShadowColor,
                                blurRadius: blurRadius,
                                offset: offset,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the full list of sidebar items for the sidebar container
  Widget _buildSidebarItems() {
    final items = _sampleSidebarItems();
    return ListView(
      padding: EdgeInsets.symmetric(vertical: padding),
      children: items.map(_buildSidebarItem).toList(),
    );
  }
}

// Sample data model for a sidebar item
class SidebarItem {
  final IconData icon;
  final String label;
  final bool isSelected;

  const SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });
}

// Sample sidebar items (minimum 8)
List<SidebarItem> _sampleSidebarItems() {
  return const [
    SidebarItem(icon: Icons.home, label: 'Home', isSelected: true),
    SidebarItem(icon: Icons.dashboard, label: 'Dashboard'),
    SidebarItem(icon: Icons.bar_chart, label: 'Analytics'),
    SidebarItem(icon: Icons.folder, label: 'Projects'),
    SidebarItem(icon: Icons.people, label: 'Team'),
    SidebarItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
    SidebarItem(icon: Icons.calendar_today, label: 'Calendar'),
    SidebarItem(icon: Icons.settings, label: 'Settings'),
    SidebarItem(icon: Icons.help_outline, label: 'Help'),
  ];
}

// Builds a single sidebar icon/tile
Widget _buildSidebarItem(SidebarItem item) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 8 / 2, vertical: 8 / 2),
    child: Tooltip(
      message: item.label,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: item.isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.icon,
          color: item.isSelected ? Colors.white : Colors.white70,
          size: 22,
        ),
      ),
    ),
  );
}
