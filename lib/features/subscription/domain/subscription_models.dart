enum PaymentStatus {
  pending,
  requiresAction,
  processing,
  succeeded,
  failed,
  canceled,
  refunded,
  partiallyRefunded;

  static PaymentStatus fromJson(Object? value) => switch (value) {
    'pending' => PaymentStatus.pending,
    'requires_action' => PaymentStatus.requiresAction,
    'processing' => PaymentStatus.processing,
    'succeeded' => PaymentStatus.succeeded,
    'failed' => PaymentStatus.failed,
    'canceled' => PaymentStatus.canceled,
    'refunded' => PaymentStatus.refunded,
    'partially_refunded' => PaymentStatus.partiallyRefunded,
    _ => throw FormatException('Unknown payment status: $value'),
  };
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceMinor,
    required this.currency,
    required this.durationDays,
    required this.isActive,
    required this.renewable,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
  final int priceMinor;
  final String currency;
  final int durationDays;
  final bool isActive;
  final bool renewable;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: _int(json, 'id'),
        name: _string(json, 'name'),
        description: json['description'] as String?,
        priceMinor: _int(json, 'price_minor'),
        currency: _string(json, 'currency'),
        durationDays: _int(json, 'duration_days'),
        isActive: _bool(json, 'is_active'),
        renewable: _bool(json, 'renewable'),
      );
}

class CheckoutRequest {
  const CheckoutRequest(this.subscriptionId);
  final int subscriptionId;
  Map<String, dynamic> toJson() => {'subscription_id': subscriptionId};
}

class CheckoutResponse {
  const CheckoutResponse({
    required this.orderId,
    required this.status,
    required this.amountMinor,
    required this.currency,
    this.paymentId,
    this.paymentUrl,
    this.expiresAt,
  });

  final String orderId;
  final String? paymentId;
  final Uri? paymentUrl;
  final PaymentStatus status;
  final int amountMinor;
  final String currency;
  final DateTime? expiresAt;

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) =>
      CheckoutResponse(
        orderId: _string(json, 'order_id'),
        paymentId: json['payment_id'] as String?,
        paymentUrl: _optionalUri(json['payment_url']),
        status: PaymentStatus.fromJson(json['status']),
        amountMinor: _int(json, 'amount_minor'),
        currency: _string(json, 'currency'),
        expiresAt: _optionalUtc(json['expires_at']),
      );
}

class ActiveSubscription {
  const ActiveSubscription({
    required this.subscriptionId,
    required this.name,
    required this.startAt,
    required this.endAt,
    required this.renewable,
  });

  final int subscriptionId;
  final String name;
  final DateTime startAt;
  final DateTime endAt;
  final bool renewable;

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) =>
      ActiveSubscription(
        subscriptionId: _int(json, 'subscription_id'),
        name: _string(json, 'name'),
        startAt: _utc(json, 'start_at'),
        endAt: _utc(json, 'end_at'),
        renewable: _bool(json, 'renewable'),
      );
}

class PaymentStatusResponse {
  const PaymentStatusResponse({
    required this.orderId,
    required this.status,
    required this.subscriptionActivated,
    required this.updatedAt,
    this.paymentId,
    this.subscription,
    this.failureCode,
    this.failureMessage,
  });

  final String orderId;
  final String? paymentId;
  final PaymentStatus status;
  final bool subscriptionActivated;
  final ActiveSubscription? subscription;
  final String? failureCode;
  final String? failureMessage;
  final DateTime updatedAt;

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawSubscription = json['subscription'];
    return PaymentStatusResponse(
      orderId: _string(json, 'order_id'),
      paymentId: json['payment_id'] as String?,
      status: PaymentStatus.fromJson(json['status']),
      subscriptionActivated: _bool(json, 'subscription_activated'),
      subscription: rawSubscription == null
          ? null
          : ActiveSubscription.fromJson(_map(rawSubscription, 'subscription')),
      failureCode: json['failure_code'] as String?,
      failureMessage: json['failure_message'] as String?,
      updatedAt: _utc(json, 'updated_at'),
    );
  }
}

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$field must be an object');
}

int _int(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw FormatException('$field must be an integer');
}

String _string(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$field must be a non-empty string');
}

bool _bool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is bool) return value;
  throw FormatException('$field must be a boolean');
}

DateTime _utc(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a date string');
  return _parseUtc(value);
}

DateTime? _optionalUtc(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('date must be a string');
  return _parseUtc(value);
}

DateTime _parseUtc(String value) {
  final normalized =
      value.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(value)
      ? value
      : '${value}Z';
  return DateTime.parse(normalized).toUtc();
}

Uri? _optionalUri(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw const FormatException('payment_url must be a string');
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasScheme ||
      !uri.hasAuthority ||
      !{'http', 'https'}.contains(uri.scheme)) {
    throw const FormatException('payment_url must be an absolute HTTP(S) URL');
  }
  return uri;
}
