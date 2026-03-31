import 'package:eschool/data/repositories/leavesRepository.dart';
// import 'package:eschool/data/models/leave.dart';
import 'package:eschool/cubits/leavesCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
// import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/ui/widgets/leavesListContainer.dart';
import 'package:eschool/data/models/student.dart';

class ChildLeavesScreen extends StatelessWidget {
  final int childId;
  final Student student;
  const ChildLeavesScreen({
    Key? key,
    required this.childId,
    required this.student,
  }) : super(key: key);

  // Ganti St
  // static Route route(RouteSettings routeSettings) {
  //   final student = routeSettings.arguments as Student;
  //   return CupertinoPageRoute(
  //     builder: (_) => BlocProvider<LeavesCubit>(
  //       create: (context) => LeavesCubit(LeavesRepository()),
  //         child: ChildLeavesScreen(
  //           childId: student.id!,
  //           student: student,
  //       ),
  //      ),
  //     );
  // }

  // Ganti Struktur kode route -- Galang
  static Widget routeInstance(dynamic arguments) {
    return BlocProvider<LeavesCubit>(
      create: (context) => LeavesCubit(LeavesRepository()),
      child: Builder(
        builder: (context) {
          Student student;
          
          // Handle dari notifikasi (Map) atau navigasi normal (Student object)
          if (arguments is Student) {
            student = arguments;
          } else if (arguments is Map<String, dynamic>) {
            // Coba parse dari Map, atau ambil dari AuthCubit
            try {
              student = Student.fromJson(arguments);
            } catch (e) {
              // Fallback: ambil student yang sedang login dari AuthCubit
              student = context.read<AuthCubit>().getStudentDetails();
            }
          } else {
            // Fallback: ambil student yang sedang login dari AuthCubit
            student = context.read<AuthCubit>().getStudentDetails();
          }
          
          return ChildLeavesScreen(
            childId: student.id!,
            student: student,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ChildSubjectAttendanceScreen()');

    return Scaffold(
      body: LeavesListContainer(
        childId: childId,
        student: student,
      ),
    );
  }
}
