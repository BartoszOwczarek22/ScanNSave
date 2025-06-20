import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/models/receipt.dart';
import 'package:scan_n_save/providers/receipt_details_provider.dart';
import 'package:scan_n_save/providers/text_recognition_provider.dart';
import 'package:scan_n_save/api_service.dart';

class ReceiptScanningPage extends ConsumerWidget {
  String? recieptImagePath;

  ReceiptScanningPage({super.key, required String this.recieptImagePath});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(textRecognitionProvider(recieptImagePath!));

    return receiptAsync.when(
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (e, _) => Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nie znaleziono paragonu.'),
                    SizedBox(height: 20),
                    Text(
                      "Upewnij się, że oświetlenie jest dobre, na zdjęciu jest cały paragon oraz zdjęcie robisz od góry.",
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Wróć'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      data: (receipt) {
        // Ustaw domyślne wartości jeśli są puste lub null
        Receipt defaultReceipt = receipt.copyWith(
          storeName: receipt.storeName?.isEmpty != false ? 'Biedronka' : receipt.storeName,
          date: receipt.date?.isEmpty != false ? _getCurrentDate() : receipt.date,
        );
        
        return ProviderScope(
          overrides: [
            receiptProvider.overrideWith((ref) => ReceiptNotifier(defaultReceipt)),
          ],
          child: ReceiptDetailsPage(),
        );
      },
    );
  }
  
  String _getCurrentDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}

class ReceiptDetailsPage extends ConsumerWidget {
  String? recieptImagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły paragonu'),
        actions: [
          TextButton(
            child: const Text('Zapisz'),
            onPressed: () {
              ApiService apiService = ApiService();
              apiService.sendReceiptToServer(receipt);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: buildReceiptView(receipt, context, ref),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Suma:', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '${receipt.total.toStringAsFixed(2)} zł',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Dodaj produkt'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  showAddItemDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReceiptView(
    Receipt receipt,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'Sklep: ${receipt.storeName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Data: ${receipt.date}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(width: 5),
              IconButton(
                onPressed: () {
                  showEditReceiptDialog(
                    context,
                    ref,
                    receipt.storeName,
                    receipt.date ?? "brak",
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Edytuj produkt',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: receipt.items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = receipt.items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    'Ilość: ${item.quantity} x ${item.price.toStringAsFixed(2)} zł',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(item.quantity * item.price).toStringAsFixed(2)} zł',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edytuj produkt',
                        onPressed: () {
                          showEditItemDialog(context, ref, item, index);
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void showEditReceiptDialog(
    BuildContext context,
    WidgetRef ref,
    String storeName,
    String date,
  ) async {
    // Pobierz listę dostępnych sklepów
    final apiService = ApiService();
    List<String> availableShops = [];
    
    try {
      availableShops = await apiService.getAvailableShops();
    } catch (e) {
      print('Błąd przy pobieraniu sklepów: $e');
      // Użyj domyślnej listy w przypadku błędu
      availableShops = [
        'Biedronka',
        'Żabka', 
        'Lidl',
        'Kaufland',
        'Carrefour',
        'Tesco',
        'Auchan',
        'Netto',
        'Intermarché',
        'Stokrotka'
      ];
    }

    String selectedShop = availableShops.contains(storeName) ? storeName : availableShops.first;
    DateTime? pickedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Edytuj paragon"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown dla wyboru sklepu
              const Text('Sklep:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedShop,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: availableShops.map((String shop) {
                      return DropdownMenuItem<String>(
                        value: shop,
                        child: Text(shop),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedShop = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Button do wyboru daty
              const Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        pickedDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    pickedDate != null 
                      ? "${pickedDate!.day.toString().padLeft(2, '0')}-${pickedDate!.month.toString().padLeft(2, '0')}-${pickedDate!.year}"
                      : "Wybierz datę (aktualna: $date)",
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            ElevatedButton(
              onPressed: () {
                // Aktualizuj nazwę sklepu
                ref.read(receiptProvider.notifier).udateStoreName(selectedShop);
                
                // Aktualizuj datę jeśli została wybrana
                if (pickedDate != null) {
                  ref.read(receiptProvider.notifier).updateDate(
                    "${pickedDate!.year}-${pickedDate!.month.toString().padLeft(2, '0')}-${pickedDate!.day.toString().padLeft(2, '0')}",
                  );
                }
                
                Navigator.of(context).pop();
              },
              child: const Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }

  void showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Dodaj produkt"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nazwa produktu",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Cena (zł)"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: "Ilość"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Anuluj"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final price =
                      double.tryParse(
                        priceController.text.replaceAll(',', '.'),
                      ) ??
                      0.0;
                  final quantity =
                      double.tryParse(
                        quantityController.text.replaceAll(',', '.'),
                      ) ??
                      1.0;

                  if (name.isNotEmpty && price > 0 && quantity > 0) {
                    ref
                        .read(receiptProvider.notifier)
                        .addItem(
                          ReceiptItem(
                            name: name,
                            price: price,
                            quantity: quantity,
                          ),
                        );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Dodaj"),
              ),
            ],
          ),
    );
  }

  void showEditItemDialog(
    BuildContext context,
    WidgetRef ref,
    ReceiptItem item,
    int index,
  ) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edytuj produkt"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nazwa produktu",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: "Cena za sztukę (zł)",
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: "Ilość"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref
                      .read(receiptProvider.notifier)
                      .removeItem(index);
                  Navigator.of(context).pop();
                },
                child: Text("Usuń", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Anuluj"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final price =
                      double.tryParse(
                        priceController.text.replaceAll(',', '.'),
                      ) ??
                      0.0;
                  final quantity =
                      double.tryParse(
                        quantityController.text.replaceAll(',', '.'),
                      ) ??
                      1.0;

                  if (name.isNotEmpty && price > 0 && quantity > 0) {
                    ref
                        .read(receiptProvider.notifier)
                        .updateItem(
                          index,
                          item.copyWith(
                            name: name,
                            price: price,
                            quantity: quantity,
                          ),
                        );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Zapisz"),
              ),
            ],
          ),
    );
  }
}