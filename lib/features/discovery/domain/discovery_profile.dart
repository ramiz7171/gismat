/// A profile row returned by the `nearby_profiles` RPC. Distance is already
/// bucketed server-side (100 m) — exact coordinates never reach the client.
class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    this.bio,
    this.gender,
    required this.isVerified,
    this.lastSeen,
    required this.distanceM,
    required this.photoPaths,
  });

  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String? bio;
  final String? gender;
  final bool isVerified;
  final DateTime? lastSeen;
  final double distanceM;
  final List<String> photoPaths;

  String get fullName => '$firstName $lastName';

  bool get isOnline =>
      lastSeen != null &&
      DateTime.now().toUtc().difference(lastSeen!.toUtc()).inMinutes < 2;

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) =>
      DiscoveryProfile(
        id: json['id'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        age: json['age'] as int,
        bio: json['bio'] as String?,
        gender: json['gender'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        lastSeen: json['last_seen'] == null
            ? null
            : DateTime.parse(json['last_seen'] as String),
        distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
        photoPaths: (json['photo_paths'] as List?)?.cast<String>() ?? const [],
      );
}

/// Result of the `record_swipe` RPC.
class SwipeResult {
  const SwipeResult({required this.remaining, required this.tier});

  /// -1 = unlimited.
  final int remaining;
  final String tier;

  factory SwipeResult.fromJson(Map<String, dynamic> json) => SwipeResult(
        remaining: json['remaining'] as int? ?? -1,
        tier: json['tier'] as String? ?? 'basic',
      );
}

/// Result of the `send_poke` RPC.
class PokeResult {
  const PokeResult({required this.matched, this.conversationId});

  final bool matched;
  final String? conversationId;

  factory PokeResult.fromJson(Map<String, dynamic> json) => PokeResult(
        matched: json['matched'] as bool? ?? false,
        conversationId: json['conversation_id'] as String?,
      );
}

/// A poke received by me (from the `pokes_received` RPC).
class ReceivedPoke {
  const ReceivedPoke({
    required this.pokerId,
    required this.firstName,
    required this.age,
    required this.isVerified,
    required this.pokedAt,
    this.photoPath,
    required this.pokedBack,
  });

  final String pokerId;
  final String firstName;
  final int age;
  final bool isVerified;
  final DateTime pokedAt;
  final String? photoPath;
  final bool pokedBack;

  factory ReceivedPoke.fromJson(Map<String, dynamic> json) => ReceivedPoke(
        pokerId: json['poker_id'] as String,
        firstName: json['first_name'] as String,
        age: json['age'] as int,
        isVerified: json['is_verified'] as bool? ?? false,
        pokedAt: DateTime.parse(json['poked_at'] as String),
        photoPath: json['photo_path'] as String?,
        pokedBack: json['poked_back'] as bool? ?? false,
      );
}
