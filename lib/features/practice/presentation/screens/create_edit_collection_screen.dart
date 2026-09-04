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
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Placeholder mustard accent used for the empty cover tile in the designs.
const Color _kCoverPlaceholder = Color(0xFFC9A84C);

/// Shared create / edit UI for a user recitation collection.
///
/// Use [CreateEditCollectionScreen] for a new collection and
/// [CreateEditCollectionScreen.edit] to update an existing one. Layout is the same;
/// only initial data and the submit API differ.
class CreateEditCollectionScreen extends ConsumerStatefulWidget {
  /// Create a new collection starting with [initialName].
  const CreateEditCollectionScreen({super.key, required String this.initialName})
    : collection = null;

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
  late final Set<String> _originalTextIds;
  /// Collection-item ids keyed by `text_id` for chants already on the server.
  late final Map<String, String> _itemIdsByTextId;
  File? _localCoverFile;
  String? _uploadedImageKey;
  String? _coverPreviewUrl;
  /// Set after the collection row is persisted so retries do not create duplicates.
  String? _createdCollectionId;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;
  bool _isRemovingChant = false;
  late final List<RecitationModel> _chants;

  bool get _isEditing => widget.isEditing;

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
          if (item.textId.isNotEmpty && item.id.isNotEmpty) item.textId: item.id,
      };
    } else {
      _name = widget.initialName ?? '';
      _chants = [];
      _originalTextIds = {};
      _itemIdsByTextId = {};
    }
  }

  Future<void> _pickImage() async {
    if (_isUploadingImage || _isSubmitting) return;

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
            content: Text(failure.message),
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
    if (_isSubmitting) return;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _ChangeCollectionNameDialog(initialName: _name),
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

  Future<void> _removeChant(int index) async {
    if (_isSubmitting || _isRemovingChant) return;
    if (index < 0 || index >= _chants.length) return;

    final chant = _chants[index];
    final itemId = _itemIdsByTextId[chant.textId];
    final collectionId = widget.collection?.id;

    if (_isEditing &&
        collectionId != null &&
        collectionId.isNotEmpty &&
        itemId != null &&
        itemId.isNotEmpty) {
      setState(() => _isRemovingChant = true);
      final result = await ref
          .read(myRecitationCollectionsRepositoryProvider)
          .deleteCollectionItem(collectionId: collectionId, itemId: itemId);

      if (!mounted) return;

      result.fold(
        (failure) {
          _logger.error('Failed to remove chant: ${failure.message}');
          setState(() => _isRemovingChant = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        (_) {
          setState(() {
            _isRemovingChant = false;
            _chants.removeWhere((c) => c.textId == chant.textId);
            _originalTextIds.remove(chant.textId);
            _itemIdsByTextId.remove(chant.textId);
          });
          ref.invalidate(myRecitationCollectionDetailProvider(collectionId));
        },
      );
      return;
    }

    setState(() {
      _chants.removeAt(index);
      _originalTextIds.remove(chant.textId);
      _itemIdsByTextId.remove(chant.textId);
    });
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
    if (_chants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one chant'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
          _isCreating = false;
          if (failure is PartialCollectionCreateFailure) {
            _createdCollectionId = failure.collectionId;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
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

  Future<void> _submitEdit() async {
    final collection = widget.collection;
    if (collection == null) return;

    final trimmedName = _name.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a collection name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final imageKey = _uploadedImageKey?.trim();
    final updateResult = await ref
        .read(myRecitationCollectionsRepositoryProvider)
        .updateCollection(
          collectionId: collection.id,
          name: trimmedName,
          imgUrl: imageKey != null && imageKey.isNotEmpty ? imageKey : null,
        );

    if (!mounted) return;

    final updateFailed = updateResult.fold((failure) {
      _logger.error('Failed to update collection: ${failure.message}');
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }, (_) => false);
    if (updateFailed || !mounted) return;

    final newTextIds =
        _chants
            .map((c) => c.textId)
            .where((id) => !_originalTextIds.contains(id))
            .toList();

    if (newTextIds.isNotEmpty) {
      final addResult = await ref
          .read(myRecitationCollectionsRepositoryProvider)
          .addItemsToCollection(
            collectionId: collection.id,
            textIds: newTextIds,
          );
      if (!mounted) return;

      final addFailed = addResult.fold((failure) {
        _logger.error(
          'Collection updated but failed to add chants: ${failure.message}',
        );
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Collection updated, but some chants could not be added: '
              '${failure.message}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return true;
      }, (_) => false);
      if (addFailed) return;
    }

    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    ref.invalidate(practiceRecitationsPaginatedProvider(languageCode));
    ref.invalidate(myRecitationCollectionDetailProvider(collection.id));

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  bool get _canSubmit {
    if (_isUploadingImage || _isSubmitting || _isRemovingChant) return false;
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
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                icon: Icon(AppAssets.x, color: titleColor),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CoverTile(
                        localFile: _localCoverFile,
                        networkUrl: _coverPreviewUrl,
                        isUploading: _isUploadingImage,
                        showPlusWhenHasImage: _isEditing,
                        onTap: _pickImage,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Material(
                              color: mutedFill,
                              shape: const StadiumBorder(),
                              child: InkWell(
                                onTap: _changeName,
                                customBorder: const StadiumBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark
                                              ? AppColors.textTertiaryDark
                                              : AppColors.grey900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (_chants.isNotEmpty) ...[
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
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
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
                                  fontSize: 16,
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

class _ChangeCollectionNameDialog extends StatefulWidget {
  const _ChangeCollectionNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_ChangeCollectionNameDialog> createState() =>
      _ChangeCollectionNameDialogState();
}

class _ChangeCollectionNameDialogState
    extends State<_ChangeCollectionNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Change name',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }
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
  final VoidCallback onTap;
  final bool showPlusWhenHasImage;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        localFile != null || (networkUrl != null && networkUrl!.isNotEmpty);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          height: 88,
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
                    child: Icon(AppAssets.plus, color: Colors.white, size: 28),
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
    final fill = isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(AppAssets.plus, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              'Add chants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
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
  });

  final String title;
  final bool isDark;
  final VoidCallback onRemove;
  final int dragIndex;

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              child: Icon(AppAssets.minus, size: 16, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ReorderableDragStartListener(
            index: dragIndex,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.drag_handle,
                color: isDark ? AppColors.textSubtleDark : AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
