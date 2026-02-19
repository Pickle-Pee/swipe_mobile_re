import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:swipe_mobile_re/core/network/subscriptions/subscription_http.dart';
import 'package:swipe_mobile_re/data/models/active_subscription.dart';
import 'package:swipe_mobile_re/data/models/subscription.dart';
import 'package:swipe_mobile_re/data/repositories/profile/profile.dart';
import 'package:swipe_mobile_re/data/services/subscription_services.dart';


class PaymentService {
  static const MethodChannel _channel =
      MethodChannel('com.example.swiper/payment');

  final SubscriptionService _subscriptionService = SubscriptionService();
  final ProfileStore profileStore;

  PaymentService(this.profileStore);

  /// Инициализация платежа
  Future<Map<String, dynamic>?> startPayment({
    required String orderId,
    required double amount,
    required String description,
    required String phone,
    required String customerKey,
    required String subscriptionId,
  }) async {
    try {
      // 1) Инициализация платежа на сервере
      final Map<String, dynamic>? paymentData = await _initializePaymentOnServer(
        orderId: orderId,
        amount: amount,
        description: description,
        phone: phone,
        customerKey: customerKey,
        subscriptionId: subscriptionId,
      );

      if (paymentData == null ||
          paymentData['paymentId'] == null ||
          paymentData['paymentURL'] == null) {
        throw Exception('Не удалось инициализировать платеж на сервере.');
      }

      // 2) Вызов метода на нативной стороне
      print("Invoking native 'startPayment' with data: $paymentData");
      final dynamic result = await _channel.invokeMethod('startPayment', {
        'paymentId': paymentData['paymentId']?.toString(),
        'orderId': paymentData['orderId']?.toString(),
        'amount': paymentData['amount']?.toString(),
        'description': paymentData['description']?.toString(),
        'paymentURL': paymentData['paymentURL']?.toString(),
        'customerKey': paymentData['customerKey']?.toString(),
        'subscriptionId': paymentData['subscriptionId']?.toString(),
        'phone': phone,
      });

      print("Received result from native: $result");

      // 3) Приведение результата к Map<String, dynamic>, если возможно
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      } else if (result is String) {
        // Если вдруг нативный код вернул строку
        try {
          return json.decode(result);
        } catch (e) {
          throw Exception("Некорректный формат ответа от нативной стороны.");
        }
      } else {
        throw Exception("Неизвестный формат ответа от нативной стороны.");
      }
    } on PlatformException catch (e) {
      print("Не удалось начать платеж: '${e.message}'.");
      throw Exception("Не удалось начать платеж: ${e.message}");
    } catch (e) {
      print("Неизвестная ошибка при запуске платежа: $e");
      throw Exception("Неизвестная ошибка при запуске платежа: $e");
    }
  }

  /// Инициализация платежа на сервере
  Future<Map<String, dynamic>?> _initializePaymentOnServer({
    required String orderId,
    required double amount,
    required String description,
    required String phone,
    required String customerKey,
    required String subscriptionId,
  }) async {
    try {
      final Map<String, dynamic>? paymentData =
          await SubscriptionHttp().initPayment(
        orderId: orderId,
        amount: amount,
        customerKey: customerKey,
        phone: phone,
        subscriptionId: subscriptionId,
      );

      if (paymentData == null) {
        throw Exception('Payment data is null');
      }

      return paymentData;
    } catch (e) {
      print('Ошибка при инициализации платежа на сервере: $e');
      rethrow;
    }
  }

  /// Получение списка доступных подписок
  Future<List<Subscription>> fetchSubscriptions() async {
    print('Запрос списка подписок с бэкенда.');
    return await _subscriptionService.fetchSubscriptions();
  }

  /// Активация подписки через бэкенд
  Future<String?> activateSubscription({
    required int subscriptionId,
    required String orderId,
    required double amount,
    required int paymentId, // ИЗМЕНЕНО: стало int
  }) async {
    final int? userId = profileStore.userInfo?.id;
    if (userId == null) {
      throw Exception('User ID is required to activate subscription.');
    }

    print('Активация подписки: subscriptionId=$subscriptionId, paymentId=$paymentId');

    try {
      // ИЗМЕНЕНО: передаем paymentId как int
      final String? status = await _subscriptionService.activateSubscription(
        subscriptionId: subscriptionId,
        orderId: orderId,
        amount: amount,
        customerKey: userId.toString(),
        paymentId: paymentId, // <-- int
      );
      return status;
    } catch (e) {
      print('Ошибка при активации подписки: $e');
      throw Exception('Не удалось активировать подписку');
    }
  }

  /// Получение активной подписки пользователя
  Future<ActiveSubscription?> getActiveSubscription() async {
    print('Запрос активной подписки пользователя.');
    return await _subscriptionService.fetchActiveSubscription();
  }

  /// Отмена активной подписки
  Future<bool> cancelSubscription() async {
    print('Отмена активной подписки.');
    return await _subscriptionService.cancelSubscription();
  }
}
