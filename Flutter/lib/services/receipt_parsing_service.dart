import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scan_n_save/models/receipt.dart';
import 'package:dart_levenshtein/dart_levenshtein.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceiptItemPositioned extends ReceiptItem {
  final TextLine line;

  ReceiptItemPositioned({
    required String name,
    required double quantity,
    required double price,
    required this.line,
  }) : super(name: name, quantity: quantity, price: price);
}

class ProductParams {
  final TextLine line;
  final double quantity;
  final double price;

  ProductParams({
    required TextLine this.line,
    required double this.quantity,
    required double this.price,
  });
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
  print("detecting top");
  (top, left, right) = detectTop(recognizedText);
  print("top detected");
  print("detecting bottom");
  bottom = await detectBottom(recognizedText);
  print("bottom detected");

  final itemsPos = <ReceiptItemPositioned>[];
  print("detecting store name");
  String storeName = detectStoreName(recognizedText.text);
  print("store name detected");
  print("detecting date");
  String? date = detectDate(recognizedText.text);
  print("date detected");

  print("parsing items");

  List<ProductParams> productParams = [];
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    if (recognizedText.blocks[i].cornerPoints[3].y > top &&
        recognizedText.blocks[i].cornerPoints[0].y < bottom) {
      for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
        if (recognizedText.blocks[i].lines[j].text.length > 1) {
          if (recognizedText.blocks[i].lines[j].cornerPoints[0].x < left) {
            if (recognizedText.blocks[i].lines[j].cornerPoints[1].x < right) {
              if (!recognizedText.blocks[i].lines[j].text.contains(":") &&
                  !recognizedText.blocks[i].lines[j].text.contains("PARAGON") &&
                  !recognizedText.blocks[i].lines[j].text.contains("SPRZE") &&
                  !recognizedText.blocks[i].lines[j].text.contains("PTU") &&
                  !recognizedText.blocks[i].lines[j].text.contains("SUMA") &&
                  !recognizedText.blocks[i].lines[j].text.contains("**") &&
                  !recognizedText.blocks[i].lines[j].text.contains("%")) {
                itemsPos.add(
                  ReceiptItemPositioned(
                    line: recognizedText.blocks[i].lines[j],
                    name: recognizedText.blocks[i].lines[j].text,
                    quantity: 1,
                    price: 0,
                  ),
                );
              }
            }
            //} else {
            //throw Exception('Jakiś dziwny paragon.');
            //}
          } else if (recognizedText.blocks[i].lines[j].cornerPoints[1].x >
              right) {
            productParams.add(
              parsePriceQuantity(recognizedText.blocks[i].lines[j]),
            );
            // int smallestDif = 10000;
            // int index = -1;
            // for (int k = 0; k < itemsPos.length; k++) {
            //   int dif =
            //       (recognizedText.blocks[i].lines[j].cornerPoints[0].y -
            //               itemsPos[k].line.cornerPoints[1].y)
            //           .abs();
            //   if (dif < smallestDif) {
            //     smallestDif = dif;
            //     index = k;
            //   }
            // }
            // if (index != -1) {
            //   final (
            //     double quantity,
            //     double price,
            //     productType type,
            //   ) = parsePriceQuantity(recognizedText.blocks[i].lines[j]);
            //   itemsPos[index].price = price;
            //   itemsPos[index].quantity = quantity;
            //   itemsPos[index].type = type;
            // }
          }
        }
      }
    }
  }
  itemsPos.sort(
    (a, b) => a.line.cornerPoints[0].y.compareTo(b.line.cornerPoints[0].y),
  );
  productParams.sort(
    (a, b) => a.line.cornerPoints[0].y.compareTo(b.line.cornerPoints[0].y),
  );

  for (int i = 0; i < itemsPos.length; i++) {
    final paramsId = findClosestProductParams(itemsPos[i].line, productParams);
    if (paramsId != -1) {
      if (productParams[paramsId].price < 0 && i > 0) {
        if (itemsPos[i - 1].quantity > 0) {
          itemsPos[i - 1].price =
              itemsPos[i - 1].price -
              (productParams[paramsId].price * -1.0) / itemsPos[i - 1].quantity;
          itemsPos.removeAt(i);
          i--;
          continue;
        }
      }
      itemsPos[i].quantity = productParams[paramsId].quantity;
      itemsPos[i].price = productParams[paramsId].price;
    }
  }
  final User? user = FirebaseAuth.instance.currentUser;
  print("items parsed");
  return Receipt(
    storeName: storeName,
    date: date,
    items: itemsPos.cast<ReceiptItem>(),
    userId: user?.uid ?? '',
  );
}

int findClosestProductParams(TextLine line, List<ProductParams> pro) {
  int smallestDiff = 1000000;
  int smallestIndex = -1;
  for (int i = 0; i < pro.length; i++) {
    var dif = verDiffBeetLines(line, pro[i].line);
    if (dif < smallestDiff) {
      smallestIndex = i;
      smallestDiff = dif;
    }
  }
  return smallestIndex;
}

