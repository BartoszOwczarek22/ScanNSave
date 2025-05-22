class Receipt {
  final String storeName;
  final String? date;
  final List<ReceiptItem> items;
  final double total;

  Receipt({required this.storeName, required this.date, required this.items})
  : total = items.fold(0, (sum, item) => sum + item.price * item.quantity);

  Map<String, dynamic> toJson() => {
    'storeName': storeName,
    'date': date,
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
  };
  Receipt copyWith({
    String? storeName,
    String? date,
    List<ReceiptItem>? items,
  }) {
    return Receipt(
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      items: items ?? this.items,
    );
  }
}
enum productType {
  perPiece,
  byWeight,
}
class ReceiptItem {
  final String name;
  productType type;
  double quantity;
  double price;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': productTypeToString(type),
    'quantity': quantity,
    'price': price,
  };
  ReceiptItem copyWith({
    String? name,
    double? quantity,
    double? price,
    productType? type,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      type: type ?? this.type,
    );
  }
}

String productTypeToString(productType type) {
  return type.toString().split('.').last;
}
