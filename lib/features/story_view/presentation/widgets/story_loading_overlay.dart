import 'package:flutter/material.dart';

/// Loading overlay shown when first story item is not ready
class StoryLoadingOverlay extends StatefulWidget {
  const StoryLoadingOverlay({super.key});

  @override
  State<StoryLoadingOverlay> createState() => StoryLoadingOverlayState();
}

class StoryLoadingOverlayState extends State<StoryLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fadeOut() async {
    await _fadeController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building StoryLoadingOverlay');
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 24),
              Text(
                'Loading story...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
