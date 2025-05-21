import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/models/receipt.dart';
import 'package:scan_n_save/providers/text_recognition_provider.dart';
import 'package:scan_n_save/api_service.dart';

class ReceiptDetailsPage extends ConsumerWidget {
  Receipt? receipt;
  String? recieptImagePath;

  ReceiptDetailsPage({super.key, required this.receipt})
    : recieptImagePath = null;
  ReceiptDetailsPage.fromImage({
    super.key,
    required String this.recieptImagePath,
  }) : receipt = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (receipt != null) {
      return buildReceiptView(receipt!);
    }

    final receiptScanning = ref.watch(
      textRecognitionProvider(recieptImagePath!),
    );

    return receiptScanning.when(
      data: (data) {
        // Parse the receipt data here
        // For example, you can create a Receipt object from the scanned text
        // receipt = parseReceipt(data);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Szczegóły paragonu'),
            actions: [
              TextButton(
                child: const Text('Zapisz'),
                onPressed: () {
                  ApiService apiService = ApiService();
                  apiService.sendReceiptToServer(data);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: buildReceiptView(data),
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Column(
          //     children: [
          //       Text(
          //         data.blocks[0].text,
          //         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          //       ),
          //       const SizedBox(height: 16),
          //       Text(
          //         data.blocks[1].text,
          //         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          //       ),
          //     ],
          //   )
          // ),
        );
      },
      error:
          (error, stackTrace) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: 
                [
                  Text('${error.toString()}'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Wróć'),
                  ),
                ]
              )
            )
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget buildReceiptView(Receipt receipt) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Sklep: ${receipt.storeName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Data: ${receipt.date}',
            style: const TextStyle(color: Colors.grey),
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
                  subtitle: Text('Ilość: ${item.quantity} x ${item.price.toStringAsFixed(2)} zł'),
                  trailing: Text('${(item.quantity * item.price).toStringAsFixed(2)} zł'),
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
}
