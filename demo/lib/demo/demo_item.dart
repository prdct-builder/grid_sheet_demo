import 'package:flutter/material.dart';

/// Builds the widget for a single demo. Named for clarity at
/// [DemoItem.builder] call sites in `demo_registry.dart`, even though the
/// shape matches [WidgetBuilder].
typedef DemoBuilder = Widget Function(BuildContext context);

/// Metadata for one entry on the [DemoHomePage] dashboard.
///
/// A [DemoItem] never owns demo logic — [builder] just points at an
/// existing, unmodified widget from `lib/features/`. Adding a new demo means
/// creating that widget and registering one [DemoItem] for it in
/// `demo_registry.dart`; nothing here needs to change.
@immutable
class DemoItem {
  /// Unique, URL-safe (kebab-case) identifier. Becomes the `/demo/<id>`
  /// route segment, so it must be stable — changing it breaks bookmarks
  /// and deep links.
  final String id;

  /// Short feature name shown as the card title and detail-page heading.
  final String title;

  /// Icon shown on the dashboard card.
  final IconData icon;

  /// Short (1–2 line) summary shown under the title on the dashboard card.
  final String? description;

  /// Full-length description shown in the detail page's header. Falls back
  /// to [description] if not given.
  final String? fullDescription;

  /// Constructs the existing `features/` widget for this demo.
  final DemoBuilder builder;

  /// Asset path to this demo's source file (e.g. `lib/features/autofill.dart`),
  /// bundled via the `lib/features/` entry in `pubspec.yaml`'s `assets:` list.
  /// Loaded at runtime by `DemoCodeView` so the "Code" tab always shows the
  /// exact, current source — never a hand-copied snippet that can go stale.
  final String sourcePath;

  const DemoItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    required this.sourcePath,
    this.description,
    this.fullDescription,
  });

  /// The text shown on the detail page's header — [fullDescription] if
  /// given, otherwise [description].
  String? get detailDescription => fullDescription ?? description;
}
