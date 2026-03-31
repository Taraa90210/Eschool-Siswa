import 'package:eschool/cubits/subjectAttendanceCubit.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/widgets/subjectAttendanceContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class SubjectAttendanceAtDayScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final int? childId;

  const SubjectAttendanceAtDayScreen({
    Key? key,
    this.selectedDate,
    this.childId,
  }) : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return SubjectAttendanceAtDayScreen(
      selectedDate: arguments['selectedDate'] as DateTime?,
      childId: arguments['childId'] as int?,
    );
  }

  @override
  State<SubjectAttendanceAtDayScreen> createState() =>
      _SubjectAttendanceAtDayScreenState();
}

class _SubjectAttendanceAtDayScreenState
    extends State<SubjectAttendanceAtDayScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocProvider<SubjectAttendanceCubit>(
            create: (_) => SubjectAttendanceCubit(StudentRepository()),
            child: SubjectAttendanceContainer(
              childId: widget.childId,
              fixedDate: _selectedDate,
            ),
          ),
        ],
      ),
    );
  }
}
