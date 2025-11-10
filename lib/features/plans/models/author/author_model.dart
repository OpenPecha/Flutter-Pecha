import 'package:flutter_pecha/features/plans/models/author/social_profile_dto.dart';

class AuthorModel {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String? imageUrl;
  final String? bio;
  final List<SocialProfileDto> socialProfiles; // Managed by admin

  AuthorModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.imageUrl,
    this.bio,
    required this.socialProfiles,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      email: json['email'] as String,
      imageUrl: json['image_url'] as String?,
      bio: json['bio'] as String?,
      socialProfiles:
          (json['social_profiles'] as List<dynamic>?)
              ?.map((e) => SocialProfileDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'image_url': imageUrl,
      'bio': bio,
      'social_profiles':
          socialProfiles.map((profile) => profile.toJson()).toList(),
    };
  }

  /// Create a copy of this author with optional field updates
  AuthorModel copyWith({
    String? id,
    String? firstname,
    String? lastname,
    String? email,
    String? imageUrl,
    String? bio,
    List<SocialProfileDto>? socialProfiles,
  }) {
    return AuthorModel(
      id: id ?? this.id,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      socialProfiles: socialProfiles ?? this.socialProfiles,
    );
  }

  /// Get the full name by combining first and last name
  String get fullName => '$firstname $lastname';

  /// Get display name with fallback
  String get displayName =>
      fullName.trim().isNotEmpty ? fullName : 'Unknown Author';

  /// Check if author has a bio
  bool get hasBio => bio != null && bio!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AuthorModel(id: $id, fullName: $fullName, email: $email)';
  }
}
