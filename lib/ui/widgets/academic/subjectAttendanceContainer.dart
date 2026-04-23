import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/student/subjectAttendanceCubit.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/data/models/student/subjectAttendanceModel.dart';
import 'package:eschool/ui/widgets/system/changeCalendarMonthButton.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/academic/subjectImageContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SubjectAttendanceContainer extends StatefulWidget {
  final int? childId;
  final DateTime? fixedDate; // New parameter for fixed date

  const SubjectAttendanceContainer({
    Key? key,
    this.childId,
    this.fixedDate, // Add this parameter
  }) : super(key: key);

  @override
  State<SubjectAttendanceContainer> createState() =>
      _SubjectAttendanceContainerState();
}

class _SubjectAttendanceContainerState extends State<SubjectAttendanceContainer>
    with TickerProviderStateMixin {
  late DateTime selectedDate;
  final DateFormat dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id');
  late AnimationController _animationController;

  // More elegant color scheme
  final Color primaryColor = Color(0xFFE53935); // Red
  final Color accentColor = Color(0xFFC62828); // Darker red
  final Color lightColor = Color(0xFFFFEBEE); // Light red
  final Color surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Use fixed date if provided, otherwise use current date
    selectedDate = widget.fixedDate ?? DateTime.now();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    Future.delayed(Duration.zero, () {
      _fetchSubjectAttendance();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchSubjectAttendance() {
    context.read<SubjectAttendanceCubit>().fetchSubjectAttendance(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId ?? 0,
          date: selectedDate,
        );
  }

  String _getDayInIndonesian(String englishDay) {
    switch (englishDay.toLowerCase()) {
      case 'monday':
        return 'Senin';
      case 'tuesday':
        return 'Selasa';
      case 'wednesday':
        return 'Rabu';
      case 'thursday':
        return 'Kamis';
      case 'friday':
        return 'Jumat';
      case 'saturday':
        return 'Sabtu';
      case 'sunday':
        return 'Minggu';
      default:
        return englishDay;
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              return GestureDetector(
                onTap: () {
                  // Close on tap anywhere on the screen
                  Navigator.of(context).pop();
                },
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        // Main image with zoom
                        Center(
                          child: GestureDetector(
                            // Prevent taps on the image from closing
                            onTap: () {
                              // Stop propagation by doing nothing
                            },
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 2.5,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: Colors.white, size: 64),
                                      SizedBox(height: 16),
                                      Text(
                                        'Gagal memuat gambar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // Title at top
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lampiran',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Control buttons
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Row(
                            children: [
                              // Close button
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
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildSubjectAttendanceItem(SubjectAttendance attendance, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
                color: Colors.white, // Changed to bright white
                // Removed the gradient to keep it pure white
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Optional: Expand card to show more details
                },
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag:
                            'subject_image_${attendance.subjectAttendance.timetable.subject.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SubjectImageContainer(
                              showShadow: false,
                              height: 75,
                              width: 75,
                              radius: 12,
                              subject: attendance
                                  .subjectAttendance.timetable.subject,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    attendance
                                        .subjectAttendance.timetable.subject
                                        .getSubjectName(context: context),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                                _buildAttendanceStatus(attendance.type),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(Icons.access_time_rounded,
                                '${attendance.subjectAttendance.timetable.startTime} - ${attendance.subjectAttendance.timetable.endTime}'),
                            if (attendance.subjectAttendance.materi.isNotEmpty)
                              _buildInfoRow(
                                Icons.menu_book_rounded,
                                'Materi: ${attendance.subjectAttendance.materi}',
                                showDivider: true,
                              ),
                            if (attendance.note?.isNotEmpty ?? false)
                              _buildInfoRow(
                                Icons.notes_rounded,
                                'Catatan: ${attendance.note}',
                                isNote: true,
                                showDivider: true,
                              ),
                            if (attendance
                                    .subjectAttendance.lampiran?.isNotEmpty ??
                                false)
                              _buildAttachmentButton(
                                  attendance.subjectAttendance.lampiran!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {bool isNote = false, bool showDivider = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.withValues(alpha: 0.1)),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: primaryColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: isNote ? FontStyle.italic : FontStyle.normal,
                    color: isNote ? Colors.grey[600] : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentButton(String attachmentUrl) {
    // Check if attachment is an image based on extension
    bool isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
        .any((ext) => attachmentUrl.toLowerCase().endsWith(ext));

    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isImage) {
              _showImageDialog(context, attachmentUrl);
            } else {
              Utils.openDownloadBottomsheet(
                context: context,
                storeInExternalStorage: true,
                studyMaterial: StudyMaterial(
                  id: 0,
                  fileName: Uri.parse(attachmentUrl).pathSegments.last,
                  fileUrl: attachmentUrl,
                  fileExtension: attachmentUrl.split('.').last,
                  fileThumbnail: "",
                  studyMaterialType: StudyMaterialType.file,
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: lightColor,
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isImage ? Icons.image_rounded : Icons.attach_file_rounded,
                    size: 18, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  isImage ? 'Lihat Lampiran' : 'Unduh Lampiran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus(int type) {
    String status;
    Color color;
    IconData icon;

    switch (type) {
      case 1:
        status = 'Hadir';
        color = hadirColor;
        icon = Icons.check_circle;
        break;
      case 2:
        status = 'Sakit';
        color = sakitColor;
        icon = Icons.medical_services;
        break;
      case 3:
        status = 'Izin';
        color = izinColor;
        icon = Icons.event_busy;
        break;
      case 4:
        status = 'Alpa';
        color = alpaColor;
        icon = Icons.cancel;
        break;
      default:
        status = 'Tidak diketahui';
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: RefreshIndicator(
            displacement: Utils.getScrollViewTopPadding(
              context: context,
              appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
            ),
            color: primaryColor,
            backgroundColor: Colors.white,
            onRefresh: () async {
              _fetchSubjectAttendance();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                // bottom: Utils.getScrollViewBottomPadding(context) + 16,
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  BlocBuilder<SubjectAttendanceCubit, SubjectAttendanceState>(
                    builder: (context, state) {
                      if (state is SubjectAttendanceFetchInProgress) {
                        return Column(children: [
                          // _buildDateSelector(),
                          _buildAttendanceLoading(),
                        ]);
                      } else if (state is SubjectAttendanceFetchSuccess) {
                        String selectedDay =
                            DateFormat('EEEE', 'en_US').format(selectedDate);
                        String selectedDateStr =
                            DateFormat('yyyy-MM-dd').format(selectedDate);

                        List<SubjectAttendance> filteredAttendances =
                            state.subjectAttendances.where((attendance) {
                          return attendance.subjectAttendance.timetable.day
                                      .toLowerCase() ==
                                  selectedDay.toLowerCase() &&
                              attendance.subjectAttendance.date ==
                                  selectedDateStr;
                        }).toList();

                        if (filteredAttendances.isEmpty) {
                          bool hasScheduleForDay = state.subjectAttendances.any(
                              (attendance) =>
                                  attendance.subjectAttendance.timetable.day
                                      .toLowerCase() ==
                                  selectedDay.toLowerCase());

                          return Column(children: [
                            // _buildDateSelector(),
                            Container(
                              height: 250,
                              margin: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white, // Changed to bright white
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: lightColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        hasScheduleForDay
                                            ? Icons.pending_actions_rounded
                                            : Icons.event_busy_rounded,
                                        size: 40,
                                        color: primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        hasScheduleForDay
                                            ? 'Belum ada data absensi untuk hari ini. Hubungi guru Anda untuk melakukan absensi'
                                            : 'Tidak ada jadwal pelajaran untuk hari ${_getDayInIndonesian(selectedDay)}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.5,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    // Don't show reload button for fixed date view
                                    if (widget.fixedDate == null)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () =>
                                            _fetchSubjectAttendance(),
                                        child: Text('Muat Ulang'),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          ]);
                        }

                        return AnimationLimiter(
                          child: Column(children: [
                            // _buildDateSelector(),
                            Column(
                              children: List.generate(
                                filteredAttendances.length,
                                (index) => _buildSubjectAttendanceItem(
                                  filteredAttendances[index],
                                  index,
                                ),
                              ),
                            )
                          ]),
                        );
                      } else if (state is SubjectAttendanceFetchFailure) {
                        return ErrorContainer(
                          errorMessageCode: state.errorMessage,
                          onTapRetry: _fetchSubjectAttendance,
                        );
                      }
                      return Container();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: _buildAppBar(),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          context.read<AuthCubit>().isParent() || widget.fixedDate != null
              ? Positioned(
                  left: 10,
                  top: -2,
                  child: const CustomBackButton(),
                )
              : const SizedBox(),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              Utils.getTranslatedLabel(subjectAttendanceKey),
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -20,
            start: MediaQuery.of(context).size.width * (0.075),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.075),
                    offset: const Offset(2.5, 2.5),
                    blurRadius: 5,
                  )
                ],
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              width: MediaQuery.of(context).size.width * (0.85),
              child: Stack(
                children: [
                  Align(
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary:
                                      Theme.of(context).colorScheme.primary,
                                  onPrimary: Colors.white,
                                  surface: surfaceColor,
                                  onSurface: Colors.grey[800] ?? Colors.grey,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                ),
                                datePickerTheme: DatePickerThemeData(
                                  headerBackgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  headerForegroundColor: Colors.white,
                                  headerHeadlineStyle: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  dayOverlayColor:
                                      WidgetStateProperty.resolveWith(
                                    (states) => states
                                            .contains(WidgetState.selected)
                                        ? primaryColor.withValues(alpha: 0.2)
                                        : null,
                                  ),
                                  dayStyle:
                                      TextStyle(fontWeight: FontWeight.w500),
                                  todayForegroundColor:
                                      WidgetStateProperty.all(primaryColor),
                                  todayBackgroundColor: WidgetStateProperty.all(
                                      lightColor.withValues(alpha: 0.7)),
                                  yearOverlayColor:
                                      WidgetStateProperty.resolveWith(
                                    (states) => states
                                            .contains(WidgetState.selected)
                                        ? primaryColor.withValues(alpha: 0.2)
                                        : null,
                                  ),
                                  yearStyle:
                                      TextStyle(fontWeight: FontWeight.w500),
                                  surfaceTintColor: Colors.transparent,
                                  backgroundColor: Colors.white,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.1),
                                  dividerColor: Colors.transparent,
                                  // Move buttons higher with button bar theme
                                  rangePickerBackgroundColor: Colors.white,
                                  rangeSelectionBackgroundColor: lightColor,
                                  rangeSelectionOverlayColor:
                                      WidgetStateProperty.all(
                                          primaryColor.withValues(alpha: 0.1)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  // Adjust the input decoration theme
                                  inputDecorationTheme: InputDecorationTheme(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.8,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey
                                              .withValues(alpha: 0.3)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    errorStyle: TextStyle(
                                      fontSize: 12,
                                      height: 0.8,
                                    ),
                                  ),
                                ),
                                dialogTheme: DialogThemeData(
                                    backgroundColor: Colors.transparent),
                              ),
                              child: MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  textScaler: TextScaler.linear(1.0),
                                ),
                                child: Builder(
                                  builder: (context) => Dialog(
                                    insetPadding: EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom >
                                              0
                                          ? 16.0
                                          : 24.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                (MediaQuery.of(context)
                                                            .viewInsets
                                                            .bottom >
                                                        0
                                                    ? 0.7
                                                    : 0.85),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: SingleChildScrollView(
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              child: child!,
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
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                            _fetchSubjectAttendance();
                          });
                          _animationController.forward(from: 0.0);
                        }
                      },
                      child: Text(
                        "${dateFormatter.format(selectedDate)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ChangeCalendarMonthButton(
                      isDisable: false,
                      isNextButton: false,
                      onTap: () {
                        setState(() {
                          selectedDate =
                              selectedDate.subtract(Duration(days: 1));
                          _fetchSubjectAttendance();
                        });
                        _animationController.forward(from: 0.0);
                      },
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ChangeCalendarMonthButton(
                      onTap: () {
                        setState(() {
                          if (selectedDate
                              .add(Duration(days: 1))
                              .isAfter(DateTime.now())) return;
                          selectedDate = selectedDate.add(Duration(days: 1));
                          _fetchSubjectAttendance();
                        });
                        _animationController.forward(from: 0.0);
                      },
                      isDisable: selectedDate
                          .add(Duration(days: 1))
                          .isAfter(DateTime.now()),
                      isNextButton: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceLoading() {
    return ShimmerLoadingContainer(
      child: Column(
        children: List.generate(
          3,
          (index) => Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: Container(
              height: 140,
              padding: EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }
}
