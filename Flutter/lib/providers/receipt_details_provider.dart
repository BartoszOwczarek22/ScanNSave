import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/models/receipt.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiptNotifier extends StateNotifier<Receipt> {
  ReceiptNotifier(Receipt initial) : super(initial);

  void updateItem(int index, ReceiptItem newItem) {
    final newItems = [...state.items];
    newItems[index] = newItem;
    state = state.copyWith(items: newItems);
  }

  void addItem(ReceiptItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(int index) {
    final newItems = [...state.items]..removeAt(index);
    state = state.copyWith(items: newItems);
  }
  void udateStoreName(String storeName) {
    state = state.copyWith(storeName: storeName);
  }
  void updateDate(String date) {
    state = state.copyWith(date: date);
  }
}

final receiptProvider =
    StateNotifierProvider<ReceiptNotifier, Receipt>(
      (ref) => throw UnimplementedError()
);
