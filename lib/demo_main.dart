import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show BrowserContextMenu;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:grid_sheet_demo/demo/demo_detail_page.dart';
import 'package:grid_sheet_demo/demo/demo_home_page.dart';
import 'package:grid_sheet_demo/demo/demo_registry.dart';
import 'package:grid_sheet_demo/legacy/glassmorphism.dart';
import 'package:grid_sheet_demo/legacy/import_csv.dart';
import 'package:grid_sheet_demo/legacy/practice.dart';
import 'package:grid_sheet_demo/legacy/sample.dart';
import 'package:grid_sheet_demo/legacy/plain.dart';
import 'package:grid_sheet_demo/legacy/dashboard.dart';
import 'package:grid_sheet_demo/design_system/design_system.dart';
import 'package:grid_sheet_demo/design_system/app_theme.dart';
import 'package:grid_sheet_demo/legacy/shimmer.dart';
import 'package:grid_sheet_demo/legacy/small_plain.dart';
import 'package:grid_sheet_demo/legacy/showcase.dart';
import 'package:grid_sheet_demo/main.dart';

void main() async {
  // Without this, an error thrown outside Flutter's own build/layout/paint
  // pipeline (a raw unawaited Future, a Timer callback, an async gap with no
  // try/catch — exactly the class of bug fixed elsewhere this session) has
  // no capture point: it only ever reaches the browser console, which this
  // team never sees. This is the single place to later wire up real
  // telemetry (Sentry, Crashlytics, ...) for all three error channels.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('GridSheetDemo: FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('GridSheetDemo: uncaught platform error: $error\n$stack');
    return true;
  };

  runZonedGuarded(() async {
    appStartStopwatch.start();
    WidgetsFlutterBinding.ensureInitialized();
    usePathUrlStrategy();
    // Replaces the raw `document.addEventListener('contextmenu', ...)` that
    // used to live in web/index.html: same effect (the browser's native
    // menu never fires, letting GridSheet's own right-click menu take over),
    // but going through Flutter's own tracked flag means the framework's
    // internal context-menu-aware code (e.g. text-selection toolbars) stays
    // coordinated with it instead of being silently overridden by a JS
    // listener Flutter has no visibility into.
    if (kIsWeb) await BrowserContextMenu.disableContextMenu();
    await loadPersistedThemeMode();
    runApp(const GridSheetDemoApp());
  }, (error, stack) {
    debugPrint('GridSheetDemo: uncaught zone error: $error\n$stack');
  });
}

class GridSheetDemoApp extends StatelessWidget {
  const GridSheetDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (_, themeMode, __) => MaterialApp(
        title: 'GridSheet Features',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: themeMode,
        initialRoute: '/',
        routes: {
          '/': (context) => const DemoHomePage(),
          '/example': (context) => const Scaffold(body: GridSheetExample()),
          '/shimmer': (context) => const Scaffold(body: GridSheetShimmer()),
          '/sample': (context) => const Scaffold(body: GridSheetSample()),
          '/plain': (context) => const Scaffold(body: PlainGridSheet()),
          '/import': (context) => const Scaffold(body: ImportCSVGridSheet()),
          '/small-plain': (context) =>
              const Scaffold(body: SmallPlainGridSheet()),
          '/glass': (context) => const Scaffold(body: GlassmorphismGridSheet()),
          '/practice': (context) => const Scaffold(body: PracticeExample()),
          '/showcase': (context) => const Scaffold(body: ShowcaseGridSheet()),
          '/dashboard': (context) =>
              const Scaffold(body: TableDashboardExample()),
        },
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

/// Resolves `/gridsheet/<id>` deep links (mobile in-app pushes, and Flutter Web
/// tabs opened directly at that URL) against [demoRegistry]. Falls back to
/// [DemoHomePage] for an unknown id so a stale/mistyped link never dead-ends
/// on a blank screen.
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final name = settings.name;
  if (name == null || !name.startsWith('$demoRoutePrefix/')) return null;

  final id = name.substring(demoRoutePrefix.length + 1);
  final item = findDemoById(id);
  return MaterialPageRoute(
    settings: settings,
    builder: (_) =>
        item != null ? DemoDetailPage(item: item) : const DemoHomePage(),
  );
}
