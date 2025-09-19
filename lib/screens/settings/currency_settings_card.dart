import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencySettingsCard extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onClose;
  final GlobalKey targetKey;

  const CurrencySettingsCard({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
    required this.onClose,
    required this.targetKey,
  });

  @override
  State<CurrencySettingsCard> createState() => _CurrencySettingsCardState();
}

class _CurrencySettingsCardState extends State<CurrencySettingsCard>
    with SingleTickerProviderStateMixin {
  late String _selectedCurrency;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String> _currencySymbols = const {
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

  final Map<String, double> _exchangeRatesFromINR = {
    'USD': 0.012,
    'EUR': 0.011,
    'CHF': 0.00923,
    'GBP': 0.009,
    'CAD': 0.016,
    'AUD': 0.018,
    'JPY': 1.78,
    'CNY': 0.086,
    'SGD': 0.016,
  };

  final Map<String, TextEditingController> _rateControllers = {};
  final Map<String, bool> _isEditingRate = {};
  final GlobalKey _exchangeSectionKey = GlobalKey();

  // Display settings state
  bool _numberFormatting = true;
  bool _autoUpdateRates = true;
  bool _rateAlerts = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.1, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Test positioning after animation starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testPositioning();
    });

    // Initialize controllers and load any saved custom rates
    _initializeRateControllers();
    _loadCustomRates();
  }

  @override
  void dispose() {
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _initializeRateControllers() {
    _rateControllers.clear();
    _exchangeRatesFromINR.forEach((code, rate) {
      _rateControllers[code] = TextEditingController(text: rate.toString());
      _isEditingRate[code] = false;
    });
  }

  Future<void> _loadCustomRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('custom_exchange_rates_v1');
      if (jsonString == null || jsonString.isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      decoded.forEach((code, value) {
        final parsed = (value is num)
            ? value.toDouble()
            : double.tryParse(value.toString());
        if (parsed != null && _exchangeRatesFromINR.containsKey(code)) {
          _exchangeRatesFromINR[code] = parsed;
        }
      });
      // Update controllers with loaded values
      _exchangeRatesFromINR.forEach((code, rate) {
        _rateControllers[code]?.text = rate.toString();
      });
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load custom exchange rates: $e');
    }
  }

  Future<void> _saveCustomRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'custom_exchange_rates_v1',
        jsonEncode(_exchangeRatesFromINR),
      );
    } catch (e) {
      debugPrint('Failed to save custom exchange rates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _getCardPosition();

    return Positioned(
      top: position.dy,
      left: position.dx,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Main card
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) =>
                    _handleTapOutsideExchangeSection(details.globalPosition),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 380,
                    height: 500, // Fixed height to enable scrolling
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header section
                        _buildHeader(),

                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                // Current currency section
                                _buildCurrentCurrencySection(),

                                // Quick pick currencies
                                _buildQuickPickSection(),

                                // Exchange rates section
                                _buildExchangeRatesSection(),

                                // Display settings section
                                _buildDisplaySettingsSection(),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            child: _buildApplyButton(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Arrow pointing to the button (positioned on the right edge)
              Positioned(
                right: -10, // Position outside the card
                top: _getArrowPosition(),
                child: _buildArrow(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: CustomPaint(size: const Size(20, 20), painter: ArrowPainter()),
    );
  }

  double _getArrowPosition() {
    // Position arrow at the center of the card
    return 250.0; // Half of the 500px card height
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.attach_money, color: Colors.blue[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Set Currency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCurrencySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currencySymbols[_selectedCurrency] ?? '₹',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCurrency,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCurrencyName(_selectedCurrency),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.blue[600], size: 24),
        ],
      ),
    );
  }

  Widget _buildQuickPickSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Pick',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                const [
                  'INR',
                  'USD',
                  'EUR',
                  'CHF',
                  'GBP',
                  'CAD',
                  'AUD',
                  'JPY',
                  'CNY',
                  'SGD',
                ].map((code) {
                  return _buildCurrencyButton(code);
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyButton(String code) {
    final isSelected = _selectedCurrency == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = code),
      child: Container(
        width: 65,
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRatesSection() {
    return Container(
      key: _exchangeSectionKey,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(16),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ..._exchangeRatesFromINR.entries.map((e) {
            final code = e.key;
            final controller = _rateControllers[code]!;
            final isEditing = _isEditingRate[code] ?? false;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Row(
                      children: [
                        Text(
                          _currencySymbols[code] ?? code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          code,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: isEditing
                        ? TextField(
                            controller: controller,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: '0.0000',
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null) {
                                _exchangeRatesFromINR[code] = parsed;
                              }
                            },
                            onEditingComplete: () {
                              _saveCustomRates();
                              setState(() {
                                _isEditingRate[code] = false;
                              });
                            },
                            onSubmitted: (_) {
                              _saveCustomRates();
                              setState(() {
                                _isEditingRate[code] = false;
                              });
                            },
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditingRate[code] = true;
                              });
                              // Select all for quick overwrite
                              controller.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: controller.text.length,
                              );
                            },
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                (_exchangeRatesFromINR[code] ?? 0)
                                    .toStringAsFixed(4),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
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

  void _handleTapOutsideExchangeSection(Offset globalPosition) {
    try {
      final ctx = _exchangeSectionKey.currentContext;
      if (ctx == null) return;
      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
      if (!rect.contains(globalPosition)) {
        // Clicked outside exchange section: end editing
        FocusScope.of(ctx).unfocus();
        setState(() {
          for (final key in _isEditingRate.keys.toList()) {
            _isEditingRate[key] = false;
          }
        });
      }
    } catch (_) {}
  }

  Widget _buildDisplaySettingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display Settings',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            icon: Icons.format_list_numbered,
            title: 'Number Formatting',
            subtitle: 'K, M, B, T suffixes',
            value: _numberFormatting,
            onChanged: (value) {
              setState(() {
                _numberFormatting = value;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildSettingRow(
            icon: Icons.update,
            title: 'Auto Update Rates',
            subtitle: 'Update rates every hour',
            value: _autoUpdateRates,
            onChanged: (value) {
              setState(() {
                _autoUpdateRates = value;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildSettingRow(
            icon: Icons.notifications,
            title: 'Rate Alerts',
            subtitle: 'Notify on significant changes',
            value: _rateAlerts,
            onChanged: (value) {
              setState(() {
                _rateAlerts = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.blue[600],
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onCurrencyChanged(_selectedCurrency);
          widget.onClose();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: const Text(
          'Apply Changes',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  Offset _getCardPosition() {
    try {
      final RenderBox? targetRender =
          widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (targetRender == null) return const Offset(0, 0);

      final targetPos = targetRender.localToGlobal(Offset.zero);
      final targetSize = targetRender.size;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      // Position card to the left of the button with proper spacing
      final cardWidth = 380.0;
      final cardHeight = 500.0;
      final buttonHeight = targetSize.height;

      // Detect if this is desktop or tablet layout (width > 600px)
      final isDesktopOrTablet = screenWidth > 600;

      double left;
      double top;

      if (isDesktopOrTablet) {
        // For desktop and tablet: position card 505px left from right edge
        left = screenWidth - cardWidth - 505;
        top = targetPos.dy - (cardHeight / 2) + (buttonHeight / 2);

        // Debug logging for desktop/tablet layout
        debugPrint('Currency Card Positioning Debug (Desktop/Tablet):');
        debugPrint('  Screen width: $screenWidth');
        debugPrint('  Positioned 505px left from right edge');
        debugPrint('  Calculated left: $left');
        debugPrint('  Calculated top: $top');
      } else {
        // For mobile: use original positioning logic
        // Calculate position - card should be to the left with arrow pointing to button
        // Ensure card is fully visible on screen with extra 80px shift from right edge
        left =
            targetPos.dx -
            cardWidth -
            105; // 105px gap (25px original + 80px shift)
        top =
            targetPos.dy -
            (cardHeight / 2) +
            (buttonHeight / 2) +
            50; // 50px shift down from top

        // Debug logging for mobile layout
        debugPrint('Currency Card Positioning Debug (Mobile):');
        debugPrint('  Button position: (${targetPos.dx}, ${targetPos.dy})');
        debugPrint('  Screen width: $screenWidth');
        debugPrint('  Calculated left: $left');
        debugPrint('  Calculated top: $top');
      }

      // Ensure card doesn't go off-screen on left side
      final adjustedLeft = left < 20 ? 20.0 : left;

      // Ensure card doesn't go off-screen on right side, then shift 150px right
      final maxLeft = screenWidth - cardWidth - 20;
      final shiftedLeft = adjustedLeft + 150.0;
      final finalLeft = shiftedLeft > maxLeft ? maxLeft : shiftedLeft;

      // Ensure card doesn't go off-screen on top/bottom
      final adjustedTop = top < 50
          ? 50.0
          : (top > screenHeight - cardHeight - 50
                ? screenHeight - cardHeight - 50
                : top);

      // Debug logging for final position
      debugPrint('  Final position: ($finalLeft, $adjustedTop)');
      debugPrint('  Max left allowed: $maxLeft');
      debugPrint('  Card dimensions: ${cardWidth}x$cardHeight');

      return Offset(finalLeft, adjustedTop);
    } catch (e) {
      // Fallback position - center of screen
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      return Offset((screenWidth - 380) / 2, (screenHeight - 500) / 2);
    }
  }

  // Test method to verify positioning
  void _testPositioning() {
    final position = _getCardPosition();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth > 600;

    debugPrint('Test Position: (${position.dx}, ${position.dy})');
    debugPrint(
      'Layout Type: ${isDesktopOrTablet ? "Desktop/Tablet" : "Mobile"}',
    );
    debugPrint('Screen Width: $screenWidth');

    // Verify card is within screen bounds
    final screenHeight = MediaQuery.of(context).size.height;

    final isLeftVisible = position.dx >= 0;
    final isRightVisible = position.dx + 380 <= screenWidth;
    final isTopVisible = position.dy >= 0;
    final isBottomVisible = position.dy + 500 <= screenHeight;

    debugPrint('Visibility Check:');
    debugPrint('  Left visible: $isLeftVisible');
    debugPrint('  Right visible: $isRightVisible');
    debugPrint('  Top visible: $isTopVisible');
    debugPrint('  Bottom visible: $isBottomVisible');

    if (isDesktopOrTablet) {
      final distanceFromRight = screenWidth - (position.dx + 380);
      debugPrint(
        '  Distance from right edge: ${distanceFromRight}px (Target: 505px)',
      );
    }
  }

  String _getCurrencyName(String code) {
    const names = {
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

// Custom painter for the arrow
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    // Create a triangle arrow pointing to the right
    final centerY = size.height / 2;

    path.moveTo(4, centerY - 6); // Top left
    path.lineTo(size.width - 4, centerY); // Right point
    path.lineTo(4, centerY + 6); // Bottom left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
