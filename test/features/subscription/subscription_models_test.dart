import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';

void main() {
  test('parses contract values and UTC dates', () {
    final plan = SubscriptionPlan.fromJson({
      'id': 1,
      'name': 'Premium',
      'description': 'Thirty days',
      'price_minor': 49900,
      'currency': 'RUB',
      'duration_days': 30,
      'is_active': true,
      'renewable': false,
    });
    final checkout = CheckoutResponse.fromJson({
      'order_id': 'order-1',
      'payment_id': null,
      'payment_url': null,
      'status': 'pending',
      'amount_minor': 49900,
      'currency': 'RUB',
      'expires_at': '2026-07-13T01:00:00',
    });
    expect(plan.priceMinor, 49900);
    expect(checkout.paymentId, isNull);
    expect(checkout.expiresAt!.isUtc, isTrue);
  });

  test('parses all statuses and rejects unknown values', () {
    const values = [
      'pending',
      'requires_action',
      'processing',
      'succeeded',
      'failed',
      'canceled',
      'refunded',
      'partially_refunded',
    ];
    expect(values.map(PaymentStatus.fromJson).toSet().length, values.length);
    expect(() => PaymentStatus.fromJson('CONFIRMED'), throwsFormatException);
  });

  test('rejects invalid payment URL', () {
    expect(
      () => CheckoutResponse.fromJson({
        'order_id': 'order-1',
        'payment_id': '1',
        'payment_url': 'invalid',
        'status': 'pending',
        'amount_minor': 100,
        'currency': 'RUB',
        'expires_at': null,
      }),
      throwsFormatException,
    );
  });
}
