import 'package:flutter/material.dart';

/// Enhanced floating button with hover effects, tooltips, and floating animation
class EnhancedFloatingButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool hasBadge;
  final double size;
  final double iconSize;

  const EnhancedFloatingButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.hasBadge = false,
    this.size = 36,
    this.iconSize = 16,
  });

  @override
  State<EnhancedFloatingButton> createState() => _EnhancedFloatingButtonState();
}

class _EnhancedFloatingButtonState extends State<EnhancedFloatingButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAnimation() {
    if (_isHovered || _isPressed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _updateAnimation();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _updateAnimation();
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
          _updateAnimation();
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
          _updateAnimation();
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
          _updateAnimation();
        },
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Tooltip(
                message: widget.label,
                preferBelow: false,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(
                          alpha: (_isHovered || _isPressed) ? 0.5 : 0.3,
                        ),
                        blurRadius: (_isHovered || _isPressed) ? 12 : 8,
                        offset: Offset(0, (_isHovered || _isPressed) ? 6 : 4),
                        spreadRadius: (_isHovered || _isPressed) ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: IconButton(
                          onPressed: widget.onTap,
                          icon: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: widget.iconSize,
                          ),
                          iconSize: widget.iconSize,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (widget.hasBadge)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
