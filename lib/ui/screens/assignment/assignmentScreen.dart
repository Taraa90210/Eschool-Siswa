import 'package:eschool/cubits/assignmentsCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/undoAssignmentSubmissionCubit.dart';
import 'package:eschool/cubits/uploadAssignmentCubit.dart';
import 'package:eschool/data/models/assignment.dart';
import 'package:eschool/data/repositories/assignmentRepository.dart';
import 'package:eschool/ui/screens/assignment/widgets/undoAssignmentBottomsheetContainer.dart';
import 'package:eschool/ui/screens/assignment/widgets/uploadAssignmentFilesBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/StudyMaterial_part2.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AssignmentScreen extends StatefulWidget {
  final Assignment assignment;
  const AssignmentScreen({Key? key, required this.assignment})
      : super(key: key);

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();

  static Widget routeInstance() {
    final args = Get.arguments;
    print("Args di AssignmentScreen: $args");
    late Assignment assignment;

    if (args is Assignment) {
      assignment = args;
    } else if (args is Map<String, dynamic>) {
      assignment = Assignment.fromJson(args);
    } else {
      throw ArgumentError("Invalid arguments for AssignmentScreen: $args");
    }

    return AssignmentScreen(
      assignment: assignment,
    );
  }
}

class _AssignmentScreenState extends State<AssignmentScreen>
    with SingleTickerProviderStateMixin {
  bool isUndoAssignmentSubmissionButtonToBeShown = false;
  late bool assignmentSubmitted =
      submittedAssignment.assignmentSubmission.id != 0;
  late Assignment submittedAssignment = widget.assignment;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerAnimation;
  late Animation<Offset> _contentAnimation;
  late Animation<Offset> _submissionAnimation;

  // Enhanced color palette with opacity variations
  final Color primaryColor = Color(0xFFD22F3C);
  final Color primaryLight = Color(0xFFD22F3C).withValues(alpha: 0.8);
  final Color primaryLighter = Color(0xFFD22F3C).withValues(alpha: 0.6);
  final Color accentColor = Color(0xFF2F80ED);
  final Color backgroundColor = Color(0xFFFAF8F9);
  final Color cardColor = Colors.white;
  final Color textColor = Color(0xFF424242);

  // Accent colors with modern feel
  final Color questionColor = Color(0xFF6A3DE8);
  final Color materialColor = Color(0xFF00B59C);
  final Color fileTypeColor = Color(0xFF546E7A);
  final Color submissionColor = Color(0xFFE97A43);
  final Color pointsColor = Color(0xFF3E7BFA);
  final Color feedbackColor = Color(0xFF6D4C41);

  // UI Animation controllers
  bool _isHoveringUpload = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    // Add staggered animations for elements
    _headerAnimation = Tween<Offset>(begin: Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.1, 0.6, curve: Curves.easeOutCubic)));

    _contentAnimation = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _submissionAnimation =
        Tween<Offset>(begin: Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic)));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void uploadAssignment() {
    Utils.showBottomSheet(
      child: BlocProvider<UploadAssignmentCubit>(
        create: (_) => UploadAssignmentCubit(AssignmentRepository()),
        child: UploadAssignmentFilesBottomsheetContainer(
          assignment: submittedAssignment,
        ),
      ),
      context: context,
      enableDrag: true,
    ).then((value) {
      if (value != null) {
        if (value['error']) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: "Terjadi kesalahan: " +
                Utils.getErrorMessageFromErrorCode(
                  context,
                  value['message'].toString(),
                  source: "tugas",
                ),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          submittedAssignment = submittedAssignment
              .updateAssignmentSubmission(value['assignmentSubmission']);
          assignmentSubmitted = true;
          context
              .read<AssignmentsCubit>()
              .updateAssignments(submittedAssignment);
          setState(() {});
        }
      }
    });
  }

  void undoAssignment() {
    Utils.showBottomSheet(
      child: BlocProvider<UndoAssignmentSubmissionCubit>(
        create: (_) => UndoAssignmentSubmissionCubit(AssignmentRepository()),
        child: UndoAssignmentBottomsheetContainer(
          assignmentSubmissionId: submittedAssignment.assignmentSubmission.id,
        ),
      ),
      context: context,
      enableDrag: false,
    ).then((value) {
      if (value != null) {
        if (value['error']) {
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: Utils.getErrorMessageFromErrorCode(
              context,
              value['message'].toString(),
              source: "tugas",
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          submittedAssignment = submittedAssignment
              .updateAssignmentSubmission(AssignmentSubmission.fromJson({}));
          assignmentSubmitted = false;
          isUndoAssignmentSubmissionButtonToBeShown = false;
          setState(() {});
          context
              .read<AssignmentsCubit>()
              .updateAssignments(submittedAssignment);
          uploadAssignment();
        }
      }
    });
  }

  bool _showUploadAssignmentButton() {
    if (context.read<AuthCubit>().isParent()) {
      print("ELOL 1");
      return false;
    }
    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );

    DateTime currentDayDateTime = DateTime.now();

    if (assignmentStatusKey == inReviewKey &&
        currentDayDateTime.compareTo(submittedAssignment.dueDate) != 1) {
      isUndoAssignmentSubmissionButtonToBeShown = true;
      return true;
    }

    if (assignmentStatusKey == acceptedKey ||
        assignmentStatusKey == inReviewKey ||
        assignmentStatusKey == resubmittedKey) {
      print("ELOL 2");
      return false;
    }

    if (Utils.getAssignmentSubmissionStatusKey(
          submittedAssignment.assignmentSubmission.status,
        ) ==
        rejectedKey) {
      if (submittedAssignment.resubmission == 0) {
        return false;
      }
      if (currentDayDateTime.compareTo(
            submittedAssignment.dueDate.add(
              Duration(
                days: submittedAssignment.extraDaysForResubmission,
              ),
            ),
          ) ==
          1) {
        print("ELOL 4");
        return false;
      }
      return true;
    }

    return true;
  }

  Widget _buildUnifiedAssignmentView() {
    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );

    DateTime dueDate = submittedAssignment.dueDate;
    if ((assignmentStatusKey == rejectedKey &&
            submittedAssignment.resubmission == 1) ||
        assignmentStatusKey == resubmittedKey) {
      dueDate = submittedAssignment.dueDate
          .add(Duration(days: submittedAssignment.extraDaysForResubmission));
    }

    final now = DateTime.now();
    final isToday = dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year;
    final hasPassed = dueDate.isBefore(now) && !isToday;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Column(
      children: [
        // Main assignment card with SlideTransition animation
        SlideTransition(
          position: _headerAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 20, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Header with gradient and pattern overlay
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.9),
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Enhanced decorative pattern overlay
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.08,
                          child: CustomPaint(
                            painter: PatternPainter(),
                          ),
                        ),
                      ),

                      // Main content with improved layout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and status section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Assignment title
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      submittedAssignment.name,
                                      style: GoogleFonts.inter(
                                        fontSize: isSmallScreen ? 18 : 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.3,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: isSmallScreen ? 2 : 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    SizedBox(height: 8),

                                    // Subject info with enhanced design
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 10 : 12,
                                        vertical: isSmallScreen ? 6 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_stories_rounded,
                                            size: isSmallScreen ? 14 : 16,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                          ),
                                          SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              submittedAssignment.subject
                                                  .getSubjectName(
                                                      context: context),
                                              style: GoogleFonts.inter(
                                                fontSize:
                                                    isSmallScreen ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                letterSpacing: 0.1,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: isSmallScreen ? 12 : 16),

                              // Status/Points badge with enhanced styling
                              // Flexible(
                              //   flex: 1,
                              _buildStatusBadge(isSmallScreen),
                              // ),
                            ],
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 24),

                          // Due date section with improved layout
                          _buildDueDateSection(
                              dueDate, hasPassed, isToday, isSmallScreen),
                        ],
                      ),
                    ],
                  ),
                ),

                // Assignment Content with slide transition
                SlideTransition(
                  position: _contentAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions/Question Section with animation
                        if (submittedAssignment.instructions.isNotEmpty)
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            margin: EdgeInsets.only(bottom: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    TweenAnimationBuilder(
                                      duration: Duration(milliseconds: 800),
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      builder: (context, double value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(
                                            isSmallScreen ? 10 : 12),
                                        decoration: BoxDecoration(
                                          color: questionColor.withValues(
                                              alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: questionColor.withValues(
                                                  alpha: 0.1),
                                              blurRadius: 10,
                                              spreadRadius: 0,
                                              offset: Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.help_outline,
                                          color: questionColor,
                                          size: isSmallScreen ? 18 : 22,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 10 : 14),
                                    Expanded(
                                      child: Text(
                                        Utils.getTranslatedLabel(
                                            instructionsKey),
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: questionColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 20,
                                      vertical: 10),
                                  child: Text(
                                    submittedAssignment.instructions,
                                    style: GoogleFonts.poppins(
                                      color: textColor,
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Reference Materials Section with enhanced design
                        if (submittedAssignment.referenceMaterials.isNotEmpty)
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            margin: EdgeInsets.only(bottom: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                          isSmallScreen ? 10 : 12),
                                      decoration: BoxDecoration(
                                        color: materialColor.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: materialColor.withValues(
                                                alpha: 0.1),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                            offset: Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.attach_file,
                                        color: materialColor,
                                        size: isSmallScreen ? 18 : 22,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 10 : 14),
                                    Expanded(
                                      child: Text(
                                        Utils.getTranslatedLabel(
                                            referenceMaterialsKey),
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: materialColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 20,
                                    vertical: 10,
                                  ),
                                  child: SingleChildScrollView(
                                    child: GridView.count(
                                      primary: false,
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.all(0),
                                      crossAxisSpacing: isSmallScreen ? 8 : 12,
                                      mainAxisSpacing: isSmallScreen ? 8 : 12,
                                      crossAxisCount: isSmallScreen ? 2 : 3,
                                      children: List.generate(
                                        submittedAssignment
                                            .referenceMaterials.length,
                                        (index) {
                                          return TweenAnimationBuilder(
                                            duration: Duration(
                                                milliseconds:
                                                    400 + (index * 100)),
                                            tween: Tween<double>(
                                                begin: 0.8, end: 1.0),
                                            builder:
                                                (context, double scale, child) {
                                              return Transform.scale(
                                                  scale: scale, child: child);
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: materialColor
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                    offset: Offset(0, 3),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: materialColor
                                                      .withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                                child:
                                                    StudyMaterialWithDownloadButtonContainer2(
                                                  boxConstraints:
                                                      BoxConstraints(
                                                    maxWidth:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            (isSmallScreen
                                                                ? 0.45
                                                                : 0.7),
                                                  ),
                                                  type: 3,
                                                  studyMaterial:
                                                      submittedAssignment
                                                              .referenceMaterials[
                                                          index],
                                                  // ⬇️ ini penting untuk preview dengan swipe
                                                  gallery: submittedAssignment
                                                      .referenceMaterials,
                                                  initialIndex: index,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Allowed File Types with modern design
                        if (submittedAssignment.filetypes.isNotEmpty)
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            margin: EdgeInsets.only(bottom: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                          isSmallScreen ? 10 : 12),
                                      decoration: BoxDecoration(
                                        color: fileTypeColor.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: fileTypeColor.withValues(
                                                alpha: 0.1),
                                            blurRadius: 10,
                                            spreadRadius: 0,
                                            offset: Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: fileTypeColor,
                                        size: isSmallScreen ? 18 : 22,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 10 : 14),
                                    Expanded(
                                      child: Text(
                                        'Format Berkas yang Diterima',
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: fileTypeColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 14),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 20,
                                      vertical: 10),
                                  child: Wrap(
                                    spacing: isSmallScreen ? 6 : 10,
                                    runSpacing: isSmallScreen ? 6 : 10,
                                    children: submittedAssignment.filetypes
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      int idx = entry.key;
                                      String filetype = entry.value;
                                      return TweenAnimationBuilder(
                                        duration: Duration(
                                            milliseconds: 300 + (idx * 100)),
                                        tween:
                                            Tween<double>(begin: 0.0, end: 1.0),
                                        builder:
                                            (context, double value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  isSmallScreen ? 10 : 14,
                                              vertical: isSmallScreen ? 6 : 8),
                                          decoration: BoxDecoration(
                                            color: fileTypeColor.withValues(
                                                alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: fileTypeColor.withValues(
                                                  alpha: 0.15),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getFileTypeIcon(
                                                    filetype.toLowerCase()),
                                                size: isSmallScreen ? 12 : 16,
                                                color: fileTypeColor,
                                              ),
                                              SizedBox(
                                                  width: isSmallScreen ? 4 : 6),
                                              Text(
                                                filetype,
                                                style: GoogleFonts.poppins(
                                                  color: fileTypeColor,
                                                  fontSize:
                                                      isSmallScreen ? 11 : 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Separate card for submitted assignments
        if (assignmentSubmitted)
          SlideTransition(
            position: _submissionAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 20, vertical: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: submissionColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Submission header with gradient
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          submissionColor,
                          submissionColor.withValues(alpha: 0.8)
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 14),
                        Expanded(
                          child: Text(
                            "Diserahkan",
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 4 : 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1),
                          ),
                          child: Text(
                            getAssignmentSubmissionStatus(),
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Submission content
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Submitted Files
                        if (!submittedAssignment
                            .assignmentSubmission.submittedFiles.isEmpty)
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Utils.getTranslatedLabel(myWorkFileKey),
                                  style: GoogleFonts.poppins(
                                    color: textColor.withValues(alpha: 0.7),
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 16),
                                  child: Column(
                                    children: submittedAssignment
                                        .assignmentSubmission.submittedFiles
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => TweenAnimationBuilder(
                                            duration: Duration(
                                                milliseconds:
                                                    400 + (entry.key * 100)),
                                            tween: Tween<double>(
                                                begin: 0.9, end: 1.0),
                                            builder:
                                                (context, double scale, child) {
                                              return Transform.scale(
                                                scale: scale,
                                                child: child,
                                              );
                                            },
                                            child:
                                                StudyMaterialWithDownloadButtonContainer2(
                                              boxConstraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    (isSmallScreen ? 0.8 : 0.7),
                                              ),
                                              studyMaterial: entry.value,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Submitted Text Content
                        if (submittedAssignment
                            .assignmentSubmission.content.isNotEmpty)
                          Container(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Utils.getTranslatedLabel(myWorkTextKey),
                                  style: GoogleFonts.poppins(
                                    color: textColor.withValues(alpha: 0.7),
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 16,
                                      vertical: 10),
                                  child: Text(
                                    submittedAssignment
                                        .assignmentSubmission.content,
                                    style: GoogleFonts.poppins(
                                      color: textColor,
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Teacher Feedback Section
                        if (submittedAssignment
                            .assignmentSubmission.feedback.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                          isSmallScreen ? 8 : 10),
                                      decoration: BoxDecoration(
                                        color: feedbackColor.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.comment,
                                        color: feedbackColor,
                                        size: isSmallScreen ? 16 : 20,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Expanded(
                                      child: Text(
                                        "Komentar Guru",
                                        style: GoogleFonts.poppins(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: feedbackColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 16,
                                      vertical: 10),
                                  child: Text(
                                    submittedAssignment
                                        .assignmentSubmission.feedback,
                                    style: GoogleFonts.poppins(
                                      fontStyle: FontStyle.italic,
                                      color: textColor.withValues(alpha: 0.8),
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _uploadOrUndoAssignmentButton() {
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 25.0, bottom: 25.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHoveringUpload = true),
          onExit: (_) => setState(() => _isHoveringUpload = false),
          child: GestureDetector(
            onTap: () {
              if (isUndoAssignmentSubmissionButtonToBeShown) {
                undoAssignment();
              } else {
                uploadAssignment();
              }
            },
            child: TweenAnimationBuilder(
              duration: Duration(milliseconds: 300),
              tween:
                  Tween<double>(begin: 1.0, end: _isHoveringUpload ? 1.1 : 1.0),
              builder: (context, double scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 60,
                height: 60,
                padding: EdgeInsets.all(
                    isUndoAssignmentSubmissionButtonToBeShown ? 14 : 13),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: _isHoveringUpload ? 15 : 10,
                      offset: const Offset(0, 4),
                      color: primaryColor.withValues(
                          alpha: _isHoveringUpload ? 0.5 : 0.4),
                    )
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withValues(
                          alpha: _isHoveringUpload ? 0.9 : 0.8)
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background pulse animation
                    if (_isHoveringUpload)
                      TweenAnimationBuilder(
                        duration: Duration(milliseconds: 1500),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, double value, child) {
                          return AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: _isHoveringUpload ? 1.0 : 0.0,
                            child: Container(
                              width: 60 * (1 + value * 0.2),
                              height: 60 * (1 + value * 0.2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    primaryColor.withValues(
                                        alpha: 0.6 * (1 - value)),
                                    primaryColor.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Icon
                    SvgPicture.asset(
                      Utils.getImagePath(
                          isUndoAssignmentSubmissionButtonToBeShown
                              ? "undo_assignment_submission.svg"
                              : "file_upload_icon.svg"),
                      colorFilter:
                          ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getAssignmentSubmissionStatus() {
    if (Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    ).isNotEmpty) {
      return Utils.getTranslatedLabel(
        Utils.getAssignmentSubmissionStatusKey(
            submittedAssignment.assignmentSubmission.status),
      );
    }
    return "";
  }

  IconData _getFileTypeIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('doc') || fileType.contains('txt'))
      return Icons.description;
    if (fileType.contains('xls')) return Icons.insert_chart;
    if (fileType.contains('jpg') ||
        fileType.contains('png') ||
        fileType.contains('jpeg')) return Icons.image;
    if (fileType.contains('zip') || fileType.contains('rar'))
      return Icons.folder_zip;
    if (fileType.contains('ppt')) return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  IconData _getStatusIcon() {
    String statusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );
    switch (statusKey) {
      case 'inReview':
        return Icons.hourglass_top_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'resubmitted':
        return Icons.refresh_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildStatusBadge(bool isSmallScreen) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  assignmentSubmitted ? _getStatusIcon() : Icons.star_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignmentSubmitted
                            ? getAssignmentSubmissionStatus()
                            : "${submittedAssignment.points} ${Utils.getTranslatedLabel(pointsKey)}",
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (assignmentSubmitted &&
                          submittedAssignment.assignmentSubmission.points >
                              0) ...[
                        SizedBox(height: 2),
                        Text(
                          "${submittedAssignment.assignmentSubmission.points}/${submittedAssignment.points}",
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDueDateSection(
      DateTime dueDate, bool hasPassed, bool isToday, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status label on the right
          Row(
            children: [
              Text(
                "Batas Waktu",
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.1,
                ),
              ),

              // Status label positioned at far right of header
              if (hasPassed || isToday) ...[
                Spacer(),
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, animValue, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * animValue),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasPassed
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.amber.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasPassed
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.amber.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: hasPassed
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasPassed
                                  ? Icons.warning_rounded
                                  : Icons.today_rounded,
                              size: isSmallScreen ? 10 : 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              hasPassed ? "Terlambat" : "Hari Ini",
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 9 : 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),

          SizedBox(height: 12),

          // Date and time in one row
          Row(
            children: [
              // Date on the left
              Expanded(
                child: Text(
                  DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(dueDate),
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Time on the far right
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  SizedBox(width: 6),
                  Text(
                    DateFormat("HH:mm WIB").format(dueDate),
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height *
                  Utils.appBarMediumtHeightPercentage,
              bottom: 90,
            ),
            physics: BouncingScrollPhysics(),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: child,
                );
              },
              child: _buildUnifiedAssignmentView(),
            ),
          ),
          ScreenTopBackgroundContainer(
            heightPercentage: Utils.appBarSmallerHeightPercentage,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    left: 10,
                    top: -2,
                    child: const CustomBackButton(),
                  ),
                  Text(
                    Utils.getTranslatedLabel(assignmentKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _showUploadAssignmentButton()
              ? _uploadOrUndoAssignmentButton()
              : const SizedBox(),
        ],
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Drawing decorative pattern
    double spacing = size.width / 10;

    // Draw circles
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
          Offset(size.width - 20, size.height / 2 - 30 + (i * 15)),
          10 + (i * 10),
          paint);
    }

    // Draw diagonal lines
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(0, spacing * i),
        Offset(spacing * i, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
