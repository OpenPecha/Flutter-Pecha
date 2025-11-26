import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

class ChooseImage extends StatefulWidget {
  const ChooseImage({super.key, required this.text});
  final String text;

  @override
  State<ChooseImage> createState() => _ChooseImageState();
}

class _ChooseImageState extends State<ChooseImage> {
  static const int _imageCount = 4;
  final Set<int> _loadedImages = {};
  final Set<int> _failedImages = {};

  @override
  void initState() {
    super.initState();
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    for (int i = 1; i <= _imageCount; i++) {
      try {
        final imagePath = 'assets/images/segment-bg/$i.jpg';
        await rootBundle.load(imagePath);
        if (mounted) {
          setState(() {
            _loadedImages.add(i);
          });
        }
      } catch (e) {
        debugPrint('Failed to load image $i: $e');
        if (mounted) {
          setState(() {
            _failedImages.add(i);
          });
        }
      }
    }
  }

  void _showImageConfirmation(BuildContext context, String imagePath, int index) {
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      isDismissible: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 80),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Image preview
              Hero(
                tag: 'image_preview_$index',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    imagePath,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 260,
                        height: 260,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: () {
                          context.pop();
                          context.push(
                            '/texts/segment_image/create_image',
                            extra: {'text': widget.text, 'imagePath': imagePath},
                          );
                        },
                        child: Text(
                          localizations.choose_image,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => context.pop(),
                        child: Text(
                          localizations.cancel,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final availableImages = _imageCount - _failedImages.length;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        title: Text(
          localizations.choose_image,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        centerTitle: false,
      ),
      body: _loadedImages.isEmpty && _failedImages.length < _imageCount
          ? const Center(child: CircularProgressIndicator())
          : availableImages == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.no_images_available,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.choose_bg_image,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _imageCount,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final imageIndex = index + 1;
                          final imagePath = 'assets/images/segment-bg/$imageIndex.jpg';
                          final isLoading = !_loadedImages.contains(imageIndex) &&
                              !_failedImages.contains(imageIndex);
                          final hasFailed = _failedImages.contains(imageIndex);

                          return Hero(
                            tag: 'image_preview_$imageIndex',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: hasFailed
                                    ? null
                                    : () => _showImageConfirmation(
                                          context,
                                          imagePath,
                                          imageIndex,
                                        ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : hasFailed
                                          ? Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 32,
                                                color: Colors.grey[400],
                                              ),
                                            )
                                          : Image.asset(
                                              imagePath,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.broken_image,
                                                  size: 32,
                                                  color: Colors.grey[400],
                                                );
                                              },
                                            ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
