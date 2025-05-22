import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scan_n_save/pages/home_page.dart';

class PriceComparisonScreen extends StatefulWidget{
  const PriceComparisonScreen({Key? key}) : super(key: key);

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedCategory = 'Wszystkie';
  String _sortBy = 'Cena (rosnąco)';

  final List<String> _categories = [
    'Wszystkie',
    'Nabiał', 
    'Owoce', 
    'Warzywa', 
    'Słodycze',
    'Pieczywo',
    'Napoje', 
    'Mięso', 
    'Ryby', 
    'Przekąski',
    'Inne'
  ];

  final List<String> _sortOptions = [
    'Cena (rosnąco)',
    'Cena (malejąco)',
    'Nazwa sklepu',
    'Nazwa produktu',
    'Najlepsza oferta'
  ];

  @override
  void initState(){
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose(){
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final List<ProductComparison> _productComparisons = [
      ProductComparison(
        productName: 'Mleko 3.2% 1L',
        category: 'Nabiał',
        storePrices: [
          StorePrice('Biedronka', 3.49, DateTime.now().subtract(Duration(days: 1))),
          StorePrice('Lidl', 3.29, DateTime.now().subtract(Duration(days: 2))),
          StorePrice('Carrefour', 3.89, DateTime.now().subtract(Duration(days: 1))),
          StorePrice('Żabka', 4.19, DateTime.now().subtract(Duration(hours: 12))),
        ],
      ),
      ProductComparison(
        productName: 'Chleb pszenny 500g',
        category: 'Pieczywo',
        storePrices: [
          StorePrice('Biedronka', 2.99, DateTime.now().subtract(Duration(days: 1))),
          StorePrice('Lidl', 2.79, DateTime.now().subtract(Duration(days: 3))),
          StorePrice('Eurospar', 3.49, DateTime.now().subtract(Duration(days: 2))),
          StorePrice('Żabka', 3.99, DateTime.now().subtract(Duration(hours: 8))),
        ],
      ),
      ProductComparison(
        productName: 'Pierś z kurczaka 1kg',
        category: 'Mięso',
        storePrices: [
          StorePrice('Biedronka', 12.99, DateTime.now().subtract(Duration(days: 2))),
          StorePrice('Lidl', 11.99, DateTime.now().subtract(Duration(days: 1))),
          StorePrice('Carrefour', 13.49, DateTime.now().subtract(Duration(days: 3))),
          StorePrice('Eurospar', 12.49, DateTime.now().subtract(Duration(days: 1))),
        ],
      ),
      ProductComparison(
        productName: 'Coca-Cola 0.5L',
        category: 'Napoje',
        storePrices: [
          StorePrice('Biedronka', 2.49, DateTime.now().subtract(Duration(hours: 6))),
          StorePrice('Lidl', 2.29, DateTime.now().subtract(Duration(days: 1))),
          StorePrice('Carrefour', 2.69, DateTime.now().subtract(Duration(days: 2))),
          StorePrice('Żabka', 3.49, DateTime.now().subtract(Duration(hours: 4))),
          StorePrice('Eurospar', 2.79, DateTime.now().subtract(Duration(days: 1))),
        ],
      ),
      ProductComparison(
        productName: 'Jogurt naturalny 200g',
        category: 'Nabiał',
        storePrices: [
          StorePrice('Biedronka', 2.99, DateTime.now().subtract(Duration(days: 1))),
          StorePrice('Lidl', 2.49, DateTime.now().subtract(Duration(days: 2))),
          StorePrice('Carrefour', 3.49, DateTime.now().subtract(Duration(days: 1))),
        ],
      ),
      ProductComparison(
        productName: 'Chipsy Pringles paprykowe 140g',
        category: 'Przekąski',
        storePrices: [
          StorePrice('Biedronka', 6.99, DateTime.now().subtract(Duration(hours: 12))),
          StorePrice('Lidl', 6.49, DateTime.now().subtract(Duration(days: 1))),
          StorePrice('Żabka', 7.99, DateTime.now().subtract(Duration(hours: 3))),
          StorePrice('Eurospar', 7.29, DateTime.now().subtract(Duration(days: 2))),
        ],
      ),
    ];

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: (){Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));}, icon: const Icon(Icons.arrow_back)),
          title: const Text('Porównywarka cen'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.compare_arrows), text: 'Porównaj ceny',),
              Tab(icon: Icon(Icons.trending_down), text: 'Najlepsze okazje',)
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildComparisonTab(),
            _buildBestDealsTab(),
          ],
        ),
      );
    }

    Widget _buildComparisonTab(){
      return Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildProductList())
        ],
      );
    }

    Widget _buildBestDealsTab(){
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildBestDealsHeader(),
            _buildBestDealsList()
          ],
        ),
      );
    }

    Widget _buildSearchAndFilters(){
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Wyszukaj produkt...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: (){
                  setState(() {
                    _searchController.clear();
                  });
                },) : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12,),

            // Filtry
            Row(children: [
              Expanded(
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'Kategoria',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                  value: _selectedCategory,
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null){
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                  ),
                ),

                const SizedBox(width: 12,),
                Expanded(child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sortuj po',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                  value: _sortBy,
                  items: _sortOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: const TextStyle(fontSize: 13),),
                    );
                  }
                  ).toList(),
                  onChanged: (String? newValue){
                    if (newValue != null){
                      setState(() {
                        _sortBy = newValue;
                      });
                    }
                  },
                ),
                ),
            ],
              )
            ],
            ),
        );
    }

    Widget _buildProductList() {
      final filteredProducts = _getFilteredProducts();

      if (filteredProducts.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey,),
              SizedBox(height: 16,),
              Text("Nie znaleziono produktów", style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text('Spróbuj ponowić wyszukanie albo użyć innych filtrów', style: TextStyle(fontSize: 14, color: Colors.grey),),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index){
          return _buildProductComparisonCard(filteredProducts[index]);
        },
      );
    }
    Widget _buildProductComparisonCard(ProductComparison product) {
    final currencyFormat = NumberFormat.currency(symbol: 'zł', decimalDigits: 2);
    final sortedPrices = [...product.storePrices]..sort((a, b) => a.price.compareTo(b.price));
    final bestPrice = sortedPrices.first;
    final worstPrice = sortedPrices.last;
    final savings = worstPrice.price - bestPrice.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (savings > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Oszczędź ${currencyFormat.format(savings)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedPrices.map((storePrice) {
              final isLowest = storePrice == bestPrice;
              final isHighest = storePrice == worstPrice && savings > 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLowest 
                      ? Colors.green.withOpacity(0.1)
                      : isHighest 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLowest 
                        ? Colors.green
                        : isHighest 
                            ? Colors.red
                            : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStoreColor(storePrice.storeName),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          storePrice.storeName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storePrice.storeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _getTimeAgo(storePrice.lastUpdated),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(storePrice.price),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isLowest 
                                ? Colors.green
                                : isHighest 
                                    ? Colors.red
                                    : null,
                          ),
                        ),
                        if (isLowest)
                          const Text(
                            'Najlepsza cena',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBestDealsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Najlepsze oferty z dzisiaj',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Produkty z największą różnicą cen między sklepami',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestDealsList() {
    final currencyFormat = NumberFormat.currency(symbol: 'zł', decimalDigits: 2);
    final bestDeals = _productComparisons.where((product) {
      final prices = product.storePrices.map((sp) => sp.price).toList()..sort();
      return prices.length > 1 && (prices.last - prices.first) > 0.5;
    }).toList();
    
    bestDeals.sort((a, b) {
      final aPrices = a.storePrices.map((sp) => sp.price).toList()..sort();
      final bPrices = b.storePrices.map((sp) => sp.price).toList()..sort();
      final aSavings = aPrices.last - aPrices.first;
      final bSavings = bPrices.last - bPrices.first;
      return bSavings.compareTo(aSavings);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: bestDeals.length,
      itemBuilder: (context, index) {
        final product = bestDeals[index];
        final prices = product.storePrices.map((sp) => sp.price).toList()..sort();
        final savings = prices.last - prices.first;
        final bestStore = product.storePrices.firstWhere((sp) => sp.price == prices.first);
        final worstStore = product.storePrices.firstWhere((sp) => sp.price == prices.last);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${index + 1} OKAZJA',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Oszczędź ${currencyFormat.format(savings)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          children: [
                            Text(
                              bestStore.storeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              currencyFormat.format(bestStore.price),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'Najlepsza cena',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Column(
                          children: [
                            Text(
                              worstStore.storeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              currencyFormat.format(worstStore.price),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text(
                              'Najwyższa cena',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ProductComparison> _getFilteredProducts() {
    List<ProductComparison> filtered = _productComparisons;

    // Filter by search text
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.productName.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'Wszystkie') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Sort products
    switch (_sortBy) {
      case 'Cena (rosnąco)':
        filtered.sort((a, b) {
          final aMin = a.storePrices.map((sp) => sp.price).reduce((a, b) => a < b ? a : b);
          final bMin = b.storePrices.map((sp) => sp.price).reduce((a, b) => a < b ? a : b);
          return aMin.compareTo(bMin);
        });
        break;
      case 'Cena (malejąco)':
        filtered.sort((a, b) {
          final aMax = a.storePrices.map((sp) => sp.price).reduce((a, b) => a > b ? a : b);
          final bMax = b.storePrices.map((sp) => sp.price).reduce((a, b) => a > b ? a : b);
          return bMax.compareTo(aMax);
        });
        break;
      case 'Nazwa produktu':
        filtered.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'Najlepsza oferta':
        filtered.sort((a, b) {
          final aPrices = a.storePrices.map((sp) => sp.price).toList()..sort();
          final bPrices = b.storePrices.map((sp) => sp.price).toList()..sort();
          final aSavings = aPrices.length > 1 ? aPrices.last - aPrices.first : 0;
          final bSavings = bPrices.length > 1 ? bPrices.last - bPrices.first : 0;
          return bSavings.compareTo(aSavings);
        });
        break;
    }

    return filtered;
  }

  Color _getStoreColor(String storeName) {
    switch (storeName) {
      case 'Biedronka':
        return Colors.red;
      case 'Lidl':
        return Colors.lightBlue;
      case 'Carrefour':
        return Colors.purple;
      case 'Eurospar':
        return Colors.orange;
      case 'Żabka':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ProductComparison {
  final String productName;
  final String category;
  final List<StorePrice> storePrices;

  ProductComparison({
    required this.productName,
    required this.category,
    required this.storePrices,
  });
}

class StorePrice {
  final String storeName;
  final double price;
  final DateTime lastUpdated;

  StorePrice(this.storeName, this.price, this.lastUpdated);
}
