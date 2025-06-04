import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scan_n_save/models/receipt.dart';
import 'package:scan_n_save/services/receipt_parsing_service.dart';

class MockPriceQuantity {
  final double quantity;
  final double price;
  final productType type;
  final String? name;

  MockPriceQuantity({required this.quantity, required this.price, required this.type, required this.name});
}

List<MockPriceQuantity> mockPriceQuantities = [
  MockPriceQuantity(quantity: 1.0, price: 2.99, type: productType.perPiece, name: '1.0x 2.99 2.99'),
  MockPriceQuantity(quantity: 3.2, price: 83.89, type: productType.byWeight, name: '3.2x 83.8983.89'),
  MockPriceQuantity(quantity: 1.0, price: 2.99, type: productType.perPiece, name: '1.0szt. 2.99 2.99'),
  MockPriceQuantity(quantity: 2.0, price: 5.99, type: productType.perPiece, name: '2.0szt 5.995.99 A'),
  MockPriceQuantity(quantity: 1.0, price: 9.99, type: productType.perPiece, name: '1.0szt. x9.99 9.99C'),
];

void main() {
  group('price&quantity parsing', () {
    for (int i = 0; i < mockPriceQuantities.length; i++) {
      test('should parse price and quantity from "${mockPriceQuantities[i].name}"', () {
        final receiptText = mockPriceQuantities[i].name!;
        final parsedData = parsePriceQuantity(TextLine(text: receiptText, boundingBox: Rect.fromLTRB(0, 0, 100, 100), cornerPoints: [], elements: [], recognizedLanguages: [], confidence: 1.0, angle: 0.0));

        expect(parsedData.quantity, mockPriceQuantities[i].quantity);
        expect(parsedData.price, mockPriceQuantities[i].price);
        expect(parsedData.type, mockPriceQuantities[i].type);
      });
    }
    

    // test('should handle missing price or quantity gracefully', () {
    //   final receiptText = 'Item: Banana, Quantity: 2';
    //   final parsedData = ReceiptParsingService.parseReceipt(receiptText);

    //   expect(parsedData['price'], null);
    //   expect(parsedData['quantity'], 2);
    // });

    // test('should return null for invalid input', () {
    //   final receiptText = 'Invalid receipt text';
    //   final parsedData = ReceiptParsingService.parseReceipt(receiptText);

    //   expect(parsedData, isNull);
    // });
  });
}