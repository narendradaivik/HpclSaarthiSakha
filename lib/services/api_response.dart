/// Generic wrapper for every API response.
/// [T] is the parsed data type on success.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? statusCode;
  final String? errorCode; // machine-readable e.g. "INSUFFICIENT_VOLUME"
  final Map<String, dynamic>? errorData; // extra fields from error body

  const ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
    this.errorCode,
    this.errorData,
  });

  factory ApiResponse.ok(T data, {int? statusCode}) =>
      ApiResponse(success: true, data: data, statusCode: statusCode ?? 200);

  factory ApiResponse.error(
    String message, {
    int? statusCode,
    String? errorCode,
    Map<String, dynamic>? errorData,
  }) => ApiResponse(
    success: false,
    errorMessage: message,
    statusCode: statusCode,
    errorCode: errorCode,
    errorData: errorData,
  );

  /// True when API returned success=false but still sent parseable bill data
  /// (e.g. NOT_HPCL / DUPLICATE return data:{} so the rejection screen can
  ///  show bill details — receipt number, quantity, outlet name, image etc.)
  bool get isRejection => !success && data != null;
  bool get hasData => data != null;

  @override
  String toString() =>
      'ApiResponse(success: $success, statusCode: $statusCode, '
      'data: $data, error: $errorMessage, code: $errorCode)';
}
