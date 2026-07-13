enum ApiExceptionType { network, validation, unauthorized, server, unknown }

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}

class NetworkApiException extends ApiException {
  const NetworkApiException({required super.message, super.details})
    : super(type: ApiExceptionType.network);
}

class ValidationApiException extends ApiException {
  const ValidationApiException({
    required super.message,
    required super.statusCode,
    super.details,
  }) : super(type: ApiExceptionType.validation);
}

class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException({
    required super.message,
    required super.statusCode,
    super.details,
  }) : super(type: ApiExceptionType.unauthorized);
}

class ServerApiException extends ApiException {
  const ServerApiException({
    required super.message,
    required super.statusCode,
    super.details,
  }) : super(type: ApiExceptionType.server);
}

class UnknownApiException extends ApiException {
  const UnknownApiException({
    required super.message,
    super.statusCode,
    super.details,
  }) : super(type: ApiExceptionType.unknown);
}
