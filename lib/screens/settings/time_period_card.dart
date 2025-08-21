import 'package:flutter/material.dart';

class TimePeriodCard extends StatefulWidget {
  final String currentTimePeriod;
  final ValueChanged<String> onTimePeriodChanged;
  final VoidCallback onClose;
  final GlobalKey targetKey;

  const TimePeriodCard({
    super.key,
    required this.currentTimePeriod,
    required this.onTimePeriodChanged,
    required this.onClose,
    required this.targetKey,
  });

  @override
  State<TimePeriodCard> createState() => _TimePeriodCardState();
}

class _TimePeriodCardState extends State<TimePeriodCard>
    with SingleTickerProviderStateMixin {
  late String _selectedTimePeriod;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  DateTime _selectedDate = DateTime.now();

  final List<String> _timePeriods = [
    'Week',
    'Month',
    'Quarter',
    'Semester',
    'Annual',
    'Two Years',
    'Three Years',
    'Five Years',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimePeriod = widget.currentTimePeriod;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 380,
                  height: 500,
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
                              // Time period options section
                              _buildTimePeriodSection(),

                              // Calendar section
                              _buildCalendarSection(),

                              // Apply button
                              _buildApplyButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
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
            child: Icon(Icons.schedule, color: Colors.blue[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Time Period Settings',
              style: TextStyle(
                fontSize: 18,
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

  Widget _buildTimePeriodSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _timePeriods.map((period) {
              final isSelected = _selectedTimePeriod == period;
              return GestureDetector(
                onTap: () => setState(() => _selectedTimePeriod = period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[600] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Date Selection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected Date: ${_formatDate(_selectedDate)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onTimePeriodChanged(_selectedTimePeriod);
          widget.onClose();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: const Text(
          'Apply Changes',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
        // For desktop and tablet: position card 505px left from right edge (same as Currency Settings card)
        left = screenWidth - cardWidth - 505;
        top = targetPos.dy - (cardHeight / 2) + (buttonHeight / 2);

        // Debug logging for desktop/Tablet layout
        debugPrint('Time Period Card Positioning Debug (Desktop/Tablet):');
        debugPrint('  Screen width: $screenWidth');
        debugPrint(
          '  Positioned 505px left from right edge (same as Currency Settings card)',
        );
        debugPrint('  Calculated left: $left');
        debugPrint('  Calculated top: $top');
      } else {
        // For mobile: use same positioning logic
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
        debugPrint('Time Period Card Positioning Debug (Mobile):');
        debugPrint('  Button position: (${targetPos.dx}, ${targetPos.dy})');
        debugPrint('  Screen width: $screenWidth');
        debugPrint('  Calculated left: $left');
        debugPrint('  Calculated top: $top');
      }

      // Ensure card doesn't go off-screen on left side
      final adjustedLeft = left < 20 ? 20.0 : left;

      // Ensure card doesn't go off-screen on right side
      final maxLeft = screenWidth - cardWidth - 20;
      final finalLeft = adjustedLeft > maxLeft ? maxLeft : adjustedLeft;

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 6, size.height / 2 - 6);
    path.lineTo(size.width - 6, size.height / 2 + 6);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
