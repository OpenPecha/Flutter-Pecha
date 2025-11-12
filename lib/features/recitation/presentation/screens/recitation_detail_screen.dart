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
    _isSaved =
        ref
            .watch(savedRecitationsFutureProvider)
            .value
            ?.contains(widget.recitation) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final contentAsync = ref.watch(
      recitationContentProvider({
        'id': widget.recitation.id,
        'language': languageCode,
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recitation.title,
          style: const TextStyle(fontSize: 18),
        ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
        ],
        // Recitation (original text)
        if (segment.recitation != null && segment.recitation!.isNotEmpty) ...[
          ...segment.recitation!.entries.map((entry) {
            return _buildTextSection(context, entry.value.text);
          }),
        ],
        // Translations
        if (segment.translations != null &&
            segment.translations!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...segment.translations!.entries.map((entry) {
            return _buildTextSection(context, entry.value.text);
          }),
        ],
        // Transliterations
        if (segment.transliterations != null &&
            segment.transliterations!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...segment.transliterations!.entries.map((entry) {
            return _buildTextSection(context, entry.value.text);
          }),
        ],
        // Adaptations
        if (segment.adaptations != null && segment.adaptations!.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...segment.adaptations!.entries.map((entry) {
            return _buildTextSection(context, entry.value.text);
          }),
        ],
      ],
    );
  }

  Widget _buildTextSection(BuildContext context, String text) {
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

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    // TODO: Call repository to save/unsave
    final repository = ref.read(recitationsRepositoryProvider);
    if (_isSaved) {
      repository.saveRecitation(widget.recitation.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recitation saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      repository.unsaveRecitation(widget.recitation.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recitation removed'),
          duration: Duration(seconds: 2),
        ),
      );
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
