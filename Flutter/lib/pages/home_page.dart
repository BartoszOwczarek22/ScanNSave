import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scan_n_save/auth/verifyPage.dart';
import 'package:scan_n_save/core/clip_shadow_path.dart';
import 'package:scan_n_save/core/notch_menu.dart';
import 'package:scan_n_save/pages/camera_page.dart';
import 'package:scan_n_save/settings_page.dart';
import 'package:scan_n_save/lists/shopping_lists_page.dart';
import 'package:scan_n_save/pages/recipt_history/receipt_history_page.dart';
import 'package:scan_n_save/stats/main_dashboard.dart';
import 'package:scan_n_save/stats/store_comparison.dart';
import 'package:scan_n_save/sharedprefsnotifier.dart';
import 'package:scan_n_save/api_service.dart';



final recentReceiptsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final api = ApiService();
  final response = await api.getParagons(page: 1, pageSize: 2);
  return List<Map<String, dynamic>>.from(response['items']);
});


// Sample data - just for MVP
final shoppingListsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {'id': 1, 'name': 'Lista zakupów niedziela', 'items': 12},
  {'id': 2, 'name': 'Impreza', 'items': 8},
]);

final savedAmountProvider = Provider<double>((ref) => 124.50);
double _actualMonthlySpending = 0.0;
bool _isLoadingSpending = true;

final comparisonDataProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {
    'item': 'Mleko 1L',
    'stores': [
      {'name': 'Żabka', 'price': '3.49 zł'},
      {'name': 'Biedronka', 'price': '3.29 zł'},
      {'name': 'Lidl', 'price': '3.79 zł'},
    ]
  },
  {
    'item': 'Jajka (12 szt.)',
    'stores': [
      {'name': 'Żabka', 'price': '4.99 zł'},
      {'name': 'Biedronka', 'price': '5.29 zł'},
      {'name': 'Lidl', 'price': '4.79 zł'},
    ]
  },
]);

class HomePage extends ConsumerStatefulWidget {
  HomePage({super.key}) {}

  @override
  ConsumerState<HomePage> createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser?.emailVerified == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailVerificationPage()),
        );
      }
      _loadMonthlySpending();
    });
  }


Future<void> _loadMonthlySpending() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final spending = await ApiService().getExpensesByMonth(user.uid);

    if (mounted) {
      setState(() {
        _actualMonthlySpending = spending;
        _isLoadingSpending = false;
      });
    }
  } catch (e) {
    print('Błąd przy pobieraniu miesięcznych wydatków: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    // Get data from providers
    final recentReceipts = ref.watch(recentReceiptsProvider);
    final shoppingLists = ref.watch(shoppingListsProvider);
    final savedAmount = ref.watch(savedAmountProvider);
    final comparisonData = ref.watch(comparisonDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset('assets/icons/logo.svg', colorFilter: ColorFilter.mode(Color.fromARGB(255, 99, 171, 243), BlendMode.srcIn),height: 30,),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                )
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Dashboard
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(
                    children: [
                      _buildStatCard(
                        'W tym miesiącu',
                        _isLoadingSpending ? '...' : '${_actualMonthlySpending.toStringAsFixed(2)} zł',
                        'Łączne wydatki',
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard('Zaoszczędzono', '${savedAmount.toStringAsFixed(2)} zł',
                          'Z porównywarką cen', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    'Ostatnie zakupy',
                    Icons.receipt,
                    recentReceipts.when(
                      data: (receipts){
                        if (receipts.isEmpty) {
                          return const Text(
                            'Brak ostatnich paragonów',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return Column(
                          children: receipts
                          .map((receipt) => _buildReceiptItem(receipt)).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(),),
                      error: (e, st) => Text("Błąd: $e", style: const TextStyle(color:Colors.red),)
                      ),
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReceiptHistoryPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    'Listy zakupów',
                    Icons.shopping_bag,
                    Column(
                      children: shoppingLists
                          .map((list) => _buildListItem(list))
                          .toList(),
                    ),
                    actionIcon: Icons.add,
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShoppingListsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    'Porównywarka cen',
                    Icons.store,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: comparisonData.map((item) => _buildComparisonItem(item)).toList(),
                    ),
                    onSeeAll: () {
                      // TODO: Pełna porównywarka
                    },
                  ),
                  //
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          NotchMenu(true, 5),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color valueColor) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Widget content, {
    VoidCallback? onSeeAll,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color.fromRGBO(99, 171, 243, 1.0), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: () { if (title == "Porównywarka cen"){Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => PriceComparisonScreen()), );} else if (title == "Ostatnie zakupy"){Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => ReceiptHistoryPage()), );} else {
                      Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => ShoppingListsPage()), );
                    }},
                    child: Row(
                      children: const [
                        Text('Sprawdź', style: TextStyle(color: Color.fromRGBO(99, 171, 243, 1.0))),
                        Icon(Icons.chevron_right, size: 16, color: Color.fromRGBO(99, 171, 243, 1.0)),
                      ],
                    ),
                  )
                else if (onAction != null && actionIcon != null)
                  TextButton(
                    onPressed: onAction,
                    child: Row(
                      children: [
                        Icon(actionIcon, size: 16, color: const Color.fromRGBO(99, 171, 243, 1.0)),
                        const SizedBox(width: 4),
                        const Text('Nowa lista', style: TextStyle(color: Color.fromRGBO(99, 171, 243, 1.0))),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptItem(Map<String, dynamic> receipt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                receipt['storeName']?.toString() ??
                receipt['store_name']?.toString() ??
                receipt['store']?.toString() ??
                'Nieznany sklep',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                _formatReceiptDate(receipt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Text(
            _formatPrice(receipt),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> list) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            list['name'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            formatProdukt(list['items']),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(Map<String, dynamic> item) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    int bestPriceIndex = 0;
    double lowestPrice = double.maxFinite;
    
    for (int i = 0; i < item['stores'].length; i++) {
      String priceStr = item['stores'][i]['price'].toString().replaceAll('zł', '');
      double price = double.parse(priceStr);
      
      if (price < lowestPrice) {
        lowestPrice = price;
        bestPriceIndex = i;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['item'],
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: item['stores'].asMap().entries.map<Widget>((entry) {
              int idx = entry.key;
              Map<String, dynamic> store = entry.value;
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        store['name'],
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white :  Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store['price'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: idx == bestPriceIndex ? Colors.green : isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}



String formatProdukt(int count) {
  if (count == 1) {
    return '$count produkt';
  } else if ((count % 10 >= 2 && count % 10 <= 4) &&
             !(count % 100 >= 12 && count % 100 <= 14)) {
    return '$count produkty';
  } else {
    return '$count produktów';
  }
}

String _formatReceiptDate(Map<String, dynamic> receipt) {
  final date = receipt['date'] ?? receipt['purchase_date'] ?? receipt['created_at'];
  if (date == null) return 'Brak daty';

  if (date is String) {
    if (date.contains('T')) {
      final parts = date.split('T')[0].split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    } else if (date.contains('-')) {
      final parts = date.split('-');
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    } else {
      return date;
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
