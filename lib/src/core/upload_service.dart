import 'dart:io' show Platform, SocketException;
import 'package:cupertino_http/cupertino_http.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

/// Service that handles photo uploads via Cloudflare R2 presigned URLs.
///
/// On iOS the PUT is sent through `CupertinoClient` (NSURLSession). The default
/// `package:http` client wraps `dart:io HttpClient`, whose TLS stack fails the
/// handshake against Cloudflare R2 with SSLV3_ALERT_HANDSHAKE_FAILURE.
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final TrembleApiClient _api = TrembleApiClient();

  /// Upload a photo to Cloudflare R2.
  ///
  /// [file] — file picked via `image_picker`
  /// [onProgress] — optional callback called with (bytesSent, totalBytes).
  ///   Because bytes are fully buffered before upload, this fires once at
  ///   100 % when the upload completes (sufficient for the spinner UX).
  /// Returns the public URL to store in `photoUrls`.
  /// Throws [TrembleApiException] on failure.
  Future<String> uploadPhoto(
    XFile file, {
    void Function(int bytes, int total)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;
    final mimeType = _mimeTypeFromPath(file.path);
    final fileName = _sanitizeFileName(file.name);

    // Validate size client-side (10 MB max)
    if (fileSize > 10 * 1024 * 1024) {
      throw TrembleApiException(
        code: 'invalid-argument',
        message: 'Photo must be under 10 MB.',
      );
    }

    // Step 1: Get presigned upload URL from Cloud Function
    final result = await _api.call('generateUploadUrl', data: {
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSizeBytes': fileSize,
    });

    final uploadUrl = result['uploadUrl'] as String;
    final publicUrl = result['publicUrl'] as String;

    // Step 2: PUT directly to R2 via the platform-appropriate client.
    final client = _platformClient();
    try {
      final response = await client.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': mimeType},
        body: bytes,
      );

      onProgress?.call(fileSize, fileSize);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TrembleApiException(
          code: 'internal',
          message: 'Upload failed (HTTP ${response.statusCode}).',
        );
      }

      return publicUrl;
    } on TrembleApiException {
      rethrow;
    } on SocketException catch (e) {
      throw TrembleApiException(
        code: 'unavailable',
        message: 'Network error uploading to R2: $e',
      );
    } catch (e) {
      throw TrembleApiException(
        code: 'unavailable',
        message: 'Upload to R2 failed: $e',
      );
    } finally {
      client.close();
    }
  }

  http.Client _platformClient() {
    if (Platform.isIOS) {
      final config = URLSessionConfiguration.defaultSessionConfiguration();
      return CupertinoClient.fromSessionConfiguration(config);
    }
    return http.Client();
  }

  /// Upload a photo from a file path (for profile editing).
  Future<String> uploadPhotoFromPath(
    String path, {
    void Function(int bytes, int total)? onProgress,
  }) async {
    final file = XFile(path);
    return uploadPhoto(file, onProgress: onProgress);
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
