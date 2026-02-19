

import 'package:swipe_mobile_re/core/network/subscriptions/subscription_http.dart';
import 'package:swipe_mobile_re/data/models/active_subscription.dart';
import 'package:swipe_mobile_re/data/models/subscription.dart';

class SubscriptionService {
  final SubscriptionHttp _subscriptionHttp = SubscriptionHttp();

  /// Получение списка доступных подписок
  Future<List<Subscription>> fetchSubscriptions() async {
    return await _subscriptionHttp.getAllSubscriptions();
  }

  /// Получение активной подписки пользователя
  Future<ActiveSubscription?> fetchActiveSubscription() async {
    return await _subscriptionHttp.getActiveSubscription();
  }

  /// Инициализация платежа
  Future<Map<String, dynamic>?> initPayment({
    required String orderId,
    required double amount,
    required String customerKey,
    required String phone,
    required String subscriptionId,
  }) async {
    return await _subscriptionHttp.initPayment(
      orderId: orderId,
      amount: amount,
      customerKey: customerKey,
      phone: phone,
      subscriptionId: subscriptionId,
    );
  }

  /// Активация подписки
  Future<String?> activateSubscription({
    required int subscriptionId,
    required String orderId,
    required double amount,
    required String customerKey,
    required int paymentId,  // ИЗМЕНЕНО: добавили
  }) async {
    // ИЗМЕНЕНО: передаем paymentId в _subscriptionHttp
    return await _subscriptionHttp.activateSubscription(
      subscriptionId: subscriptionId,
      orderId: orderId,
      amount: amount,
      customerKey: customerKey,
      paymentId: paymentId, // <-- int
    );
  }

  /// Отмена активной подписки
  Future<bool> cancelSubscription() async {
    return await _subscriptionHttp.cancelSubscription();
  }
}
