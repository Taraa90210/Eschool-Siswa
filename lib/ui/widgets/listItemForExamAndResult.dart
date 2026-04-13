import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ListItemForExamAndResult extends StatefulWidget {
  final String examStartingDate;
  final String examName;
  final int index;
  final String examDescription;
  final String resultGrade;
  final int examStatus;
  final double resultPercentage;
  final VoidCallback onItemTap;

  const ListItemForExamAndResult({
    Key? key,
    required this.examStartingDate,
    required this.examName,
    required this.examDescription,
    required this.resultGrade,
    required this.resultPercentage,
    required this.onItemTap,
    required this.index,
    this.examStatus = 0,
  }) : super(key: key);

  @override
  State<ListItemForExamAndResult> createState() =>
      _ListItemForExamAndResultState();
}

class _ListItemForExamAndResultState extends State<ListItemForExamAndResult>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isparent = context.read<AuthCubit>().isParent();
    DateTime? startDate = widget.examStartingDate.isNotEmpty
        ? DateTime.parse(widget.examStartingDate)
        : null;
    String formattedStartDate = startDate != null
        ? DateFormat('dd MMM yyyy', 'id').format(startDate)
        : "N/A";

    // Get primary color from theme
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withValues(alpha: 0.9),
        primaryColor.withValues(alpha: 0.8),
      ],
    );

    // Determine status text based on examStatus
    String statusText = "";

    if (widget.examStatus == 1) {
      statusText = Utils.getTranslatedLabel(onGoingKey);
    }

    if (widget.examStatus == 0) {
      statusText = Utils.getTranslatedLabel(upComingKey);
    }

    if (widget.examStatus == 2) {
      statusText = Utils.getTranslatedLabel(completedKey);
    }

    // else {
    //   if (startDate != null) {
    //     if (now.year == startDate.year &&
    //     now.month == startDate.month &&
    //     now.day == startDate.day) {
    //       statusText = Utils.getTranslatedLabel(todayKey);
    //     } else if (now.isBefore(startDate)) {
    //       statusText = Utils.getTranslatedLabel(commingSoonKey);
    //     } else if (now.isAfter(startDate)) {
    //       statusText = Utils.getTranslatedLabel(completedKey);
    //     }
    //   } else {
    //     statusText = Utils.getTranslatedLabel(notAvailableKey);
    //   }
    // }

    return Animate(
      effects: listItemAppearanceEffects(itemIndex: widget.index),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _isHovering = true;
                    _animationController.forward();
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isHovering = false;
                    _animationController.reverse();
                  });
                },
                child: GestureDetector(
                  onTap: widget.onItemTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovering
                              ? primaryColor.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: _isHovering ? 15 : 10,
                          spreadRadius: _isHovering ? 1 : 0,
                          offset: Offset(0, _isHovering ? 6 : 4),
                        ),
                      ],
                      border: Border.all(
                        color: _isHovering
                            ? primaryColor.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with gradient background
                        Container(
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14.5),
                              topRight: Radius.circular(14.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  Utils.getTranslatedLabel(
                                      widget.examStatus == 1
                                          ? resultKey
                                          : examsKey),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Status indicator
                              isparent
                                  ? const SizedBox()
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          width: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(
                                                alpha: 0.1),
                                            blurRadius: 3,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Status indicator dot
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                                begin: 0.7,
                                                end: statusText ==
                                                        Utils
                                                            .getTranslatedLabel(
                                                                onGoingKey)
                                                    ? 1.0
                                                    : 0.7),
                                            duration: const Duration(
                                                milliseconds: 1000),
                                            curve: Curves.easeInOut,
                                            builder: (context, value, _) {
                                              return Container(
                                                width: 6,
                                                height: 6,
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      _getPositiveStatusColor(
                                                          statusText,
                                                          primaryColor),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          _getPositiveStatusColor(
                                                                  statusText,
                                                                  primaryColor)
                                                              .withValues(
                                                                  alpha: value *
                                                                      0.5),
                                                      blurRadius: value * 4,
                                                      spreadRadius: value * 1,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          Text(
                                            statusText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        // Content area
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exam name
                              Text(
                                widget.examName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E2E2E),
                                  height: 1.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),

                              if (widget.examDescription.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  widget.examDescription,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: _isExpanded ? null : 2,
                                  overflow: _isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                if (widget.examDescription.length > 80)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      _isExpanded
                                          ? "Baca lebih sedikit"
                                          : "Baca lebih banyak",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 20),

                              // Divider
                              Container(
                                height: 1,
                                color: Colors.grey.withValues(alpha: 0.15),
                                margin: const EdgeInsets.only(bottom: 16),
                              ),

                              // Information row
                              Row(
                                children: [
                                  // First column - Date info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Utils.getTranslatedLabel(dateKey),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formattedStartDate,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      ],
                                    ),
                                  ),

                                  // Second column - Result information
                                  if (widget.resultPercentage > 0 ||
                                      widget.resultGrade.isNotEmpty)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            Utils.getTranslatedLabel(
                                                widget.resultGrade.isNotEmpty
                                                    ? gradeKey
                                                    : percentageKey),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            widget.resultGrade.isNotEmpty
                                                ? widget.resultGrade
                                                : "${widget.resultPercentage}%",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              // Progress bar for result percentage
                              if (widget.resultPercentage > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            Utils.getTranslatedLabel(
                                                percentageKey),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "${widget.resultPercentage}%",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _getProgressColor(
                                                  widget.resultPercentage),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Animated progress bar
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                            begin: 0,
                                            end: widget.resultPercentage / 100),
                                        duration:
                                            const Duration(milliseconds: 800),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, _) {
                                          return Stack(
                                            children: [
                                              // Background
                                              Container(
                                                height: 8,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                              // Progress
                                              Container(
                                                height: 8,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    value *
                                                    0.7,
                                                decoration: BoxDecoration(
                                                  color: _getProgressColor(
                                                      widget.resultPercentage),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _getProgressColor(
                                                              widget
                                                                  .resultPercentage)
                                                          .withValues(
                                                              alpha: 0.4),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Bottom action bar - only show if not completed
                        if (widget.examStatus != 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(14.5),
                                bottomRight: Radius.circular(14.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedOpacity(
                                  opacity: _isHovering ? 1.0 : 0.6,
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    Utils.getTranslatedLabel(viewDetailKey),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: primaryColor,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper function to determine progress color based on percentage
  Color _getProgressColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.lightGreen;
    } else if (percentage >= 40) {
      return Colors.orange;
    } else {
      return Colors.redAccent;
    }
  }

  // Helper function to determine positive status color
  Color _getPositiveStatusColor(String statusText, Color primaryColor) {
    if (statusText == Utils.getTranslatedLabel(onGoingKey)) {
      return Colors.blue;
    } else if (statusText == Utils.getTranslatedLabel(commingSoonKey)) {
      return Colors.yellow;
    } else if (statusText == Utils.getTranslatedLabel(completedKey)) {
      return Colors.green;
    } else {
      return Colors.white;
    }
  }
}
