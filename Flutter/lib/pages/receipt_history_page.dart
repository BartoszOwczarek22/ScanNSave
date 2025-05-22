import 'package:flutter/material.dart';
import 'package:scan_n_save/pages/home_page.dart';
import 'package:scan_n_save/pages/camera_page.dart';

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

  DateTimeRange? selectedDateRange;
  String selectedSort = 'Data';
  bool ascending = false;

  List<Map<String, String>> get filteredReceipts {
    List<Map<String, String>> filtered = allReceipts;

    if (selectedDateRange != null) {
      filtered = filtered.where((r) {
        final receiptDate =
            DateTime.parse(r['date']!.split('.').reversed.join());
        return receiptDate.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            receiptDate.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    filtered.sort((a, b) {
      int cmp;
      switch (selectedSort) {
        case 'Cena':
          double parsePrice(String price) =>
              double.tryParse(price.replaceAll(',', '.').replaceAll(' zł', '')) ?? 0;
          cmp = parsePrice(a['price']!).compareTo(parsePrice(b['price']!));
          break;
        case 'Sklep':
          cmp = a['store']!.compareTo(b['store']!);
          break;
        case 'Data':
        default:
          final aDate = DateTime.parse(a['date']!.split('.').reversed.join());
          final bDate = DateTime.parse(b['date']!.split('.').reversed.join());
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
      });
    }
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    onPressed: pickDateRange,
                    label: Text(rangeText),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedSort,
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
                    subtitle: Text(formatDateString(receipt['date']!)),
                    trailing: Text(
                      receipt['price']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
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

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String formatDateString(String date) {
    if (date.contains('-')) {
      final parts = date.split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    }
    return date;
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPage(),
                    ),
                  );
              },
              child: const Text('Skanuj'),
            ),
          ],
        );
      },
    );
  }
}
