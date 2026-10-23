import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Copies picked photos into the app's documents directory and backs them up
/// to Firebase Cloud Storage.
class PhotoStorage {
  PhotoStorage._();

  static const String _folder = 'memory_photos';

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ensure we have an active Firebase session. Anonymous sign-in ensures
  /// rules checking `request.auth != null` pass smoothly.
  static Future<void> _ensureAuth() async {
    if (Firebase.apps.isEmpty) return;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('PhotoStorage: Anonymous auth note: $e');
    }
  }

  /// Uploads a local file to Firebase Cloud Storage.
  /// Returns the cloud download URL (https://...) or null if upload fails.
  static Future<String?> uploadToCloud(File file) async {
    if (Firebase.apps.isEmpty) return null;
    try {
      await _ensureAuth();
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anon';

      final dot = file.path.lastIndexOf('.');
      final ext = (dot != -1 && file.path.length - dot <= 6)
          ? file.path.substring(dot).toLowerCase()
          : '.jpg';

      final fileName = '${const Uuid().v4()}$ext';
      final ref = FirebaseStorage.instance.ref().child('memories/$uid/$fileName');

      String contentType = 'image/jpeg';
      if (ext == '.png') {
        contentType = 'image/png';
      } else if (ext == '.webp') {
        contentType = 'image/webp';
      } else if (ext == '.gif') {
        contentType = 'image/gif';
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
          'original_name': file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'photo',
        },
      );

      final task = await ref.putFile(file, metadata);
      final downloadUrl = await task.ref.getDownloadURL();
      debugPrint('PhotoStorage: Successfully uploaded to Firebase Storage -> $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('PhotoStorage: Firebase Storage upload error (using local fallback): $e');
      return null;
    }
  }

  /// Persists [sourcePath].
  /// 1. Copies locally to app documents directory first (ensuring immediate availability & offline backup).
  /// 2. Attempts to upload to Firebase Cloud Storage.
  /// 3. Returns the cloud URL if successful, otherwise falls back to the local file path.
  static Future<String> persist(String sourcePath) async {
    if (sourcePath.startsWith('http')) return sourcePath;
    String localTarget = sourcePath;
    try {
      final dir = await _dir();
      final dot = sourcePath.lastIndexOf('.');
      final ext = (dot != -1 && sourcePath.length - dot <= 6) ? sourcePath.substring(dot) : '.jpg';
      localTarget = '${dir.path}/${const Uuid().v4()}$ext';
      final file = await File(sourcePath).copy(localTarget);

      // Attempt Cloud Storage upload
      final cloudUrl = await uploadToCloud(file);
      if (cloudUrl != null && cloudUrl.isNotEmpty) {
        return cloudUrl;
      }
      return localTarget;
    } catch (e) {
      debugPrint('PhotoStorage: failed to persist photo: $e');
      return localTarget;
    }
  }

  /// Re-maps a stored path to the current documents directory.
  /// (The app container path can change between iOS app updates.)
  /// If it is already an http/https URL, returns it directly.
  static Future<String> resolve(String path) async {
    if (path.startsWith('http')) return path;
    final marker = '/$_folder/';
    final index = path.indexOf(marker);
    if (index == -1) return path;
    try {
      final dir = await _dir();
      return '${dir.path}/${path.substring(index + marker.length)}';
    } catch (_) {
      return path;
    }
  }

  /// Best-effort deletion of stored photo files (both local and cloud).
  static Future<void> delete(Iterable<String> paths) async {
    for (final path in paths) {
      if (path.startsWith('http')) {
        if (Firebase.apps.isNotEmpty &&
            (path.contains('firebasestorage.googleapis.com') ||
             path.contains('firebasestorage.app'))) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(path);
            await ref.delete();
            debugPrint('PhotoStorage: Deleted cloud file $path');
          } catch (e) {
            debugPrint('PhotoStorage: failed to delete cloud photo $path: $e');
          }
        }
        continue;
      }

      if (!path.contains('/$_folder/')) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('PhotoStorage: failed to delete $path: $e');
      }
    }
  }
}
