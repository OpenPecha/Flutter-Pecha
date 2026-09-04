import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/my_recitation_collections_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/add_chants_to_collection_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/collection_name_dialog.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:image_picker/image_picker.dart';

/// Placeholder mustard accent used for the empty cover tile in the designs.
const Color _kCoverPlaceholder = Color(0xFFC9A84C);

// Measured from the 390x844 design; page content is inset 20 each side.
const double _kCoverWidth = 134;
const double _kCoverHeight = 100;
const double _kRemoveCircleSize = 24;
const double _kRowHitSize = 40;
const double _kAddTileSize = 60;

/// Shared create / edit UI for a user recitation collection.
///
/// Use [CreateEditCollectionScreen] for a new collection and
/// [CreateEditCollectionScreen.edit] to update an existing one. Layout is the same;
/// only initial data and the submit API differ.
class CreateEditCollectionScreen extends ConsumerStatefulWidget {
  /// Create a new collection starting with [initialName].
  const CreateEditCollectionScreen({
    super.key,
    required String this.initialName,
  }) : collection = null;

  /// Edit an existing [collection] (name, cover, add chants).
  const CreateEditCollectionScreen.edit({
    super.key,
    required MyRecitationCollectionDetailModel this.collection,
  }) : initialName = null;

  final String? initialName;
  final MyRecitationCollectionDetailModel? collection;

  bool get isEditing => collection != null;

  @override
  ConsumerState<CreateEditCollectionScreen> createState() =>
      _CreateEditCollectionScreenState();
}

