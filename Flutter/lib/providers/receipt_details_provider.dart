import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/models/receipt.dart';

final receiptDetailsProvider = StateProvider<Receipt>((ref) {
  return Receipt(storeName: "brak", date: "brak", items: []);
});