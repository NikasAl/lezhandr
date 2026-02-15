import 'dart:io';
import 'package:dio/dio.dart';
import '../models/artifacts.dart';
import '../services/api_client.dart';

/// Repository for image uploads
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
}

/// Repository for OCR operations
class OcrRepository {
  final ApiClient _apiClient;

  OcrRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Process problem condition image (OCR)
  Future<OcrResult> processProblemImage({
    required int problemId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    try {
      final response = await _apiClient.dio.post(
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
      return OcrResult.error(e.message ?? 'Network error');
    } catch (e) {
      return OcrResult.error(e.toString());
    }
  }

  /// Process solution image (OCR)
  Future<OcrResult> processSolutionImage({
    required int solutionId,
    PersonaId persona = PersonaId.petrovich,
  }) async {
    try {
      final response = await _apiClient.dio.post(
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
      return OcrResult.error(e.message ?? 'Network error');
    } catch (e) {
      return OcrResult.error(e.toString());
    }
  }
}
