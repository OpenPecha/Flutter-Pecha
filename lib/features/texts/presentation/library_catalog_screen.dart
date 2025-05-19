import 'package:flutter/material.dart';

class LibraryCatalogScreen extends StatelessWidget {
  const LibraryCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Browse The Library',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Serif',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 22,
                        fontFamily: 'Serif',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const [
                  _LibrarySection(
                    title: 'Liturgy',
                    subtitle: 'Prayers and rituals',
                    dividerColor: Color(0xFF8B3A50),
                  ),
                  _LibrarySection(
                    title: 'Madhyamaka',
                    subtitle: 'Madhyamaka treatises',
                    dividerColor: Color(0xFFB6D7D7),
                  ),
                  _LibrarySection(
                    title: "The Buddha's Teachings",
                    subtitle:
                        'Kangyur and newly translated teachings of the Buddha',
                    dividerColor: Color(0xFF4C406A),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color dividerColor;

  const _LibrarySection({
    required this.title,
    required this.subtitle,
    required this.dividerColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: dividerColor, thickness: 3, height: 4),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontFamily: 'Serif',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 15,
              fontFamily: 'Serif',
            ),
          ),
        ],
      ),
    );
  }
}
