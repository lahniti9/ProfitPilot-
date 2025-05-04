import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];
  final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyData = prefs.getStringList('profit_history');

    if (historyData != null) {
      setState(() {
        history = historyData.map((item) {
          final cleaned = item.replaceAll('{', '').replaceAll('}', '');
          final pairs = cleaned.split(', ');
          return {
            for (var pair in pairs)
              pair.split(': ')[0].trim(): pair.split(': ')[1].trim()
          };
        }).toList();
        history.sort((a, b) =>
            b['timestamp']!.compareTo(a['timestamp']!)); // Newest first
      });
    }
  }

  Future<void> clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content:
            const Text('Are you sure you want to delete all history items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profit_history');
      setState(() {
        history.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History cleared'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> deleteItem(int index) async {
    final itemToDelete = history[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete calculation from ${itemToDelete['timestamp']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final newHistory =
          List<String>.from(prefs.getStringList('profit_history') ?? []);
      newHistory.removeAt(index);
      await prefs.setStringList('profit_history', newHistory);

      setState(() {
        history.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: history.isEmpty ? _buildEmptyState() : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Calculations Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your calculation history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final profit = double.parse(item['profit']!);
          final isProfit = profit >= 0;
          final profitColor = isProfit ? _colorScheme.primary : Colors.red;

          return Dismissible(
            key: Key(item['timestamp']!),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            confirmDismiss: (direction) async {
              try {
                await deleteItem(index);
                return true; // Only confirm if deletion succeeds
              } catch (e) {
                return false; // Don't dismiss if there's an error
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Optional: Add detail view or edit functionality
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['timestamp'] ?? 'No date',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Icon(
                              isProfit
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: profitColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Investment',
                          '\$${item['investment']}',
                          Icons.attach_money,
                        ),
                        _buildDetailRow(
                          'Purchase Price',
                          '\$${item['purchasePrice']}/unit',
                          Icons.shopping_cart,
                        ),
                        _buildDetailRow(
                          'Selling Price',
                          '\$${item['sellingPrice']}/unit',
                          Icons.sell,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: profitColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Profit/Loss: ',
                                style: TextStyle(
                                  color:
                                      _colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                '\$${(double.tryParse(item['profit'].toString()) ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: profitColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: _colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
