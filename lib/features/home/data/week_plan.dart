import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import localized week plans
import 'week_plan_en.dart';
import 'week_plan_bo.dart';
import 'week_plan_zh.dart';

// Default English week plan (fallback)
const Map<String, dynamic> weekPlan = weekPlanEn;

// Provider to get the appropriate week plan based on locale
final weekPlanProvider = Provider<Map<String, dynamic>>((ref) {
  final locale = ref.watch(localeProvider);
  return _getWeekPlanForLocale(locale);
});

// Function to get week plan based on locale
Map<String, dynamic> _getWeekPlanForLocale(Locale? locale) {
  if (locale == null) return weekPlanEn;

  switch (locale.languageCode) {
    case 'bo':
      return weekPlanBo;
    case 'zh':
      return weekPlanZh;
    case 'en':
    default:
      return weekPlanEn;
  }
}

// Helper function to get week plan for a specific locale
Map<String, dynamic> getWeekPlanForLocale(Locale? locale) {
  return _getWeekPlanForLocale(locale);
}
