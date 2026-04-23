import 'dart:math';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

class ScreenTopBackgroundContainer extends StatelessWidget {
  final Widget? child;
  final double? heightPercentage;
  final EdgeInsets? padding;
  const ScreenTopBackgroundContainer({
    Key? key,
    this.child,
    this.heightPercentage,
    this.padding,
  }) : super(key: key);

  // Decorative elements with simpler implementation
  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildDecorativeSquare(double size, Color color) {
    return Transform.rotate(
      angle: 0.3, // Slight rotation for visual interest
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 4),
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).colorScheme.primary;
    final containerHeight = MediaQuery.of(context).size.height *
        (heightPercentage ?? Utils.appBarBiggerHeightPercentage);

    return Stack(children: [
      // Add solid white background container first
      Container(
        width: MediaQuery.of(context).size.width,
        height: containerHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      Container(
        alignment: Alignment.topCenter,
        width: MediaQuery.of(context).size.width,
        height: containerHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(
                  alpha: 0.9), // Exactly 0.9 opacity as requested
              primaryColor.withValues(
                  alpha: 0.8), // Exactly 0.8 opacity as requested
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Enhanced decorative elements
            _buildDecorations(context, primaryColor, containerHeight),

            // Content overlay
            if (child != null)
              Positioned.fill(
                child: Padding(
                  padding: padding ??
                      EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top +
                            Utils.screenContentTopPadding,
                      ),
                  child: child!,
                ),
              ),
          ],
        ),
      )
    ]);
  }

  // Enhanced decorations method
  Widget _buildDecorations(
      BuildContext context, Color primaryColor, double containerHeight) {
    return Stack(
      children: [
        // Decorative circles and shapes
        Positioned(
          top: -20,
          left: -20,
          child:
              _buildDecorativeCircle(100, Colors.white.withValues(alpha: 0.05)),
        ),
        Positioned(
          top: 60,
          left: 130,
          child:
              _buildDecorativeCircle(30, Colors.white.withValues(alpha: 0.08)),
        ),
        Positioned(
          bottom: 15,
          right: 20,
          child:
              _buildDecorativeSquare(40, Colors.white.withValues(alpha: 0.05)),
        ),

        // Education themed icons (if we have enough height)

        // Floating particles for subtle animation
        ..._generateFloatingParticles(containerHeight),
      ],
    );
  }

  // Generate floating particles for subtle animation
  List<Widget> _generateFloatingParticles(double containerHeight) {
    final random = Random(42); // Fixed seed for consistent pattern
    final int particleCount = containerHeight > 120 ? 8 : 4;

    return List.generate(particleCount, (index) {
      final top = random.nextDouble() * containerHeight * 0.7;
      final left = random.nextDouble() * 350;
      final size = random.nextDouble() * 2.5 + 1.5; // Size between 1.5-4

      return Positioned(
        top: top,
        left: left,
        child: _FloatingParticle(
          size: size,
          color:
              Colors.white.withValues(alpha: 0.4 + random.nextDouble() * 0.3),
        ),
      );
    });
  }
}

// Simple animated floating particle
class _FloatingParticle extends StatefulWidget {
  final double size;
  final Color color;

  const _FloatingParticle({
    required this.size,
    required this.color,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + (widget.size * 500).toInt()),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Opacity(
          opacity: 0.4 + (_controller.value * 0.6),
          child: Transform.translate(
            offset: Offset(
              sin(_controller.value * pi * 2) * 3,
              -_controller.value * 5,
            ),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: widget.size * 1.5,
                    spreadRadius: widget.size / 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
