import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'subscription_models.dart';

abstract interface class SubscriptionRepository {
  Future<List<SubscriptionPlan>> getPlans();
  Future<ActiveSubscription?> getActiveSubscription();
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  );
  Future<PaymentStatusResponse> getPaymentStatus(String orderId);
  Future<ActiveSubscription> cancelRenewal();
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  });
}

class DioSubscriptionRepository implements SubscriptionRepository {
  DioSubscriptionRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/subscriptions',
    );
    final items = response.data?['subscriptions'];
    if (items is! List<dynamic>) {
      throw const FormatException('subscriptions must be a list');
    }
    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('subscription must be an object');
      }
      return SubscriptionPlan.fromJson(item);
    }).toList();
  }

  @override
  Future<ActiveSubscription?> getActiveSubscription() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/subscriptions/active',
    );
    return _parseActive(response.data);
  }

  @override
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/subscriptions/checkout',
      data: CheckoutRequest(subscriptionId).toJson(),
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty checkout response');
    }
    return CheckoutResponse.fromJson(data);
  }

  @override
  Future<PaymentStatusResponse> getPaymentStatus(String orderId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/subscriptions/payments/$orderId',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty payment status response');
    }
    return PaymentStatusResponse.fromJson(data);
  }

  @override
  Future<ActiveSubscription> cancelRenewal() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/subscriptions/cancel',
    );
    final active = _parseActive(response.data);
    if (active == null) {
      throw const FormatException('Cancel response has no subscription');
    }
    return active;
  }

  @override
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  }) async {
    final result = success ? 'success' : 'failure';
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/subscriptions/demo/payments/$orderId/$result',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty demo payment response');
    }
    return PaymentStatusResponse.fromJson(data);
  }

  ActiveSubscription? _parseActive(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('subscription')) {
      throw const FormatException('Invalid active subscription response');
    }
    final value = data['subscription'];
    if (value == null) {
      return null;
    }
    if (value is! Map<String, dynamic>) {
      throw const FormatException('subscription must be an object');
    }
    return ActiveSubscription.fromJson(value);
  }
}
