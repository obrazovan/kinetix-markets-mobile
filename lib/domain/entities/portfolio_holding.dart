/// User-owned virtual portfolio position tracked against live/cached prices.
class PortfolioHolding {
  const PortfolioHolding({
    required this.symbol,
    required this.quantity,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      symbol: json['symbol'] as String,
      quantity: (json['quantity'] as num).toDouble(),
    );
  }

  final String symbol;
  final double quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'symbol': symbol,
        'quantity': quantity,
      };
}
