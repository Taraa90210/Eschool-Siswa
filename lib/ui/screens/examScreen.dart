import 'package:eschool/data/models/academics/subject.dart';
import 'package:eschool/ui/screens/home/widgets/examContainer.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExamScreen extends StatelessWidget {
  final int? childId;
  final List<Subject>? subjects;
  const ExamScreen({Key? key, this.childId, this.subjects}) : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments;
    
    // Handle dari notifikasi (Map dengan data minimal) atau navigasi normal
    if (arguments is Map<String, dynamic>) {
      return ExamScreen(
        childId: arguments['childId'],
        subjects: arguments['subjects'],
      );
    }
    
    // Fallback: tanpa arguments
    return const ExamScreen(
      childId: null,
      subjects: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExamContainer(
        childId: childId,
        subjects: subjects,
      ),
    );
  }
}
