// Models for user recitation-collection endpoints under
// `/users/me/recitation-collections`.
//
// Separate from group-scoped collections (`GroupRecitationCollectionModel`).

/// Request body for `POST /users/me/recitation-collections`.
class CreateRecitationCollectionRequest {
  final String name;

  /// Storage key returned by [RecitationCollectionImageUploadResponse.key].
  final String imgUrl;

  const CreateRecitationCollectionRequest({
    required this.name,
    required this.imgUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'img_url': imgUrl,
  };
}

/// Nested image URLs from `POST .../upload-image`.
class RecitationCollectionUploadedImage {
  final String? thumbnail;
  final String? medium;
  final String? original;

  const RecitationCollectionUploadedImage({
    this.thumbnail,
    this.medium,
    this.original,
  });

  factory RecitationCollectionUploadedImage.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecitationCollectionUploadedImage(
      thumbnail: json['thumbnail'] as String?,
      medium: json['medium'] as String?,
      original: json['original'] as String?,
    );
  }

  /// Best URL for local preview after upload.
  String? get displayUrl => medium ?? original ?? thumbnail;
}

/// Response from `POST /users/me/recitation-collections/upload-image` (201).
class RecitationCollectionImageUploadResponse {
  final RecitationCollectionUploadedImage? image;

  /// Pass this value as `img_url` when creating/updating a collection.
  final String key;
  final String? path;
  final String? message;

  const RecitationCollectionImageUploadResponse({
    required this.key,
    this.image,
    this.path,
    this.message,
  });

  factory RecitationCollectionImageUploadResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final imageJson = json['image'];
    return RecitationCollectionImageUploadResponse(
      key: json['key'] as String? ?? '',
      image:
          imageJson is Map<String, dynamic>
              ? RecitationCollectionUploadedImage.fromJson(imageJson)
              : null,
      path: json['path'] as String?,
      message: json['message'] as String?,
    );
  }
}

/// Response from `POST /users/me/recitation-collections` (201).
class RecitationCollectionModel {
  final String id;
  final String name;
  final String? imgUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RecitationCollectionModel({
    required this.id,
    required this.name,
    this.imgUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory RecitationCollectionModel.fromJson(Map<String, dynamic> json) {
    return RecitationCollectionModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imgUrl: json['img_url'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

/// Request body for `POST /users/me/recitation-collections/{id}/items`.
class AddRecitationCollectionItemsRequest {
  final List<String> textIds;

  const AddRecitationCollectionItemsRequest({required this.textIds});

  Map<String, dynamic> toJson() => {'text_ids': textIds};
}

/// A chant row returned after adding items to a collection.
class RecitationCollectionItemModel {
  final String id;
  final String textId;
  final String? title;
  final String? language;
  final String? type;
  final int displayOrder;

  const RecitationCollectionItemModel({
    required this.id,
    required this.textId,
    this.title,
    this.language,
    this.type,
    this.displayOrder = 0,
  });

  factory RecitationCollectionItemModel.fromJson(Map<String, dynamic> json) {
    return RecitationCollectionItemModel(
      id: json['id'] as String? ?? '',
      textId: json['text_id'] as String? ?? '',
      title: json['title'] as String?,
      language: json['language'] as String?,
      type: json['type'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Response from `POST /users/me/recitation-collections/{id}/items` (201).
class AddRecitationCollectionItemsResponse {
  final String collectionId;
  final int addedCount;
  final List<RecitationCollectionItemModel> items;

  const AddRecitationCollectionItemsResponse({
    required this.collectionId,
    required this.addedCount,
    this.items = const [],
  });

  factory AddRecitationCollectionItemsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return AddRecitationCollectionItemsResponse(
      collectionId: json['collection_id'] as String? ?? '',
      addedCount: (json['added_count'] as num?)?.toInt() ?? 0,
      items:
          rawItems
              .whereType<Map<String, dynamic>>()
              .map(RecitationCollectionItemModel.fromJson)
              .toList(),
    );
  }
}
