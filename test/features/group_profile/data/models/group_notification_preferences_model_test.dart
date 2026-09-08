import 'package:flutter_pecha/features/group_profile/data/models/group_notification_preferences_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupNotificationPreferencesModel', () {
    test('parses both flags', () {
      final model = GroupNotificationPreferencesModel.fromJson({
        'chat': false,
        'content': true,
      });
      expect(
        model.toEntity(),
        const GroupNotificationPreferences(chat: false, content: true),
      );
    });

    test('a missing flag reads as the backend default, on', () {
      expect(
        GroupNotificationPreferencesModel.fromJson(const {}).toEntity(),
        GroupNotificationPreferences.allOn,
      );
      expect(
        GroupNotificationPreferencesModel.fromJson({'chat': false}).toEntity(),
        const GroupNotificationPreferences(chat: false, content: true),
      );
    });

    test('request body carries only the flags that were passed', () {
      expect(GroupNotificationPreferencesModel.toRequestJson(chat: false), {
        'chat': false,
      });
      expect(GroupNotificationPreferencesModel.toRequestJson(content: true), {
        'content': true,
      });
      expect(
        GroupNotificationPreferencesModel.toRequestJson(
          chat: true,
          content: false,
        ),
        {'chat': true, 'content': false},
      );
    });
  });

  group('GroupProfileModel.my_notification_preferences', () {
    test('is carried onto the entity when present', () {
      final profile =
          GroupProfileModel.fromJson({
            'id': 'grp-1',
            'my_notification_preferences': {'chat': true, 'content': false},
          }).toEntity();
      expect(
        profile.myNotificationPreferences,
        const GroupNotificationPreferences(chat: true, content: false),
      );
    });

    test('is null when the backend omits it or sends null', () {
      expect(
        GroupProfileModel.fromJson({
          'id': 'grp-1',
        }).toEntity().myNotificationPreferences,
        isNull,
      );
      expect(
        GroupProfileModel.fromJson({
          'id': 'grp-1',
          'my_notification_preferences': null,
        }).toEntity().myNotificationPreferences,
        isNull,
      );
    });
  });
}
