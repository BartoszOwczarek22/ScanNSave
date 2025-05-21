import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scan_n_save/models/receipt.dart';
import 'package:dart_levenshtein/dart_levenshtein.dart';


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
  (top, left, right) = detectTop(recognizedText);
  // for (int i = 0; i < recognizedText.blocks.length; i++) {
  //   if (recognizedText.blocks[i].text.contains('PARAGON FISKALNY')) {
  //     for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
  //       if (recognizedText.blocks[i].lines[j].text.contains(
  //         'PARAGON FISKALNY',
  //       )) {
  //         top = recognizedText.blocks[i].lines[j].cornerPoints[3].y;
  //         left = recognizedText.blocks[i].lines[j].cornerPoints[3].x;
  //         right = recognizedText.blocks[i].lines[j].cornerPoints[2].x;
  //         break;
  //       }
  //     }
  //     break;
  //   }
  // }
  if (top == -1) {
    throw Exception('Nie znaleziono paragonu.');
  }
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    if (recognizedText.blocks[i].text.toUpperCase().contains(RegExp("SPR[ZE][EDŁL]"))) {
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
  String storeName = detectStoreName(recognizedText.text);
  String date = 'Brak daty';

  for (int i = 0; i < recognizedText.blocks.length; i++) {
    if (recognizedText.blocks[i].cornerPoints[3].y > top &&
        recognizedText.blocks[i].cornerPoints[0].y < bottom) {
      for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
        if (recognizedText.blocks[i].lines[j].text.length > 1) {
          if (recognizedText.blocks[i].lines[j].cornerPoints[0].x < left) {
            if (recognizedText.blocks[i].lines[j].cornerPoints[1].x < right) {
              //if (!recognizedText.blocks[i].lines[j].text.contains(":")) {
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
            //} else {
              //throw Exception('Jakiś dziwny paragon.');
            //}
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

Future<bool> isSimilar(String a, String b, {int maxDistance = 2}) async {
  return await a.toLowerCase().levenshteinDistance(b.toLowerCase()) <= maxDistance;
}

Future<bool> ContainsLeven(String ocrText, List<String> keywords, {int maxDistance = 2,}) async {
  final wordsInText = ocrText.split(RegExp(r'\s+'));

  for (final keyword in keywords) {
    for (final word in wordsInText) {
      final distance = await isSimilar(word, keyword);
      if (distance) {
        return true;
      }
      
    }
  }
  return false;
}

(int, int, int) detectTop(RecognizedText recognizedText){
  bool parFound = false;
  int top = -1;
  int left = -1;
  int right = -1;
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
      if (recognizedText.blocks[i].lines[j].text.toUpperCase().replaceAll(' ', '').
      contains('PARAGON')) {
        parFound = true;
        top = recognizedText.blocks[i].lines[j].cornerPoints[3].y;
        left = recognizedText.blocks[i].lines[j].cornerPoints[3].x;
        i = recognizedText.blocks.length;
        break;
      }
    }
  }
  if (!parFound) {
    throw Exception('Nie znaleziono paragonu.');
  }
  bool fiskalnyFound = false;
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
      if (recognizedText.blocks[i].lines[j].text.toUpperCase().replaceAll(' ', '').
      contains("FISKALNY")) {
        fiskalnyFound = true;
        right = recognizedText.blocks[i].lines[j].cornerPoints[2].x;
        i = recognizedText.blocks.length;
        break;
      }
    }
  }
  if (!fiskalnyFound) {
    throw Exception('Nie znaleziono paragonu.');
  }

  return (top, left, right);
}

String detectStoreName(String ocrText) {
  final keywords = [
    'biedronka',
    'lidl',
    'tesco',
    'carrefour',
    'żabka',
    'stokrotka',
    'netto',
    'kaufland',
    'auchan',
    'chata polska',
    'selgros',
    'makro',
    'intermarche',
    'freshmarket',
    'dino',
    'aldi',
    'eurospar',
  ];
  final textLower = ocrText.toLowerCase();
  for (final keyword in keywords) {
    if (textLower.contains(keyword)) {
      return keyword;
    }
  }
  return 'Nieznany sklep';
}