import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final textRecognitionProvider = FutureProvider.family<Receipt, String>((ref, imagePath) async {
  return parseTextFromImage(imagePath);
});

 
class Receipt {
  final String storeName;
  final String date;
  final List<ReceiptItem> items;
  final double total;

  Receipt({required this.storeName, required this.date, required this.items})
    : total = items.fold(0, (sum, item) => sum + item.price * item.quantity);
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double price;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}


Future<Receipt> parseTextFromImage(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

  int proBlockId = -1;
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    if (recognizedText.blocks[i].text.contains('PARAGON FISKALNY')) {
      proBlockId = i;
      proBlockId += 1;
      break;
    }
  }
  if (proBlockId == -1) {
    throw Exception('Nie znaleziono paragonu.');
  }
  final items = <ReceiptItem>[];
  String storeName = 'Nieznany sklep';
  String date = 'Brak daty';
  for (int i = 0; i < recognizedText.blocks[proBlockId].lines.length; i++) {
    items.add(ReceiptItem(
      name: recognizedText.blocks[proBlockId].lines[i].text,
      quantity: 1,
      price: 0.0,
    ));
  }
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    
  }

  //🔽 Uproszczony parser (demo)
  // final lines = recognizedText.text.split('\n');
  // final items = <ReceiptItem>[];
  // String storeName = 'Nieznany sklep';
  // String date = 'Brak daty';

  // for (final line in lines) {
  //   if (line.contains(RegExp(r'\d{2}[./-]\d{2}[./-]\d{4}'))) {
  //     date = line;
  //   } else if (RegExp(r'[0-9]+\s*x\s*[0-9,]+').hasMatch(line)) {
  //     // Przykład: "2 x 3,49"
  //     final parts = line.split(RegExp(r'\s+x\s+'));
  //     if (parts.length == 2) {
  //       try {
  //         final quantity = int.parse(parts[0]);
  //         final price = double.parse(parts[1].replaceAll(',', '.'));
  //         items.add(ReceiptItem(name: 'Produkt', quantity: quantity, price: price));
  //       } catch (_) {}
  //     }
  //   } else if (items.isEmpty) {
  //     storeName = line;
  //   }
  // }

  return Receipt(storeName: storeName, date: date, items: items);
}