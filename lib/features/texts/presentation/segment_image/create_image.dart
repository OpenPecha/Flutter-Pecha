import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  final screenshotController = ScreenshotController();
  bool _isSaved = false;
  Uint8List? _capturedImageBytes;

  Future<void> _captureAndSetState() async {
    final imageBytes = await screenshotController.capture();
    if (imageBytes == null) return;

    setState(() {
      _isSaved = true;
      _capturedImageBytes = imageBytes;
    });
  }

  Future<void> _shareImage() async {
    if (_capturedImageBytes == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/verse_image_for_sharing.png';
    final file = File(imagePath);
    await file.writeAsBytes(_capturedImageBytes!);

    try {
      await SharePlus.instance.share(
        ShareParams(
          previewThumbnail: XFile(widget.imagePath),
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _downloadImage() async {
    if (_capturedImageBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image not captured yet.')),
        );
      }
      return;
    }
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        _capturedImageBytes!,
        name: 'verse_image_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      if (result['isSuccess']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to gallery'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save image'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error downloading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Create Image",
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
          if (!_isSaved)
            ElevatedButton(
              key: const Key('save_image_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _captureAndSetState,
              child: Text(
                "Save",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Done",
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
          Screenshot(
            controller: screenshotController,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Image
                Image.asset(
                  widget.imagePath,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.5,
                  fit: BoxFit.cover,
                ),
                // Text Overlay
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.5,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isSaved) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _downloadImage,
                        child: const Text(
                          'Download Image',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _shareImage,
                        child: const Text(
                          'Share',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
