/// Generic API Response wrapper untuk consistency across all endpoints
///
/// Digunakan untuk wrap semua response dari API service layer
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  /// Factory untuk success response
  factory ApiResponse.success({
    required T data,
    String? message,
  }) =>
      ApiResponse(
        success: true,
        data: data,
        message: message ?? 'Success',
        error: null,
      );

  /// Factory untuk error response
  factory ApiResponse.error({
    required String message,
    required int statusCode,
    String? details,
  }) =>
      ApiResponse(
        success: false,
        data: null,
        message: message,
        error: ApiError(
          message: message,
          statusCode: statusCode,
          details: details,
        ),
      );

  /// Factory untuk exception handling
  factory ApiResponse.exception({
    required Exception exception,
  }) =>
      ApiResponse(
        success: false,
        data: null,
        message: exception.toString(),
        error: ApiError(
          message: exception.toString(),
          statusCode: 500,
          details: 'An unexpected error occurred',
        ),
      );

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, data: $data, error: $error)';
}

/// Model untuk API Error details
class ApiError {
  final String message;
  final int statusCode;
  final String? details;

  ApiError({
    required this.message,
    required this.statusCode,
    this.details,
  });

  @override
  String toString() =>
      'ApiError(message: $message, statusCode: $statusCode, details: $details)';
}
