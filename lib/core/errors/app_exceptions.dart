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
  ApiException(this.message, {this.status});
  @override
  String toString() => message;
}
