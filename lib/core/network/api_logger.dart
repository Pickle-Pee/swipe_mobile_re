import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef ApiLogSink = void Function(String message);

class SafeApiLogInterceptor extends Interceptor {
  SafeApiLogInterceptor(this._sink);

  static const logsBodies = false;
  static const _startedAtKey = 'safe_log_started_at';

  final ApiLogSink _sink;

  static ApiLogSink get defaultSink => kReleaseMode ? _discard : debugPrint;

  static void _discard(String _) {}

  static String _path(RequestOptions options) => options.uri.path;

  static String? _requestId(Headers? headers) {
    final values = headers?.map['x-request-id'];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  static String? _errorCode(Object? data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error is Map && error['code'] is String) {
      return error['code'] as String;
    }
    return data['code'] is String ? data['code'] as String : null;
  }

  static int? _durationMs(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    return startedAt is Stopwatch ? startedAt.elapsedMilliseconds : null;
  }

  void _write({
    required String direction,
    required RequestOptions request,
    required Object status,
    Headers? headers,
    Object? responseData,
  }) {
    final fields = <String>[
      direction,
      status.toString(),
      request.method,
      _path(request),
      if (_durationMs(request) case final duration?) '${duration}ms',
      if (_errorCode(responseData) case final code?) 'code=$code',
      if (_requestId(headers) case final requestId?) 'request_id=$requestId',
    ];
    _sink(fields.join(' '));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = Stopwatch()..start();
    _sink('--> ${options.method} ${_path(options)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _write(
      direction: '<--',
      request: response.requestOptions,
      status: response.statusCode ?? '-',
      headers: response.headers,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _write(
      direction: '<--',
      request: err.requestOptions,
      status: err.response?.statusCode ?? 'network',
      headers: err.response?.headers,
      responseData: err.response?.data,
    );
    handler.next(err);
  }
}
