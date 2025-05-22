import 'package:flutter/material.dart';
import 'package:scan_n_save/pages/home_page.dart';

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
          onPressed: () => Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => HomePage()), ),
        )
      ),
      body: ListView.builder(
        itemCount: shoppingLists.length,
        itemBuilder: (context, index) {
          final list = shoppingLists[index];
          return ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(list['name'] as String),
            subtitle: Text('Liczba produktów: ${list['items']}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Przejście do szczegółów listy (do zaimplementowania)
              Navigator.pushNamed(context, '/shopping-lists');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Otwieranie: ${list['name']}')),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Dodawanie nowej listy (do zaimplementowania)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dodaj nową listę - funkcja w budowie')),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Dodaj nową listę',
      ),
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