import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/attendanceCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/data/models/attendanceDay.dart';
import 'package:eschool/ui/widgets/changeCalendarMonthButton.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';

import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

//
import 'package:auto_size_text/auto_size_text.dart';
import 'package:eschool/ui/styles/colors.dart';

class AttendanceContainer extends StatefulWidget {
  final int? childId;
  const AttendanceContainer({Key? key, this.childId}) : super(key: key);

  @override
  State<AttendanceContainer> createState() => _AttendanceContainerState();
}

class _AttendanceContainerState extends State<AttendanceContainer> {
  //last and first day of calendar
  late DateTime firstDay = DateTime.now();
  late DateTime lastDay = DateTime.now();

  //current day
  late DateTime focusedDay = DateTime.now();

  PageController? calendarPageController;

  // Galang
  bool isModalOpen = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      //fetch attendacne
      context.read<AttendanceCubit>().fetchAttendance(
            month: DateTime.now().month,
            year: DateTime.now().year,
            useParentApi: context.read<AuthCubit>().isParent(),
            childId: widget.childId,
          );
    });

    super.initState();
  }

  bool _disableChangeNextMonthButton() {
    return focusedDay.year == DateTime.now().year &&
        focusedDay.month == DateTime.now().month;
  }

  bool _disableChangePrevMonthButton() {
    return firstDay.month == focusedDay.month &&
        firstDay.year == focusedDay.year;
  }

  Widget _buildShimmerAttendanceCounterContainer(
    BoxConstraints boxConstraints,
  ) {
    return ShimmerLoadingContainer(
      child: CustomShimmerContainer(
        height: boxConstraints.maxWidth * (0.425),
        width: boxConstraints.maxWidth * (0.425),
      ),
    );
  }

  // Galang
  Widget _buildAttendanceCounterHadirContainer({
    required String title,
    required BoxConstraints boxConstraints,
    required String value,
    required Color backgroundColor,
    required List<AttendanceDay> presentDays,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isModalOpen = true; // Set isModalOpen true saat modal dibuka
        });

        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4, // Tinggi garis
                    width: 70, // Lebar garis
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 164, 156, 156), // Warna garis
                      borderRadius: BorderRadius.circular(16), // Border radius
                    ),
                  ),
                  SizedBox(height: 10),
                  AutoSizeText(
                    Utils.getTranslatedLabel(detailspresentKey),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  // Widget untuk menampilkan data absensi
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: hadirColor,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hadir',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${presentDays.length} Hari',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[200],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ).whenComplete(() {
          setState(() {
            isModalOpen = false; // Set isModalOpen false saat modal ditutup
          });
        });
      },
      child: Container(
        height: boxConstraints.maxWidth * 0.425,
        width: boxConstraints.maxWidth * 0.425,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.25),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              title,
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontWeight: FontWeight.w600,
                fontSize: 15.0,
              ),
              maxLines: 2,
            ),
            SizedBox(height: boxConstraints.maxWidth * (0.45) * (0.125)),
            CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Text(
                  (presentDays.length).toString(), // Total semua jenis absensi
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Icon(
            //   isModalOpen
            //       ? Icons.keyboard_arrow_up
            //       : Icons.keyboard_arrow_down,
            //   color: Theme.of(context).scaffoldBackgroundColor,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCounterWithModalContainer({
    required String title,
    required BoxConstraints boxConstraints,
    required String value,
    required Color backgroundColor,
    required List<AttendanceDay> sakitDays,
    required List<AttendanceDay> izinDays,
    required List<AttendanceDay> alpaDays,
    required List<AttendanceDay> absentDays,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isModalOpen = true; // Set isModalOpen true saat modal dibuka
        });

        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4, // Tinggi garis
                    width: 70, // Lebar garis
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 164, 156, 156), // Warna garis
                      borderRadius: BorderRadius.circular(16), // Border radius
                    ),
                  ),
                  SizedBox(height: 10),
                  AutoSizeText(
                    Utils.getTranslatedLabel(detailsabsentKey),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  // Widget untuk menampilkan data absensi
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: sakitColor,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.healing, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sakit',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${sakitDays.length} Hari',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[200],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 4),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: izinColor,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.note_alt, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Izin',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${izinDays.length} Hari',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[200],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: alpaColor,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alpa',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${alpaDays.length} Hari',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[200],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                ],
              ),
            );
          },
        ).whenComplete(() {
          setState(() {
            isModalOpen = false; // Set isModalOpen false saat modal ditutup
          });
        });
      },
      child: Container(
        height: boxConstraints.maxWidth * 0.425,
        width: boxConstraints.maxWidth * 0.425,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.25),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AutoSizeText(
              title,
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontWeight: FontWeight.w600,
                fontSize: 15.0,
              ),
              maxLines: 2,
            ),
            SizedBox(height: boxConstraints.maxWidth * (0.45) * (0.125)),
            CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Text(
                  (absentDays.length +
                          izinDays.length +
                          sakitDays.length +
                          alpaDays.length)
                      .toString(), // Total semua jenis absensi
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Icon(
            //   isModalOpen
            //       ? Icons.keyboard_arrow_up
            //       : Icons.keyboard_arrow_down,
            //   color: Theme.of(context).scaffoldBackgroundColor,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          context.read<AuthCubit>().isParent()
              ? const CustomBackButton()
              : const SizedBox(),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              Utils.getTranslatedLabel(attendanceKey),
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
                    child: Text(
                      "${Utils.getTranslatedLabel(Utils.getMonthName(focusedDay.month))} ${focusedDay.year}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ChangeCalendarMonthButton(
                      isDisable: _disableChangePrevMonthButton(),
                      isNextButton: false,
                      onTap: () {
                        if (context.read<AttendanceCubit>().state
                            is AttendanceFetchInProgress) {
                          return;
                        }
                        if (_disableChangePrevMonthButton()) {
                          return;
                        }

                        calendarPageController?.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ChangeCalendarMonthButton(
                      onTap: () {
                        if (context.read<AttendanceCubit>().state
                            is AttendanceFetchInProgress) {
                          return;
                        }
                        if (_disableChangeNextMonthButton()) {
                          return;
                        }
                        calendarPageController?.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      isDisable: _disableChangeNextMonthButton(),
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

  Widget _buildCalendarContainer({
    required List<AttendanceDay> presentDays,
    required List<AttendanceDay> absentDays,
    required List<AttendanceDay> alpaDays,
    required List<AttendanceDay> sakitDays,
    required List<AttendanceDay> izinDays,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .secondary
                .withValues(alpha: 0.075),
            offset: const Offset(5.0, 5),
            blurRadius: 10,
          )
        ],
        borderRadius: BorderRadius.circular(15.0),
      ),
      margin: const EdgeInsets.only(top: 20),
      child: TableCalendar(
        locale: 'id_ID',
        headerVisible: false,
        daysOfWeekHeight: 40,

        onPageChanged: (DateTime dateTime) {
          setState(() {
            focusedDay = dateTime;
          });

          //fetch attendance by year and month
          context.read<AttendanceCubit>().fetchAttendance(
                month: dateTime.month,
                year: dateTime.year,
                useParentApi: context.read<AuthCubit>().isParent(),
                childId: widget.childId,
              );
        },

        onCalendarCreated: (contoller) {
          calendarPageController = contoller;
        },

        //holiday date will be in use to make present dates
        holidayPredicate: (dateTime) {
          return presentDays.indexWhere(
                (element) {
                  return Utils.formatDate(dateTime) ==
                      Utils.formatDate(element.date);
                },
              ) !=
              -1;
        },

        //selected date will be in use to mark absent dates
        selectedDayPredicate: (dateTime) {
          return (absentDays + sakitDays + alpaDays + izinDays).indexWhere(
                (element) =>
                    Utils.formatDate(dateTime) ==
                    Utils.formatDate(element.date),
              ) !=
              -1;
        },
        availableGestures: AvailableGestures.none,
        onDaySelected: (selectedDay, focusedDay) {
          Get.toNamed(
            Routes.subjectAttendanceAtDay,
            arguments: {
              "childId": widget.childId,
              "selectedDate": selectedDay,
            },
          );
          // if (isPresent) {
          //   Get.toNamed(
          //     Routes.subjectAttendanceAtDay,
          //     arguments: {
          //       "childId": widget.childId,
          //       "selectedDate": selectedDay,
          //     },
          //   );
          // }
        },
        calendarStyle: CalendarStyle(
          isTodayHighlighted: false,
          holidayTextStyle:
              TextStyle(color: Theme.of(context).scaffoldBackgroundColor),
          holidayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          selectedDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekendStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          weekdayStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        headerStyle:
            const HeaderStyle(titleCentered: true, formatButtonVisible: false),
        firstDay: firstDay, //start education year
        lastDay: lastDay, //end education year
        focusedDay: focusedDay,
      ),
    );
  }

  Widget _buildAttendaceCalendar() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: Utils.getScrollViewBottomPadding(context),
        top: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
        ),
      ),
      child: Column(
        children: [
          BlocConsumer<AttendanceCubit, AttendanceState>(
            listener: (context, state) {
              if (state is AttendanceFetchSuccess) {
                //if current day falls into session year calendar then change the
                //start and end date
                if (Utils.isTodayInSessionYear(
                  state.sessionYear.getStartDateInDateTime(),
                  state.sessionYear.getEndDateInDateTime(),
                )) {
                  lastDay = state.sessionYear.getEndDateInDateTime();
                  firstDay = state.sessionYear.getStartDateInDateTime();
                  setState(() {});
                }
              }
            },
            builder: (context, state) {
              if (state is AttendanceFetchSuccess) {
                //filter out the present and absent days
                print("Attendance days: ${state.attendanceDays.length}");
                List<AttendanceDay> presentDays = state.attendanceDays
                    .where((element) => element.type == 1)
                    .toList();
                List<AttendanceDay> absentDays = state.attendanceDays
                    .where((element) => element.type == 0)
                    .toList();
                List<AttendanceDay> alpaDays = state.attendanceDays
                    .where((element) => element.type == 4)
                    .toList();
                List<AttendanceDay> sakitDays = state.attendanceDays
                    .where((element) => element.type == 2)
                    .toList();
                List<AttendanceDay> izinDays = state.attendanceDays
                    .where((element) => element.type == 3)
                    .toList();

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * (0.075),
                  ),
                  child: Column(
                    children: [
                      _buildCalendarContainer(
                        presentDays: presentDays,
                        absentDays: absentDays,
                        alpaDays: alpaDays,
                        sakitDays: sakitDays,
                        izinDays: izinDays,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * (0.05),
                      ),
                      LayoutBuilder(
                        builder: (context, boxConstraints) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAttendanceCounterHadirContainer(
                                boxConstraints: boxConstraints,
                                title: Utils.getTranslatedLabel(
                                  totalPresentKey,
                                ),
                                value: presentDays.length.toString(),
                                backgroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                presentDays: presentDays,
                              ),
                              const Spacer(),
                              _buildAttendanceCounterWithModalContainer(
                                boxConstraints: boxConstraints,
                                title: Utils.getTranslatedLabel(
                                  totalAbsentKey,
                                ),
                                value: absentDays.length.toString(),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                sakitDays: sakitDays, // Pass sakitDays
                                izinDays: izinDays, // Pass izinDays
                                alpaDays: alpaDays, // Pass alpaDays
                                absentDays: absentDays,
                              ),
                            ],
                          );
                        },
                      )
                    ],
                  ),
                );
              }
              if (state is AttendanceFetchFailure) {
                return ErrorContainer(
                  errorMessageCode: state.errorMessage,
                  showErrorImage: false,
                  onTapRetry: () {
                    context.read<AttendanceCubit>().fetchAttendance(
                          month: focusedDay.month,
                          year: focusedDay.year,
                          useParentApi: context.read<AuthCubit>().isParent(),
                          childId: widget.childId,
                        );
                  },
                );
              }

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * (0.075),
                ),
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    return Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        ShimmerLoadingContainer(
                          child: CustomShimmerContainer(
                            width: boxConstraints.maxWidth,
                            height:
                                MediaQuery.of(context).size.height * (0.425),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * (0.05),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildShimmerAttendanceCounterContainer(
                              boxConstraints,
                            ),
                            const Spacer(),
                            _buildShimmerAttendanceCounterContainer(
                              boxConstraints,
                            )
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildAttendaceCalendar(),
        _buildAppBar(),
      ],
    );
  }
}
