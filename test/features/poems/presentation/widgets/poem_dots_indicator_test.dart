import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/poems/presentation/widgets/poem_dots_indicator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not overflow when many poems are loaded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PoemDotsIndicator(
              count: 40,
              currentIndex: 20,
              activeColor: AppColors.textPrimary,
              inactiveColor: AppColors.grey300,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
