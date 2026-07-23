/// Domain entity for a user profile (own or other).
class Profile {
  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender,
    this.interestedIn = const [],
    this.bio,
    this.tier = 'basic',
    this.isAdmin = false,
    this.isVerified = false,
    this.isSnoozed = false,
    this.isBanned = false,
    this.verificationStatus = 'none',
    this.lastSeen,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final List<String> interestedIn;
  final String? bio;
  final String tier;
  final bool isAdmin;
  final bool isVerified;
  final bool isSnoozed;
  final bool isBanned;
  final String verificationStatus;
  final DateTime? lastSeen;

  String get fullName => '$firstName $lastName';

  int get age {
    final now = DateTime.now();
    var a = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      a--;
    }
    return a;
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
        gender: json['gender'] as String?,
        interestedIn: (json['interested_in'] as List?)?.cast<String>() ?? const [],
        bio: json['bio'] as String?,
        tier: json['tier'] as String? ?? 'basic',
        isAdmin: json['is_admin'] as bool? ?? false,
        isVerified: json['is_verified'] as bool? ?? false,
        isSnoozed: json['is_snoozed'] as bool? ?? false,
        isBanned: json['is_banned'] as bool? ?? false,
        verificationStatus: json['verification_status'] as String? ?? 'none',
        lastSeen: json['last_seen'] == null
            ? null
            : DateTime.parse(json['last_seen'] as String),
      );

  Profile copyWith({
    String? firstName,
    String? lastName,
    String? gender,
    List<String>? interestedIn,
    String? bio,
    bool? isSnoozed,
    String? tier,
  }) =>
      Profile(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        dateOfBirth: dateOfBirth,
        gender: gender ?? this.gender,
        interestedIn: interestedIn ?? this.interestedIn,
        bio: bio ?? this.bio,
        tier: tier ?? this.tier,
        isAdmin: isAdmin,
        isVerified: isVerified,
        isSnoozed: isSnoozed ?? this.isSnoozed,
        isBanned: isBanned,
        verificationStatus: verificationStatus,
        lastSeen: lastSeen,
      );
}

/// A profile photo row.
class ProfilePhoto {
  const ProfilePhoto(
      {required this.id, required this.storagePath, required this.position});

  final String id;
  final String storagePath;
  final int position;

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) => ProfilePhoto(
        id: json['id'] as String,
        storagePath: json['storage_path'] as String,
        position: json['position'] as int,
      );
}

/// Data-driven tier limits from the `tier_limits` table.
class TierLimit {
  const TierLimit(
      {required this.tier, this.dailySwipeLimit, required this.maxPhotos});

  final String tier;
  final int? dailySwipeLimit; // null = unlimited
  final int maxPhotos;

  factory TierLimit.fromJson(Map<String, dynamic> json) => TierLimit(
        tier: json['tier'] as String,
        dailySwipeLimit: json['daily_swipe_limit'] as int?,
        maxPhotos: json['max_photos'] as int,
      );
}
