import 'package:flutter/material.dart';

class ReceiptHistoryPage extends StatefulWidget {
  const ReceiptHistoryPage({super.key});

  @override
  State<ReceiptHistoryPage> createState() => _ReceiptHistoryPageState();
}

class _ReceiptHistoryPageState extends State<ReceiptHistoryPage> {
  final List<Map<String, String>> allReceipts = [
    {'store': 'Biedronka', 'date': '01.01.2000', 'price': '21,37 zł'},
    {'store': 'Lidl', 'date': '01.01.2000', 'price': '14,10 zł'},
    {'store': 'Żabka', 'date': '01.01.2000', 'price': '23,45 zł'},
    {'store': 'Carrefour', 'date': '01.01.2000', 'price': '23,45 zł'},
    {'store': 'Biedronka', 'date': '12.10.2024', 'price': '435,45 zł'},
  ];

  String? startDate;
  String? endDate;

  List<Map<String, String>> get filteredReceipts {
    if (startDate == null || endDate == null) return allReceipts;

    DateTime start = DateTime.parse(startDate!);
    DateTime end = DateTime.parse(endDate!);

    return allReceipts.where((r) {
      final receiptDate = DateTime.parse(r['date']!.split('.').reversed.join());
      return receiptDate.isAfter(start.subtract(const Duration(days: 1))) &&
          receiptDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> pickDate({required bool isStart}) async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      setState(() {
        if (isStart) {
          startDate = picked.toIso8601String().split('T').first;
        } else {
          endDate = picked.toIso8601String().split('T').first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia zakupów'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(isStart: true),
                    child: Text(startDate != null ? 'Od: $startDate' : 'Wybierz datę od'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(isStart: false),
                    child: Text(endDate != null ? 'Do: $endDate' : 'Wybierz datę do'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredReceipts.length,
              itemBuilder: (context, index) {
                final receipt = filteredReceipts[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(receipt['store']!),
                    subtitle: Text(formatDate(receipt['date']!)),
                    trailing: Text(receipt['price']!,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  String formatDate(String date) {
    // date in format yyyy-MM-dd or dd.MM.yyyy
    if (date.contains('-')) {
      final parts = date.split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    }
    return date;
  }
}
