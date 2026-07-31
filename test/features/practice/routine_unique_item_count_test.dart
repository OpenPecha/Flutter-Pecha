import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RoutineItem series(String id) => RoutineItem(
    id: id,
    title: id,
    type: RoutineItemType.series,
  );

  RoutineItem chant(String id) => RoutineItem(
    id: id,
    title: id,
    type: RoutineItemType.recitation,
  );

  RoutineBlock block(List<RoutineItem> items, {int hour = 6, int minute = 0}) {
    return RoutineBlock(
      time: TimeOfDay(hour: hour, minute: minute),
      items: items,
    );
  }

  test('one plan across multiple time blocks counts as 1', () {
    final data = RoutineData(
      blocks: [
        block([series('bodhisattva')], hour: 6, minute: 6),
        block([series('bodhisattva')], hour: 6, minute: 16),
        block([series('bodhisattva')], hour: 11, minute: 21),
        block([series('bodhisattva')], hour: 12, minute: 7),
        block([series('bodhisattva')], hour: 18, minute: 23),
      ],
    );

    expect(data.uniqueItemCount(RoutineItemType.series), 1);
    expect(data.uniqueItemCount(RoutineItemType.recitation), 0);
  });

  test('two distinct plans count as 2', () {
    final data = RoutineData(
      blocks: [
        block([series('plan-a')], hour: 6),
        block([series('plan-b')], hour: 7),
        block([series('plan-a')], hour: 8),
      ],
    );

    expect(data.uniqueItemCount(RoutineItemType.series), 2);
  });

  test('empty routine counts as 0', () {
    const data = RoutineData();
    expect(data.uniqueItemCount(RoutineItemType.series), 0);
    expect(data.uniqueItemCount(RoutineItemType.recitation), 0);
  });

  test('chants are deduped separately from plans', () {
    final data = RoutineData(
      blocks: [
        block([series('plan-a'), chant('chant-a')], hour: 6),
        block([series('plan-a'), chant('chant-a')], hour: 7),
        block([chant('chant-b')], hour: 8),
      ],
    );

    expect(data.uniqueItemCount(RoutineItemType.series), 1);
    expect(data.uniqueItemCount(RoutineItemType.recitation), 2);
  });
}
