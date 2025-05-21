import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_n_save/models/receipt.dart';

void sendReceiptToServer(Receipt reciept) async {

  // Serializacja do JSON
  String jsonBody = jsonEncode(reciept.toJson());

  // Wysłanie POST
  final response = await http.post(
    Uri.parse('http://10.0.2.2/paragon'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonBody,
  );

  if (response.statusCode == 200) {
    print('Sukces! Odpowiedź: ${response.body}');
  } else {
    print('Błąd: ${response.statusCode}');
  }
}
