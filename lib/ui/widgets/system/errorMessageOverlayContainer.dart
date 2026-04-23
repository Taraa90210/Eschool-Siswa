import 'package:eschool/utils/system/constants.dart';
import 'package:flutter/material.dart';

class ErrorMessageOverlayContainer extends StatefulWidget {
  final String errorMessage;
  final Color backgroundColor;
  final IconData? icon;
  const ErrorMessageOverlayContainer({
    Key? key,
    required this.errorMessage,
    required this.backgroundColor,
    this.icon,
  }) : super(key: key);

  @override
  State<ErrorMessageOverlayContainer> createState() =>
      _ErrorMessageOverlayContainerState();
}

class _ErrorMessageOverlayContainerState
    extends State<ErrorMessageOverlayContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))
    ..forward();

  late Animation<double> slideAnimation =
      Tween<double>(begin: -0.5, end: 1.0).animate(
    CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCirc,
    ),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(
        Duration(
          milliseconds: errorMessageDisplayDuration.inMilliseconds - 500,
        ), () {
      animationController.reverse();
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, child) {
        return PositionedDirectional(
          start: MediaQuery.of(context).size.width * (0.05),
          bottom: MediaQuery.of(context).size.height *
              (0.075) *
              (slideAnimation.value),
          child: Opacity(
            opacity: slideAnimation.value < 0.0 ? 0.0 : slideAnimation.value,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: MediaQuery.of(context).size.width * (0.9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, 
                  vertical: 14.0
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    if (widget.icon != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    if (widget.icon != null) const SizedBox(width: 12),
                    
                    // Message
                    Expanded(
                      child: Text(
                        widget.errorMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
