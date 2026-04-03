class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  factory ApiException.fromStatusCode(int? statusCode, dynamic errorData) {
    if (statusCode == null) return ApiException(message: "No internet connection");
    
    switch (statusCode) {
      case 400:
        return ApiException(statusCode: statusCode, message: _extractMessage(errorData) ?? "Invalid request");
      case 401:
        return ApiException(statusCode: statusCode, message: "Session expired. Please log in again.");
      case 403:
        return ApiException(statusCode: statusCode, message: "You don't have permission to do this");
      case 404:
        return ApiException(statusCode: statusCode, message: "Not found");
      case 429:
        return ApiException(statusCode: statusCode, message: "Too many attempts. Please wait a moment.");
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiException(statusCode: statusCode, message: "Server error. Please try again later.");
      default:
        return ApiException(statusCode: statusCode, message: _extractMessage(errorData) ?? "An unexpected error occurred");
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map && data.containsKey('error')) {
       final err = data['error'];
       if (err is String) return err;
       if (err is List && err.isNotEmpty) return err.first.toString();
    }
    if (data is Map && data.containsKey('message')) return data['message'].toString();
    return null;
  }

  @override
  String toString() => message;
}
