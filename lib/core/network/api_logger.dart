import 'package:dio/dio.dart';

typedef ApiLogSink = void Function(String message);

class SafeApiLogInterceptor extends Interceptor {
  SafeApiLogInterceptor(this._sink);

  final ApiLogSink _sink;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _sink('--> ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _sink(
      '<-- ${response.statusCode ?? '-'} ${response.requestOptions.method} '
      '${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    _sink(
      '<-- ${error.response?.statusCode ?? 'network'} '
      '${error.requestOptions.method} ${error.requestOptions.path}',
    );
    handler.next(error);
  }
}
