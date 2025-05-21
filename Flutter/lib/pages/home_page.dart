import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/auth/verifyPage.dart';
import 'package:scan_n_save/core/clip_shadow_path.dart';
import 'package:scan_n_save/pages/camera_page.dart';
import 'package:scan_n_save/settings_page.dart';
import 'package:scan_n_save/lists/shopping_lists_page.dart';
import 'package:scan_n_save/pages/receipt_history_page.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("Strona główna")),
      body: Stack(
        children: [
          // cała strona głowna
          Positioned.fill(child: Center(child: Text("Zawartość aplikacji"))),
          NotchMenu()
        ],
      ),
      // Center(
      //   child: ElevatedButton(
      //     onPressed: () async {
      //       await FirebaseAuth.instance.signOut();
      //       Navigator.pushReplacement(
      //         context,
      //         MaterialPageRoute(builder: (context) => LoginPage()),
      //       );
      //       ref.read(isLoadingProvider.notifier).state = false;
      //       ref.read(emailVerificationProvider.notifier).state = false;
      //     },
      //     child: const Text('wyloguj'),
      //   ),
      // ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => SettingsPage()),
      //     );
      //   },
      //   child: const Icon(Icons.settings),
      // ),
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
                      icon: Icons.shopping_cart_outlined,
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
                      onPressed: () => {},
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
