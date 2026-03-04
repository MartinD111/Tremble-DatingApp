import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

/// Service that handles photo uploads via Cloudflare R2 presigned URLs.
///
/// Flow:
///   1. Call `uploadPhoto(xFile)` — this calls the Cloud Function to get a presigned URL
///   2. The function then PUTs the file directly to R2
///   3. Returns the final public URL to store in the user's profile
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final TrembleApiClient _api = TrembleApiClient();

  /// Upload a photo to Cloudflare R2.
  ///
  /// [file] — file picked via `image_picker`
  /// Returns the public URL to store in `photoUrls`.
  /// Throws [TrembleApiException] on failure.
  Future<String> uploadPhoto(XFile file) async {
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;
    final mimeType = _mimeTypeFromPath(file.path);
    final fileName = _sanitizeFileName(file.name);

    // Validate size client-side (10MB max)
    if (fileSize > 10 * 1024 * 1024) {
      throw TrembleApiException(
        code: 'invalid-argument',
        message: 'Photo must be under 10 MB.',
      );
    }

    // Step 1: Get presigned upload URL from server
    final result = await _api.call('generateUploadUrl', data: {
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSizeBytes': fileSize,
    });

    final uploadUrl = result['uploadUrl'] as String;
    final publicUrl = result['publicUrl'] as String;

    // Step 2: PUT directly to R2 (no Firebase involved)
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': mimeType,
        'Content-Length': fileSize.toString(),
      },
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TrembleApiException(
        code: 'internal',
        message: 'Upload failed (HTTP ${response.statusCode}).',
      );
    }

    return publicUrl;
  }

  /// Upload a photo from a file path (for profile editing).
  Future<String> uploadPhotoFromPath(String path) async {
    final file = XFile(path);
    return uploadPhoto(file);
  }

  String _mimeTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String _sanitizeFileName(String name) {
    // Keep only alphanumeric, dash, underscore, dot
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}

final uploadServiceProvider = Provider<UploadService>((_) => UploadService());
