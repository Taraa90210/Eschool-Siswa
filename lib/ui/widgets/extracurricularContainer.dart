import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/extracurricularCubit.dart';
import 'package:eschool/cubits/myExtracurricularCubit.dart';
import 'package:eschool/cubits/joinExtracurricularCubit.dart';
import 'package:eschool/cubits/allMyExtracurricularStatusCubit.dart';
import 'package:eschool/data/models/extracurricular.dart';
import 'package:eschool/data/models/studentExtracurricular.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

class ExtracurricularContainer extends StatefulWidget {
  final bool showBackButton;

  const ExtracurricularContainer({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<ExtracurricularContainer> createState() =>
      _ExtracurricularContainerState();
}

class _ExtracurricularContainerState extends State<ExtracurricularContainer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.delayed(Duration.zero, () {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    // Fetch all extracurriculars first to get coach names
    context.read<ExtracurricularCubit>().fetchExtracurriculars();
    // Then fetch my extracurriculars
    context.read<MyExtracurricularCubit>().fetchMyExtracurriculars();
    // Also fetch all my extracurricular statuses for button status checking
    context
        .read<AllMyExtracurricularStatusCubit>()
        .fetchAllMyExtracurricularStatuses();
  }

  Future<void> _onRefresh() async {
    // Clear search when refreshing
    _searchController.clear();

    // Fetch data based on current tab
    if (_currentTabIndex == 0) {
      // All Extracurriculars tab
      context.read<ExtracurricularCubit>().fetchExtracurriculars();
      // Also refresh status for button updates
      context
          .read<AllMyExtracurricularStatusCubit>()
          .fetchAllMyExtracurricularStatuses();
    } else {
      // My Extracurriculars tab
      context.read<MyExtracurricularCubit>().fetchMyExtracurriculars();
    }

    // Wait a bit for the API call to complete
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void _refreshAfterJoin() {
    // Optimized refresh after successful join
    // Prioritize fetching my extracurriculars first to show updated status
    context.read<MyExtracurricularCubit>().fetchMyExtracurriculars();
    // Also immediately fetch all statuses to update button states
    context
        .read<AllMyExtracurricularStatusCubit>()
        .fetchAllMyExtracurricularStatuses();

    // Delay fetching all extracurriculars to avoid overwhelming the API
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<ExtracurricularCubit>().fetchExtracurriculars();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_currentTabIndex == 0) {
      context.read<ExtracurricularCubit>().searchExtracurriculars(query);
    } else {
      context.read<MyExtracurricularCubit>().fetchMyExtracurriculars(
            search: query,
          );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: 10.0),
      child: Row(
        children: [
          // Modern Search Bar - Takes available space dynamically
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Cari ekstrakurikuler...',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  // Clear button with animation
                  AnimatedOpacity(
                    opacity: _searchController.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _onSearchChanged('');
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 16,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(width: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Semua Ekstrakurikuler',
              isSelected: _currentTabIndex == 0,
              onTap: () {
                setState(() {
                  _currentTabIndex = 0;
                });
                _tabController.animateTo(0);
                _fetchData();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              title: 'Ekstrakurikuler Saya',
              isSelected: _currentTabIndex == 1,
              onTap: () {
                setState(() {
                  _currentTabIndex = 1;
                });
                _tabController.animateTo(1);
                _fetchData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtracurricularCard(Extracurricular extracurricular) {
    final student = context.read<AuthCubit>().getStudentDetails();
    final studentId = student.id ?? 0;
    final nisn = student.admissionNo ?? '';

    // Check if student has already joined/requested this extracurricular
    // Use AllMyExtracurricularStatusCubit for accurate status checking (includes all statuses)
    StudentExtracurricular? joinedStatus;
    final allStatusState =
        context.watch<AllMyExtracurricularStatusCubit>().state;
    if (allStatusState is AllMyExtracurricularStatusFetchSuccess) {
      joinedStatus =
          allStatusState.getStatusByExtracurricularId(extracurricular.id ?? 0);
    }

    // Modern color scheme - Student theme (Bright Red)
    final colorScheme = {
      'primary': Color(0xffd22f3c), // App primary red (bright red)
      'gradient1': Color(0xffd22f3c), // Primary red
      'gradient2': Color(0xffdc3545), // Slightly lighter red
      'gradient3': Color(0xffe74c3c), // Bright red
      'neutral1': Color(0xFF333333), // Dark gray for primary text
      'neutral2': Color(0xFF666666), // Medium gray for secondary text
      'accent': Color(0xffd22f3c), // Same as primary
    };

    // Calculate dynamic header height for text wrapping
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 48;
    final double titleFontSize = 24.0;
    final double lineHeight = 1.4;

    final int estimatedCharactersPerLine =
        (availableWidth / (titleFontSize * 0.6)).floor();
    final int estimatedLines = math.max(1,
        (extracurricular.title?.length ?? 0) ~/ estimatedCharactersPerLine + 1);
    final double estimatedTextHeight =
        estimatedLines * (titleFontSize * lineHeight);

    final double minHeight = 260.0;
    final double maxHeight = 400.0;
    final double headerHeight =
        math.min(maxHeight, math.max(minHeight, estimatedTextHeight + 200.0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          highlightColor: Colors.transparent,
          splashColor: colorScheme['primary']!.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white, // White background for card
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModernCardHeader(
                        extracurricular, colorScheme, headerHeight),
                    _buildModernCardContent(extracurricular, colorScheme,
                        headerHeight, studentId, nisn, joinedStatus),
                  ],
                ),
                _buildModernOverlappingCard(
                    extracurricular, colorScheme, headerHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCardHeader(Extracurricular extracurricular,
      Map<String, Color> colorScheme, double headerHeight) {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme['gradient1']!,
            colorScheme['gradient2']!,
            colorScheme['gradient3']!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Pattern Overlay
          Opacity(
            opacity: 0.07,
            child: CustomPaint(
              size: Size.infinite,
              painter: ModernPatternPainter(
                primaryColor: Colors.white,
                secondaryColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Glow Effect Corner
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Coach name badge
          Positioned(
            top: 30,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: colorScheme['primary']),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        extracurricular.instructor ?? 'Tidak ada pembimbing',
                        style: TextStyle(
                          color: colorScheme['primary'],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title
          Positioned(
            top: 90,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extracurricular.title ?? 'Tidak ada judul',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.left,
                  maxLines: null,
                ),
                SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCardContent(
      Extracurricular extracurricular,
      Map<String, Color> colorScheme,
      double headerHeight,
      int studentId,
      String nisn,
      StudentExtracurricular? joinedStatus) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, math.max(120, (headerHeight * 0.35).round().toDouble()), 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join Button - Modern Design for Students
          SizedBox(
            width: double.infinity,
            height: 56,
            child: BlocConsumer<JoinExtracurricularCubit,
                JoinExtracurricularState>(
              listener: (context, state) {
                if (state is JoinExtracurricularSuccess) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: state.message,
                    backgroundColor: Colors.green,
                  );
                  // Refresh data after successful join
                  _refreshAfterJoin();
                } else if (state is JoinExtracurricularFailure) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: state.errorMessage,
                    backgroundColor: Colors.red,
                  );
                }
              },
              builder: (context, state) {
                // Check joined status first
                if (joinedStatus != null) {
                  if (joinedStatus.status == 0) {
                    return _buildStatusButton(
                      text: 'Menunggu Persetujuan',
                      color: const Color(0xffFF9800), // Orange
                      icon: Icons.access_time,
                    );
                  } else if (joinedStatus.status == 1) {
                    return _buildStatusButton(
                      text: 'Terdaftar',
                      color: const Color(0xff2196F3), // Blue
                      icon: Icons.check_circle,
                    );
                  } else if (joinedStatus.status == 2) {
                    return _buildStatusButton(
                      text: 'Ditolak',
                      color: Colors.red,
                      icon: Icons.cancel,
                    );
                  }
                }

                final isLoading = state is JoinExtracurricularInProgress;
                final isAvailable = extracurricular.isAvailable;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isAvailable
                          ? [
                              Color(0xFF4CAF50), // Green
                              Color(0xFF45A049), // Darker green
                              Color(0xFF388E3C), // Deep green
                            ]
                          : [
                              Colors.grey[400] ?? Colors.grey,
                              Colors.grey[500] ?? Colors.grey,
                              Colors.grey[600] ?? Colors.grey,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isAvailable
                        ? [
                            BoxShadow(
                              color: Color(0xFF4CAF50).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                              spreadRadius: -5,
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading || !isAvailable
                          ? null
                          : () {
                              context
                                  .read<JoinExtracurricularCubit>()
                                  .joinExtracurricular(
                                    extracurricularId: extracurricular.id!,
                                    studentId: studentId,
                                    nisn: nisn,
                                  );
                            },
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isAvailable ? Icons.add : Icons.block,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    isAvailable ? 'Bergabung' : 'Penuh',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String text,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: Offset(0, 5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOverlappingCard(Extracurricular extracurricular,
      Map<String, Color> colorScheme, double headerHeight) {
    return Positioned(
      top: headerHeight - 85,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Description section
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme['primary']!.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: colorScheme['primary'],
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme['neutral1'],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          extracurricular.description ?? 'Tidak ada deskripsi',
                          style: TextStyle(
                            color: colorScheme['neutral2'],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme['primary']!.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      color: colorScheme['primary'],
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme['primary']!.withValues(alpha: 0.08),
              indent: 20,
              endIndent: 20,
            ),

            // Category section
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme['primary']!.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 16,
                          color: colorScheme['primary'],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ekstrakurikuler',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme['neutral1'],
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildMyExtracurricularCard(
      StudentExtracurricular studentExtracurricular) {
    final extracurricular = studentExtracurricular.extracurricular;
    if (extracurricular == null) return const SizedBox.shrink();

    // Modern color scheme - My Ekstrakurikuler theme (Red for joined activities)
    final colorScheme = {
      'primary': Color(0xffE53935), // Red
      'gradient1': Color(0xffC62828), // Dark red
      'gradient2': Color(0xffE53935), // Primary red
      'gradient3': Color(0xffEF5350), // Light red
      'neutral1': Color(0xFF333333), // Dark gray for primary text
      'neutral2': Color(0xFF666666), // Medium gray for secondary text
      'accent': Color(0xffE53935), // Same as primary
      'success': Color(0xff4CAF50), // Green for active status
      'warning': Color(0xffFF9800), // Orange for pending status
    };

    // Status color based on studentExtracurricular.status
    Color statusColor;
    String statusText;
    switch (studentExtracurricular.status) {
      case 0:
        statusColor = colorScheme['warning']!;
        statusText = 'Menunggu';
        break;
      case 1:
        statusColor = colorScheme['success']!;
        statusText = 'Disetujui';
        break;
      case 2:
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Tidak Diketahui';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          highlightColor: Colors.transparent,
          splashColor: colorScheme['primary']!.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMyExtracurricularCardHeader(
                        extracurricular, colorScheme, statusColor, statusText),
                    _buildMyExtracurricularCardContent(
                        studentExtracurricular, extracurricular, colorScheme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyExtracurricularCardHeader(Extracurricular extracurricular,
      Map<String, Color> colorScheme, Color statusColor, String statusText) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme['gradient1']!,
            colorScheme['gradient2']!,
            colorScheme['gradient3']!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Pattern Overlay
          Opacity(
            opacity: 0.07,
            child: CustomPaint(
              size: Size.infinite,
              painter: ModernPatternPainter(
                primaryColor: Colors.white,
                secondaryColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Ekstrakurikuler Label
          Positioned(
            top: 20,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ekstrakurikuler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status Badge
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Title and basic info
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extracurricular.title ?? 'Tidak ada judul',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyExtracurricularCardContent(
      StudentExtracurricular studentExtracurricular,
      Extracurricular extracurricular,
      Map<String, Color> colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pembimbing Card - moved to white section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme['primary']!.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme['primary']!.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Coach Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme['primary']!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: colorScheme['primary'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Coach Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembimbing',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme['neutral2'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildInstructorNameWidget(extracurricular, colorScheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          if (extracurricular.description != null &&
              extracurricular.description!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme['neutral1'],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  extracurricular.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme['neutral2'],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Join Date and Update Date
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.event_available,
                  label: 'Bergabung',
                  value: Utils.formatDate(DateTime.tryParse(
                          studentExtracurricular.createdAt ?? '') ??
                      DateTime.now()),
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.update,
                  label: 'Diperbarui',
                  value: Utils.formatDate(DateTime.tryParse(
                          studentExtracurricular.updatedAt ?? '') ??
                      DateTime.now()),
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInstructorNameWidget(
      Extracurricular extracurricular, Map<String, Color> colorScheme) {
    // Use BlocBuilder to listen for ExtracurricularCubit state changes
    // This ensures coach names update when All Extracurriculars data is loaded
    return BlocBuilder<ExtracurricularCubit, ExtracurricularState>(
      builder: (context, state) {
        String displayName = _getInstructorNameSimple(extracurricular);

        return Text(
          displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme['neutral1'],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  String _getInstructorNameSimple(Extracurricular extracurricular) {
    // The instructor field already contains coach_name from API endpoint /show
    if (extracurricular.instructor?.isNotEmpty == true) {
      return extracurricular.instructor!;
    }

    // For My Extracurricular cards, try to get coach name from All Extracurriculars data
    if (extracurricular.coachId != null) {
      final coachName =
          _getCoachNameFromAllExtracurriculars(extracurricular.coachId!);
      if (coachName != null) {
        return coachName;
      }
      return 'Pembimbing (ID: ${extracurricular.coachId})';
    }

    return 'Tidak ada pembimbing';
  }

  String? _getCoachNameFromAllExtracurriculars(int coachId) {
    // Try to get coach name from All Extracurriculars data which has coach_name
    final extracurricularState = context.read<ExtracurricularCubit>().state;
    if (extracurricularState is ExtracurricularFetchSuccess) {
      for (final extracurricular in extracurricularState.extracurriculars) {
        if (extracurricular.coachId == coachId &&
            extracurricular.instructor?.isNotEmpty == true) {
          return extracurricular.instructor;
        }
      }
    }
    return null;
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Map<String, Color> colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme['primary']!.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme['primary']!.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme['primary'],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme['primary'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme['neutral1'],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: 3, // Show 3 shimmer cards
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerhighlightColor,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shimmer Header
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      color: shimmerBaseColor,
                    ),
                    child: Stack(
                      children: [
                        // Coach name badge shimmer
                        Positioned(
                          top: 30,
                          left: 24,
                          right: 24,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Container(
                                width: 120,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: shimmerBaseColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Title shimmer
                        Positioned(
                          top: 90,
                          left: 24,
                          right: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: 200,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: 60,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Shimmer Content (Button area)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 120, 24, 24),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: shimmerBaseColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              // Shimmer Overlapping Card
              Positioned(
                top: 195, // Dynamic positioning like real card
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Description shimmer
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: shimmerBaseColor,
                                shape: BoxShape.circle,
                              ),
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: shimmerBaseColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: shimmerBaseColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Container(
                                    width: 150,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: shimmerBaseColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: shimmerBaseColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              width: 32,
                              height: 32,
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Divider(height: 1, thickness: 1, color: shimmerBaseColor),
                      // Category shimmer
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: shimmerBaseColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: shimmerBaseColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
    );
  }

  Widget _buildAllExtracurriculars() {
    return BlocBuilder<ExtracurricularCubit, ExtracurricularState>(
      builder: (context, state) {
        if (state is ExtracurricularFetchInProgress) {
          return _buildShimmerLoading();
        } else if (state is ExtracurricularFetchFailure) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: () {
                context.read<ExtracurricularCubit>().fetchExtracurriculars();
              },
            ),
          );
        } else if (state is ExtracurricularFetchSuccess) {
          if (state.extracurriculars.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child:
                  const NoDataContainer(titleKey: 'Tidak ada ekstrakurikuler'),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  bottom: 100), // Increased padding for bottom navigation
              itemCount: state.extracurriculars.length,
              itemBuilder: (context, index) {
                return _buildExtracurricularCard(state.extracurriculars[index]);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMyExtracurriculars() {
    return BlocBuilder<MyExtracurricularCubit, MyExtracurricularState>(
      builder: (context, state) {
        if (state is MyExtracurricularFetchInProgress) {
          return _buildShimmerLoading();
        } else if (state is MyExtracurricularFetchFailure) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: () {
                context
                    .read<MyExtracurricularCubit>()
                    .fetchMyExtracurriculars();
              },
            ),
          );
        } else if (state is MyExtracurricularFetchSuccess) {
          final approvedExtracurriculars =
              state.myExtracurriculars.where((e) => e.status == 1).toList();

          if (approvedExtracurriculars.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: const NoDataContainer(
                  titleKey: 'Anda belum mengikuti ekstrakurikuler apapun'),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  bottom: 100), // Increased padding for bottom navigation
              itemCount: approvedExtracurriculars.length,
              itemBuilder: (context, index) {
                return _buildMyExtracurricularCard(
                    approvedExtracurriculars[index]);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              ScreenTopBackgroundContainer(
                heightPercentage: Utils.appBarSmallerHeightPercentage,
                child: Stack(
                  children: [
                    if (widget.showBackButton) const CustomBackButton(),
                    // Title positioned in the center of header
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Text(
                          'Ekstrakurikuler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSearchBar(),
              _buildTabBar(),
              const SizedBox(height: 10),
              Expanded(
                child: _currentTabIndex == 0
                    ? _buildAllExtracurriculars()
                    : _buildMyExtracurriculars(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ModernPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  ModernPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dotPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final double spacing = 40;

    // Draw curved lines
    for (double i = -size.width / 2; i < size.width * 1.5; i += spacing) {
      final path = Path();
      path.moveTo(i, 0);
      path.quadraticBezierTo(
          i + spacing / 2, size.height / 2, i + spacing, size.height);
      canvas.drawPath(path, paint);
    }

    // Add decorative dots
    for (int i = 0; i < 12; i++) {
      final x = (size.width * 0.1) + (i * size.width * 0.08);
      final y = size.height * 0.2 + (i % 3) * size.height * 0.3;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