//oblicza różnicę wysokości dwóch lini
int verDiffBeetLines(TextLine line1, TextLine line2) {
  return (line1.cornerPoints[1].y - line2.cornerPoints[0].y).abs();
}

ProductParams parsePriceQuantity(TextLine textLine) {
  var text = textLine.text;
  text = text.replaceAll(' ', '');
  String wynik = text.replaceAllMapped(RegExp(r'[a-zA-Z]+'), (match) {
    String found = match.group(0)!;
    if (found == 'x' || found == 'szt') {
      return found;
    }
    return ''; // usuń
  });
  text = wynik;
  text = text.replaceAll(',', '.');
  var parts = text.split('x');
  if (parts.length == 1) {
    parts = text.split('szt');
    if (parts.length == 1) {
      if (text.contains('-')) {
        RegExp regex = RegExp(r'-[\d]+.\d\d');
        Match? match = regex.firstMatch(text);
        String reduceString = match?.group(0) ?? '';
        double? reduce = double.tryParse(reduceString);
        if (reduce != null) {
          if (reduce < 0) {
            return ProductParams(
              line: textLine,
              quantity: 1.0,
              price: reduce,
            );
          }
        }
      }
    }
  }

  if (parts.length == 2) {
    for (int i = 0; i < parts.length; i++) {
      parts[i] = parts[i].replaceAll(RegExp(r'[a-zA-Z]+'), '');
    }
    RegExp regexQuantity = RegExp(r'(\d+.\d+)|\d+');
    Match? matchQuantity = regexQuantity.firstMatch(parts[0]);
    parts[0] = matchQuantity?.group(0) ?? '';


    final quantity = double.tryParse(parts[0].trim().replaceAll(',', '.'));
    //final parts2 = parts[1].split(' ');
    var secondPart = parts[1].replaceAll(',', '.');
    RegExp regex = RegExp(r'\d+\.\d{2}');
    Match? match = regex.firstMatch(secondPart);
    String priceString = match?.group(0) ?? '';

    final price = double.tryParse(priceString);
    if (quantity != null && price != null) {
      if (quantity % 1 == 0) {
        return ProductParams(
          line: textLine,
          quantity: quantity,
          price: price,
        );
      } else {
        return ProductParams(
          line: textLine,
          quantity: quantity,
          price: price,
        );
      }
    }
  }
  return ProductParams(
    line: textLine,
    quantity: 0.0,
    price: 0.0,
  );
}

Future<bool> isSimilar(String a, String b, {int maxDistance = 2}) async {
  return await a.toLowerCase().levenshteinDistance(b.toLowerCase()) <=
      maxDistance;
}

Future<bool> ContainsLeven(
  String ocrText,
  List<String> keywords, {
  int maxDistance = 2,
}) async {
  final wordsInText = ocrText.split(RegExp(r'\s+'));

  for (final keyword in keywords) {
    for (final word in wordsInText) {
      final distance = await isSimilar(word, keyword, maxDistance: maxDistance);
      if (distance) {
        return true;
      }
    }
  }
  return false;
}

(int, int, int) detectTop(RecognizedText recognizedText) {
  bool parFound = false;
  int top = -1;
  int left = -1;
  int right = -1;
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
      if (recognizedText.blocks[i].lines[j].text
          .toUpperCase()
          .replaceAll(' ', '')
          .contains('PARAGON')) {
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
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
      if (recognizedText.blocks[i].lines[j].text
          .toUpperCase()
          .replaceAll(' ', '')
          .contains("FISKALNY")) {
        right = recognizedText.blocks[i].lines[j].cornerPoints[2].x;
        return (top, left, right);
      }
    }
  }

  throw Exception('Nie znaleziono paragonu.');
}

Future<int> detectBottom(RecognizedText recognizedText) async {
  int bottom = 10000;
  for (int i = 0; i < recognizedText.blocks.length; i++) {
    for (int j = 0; j < recognizedText.blocks[i].lines.length; j++) {
      if (recognizedText.blocks[i].lines[j].text.toUpperCase().contains("SP")) {
        if (recognizedText.blocks[i].lines[j].cornerPoints[0].y < bottom) {
          if (await ContainsLeven(
            recognizedText.blocks[i].lines[j].text.toUpperCase(),
            ["SPRZED"],
            maxDistance: 2,
          )) {
            bottom = recognizedText.blocks[i].lines[j].cornerPoints[0].y;
            //i = recognizedText.blocks.length;
            //return bottom;
          }
        }
      }
    }
  }
  if (bottom != -1) {
    return bottom;
  }
  throw Exception('Nie znaleziono paragonu.');
}

String detectStoreName(String ocrText) {
  final keywords = [
    'biedronka',
    'lidl',
    'carrefour',
    'zabka',
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

String? detectDate(String ocrText) {
  final textPre = ocrText.replaceAll(' ', '');
  RegExp regex = RegExp(r'2\d{3}-[01][0-9]-[0-3][0-9]');
  Iterable<RegExpMatch> matches = regex.allMatches(textPre);

  if (matches.isNotEmpty) {
    return matches.first.group(0);
  } else {
    return null;
  }
}
