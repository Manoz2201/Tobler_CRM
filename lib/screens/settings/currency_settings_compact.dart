import 'package:flutter/material.dart';

class CurrencySettingsCompact extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onCurrencyChanged;

  const CurrencySettingsCompact({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  State<CurrencySettingsCompact> createState() =>
      _CurrencySettingsCompactState();
}

class _CurrencySettingsCompactState extends State<CurrencySettingsCompact> {
  late String _selectedCurrency;
  final Map<String, String> _currencySymbols = const {
    'INR': '₹',
    'USD': ' 4',
    'EUR': '€',
    'CHF': 'CHF ',
    'GBP': '£',
  };

  final Map<String, double> _exchangeRatesFromINR = const {
    'USD': 0.012,
    'EUR': 0.011,
    'CHF': 0.00923,
    'GBP': 0.009,
  };

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Currency Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Current currency card
              _buildCurrentCurrencyCard(),
              const SizedBox(height: 12),

              // Quick pick currencies grid
              Text(
                'Quick Pick',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              _buildCurrencyGrid(),

              const SizedBox(height: 12),
              _buildExchangeRatesCard(),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onCurrencyChanged(_selectedCurrency);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCurrencyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currencySymbols[_selectedCurrency] ?? '₹',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCurrency,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getCurrencyName(_selectedCurrency),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.blue, size: 18),
        ],
      ),
    );
  }

  Widget _buildCurrencyGrid() {
    final quickCurrencies = const ['INR', 'USD', 'EUR', 'CHF', 'GBP'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: quickCurrencies.map((code) {
        final isSelected = _selectedCurrency == code;
        return GestureDetector(
          onTap: () => setState(() => _selectedCurrency = code),
          child: Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600] : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currencySymbols[code] ?? code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExchangeRatesCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exchange Rates (1 INR)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ..._exchangeRatesFromINR.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _currencySymbols[e.key] ?? e.key,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Text(e.key, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  Text(
                    e.value.toStringAsFixed(4),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getCurrencyName(String code) {
    const names = {
      'INR': 'Indian Rupee',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'CHF': 'Swiss Franc',
      'GBP': 'British Pound',
    };
    return names[code] ?? code;
  }
}
