import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_n_save/models/receipt.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.162:8000'; 

  // Metoda wysyłająca obiekt Receipt do backendu
  Future<void> sendReceiptToServer(Receipt receipt) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    // Utwórz Receipt z userId
    final receiptWithUserId = Receipt(
      storeName: receipt.storeName,
      date: receipt.date,
      items: receipt.items,
      userId: user.uid,
    );

    String jsonBody = jsonEncode(receiptWithUserId.toJson());

    final response = await http.post(
      Uri.parse('$baseUrl/receipt/save'), // Zmieniony endpoint
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
  // Pobierz aktualnego użytkownika Firebase
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Użytkownik nie jest zalogowany');
  }
  
  // Buduj URL z wymaganym user_id
  String url = '$baseUrl/paragon/list?user_id=${user.uid}&page=$page&page_size=$pageSize';
  
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
    
    // Backend zwraca strukturę z paginacją
    return {
      'items': data['paragons'],
      'total_pages': data['total_pages'],
      'current_page': data['page'],
      'total_items': data['total_count'],
      'page_size': data['page_size'],
    };
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
  // Pobierz aktualnego użytkownika Firebase
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Użytkownik nie jest zalogowany');
  }

  final url = '$baseUrl/paragon/date-range/?user_id=${user.uid}&start_date=$startDate&end_date=$endDate';

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
  // Pobierz aktualnego użytkownika Firebase
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Użytkownik nie jest zalogowany');
  }

  final response = await http.get(
    Uri.parse('$baseUrl/paragon/$paragonId?user_id=${user.uid}'),
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

  Future<List<Map<String, dynamic>>> getExpensesByCategory({required String userId, required String startDate, required String endDate,}) async {

    final url = '$baseUrl/api/stats/categories'
      '?user_id=$userId&start_date=$startDate&end_date=$endDate';

    final response = await http.get(Uri.parse(url), headers: {'Content-Type' : 'application/json'});
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    } else {
      print('Błąd: status ${response.statusCode}, body: ${response.body}');
      throw Exception("Błąd: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> getExpensesByShop({required String userId, required String startDate, required String endDate,}) async {

    final url = '$baseUrl/api/stats/shops'
      '?user_id=$userId&start_date=$startDate&end_date=$endDate';

    final response = await http.get(Uri.parse(url), headers: {'Content-Type' : 'application/json'});
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('Błąd: status ${response.statusCode}, body: ${response.body}');
      throw Exception("Błąd: ${response.body}");
    }
  }
}