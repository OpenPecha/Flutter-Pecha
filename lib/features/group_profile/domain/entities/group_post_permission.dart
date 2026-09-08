class GroupPostPermission {
  final String groupId;
  final bool hasPermission;
  final String? role;
  final bool isSuperAdmin;
  final String? authorId;

  const GroupPostPermission({
    required this.groupId,
    this.hasPermission = false,
    this.role,
    this.isSuperAdmin = false,
    this.authorId,
  });
}
