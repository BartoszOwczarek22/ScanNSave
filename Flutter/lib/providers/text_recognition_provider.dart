import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scan_n_save/models/receipt.dart';
import 'package:scan_n_save/services/receipt_parsing_service.dart';

final textRecognitionProvider = FutureProvider.family<Receipt, String>((
  ref,
  imagePath,
) async {
  return parseTextFromImage(imagePath);
});


