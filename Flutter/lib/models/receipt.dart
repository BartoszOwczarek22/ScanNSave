class Receipt {
  final String storeName;
  final String? date;
  final List<ReceiptItem> items;
  final double total;
  final String userId; // Teraz wymagane pole

  Receipt({
    required this.storeName,
    required this.date,
    required this.items,
    required this.userId,
  }) : total = items.fold(0, (sum, item) => sum + item.price * item.quantity);

  Map<String, dynamic> toJson() => {
    'storeName': storeName,
    'date': date,
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
    'userId': userId,
  };

  Receipt copyWith({
    String? storeName,
    String? date,
    List<ReceiptItem>? items,
    String? userId,
  }) {
    return Receipt(
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      items: items ?? this.items,
      userId: userId ?? this.userId,
    );
  }
}

class ReceiptItem {
  final String name;
  double quantity;
  double price;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
  };

  ReceiptItem copyWith({
    String? name,
    double? quantity,
    double? price,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}