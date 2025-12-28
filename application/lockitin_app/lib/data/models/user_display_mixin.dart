/// Mixin providing common display properties for user-related models
///
/// Requires implementing classes to provide [fullName] and [email] getters
mixin UserDisplayMixin {
  /// The user's full name (nullable)
  String? get fullName;

  /// The user's email address
  String get email;

  /// Display name (full name or email if no name)
  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  /// Initials for avatar placeholder
  String get initials {
    if (fullName?.isNotEmpty == true) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}
