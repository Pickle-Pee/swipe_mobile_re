import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:swipe_mobile_re/core/config/config.dart';
import 'package:swipe_mobile_re/core/network/dio_interceptors.dart';
import 'package:swipe_mobile_re/data/models/active_subscription.dart';
import 'package:swipe_mobile_re/data/models/subscription.dart';
class SubscriptionHttp {
  // Синглтон
  static final SubscriptionHttp _instance = SubscriptionHttp._internal();
  factory SubscriptionHttp() => _instance;

  late Dio dio;

  SubscriptionHttp._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseAppUrl,
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 3000),
    ));
    dio.interceptors.add(SwipeInterceptor(dio));
  }

  /// Инициализация платежа
  Future<Map<String, dynamic>?> initPayment({
    required String orderId,
    required double amount,
    required String customerKey,
    required String phone,
    required String subscriptionId,
  }) async {
    try {
      Map<String, dynamic> body = {
        'orderId': orderId,
        'amount': amount,
        'customerKey': customerKey,
        'phone': phone,
        'subscriptionId': subscriptionId,
      };

      Response response = await dio.post(
        "/subscriptions/init_payment",
        data: jsonEncode(body),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;

      if (response.statusCode == 200 &&
          data['paymentId'] != null &&
          data['paymentURL'] != null) {
        return {
          'paymentId': data['paymentId'],
          'paymentURL': data['paymentURL'],
          'orderId': orderId,
          'amount': amount,
          'description': data['description'] ?? "Оплата по заказу №$orderId",
          'customerKey': customerKey,
          'subscriptionId': subscriptionId
        };
      } else {
        throw Exception('Failed to initialize payment on server');
      }
    } catch (e) {
      print('Ошибка при инициализации платежа: $e');
      throw Exception('Не удалось инициализировать платеж');
    }
  }

  /// Получить все доступные подписки
  Future<List<Subscription>> getAllSubscriptions() async {
    try {
      print('Запрос подписок отправлен на /subscriptions');
      Response response = await dio.get("/subscriptions/");
      print('Ответ получен: ${response.statusCode}');
      print('Данные ответа: ${response.data}');

      final data = response.data;

      if (data['subscriptions'] == null || data['subscriptions'] is! List) {
        throw Exception('Некорректный формат данных от сервера');
      }

      List<Subscription> subscriptions = [];
      for (var sub in data['subscriptions']) {
        subscriptions.add(Subscription.fromJson(sub));
      }
      print('Загруженные подписки: ${subscriptions.length}');
      return subscriptions;
    } catch (e) {
      print('Ошибка при получении подписок: $e');
      throw Exception('Не удалось получить подписки');
    }
  }

  /// Получить активную подписку пользователя
  Future<ActiveSubscription?> getActiveSubscription() async {
    try {
      Response response = await dio.get("/subscriptions/active");
      final data = response.data;

      if (data['subscription_id'] != null) {
        return ActiveSubscription.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Ошибка при получении активной подписки: $e');
      throw Exception('Не удалось получить активную подписку');
    }
  }

  /// Активировать платную подписку
  Future<String?> activateSubscription({
    required int subscriptionId,
    required String orderId,
    required double amount,
    required String customerKey,
    required int paymentId,
  }) async {
    try {
      // Формирование тела запроса
      Map<String, dynamic> body = {
        'subscription_id': subscriptionId,
        'order_id': orderId,
        'amount': amount,
        'customer_key': customerKey,
        'payment_id': paymentId,
      };

      Response response = await dio.post(
        "/subscriptions/activate_subscription",
        data: jsonEncode(body),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;

      // Предполагается, что бэкенд возвращает статус (например, "success")
      return data['status'];
    } catch (e) {
      print('Ошибка при активации подписки: $e');
      throw Exception('Не удалось активировать подписку');
    }
  }

  /// Отменить активную подписку
  Future<bool> cancelSubscription() async {
    try {
      Response response = await dio.post(
        "/subscriptions/cancel",
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Не удалось отменить подписку: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Ошибка при отмене подписки: $e');
      throw Exception('Не удалось отменить подписку');
    }
  }

  /// --- NEW: Активировать промо-подписку ---
  Future<Map<String, dynamic>> activatePromoSubscription() async {
    try {
      final response = await dio.post(
        "/subscriptions/promo_activate",
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ожидаем что вернётся JSON вида
        // {
        //    "message": "...",
        //    "subscription_id": 999,
        //    "end_date": "2024-12-31T23:59:59"
        // }
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Не удалось активировать промо-подписку');
      }
    } catch (e) {
      print('Ошибка при активации промо-подписки: $e');
      throw Exception('Не удалось активировать промо-подписку');
    }
  }
}
