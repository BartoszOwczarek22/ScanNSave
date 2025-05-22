import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/models/receipt.dart';
import 'package:scan_n_save/providers/receipt_details_provider.dart';
import 'package:scan_n_save/providers/text_recognition_provider.dart';
import 'package:scan_n_save/api_service.dart';

class ReceiptScanningPage extends ConsumerWidget {
  String? recieptImagePath;

  ReceiptScanningPage({
    super.key,
    required String this.recieptImagePath,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(textRecognitionProvider(recieptImagePath!));

    return receiptAsync.when(
      loading: () => Scaffold(body:Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Nie znaleziono paragonu.'),
                SizedBox(height: 20),
                Text("Upewnij się, że oświetlenie jest dobre, na zdjęciu jest cały paragon oraz zdjęcie robisz od góry.",
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
          )
        ),
      ),
      data: (receipt) {
        return ProviderScope(
          overrides: [
            receiptProvider.overrideWith(
              (ref) => ReceiptNotifier(receipt),
            ),
          ],
          child: ReceiptDetailsPage(),
        );
      },
    );
  }
}


class ReceiptDetailsPage extends ConsumerWidget {
  //Receipt? receipt;
  String? recieptImagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider);
    final receiptNotifier = ref.watch(receiptProvider.notifier);

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
    );
  }

  Widget buildReceiptView(Receipt receipt, BuildContext context, WidgetRef ref) {
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
                  showEditReceiptDialog(context, ref, receipt.storeName, receipt.date ?? "brak");
                },
                icon: Icon(Icons.edit),
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
                  // subtitle: Text('Ilość: ${item.quantity} x ${item.price}'),
                  // trailing: Text('${(item.price)}'),
                  subtitle: Text(
                    'Ilość: ${item.quantity} x ${item.price.toStringAsFixed(2)} zł',
                  ),
                  trailing: Text(
                    '${(item.quantity * item.price).toStringAsFixed(2)} zł',
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Suma:', style: TextStyle(fontSize: 18)),
              Text(
                '${receipt.total.toStringAsFixed(2)} zł',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void showEditReceiptDialog(BuildContext context, WidgetRef ref, String storeName, String date) {
    TextEditingController storeNameInputControler = TextEditingController();
    storeNameInputControler.text = storeName;
    DateTime? pickedDate;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edytuj"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: storeNameInputControler,
                  decoration: const InputDecoration(
                    labelText: 'Sklep',
                    border: OutlineInputBorder(),
                ),),
                OutlinedButton(
                  onPressed: () async {
                    pickedDate = await showDatePicker(
                      lastDate: DateTime.now(),
                      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                      context: context
                      
                    );
                  },
                  child: Text("wybierz datę"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => {Navigator.of(context).pop()},
                child: Text("Anuluj"),
              ),
              TextButton(
                onPressed: () {
                  ref.read(receiptProvider.notifier).udateStoreName(storeNameInputControler.text);
                  if (pickedDate != null)
                  {
                    ref.read(receiptProvider.notifier).updateDate("${pickedDate!.year}-${pickedDate!.month}-${pickedDate!.day}");
                  }
                  Navigator.of(context).pop();
                },
                child: Text("Zapisz"),
              ),
            ],
          ),
    );
  }
}