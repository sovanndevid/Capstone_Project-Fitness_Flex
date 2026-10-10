import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_flex_app/main.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/presentation/pages/guest_access_page.dart';

void main() {
  test('Dark theme has dark backgrounds and legible foregrounds', () {
    final theme = AppTheme.darkTheme;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppTheme.darkBackground);
    expect(theme.colorScheme.surface, AppTheme.darkSurface);
    expect(theme.colorScheme.onSurface, AppTheme.darkText);
    expect(theme.navigationBarTheme.backgroundColor, AppTheme.darkSurface);
  });

  testWidgets('The Flutter application stays dark regardless of device theme',
      (tester) async {
    await tester.pumpWidget(const FitnessFlexApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  test('Guest route enters real anonymous Firebase flow, not the local preview', () {
    final guest = AppRouter.getRoutes()[AppRouter.guest];
    expect(guest, isNotNull);
    // Route source uses GuestAccessPage, not GuestExperiencePage.
    final widget = guest!(_FakeContext());
    expect(widget, isA<GuestAccessPage>());
  });
}

// Avoid constructing a real BuildContext for a route factory that ignores it.
// FakeContext only provides the BuildContext type expected by WidgetBuilder.
class _FakeContext extends Fake implements BuildContext {}
