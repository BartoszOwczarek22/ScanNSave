import 'package:flutter/material.dart';

class ReceiptHistoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> receipt;
  final VoidCallback? onDelete;

  const ReceiptHistoryDetailPage({
    super.key,
    required this.receipt,
    this.onDelete,
  });

  String get storeName {
    return receipt['storeName'] ??
        receipt['store_name'] ??
        receipt['store'] ??
        'Nieznany sklep';
  }

  String get formattedDate {
    final rawDate = receipt['date'] ?? receipt['purchase_date'] ?? receipt['created_at'];
    if (rawDate is String && rawDate.contains('-')) {
      final parts = rawDate.split('T').first.split('-');
      if (parts.length == 3) {
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    }
    return 'Brak daty';
  }

  String get formattedTotal {
    final raw = receipt['total'] ?? receipt['total_amount'] ?? receipt['price'];
    final parsed = raw is num
        ? raw.toDouble()
        : double.tryParse(raw.toString().replaceAll(',', '.'));

    return parsed != null ? '${parsed.toStringAsFixed(2).replaceAll('.', ',')} zł' : '0,00 zł';
  }

  List<Widget> buildItemWidgets() {
    final items = receipt['items'];
    if (items is! List || items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Brak produktów',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    return [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Produkty:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      ...items.map((item) {
        if (item is Map<String, dynamic>) {
          final name = item['name'] ?? item['indeks'] ?? 'Produkt';
          final quantity = item['quantity']?.toString() ?? '';
          final priceRaw = item['price'];
          final price = priceRaw != null
              ? '${priceRaw.toString().replaceAll('.', ',')} zł'
              : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $name'
              '${quantity.isNotEmpty && quantity != '0' ? ' ($quantity szt.)' : ''}'
              '${price.isNotEmpty ? ' - $price' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }
        return Text('• ${item.toString()}');
      }).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły paragonu'),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Usuń paragon',
              onPressed: onDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sklep + Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    storeName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kwota
            Text(
              formattedTotal,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const Divider(height: 32),

            // Lista produktów
            ...buildItemWidgets(),

            const SizedBox(height: 24),

            // Obraz
            GestureDetector(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImagePage(imagePath: 'assets/icons/par7.jpg'),
      ),
    );
  },
              child: Hero(
                tag: 'receiptImage',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/par7.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class FullscreenImagePage extends StatelessWidget {
  final String imagePath;

  const FullscreenImagePage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: 'receiptImage',
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
    );
  }
}
