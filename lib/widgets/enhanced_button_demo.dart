import 'package:flutter/material.dart';
import 'enhanced_floating_button.dart';

/// Demo widget to showcase the EnhancedFloatingButton functionality
class EnhancedButtonDemo extends StatelessWidget {
  const EnhancedButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Button Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enhanced Floating Button Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Hover over or tap the buttons to see the effects:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Row of different button types
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Currency button
                EnhancedFloatingButton(
                  icon: Icons.attach_money,
                  label: 'Currency Settings',
                  color: Colors.blue,
                  size: 64,
                  iconSize: 28,
                  onTap: () =>
                      _showSnackBar(context, 'Currency Settings tapped!'),
                ),

                const SizedBox(width: 24),

                // Time Period button
                EnhancedFloatingButton(
                  icon: Icons.schedule,
                  label: 'Time Period',
                  color: Colors.green,
                  size: 64,
                  iconSize: 28,
                  onTap: () => _showSnackBar(context, 'Time Period tapped!'),
                ),

                const SizedBox(width: 24),

                // Notifications button with badge
                EnhancedFloatingButton(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  color: Colors.orange,
                  size: 64,
                  iconSize: 28,
                  hasBadge: true,
                  onTap: () => _showSnackBar(context, 'Notifications tapped!'),
                ),

                const SizedBox(width: 24),

                // Chat button with badge
                EnhancedFloatingButton(
                  icon: Icons.chat,
                  label: 'Chat & Messages',
                  color: Colors.purple,
                  size: 64,
                  iconSize: 28,
                  hasBadge: true,
                  onTap: () => _showSnackBar(context, 'Chat tapped!'),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Different sizes demonstration
            const Text(
              'Different Sizes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EnhancedFloatingButton(
                  icon: Icons.star,
                  label: 'Small (36px)',
                  color: Colors.amber,
                  size: 36,
                  iconSize: 16,
                  onTap: () => _showSnackBar(context, 'Small button tapped!'),
                ),

                const SizedBox(width: 16),

                EnhancedFloatingButton(
                  icon: Icons.star,
                  label: 'Medium (48px)',
                  color: Colors.amber,
                  size: 48,
                  iconSize: 20,
                  onTap: () => _showSnackBar(context, 'Medium button tapped!'),
                ),

                const SizedBox(width: 16),

                EnhancedFloatingButton(
                  icon: Icons.star,
                  label: 'Large (64px)',
                  color: Colors.amber,
                  size: 64,
                  iconSize: 28,
                  onTap: () => _showSnackBar(context, 'Large button tapped!'),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                children: [
                  Text(
                    'Features Demonstrated:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Hover effects with enhanced shadows\n'
                    '• 6px floating animation on hover/tap\n'
                    '• Contextual tooltips\n'
                    '• Touch support for mobile devices\n'
                    '• Badge support for notifications\n'
                    '• Configurable sizes and colors',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
