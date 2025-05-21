import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_n_save/models/receipt.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; 

  Future<String> getHello() async {
    final response = await http.get(Uri.parse('$baseUrl/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message'];
    } else {
      throw Exception('Failed to load message');
    }
  }
  void sendReceiptToServer(Receipt reciept) async {

  // Serializacja do JSON
  String jsonBody = jsonEncode(reciept.toJson());

  // Wysłanie POST
  final response = await http.post(
    Uri.parse('$baseUrl/paragon/'),
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
}
