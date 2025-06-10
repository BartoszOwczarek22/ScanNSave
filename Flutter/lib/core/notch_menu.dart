import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/core/clip_shadow_path.dart';
import 'package:scan_n_save/lists/shopping_lists_page.dart';
import 'package:scan_n_save/pages/camera_page.dart';
import 'package:scan_n_save/pages/receipt_history_page.dart';
import 'package:scan_n_save/sharedprefsnotifier.dart';
import 'package:scan_n_save/stats/main_dashboard.dart';
import 'package:scan_n_save/stats/store_comparison.dart';

class NotchMenu extends ConsumerWidget {
  const NotchMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseSize = MediaQuery.of(context).size.shortestSide;
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

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
              color: isDark ? const Color.fromARGB(255, 47, 46, 53) : Color(0xFFF9F9F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BottomMenuButton(
                    icon: Icons.receipt_outlined,
                    label: 'Paragony',
                    onPressed: () {
                      if (ModalRoute.of(context)?.settings.name != '/receipt-history') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReceiptHistoryPage(),
                            settings: RouteSettings(name: '/receipt-history'),
                          ),
                        );
                      }
                    },
                  ),
                  BottomMenuButton(
                    icon: Icons.insert_chart_outlined_rounded,
                    label: 'Statystyki',
                    onPressed: () => {
                      if (ModalRoute.of(context)?.settings.name != '/statistics') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpenseStatisticsScreen(),
                            settings: RouteSettings(name: '/statistics'),
                          ),
                        )
                      }
                    },
                  ),
                  SizedBox(width: baseSize * 0.1),
                  BottomMenuButton(
                    icon: Icons.checklist_rtl_rounded,
                    label: 'Listy',
                    onPressed: () {
                       if (ModalRoute.of(context)?.settings.name != '/shopping-lists') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShoppingListsPage(),
                            settings: RouteSettings(name: '/shopping-lists'),
                          ),
                        );
                      }
                    },
                  ),
                  BottomMenuButton(
                    icon: Icons.bar_chart,
                    label: 'Porównywaj \nceny',
                    onPressed: () => {
                      if (ModalRoute.of(context)?.settings.name != '/price-comparison') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PriceComparisonScreen(),
                            settings: RouteSettings(name: '/price-comparison'),
                          ),
                        )
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          left: 0,
          right: 0,
          child: Center(child: Text("Skanuj", style: TextStyle(color: Color.fromRGBO(99, 171, 243, 1.0), fontWeight: FontWeight.bold),))),
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

class BottomMenuButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final baseSize = MediaQuery.of(context).size.shortestSide;
    return TextButton(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: baseSize * 0.06, color: isDark ? const Color.fromRGBO(222, 222, 222, 1) : Color.fromRGBO(70, 70, 70, 1.0) ,),
          Text(label,textAlign: TextAlign.center ,style: TextStyle(color: isDark ? const Color.fromRGBO(222, 222, 222, 1) : Color.fromRGBO(70, 70, 70, 1.0)),)
        ],
      ),
    );
  }
}

class NotchMenuClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double notchHeight = 50;
    double notchWidth = 130;
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