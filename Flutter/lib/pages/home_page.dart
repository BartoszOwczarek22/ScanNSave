import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scan_n_save/auth/verifyPage.dart';
import 'package:scan_n_save/core/clip_shadow_path.dart';
import 'package:scan_n_save/pages/camera_page.dart';
import 'package:scan_n_save/settings_page.dart';
import 'package:scan_n_save/lists/shopping_lists_page.dart';
import 'package:scan_n_save/pages/receipt_history_page.dart';
import 'package:scan_n_save/stats/main_dashboard.dart';
import 'package:scan_n_save/stats/store_comparison.dart';

// Sample data - just for MVP

final recentReceiptsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {
    'id': 1,
    'store': 'Biedronka',
    'date': 'Maj 19, 2025',
    'total': '78 zł'
  },
  {
    'id': 2,
    'store': 'Żabka',
    'date': 'Maj 15, 2025',
    'total': '32.10 zł'
  },
]);


final shoppingListsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {'id': 1, 'name': 'Lista zakupów niedziela', 'items': 12},
  {'id': 2, 'name': 'Impreza', 'items': 8},
]);

final savedAmountProvider = Provider<double>((ref) => 124.50);
final monthlySpendingProvider = Provider<double>((ref) => 843.27);

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
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get data from providers
    final recentReceipts = ref.watch(recentReceiptsProvider);
    final shoppingLists = ref.watch(shoppingListsProvider);
    final savedAmount = ref.watch(savedAmountProvider);
    final monthlySpending = ref.watch(monthlySpendingProvider);
    final comparisonData = ref.watch(comparisonDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset('assets/icons/logo.svg', colorFilter: ColorFilter.mode(Color.fromARGB(255, 99, 171, 243), BlendMode.srcIn),height: 30,),
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
                      _buildStatCard('W tym miesiącu', '\$${monthlySpending.toStringAsFixed(2)}',
                          'Łączne wydatki', Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard('Zaoszczędzono', '\$${savedAmount.toStringAsFixed(2)}',
                          'Z porównywarką cen', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    'Ostatnie zakupy',
                    Icons.receipt,
                    Column(
                      children: recentReceipts
                          .map((receipt) => _buildReceiptItem(receipt))
                          .toList(),
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
          NotchMenu(),
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
                    onPressed: () {        Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => PriceComparisonScreen()), );},
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
                receipt['store'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                receipt['date'],
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Text(
            receipt['total'],
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
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        store['name'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store['price'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: idx == bestPriceIndex ? Colors.green : Colors.black,
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

class NotchMenu extends StatelessWidget {
  const NotchMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final baseSize = MediaQuery.of(context).size.shortestSide;
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipShadowPath(
            shadow: Shadow(
              color: Colors.black54,
              offset: Offset(0, 0),
              blurRadius: 10,
            ),
            clipper: NotchMenuClipper(),
            child: Container(
              height: 90,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BottomMenuButton(
                    icon: Icons.receipt_outlined,
                    label: 'Historia',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiptHistoryPage(), 
                        ),
                      );
                    },
                  ),
                  BottomMenuButton(
                    icon: Icons.checklist_rtl_rounded,
                    label: 'Listy',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShoppingListsPage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: baseSize * 0.1),
                  BottomMenuButton(
                    icon: Icons.insert_chart_outlined_rounded,
                    label: 'Statystyki',
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExpenseStatisticsScreen()
                        ),
                      )
                    },
                  ),
                  BottomMenuButton(
                    icon: Icons.account_circle_outlined,
                    label: 'Konto',
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(),
                        ),
                      )
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: ClipOval( 
              child: IconButton(
                onPressed: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPage(),
                    ),
                  )
                },
                icon: Icon(Icons.document_scanner_outlined),
                color: Colors.white,
                iconSize: 30,
                style: IconButton.styleFrom(
                  backgroundColor: Color.fromRGBO(99, 171, 243, 1.0),
                  padding: EdgeInsets.all(20),
                  shape: CircleBorder(),
                ),
              )
            )
          )
        )
      ],
    );
  }
}

class BottomMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const BottomMenuButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseSize = MediaQuery.of(context).size.shortestSide;
    return TextButton(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: baseSize * 0.06, color: Color.fromRGBO(70, 70, 70, 1.0),),
          Text(label, style: TextStyle(color: Color.fromRGBO(70, 70, 70, 1.0)),)
        ],
      ),
    );
  }
}

class NotchMenuClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double notchHeight = 55;
    double notchWidth = 135;
    double notchRounding = 30;

    Path path = Path();
    path.lineTo((size.width - notchWidth) / 2, 0);

    // lewa krzywa
    path.cubicTo(
      (size.width - notchWidth) / 2 + notchRounding,
      0,
      (size.width - notchWidth) / 2 + notchRounding / 2,
      notchHeight,
      size.width / 2,
      notchHeight,
    );

    // prawa krzywa
    path.cubicTo(
      (size.width - notchWidth) / 2 + notchWidth - notchRounding / 2,
      notchHeight,
      (size.width - notchWidth) / 2 + notchWidth - notchRounding,
      0,
      (size.width - notchWidth) / 2 + notchWidth,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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