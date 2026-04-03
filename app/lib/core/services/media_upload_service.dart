import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../network/dio_client.dart';

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(ref.watch(dioClientProvider));
});

class MediaUploadService {
  final Dio _dio;

  MediaUploadService(this._dio);

  Future<String> uploadMedia(File file) async {
    final fileName = p.basename(file.path);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dio.post('/media/upload', data: formData);
    return response.data['url'] as String;
  }

  Future<void> deleteMedia(String url) async {
    await _dio.delete('/media', data: {'mediaUrl': url});
  }
}
