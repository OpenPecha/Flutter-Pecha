import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_api_models.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_api_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionType.fromJson', () {
    test('parses PLAN as a first-class plan session', () {
      expect(SessionType.fromJson('PLAN'), SessionType.plan);
      expect(SessionType.fromJson('plan'), SessionType.plan);
    });

    test('parses SERIES independently of PLAN', () {
      expect(SessionType.fromJson('SERIES'), SessionType.series);
    });
  });

  group('routineItemFromSessionDto', () {
    test('maps a PLAN session onto RoutineItemType.plan', () {
      const inputSession = SessionDTO(
        id: 'session-1',
        sessionType: SessionType.plan,
        sourceId: 'plan-1',
        title: 'Lojong',
        language: 'en',
        displayOrder: 0,
      );

      final actualItem = routineItemFromSessionDto(inputSession);

      expect(actualItem.id, 'plan-1');
      expect(actualItem.type, RoutineItemType.plan);
      expect(actualItem.currentPlanId, 'plan-1');
    });

    test('uses sourceId when PLAN currentPlanId is empty', () {
      const inputSession = SessionDTO(
        id: 'session-1',
        sessionType: SessionType.plan,
        sourceId: 'plan-1',
        title: 'Lojong',
        language: '',
        displayOrder: 0,
        currentPlanId: '',
      );

      final actualItem = routineItemFromSessionDto(inputSession);

      expect(actualItem.language, isNull);
      expect(actualItem.currentPlanId, 'plan-1');
    });
  });

  group('routineBlockToRequest', () {
    test('writes PLAN for standalone plan items', () {
      final inputBlock = RoutineBlock(
        time: const TimeOfDay(hour: 7, minute: 30),
        items: const [
          RoutineItem(
            id: 'plan-1',
            title: 'Lojong',
            type: RoutineItemType.plan,
          ),
        ],
      );

      final actualRequest = routineBlockToRequest(inputBlock);

      expect(actualRequest.sessions, hasLength(1));
      expect(actualRequest.sessions.first.sessionType, SessionType.plan);
      expect(actualRequest.sessions.first.sourceId, 'plan-1');
      expect(actualRequest.toJson()['sessions'], [
        {
          'session_type': 'PLAN',
          'source_id': 'plan-1',
          'display_order': 0,
        },
      ]);
    });

    test('keeps series, recitation, timer, and mala payloads unchanged', () {
      final inputBlock = RoutineBlock(
        time: const TimeOfDay(hour: 8, minute: 0),
        items: const [
          RoutineItem(
            id: 'series-1',
            title: 'Ngondro',
            type: RoutineItemType.series,
          ),
          RoutineItem(
            id: 'text-1',
            title: 'Heart Sutra',
            type: RoutineItemType.recitation,
          ),
          RoutineItem(
            id: 'timer-1',
            title: '',
            type: RoutineItemType.timer,
            durationMs: 600000,
          ),
          RoutineItem(
            id: 'preset-1',
            title: 'Om Mani',
            type: RoutineItemType.accumulator,
          ),
          RoutineItem(
            id: 'collection-1',
            title: 'Daily Chants',
            type: RoutineItemType.myRecitationCollection,
            itemCount: 3,
          ),
        ],
      );

      final actualSessions = routineBlockToRequest(inputBlock).toJson()['sessions'];

      expect(actualSessions, [
        {
          'session_type': 'SERIES',
          'source_id': 'series-1',
          'display_order': 0,
        },
        {
          'session_type': 'RECITATION',
          'source_id': 'text-1',
          'display_order': 1,
        },
        {
          'session_type': 'TIMER',
          'display_order': 2,
          'duration_ms': 600000,
        },
        {
          'session_type': 'ACCUMULATOR',
          'accumulator_id': 'preset-1',
          'display_order': 3,
        },
        {
          'session_type': 'RECITATION_COLLECTION',
          'source_id': 'collection-1',
          'display_order': 4,
        },
      ]);
    });
  });

  group('routineItemFromSessionDto existing types', () {
    test('maps SERIES, RECITATION, TIMER, and ACCUMULATOR independently of PLAN', () {
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's1',
              sessionType: SessionType.series,
              sourceId: 'series-1',
              title: 'Ngondro',
              language: 'en',
              displayOrder: 0,
            ),
          ).type,
          RoutineItemType.series,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's2',
              sessionType: SessionType.recitation,
              sourceId: 'text-1',
              title: 'Heart Sutra',
              language: 'en',
              displayOrder: 1,
            ),
          ).type,
          RoutineItemType.recitation,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's3',
              sessionType: SessionType.timer,
              sourceId: 'timer-1',
              title: '',
              language: 'en',
              displayOrder: 2,
              durationMs: 600000,
            ),
          ).type,
          RoutineItemType.timer,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's4',
              sessionType: SessionType.accumulator,
              sourceId: 'preset-1',
              title: 'Om Mani',
              language: 'en',
              displayOrder: 3,
            ),
          ).type,
          RoutineItemType.accumulator,
        );
        expect(
          routineItemFromSessionDto(
            const SessionDTO(
              id: 's5',
              sessionType: SessionType.recitationCollection,
              sourceId: 'collection-1',
              title: 'Daily Chants',
              language: 'en',
              displayOrder: 4,
            ),
          ).type,
          RoutineItemType.myRecitationCollection,
        );
      },
    );

    test('parses RECITATION_COLLECTION as a personal collection session', () {
      final session = SessionDTO.fromJson({
        'id': 'session-collection',
        'session_type': 'RECITATION_COLLECTION',
        'source_id': 'collection-1',
        'title': 'Daily Chants',
        'language': 'en',
        'display_order': 0,
        'item_count': 3,
      });

      final item = routineItemFromSessionDto(session);

      expect(session.sessionType, SessionType.recitationCollection);
      expect(item.id, 'collection-1');
      expect(item.title, 'Daily Chants');
      expect(item.type, RoutineItemType.myRecitationCollection);
      expect(item.itemCount, 3);
    });
  });
}
