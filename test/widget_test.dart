import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptopests/main.dart';
import 'package:taptopests/features/game/presentation/widgets/pest_widget.dart';

void main() {
  testWidgets('Game starts and multiple pests appear', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TapToPestsApp());

    // Verify that we are on the idle screen
    expect(find.text('TAP PESTS'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    // Tap the 'START' button and trigger a frame.
    await tester.tap(find.text('START'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 500)); // Wait for transition

    // Verify that we are in the game and pests have spawned
    expect(find.byType(PestWidget), findsAtLeastNWidgets(1));
    expect(find.textContaining('SCORE:'), findsOneWidget);
    expect(find.textContaining('TIME:'), findsOneWidget);
  });

  testWidgets('Game over when timer runs out', (WidgetTester tester) async {
    await tester.pumpWidget(const TapToPestsApp());

    // Start game
    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Wait for timer to run out (30 seconds)
    // We can fast forward time
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();

    // Verify Game Over screen
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
  });
}
