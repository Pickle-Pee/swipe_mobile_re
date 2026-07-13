import 'package:dio/dio.dart';
import 'package:swipe_mobile_re/core/network/user/user_http.dart';
import 'package:swipe_mobile_re/core/storage/token_storage.dart';

class SwipeInterceptor extends InterceptorsWrapper {
  int repeatCounter = 0;
  late Dio dio;

  SwipeInterceptor(Dio dioInstance) {
    dio = dioInstance;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? access = await TokenStorage().getAccessToken();
    if (access != null && access.isNotEmpty) {
      options.headers["Authorization"] = "Bearer $access";
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && repeatCounter.isEven) {
      repeatCounter++;

      UserHttp userHttp = UserHttp();
      int resultr = await userHttp.refresh();
      if (resultr != 0) {
        return handler.next(err);
      }

      final String? token = await TokenStorage().getAccessToken();
      if (token != null && token.isNotEmpty) {
        dio.options.headers["Authorization"] = "Bearer $token";
      }

      try {
        final RequestOptions options = err.requestOptions;
        final Response response = await dio.request(
          options.path,
          data: options.data,
          queryParameters: options.queryParameters,
          options: Options(
            method: options.method,
            headers: options.headers,
            extra: options.extra,
          ),
        );
        return handler.resolve(response);
      } catch (_) {
        return handler.next(err);
      }
    }
    return super.onError(err, handler);
  }
}
