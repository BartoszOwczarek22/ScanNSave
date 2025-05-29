import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_n_save/models/receipt.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; 

  // Metoda wysyłająca obiekt Receipt do backendu
  Future<void> sendReceiptToServer(Receipt receipt) async {
    String jsonBody = jsonEncode(receipt.toJson());

    final response = await http.post(
      Uri.parse('$baseUrl/paragon/save-to-db'), 
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonBody,
    );

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode == 200) {
      print('Sukces! Odpowiedź backendu: ${response.body}');
    } else {
      print('Błąd przy wysyłaniu danych. Status: ${response.statusCode}');
      print('Treść odpowiedzi: ${response.body}');
      throw Exception('Błąd przy wysyłaniu paragonu');
    }
  }

  // Pobieranie listy paragonów z paginacją i filtrowaniem
  Future<Map<String, dynamic>> getParagons({
    int page = 1,
    int pageSize = 10,
    String? storeName,
  }) async {
    String url = '$baseUrl/paragon/list?page=$page&page_size=$pageSize';
    
    if (storeName != null && storeName.isNotEmpty) {
      url += '&store_name=${Uri.encodeComponent(storeName)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Jeśli odpowiedź ma strukturę z 'paragons'
      if (data is Map<String, dynamic> && data.containsKey('paragons')) {
        return {
          'items': data['paragons'],
          'total_pages': 1, // Domyślnie jedna strona jeśli brak informacji o paginacji
          'current_page': page,
          'total_items': (data['paragons'] as List).length,
        };
      }
      
      // Jeśli odpowiedź ma standardową strukturę paginacji
      return data;
    } else {
      print('Błąd przy pobieraniu paragonów. Status: ${response.statusCode}');
      print('Treść odpowiedzi: ${response.body}');
      throw Exception('Błąd przy pobieraniu paragonów');
    }
  }

  // Pobieranie paragonów w zakresie dat
  Future<List<Map<String, dynamic>>> getParagonsInDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final url = '$baseUrl/paragon/date-range/?start_date=$startDate&end_date=$endDate';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('Błąd przy pobieraniu paragonów w zakresie dat. Status: ${response.statusCode}');
      print('Treść odpowiedzi: ${response.body}');
      throw Exception('Błąd przy pobieraniu paragonów w zakresie dat');
    }
  }

  // Pobieranie konkretnego paragonu po ID
  Future<Map<String, dynamic>> getParagonById(int paragonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/paragon/$paragonId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Paragon nie został znaleziony');
    } else {
      print('Błąd przy pobieraniu paragonu. Status: ${response.statusCode}');
      print('Treść odpowiedzi: ${response.body}');
      throw Exception('Błąd przy pobieraniu paragonu');
    }
  }
}