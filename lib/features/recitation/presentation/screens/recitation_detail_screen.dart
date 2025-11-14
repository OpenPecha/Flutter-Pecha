import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecitationDetailScreen extends ConsumerStatefulWidget {
  final RecitationModel recitation;

  const RecitationDetailScreen({super.key, required this.recitation});

  @override
  ConsumerState<RecitationDetailScreen> createState() =>
      _RecitationDetailScreenState();
}

class _RecitationDetailScreenState
    extends ConsumerState<RecitationDetailScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;

    // Build params based on language
    List<String>? recitations;
    List<String>? translations;
    List<String>? transliterations;
    List<String>? adaptations;

    if (languageCode == "bo") {
      recitations = ["bo"];
      adaptations = ["bo"];
      translations = ["en"];
    } else if (languageCode == "en") {
      translations = ["en"];
      recitations = ["bo"];
      transliterations = ["en"];
    } else if (languageCode == "zh") {
      translations = ["zh", "en"];
      transliterations = ["en"];
    }

    final recitationParams = RecitationContentParams(
      textId: widget.recitation.textId,
      recitations: recitations,
      translations: translations,
      transliterations: transliterations,
      adaptations: adaptations,
    );

    final contentAsync = ref.watch(recitationContentProvider(recitationParams));

    return Scaffold(
      appBar: AppBar(
        // title: Text(
        //   widget.recitation.title,
        //   style: const TextStyle(fontSize: 18),
        // ),
        actions: [
          IconButton(
            onPressed: _toggleSave,
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
          ),
          IconButton(
            onPressed: _shareRecitation,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: contentAsync.when(
        data: (content) => _buildContent(context, content),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecitationContentModel content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          // Segments
          ...content.segments.asMap().entries.map((entry) {
            final index = entry.key;
            final segment = entry.value;
            return _buildSegment(context, segment, index);
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    RecitationSegmentModel segment,
    int index,
  ) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) ...[
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
        ],
        // Order content based on language
        if (languageCode == "bo") ...[
          // Tibetan: 1. Recitation, 2. Adaptation, 3. Translation
          if (segment.recitation != null && segment.recitation!.isNotEmpty) ...[
            ...segment.recitation!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.adaptations != null &&
              segment.adaptations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.adaptations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.translations != null &&
              segment.translations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.translations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
        ] else if (languageCode == "en") ...[
          // English: 1. Translation, 2. Recitation, 3. Transliteration
          if (segment.translations != null &&
              segment.translations!.isNotEmpty) ...[
            ...segment.translations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.recitation != null && segment.recitation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.recitation!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.transliterations != null &&
              segment.transliterations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.transliterations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
        ] else if (languageCode == "zh") ...[
          // Chinese: 1. Translation (Chinese), 2. Translation (English), 3. Transliteration (English)
          if (segment.translations != null &&
              segment.translations!.isNotEmpty) ...[
            ...segment.translations!.entries.map((entry) {
              // Display all translations (Chinese first, then English)
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.transliterations != null &&
              segment.transliterations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.transliterations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
        ] else ...[
          // Default order for other languages
          if (segment.recitation != null && segment.recitation!.isNotEmpty) ...[
            ...segment.recitation!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.translations != null &&
              segment.translations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.translations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.transliterations != null &&
              segment.transliterations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.transliterations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
          if (segment.adaptations != null &&
              segment.adaptations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...segment.adaptations!.entries.map((entry) {
              return _buildTextSection(context, entry.value.content);
            }),
          ],
        ],
      ],
    );
  }

  Widget _buildTextSection(BuildContext context, String text) {
    // replace <br> with \n
    text = text.replaceAll('<br>', '\n');
    text = text.replaceAll('<br/>', '\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load recitation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleSave() async {
    final repository = ref.read(recitationsRepositoryProvider);
    final result = await repository.saveRecitation(widget.recitation.textId);
    if (mounted && result) {
      setState(() {
        _isSaved = true;
      });
    } else {
      setState(() {
        _isSaved = false;
      });
    }
  }

  void _shareRecitation() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
