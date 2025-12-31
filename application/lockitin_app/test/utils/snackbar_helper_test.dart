import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/utils/snackbar_helper.dart';
import 'package:lockitin_app/core/theme/app_theme.dart';

void main() {
  group('SnackBarHelper', () {
    Widget buildTestWidget({required Widget child}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: child,
        ),
      );
    }

    group('showSuccess', () {
      testWidgets('should show success message with check icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showSuccess(context, 'Success message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('Success message'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should have green background', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showSuccess(context, 'Success');
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, equals(Colors.green));
      });
    });

    group('showError', () {
      testWidgets('should show error message with error icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showError(context, 'Error message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('Error message'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('showInfo', () {
      testWidgets('should show info message with info icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showInfo(context, 'Info message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('Info message'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
      });
    });

    group('showWarning', () {
      testWidgets('should show warning message with warning icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showWarning(context, 'Warning message');
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('Warning message'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('should have orange background', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showWarning(context, 'Warning');
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, equals(Colors.orange));
      });
    });

    group('hide', () {
      testWidgets('should hide current snackbar', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      SnackBarHelper.showSuccess(context, 'Visible');
                    },
                    child: const Text('Show'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      SnackBarHelper.hide(context);
                    },
                    child: const Text('Hide'),
                  ),
                ],
              );
            },
          ),
        ));

        // Show snackbar
        await tester.tap(find.text('Show'));
        await tester.pump();
        expect(find.text('Visible'), findsOneWidget);

        // Hide snackbar
        await tester.tap(find.text('Hide'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Visible'), findsNothing);
      });
    });

    group('SnackBar Properties', () {
      testWidgets('should have floating behavior', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showSuccess(context, 'Test');
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      });

      testWidgets('should accept custom duration', (tester) async {
        const customDuration = Duration(seconds: 5);

        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarHelper.showSuccess(
                    context,
                    'Test',
                    duration: customDuration,
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ));

        await tester.tap(find.text('Show'));
        await tester.pump();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.duration, equals(customDuration));
      });

      testWidgets('should replace current snackbar with new one', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      SnackBarHelper.showSuccess(context, 'Message One');
                    },
                    child: const Text('Show First'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      SnackBarHelper.showError(context, 'Message Two');
                    },
                    child: const Text('Show Second'),
                  ),
                ],
              );
            },
          ),
        ));

        await tester.tap(find.text('Show First'));
        await tester.pump();
        expect(find.text('Message One'), findsOneWidget);

        await tester.tap(find.text('Show Second'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Message Two'), findsOneWidget);
      });
    });
  });
}
