import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';

void main() {
  test('uses canonical endpoints and sends only subscription_id', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = MockAdapter((options) async {
        requests.add(options);
        if (options.path == '/subscriptions') {
          return response(200, {
            'subscriptions': [planJson()],
          });
        }
        if (options.path == '/subscriptions/active') {
          return response(200, {'subscription': null});
        }
        if (options.path == '/subscriptions/checkout') {
          return response(201, checkoutJson());
        }
        if (options.path.contains('/payments/')) {
          return response(200, paymentJson());
        }
        return response(200, {'subscription': activeJson()});
      });
    final repository = DioSubscriptionRepository(
      ApiClient(dio: dio, tokenStore: EmptyTokenStore(), logSink: (_) {}),
    );
    expect((await repository.getPlans()).single.priceMinor, 49900);
    expect(await repository.getActiveSubscription(), isNull);
    await repository.createCheckout(1, 'key-1');
    await repository.getPaymentStatus('order-1');
    expect((await repository.cancelRenewal()).renewable, isFalse);
    final checkout = requests.singleWhere(
      (r) => r.path == '/subscriptions/checkout',
    );
    expect(checkout.data, {'subscription_id': 1});
    expect(checkout.headers['Idempotency-Key'], 'key-1');
    expect(
      requests.map((request) => request.path).toSet(),
      {
        '/subscriptions',
        '/subscriptions/active',
        '/subscriptions/checkout',
        '/subscriptions/payments/order-1',
        '/subscriptions/cancel',
      },
    );
    expect(requests.every((request) => request.uri.host == 'api.test'), isTrue);
  });

  test('rejects malformed list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = MockAdapter(
        (_) async => response(200, {'subscriptions': 'bad'}),
      );
    final repository = DioSubscriptionRepository(
      ApiClient(dio: dio, tokenStore: EmptyTokenStore(), logSink: (_) {}),
    );
    expect(repository.getPlans(), throwsFormatException);
  });
}

Map<String, dynamic> planJson() => {
  'id': 1,
  'name': 'Premium',
  'description': 'Plan',
  'price_minor': 49900,
  'currency': 'RUB',
  'duration_days': 30,
  'is_active': true,
  'renewable': false,
};
Map<String, dynamic> checkoutJson() => {
  'order_id': 'order-1',
  'payment_id': 'payment-1',
  'payment_url': 'https://pay.test/1',
  'status': 'pending',
  'amount_minor': 49900,
  'currency': 'RUB',
  'expires_at': null,
};
Map<String, dynamic> activeJson() => {
  'subscription_id': 1,
  'name': 'Premium',
  'start_at': '2026-07-13T01:00:00Z',
  'end_at': '2026-08-12T01:00:00Z',
  'renewable': false,
};
Map<String, dynamic> paymentJson() => {
  'order_id': 'order-1',
  'payment_id': 'payment-1',
  'status': 'processing',
  'subscription_activated': false,
  'subscription': null,
  'failure_code': null,
  'failure_message': null,
  'updated_at': '2026-07-13T01:00:00Z',
};

typedef Handler = Future<ResponseBody> Function(RequestOptions options);

class MockAdapter implements HttpClientAdapter {
  MockAdapter(this.handler);
  final Handler handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(int code, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  code,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

class EmptyTokenStore implements ApiTokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}
}
