import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_n_save/models/receipt.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.20.249:8000'; 

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

  // Pobieranie listy paragonów dla aktualnie zalogowanego użytkownika
  Future<Map<String, dynamic>> getParagons({
    int page = 1,
    int pageSize = 10,
    String? storeName,
  }) async {
    // Pobieramy ID aktualnie zalogowanego użytkownika
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }
    
    String userId = currentUser.uid;
    String url = '$baseUrl/paragon/list?user_id=$userId&page=$page&page_size=$pageSize';
    
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
      
      // Zwracamy dane w standardowym formacie
      return {
        'items': data['paragons'] ?? [],
        'total_pages': data['total_pages'] ?? 1,
        'current_page': data['page'] ?? page,
        'total_items': data['total_count'] ?? 0,
        'page_size': data['page_size'] ?? pageSize,
      };
    } else {
      print('Błąd przy pobieraniu paragonów. Status: ${response.statusCode}');
      print('Treść odpowiedzi: ${response.body}');
      throw Exception('Błąd przy pobieraniu paragonów');
    }
  }

  // Pobieranie konkretnego paragonu po ID dla aktualnego użytkownika
  Future<Map<String, dynamic>> getParagonById(int paragonId) async {
    // Pobieramy ID aktualnie zalogowanego użytkownika
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }
    
    String userId = currentUser.uid;
    
    final response = await http.get(
      Uri.parse('$baseUrl/paragon/$paragonId?user_id=$userId'),
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

  // Pobieranie paragonów w zakresie dat dla aktualnego użytkownika
  Future<List<Map<String, dynamic>>> getParagonsInDateRange({
    required String startDate,
    required String endDate,
  }) async {
    // Pobieramy ID aktualnie zalogowanego użytkownika
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }
    
    String userId = currentUser.uid;
    final url = '$baseUrl/paragon/date-range/?user_id=$userId&start_date=$startDate&end_date=$endDate';

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

  // Dodatkowa metoda do pobierania wszystkich paragonów użytkownika bez paginacji
  Future<List<Map<String, dynamic>>> getAllUserParagons() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }
    
    String userId = currentUser.uid;
    List<Map<String, dynamic>> allParagons = [];
    int page = 1;
    int pageSize = 100;
    bool hasMorePages = true;
    
    while (hasMorePages) {
      try {
        final response = await getParagons(
          page: page,
          pageSize: pageSize,
        );
        
        List<dynamic> paragons = response['items'] ?? [];
        allParagons.addAll(paragons.cast<Map<String, dynamic>>());
        
        int totalPages = response['total_pages'] ?? 1;
        hasMorePages = page < totalPages;
        page++;
        
      } catch (e) {
        print('Błąd przy pobieraniu strony $page: $e');
        break;
      }
    }
    
    return allParagons;
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory({
    required String startDate, 
    required String endDate,
  }) async {
    // Pobieramy ID aktualnie zalogowanego użytkownika
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }
    
    String userId = currentUser.uid;
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

  Future<List<Map<String, dynamic>>> getExpensesByShop({
    required String startDate, 
    required String endDate,
  }) async {
    // Pobieramy ID aktualnie zalogowanego użytkownika
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }
    
    String userId = currentUser.uid;
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