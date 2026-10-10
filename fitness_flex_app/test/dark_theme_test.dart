import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_flex_app/core/themes/app_theme.dart';
import 'package:fitness_flex_app/navigation/app_router.dart';
import 'package:fitness_flex_app/presentation/pages/guest_access_page.dart';

void main() {
  test('Dark palette retains distinct readable surfaces and lime accents', () {
    expect(AppTheme.darkBackground, const Color(0xFF101820));
    expect(AppTheme.darkSurface, const Color(0xFF181F29));
    expect(AppTheme.darkText, const Color(0xFFF0F5F0));
    expect(AppTheme.darkMuted, const Color(0xFFAEBEBA));
    expect(AppTheme.secondaryColor, const Color(0xFFC7F681));
    expect(AppTheme.darkBackground, isNot(AppTheme.darkText));
  });

  test('Guest route points to complete Firebase-backed app entry', () {
    final route = AppRouter.getRoutes()[AppRouter.guest];
    expect(route, isNotNull);
    expect(route!(_FakeContext()), isA<GuestAccessPage>());
  });
}

class _FakeContext extends Fake implements BuildContext {}
