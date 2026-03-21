import 'package:dio/dio.dart';

/// Helper class to convert errors to user-friendly messages
class ErrorMessages {
  /// Convert an error to a user-friendly Russian message
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Check for network/connection errors
    if (_isNetworkError(error, errorString)) {
      return 'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';
    }
    
    // Check for timeout errors
    if (_isTimeoutError(error, errorString)) {
      return 'Превышено время ожидания. Проверьте соединение и попробуйте снова.';
    }
    
    // Check for server errors
    if (_isServerError(error, errorString)) {
      return 'Ошибка сервера. Попробуйте позже.';
    }
    
    // Check for authentication errors
    if (_isAuthError(error, errorString)) {
      return 'Неверный email или пароль.';
    }
    
    // Check for specific error messages
    if (errorString.contains('invalid credentials') || 
        errorString.contains('неправильный пароль') ||
        errorString.contains('user not found')) {
      return 'Неверный email или пароль.';
    }
    
    // If error has a meaningful message, extract it
    final message = _extractDetailMessage(error);
    if (message != null && message.isNotEmpty) {
      return message;
    }
    
    // Default message
    return 'Произошла ошибка. Попробуйте снова.';
  }
  
  /// Check if error is a network/connection error
  static bool _isNetworkError(dynamic error, String errorString) {
    // Dio connection error
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown) {
        return true;
      }
    }
    
    // Check error string for common network error patterns
    return errorString.contains('socketexception') ||
           errorString.contains('connection refused') ||
           errorString.contains('connection failed') ||
           errorString.contains('network unreachable') ||
           errorString.contains('no address associated') ||
           errorString.contains('connection error') ||
           errorString.contains('no connection') ||
           errorString.contains('нет соединения');
  }
  
  /// Check if error is a timeout error
  static bool _isTimeoutError(dynamic error, String errorString) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout;
    }
    
    return errorString.contains('timeout') ||
           errorString.contains('timed out') ||
           errorString.contains('время ожидания');
  }
  
  /// Check if error is a server error (5xx)
  static bool _isServerError(dynamic error, String errorString) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return true;
      }
    }
    
    return errorString.contains('500') ||
           errorString.contains('502') ||
           errorString.contains('503') ||
           errorString.contains('504') ||
           errorString.contains('internal server error') ||
           errorString.contains('service unavailable');
  }
  
  /// Check if error is an authentication error (401, 403)
  static bool _isAuthError(dynamic error, String errorString) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return true;
      }
    }
    
    return errorString.contains('401') ||
           errorString.contains('403') ||
           errorString.contains('unauthorized') ||
           errorString.contains('forbidden');
  }
  
  /// Extract detail message from error response
  static String? _extractDetailMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        // Try common API error fields
        final detail = data['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          // Translate common English messages
          return _translateMessage(detail);
        }
        
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return _translateMessage(message);
        }
        
        final error = data['error']?.toString();
        if (error != null && error.isNotEmpty) {
          return _translateMessage(error);
        }
      }
    }
    
    // Try to extract from ApiException
    final errorString = error.toString();
    if (errorString.contains('ApiException:')) {
      final match = RegExp(r'ApiException:\s*(.+?)\s*\(').firstMatch(errorString);
      if (match != null) {
        return _translateMessage(match.group(1) ?? '');
      }
    }
    
    return null;
  }
  
  /// Translate common English error messages to Russian
  static String _translateMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('incorrect password') ||
        lowerMessage.contains('wrong password')) {
      return 'Неверный email или пароль.';
    }
    
    if (lowerMessage.contains('user not found') ||
        lowerMessage.contains('user does not exist')) {
      return 'Пользователь не найден.';
    }
    
    if (lowerMessage.contains('email already exists') ||
        lowerMessage.contains('email already registered')) {
      return 'Этот email уже зарегистрирован.';
    }
    
    if (lowerMessage.contains('username already exists') ||
        lowerMessage.contains('username already taken')) {
      return 'Это имя пользователя уже занято.';
    }
    
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Нет подключения к интернету.';
    }
    
    if (lowerMessage.contains('timeout')) {
      return 'Превышено время ожидания.';
    }
    
    return message;
  }
}
