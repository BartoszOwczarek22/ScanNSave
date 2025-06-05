import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_n_save/models/receipt.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; 


  Future<void> sendUserToken() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final String token = user.uid; // Pobierz token użytkownika
    final String name = user.email ?? "błąd"; // Pobierz email użytkownika

    return http.post(
      Uri.parse('$baseUrl/user/add'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': token, 'name': name}),
    ).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Błąd przy wysyłaniu tokenu użytkownika: ${response.statusCode}');
      }
    });
  }
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
    
    // Przekształć dane do formatu oczekiwanego przez aplikację
    List<Map<String, dynamic>> transformedParagons = [];
    
    for (var paragon in data['paragons']) {
      Map<String, dynamic> transformedParagon = {
        'id': paragon['id'],
        'storeName': paragon['shop_name'], // Zmapuj shop_name na storeName
        'store_name': paragon['shop_name'], // Zachowaj też oryginalną nazwę
        'date': paragon['date'],
        'purchase_date': paragon['date'], // Dodaj alternatywną nazwę
        'total': paragon['sum_price'], // Zmapuj sum_price na total
        'total_amount': paragon['sum_price'], // Dodaj alternatywną nazwę
        'price': paragon['sum_price'], // Dodaj trzecią alternatywę
        'location': paragon['location'],
        'create_date': paragon['create_date'],
        'items': [], // Przekształć receipt_indekses na items
      };
      
      // Przekształć receipt_indekses na items
      if (paragon['receipt_indekses'] != null && paragon['receipt_indekses'] is List) {
        List<Map<String, dynamic>> items = [];
        for (var indeks in paragon['receipt_indekses']) {
          items.add({
            'name': indeks['indeks'], // nazwa produktu
            'price': indeks['price'], // cena
            'quantity': indeks['quantity'] ?? 1, // ilość (domyślnie 1)
          });
        }
        transformedParagon['items'] = items;
      }
      
      transformedParagons.add(transformedParagon);
    }
    
    // Backend zwraca strukturę z paginacją
    return {
      'items': transformedParagons, // Użyj przekształconych danych
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
    
    // Przekształć dane tak samo jak w getParagons
    List<Map<String, dynamic>> transformedParagons = [];
    
    for (var paragon in data) {
      Map<String, dynamic> transformedParagon = {
        'id': paragon['id'],
        'storeName': paragon['shop_name'],
        'store_name': paragon['shop_name'],
        'date': paragon['date'],
        'purchase_date': paragon['date'],
        'total': paragon['sum_price'],
        'total_amount': paragon['sum_price'],
        'price': paragon['sum_price'],
        'location': paragon['location'],
        'create_date': paragon['create_date'],
        'items': [],
      };
      
      // Przekształć receipt_indekses na items
      if (paragon['receipt_indekses'] != null && paragon['receipt_indekses'] is List) {
        List<Map<String, dynamic>> items = [];
        for (var indeks in paragon['receipt_indekses']) {
          items.add({
            'name': indeks['indeks'],
            'price': indeks['price'],
            'quantity': indeks['quantity'] ?? 1,
          });
        }
        transformedParagon['items'] = items;
      }
      
      transformedParagons.add(transformedParagon);
    }
    
    return transformedParagons;
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