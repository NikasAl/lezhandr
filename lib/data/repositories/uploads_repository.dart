import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/artifacts.dart';
import '../services/api_client.dart';

/// Repository for image uploads and fetching
class UploadsRepository {
  final ApiClient _apiClient;

  UploadsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Upload image for an entity
  /// category: condition, solution, epiphany, question, hint
  Future<UploadResult> uploadImage({
    required String category,
    required int entityId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return UploadResult.error('File not found: $filePath');
      }

      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.dio.post(
        '/uploads/$category/$entityId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return UploadResult.success(response.data['path'] as String?);
      }

      return UploadResult.error('Upload failed: ${response.statusCode}');
    } on DioException catch (e) {
      return UploadResult.error(e.message ?? 'Network error');
    } catch (e) {
      return UploadResult.error(e.toString());
    }
  }

  /// Fetch image bytes with authorization
  /// Returns (bytes, contentType) or (null, null) on error
  Future<(Uint8List?, String?)> fetchImageBytes({
    required String category,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/images/$category/$entityId',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers.value('content-type') ?? 'image/webp';
        return (response.data as Uint8List, contentType);
      }
      return (null, null);
    } on DioException catch (e) {
      print('❌ Error fetching image: ${e.message}');
      return (null, null);
    } catch (e) {
      print('❌ Error fetching image: $e');
      return (null, null);
    }
  }
}

/// Repository for OCR operations (uses long polling for AI requests)
class OcrRepository {
  final ApiClient _apiClient;

  OcrRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Process problem condition image (OCR)
  /// Uses extended timeout for AI processing
  Future<OcrResult> processProblemImage({
    required int problemId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    try {
      // Use longPollDio for extended timeout (5 minutes)
      final response = await _apiClient.longPollDio.post(
        '/content/process-image/problem/$problemId',
        queryParameters: {'persona': persona.name},
      );

      if (response.statusCode == 200) {
        return OcrResult.fromJson(response.data);
      }

      return OcrResult.error('OCR failed: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        return OcrResult.error('Недостаточно средств');
      }
      // Don't report timeout as error - let caller handle it
      if (e.type == DioExceptionType.receiveTimeout) {
        return OcrResult.error('Превышено время ожидания. Попробуйте позже.');
      }
      return OcrResult.error(e.message ?? 'Network error');
    } catch (e) {
      return OcrResult.error(e.toString());
    }
  }

  /// Process solution image (OCR)
  /// Uses extended timeout for AI processing
  Future<OcrResult> processSolutionImage({
    required int solutionId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    try {
      // Use longPollDio for extended timeout (5 minutes)
      final response = await _apiClient.longPollDio.post(
        '/content/process-image/solution/$solutionId',
        queryParameters: {'persona': persona.name},
      );

      if (response.statusCode == 200) {
        return OcrResult.fromJson(response.data);
      }

      return OcrResult.error('OCR failed: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        return OcrResult.error('Недостаточно средств');
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        return OcrResult.error('Превышено время ожидания. Попробуйте позже.');
      }
      return OcrResult.error(e.message ?? 'Network error');
    } catch (e) {
      return OcrResult.error(e.toString());
    }
  }
}
