import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:intl/intl.dart';

class DayCarousel extends StatelessWidget {
  final String language;
  final List<PlanDaysModel> days;
  final DateTime startDate;
  final int selectedDay;
  final Function(int) onDaySelected;
  final Map<int, bool>? dayCompletionStatus;

  const DayCarousel({
    super.key,
    required this.language,
    required this.days,
    required this.startDate,
    required this.selectedDay,
    required this.onDaySelected,
    this.dayCompletionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 20.0 : 16.0;
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: CarouselSlider.builder(
        options: CarouselOptions(
          aspectRatio: 1,
          height: 70,
          viewportFraction: 0.24, // Show ~4 items at once (60px + margins)
          enableInfiniteScroll: false,
          scrollPhysics: const ClampingScrollPhysics(), // Smoother scroll
          autoPlayCurve: Curves.easeInOut,
          autoPlayAnimationDuration: const Duration(milliseconds: 300),
          padEnds: false, // Remove extra padding at start/end
          initialPage: 0, // Start from the beginning
        ),
        itemCount: days.length,
        itemBuilder: (context, index, realIndex) {
          final day = days[index];
          final dayDate = startDate.add(Duration(days: day.dayNumber - 1));
          //convert to 02 Jan type format
          final dayDateString = DateFormat('dd MMM').format(dayDate);
          final isSelected = selectedDay == day.dayNumber;
          final isCompleted = dayCompletionStatus?[day.dayNumber] ?? false;

          return GestureDetector(
            onTap: () => onDaySelected(day.dayNumber),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFF1E3A8A)
                          : Theme.of(context).cardColor,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isCompleted)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.dayNumber}',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          height: lineHeight,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayDateString,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: fontFamily,
                          height: lineHeight,
                          fontWeight:
                              startDate == dayDate
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
