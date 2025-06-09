import 'package:flutter/material.dart';

class FiltersSection extends StatelessWidget {
  final String currentFilterType;
  final List<int> years;
  final List<String> months;
  final int selectedYear;
  final String selectedMonth;
  final void Function(String) onFilterTypeChanged;
  final void Function(int) onYearChanged;
  final void Function(String) onMonthChanged;

  const FiltersSection({
    Key? key,
    required this.currentFilterType,
    required this.years,
    required this.months,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onFilterTypeChanged,
    required this.onYearChanged,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  selected: {currentFilterType},
                  onSelectionChanged: (Set<String> newSelection) {
                    onFilterTypeChanged(newSelection.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Rok',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: selectedYear,
                  items: years.map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) onYearChanged(newValue);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Miesiąc',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: selectedMonth,
                  items: months.map((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) onMonthChanged(newValue);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
