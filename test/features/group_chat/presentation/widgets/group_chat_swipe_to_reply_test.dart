import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_swipe_to_reply.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required VoidCallback onReply}) {
  return MaterialApp(
    home: Scaffold(
      body: GroupChatSwipeToReply(
        onReply: onReply,
        // Coloured, so it hit-tests: the real row is an AnimatedContainer,
        // which is opaque to hits even when its colour is transparent.
        child: Container(height: 60, width: double.infinity, color: Colors.blue),
      ),
    ),
  );
}

void main() {
  group('GroupChatSwipeToReply', () {
    testWidgets('a row disposed without ever being swiped does not throw', (
      tester,
    ) async {
      await tester.pumpWidget(_host(onReply: () {}));
      // Scrolled out of the thread without being touched. The animation
      // controller must already exist by now: creating it during unmount does
      // an ancestor lookup on a deactivated element and throws, which is what
      // tore the message list down.
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a drag past the threshold replies once', (tester) async {
      var replies = 0;
      await tester.pumpWidget(_host(onReply: () => replies++));

      await tester.drag(find.byType(GroupChatSwipeToReply), const Offset(70, 0));
      await tester.pumpAndSettle();

      expect(replies, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short drag springs back without replying', (tester) async {
      var replies = 0;
      await tester.pumpWidget(_host(onReply: () => replies++));

      await tester.drag(find.byType(GroupChatSwipeToReply), const Offset(20, 0));
      await tester.pumpAndSettle();

      expect(replies, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing mid-spring does not throw', (tester) async {
      await tester.pumpWidget(_host(onReply: () {}));
      await tester.drag(find.byType(GroupChatSwipeToReply), const Offset(70, 0));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      expect(tester.takeException(), isNull);
    });
  });
}
