import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class CreateImage extends StatefulWidget {
  const CreateImage({super.key, required this.imagePath, required this.text});
  final String imagePath;
  final String text;

  @override
  State<CreateImage> createState() => _CreateImageState();
}

class _CreateImageState extends State<CreateImage> {
  final _logger = AppLogger('CreateImage');
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();

  bool _isSaved = false;
  bool _isCapturing = false;
  bool _isSharingOrDownloading = false;
  Uint8List? _capturedImageBytes;

  // Customization options
  double _textSize = 20.0;
  Color _textColor = Colors.white;
  bool _hasTextShadow = true;

  // Dynamic font size limits
  static const double _minFontSize = 14.0;
  static const double _maxFontSize = 32.0;
  late double _calculatedMaxFontSize;
  late String _displayText;

  @override
  void initState() {
    super.initState();
    _calculateFontSizeAndText();
  }

  void _calculateFontSizeAndText() {
    // Estimate available space (width is screen-dependent, height is 50% of screen)
    // Approximate characters that can fit: shorter text = larger font, longer text = smaller font
    final textLength = widget.text.length;

    // Dynamic font size calculation based on text length
    // More generous sizing to allow larger fonts for reasonable text lengths
    double calculatedSize;
    if (textLength <= 30) {
      // Very short text - can use maximum 32px
      calculatedSize = 32.0;
    } else if (textLength <= 80) {
      // Short text - 28px
      calculatedSize = 28.0;
    } else if (textLength <= 150) {
      // Medium-short text - 26px
      calculatedSize = 26.0;
    } else if (textLength <= 250) {
      // Medium text - 24px
      calculatedSize = 24.0;
    } else if (textLength <= 350) {
      // Medium-long text - 22px
      calculatedSize = 22.0;
    } else if (textLength <= 450) {
      // Long text - 20px
      calculatedSize = 20.0;
    } else if (textLength <= 550) {
      // Very long text - 18px
      calculatedSize = 18.0;
    } else if (textLength <= 700) {
      // Extra long text - 16px
      calculatedSize = 16.0;
    } else {
      // Maximum length - minimum 14px
      calculatedSize = _minFontSize;
    }

    _textSize = calculatedSize;
    _calculatedMaxFontSize = calculatedSize.clamp(_minFontSize, _maxFontSize);

    // Truncate text if it's too long even at minimum font size
    // Rough estimate: at font size 14, we can fit about 900 characters
    const maxCharsAtMinSize = 900;
    if (textLength > maxCharsAtMinSize) {
      _displayText = '${widget.text.substring(0, maxCharsAtMinSize)}...';
    } else {
      _displayText = widget.text;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _captureAndSetState() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        _showErrorSnackBar('Failed to capture image. Please try again.');
        return;
      }

      if (mounted) {
        setState(() {
          _isSaved = true;
          _capturedImageBytes = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to capture image. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    if (_capturedImageBytes == null || _isSharingOrDownloading) return;

    setState(() {
      _isSharingOrDownloading = true;
    });

    File? tempFile;
    try {
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/verse_image_${DateTime.now().millisecondsSinceEpoch}.png';
      tempFile = File(imagePath);
      await tempFile.writeAsBytes(_capturedImageBytes!);

      final sharePositionOrigin = getSharePositionOrigin(
        context: context,
        globalKey: _shareButtonKey,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Unable to share. Please try again later.');
      }
    } finally {
      // Clean up temp file
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          _logger.error('Error deleting temp file', e);
        }
      }

      if (mounted) {
        setState(() {
          _isSharingOrDownloading = false;
        });
      }
    }
  }

  Future<void> _downloadImage() async {
    if (_capturedImageBytes == null || _isSharingOrDownloading) return;

    setState(() {
      _isSharingOrDownloading = true;
    });

    try {
      final result = await ImageGallerySaverPlus.saveImage(
        _capturedImageBytes!,
        name: 'verse_image_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          _showSuccessSnackBar('Image saved to gallery');
        } else {
          _showErrorSnackBar('Unable to save image. Please try again later.');
        }
      }
    } catch (e) {
      _logger.error('Error downloading image', e);
      if (mounted) {
        _showErrorSnackBar('Unable to download image. Please try again later.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingOrDownloading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green[700],
      ),
    );
  }

  void _showCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _CustomizationSheet(
            initialTextSize: _textSize,
            initialTextColor: _textColor,
            initialHasShadow: _hasTextShadow,
            minFontSize: _minFontSize,
            maxFontSize: _calculatedMaxFontSize,
            onApply: (size, color, hasShadow) {
              setState(() {
                _textSize = size;
                _textColor = color;
                _hasTextShadow = hasShadow;
              });
            },
          ),
    );
  }

  Widget _buildPreviewContent() {
    final language = Localizations.localeOf(context).languageCode;
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    return Screenshot(
      controller: _screenshotController,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Image
          Image.asset(
            widget.imagePath,
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.5,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.5,
                color: Colors.grey[300],
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey[600],
                ),
              );
            },
          ),

          // Text Overlay with fixed text scale
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: Text(
                    _displayText,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _textSize,
                      fontFamily: fontFamily,
                      height: lineHeight,
                      fontWeight: FontWeight.w600,
                      shadows:
                          _hasTextShadow
                              ? [
                                Shadow(
                                  blurRadius: 8.0,
                                  color: Colors.black.withValues(alpha: 0.6),
                                  offset: const Offset(2, 2),
                                ),
                              ]
                              : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          localizations.create_image,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 14),
        actions: [
          if (!_isSaved) ...[
            // Customize button
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              onPressed: _showCustomizationSheet,
              tooltip: 'Customize',
            ),
            // Save button
            ElevatedButton(
              key: const Key('save_image_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: _isCapturing ? null : _captureAndSetState,
              child:
                  _isCapturing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        localizations.save,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
            ),
          ] else
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                localizations.done,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          _buildPreviewContent(),

          if (_isSaved) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Download button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor:
                              Theme.of(context).textTheme.bodyMedium?.color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        onPressed:
                            _isSharingOrDownloading ? null : _downloadImage,
                        icon:
                            _isSharingOrDownloading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.download_outlined),
                        label: Text(
                          localizations.download_image,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Share button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: _shareButtonKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSharingOrDownloading ? null : _shareImage,
                        icon:
                            _isSharingOrDownloading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.share_outlined),
                        label: Text(
                          localizations.share,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                localizations.customise_message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Customization sheet widget
class _CustomizationSheet extends StatefulWidget {
  final double initialTextSize;
  final Color initialTextColor;
  final bool initialHasShadow;
  final double minFontSize;
  final double maxFontSize;
  final Function(double size, Color color, bool hasShadow) onApply;

  const _CustomizationSheet({
    required this.initialTextSize,
    required this.initialTextColor,
    required this.initialHasShadow,
    required this.minFontSize,
    required this.maxFontSize,
    required this.onApply,
  });

  @override
  State<_CustomizationSheet> createState() => _CustomizationSheetState();
}

class _CustomizationSheetState extends State<_CustomizationSheet> {
  late double _textSize;
  late Color _textColor;
  late bool _hasShadow;

  final List<Color> _colorOptions = [
    Colors.white,
    Colors.black,
    Colors.blue[700]!,
    Colors.red[700]!,
    Colors.green[700]!,
    Colors.amber[700]!,
    Colors.purple[700]!,
  ];

  @override
  void initState() {
    super.initState();
    _textSize = widget.initialTextSize;
    _textColor = widget.initialTextColor;
    _hasShadow = widget.initialHasShadow;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 100),
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

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.customise_text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Text size slider
                Text(
                  '${localizations.text_size}: ${_textSize.toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Slider(
                  value: _textSize.clamp(
                    widget.minFontSize,
                    widget.maxFontSize,
                  ),
                  min: widget.minFontSize,
                  max: widget.maxFontSize,
                  divisions: ((widget.maxFontSize - widget.minFontSize) ~/ 1)
                      .clamp(1, 20),
                  onChanged: (value) {
                    setState(() {
                      _textSize = value;
                    });
                  },
                ),
                if (widget.maxFontSize == widget.minFontSize)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Text is too long to increase font size',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Text color selector
                Text(
                  localizations.text_color,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      _colorOptions.map((color) {
                        final isSelected = _textColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _textColor = color;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[300]!,
                                width: isSelected ? 3 : 2,
                              ),
                            ),
                            child:
                                isSelected
                                    ? Icon(
                                      Icons.check,
                                      color:
                                          color == Colors.white ||
                                                  color == Colors.amber[700]
                                              ? Colors.black
                                              : Colors.white,
                                      size: 24,
                                    )
                                    : null,
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 20),

                // Shadow toggle
                SwitchListTile(
                  title: Text(localizations.text_shadow),
                  value: _hasShadow,
                  onChanged: (value) {
                    setState(() {
                      _hasShadow = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      widget.onApply(_textSize, _textColor, _hasShadow);
                      Navigator.pop(context);
                    },
                    child: Text(
                      localizations.apply,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
