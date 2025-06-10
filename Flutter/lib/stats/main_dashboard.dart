import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:scan_n_save/stats/widgets/stats_summary.dart';
import 'package:scan_n_save/stats/widgets/filters_section.dart';
import 'package:scan_n_save/stats/widgets/legend_section.dart';
import 'package:scan_n_save/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scan_n_save/core/notch_menu.dart';


class ExpenseStatisticsScreen extends StatefulWidget {
  const ExpenseStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseStatisticsScreen> createState() => _ExpenseStatisticsScreenState();
}

class _ExpenseStatisticsScreenState extends State<ExpenseStatisticsScreen> {

  String _currentFilterType = 'Kategorie';
  int _selectedYear = 2025;
  String _selectedMonth = 'Wszystkie';

  List<ExpenseCategory> _categoryData = [];
  
  List<ExpenseCategory> _shopData = [];

  bool _isLoading = true;

  String? _errorMessage;
  int _totalReceipts = 0;

  final ApiService _apiService = ApiService();

  final List<int> _years = [2023, 2024, 2025];
  
  // Months for filter
  final List<String> _months = ['Wszystkie', 'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec', 'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'];

    final List<Color> _chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
  ];

  @override 
  void initState(){
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if(user == null) {
        throw Exception("Brak użytkownika");
      }

      final dateRange = _calculateDateRange();

      await Future.wait([
        _loadCategoryData(user.uid, dateRange['start']!, dateRange['end']!),
        _loadShopData(user.uid, dateRange['start']!, dateRange['end']!)
      ]);

      final displayData = _currentFilterType == 'Kategorie' ? _categoryData : _shopData;
      _totalReceipts = displayData.fold<int>(0, (sum, item) => sum + item.receiptCount);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, String> _calculateDateRange() {
    DateTime startDate;
    DateTime endDate;

    if (_selectedMonth == "Wszystkie") {
      startDate = DateTime(_selectedYear, 1, 1);
      endDate = DateTime(_selectedYear, 12, 31);
    } else {
      int monthIndex = _months.indexOf(_selectedMonth);
      startDate = DateTime(_selectedYear, monthIndex, 1);
      endDate = DateTime(_selectedYear, monthIndex + 1, 0);
    }

    return {
      'start' : DateFormat('yyyy-MM-dd').format(startDate),
      'end' : DateFormat('yyyy-MM-dd').format(endDate)
    };
  }

  Future<void> _loadCategoryData(String userId, String startDate, String endDate) async{ 
    try {
      final categoryData = await _apiService.getExpensesByCategory(userId: userId, startDate: startDate, endDate: endDate);
      if (!mounted) return;
      setState(() {
        _categoryData = categoryData.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> data = entry.value;
          return ExpenseCategory(
            data['category'] ?? 'Nieznana kategoria',
            (data['total'] ?? 0.0).toDouble(),
            _chartColors[index % _chartColors.length],
            receiptCount: data['receipt_count'] ?? 0
          );
        }).toList();
      });
    } catch (e) {
      print('Błąd przy ładowaniu danych kategorii: $e');
      rethrow;
    }
  }


  Future<void> _loadShopData(String userId, String startDate, String endDate) async{
    try {
      final shopData = await _apiService.getExpensesByShop(userId: userId, startDate: startDate, endDate: endDate);

      if (!mounted) return;
      setState(() {
        _shopData = shopData.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> data = entry.value;
          return ExpenseCategory(
            data['shop'] ?? 'Nieznany sklep',
            (data['total'] ?? 0.0).toDouble(),
            _chartColors[index % _chartColors.length],
            receiptCount: data['receipt_count'] ?? 0,
          );
        }).toList();
      });
    } catch (e) {
      print('Błąd przy ładowaniu danych sklepów: $e');
      rethrow;
    }
  }
  @override
  Widget build(BuildContext context) {

    final displayData = _currentFilterType == 'Kategorie' ? _categoryData : _shopData;
    final totalExpense = displayData.fold(0.0, (sum, item) => sum + item.amount);
    
    return Scaffold(
    appBar: AppBar(
      title: const Text('Statystyki wydatków'),
    ),
    body: Stack(
      children: [
        // Main content with bottom padding for menu
        Padding(
          padding: const EdgeInsets.only(bottom: 90), // Space for bottom menu
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _errorMessage != null 
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Filtry
                      FiltersSection(
                        currentFilterType: _currentFilterType, 
                        years: _years, 
                        months: _months, 
                        selectedYear: _selectedYear, 
                        selectedMonth: _selectedMonth, 
                        onFilterTypeChanged: (type) {
                          if (!mounted) return;
                          setState(() {
                            _currentFilterType = type;
                          });
                          _loadData();
                        }, 
                        onYearChanged: (year){
                          if (!mounted) return;
                          setState(() {
                            _selectedYear = year;
                          });
                          _loadData();
                        }, 
                        onMonthChanged: (month){
                          if (!mounted) return;
                          setState(() {
                            _selectedMonth = month;
                          });
                          _loadData();
                        }
                      ),
                      
                      // Podsumowanie
                      StatsSummary(
                        totalExpense: totalExpense, 
                        receiptCount: _totalReceipts, 
                        displayMonth: '${_selectedMonth == 'Wszystkie' ? 'Wszystkie z' : _selectedMonth} $_selectedYear', 
                        odmienParagon: _odmienParagon
                      ),
                      
                      // Pie chart
                      displayData.isEmpty 
                        ? _buildNoDataWidget() 
                        : Column(
                            children: [
                              SizedBox(
                                height: 300,
                                child: _buildPieChart(displayData),
                              ),
                            ],
                          ),
                      
                      // Legenda
                      StatsLegend(data: displayData, title: _currentFilterType),
                
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
        // Bottom menu
        const NotchMenu(),
      ],
    ),
  );
}
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Wystąpił błąd podczas ładowania danych',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Nieznany błąd',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Brak danych dla wybranego okresu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Spróbuj wybrać inny rok lub miesiąc',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildPieChart(List<ExpenseCategory> data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: data.map((category) {
            return PieChartSectionData(
              color: category.color,
              value: category.amount,
              title: '', // Empty title for cleaner look
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          ),
        ),
      ),
    );
  }

  String _odmienParagon(int liczba){
    if (liczba == 1) return 'paragon';
    if ([2,3,4].contains(liczba % 10) && !(liczba % 100 >= 12 && liczba % 100 <= 14)){
      return 'paragony';
    }
    return 'paragonów';
  }
}

class ExpenseCategory {
  final String name;
  final double amount;
  final Color color;
  final int receiptCount;

  ExpenseCategory(this.name, this.amount, this.color, {this.receiptCount = 0});
}