class _CreateEditCollectionScreenState
    extends ConsumerState<CreateEditCollectionScreen> {
  static final _logger = AppLogger('CreateEditCollectionScreen');

  late String _name;

  /// `text_id`s on the server when the screen opened. Save diffs [_chants]
  /// against this: missing ids are deleted, extra ids are added.
  late final Set<String> _originalTextIds;

  /// Collection-item ids keyed by `text_id` for chants already on the server.
  late final Map<String, String> _itemIdsByTextId;
  File? _localCoverFile;
  String? _uploadedImageKey;
  String? _coverPreviewUrl;

  /// Set after the collection row is persisted so retries do not create
  /// duplicates. Once set, name and cover are locked: the retry path only adds
  /// chants and cannot write metadata, so edits would be silently dropped.
  String? _createdCollectionId;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;
  late final List<RecitationModel> _chants;

  bool get _isEditing => widget.isEditing;

  /// True once the row exists on the server; see [_createdCollectionId].
  bool get _isMetadataLocked => _createdCollectionId != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.collection;
    if (existing != null) {
      _name = existing.name;
      _coverPreviewUrl = existing.imgUrl;
      _chants =
          existing.items
              .map(
                (item) => RecitationModel(
                  textId: item.textId,
                  title:
                      item.title?.trim().isNotEmpty == true
                          ? item.title!
                          : item.textId,
                  language: item.language,
                  displayOrder: item.displayOrder,
                ),
              )
              .toList();
      _originalTextIds = _chants.map((c) => c.textId).toSet();
      _itemIdsByTextId = {
        for (final item in existing.items)
          if (item.textId.isNotEmpty && item.id.isNotEmpty)
            item.textId: item.id,
      };
    } else {
      _name = widget.initialName ?? '';
      _chants = [];
      _originalTextIds = {};
      _itemIdsByTextId = {};
    }
  }

  Future<void> _pickImage() async {
    if (_isUploadingImage || _isSubmitting || _isMetadataLocked) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    final file = File(xFile.path);
    setState(() {
      _localCoverFile = file;
      _isUploadingImage = true;
      _uploadedImageKey = null;
      if (!_isEditing) {
        _coverPreviewUrl = null;
      }
    });

    final result = await ref
        .read(myRecitationCollectionsRepositoryProvider)
        .uploadImage(file);

    if (!mounted) return;

    result.fold(
      (failure) {
        _logger.error('Failed to upload collection image: ${failure.message}');
        setState(() {
          _isUploadingImage = false;
          _localCoverFile = null;
          _uploadedImageKey = null;
          _coverPreviewUrl = _isEditing ? widget.collection?.imgUrl : null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.something_went_wrong),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (upload) {
        setState(() {
          _isUploadingImage = false;
          _uploadedImageKey = upload.key;
          _coverPreviewUrl = upload.image?.displayUrl ?? _coverPreviewUrl;
        });
      },
    );
  }

  Future<void> _changeName() async {
    if (_isSubmitting || _isMetadataLocked) return;
    final result = await showCollectionNameDialog(
      context,
      title: 'Change title',
      actionLabel: context.l10n.save,
      initialName: _name,
    );
    if (!mounted || result == null) return;
    setState(() => _name = result);
  }

  Future<void> _addChants() async {
    if (_isSubmitting) return;
    final result = await openAddChantsToCollectionScreen(
      context,
      initiallySelected: _chants,
    );
    if (!mounted || result == null) return;
    setState(() {
      _chants
        ..clear()
        ..addAll(result);
    });
  }

  /// Staged, like every other edit: the server delete happens on Save, so
  /// closing with X discards it.
  void _removeChant(int index) {
    if (_isSubmitting) return;
    if (index < 0 || index >= _chants.length) return;
    setState(() => _chants.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _chants.removeAt(oldIndex);
      _chants.insert(newIndex, item);
    });
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting || _isUploadingImage) return;

    if (_isEditing) {
      await _submitEdit();
    } else {
      await _submitCreate();
    }
  }

  Future<void> _submitCreate() async {
    setState(() => _isSubmitting = true);

    final textIds = _chants.map((c) => c.textId).toList();
    final result = await ref
        .read(myRecitationCollectionsRepositoryProvider)
        .createCollectionWithItems(
          name: _name,
          imgUrl: _uploadedImageKey ?? '',
          textIds: textIds,
          existingCollectionId: _createdCollectionId,
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        _logger.error('Failed to create collection: ${failure.message}');
        setState(() {
          _isSubmitting = false;
          if (failure is PartialCollectionCreateFailure) {
            _createdCollectionId = failure.collectionId;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.something_went_wrong),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (collection) {
        _createdCollectionId = collection.id;
        final languageCode = ref.read(practiceRecitationsLanguageProvider);
        ref.invalidate(practiceRecitationsPaginatedProvider(languageCode));
        Navigator.of(context).pop();
      },
    );
  }

  /// Applies the edit as metadata → removals → additions. Each step is
  /// idempotent for a retry: the PUT re-sends the same values, ids already
  /// deleted are dropped from [_originalTextIds] as they go, and additions are
  /// computed against what is still known to be on the server.
  Future<void> _submitEdit() async {
    final collection = widget.collection;
    if (collection == null) return;

    setState(() => _isSubmitting = true);
    final repository = ref.read(myRecitationCollectionsRepositoryProvider);

    final imageKey = _uploadedImageKey?.trim();
    final updateFailure = _failureOf(
      await repository.updateCollection(
        collectionId: collection.id,
        name: _name.trim(),
        imgUrl: imageKey != null && imageKey.isNotEmpty ? imageKey : null,
      ),
    );
    if (!mounted) return;
    if (updateFailure != null) {
      _showSubmitFailure('Failed to update collection', updateFailure);
      return;
    }

    // Chants deselected in the picker or removed with the minus button.
    final currentTextIds = _chants.map((c) => c.textId).toSet();
    for (final textId in _originalTextIds.difference(currentTextIds)) {
      final itemId = _itemIdsByTextId[textId];
      if (itemId == null || itemId.isEmpty) continue;
      final deleteFailure = _failureOf(
        await repository.deleteCollectionItem(
          collectionId: collection.id,
          itemId: itemId,
        ),
      );
      if (!mounted) return;
      if (deleteFailure != null) {
        _showSubmitFailure('Failed to remove chant $textId', deleteFailure);
        return;
      }
      _originalTextIds.remove(textId);
      _itemIdsByTextId.remove(textId);
    }

    final newTextIds =
        _chants
            .map((c) => c.textId)
            .where((id) => !_originalTextIds.contains(id))
            .toList();
    if (newTextIds.isNotEmpty) {
      final addFailure = _failureOf(
        await repository.addItemsToCollection(
          collectionId: collection.id,
          textIds: newTextIds,
        ),
      );
      if (!mounted) return;
      if (addFailure != null) {
        _showSubmitFailure('Failed to add chants', addFailure);
        return;
      }
    }

    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    ref.invalidate(practiceRecitationsPaginatedProvider(languageCode));
    ref.invalidate(myRecitationCollectionDetailProvider(collection.id));

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  static Failure? _failureOf<T>(Either<Failure, T> result) =>
      result.fold((failure) => failure, (_) => null);

  /// Logs the detail, re-enables the form, and shows a translated message.
  void _showSubmitFailure(String logContext, Failure failure) {
    _logger.error('$logContext: ${failure.message}');
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.something_went_wrong),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _canSubmit {
    if (_isUploadingImage || _isSubmitting) return false;
    if (_isEditing) return _name.trim().isNotEmpty;
    return _chants.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final mutedFill = isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final canSubmit = _canSubmit;
    final actionBg =
        canSubmit
            ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
            : (isDark ? AppColors.grey900 : AppColors.grey500);
    final actionFg =
        canSubmit
            ? (isDark ? AppColors.textPrimary : AppColors.onPrimary)
            : AppColors.onPrimary;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final actionLabel = _isEditing ? context.l10n.save : 'Create';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  icon: Icon(AppAssets.x, color: titleColor),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CoverTile(
                        localFile: _localCoverFile,
                        networkUrl: _coverPreviewUrl,
                        isUploading: _isUploadingImage,
                        showPlusWhenHasImage: _isEditing,
                        onTap: _isMetadataLocked ? null : _pickImage,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            if (!_isMetadataLocked) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Material(
                                  color: mutedFill,
                                  shape: const StadiumBorder(),
                                  child: InkWell(
                                    onTap: _changeName,
                                    customBorder: const StadiumBorder(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      child: Text(
                                        'Change',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isDark
                                                  ? AppColors.textTertiaryDark
                                                  : AppColors.grey900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_chants.isNotEmpty) ...[
                    // Order is only persisted on create, via the text_ids
                    // array; the API has no reorder call for personal
                    // collections (unlike the CMS group one), so the drag
                    // handle is hidden in edit mode rather than lying.
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _chants.length,
                      onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 2,
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final chant = _chants[index];
                        return _SelectedChantRow(
                          key: ValueKey(chant.textId),
                          title: chant.title,
                          isDark: isDark,
                          onRemove: () => _removeChant(index),
                          dragIndex: index,
                          canReorder: !_isEditing,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  _AddChantsRow(isDark: isDark, onTap: _addChants),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 8, 30, 8 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: actionBg,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    onTap: canSubmit ? _onSubmit : null,
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child:
                          _isSubmitting
                              ? Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: actionFg,
                                  ),
                                ),
                              )
                              : Text(
                                actionLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: actionFg,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the shared collection editor in edit mode.
Future<bool?> openEditCollectionScreen(
  BuildContext context, {
  required MyRecitationCollectionDetailModel collection,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => CreateEditCollectionScreen.edit(collection: collection),
    ),
  );
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.localFile,
    required this.networkUrl,
    required this.isUploading,
    required this.onTap,
    this.showPlusWhenHasImage = false,
  });

  final File? localFile;
  final String? networkUrl;
  final bool isUploading;

  /// Null disables picking (uploading, or metadata locked after a partial
  /// create).
  final VoidCallback? onTap;
  final bool showPlusWhenHasImage;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        localFile != null || (networkUrl != null && networkUrl!.isNotEmpty);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _kCoverWidth,
          height: _kCoverHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (localFile != null)
                Image.file(localFile!, fit: BoxFit.cover)
              else if (networkUrl != null && networkUrl!.isNotEmpty)
                CachedNetworkImage(imageUrl: networkUrl!, fit: BoxFit.cover)
              else
                const ColoredBox(color: _kCoverPlaceholder),
              if (isUploading)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (!hasImage || showPlusWhenHasImage)
                ColoredBox(
                  color: Colors.black.withValues(
                    alpha: hasImage && showPlusWhenHasImage ? 0.2 : 0,
                  ),
                  child: const Center(
                    child: Icon(AppAssets.plus, color: Colors.white, size: 24),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChantsRow extends StatelessWidget {
  const _AddChantsRow({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.surfaceVariantDark : AppColors.grey50;
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey100;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: _kAddTileSize,
                  height: _kAddTileSize,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(AppAssets.plus, color: color, size: 24),
                ),
                const SizedBox(width: 34),
                Text(
                  'Add chants',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: _kAddTileSize + 24),
              child: Divider(height: 1, thickness: 1, color: dividerColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedChantRow extends StatelessWidget {
  const _SelectedChantRow({
    super.key,
    required this.title,
    required this.isDark,
    required this.onRemove,
    required this.dragIndex,
    this.canReorder = true,
  });

  final String title;
  final bool isDark;
  final VoidCallback onRemove;
  final int dragIndex;

  /// Hides the drag handle when the order cannot be saved.
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.surfaceVariantDark : AppColors.grey50;
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      child: Row(
        children: [
          // 24pt circle from the design, centred in a 40pt hit target.
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: _kRowHitSize,
              height: _kRowHitSize,
              child: Center(
                child: Container(
                  width: _kRemoveCircleSize,
                  height: _kRemoveCircleSize,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(AppAssets.minus, size: 14, color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canReorder)
            ReorderableDragStartListener(
              index: dragIndex,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: _kRowHitSize,
                  height: _kRowHitSize,
                  child: Icon(
                    Icons.drag_handle,
                    color:
                        isDark ? AppColors.textSubtleDark : AppColors.grey800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
