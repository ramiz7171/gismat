import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<Profile?> fetchMyProfile() async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', _uid)
          .maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<Profile?> fetchProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return row == null ? null : Profile.fromJson(row);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> createProfile({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String gender,
    required List<String> interestedIn,
    String? bio,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': _uid,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
        'gender': gender,
        'interested_in': interestedIn,
        'bio': bio?.trim(),
      });
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> patch) async {
    try {
      await _client.from('profiles').update(patch).eq('id', _uid);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<List<TierLimit>> fetchTierLimits() async {
    try {
      final rows = await _client.from('tier_limits').select();
      return (rows as List)
          .map((r) => TierLimit.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  // ---- Photos ----------------------------------------------------------

  Future<List<ProfilePhoto>> fetchMyPhotos() => fetchPhotos(_uid);

  Future<List<ProfilePhoto>> fetchPhotos(String userId) async {
    try {
      final rows = await _client
          .from('photos')
          .select()
          .eq('user_id', userId)
          .order('position', ascending: true);
      return (rows as List)
          .map((r) => ProfilePhoto.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  String publicPhotoUrl(String storagePath) =>
      _client.storage.from('profile-photos').getPublicUrl(storagePath);

  Future<void> addPhoto(File file, {required int position}) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext) ? ext : 'jpg';
      final path =
          '$_uid/${DateTime.now().millisecondsSinceEpoch}-$position.$safeExt';
      await _client.storage.from('profile-photos').upload(path, file,
          fileOptions: const FileOptions(cacheControl: '3600'));
      await _client
          .from('photos')
          .insert({'user_id': _uid, 'storage_path': path, 'position': position});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> deletePhoto(ProfilePhoto photo) async {
    try {
      await _client.from('photos').delete().eq('id', photo.id);
      await _client.storage.from('profile-photos').remove([photo.storagePath]);
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Persists a full reorder; positions are re-assigned from list order.
  /// The unique(user_id, position) constraint is deferrable, so updating
  /// row-by-row inside one call is safe.
  Future<void> reorderPhotos(List<ProfilePhoto> ordered) async {
    try {
      // Two-phase update avoids transient duplicates without a transaction.
      for (var i = 0; i < ordered.length; i++) {
        await _client
            .from('photos')
            .update({'position': 1000 + i}).eq('id', ordered[i].id);
      }
      for (var i = 0; i < ordered.length; i++) {
        await _client.from('photos').update({'position': i}).eq('id', ordered[i].id);
      }
    } catch (e) {
      throw mapError(e);
    }
  }

  // ---- Verification ----------------------------------------------------

  Future<void> submitVerificationSelfie(Uint8List bytes) async {
    try {
      final path = '$_uid/verification-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('profile-photos').uploadBinary(path, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      await _client.from('profiles').update({
        'verification_status': 'pending',
        'verification_photo_path': path,
      }).eq('id', _uid);
    } catch (e) {
      throw mapError(e);
    }
  }

  // ---- Location --------------------------------------------------------

  Future<void> updateLocation({required double lat, required double lng}) async {
    try {
      await _client.rpc<void>('update_location', params: {'lat': lat, 'lng': lng});
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> touchLastSeen() async {
    try {
      await _client
          .from('profiles')
          .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', _uid);
    } catch (_) {
      // best-effort; never surface
    }
  }
}
