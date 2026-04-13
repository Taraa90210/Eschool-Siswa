import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ListItemForOnlineExamAndOnlineResult extends StatefulWidget {
  final bool isExamStarted;
  final String examStartingDate;
  final String examEndingDate;
  final String examName;
  final String subjectName;
  final String totalMarks;
  final bool isSubjectSelected;
  final String marks;
  final VoidCallback onItemTap;
  final bool isResult;
  final int statusUjian;

  const ListItemForOnlineExamAndOnlineResult({
    Key? key,
    required this.isExamStarted,
    required this.examStartingDate,
    required this.examEndingDate,
    required this.examName,
    required this.subjectName,
    required this.totalMarks,
    required this.isSubjectSelected,
    required this.marks,
    required this.onItemTap,
    this.isResult = false,
    required this.statusUjian,
  }) : super(key: key);

  @override
  State<ListItemForOnlineExamAndOnlineResult> createState() =>
      _ListItemForOnlineExamAndOnlineResultState();
}

class _ListItemForOnlineExamAndOnlineResultState
    extends State<ListItemForOnlineExamAndOnlineResult>
    with SingleTickerProviderStateMixin {
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
    DateTime? endDate = widget.examEndingDate.isNotEmpty
        ? DateTime.parse(widget.examEndingDate)
        : null;

    String formattedStartDate = startDate != null
        ? DateFormat('dd MMM yyyy', 'id').format(startDate)
        : "N/A";

    String duration = "";
    if (startDate != null && endDate != null) {
      final difference = endDate.difference(startDate);
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      duration =
          "${hours > 0 ? "${hours} ${Utils.getTranslatedLabel(hourKey)} " : ""}${minutes > 0 ? "${minutes} ${Utils.getTranslatedLabel(minuteKey)}" : ""}";
    }

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

    // Calculate percentage if marks is available
    double percentageValue = 0.0;
    if (widget.marks.isNotEmpty && widget.totalMarks.isNotEmpty) {
      try {
        double marksValue = double.parse(widget.marks);
        double totalMarksValue = double.parse(widget.totalMarks);
        if (totalMarksValue > 0) {
          percentageValue = (marksValue / totalMarksValue) * 100;
        }
      } catch (e) {
        // Handle parsing errors silently
      }
    }

    // Determine exam status text
    String statusText = "";
    DateTime now = DateTime.now();

    if (startDate != null && endDate != null) {
      if (now.isBefore(startDate)) {
        // Belum dimulai
        statusText = Utils.getTranslatedLabel(commingSoonKey);
      } else if (now.isAfter(endDate)) {
        // Sudah berakhir
        statusText = Utils.getTranslatedLabel(completedKey);
      } else {
        // Sedang berlangsung
        statusText = Utils.getTranslatedLabel(onGoingKey);
      }
    } else {
      statusText = Utils.getTranslatedLabel(notAvailableKey);
    }
    int status = widget.statusUjian;
    String statusUjianSiswa = "";

    if (status == 0) {
      statusUjianSiswa = Utils.getTranslatedLabel(notYetExamDoneKey);
    } else if (status == 1) {
      statusUjianSiswa = Utils.getTranslatedLabel(processExamKey);
    } else if (status == 2) {
      statusUjianSiswa = Utils.getTranslatedLabel(doneExamKey);
    } else if (status == 4) {
      statusUjianSiswa = "";
    }

    return AnimatedBuilder(
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
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simplified header with gradient background
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
                            // Removed icon for simplicity
                            Expanded(
                              child: Text(
                                widget.subjectName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // Status badge - untuk siswa atau parent
                            (isparent ? statusText.isNotEmpty : statusUjianSiswa.isNotEmpty)
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius:
                                          BorderRadius.circular(30),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              primaryColor.withValues(alpha: 0.1),
                                          blurRadius: 3,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      isparent ? statusText : statusUjianSiswa,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                            // Redesigned status indicator with red theme harmony
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 10,
                            //     vertical: 4
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: Colors.white.withValues(alpha: 0.2),
                            //     borderRadius: BorderRadius.circular(30),
                            //     border: Border.all(
                            //       color: Colors.white.withValues(alpha: 0.3),
                            //       width: 0.8,
                            //     ),
                            //     boxShadow: [
                            //       BoxShadow(
                            //         color: primaryColor.withValues(alpha: 0.1),
                            //         blurRadius: 3,
                            //         spreadRadius: 0,
                            //         offset: const Offset(0, 1),
                            //       ),
                            //     ],
                            //   ),
                            //   child: Row(
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       // Pulsating dot for active status with matching color
                            //       TweenAnimationBuilder<double>(
                            //         tween: Tween<double>(
                            //           begin: 0.7,
                            //           end: now.isAfter(startDate ?? DateTime.now()) &&
                            //               now.isBefore(endDate ?? DateTime.now()) ? 1.0 : 0.7
                            //         ),
                            //         duration: const Duration(milliseconds: 1000),
                            //         curve: Curves.easeInOut,
                            //         builder: (context, value, _) {
                            //           return Container(
                            //             width: 6,
                            //             height: 6,
                            //             margin: const EdgeInsets.only(right: 6),
                            //             decoration: BoxDecoration(
                            //               shape: BoxShape.circle,
                            //               color: _getPositiveStatusColor(statusText, primaryColor),
                            //               boxShadow: [
                            //                 BoxShadow(
                            //                   color: _getPositiveStatusColor(statusText, primaryColor).withValues(alpha: value * 0.5),
                            //                   blurRadius: value * 4,
                            //                   spreadRadius: value * 1,
                            //                 ),
                            //               ],
                            //             ),
                            //           );
                            //         },
                            //       ),
                            //       Text(
                            //         statusText,
                            //         style: const TextStyle(
                            //           fontSize: 12,
                            //           fontWeight: FontWeight.w500,
                            //           color: Colors.white,
                            //           letterSpacing: 0.2,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),

                      // Content area with clean layout
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Simplified exam name without icon
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
                            const SizedBox(height: 8),
                            isparent
                                ? const SizedBox(
                                    height: 0,
                                  )
                                : Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(statusText),
                                      height: 1.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                            const SizedBox(height: 20),

                            // Horizontal divider for visual separation
                            Container(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.15),
                              margin: const EdgeInsets.only(bottom: 16),
                            ),

                            // Information row with simplified data presentation
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

                                // Second column - Duration or Result
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        widget.isResult
                                            ? Utils.getTranslatedLabel(
                                                pointsKey)
                                            : Utils.getTranslatedLabel(
                                                durationKey),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (duration.isNotEmpty &&
                                          !widget.isResult)
                                        Text(
                                          duration,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      else if (widget.isResult)
                                        Text(
                                          widget.marks.isNotEmpty
                                              ? "${widget.marks}/${widget.totalMarks}"
                                              : "Total: ${widget.totalMarks}",
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

                            // Score indicator for results
                            if (widget.isResult)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          "${percentageValue.toStringAsFixed(0)}%",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _getProgressColor(
                                                percentageValue),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Animated progress bar
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                          begin: 0, end: percentageValue / 100),
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
                                                  0.83,
                                              decoration: BoxDecoration(
                                                color: _getProgressColor(
                                                    percentageValue),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getProgressColor(
                                                            percentageValue)
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
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

                      // Bottom action bar
                      if (statusUjianSiswa ==
                              Utils.getTranslatedLabel(notYetExamDoneKey) &&
                          statusText != Utils.getTranslatedLabel(completedKey))
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
                          child: context.read<AuthCubit>().isParent()
                              ? const SizedBox()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedOpacity(
                                      opacity: _isHovering ? 1.0 : 0.6,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Text(
                                        _examButtonLabel(),
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    widget.isExamStarted && !widget.isResult
                                        ? Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: primaryColor,
                                            size: 14,
                                          )
                                        : const SizedBox(),
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
    );
  }

  String _examButtonLabel() {
    if (widget.isResult) {
      return Utils.getTranslatedLabel(viewDetailKey); // Lihat Detail
    } else if (widget.isExamStarted) {
      return Utils.getTranslatedLabel(startExamKey); // Mulai Ujian
    } else {
      return "Akan Datang"; // Belum waktunya
    }
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

  Color _getStatusColor(String label) {
    if (label == Utils.getTranslatedLabel(completedKey)) {
      return Colors.grey;
    } else if (label == Utils.getTranslatedLabel(onGoingKey)) {
      return Colors.green;
    } else if (label == Utils.getTranslatedLabel(commingSoonKey)) {
      return Colors.blue;
    } else {
      return Colors.redAccent;
    }
  }
}
