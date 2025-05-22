import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:scan_n_save/pages/camera_page.dart';
import 'package:scan_n_save/pages/home_page.dart';

class ExpenseStatisticsScreen extends StatefulWidget {
  const ExpenseStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseStatisticsScreen> createState() => _ExpenseStatisticsScreenState();
}

class _ExpenseStatisticsScreenState extends State<ExpenseStatisticsScreen> {

  String _currentFilterType = 'Kategorie';
  int _selectedYear = 2025;
  String _selectedMonth = 'Wszystkie';

  final List<ExpenseCategory> _categoryData = [
    ExpenseCategory('Nabiał', 450.75, Colors.blue),
    ExpenseCategory('Owoce', 320.50, Colors.red),
    ExpenseCategory('Warzywa', 215.30, Colors.green),
    ExpenseCategory('Słodycze', 175.20, Colors.purple),
    ExpenseCategory('Mięso', 145.85, Colors.orange),
    ExpenseCategory('Ryby', 95.40, Colors.teal),
    ExpenseCategory('Inne', 85.30, Colors.grey),
  ];
  
  final List<ExpenseCategory> _shopData = [
    ExpenseCategory('Lidl', 380.45, Colors.blue),
    ExpenseCategory('Biedronka', 290.30, Colors.red),
    ExpenseCategory('Żabka', 240.75, Colors.green),
    ExpenseCategory('Carrefour', 210.20, Colors.purple),
    ExpenseCategory('Auchan', 175.50, Colors.orange),
    ExpenseCategory('Eurospar', 150.85, Colors.teal),
    ExpenseCategory('Inne', 125.25, Colors.grey),
  ];

  final List<int> _years = [2023, 2024, 2025];
  
  // Months for filter
  final List<String> _months = ['Wszystkie', 'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec', 'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'];

  @override
  Widget build(BuildContext context) {

    final displayData = _currentFilterType == 'Kategorie' ? _categoryData : _shopData;
    final totalExpense = displayData.fold(0.0, (sum, item) => sum + item.amount);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki wydatków'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Filtry
              _buildFilters(),
              
              // Podsumowanie
              _buildStatsSummary(totalExpense),
              
              // Pie chart
              SizedBox(
                height: 300,
                child: _buildPieChart(displayData),
              ),
              
              // Legenda
              _buildLegend(displayData),

              const SizedBox(height: 80),

            ],
          ),
        ),
      ),

    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtruj',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Category/Shop toggle
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'Kategorie',
                      label: Text('Kategorie'),
                      icon: Icon(Icons.category),
                    ),
                    ButtonSegment<String>(
                      value: 'Sklepy',
                      label: Text('Sklepy'),
                      icon: Icon(Icons.store),
                    ),
                  ],
                  selected: {_currentFilterType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _currentFilterType = newSelection.first;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Year dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Rok',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedYear,
                  items: _years.map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Month dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Miesiąc',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedMonth,
                  items: _months.map((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMonth = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(double totalExpense) {   
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Łączne wydatki',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalExpense zł',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_selectedMonth == 'Wszystkie' ? 'Wszystkie z' : _selectedMonth} $_selectedYear',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Średnia na paragon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalExpense/15} zł', // Mock average calculation
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '15 paragonów',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildLegend(List<ExpenseCategory> data) {
  // Sortowanie danych
    final sortedData = [...data]..sort((a, b) => b.amount.compareTo(a.amount));
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentFilterType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final category = sortedData[index];
              final percentage = (category.amount / data.fold(0.0, (sum, item) => sum + item.amount)) * 100;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${category.amount} zł',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          TextButton(
            onPressed: () {
              // Navigate to detailed breakdown
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Zobacz dokładne statystyki'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class ExpenseCategory {
  final String name;
  final double amount;
  final Color color;

  ExpenseCategory(this.name, this.amount, this.color);
}