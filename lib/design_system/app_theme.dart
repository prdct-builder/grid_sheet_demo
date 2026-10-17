import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-level theme notifier. Both [main.dart] (GridSheetApp) and
/// [toolbar_testing.dart] import this file to read/toggle the theme
/// without creating a circular dependency.
///
/// Defaults to [ThemeMode.system] — until the user explicitly toggles it
/// (see [loadPersistedThemeMode]), the app follows the OS/browser's
/// light/dark preference, matching `index.html`'s own
/// `prefers-color-scheme` loading-screen skeleton so there's no theme flip
/// the moment the real app takes over.
final ValueNotifier<ThemeMode> appThemeMode =
    ValueNotifier<ThemeMode>(ThemeMode.system);

const _themeModePrefKey = 'gs_theme_mode';

/// Restores the last-persisted theme choice (if any) into [appThemeMode],
/// then wires up automatic persistence for every future change — every
/// toggle button in the app sets [appThemeMode].value directly, so a
/// single listener here is enough to catch all of them.
///
/// Awaited once in `main()` before `runApp` so a demo opened in a brand-new
/// browser tab (see `DemoHomePage._openDemo`) boots with the same theme as
/// the tab it was opened from, instead of resetting to the default.
Future<void> loadPersistedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_themeModePrefKey);
  if (saved != null) {
    appThemeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }
  appThemeMode.addListener(() {
    prefs.setString(_themeModePrefKey, appThemeMode.value.name);
  });
}

/// Started as the very first statement in `main()` and stopped once the
/// grid's first frame has actually painted, to measure real perceived
/// startup time (not just widget construction).
final Stopwatch appStartStopwatch = Stopwatch();

/// Elapsed [appStartStopwatch] time, published once the first grid on
/// screen finishes loading — whichever route the user actually lands on.
/// Every demo route's `GridSheet.onLoaded` calls [recordGridLoadTime], and
/// [LoadTimeLabel] displays it, so "Loaded in Xms" behaves the same way
/// across every route without each page tracking its own timer.
final ValueNotifier<int?> appLoadDurationMs = ValueNotifier<int?>(null);

/// Stops [appStartStopwatch] (if still running) after the frame in which a
/// grid's `onLoaded` fired has actually painted, then publishes the result
/// via [appLoadDurationMs]. Safe to call from every route — only the first
/// call, from whichever route the user actually lands on, has any effect.
void recordGridLoadTime() {
  if (appLoadDurationMs.value != null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!appStartStopwatch.isRunning) return;
    appStartStopwatch.stop();
    final ms = appStartStopwatch.elapsedMilliseconds;
    //debugPrint('EVENT: gridFullyLoaded -> ${ms}ms');
    appLoadDurationMs.value = ms;
  });
}

class DemoViewLoadTimeScope extends InheritedNotifier<ValueNotifier<int?>> {
  const DemoViewLoadTimeScope({
    super.key,
    required ValueNotifier<int?> super.notifier,
    required super.child,
  });

  static ValueNotifier<int?>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DemoViewLoadTimeScope>()
        ?.notifier;
  }
}

/// "Loaded in Xms" label, shown once the relevant notifier — the nearest
/// [DemoViewLoadTimeScope], or [appLoadDurationMs] where none is in scope
/// — is published.
class LoadTimeLabel extends StatelessWidget {
  final TextStyle? style;

  const LoadTimeLabel({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final notifier = DemoViewLoadTimeScope.of(context) ?? appLoadDurationMs;

    return ValueListenableBuilder<int?>(
      valueListenable: notifier,
      builder: (_, ms, __) {
        if (ms == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            'Loaded in ${ms}ms',
            style: style ??
                TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        );
      },
    );
  }
}
