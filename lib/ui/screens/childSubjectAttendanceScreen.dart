import 'package:eschool/cubits/subjectAttendanceCubit.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/widgets/subjectAttendanceContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ChildSubjectAttendanceScreen extends StatelessWidget {
  final int childId;
  const ChildSubjectAttendanceScreen({Key? key, required this.childId})
      : super(key: key);

  // static Route route(RouteSettings routeSettings) {
  //   return CupertinoPageRoute(
  //       builder: (_) => BlocProvider<SubjectAttendanceCubit>(
  //             create: (context) => SubjectAttendanceCubit(StudentRepository()),
  //             child: ChildSubjectAttendanceScreen(
  //                 childId: routeSettings.arguments as int,),
  //           ),);
  // }

  // Struktur Kode Baru
  static Widget routeInstance() {
    return BlocProvider<SubjectAttendanceCubit>(
      create: (context) => SubjectAttendanceCubit(StudentRepository()),
      child: ChildSubjectAttendanceScreen(
        childId: Get.arguments as int,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ChildSubjectAttendanceScreen()');
    return Scaffold(
      body: SubjectAttendanceContainer(
        childId: childId,
      ),
    );
  }
}
