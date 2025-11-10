import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
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
    _isSaved = widget.recitation.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    final textId = widget.recitation.textId;
    final contentAsync = ref.watch(
      textDetailsFutureProvider(
        TextDetailsParams(
          textId: textId,
          direction: 'next',
          contentId: null,
          segmentId: null,
          versionId: null,
        ),
      ),
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

  Widget _buildContent(BuildContext context, ReaderResponse content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.textDetail.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const Divider(),
          const SizedBox(height: 16),
          // Main content
          // Text(
          //   content.content,
          //   style: Theme.of(
          //     context,
          //   ).textTheme.bodyLarge?.copyWith(height: 1.8, fontSize: 16),
          // ),
          // Phonetic if available
          // if (content.phonetic != null && content.phonetic!.isNotEmpty) ...[
          //   const SizedBox(height: 24),
          //   const Divider(),
          //   const SizedBox(height: 16),
          //   Text(
          //     'Phonetic',
          //     style: Theme.of(
          //       context,
          //     ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          //   ),
          //   const SizedBox(height: 12),
          //   Text(
          //     content.phonetic!,
          //     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          //       height: 1.6,
          //       fontStyle: FontStyle.italic,
          //     ),
          //   ),
          // ],
          // Translation if available
          if (content.textDetail.categories.contains('translation') &&
              content.textDetail.categories.contains('translation')) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Translation',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Text(
            //   content.textDetail.translation!.content,
            //   style: Theme.of(
            //     context,
            //   ).textTheme.bodyMedium?.copyWith(height: 1.6),
            // ),
          ],
          const SizedBox(height: 32),
        ],
      ),
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
