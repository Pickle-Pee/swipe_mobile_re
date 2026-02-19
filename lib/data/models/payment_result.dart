class PaymentResult {
  final String status;
  final int? paymentId;
  final String? cardId;
  final String? rebillId;
  final String? error;

  PaymentResult({
    required this.status,
    this.paymentId,
    this.cardId,
    this.rebillId,
    this.error,
  });

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    final raw = map['paymentId'];
    int? pid;
    if (raw != null) {
      if (raw is int) {
        pid = raw; // Уже int
      } else {
        // Если вдруг приходит как строка, пробуем распарсить
        pid = int.tryParse(raw.toString());
      }
    }
    return PaymentResult(
      status: map['status'] ?? 'unknown',
      paymentId: pid,
      cardId: map['cardId'],
      rebillId: map['rebillId'],
      error: map['error'],
    );
  }
}
