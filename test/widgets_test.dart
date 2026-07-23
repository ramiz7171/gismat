import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gismat/core/widgets/buttons.dart';
import 'package:gismat/core/widgets/common.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('PrimaryButton', () {
    testWidgets('renders label and fires onPressed', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(_wrap(
          PrimaryButton(label: 'Continue', onPressed: () => pressed++)));
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(pressed, 1);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester
          .pumpWidget(_wrap(const PrimaryButton(label: 'Disabled')));
      final semantics = tester.getSemantics(find.text('Disabled'));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });

    testWidgets('shows spinner while loading and hides label',
        (tester) async {
      await tester.pumpWidget(_wrap(PrimaryButton(
          label: 'Save', loading: true, onPressed: () {})));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('meets 44pt minimum touch target', (tester) async {
      await tester.pumpWidget(
          _wrap(PrimaryButton(label: 'Tap', onPressed: () {})));
      final size = tester.getSize(find.byType(InkWell).first);
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('EmptyState', () {
    testWidgets('shows title, body and action', (tester) async {
      var actions = 0;
      await tester.pumpWidget(_wrap(EmptyState(
        icon: Icons.inbox,
        title: 'Nothing here',
        body: 'Come back later',
        actionLabel: 'Retry',
        onAction: () => actions++,
      )));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Come back later'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(actions, 1);
    });
  });

  group('GismatAvatar', () {
    testWidgets('falls back to placeholder icon without url',
        (tester) async {
      await tester.pumpWidget(_wrap(const GismatAvatar()));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows verified badge', (tester) async {
      await tester
          .pumpWidget(_wrap(const GismatAvatar(verified: true)));
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });
  });
}
