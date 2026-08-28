import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePoem(BuildContext context, Poem poem) async {
  final shareUrl = DeepLinkUrlBuilder.poemLink(poemId: poem.id).toString();
  final title = poem.title.trim();
  final message = title.isNotEmpty ? '$title\n\n$shareUrl' : shareUrl;
  final sharePositionOrigin = getSharePositionOrigin(context: context);

  await SharePlus.instance.share(
    ShareParams(
      text: message,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
