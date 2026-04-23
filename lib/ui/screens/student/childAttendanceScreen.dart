import 'package:eschool/cubits/student/attendanceCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/widgets/attendanceContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ChildAttendanceScreen extends StatelessWidget {
  final int childId;
  const ChildAttendanceScreen({Key? key, required this.childId})
      : super(key: key);

  static Widget routeInstance() {
    return BlocProvider<AttendanceCubit>(
      create: (context) => AttendanceCubit(StudentRepository()),
      child: Builder(
        builder: (context) {
          final arguments = Get.arguments;
          int childId;
          
          // Handle dari notifikasi (Map) atau navigasi normal (int)
          if (arguments is int) {
            childId = arguments;
          } else if (arguments is Map<String, dynamic> && arguments['childId'] != null) {
            childId = arguments['childId'] is int 
                ? arguments['childId'] 
                : int.tryParse(arguments['childId'].toString()) ?? context.read<AuthCubit>().getStudentDetails().id ?? 0;
          } else {
            // Fallback: ambil dari AuthCubit
            childId = context.read<AuthCubit>().getStudentDetails().id ?? 0;
          }
          
          return ChildAttendanceScreen(childId: childId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AttendanceContainer(
        childId: childId,
      ),
    );
  }
}
