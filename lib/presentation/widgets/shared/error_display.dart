import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Types of errors that can occur
enum ErrorType {
  /// No internet connection or cannot reach server
  network,
  /// Server returned an error (4xx, 5xx)
  server,
  /// Request timeout
  timeout,
  /// Authentication error (401)
  auth,
  /// Unknown error
  unknown,
}

/// Helper to determine error type from exception
ErrorType getErrorType(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ErrorType.timeout;
      case DioExceptionType.connectionError:
        return ErrorType.network;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return ErrorType.auth;
        }
        if (statusCode != null && statusCode >= 500) {
          return ErrorType.server;
        }
        return ErrorType.server;
      default:
        return ErrorType.unknown;
    }
  }
  return ErrorType.unknown;
}

/// Get user-friendly error message
String getErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Сервер долго не отвечает.\nПопробуйте позже.';
      case DioExceptionType.connectionError:
        return 'Не удалось подключиться к серверу.\nПроверьте интернет-соединение.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        // Try to get detail message from response
        if (data is Map && data['detail'] != null) {
          final detail = data['detail'].toString();
          // Don't show raw error for auth errors
          if (statusCode == 401) {
            return 'Требуется авторизация';
          }
          return detail;
        }
        
        if (statusCode == 401) {
          return 'Требуется авторизация';
        }
        if (statusCode == 403) {
          return 'Доступ запрещён';
        }
        if (statusCode == 404) {
          return 'Данные не найдены';
        }
        if (statusCode != null && statusCode >= 500) {
          return 'Ошибка сервера.\nПопробуйте позже.';
        }
        return 'Ошибка: $statusCode';
      case DioExceptionType.cancel:
        return 'Запрос отменён';
      default:
        return 'Произошла неизвестная ошибка';
    }
  }
  
  return error.toString();
}

/// Widget to display when an error occurs
/// Shows a friendly error message with Kот Базис image for network errors
class ErrorDisplay extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? retryText;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    final errorType = getErrorType(error);
    final message = getErrorMessage(error);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image for network errors
            if (errorType == ErrorType.network || errorType == ErrorType.timeout)
              _buildNetworkErrorImage(context)
            else if (errorType == ErrorType.server)
              _buildServerErrorIcon(context)
            else if (errorType == ErrorType.auth)
              _buildAuthErrorIcon(context)
            else
              _buildUnknownErrorIcon(context),
            
            const SizedBox(height: 24),
            
            // Error message
            Text(
              _getTitle(errorType),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Нет связи';
      case ErrorType.timeout:
        return 'Время ожидания';
      case ErrorType.server:
        return 'Ошибка сервера';
      case ErrorType.auth:
        return 'Ошибка авторизации';
      case ErrorType.unknown:
        return 'Произошла ошибка';
    }
  }

  Widget _buildNetworkErrorImage(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/kot_basis_error.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image not found
            return Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            );
          },
        ),
      ),
    );
  }

  Widget _buildServerErrorIcon(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.cloud_off_rounded,
        size: 48,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildAuthErrorIcon(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock_outline_rounded,
        size: 48,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildUnknownErrorIcon(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.error_outline_rounded,
        size: 48,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Simple error widget for inline use (smaller, without image)
class InlineError extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const InlineError({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorType = getErrorType(error);
    final message = getErrorMessage(error);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            errorType == ErrorType.network 
                ? Icons.wifi_off_rounded 
                : Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Повторить',
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }
}
