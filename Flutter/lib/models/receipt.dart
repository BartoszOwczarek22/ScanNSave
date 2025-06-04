import 'package:firebase_auth/firebase_auth.dart';

class Receipt {
  final String storeName;
  final String? date;
  final List<ReceiptItem> items;
  final double total;

  Receipt({required this.storeName, required this.date, required this.items})
  : total = items.fold(0, (sum, item) => sum + item.price * item.quantity);

  Map<String, dynamic> toJson() => {
    //'storeName': storeName,
    'date': date,
    'receipt_indekses': items.map((item) => item.toJson()).toList(),
    'sum_price': total,
    'creator_id': FirebaseAuth.instance.currentUser?.uid,
    'pic_path': 'path',
    'shop_parcel_id': "6a074237-ca4f-47e0-b657-651d7ce72df2",
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
    'indeks': name,
    //'type': productTypeToString(type),
    'quantity': quantity,
    'price': price,
    //'product_id': 0,
    //'shop_id': 0,
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
