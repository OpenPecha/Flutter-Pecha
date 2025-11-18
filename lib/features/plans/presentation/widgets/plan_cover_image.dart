import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';

class PlanCoverImage extends StatelessWidget {
  final String imageUrl;
  final double? height;

  const PlanCoverImage({super.key, required this.imageUrl, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: CachedNetworkImageWidget(
        imageUrl: imageUrl,
        width: double.infinity,
        height: height ?? MediaQuery.of(context).size.height * 0.23,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(12),
        errorWidget: const Center(child: Icon(Icons.broken_image, size: 80)),
      ),
    );
  }
}
