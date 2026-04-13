import 'dart:async';

import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/timeTableCubit.dart';
import 'package:eschool/data/models/timeTableSlot.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/subjectImageContainer.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class TimeTableContainer extends StatefulWidget {
  final int? childId;
  const TimeTableContainer({Key? key, this.childId}) : super(key: key);

  @override
  State<TimeTableContainer> createState() => _TimeTableContainerState();
}

class _TimeTableContainerState extends State<TimeTableContainer>
    with SingleTickerProviderStateMixin {
  late int _currentSelectedDayIndex = DateTime.now().weekday - 1;
  Timer? _tick;
  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    Future.delayed(Duration.zero, () {
      context.read<TimeTableCubit>().fetchStudentTimeTable(
            useParentApi: context.read<AuthCubit>().isParent(),
            childId: widget.childId,
          );
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  List<TimeTableSlot> _buildTimeTableSlots(List<TimeTableSlot> timeTableSlot) {
    final selectedDay = Utils.weekDaysFullForm[_currentSelectedDayIndex];
    final dayWiseTimeTableSlots =
        timeTableSlot.where((element) => element.day == selectedDay).toList();
    return dayWiseTimeTableSlots;
  }

  Widget _buildTimeTableShimmerLoadingContainer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: Utils.screenContentHorizontalPaddingInPercentage *
            MediaQuery.of(context).size.width,
      ),
      child: ShimmerLoadingContainer(
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Row(
              children: [
                CustomShimmerContainer(
                  height: 60,
                  width: boxConstraints.maxWidth * (0.25),
                ),
                SizedBox(
                  width: boxConstraints.maxWidth * (0.05),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomShimmerContainer(
                      height: 9,
                      width: boxConstraints.maxWidth * (0.6),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    CustomShimmerContainer(
                      height: 8,
                      width: boxConstraints.maxWidth * (0.5),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeTableLoading() {
    return ShimmerLoadingContainer(
      child: Column(
        children: List.generate(5, (index) => index)
            .map((e) => _buildTimeTableShimmerLoadingContainer())
            .toList(),
      ),
    );
  }

  Widget _buildAppBar() {
    String getStudentClassDetails = "";
    if (context.read<AuthCubit>().isParent()) {
      final studentDetails =
          (context.read<AuthCubit>().getParentDetails().children ?? [])
              .where((element) => element.id == widget.childId)
              .first;

      getStudentClassDetails = studentDetails.classSection?.name ?? "";
    } else {
      getStudentClassDetails =
          context.read<AuthCubit>().getStudentDetails().classSection?.name ??
              "";
    }
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.childId == null ? const SizedBox() : const CustomBackButton(),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              Utils.getTranslatedLabel(timeTableKey),
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: MediaQuery.of(context).size.width * (0.075),
            child: Container(
              alignment: Alignment.center,
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
              child: Text(
                "${Utils.getTranslatedLabel(classKey)} - $getStudentClassDetails",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContainer(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 5.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentSelectedDayIndex = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: index == _currentSelectedDayIndex
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            Utils.getTranslatedLabel(Utils.weekDays[index]),
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: index == _currentSelectedDayIndex
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDays() {
    final List<Widget> children = [];

    for (var i = 0; i < Utils.weekDays.length; i++) {
      children.add(_buildDayContainer(i));
    }

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE), // Light gray background
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.07,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    );
  }

  Widget _buildTimeTableSlotDetailsContainer({
    required TimeTableSlot timeTableSlot,
  }) {
    final isBreak =
        timeTableSlot.subject.getSubjectName(context: context).isEmpty;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Hitung slot aktif: hanya slot di hari yang dipilih DAN hari ini yang dicek jam aktif
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    bool isActive = false;
    if (_currentSelectedDayIndex == todayIndex) {
      final nowSec = now.hour * 3600 + now.minute * 60 + now.second;
      final s = _toSecondsSinceMidnight(timeTableSlot.startTime);
      final e = _toSecondsSinceMidnight(timeTableSlot.endTime);
      isActive = (s <= e)
          ? (nowSec >= s && nowSec <= e)
          : (nowSec >= s || nowSec <= e);
    }

    final double imageWidth = MediaQuery.of(context).size.width * 0.175;
    const double imageHeight = 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.075),
            offset: const Offset(4, 4),
            blurRadius: 10,
          )
        ],
        color: isActive
            ? cs.primary // background aktif
            : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: cs.primary, width: 1) : null,
      ),
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 12.5, vertical: 10.0),
      child: Row(
        children: [
          isBreak
              ? Container(
                  height: imageHeight,
                  width: imageWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.5),
                    color: (isActive
                        ? cs.primary.withValues(alpha: 0.18)
                        : cs.primary.withValues(
                            alpha: 0.10)), // bg icon break aktif/nonaktif
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: imageWidth * 0.15,
                    vertical: imageHeight * 0.15,
                  ),
                  child: SvgPicture.asset(
                    Utils.getImagePath("lunch-time.svg"),
                    colorFilter: ColorFilter.mode(
                      isActive
                          ? cs.onTertiary // warna icon saat aktif
                          : cs.primary, // warna icon saat aktif
                      BlendMode.srcIn,
                    ),
                  ),
                )
              : SubjectImageContainer(
                  showShadow: false,
                  height: imageHeight,
                  width: imageWidth,
                  radius: 7.5,
                  subject: timeTableSlot.subject,
                ),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${Utils.formatTime(timeTableSlot.startTime)} - ${Utils.formatTime(timeTableSlot.endTime)}",
                  style: TextStyle(
                    color: isActive ? cs.surface : cs.secondary, // jam aktif
                    fontWeight: FontWeight.w700,
                    fontSize: 14.0,
                  ),
                ),
                Text(
                  timeTableSlot.note == 'Break'
                      ? Utils.getTranslatedLabel(breakKey)
                      : timeTableSlot.subject
                              .getSubjectName(context: context)
                              .isEmpty
                          ? timeTableSlot.note
                          : timeTableSlot.subject
                              .getSubjectName(context: context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? cs.surface : cs.secondary,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400, // tebalkan saat aktif
                    fontSize: 12.0,
                  ),
                ),
                Text(
                  "${timeTableSlot.teacherFirstName} ${timeTableSlot.teacherLastName}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? cs.surface : cs.secondary,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTable() {
    return BlocBuilder<TimeTableCubit, TimeTableState>(
      builder: (context, state) {
        if (state is TimeTableFetchSuccess) {
          final timetableSlots = _buildTimeTableSlots(state.timeTable);
          return SizedBox(
            width: MediaQuery.of(context).size.width,
            child: timetableSlots.isEmpty
                ? NoDataContainer(
                    key: isApplicationItemAnimationOn ? UniqueKey() : null,
                    titleKey: noLecturesKey,
                  )
                : Column(
                    children: List.generate(
                      timetableSlots.length,
                      (index) => Animate(
                        key: isApplicationItemAnimationOn ? UniqueKey() : null,
                        effects: listItemAppearanceEffects(
                          itemIndex: index,
                          totalLoadedItems: timetableSlots.length,
                        ),
                        child: _buildTimeTableSlotDetailsContainer(
                          timeTableSlot: timetableSlots[index],
                        ),
                      ),
                    ),
                  ),
          );
        }
        if (state is TimeTableFetchFailure) {
          return ErrorContainer(
            key: isApplicationItemAnimationOn ? UniqueKey() : null,
            errorMessageCode: state.errorMessage,
            onTapRetry: () {
              context.read<TimeTableCubit>().fetchStudentTimeTable(
                    useParentApi: context.read<AuthCubit>().isParent(),
                    childId: widget.childId,
                  );
            },
          );
        }

        return _buildTimeTableLoading();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print("TimeTableContainer");
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: Utils.getScrollViewBottomPadding(context),
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * (0.025),
                ),
                _buildDays(),
                SizedBox(
                  height: MediaQuery.of(context).size.height * (0.025),
                ),
                _buildTimeTable(),
              ],
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
}

// Ubah: dukung DateTime, TimeOfDay, dan String "HH:mm" / "HH:mm:ss"
int _toSecondsSinceMidnight(dynamic t) {
  if (t is DateTime) {
    return t.hour * 3600 + t.minute * 60 + t.second;
  }
  if (t is TimeOfDay) {
    return t.hour * 3600 + t.minute * 60;
  }
  if (t is String) {
    final parts = t.trim().split(':');
    if (parts.length < 2 || parts.length > 3) {
      throw ArgumentError('Time string must be HH:mm or HH:mm:ss, got "$t"');
    }
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final s = parts.length == 3 ? int.parse(parts[2]) : 0;

    if (h < 0 || h > 23 || m < 0 || m > 59 || s < 0 || s > 59) {
      throw ArgumentError('Time out of range: "$t"');
    }
    return h * 3600 + m * 60 + s;
  }
  throw ArgumentError('Unsupported time type: ${t.runtimeType}');
}
