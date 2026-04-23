import 'package:eschool/cubits/student/leavesCubit.dart';
import 'package:eschool/data/models/student/leave.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/ui/widgets/applyLeavesContainer.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/ui/widgets/expandableText.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomCircularProgressIndicator extends StatelessWidget {
  final Color indicatorColor;

  const CustomCircularProgressIndicator({
    Key? key,
    this.indicatorColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
    );
  }
}

class LeavesListContainer extends StatefulWidget {
  final int? childId;
  final Student student;
  const LeavesListContainer({
    Key? key,
    this.childId,
    required this.student,
  }) : super(key: key);

  @override
  State<LeavesListContainer> createState() => _LeavesListContainerState();
}

class _LeavesListContainerState extends State<LeavesListContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    Future.delayed(Duration.zero, () {
      _fetchLeaves();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchLeaves() {
    context.read<LeavesCubit>().fetchLeaves(
          childId: widget.childId ?? 0,
        );
  }

  void _navigateToApplyLeaves() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) =>
            ApplyLeavesContainer(childId: widget.childId, data: null),
      ),
    )
        .then((_) {
      _fetchLeaves();
    });
  }

  bool _shouldShowFab(List<Leave> leaves) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hasToday = leaves.any(
      (leave) => leave.leaveDetail.any((d) => d.date == today),
    );
    return !hasToday;
  }

  void _showFullScreenImage(BuildContext context, LeaveDetail detail) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          final url = detail.fileUrl ?? "";
          final isSvg = (detail.fileExtension?.toLowerCase() == 'svg');

          final TransformationController controller =
              TransformationController();
          bool isZoomed = false;

          return StatefulBuilder(
            builder: (context, setState) {
              controller.addListener(() {
                final double scale = controller.value.getMaxScaleOnAxis();
                final bool nowZoomed = scale > 1.5;
                if (nowZoomed != isZoomed) {
                  setState(() => isZoomed = nowZoomed);
                }
              });

              void _snapBackIfNotZoomed() {
                final double scale = controller.value.getMaxScaleOnAxis();
                if (scale <= 1.5) {
                  controller.value = Matrix4.identity();
                  if (isZoomed) setState(() => isZoomed = false);
                }
              }

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;

                          return Center(
                            child: Hero(
                              tag: "leave_image_${detail.id}",
                              child: InteractiveViewer(
                                transformationController: controller,
                                panEnabled: isZoomed,
                                boundaryMargin: isZoomed
                                    ? const EdgeInsets.all(200)
                                    : EdgeInsets.zero,
                                clipBehavior: Clip.hardEdge,
                                minScale: 1.0,
                                maxScale: 4.0,
                                onInteractionEnd: (_) => _snapBackIfNotZoomed(),
                                child: SizedBox(
                                  width: w,
                                  height: h,
                                  child: isSvg
                                      ? SvgPicture.network(
                                          url,
                                          fit: BoxFit.contain,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: url,
                                          fit: BoxFit.contain,
                                          placeholder: (context, _) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          errorWidget: (context, _, __) =>
                                              const Icon(Icons.error,
                                                  color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _downloadFile(detail),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.download,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "1/1",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _downloadFile(LeaveDetail detail) {
    if (detail.fileUrl == null) return;

    Utils.openDownloadBottomsheet(
      context: context,
      storeInExternalStorage: true,
      studyMaterial: StudyMaterial(
        id: detail.id,
        fileName: detail.fileName ?? "file",
        fileUrl: detail.fileUrl ?? "",
        fileExtension: detail.fileExtension ?? "",
        fileThumbnail: "",
        studyMaterialType: StudyMaterialType.file,
      ),
    );
  }

  Widget buildLeaveDates(List<LeaveDetail> leaveDetail) {
    if (leaveDetail.isEmpty) {
      return Text(
        Utils.getTranslatedLabel(noLeaveDetailsKey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      );
    }

    try {
      if (leaveDetail.length == 1) {
        final date = DateTime.tryParse(leaveDetail[0].date) ?? DateTime.now();
        final formattedDate = DateFormat("dd MMM yyyy", 'id').format(date);
        return Text(
          formattedDate,
          style: TextStyle(
            fontSize: 13,
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        );
      } else if (leaveDetail.length > 1) {
        final fromDate =
            DateTime.tryParse(leaveDetail.first.date) ?? DateTime.now();
        final formattedFromDate =
            DateFormat("dd MMM yyyy", 'id').format(fromDate);
        // (kalau butuh rentang, bisa tambahkan toDate & tampilkan)
        return Text(
          formattedFromDate,
          style: TextStyle(
            fontSize: 13,
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          ),
        );
      } else {
        return Text(
          "Invalid date format",
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      return Text(
        "Invalid date format",
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showAttachmentDialog(BuildContext context, LeaveDetail detail) {
    final isImage = detail.fileExtension != null &&
        ['jpg', 'jpeg', 'png', 'gif']
            .contains(detail.fileExtension!.toLowerCase());

    if (isImage && detail.fileUrl != null) {
      _showFullScreenImage(context, detail);
    } else {
      _downloadFile(detail);
    }
  }

  Widget _buildLeaveItem(Leave leave, int index) {
    String leaveType = "";
    String leaveStatus = "";
    Color leaveStatusColor = Colors.grey;
    Color leaveTextColor = Colors.grey;
    IconData leaveIcon = Icons.info_rounded;

    if (leave.leaveDetail.isNotEmpty) {
      // Ambil detail yang BUKAN file; ini bisa kosong kalau semua adalah file
      final sortedDetails = leave.leaveDetail
          .where((detail) => !detail.isFile)
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id));

      if (sortedDetails.isNotEmpty) {
        final type = sortedDetails.first.type;
        final status = leave.status;

        if (status == 1) {
          leaveStatus = "Disetujui";
          leaveStatusColor = const Color(0xFFE6F4EA);
          leaveTextColor = const Color(0xFF2E7D32);
          leaveIcon = Icons.check_circle_rounded;
        } else if (status == 0) {
          leaveStatus = "Tertunda";
          leaveStatusColor = const Color(0xFFFFF4E5);
          leaveTextColor = const Color(0xFFEF6C00);
          leaveIcon = Icons.hourglass_empty_rounded;
        } else if (status == 2) {
          leaveStatus = "Ditolak";
          leaveStatusColor = const Color(0xFFFDEAEA);
          leaveTextColor = Theme.of(context).colorScheme.primary;
          leaveIcon = Icons.cancel;
        }

        if (type.toLowerCase() == "leave") {
          leaveType = "Izin";
        } else if (type.toLowerCase() == "sick") {
          leaveType = "Sakit";
        } else {
          leaveType = "Tipe tidak diketahui";
          leaveStatus = "";
        }
      } else {
        // Semua detail adalah file; tentukan fallback
        leaveType = "Tipe tidak diketahui";
        final status = leave.status;
        if (status == 1) {
          leaveStatus = "Disetujui";
          leaveStatusColor = const Color(0xFFE6F4EA);
          leaveTextColor = const Color(0xFF2E7D32);
          leaveIcon = Icons.check_circle_rounded;
        } else if (status == 0) {
          leaveStatus = "Tertunda";
          leaveStatusColor = const Color(0xFFFFF4E5);
          leaveTextColor = const Color(0xFFEF6C00);
          leaveIcon = Icons.hourglass_empty_rounded;
        } else if (status == 2) {
          leaveStatus = "Ditolak";
          leaveStatusColor = const Color(0xFFFDEAEA);
          leaveTextColor = Theme.of(context).colorScheme.primary;
          leaveIcon = Icons.cancel;
        }
      }
    }

    final typeColor = leaveType == "Sakit"
        ? Theme.of(context).colorScheme.primary
        : Colors.blue;

    return Animate(
      effects: [
        FadeEffect(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
        ),
        SlideEffect(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutQuint,
        ),
      ],
      autoPlay: true,
      onComplete: (controller) => controller.stop(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (leave.status == 1) return; // Disetujui => tidak bisa edit
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => ApplyLeavesContainer(
                    childId: widget.childId,
                    data: leave,
                  ),
                ),
              )
                  .then((_) {
                _fetchLeaves();
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                leaveType == "Sakit"
                                    ? Icons.medical_services_rounded
                                    : Icons.event_busy_rounded,
                                color: typeColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.student.getFullName(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              typeColor.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          leaveType,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: typeColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      buildLeaveDates(leave.leaveDetail),
                                      const Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              leaveStatus.isNotEmpty ? 10 : 7,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: leaveTextColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              leaveIcon,
                                              color: leaveStatusColor,
                                              size: 16,
                                            ),
                                            if (leaveStatus.isNotEmpty)
                                              const SizedBox(width: 6),
                                            Text(
                                              leaveStatus,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: leaveStatusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// Alasan izin (pemohon)
                  ReasonSection(
                    title: 'Alasan izin',
                    text: leave.reason,
                    sourceLabel: 'Wali Murid',
                    icon: Icons.notes_rounded,
                    accent: typeColor,
                    margin: const EdgeInsets.only(top: 0),
                  ),

                  /// Alasan ditolak (reviewer) → tampil hanya jika ada
                  if (leave.rejectReason != "" &&
                      leave.rejectReason.trim().isNotEmpty &&
                      leave.status == 2)
                    ReasonSection(
                      title: 'Alasan ditolak',
                      text: (leave.rejectReason),
                      sourceLabel: 'Guru/Wali Kelas',
                      icon: Icons.block_rounded,
                      accent: typeColor,
                      margin: const EdgeInsets.only(top: 10),
                    ),

                  /// Lampiran
                  if (leave.leaveDetail.any((detail) => detail.isFile)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Lampiran",
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            // aman karena sudah dicek .any(isFile)
                            final fileDetail = leave.leaveDetail
                                .firstWhere((detail) => detail.isFile);
                            _showAttachmentDialog(context, fileDetail);
                          },
                          icon: const Icon(Icons.visibility_rounded, size: 16),
                          label: const Text("Lihat"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeColor.withValues(alpha: 0.1),
                            foregroundColor: typeColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    final dummyLeaves = List.generate(
      5,
      (index) => Leave(
        id: index,
        userId: 0,
        reason: 'This is a dummy reason for the loading state skeletonizer.',
        type: 'Sick',
        fromDate: '2024-01-01',
        toDate: '2024-01-01',
        status: 0,
        schoolId: 0,
        rejectReason: '',
        leaveMasterId: 0,
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
        leaveDetail: [
          LeaveDetail(
            id: index,
            leaveId: index,
            date: '2024-01-01',
            type: 'Sick',
            schoolId: 0,
          )
        ],
        fileDetail: [],
      ),
    );

    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
              ) +
              10,
          bottom: 20,
        ),
        itemCount: dummyLeaves.length,
        itemBuilder: (context, index) => _buildLeaveItem(
          dummyLeaves[index],
          index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: BlocBuilder<LeavesCubit, LeavesState>(
        builder: (context, state) {
          if (state is LeavesFetchSuccess) {
            if (_shouldShowFab(state.leaves)) {
              return FloatingActionButton(
                onPressed: _navigateToApplyLeaves,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: Utils.getTranslatedLabel(applyLeavesKey),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: 1.05,
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  );
            }
            return const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        },
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: RefreshIndicator(
              onRefresh: () async {
                Future.delayed(Duration.zero, () {
                  _fetchLeaves();
                });
              },
              color: Theme.of(context).colorScheme.primary,
              child: BlocBuilder<LeavesCubit, LeavesState>(
                builder: (context, state) {
                  if (state is LeavesFetchInProgress) {
                    return _buildLoadingShimmer();
                  }
                  if (state is LeavesFetchSuccess) {
                    final firstLeave =
                        state.leaves.isNotEmpty ? state.leaves.first : null;
                    final firstDetail =
                        (firstLeave?.leaveDetail.isNotEmpty ?? false)
                            ? firstLeave!.leaveDetail.first
                            : null;

                    if (firstLeave == null ||
                        firstDetail == null ||
                        firstDetail.leaveId == null) {
                      // ⬅️ HILANGKAN AKSES state.leaves[0] di sini
                      debugPrint(
                          "No leaves detail available (empty list or invalid)");
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: Utils.getScrollViewTopPadding(
                            context: context,
                            appBarHeightPercentage:
                                Utils.appBarSmallerHeightPercentage,
                          ),
                        ),
                        child: Animate(
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 500)),
                            ScaleEffect(duration: Duration(milliseconds: 500)),
                          ],
                          autoPlay: true,
                          onComplete: (controller) => controller.stop(),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.15),
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 120,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Belum Ada Data Izin Untuk Hari Ini!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap tombol + untuk mengajukan izin baru',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(
                        top: Utils.getScrollViewTopPadding(
                          context: context,
                          appBarHeightPercentage:
                              Utils.appBarSmallerHeightPercentage,
                        ),
                        bottom: 20,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.leaves.length,
                      itemBuilder: (context, index) {
                        return _buildLeaveItem(state.leaves[index], index);
                      },
                    );
                  }
                  if (state is LeavesFetchFailure) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: Utils.getScrollViewTopPadding(
                          context: context,
                          appBarHeightPercentage:
                              Utils.appBarSmallerHeightPercentage,
                        ),
                      ),
                      child: ErrorContainer(
                        errorMessageCode: state.errorMessage,
                        onTapRetry: _fetchLeaves,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
          ScreenTopBackgroundContainer(
            heightPercentage: Utils.appBarSmallerHeightPercentage,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    const CustomBackButton(),
                    Text(
                      Utils.getTranslatedLabel(leavesKey),
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: Utils.screenTitleFontSize,
                      ),
                    ),
                  ]),
            ),
          )
        ],
      ),
    );
  }
}

/// ===== Reusable UI: blok alasan dengan aksen & chip sumber =====
class ReasonSection extends StatelessWidget {
  const ReasonSection({
    super.key,
    required this.title,
    required this.text,
    required this.sourceLabel,
    required this.icon,
    required this.accent,
    this.margin,
  });

  final String title;
  final String text;
  final String sourceLabel;
  final IconData icon;
  final Color accent;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: margin ?? const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  sourceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ExpandableText(
            text: text,
            style: TextStyle(
              height: 1.35,
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
