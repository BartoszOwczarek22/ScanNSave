import 'package:flutter/material.dart';
import 'package:scan_n_save/pages/home_page.dart';
import 'package:scan_n_save/core/notch_menu.dart';

class ShoppingListsPage extends StatelessWidget {
  const ShoppingListsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Przykładowe dane
    final shoppingLists = [
      {'name': 'Zakupy spożywcze', 'items': 12},
      {'name': 'Impreza urodzinowa', 'items': 7},
      {'name': 'Domowe porządki', 'items': 5},
    ];

    return Scaffold(
    appBar: AppBar(
      title: const Text('Twoje listy zakupów'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        ),
      ),
    ),
    body: Stack(
      children: [
        // Zawartość strony
        Padding(
          padding: const EdgeInsets.only(bottom: 90), // Dodaj margines dla menu
          child: ListView.builder(
            itemCount: shoppingLists.length,
            itemBuilder: (context, index) {
              final list = shoppingLists[index];
              return ListTile(
                leading: const Icon(Icons.list_alt),
                title: Text(list['name'] as String),
                subtitle: Text('Liczba produktów: ${list['items']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Otwieranie: ${list['name']}')),
                  );
                },
              );
            },
          ),
        ),
        // Dodaj NotchMenu
        const NotchMenu(),
      ],
    ),
    // Usuń floatingActionButton (funkcjonalność przeniesiona do NotchMenu)
  );
  }
}

void main() {
  runApp(MaterialApp(
    home: const ShoppingListsPage(),
    routes: {
      // ...inne trasy...
      '/shopping-lists': (context) => const ShoppingListsPage(),
    },
   ));
}