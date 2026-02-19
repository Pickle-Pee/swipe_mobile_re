// lib/models/active_subscription.dart

class ActiveSubscription {
  final int subscriptionId;
  final DateTime endDate;

  ActiveSubscription({
    required this.subscriptionId,
    required this.endDate,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      subscriptionId: json['subscription_id'],
      endDate: DateTime.parse(json['end_date']),
    );
  }
}
