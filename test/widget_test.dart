import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptopests/main.dart';

void main() {
  testWidgets('Game starts and multiple pests appear', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that we are on the idle screen
    expect(find.text('TAP TO REPEL'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    // Tap the 'START' button and trigger a frame.
    await tester.tap(find.text('START'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 500)); // Wait for transition

    // Verify that we are in the game and pests have spawned
    // Round 1 spawns 3 + (1 * 2) = 5 pests
    expect(find.byIcon(Icons.bug_report), findsNWidgets(5));
    expect(find.text('ROUND'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Tapping all pests clears the round', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Start game
    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Find all pests
    final pestFinder = find.byIcon(Icons.bug_report);
    expect(pestFinder, findsNWidgets(5));

    // Tap all of them
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.byIcon(Icons.bug_report).first, warnIfMissed: false);
      await tester.pump();
    }

    // Verify round clear screen appears
    expect(find.textContaining('ROUND 1 CLEAR!'), findsOneWidget);
    
    // Wait for next round to start
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    
    // Round 2 should have started
    expect(find.text('2'), findsOneWidget);
    // Round 2 spawns 3 + (2 * 2) = 7 pests
    expect(find.byIcon(Icons.bug_report), findsNWidgets(7));
  });

  testWidgets('Game over when timer runs out', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Start game
    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Wait for timer to run out (Round 1 has ~7 seconds)
    // We can fast forward time
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    // Verify Game Over screen
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
  });
}
