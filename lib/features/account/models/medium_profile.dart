/// A Medium author's public profile, as shown to a signed-in reader.
///
/// Only what Medium renders publicly is stored, so the Home card can be built
/// from a cached snapshot without another network round trip. Engagement counts
/// are optional because Medium omits them for authors with no audience.
class MediumProfile {
  const MediumProfile({
    required this.handle,
    required this.name,
    this.bio,
    this.avatarUrl,
    this.followerCount,
    this.publicationCount,
  });

  factory MediumProfile.fromJson(Map<String, dynamic> json) {
    return MediumProfile(
      handle: json['handle'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      followerCount: json['followerCount'],
      publicationCount: json['publicationCount'],
    );
  }

  /// The Medium handle, without its leading `@`.
  final String handle;

  /// The author's display name. Falls back to the handle when unnamed.
  final String name;

  /// The short author bio, when the author wrote one.
  final String? bio;

  /// Absolute URL of the profile image.
  final String? avatarUrl;

  /// Number of followers, when Medium rendered a count.
  final int? followerCount;

  /// Number of published posts, when Medium rendered a count.
  final int? publicationCount;

  /// The handle in `@mention` form.
  String get mention => '@$handle';

  /// The author's public profile page.
  String get profileUrl => 'https://medium.com/@$handle';

  /// Whether any engagement count is known, so the card can hide its stat row
  /// rather than rendering a column of dashes.
  bool get hasStats => followerCount != null || publicationCount != null;

  MediumProfile copyWith({
    String? handle,
    String? name,
    String? bio,
    String? avatarUrl,
    int? followerCount,
    int? publicationCount,
  }) {
    return MediumProfile(
      handle: handle ?? this.handle,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      publicationCount: publicationCount ?? this.publicationCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'handle': handle,
      'name': name,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'followerCount': followerCount,
      'publicationCount': publicationCount,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MediumProfile &&
        other.handle == handle &&
        other.name == name &&
        other.bio == bio &&
        other.avatarUrl == avatarUrl &&
        other.followerCount == followerCount &&
        other.publicationCount == publicationCount;
  }

  @override
  int get hashCode => Object.hash(
    handle,
    name,
    bio,
    avatarUrl,
    followerCount,
    publicationCount,
  );
}
