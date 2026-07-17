/// Thrown when the backend gates a chapter behind VIP or login.
class VipRequiredException implements Exception {
  final String message;
  final bool requiresVip;
  final int status;
  VipRequiredException(this.message, {this.requiresVip = false, this.status = 0});
  @override
  String toString() => message;
}

class NotLoggedInException implements Exception {
  @override
  String toString() => 'Not logged in';
}

class ApiException implements Exception {
  final String message;
  final int? status;
  /// Per-field validation errors from backend, keyed by field name.
  /// Example: {'username': 'Username phải từ 3-20 ký tự', 'email': 'Email không hợp lệ'}
  final Map<String, String> fieldErrors;

  ApiException(this.message, {this.status, Map<String, String>? fieldErrors})
      : fieldErrors = fieldErrors ?? {};

  @override
  String toString() => message;
}
