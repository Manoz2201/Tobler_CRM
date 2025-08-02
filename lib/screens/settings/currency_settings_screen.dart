import 'package:flutter/material.dart';

class CurrencySettingsScreen extends StatefulWidget {
  final String currentCurrency;
  final Function(String) onCurrencyChanged;

  const CurrencySettingsScreen({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _selectedCurrency = 'INR';
  bool _isLoading = false;
  Map<String, double> _exchangeRates = {};
  final Map<String, String> _currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'CHF': 'CHF ',
    'GBP': '£',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'JPY': '¥',
    'CNY': '¥',
    'SGD': 'S\$',
  };

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate fetching exchange rates from an API
      // In a real app, you would fetch from a currency API like Fixer.io
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _exchangeRates = {
          'USD': 0.012,
          'EUR': 0.011,
          'CHF': 0.010,
          'GBP': 0.009,
          'CAD': 0.016,
          'AUD': 0.018,
          'JPY': 1.78,
          'CNY': 0.086,
          'SGD': 0.016,
        };
      });
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Settings'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading exchange rates...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Currency Section
                  _buildSectionHeader('Current Currency'),
                  SizedBox(height: 16),
                  _buildCurrentCurrencyCard(),
                  SizedBox(height: 24),

                  // Available Currencies Section
                  _buildSectionHeader('Available Currencies'),
                  SizedBox(height: 16),
                  _buildCurrencyList(),
                  SizedBox(height: 24),

                  // Exchange Rates Section
                  _buildSectionHeader('Exchange Rates (1 INR)'),
                  SizedBox(height: 16),
                  _buildExchangeRatesCard(),
                  SizedBox(height: 24),

                  // Settings Section
                  _buildSectionHeader('Display Settings'),
                  SizedBox(height: 16),
                  _buildDisplaySettings(),
                  SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onCurrencyChanged(_selectedCurrency);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Currency updated to $_selectedCurrency'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildCurrentCurrencyCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currencySymbols[_selectedCurrency] ?? '₹',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCurrency,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getCurrencyName(_selectedCurrency),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.blue[600],
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyList() {
    final currencies = [
      {'code': 'INR', 'name': 'Indian Rupee'},
      {'code': 'USD', 'name': 'US Dollar'},
      {'code': 'EUR', 'name': 'Euro'},
      {'code': 'CHF', 'name': 'Swiss Franc'},
      {'code': 'GBP', 'name': 'British Pound'},
      {'code': 'CAD', 'name': 'Canadian Dollar'},
      {'code': 'AUD', 'name': 'Australian Dollar'},
      {'code': 'JPY', 'name': 'Japanese Yen'},
      {'code': 'CNY', 'name': 'Chinese Yuan'},
      {'code': 'SGD', 'name': 'Singapore Dollar'},
    ];

    return Column(
      children: currencies.map((currency) {
        final isSelected = _selectedCurrency == currency['code'];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _currencySymbols[currency['code']] ?? '₹',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue[700] : Colors.grey[700],
                ),
              ),
            ),
            title: Text(
              currency['code']!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue[700] : Colors.grey[800],
              ),
            ),
            subtitle: Text(
              currency['name']!,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Colors.blue[600],
                  )
                : null,
            onTap: () {
              setState(() {
                _selectedCurrency = currency['code']!;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExchangeRatesCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: _exchangeRates.entries.map((entry) {
          final currency = entry.key;
          final rate = entry.value;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _currencySymbols[currency] ?? currency,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      currency,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  rate.toStringAsFixed(4),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisplaySettings() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.format_list_numbered, color: Colors.blue[600]),
            title: Text('Number Formatting'),
            subtitle: Text('K, M, B, T suffixes'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Handle number formatting toggle
              },
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.update, color: Colors.blue[600]),
            title: Text('Auto Update Rates'),
            subtitle: Text('Update rates every hour'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Handle auto update toggle
              },
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications, color: Colors.blue[600]),
            title: Text('Rate Alerts'),
            subtitle: Text('Notify on significant changes'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Handle rate alerts toggle
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getCurrencyName(String code) {
    final names = {
      'INR': 'Indian Rupee',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'CHF': 'Swiss Franc',
      'GBP': 'British Pound',
      'CAD': 'Canadian Dollar',
      'AUD': 'Australian Dollar',
      'JPY': 'Japanese Yen',
      'CNY': 'Chinese Yuan',
      'SGD': 'Singapore Dollar',
    };
    return names[code] ?? code;
  }
} 