import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePoem(BuildContext context, Poem poem) async {
  final longUrl = DeepLinkUrlBuilder.poemLink(poemId: poem.id).toString();
  final shareUrl = await resolveShareUrl(context, longUrl);
  final shareMessage = context.l10n.share_poem_message;
  final title = poem.title.trim();
  final message =
      title.isNotEmpty
          ? '$shareMessage\n\n$title\n\n$shareUrl'
          : '$shareMessage\n\n$shareUrl';
  final sharePositionOrigin = getSharePositionOrigin(context: context);

  await SharePlus.instance.share(
    ShareParams(
      text: message,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
