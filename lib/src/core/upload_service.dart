import 'dart:io'
    show
        HandshakeException,
        HttpClient,
        HttpHeaders,
        SocketException,
        TlsException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  /// [onProgress] — optional callback called with (bytesSent, totalBytes)
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

    // Step 2: PUT directly to R2, streaming in chunks for progress reporting
    final httpClient = HttpClient();
    try {
      final request = await httpClient.putUrl(Uri.parse(uploadUrl));
      request.headers.set(HttpHeaders.contentTypeHeader, mimeType);

      const chunkSize = 65536; // 64 KB
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, bytes.length);
        request.add(bytes.sublist(i, end));
        onProgress?.call(end, fileSize);
      }

      final response = await request.close();
      await response.drain<void>();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TrembleApiException(
          code: 'internal',
          message: 'Upload failed (HTTP ${response.statusCode}).',
        );
      }

      return publicUrl;
    } on HandshakeException catch (e) {
      throw TrembleApiException(
        code: 'unavailable',
        message: 'TLS handshake failed uploading to R2: $e',
      );
    } on SocketException catch (e) {
      throw TrembleApiException(
        code: 'unavailable',
        message: 'Network error uploading to R2: $e',
      );
    } on TlsException catch (e) {
      throw TrembleApiException(
        code: 'unavailable',
        message: 'TLS error uploading to R2: $e',
      );
    } finally {
      httpClient.close();
    }
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
