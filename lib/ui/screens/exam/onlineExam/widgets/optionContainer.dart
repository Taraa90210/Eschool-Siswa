import 'package:flutter/material.dart';
import 'package:eschool/data/models/exam/answerOption.dart';
import 'package:eschool/data/models/exam/question.dart';

class OptionContainer extends StatefulWidget {
  final Function(Question, AnswerOption) submitAnswer;
  final Question question;
  final AnswerOption answerOption;
  final BoxConstraints constraints;
  final String? choice;
  final int submittedAnswerIds;
  final double fontScale;
  final String fontFamily;

  const OptionContainer({
    Key? key,
    this.choice,
    required this.constraints,
    required this.submitAnswer,
    required this.question,
    required this.answerOption,
    required this.submittedAnswerIds,
    required this.fontScale,
    required this.fontFamily,
  }) : super(key: key);

  @override
  State<OptionContainer> createState() => _OptionContainerState();
}

class _OptionContainerState extends State<OptionContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.submitAnswer(widget.question, widget.answerOption);
    _animationController.forward().then((_) => _animationController.reverse());
  }

  Color _getBackgroundColor() {
    return widget.submittedAnswerIds == widget.answerOption.id
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade100;
  }

  Color _getTextColor() {
    return widget.submittedAnswerIds == widget.answerOption.id
        ? Colors.white
        : Colors.black.withValues(alpha: 0.9);
  }

  Color _getBorderColor() {
    return widget.submittedAnswerIds == widget.answerOption.id
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.9)
        : Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final double badgeSize = (28 + 8 * widget.fontScale).clamp(30.0, 48.0);
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: widget.submittedAnswerIds == widget.answerOption.id
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            width: widget.constraints.maxWidth,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getBorderColor(),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 15), // Padding lebih besar
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Choice Badge
                  if (widget.choice != null) ...[
                    Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.submittedAnswerIds ==
                                  widget.answerOption.id
                              ? [Colors.white, Colors.white.withValues(alpha: 0.9)]
                              : [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.8),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown, // turun kalau kepanjangan
                          child: Text(
                            widget.choice!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.submittedAnswerIds ==
                                      widget.answerOption.id
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize:
                                  badgeSize * 0.6, // proporsional terhadap box
                              height: 1.0, // rapikan vertical metrics
                              letterSpacing: 0.2, // sedikit spasi biar crisp
                              fontFamily: widget.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Option Text
                  Expanded(
                    child: Text(
                      widget.answerOption.option ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 16 * widget.fontScale,
                        fontFamily: widget.fontFamily,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  // Selection Indicator
                  if (widget.submittedAnswerIds == widget.answerOption.id)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
