import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_logger.dart';

abstract interface class ApiTokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clear();
}

class SecureApiTokenStore implements ApiTokenStore {
  SecureApiTokenStore([TokenStorage? storage])
      : _storage = storage ?? TokenStorage();

  final TokenStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.getAccessToken();

  @override
  Future<String?> readRefreshToken() => _storage.getRefreshToken();

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final accessResult = await _storage.setAccessToken(accessToken);
    final refreshResult = await _storage.setRefreshToken(refreshToken);
    if (accessResult != 0 || refreshResult != 0) {
      throw StateError('Could not persist refreshed session');
    }
  }

  @override
  Future<void> clear() async {
    if (await _storage.clearTokens() != 0) {
      throw StateError('Could not clear session');
    }
  }
}

class ApiClient {
  ApiClient({
    Dio? dio,
    ApiTokenStore? tokenStore,
    ApiLogSink? logSink,
    this.refreshPath = '/auth/refresh_token',
    Duration connectTimeout = const Duration(seconds: 5),
    Duration sendTimeout = const Duration(seconds: 5),
    Duration receiveTimeout = const Duration(seconds: 10),
  })  : _tokenStore = tokenStore ?? SecureApiTokenStore(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseAppUrl,
                connectTimeout: connectTimeout,
                sendTimeout: sendTimeout,
                receiveTimeout: receiveTimeout,
              ),
            ) {
    this.dio.interceptors.add(_AuthInterceptor(this));
    this.dio.interceptors.add(
      SafeApiLogInterceptor(logSink ?? debugPrint),
    );
  }

  static const _retriedRequestKey = 'api_client_retried';

  final Dio dio;
  final ApiTokenStore _tokenStore;
  final String refreshPath;
  Future<bool>? _refreshFuture;

  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path,
        method: 'POST',
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<bool> _refreshOnce() async {
    final runningRefresh = _refreshFuture;
    if (runningRefresh != null) {
      return runningRefresh;
    }

    final refresh = _performRefresh();
    _refreshFuture = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearSession();
      return false;
    }

    final refreshDio = Dio(dio.options)..httpClientAdapter = dio.httpClientAdapter;
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        refreshPath,
        queryParameters: {'refresh_token': refreshToken},
      );
      final data = response.data;
      final accessToken = _stripBearer(data?['access_token'] as String?);
      final newRefreshToken =
          _stripBearer(data?['refresh_token'] as String?) ?? refreshToken;
      if (accessToken == null || accessToken.isEmpty) {
        await _clearSession();
        return false;
      }
      await _tokenStore.saveTokens(accessToken, newRefreshToken);
      return true;
    } on Object {
      await _clearSession();
      return false;
    }
  }

  Future<void> _clearSession() async {
    try {
      await _tokenStore.clear();
    } on Object catch (error) {
      debugPrint('Could not clear the local API session: $error');
    }
  }

  static String? _stripBearer(String? token) {
    if (token == null) return null;
    return token.startsWith('Bearer ') ? token.substring(7) : token;
  }

  static ApiException _mapException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final message = _messageFrom(responseData) ?? error.message ?? 'Request failed';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkApiException(
        message: message,
        details: responseData,
      );
    }
    if (statusCode == 401 || statusCode == 403) {
      return UnauthorizedApiException(
        message: message,
        statusCode: statusCode,
        details: responseData,
      );
    }
    if (statusCode == 400 || statusCode == 409 || statusCode == 422) {
      return ValidationApiException(
        message: message,
        statusCode: statusCode,
        details: responseData,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerApiException(
        message: message,
        statusCode: statusCode,
        details: responseData,
      );
    }
    return UnknownApiException(
      message: message,
      statusCode: statusCode,
      details: responseData,
    );
  }

  static String? _messageFrom(Object? data) {
    if (data is Map<String, dynamic>) {
      final value = data['detail'] ?? data['message'];
      return value is String ? value : null;
    }
    return null;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path != _client.refreshPath) {
      final token = await _client._tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final isUnauthorized = error.response?.statusCode == 401;
    final wasRetried = request.extra[ApiClient._retriedRequestKey] == true;
    if (!isUnauthorized || wasRetried || request.path == _client.refreshPath) {
      if (isUnauthorized && wasRetried) {
        await _client._clearSession();
      }
      handler.next(error);
      return;
    }

    if (!await _client._refreshOnce()) {
      handler.next(error);
      return;
    }

    final accessToken = await _client._tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      await _client._clearSession();
      handler.next(error);
      return;
    }

    request.extra[ApiClient._retriedRequestKey] = true;
    request.headers['Authorization'] = 'Bearer $accessToken';
    try {
      handler.resolve(await _client.dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
