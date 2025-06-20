import 'package:flutter/material.dart';
import 'package:scan_n_save/pages/home_page.dart';
import 'package:scan_n_save/pages/camera_page.dart';
import 'package:scan_n_save/api_service.dart';

class ReceiptHistoryPage extends StatefulWidget {
  const ReceiptHistoryPage({super.key});

  @override
  State<ReceiptHistoryPage> createState() => _ReceiptHistoryPageState();
}

class _ReceiptHistoryPageState extends State<ReceiptHistoryPage> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> allReceipts = [];
  bool isLoading = true;
  String? errorMessage;
  
  DateTimeRange? selectedDateRange;
  String selectedSort = 'Data';
  bool ascending = false;
  
  // Parametry paginacji
  int currentPage = 1;
  int pageSize = 20;
  int totalPages = 1;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    loadReceipts();
  }

  Future<void> loadReceipts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (selectedDateRange != null) {
        // Pobierz paragony w zakresie dat
        await loadReceiptsByDateRange();
      } else {
        // Pobierz wszystkie paragony z paginacją
        await loadAllReceipts();
      }
    } catch (e) {
      if(!mounted) return;
      setState(() {
        errorMessage = 'Błąd przy pobieraniu danych: $e';
        isLoading = false;
      });
    }
  }

  Future<void> loadAllReceipts() async {
    try {
      final response = await _apiService.getParagons(
        page: currentPage,
        pageSize: pageSize,
      );
      
      setState(() {
        if (currentPage == 1) {
          allReceipts = List<Map<String, dynamic>>.from(response['items']);
        } else {
          allReceipts.addAll(List<Map<String, dynamic>>.from(response['items']));
        }
        
        totalPages = response['total_pages'];
        hasMoreData = currentPage < totalPages;
        isLoading = false;
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> loadReceiptsByDateRange() async {
    try {
      final startDate = formatDateForApi(selectedDateRange!.start);
      final endDate = formatDateForApi(selectedDateRange!.end);
      
      final receipts = await _apiService.getParagonsInDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      
      setState(() {
        allReceipts = receipts;
        hasMoreData = false; // Brak paginacji dla zakresu dat
        isLoading = false;
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> loadMoreReceipts() async {
    if (!hasMoreData || isLoading) return;
    
    setState(() {
      currentPage++;
    });
    
    await loadAllReceipts();
  }

  Future<void> refreshReceipts() async {
    setState(() {
      currentPage = 1;
      allReceipts.clear();
    });
    await loadReceipts();
  }

  List<Map<String, dynamic>> get filteredReceipts {
    List<Map<String, dynamic>> filtered = List.from(allReceipts);

    // Sortowanie
    filtered.sort((a, b) {
      int cmp;
      switch (selectedSort) {
        case 'Cena':
          double parsePrice(Map<String, dynamic> receipt) {
            final amount = receipt['total'] ?? receipt['total_amount'] ?? receipt['price'];
            if (amount is num) return amount.toDouble();
            if (amount is String) {
              return double.tryParse(amount.replaceAll(',', '.').replaceAll(' zł', '')) ?? 0;
            }
            return 0;
          }
          cmp = parsePrice(a).compareTo(parsePrice(b));
          break;
        case 'Sklep':
          cmp = _getStoreName(a).compareTo(_getStoreName(b));
          break;
        case 'Data':
        default:
          DateTime parseDate(Map<String, dynamic> receipt) {
            final date = receipt['date'] ?? receipt['purchase_date'] ?? receipt['created_at'];
            if (date is String) {
              if (date.contains('T')) {
                return DateTime.parse(date.split('T')[0]);
              } else if (date.contains('.')) {
                final parts = date.split('.');
                return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
              } else if (date.contains('-')) {
                return DateTime.parse(date.split('T')[0]);
              }
            }
            return DateTime.now();
          }
          
          final aDate = parseDate(a);
          final bDate = parseDate(b);
          cmp = aDate.compareTo(bDate);
          break;
      }
      return ascending ? cmp : -cmp;
    });

    return filtered;
  }

  Future<void> pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        currentPage = 1;
        allReceipts.clear();
      });
      await loadReceipts();
    }
  }

  void clearDateFilter() {
    setState(() {
      selectedDateRange = null;
      currentPage = 1;
      allReceipts.clear();
    });
    loadReceipts();
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = selectedDateRange == null
        ? 'Wybierz zakres dat'
        : '${formatDate(selectedDateRange!.start)} - ${formatDate(selectedDateRange!.end)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia zakupów'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshReceipts,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtry i sortowanie
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        onPressed: pickDateRange,
                        label: Text(rangeText),
                      ),
                    ),
                    if (selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: clearDateFilter,
                        tooltip: 'Wyczyść filtr dat',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedSort,
                        isExpanded: true,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSort = value;
                            });
                          }
                        },
                        items: ['Data', 'Cena', 'Sklep'].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text('Sortuj po $option'),
                          );
                        }).toList(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        ascending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          ascending = !ascending;
                        });
                      },
                      tooltip: ascending ? 'Rosnąco' : 'Malejąco',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista paragonów
          Expanded(
            child: _buildReceiptsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showScanReceiptDialog();
        },
        child: const Icon(Icons.add_a_photo),
        tooltip: 'Zeskanuj nowy paragon',
      ),
    );
  }

  Widget _buildReceiptsList() {
    if (isLoading && allReceipts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: refreshReceipts,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      );
    }

    if (allReceipts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Brak paragonów do wyświetlenia',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final receipts = filteredReceipts;
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isLoading && 
            hasMoreData && 
            selectedDateRange == null &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          loadMoreReceipts();
        }
        return true;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: receipts.length + (hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == receipts.length) {
            // Loading indicator na końcu listy
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final receipt = receipts[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(_getStoreName(receipt)),
              subtitle: Text(_formatReceiptDate(receipt)),
              trailing: Text(
                _formatPrice(receipt),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _showReceiptDetails(receipt),
            ),
          );
        },
      ),
    );
  }

  String _getStoreName(Map<String, dynamic> receipt) {
    return receipt['storeName']?.toString() ?? 
           receipt['store_name']?.toString() ?? 
           receipt['store']?.toString() ?? 
           'Nieznany sklep';
  }

  String _formatReceiptDate(Map<String, dynamic> receipt) {
    final date = receipt['date'] ?? receipt['purchase_date'] ?? receipt['created_at'];
    if (date == null) return 'Brak daty';
    
    if (date is String) {
      if (date.contains('T')) {
        // Format ISO (2024-01-01T00:00:00Z)
        final dateOnly = date.split('T')[0];
        final parts = dateOnly.split('-');
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      } else if (date.contains('.')) {
        // Format DD.MM.YYYY
        return date;
      } else if (date.contains('-')) {
        // Format YYYY-MM-DD
        final parts = date.split('-');
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    }
    
    return date.toString();
  }

  String _formatPrice(Map<String, dynamic> receipt) {
    final amount = receipt['total'] ?? receipt['total_amount'] ?? receipt['price'];
    if (amount == null) return '0,00 zł';
    
    if (amount is num) {
      return '${amount.toStringAsFixed(2).replaceAll('.', ',')} zł';
    }
    
    if (amount is String) {
      if (amount.contains('zł')) {
        return amount;
      }
      final parsed = double.tryParse(amount.replaceAll(',', '.'));
      if (parsed != null) {
        return '${parsed.toStringAsFixed(2).replaceAll('.', ',')} zł';
      }
    }
    
    return amount.toString();
  }

void _showReceiptDetails(Map<String, dynamic> receipt) {
  try {
    _debugReceiptStructure(receipt); // Debug
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_getStoreName(receipt)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data: ${_formatReceiptDate(receipt)}'),
                Text('Kwota: ${_formatPrice(receipt)}'),
                const SizedBox(height: 12),
                _buildItemsList(receipt),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    print('Błąd podczas wyświetlania szczegółów paragonu: $e');
    // Pokaż prosty komunikat o błędzie
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Błąd podczas wyświetlania szczegółów: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Widget _buildItemsList(Map<String, dynamic> receipt) {
  try {
    // Sprawdź czy items istnieje i jest listą
    final items = receipt['items'];
    
    if (items == null) {
      print('Items is null');
      return const Text(
        'Brak szczegółów produktów',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }
    
    if (items is! List) {
      print('Items is not a List, type: ${items.runtimeType}');
      return const Text(
        'Nieprawidłowy format danych produktów',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }
    
    if (items.isEmpty) {
      print('Items list is empty');
      return const Text(
        'Brak produktów w paragonie',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }
    
    print('Found ${items.length} items');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Produkty:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Użyj Column zamiast ListView dla małej liczby elementów
        if (items.length <= 10)
          ...items.asMap().entries.map((entry) {
            try {
              final index = entry.key;
              final item = entry.value;
              print('Processing item $index: $item');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildItemWidget(item, index),
              );
            } catch (e) {
              print('Error processing item ${entry.key}: $e');
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• Błąd odczytu produktu #${entry.key + 1}',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              );
            }
          }).toList()
        else
          // Dla dużej liczby produktów użyj Container z ograniczoną wysokością
          SizedBox(
            width: double.maxFinite,
            height: 250,
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.asMap().entries.map((entry) {
                    try {
                      final index = entry.key;
                      final item = entry.value;
                      print('Processing item $index: $item');
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildItemWidget(item, index),
                      );
                    } catch (e) {
                      print('Error processing item ${entry.key}: $e');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• Błąd odczytu produktu #${entry.key + 1}',
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      );
                    }
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  } catch (e) {
    print('Error in _buildItemsList: $e');
    return Text(
      'Błąd podczas ładowania listy produktów: $e',
      style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
    );
  }
}

Widget _buildItemWidget(dynamic item, int index) {
  try {
    String itemText = '• ';
    
    if (item is Map<String, dynamic>) {
      final name = item['name']?.toString() ?? 
                  item['indeks']?.toString() ?? 
                  'Nieznany produkt';
      
      itemText += name;
      
      // Dodaj ilość jeśli istnieje
      final quantity = item['quantity'];
      if (quantity != null && quantity.toString() != '0' && quantity.toString() != '') {
        itemText += ' (${quantity}szt.)';
      }
      
      // Dodaj cenę jeśli istnieje
      final price = item['price'];
      if (price != null && price.toString() != '0' && price.toString() != '') {
        String formattedPrice = price.toString().replaceAll('.', ',');
        if (!formattedPrice.contains('zł')) {
          formattedPrice += ' zł';
        }
        itemText += ' - $formattedPrice';
      }
    } else if (item is String) {
      itemText += item;
    } else {
      itemText += item.toString();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        itemText,
        style: const TextStyle(fontSize: 14),
      ),
    );
  } catch (e) {
    print('Error in _buildItemWidget for item $index: $e');
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '• Produkt #${index + 1} (błąd odczytu)',
        style: const TextStyle(color: Colors.orange, fontSize: 14),
      ),
    );
  }
}

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showScanReceiptDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Zeskanuj paragon'),
          content: const Text('Chciałbyś zeskanować nowy paragon?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraPage(),
                  ),
                ).then((_) {
                  // Odśwież listę po powrocie z kamery
                  refreshReceipts();
                });
              },
              child: const Text('Skanuj'),
            ),
          ],
        );
      },
    );
  }
}

void _debugReceiptStructure(Map<String, dynamic> receipt) {
  print('=== DEBUG: Receipt Structure ===');
  print('Keys: ${receipt.keys.toList()}');
  
  receipt.forEach((key, value) {
    print('$key: ${value.runtimeType} = $value');
    
    if (key == 'items' && value is List) {
      print('  Items count: ${value.length}');
      for (int i = 0; i < value.length && i < 3; i++) {
        print('  Item $i: ${value[i].runtimeType} = ${value[i]}');
        if (value[i] is Map) {
          print('    Item $i keys: ${(value[i] as Map).keys.toList()}');
        }
      }
    }
  });
  print('=== END DEBUG ===');
}