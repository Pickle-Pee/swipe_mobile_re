// lib/models/saved_card.dart

class SavedCard {
  final String cardId;
  final String maskedPan;
  final String expiryDate;
  final String cardType;

  SavedCard({
    required this.cardId,
    required this.maskedPan,
    required this.expiryDate,
    required this.cardType,
  });

  factory SavedCard.fromMap(Map<String, dynamic> map) {
    return SavedCard(
      cardId: map['cardId'],
      maskedPan: map['maskedPan'],
      expiryDate: map['expiryDate'],
      cardType: map['cardType'],
    );
  }
}
