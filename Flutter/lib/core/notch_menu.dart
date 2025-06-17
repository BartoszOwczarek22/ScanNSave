import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/core/clip_shadow_path.dart';
import 'package:scan_n_save/lists/shopping_lists_page.dart';
import 'package:scan_n_save/pages/camera_page.dart';
import 'package:scan_n_save/pages/home_page.dart';
import 'package:scan_n_save/pages/receipt_history_page.dart';
import 'package:scan_n_save/sharedprefsnotifier.dart';
import 'package:scan_n_save/stats/main_dashboard.dart';
import 'package:scan_n_save/stats/store_comparison.dart';

class NotchMenu extends ConsumerWidget {
  final bool isHomePage;
  final int screenIndex;
  const NotchMenu(this.isHomePage, this.screenIndex, {super.key});

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
                    selected: screenIndex == 0,
                    icon: Icons.receipt_outlined,
                    label: 'Paragony',
                    onPressed: () {
                      if (ModalRoute.of(context)?.settings.name != '/receipt-history') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReceiptHistoryPage(),
                            settings: RouteSettings(name: '/receipt-history'),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  BottomMenuButton(
                    selected: screenIndex == 1,
                    icon: Icons.insert_chart_outlined_rounded,
                    label: 'Statystyki',
                    onPressed: () => {
                      if (ModalRoute.of(context)?.settings.name != '/statistics') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpenseStatisticsScreen(),
                            settings: RouteSettings(name: '/statistics'),
                          ),
                          (route) => false,
                        )
                      }
                    },
                  ),
                  SizedBox(width: baseSize * 0.1),
                  BottomMenuButton(
                    selected: screenIndex == 2,
                    icon: Icons.checklist_rtl_rounded,
                    label: 'Listy',
                    onPressed: () {
                       if (ModalRoute.of(context)?.settings.name != '/shopping-lists') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShoppingListsPage(),
                            settings: RouteSettings(name: '/shopping-lists'),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  BottomMenuButton(
                    selected: screenIndex == 3,
                    icon: Icons.bar_chart,
                    label: 'Porównywaj \nceny',
                    onPressed: () => {
                      if (ModalRoute.of(context)?.settings.name != '/price-comparison') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PriceComparisonScreen(),
                            settings: RouteSettings(name: '/price-comparison'),
                          ),
                          (route) => false,
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
          child: Center(child: Text(isHomePage ? "Skanuj" : "Home", style: TextStyle(color: Color.fromRGBO(99, 171, 243, 1.0), fontWeight: FontWeight.bold),))),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: ClipOval( 
              child: IconButton(
                onPressed: isHomePage ? () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPage(),
                    ),
                  )
                } : () => {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(),
                    ),
                    (route) => false,
                  )
                },
                icon: Icon(isHomePage ? Icons.document_scanner_outlined : Icons.home_outlined),
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
  final bool selected;

  const BottomMenuButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
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
          Icon(icon, size: baseSize * 0.06, color: selected ? const Color.fromRGBO(99, 171, 243, 1.0) : (isDark ? const Color.fromRGBO(222, 222, 222, 1) : Color.fromRGBO(70, 70, 70, 1.0)),),
          Text(label,textAlign: TextAlign.center ,style: TextStyle(color: selected ? const Color.fromRGBO(99, 171, 243, 1.0) : (isDark ? const Color.fromRGBO(222, 222, 222, 1) : Color.fromRGBO(70, 70, 70, 1.0))),)
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