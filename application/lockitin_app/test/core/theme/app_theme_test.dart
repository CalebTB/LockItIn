import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';
import 'package:lockitin_app/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    group('lightTheme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.lightTheme;
      });

      test('should return ThemeData', () {
        expect(theme, isA<ThemeData>());
      });

      test('should use Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('should have color scheme', () {
        expect(theme.colorScheme, isNotNull);
      });

      test('should have AppColorsExtension', () {
        expect(theme.extension<AppColorsExtension>(), isNotNull);
      });

      test('should have AppBar theme with no elevation', () {
        expect(theme.appBarTheme.elevation, equals(0));
        expect(theme.appBarTheme.centerTitle, isFalse);
      });

      test('should have Card theme with rounded corners', () {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
      });

      test('should have Icon theme with primary color', () {
        expect(theme.iconTheme.size, equals(24));
      });

      test('should have floating snackbar behavior', () {
        expect(theme.snackBarTheme.behavior, equals(SnackBarBehavior.floating));
      });

      test('should have FAB theme with rounded shape', () {
        final shape = theme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
      });

      test('should have filled input decoration', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
      });

      test('should have button themes with rounded corners', () {
        final elevatedStyle = theme.elevatedButtonTheme.style;
        expect(elevatedStyle, isNotNull);
      });
    });

    group('darkTheme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.darkTheme;
      });

      test('should return ThemeData', () {
        expect(theme, isA<ThemeData>());
      });

      test('should use Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('should have color scheme', () {
        expect(theme.colorScheme, isNotNull);
      });

      test('should have dark AppColorsExtension', () {
        final extension = theme.extension<AppColorsExtension>();
        expect(extension, isNotNull);
      });

      test('should have AppBar theme with no elevation', () {
        expect(theme.appBarTheme.elevation, equals(0));
        expect(theme.appBarTheme.centerTitle, isFalse);
      });

      test('should have Card theme with rounded corners', () {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
      });

      test('should have floating snackbar behavior', () {
        expect(theme.snackBarTheme.behavior, equals(SnackBarBehavior.floating));
      });

      test('should have FAB theme with rounded shape', () {
        final shape = theme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
      });
    });

    group('Theme Consistency', () {
      late ThemeData lightTheme;
      late ThemeData darkTheme;

      setUp(() {
        lightTheme = AppTheme.lightTheme;
        darkTheme = AppTheme.darkTheme;
      });

      test('both themes should use Material 3', () {
        expect(lightTheme.useMaterial3, isTrue);
        expect(darkTheme.useMaterial3, isTrue);
      });

      test('both themes should have same icon size', () {
        expect(lightTheme.iconTheme.size, equals(darkTheme.iconTheme.size));
      });

      test('both themes should have same FAB shape', () {
        final lightShape =
            lightTheme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
        final darkShape =
            darkTheme.floatingActionButtonTheme.shape as RoundedRectangleBorder;
        expect(lightShape.borderRadius, equals(darkShape.borderRadius));
      });

      test('both themes should have same card shape', () {
        final lightShape = lightTheme.cardTheme.shape as RoundedRectangleBorder;
        final darkShape = darkTheme.cardTheme.shape as RoundedRectangleBorder;
        expect(lightShape.borderRadius, equals(darkShape.borderRadius));
      });

      test('both themes should have same input border radius', () {
        final lightBorder =
            lightTheme.inputDecorationTheme.border as OutlineInputBorder;
        final darkBorder =
            darkTheme.inputDecorationTheme.border as OutlineInputBorder;
        expect(lightBorder.borderRadius, equals(darkBorder.borderRadius));
      });

      test('both themes should have same snackbar border radius', () {
        final lightShape =
            lightTheme.snackBarTheme.shape as RoundedRectangleBorder;
        final darkShape =
            darkTheme.snackBarTheme.shape as RoundedRectangleBorder;
        expect(lightShape.borderRadius, equals(darkShape.borderRadius));
      });
    });

    group('Theme Applied to Widgets', () {
      testWidgets('light theme should apply to MaterialApp', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: Text('Test')),
          ),
        );

        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('dark theme should apply to MaterialApp', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: Text('Test')),
          ),
        );

        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('should render ElevatedButton with theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () {},
                child: const Text('Button'),
              ),
            ),
          ),
        );

        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should render Card with theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Card(child: Text('Card')),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should render TextField with theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: TextField(),
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('should render FloatingActionButton with theme', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });
  });
}
