import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final textRecognitionProvider = FutureProvider.family<Receipt, String>((
  ref,
  imagePath,
) async {
  return parseTextFromImage(imagePath);
});

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

class ReceiptItemPositioned extends ReceiptItem {
  final TextLine line;

  ReceiptItemPositioned({
    required String name,
    required double quantity,
    required double price,
    required productType type,
    required this.line,
  }) : super(name: name, quantity: quantity, price: price, type: type);
}

Future<Receipt> parseTextFromImage(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(
    inputImage,
  );
  int top = -1;
  int bottom = -1;
  int left = -1;
  int right = -1;
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    if (recognizedText.blocks[i].text.contains('PARAGON FISKALNY')) {
      for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
        if (recognizedText.blocks[i].lines[j].text.contains(
          'PARAGON FISKALNY',
        )) {
          top = recognizedText.blocks[i].lines[j].cornerPoints[3].y;
          left = recognizedText.blocks[i].lines[j].cornerPoints[3].x;
          right = recognizedText.blocks[i].lines[j].cornerPoints[2].x;
          break;
        }
      }
      break;
    }
  }
  if (top == -1) {
    throw Exception('Nie znaleziono paragonu.');
  }
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    if (recognizedText.blocks[i].text.toUpperCase().contains("SPRZED")) {
      for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
        if (recognizedText.blocks[i].lines[j].text.toUpperCase().contains(
          "SPRZED",
        )) {
          bottom = recognizedText.blocks[i].cornerPoints[0].y;
          break;
        }
      }
      break;
    }
  }
  if (bottom == -1) {
    throw Exception('Nie znaleziono paragonu.');
  }

  final itemsPos = <ReceiptItemPositioned>[];
  String storeName = 'Nieznany sklep';
  String date = 'Brak daty';

  for (int i = 0; i < recognizedText.blocks.length; i++) {
    if (recognizedText.blocks[i].cornerPoints[3].y > top &&
        recognizedText.blocks[i].cornerPoints[0].y < bottom) {
      for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
        if (recognizedText.blocks[i].lines[j].text.length > 1) {
          if (recognizedText.blocks[i].lines[j].cornerPoints[0].x < left) {
            if (recognizedText.blocks[i].lines[j].cornerPoints[1].x < right) {
              if (!recognizedText.blocks[i].lines[j].text.contains(":")) {
                itemsPos.add(
                  ReceiptItemPositioned(
                    line: recognizedText.blocks[i].lines[j],
                    name: recognizedText.blocks[i].lines[j].text,
                    quantity: 1,
                    price: 0,
                    type: productType.perPiece,
                  ),
                );
              }
            } else {
              throw Exception('Jakiś dziwny paragon.');
            }
          } else if
           (recognizedText.blocks[i].lines[j].cornerPoints[1].x > right) {
            int smallestDif = 10000;
            int index = -1;
            for (int k = 0; k < itemsPos.length; k++) {
              int dif = (recognizedText.blocks[i].lines[j].cornerPoints[0].y - itemsPos[k].line.cornerPoints[1].y).abs();
              if (dif < smallestDif) {
                smallestDif = dif;
                index = k;
              }
            }
            if (index != -1) {
              final (double quantity, double price, productType type) = parsePriceQuantity(
                recognizedText.blocks[i].lines[j].text,
              );
              itemsPos[index].price = price;
              itemsPos[index].quantity = quantity;
              itemsPos[index].type = type;
              // itemsPos[index].quantity = int.parse(
              //   recognizedText.blocks[i].lines[j].text.split("x")[0],
              // );
            }
          }
        }
      }
    }
  }
  return Receipt(
    storeName: storeName,
    date: date,
    items: itemsPos.cast<ReceiptItem>(),
  );
}

(double, double, productType) parsePriceQuantity(String text) {
  final parts = text.split('x');
  if (parts.length == 2) {
    final quantity = double.tryParse(parts[0].trim().replaceAll(',', '.'));
    final parts2 = parts[1].split(' ');
    final price = double.tryParse(parts2[0].trim().replaceAll(',', '.'));
    if (quantity != null && price != null) {
      if (quantity % 1 == 0) {
        return (quantity, price, productType.perPiece);
      } else {
        return (quantity, price, productType.byWeight);
      }
    }
  }
  return (0.0, 0.0, productType.perPiece);
}
