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
  
  });
  List<(String, String)> testStringsPositive = [
    ("sprzed", "spzed"),
    ("Spred", "Sprzed"),
    ("qq", "ee"), // dopuszcza się dwa błędy 
    ("apple", "appl"), 
    ("banana", "banan"),
    ("grape", "grap"),
  ];
  List<(String, String)> testStringsNegative = [
    ("sprzed", "dsfad"),
    ("Spred", "sqod"),
    ("qqqqq", "eeeee")
  ];
  group('string similarity tests', () {
    for (var testString in testStringsPositive) {
      test('should be true for "${testString.$1}" and "${testString.$2}"', () async {
        final result = await isSimilar(testString.$1, testString.$2);
        expect(result, true);
      });
    }
    for (var testString in testStringsNegative) {
      test('should be false for "${testString.$1}" and "${testString.$2}"', () async {
        final result = await isSimilar(testString.$1, testString.$2);
        expect(result, false);
      });
    }
  });

  List<(String, String)> testStringsDatePositive = [
    ("dfafsdfsdf2023-10-01asdfasdf dfas 230-45-2", "2023-10-01"),
    ("ggjdfklg dfkjs;f jf fdlk g 2021-12-30","2021-12-30"),
    ("2017-07-12 sdfasdusdaf das 78 92 78.443 dasdHFJDS 9999-99-99","2017-07-12"),
  ];
  List<String> testStringsDateNegative = [
    "dfafsdfsdf2023-10-0asdfasdf dfas 230-45-2",
    "ggjdfklg dfkjs;f jf fdlk g 2021-1230",
    "2017-22-12 sdfasdusdaf das 78 92 78.443 dasdHFJDS 9999-99-99"
  ];
  group("detecting date tests", () {
    for (var testString in testStringsDatePositive) {
      test('should detect date "${testString.$2}" in "${testString.$1}"', () {
        final result = detectDate(testString.$1);
        expect(result, isNotNull);
        expect(result, testString.$2);
      });
    }

    for (var testString in testStringsDateNegative) {
      test('should detect null in "${testString}"', () {
        final result = detectDate(testString);
        expect(result, isNull);
      });
    }
  });
}