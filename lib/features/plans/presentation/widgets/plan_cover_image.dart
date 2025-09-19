import 'package:flutter/material.dart';

class PlanCoverImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final double? height;

  const PlanCoverImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: height ?? MediaQuery.of(context).size.height * 0.23,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              return progress?.expectedTotalBytes == null
                  ? child
                  : const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, size: 80));
            },
          ),
        ),
      ),
    );
  }
}
