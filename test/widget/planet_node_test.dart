import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_journey/core/theme/app_theme.dart';
import 'package:phonics_journey/presentation/widgets/planet/planet_node.dart';
import 'package:phonics_journey/services/curriculum_service.dart';

void main() {
  const testLevel = CurriculumLevel(
    id: 1,
    phase: 2,
    title: 's – sun',
    gpc: 's',
    phoneme: 's',
    grapheme: 's',
    exampleWord: 'sun',
    words: ['sat', 'sit'],
    trickyWords: [],
    distractorLetters: ['a', 't'],
    description: "Meet the sound 's'",
    startsUnlocked: true,
  );

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.defaultTheme,
      home: Scaffold(
        backgroundColor: AppTheme.deepSpace,
        body: Center(child: child),
      ),
    );
  }

  group('PlanetNode', () {
    testWidgets('renders without errors when unlocked', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          PlanetNode(
            level: testLevel,
            stars: 0,
            isUnlocked: true,
            isCurrent: false,
            themeColor: AppTheme.profileColors[0],
            onTap: () {},
          ),
        ),
      );
      expect(find.byType(PlanetNode), findsOneWidget);
    });

    testWidgets('shows lock icon when locked', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          PlanetNode(
            level: testLevel,
            stars: 0,
            isUnlocked: false,
            isCurrent: false,
            themeColor: AppTheme.profileColors[0],
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('shows level number when unlocked and 0 stars', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          PlanetNode(
            level: testLevel,
            stars: 0,
            isUnlocked: true,
            isCurrent: false,
            themeColor: AppTheme.profileColors[0],
            onTap: () {},
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows star emoji when 3 stars', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          PlanetNode(
            level: testLevel,
            stars: 3,
            isUnlocked: true,
            isCurrent: false,
            themeColor: AppTheme.profileColors[0],
            onTap: () {},
          ),
        ),
      );
      expect(find.text('⭐'), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          PlanetNode(
            level: testLevel,
            stars: 0,
            isUnlocked: true,
            isCurrent: false,
            themeColor: AppTheme.profileColors[0],
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, true);
    });

    testWidgets('renders grapheme label', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          PlanetNode(
            level: testLevel,
            stars: 1,
            isUnlocked: true,
            isCurrent: false,
            themeColor: AppTheme.profileColors[0],
            onTap: () {},
          ),
        ),
      );
      expect(find.text('s'), findsWidgets);
    });
  });
}
