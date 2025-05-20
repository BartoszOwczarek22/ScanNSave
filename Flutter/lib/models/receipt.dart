class Receipt {
  final String storeName;
  final String date;
  final List<ReceiptItem> items;
  final double total;

  Receipt({required this.storeName, required this.date, required this.items})
    : total = 0.0;
  //: total = items.fold(0, (sum, item) => sum + item.price * item.quantity);
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
}
