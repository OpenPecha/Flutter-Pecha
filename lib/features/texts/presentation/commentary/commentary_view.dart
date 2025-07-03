import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommentaryView extends StatelessWidget {
  const CommentaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final numOfCommentaries = 10;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: ListView.separated(
        itemCount: numOfCommentaries + 1, // +1 for the header
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        separatorBuilder: (context, index) {
          if (index == 0) {
            return const SizedBox.shrink(); // No separator after header
          }
          return const Divider(height: 1, color: Colors.grey);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header item
            return Text(
              'All Commentary ($numOfCommentaries)',
              style: Theme.of(context).textTheme.titleLarge,
            );
          }
          // Commentary items (index - 1 because we added header)
          final commentaryIndex = index - 1;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Commentary $commentaryIndex'),
            subtitle: Text('Commentary $commentaryIndex'),
            onTap: () {
              context.pop();
            },
          );
        },
      ),
    );
  }
}
