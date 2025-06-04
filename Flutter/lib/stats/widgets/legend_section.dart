import 'package:flutter/material.dart';
import 'package:scan_n_save/stats/main_dashboard.dart';

class StatsLegend extends StatelessWidget {
  final List<ExpenseCategory> data;
  final String title;

  const StatsLegend({
    Key? key,
    required this.data,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedData = [...data]..sort((a, b) => b.amount.compareTo(a.amount));
    final total = data.fold(0.0, (sum, item) => sum + item.amount);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
              final percentage = (category.amount / total) * 100;
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
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${category.amount.toStringAsFixed(2)} zł',
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
              // nawigacja do szczegółów
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
