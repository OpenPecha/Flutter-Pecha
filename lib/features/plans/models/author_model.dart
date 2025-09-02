class AuthorModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? bio;
  final String? imageUrl;
  final String? email;
  final String password; // bcrypt hash - required
  final bool isVerified; // Verified by user with email
  final bool isActive; // Managed by admin

  // Audit trail fields
  final String createdBy; // Email of admin who created - required
  final String? updatedBy; // Email of admin who last updated
  final String? deletedBy; // Email of admin who deleted
  final DateTime? deletedAt; // Soft delete timestamp

  final DateTime createdAt;
  final DateTime updatedAt;

  AuthorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.bio,
    this.imageUrl,
    this.email,
    required this.password,
    this.isVerified = false,
    this.isActive = true,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      bio: json['bio'] as String?,
      imageUrl: json['image_url'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String,
      updatedBy: json['updated_by'] as String?,
      deletedBy: json['deleted_by'] as String?,
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'bio': bio,
      'image_url': imageUrl,
      'email': email,
      'password': password,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this author with optional field updates
  AuthorModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? bio,
    String? imageUrl,
    String? email,
    String? password,
    bool? isVerified,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthorModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      email: email ?? this.email,
      password: password ?? this.password,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the full name by combining first and last name
  String get fullName => '$firstName $lastName';

  /// Get display name with fallback
  String get displayName =>
      fullName.trim().isNotEmpty ? fullName : 'Unknown Author';

  /// Check if this author is soft deleted
  bool get isDeleted => deletedAt != null;

  /// Check if this author is available (active and not deleted)
  bool get isAvailable => isActive && !isDeleted;

  /// Check if this author is verified and active
  bool get isVerifiedAndActive => isVerified && isActive && !isDeleted;

  /// Check if author has a bio
  bool get hasBio => bio != null && bio!.isNotEmpty;

  /// Check if author has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Check if author has an email
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Get initials from first and last name
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  /// Get a safe version for JSON without password
  Map<String, dynamic> toSafeJson() {
    final json = toJson();
    json.remove('password'); // Remove password from safe JSON
    return json;
  }

  /// Create an author for public display (without sensitive info)
  AuthorModel toPublicAuthor() {
    return copyWith(
      password: '***', // Mask password
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AuthorModel(id: $id, fullName: $fullName, email: $email, isVerified: $isVerified, isActive: $isActive, isDeleted: $isDeleted)';
  }
}
