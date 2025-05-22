import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_n_save/models/receipt.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; 

  // Metoda wysyłająca obiekt Receipt do backendu
  Future<void> sendReceiptToServer(Receipt receipt) async {
    
    String jsonBody = jsonEncode(receipt.toJson());

    // Wysyłanie POST na endpoint backendu
    final response = await http.post(
      Uri.parse('$baseUrl/paragon/save'), 
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonBody,
    );

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    // Obsługa odpowiedzi
    if (response.statusCode == 200) {
      print('Sukces! Odpowiedź backendu: ${response.body}');
    } else {
      print('Błąd przy wysyłaniu danych. Status: ${response.statusCode}');
      print('Treść odpowiedzi: ${response.body}');
      
    }
  }
}
