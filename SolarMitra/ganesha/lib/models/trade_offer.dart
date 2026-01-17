// lib/models/trade_offer.dart

class TradeOffer {
  final String offerId;
  final String sellerUsername; // Using username instead of UID
  final double amountKWh;
  final double pricePerKWh;
  final double poSWSellerScore;
  final DateTime timestamp;

  TradeOffer({
    required this.offerId,
    required this.sellerUsername,
    required this.amountKWh,
    required this.pricePerKWh,
    required this.poSWSellerScore,
    required this.timestamp,
  });

  factory TradeOffer.fromSnapshot(String id, Map<dynamic, dynamic> data) {
    return TradeOffer(
      offerId: id,
      sellerUsername: data['sellerUsername'] as String,
      amountKWh: (data['amountKWh'] as num).toDouble(),
      pricePerKWh: (data['pricePerKWh'] as num).toDouble(),
      poSWSellerScore: (data['poSWSellerScore'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'sellerUsername': sellerUsername,
        'amountKWh': amountKWh,
        'pricePerKWh': pricePerKWh,
        'poSWSellerScore': poSWSellerScore,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}