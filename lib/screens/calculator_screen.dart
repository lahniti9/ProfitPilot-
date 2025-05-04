import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController investmentController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();

  String result = "";
  final formKey = GlobalKey<FormState>();
  bool _saveToHistory = true;
  bool _showResult = false;
  double _profit = 0;

  // Material 3 color scheme
  final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  );

  Future<void> calculateProfit() async {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // Close keyboard

    final double investment = double.tryParse(investmentController.text) ?? 0;
    final double purchasePrice =
        double.tryParse(purchasePriceController.text) ?? 0;
    final double sellingPrice =
        double.tryParse(sellingPriceController.text) ?? 0;

    if (investment > 0 && purchasePrice > 0 && sellingPrice > 0) {
      double units = investment / purchasePrice;
      double sellingValue = units * sellingPrice;
      double profit = sellingValue - investment;
      double profitPercentage = (profit / investment) * 100;
      _profit = profit;

      setState(() {
        result = '''
        Units Purchased: ${units.toStringAsFixed(2)}
        Sale Value: \$${sellingValue.toStringAsFixed(2)}
        Profit/Loss: \$${profit.toStringAsFixed(2)} (${profitPercentage.toStringAsFixed(2)}%)
        ''';
        _showResult = true;
      });

      if (_saveToHistory) {
        await saveToHistory(
          investment: investment,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          units: units,
          profit: profit,
        );
      }
    }
  }

  Future<void> saveToHistory({
    required double investment,
    required double purchasePrice,
    required double sellingPrice,
    required double units,
    required double profit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final String timestamp = formatter.format(now);

    final historyItem = {
      'timestamp': timestamp,
      'investment': investment,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'units': units,
      'profit': profit,
    };

    final List<String> history = prefs.getStringList('profit_history') ?? [];
    history.add(historyItem.toString());
    await prefs.setStringList('profit_history', history);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calculation saved to history'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _resetCalculator() {
    setState(() {
      investmentController.clear();
      purchasePriceController.clear();
      sellingPriceController.clear();
      result = "";
      _showResult = false;
      _saveToHistory = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Calculator'),
        actions: [
          if (_showResult)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetCalculator,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with illustration
              Column(
                children: [
                  Icon(
                    Icons.calculate_rounded,
                    size: 64,
                    color: _colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculate Your Investment Profit',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),

              // Input fields with modern styling
              _buildInputField(
                controller: investmentController,
                label: "Investment Amount",
                icon: Icons.attach_money_rounded,
                isCurrency: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: purchasePriceController,
                label: "Purchase Price per Unit",
                icon: Icons.shopping_cart_rounded,
                isCurrency: true,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: sellingPriceController,
                label: "Selling Price per Unit",
                icon: Icons.sell_rounded,
                isCurrency: true,
              ),
              const SizedBox(height: 24),

              // Save to history toggle
              Row(
                children: [
                  Switch(
                    value: _saveToHistory,
                    onChanged: (value) {
                      setState(() {
                        _saveToHistory = value;
                      });
                    },
                    activeColor: _colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save to history',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calculate button
              FilledButton(
                onPressed: calculateProfit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _colorScheme.primary,
                  foregroundColor: _colorScheme.onPrimary,
                ),
                child: const Text(
                  "Calculate Profit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Results section with animation
              if (_showResult)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _buildResultCard(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isCurrency = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: isCurrency ? '\$ ' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _colorScheme.primary, width: 2)),
        floatingLabelStyle: TextStyle(color: _colorScheme.primary),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildResultCard() {
    final bool isProfit = _profit >= 0;
    final Color resultColor =
        isProfit ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProfit
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: resultColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  isProfit ? 'PROFIT' : 'LOSS',
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              result,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 16),
            if (!_saveToHistory)
              OutlinedButton(
                onPressed: () async {
                  await saveToHistory(
                    investment: double.parse(investmentController.text),
                    purchasePrice: double.parse(purchasePriceController.text),
                    sellingPrice: double.parse(sellingPriceController.text),
                    units: double.parse(investmentController.text) /
                        double.parse(purchasePriceController.text),
                    profit: _profit,
                  );
                  setState(() {
                    _saveToHistory = true;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _colorScheme.primary,
                  side: BorderSide(color: _colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save to History Now'),
              ),
          ],
        ),
      ),
    );
  }
}
