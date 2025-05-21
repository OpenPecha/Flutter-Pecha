import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/models/term.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextDetailScreen extends ConsumerWidget {
  const TextDetailScreen({super.key, required this.term});
  final Term term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: Color(0xFFB6D7D7), width: 3)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            child: Text(
              term.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: const PechaBottomNavBar(),
    );
  }
}
