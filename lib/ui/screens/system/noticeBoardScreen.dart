import 'package:eschool/ui/widgets/academic/noticeBoardContainer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoticeBoardScreen extends StatelessWidget {
  final int? childId;
  const NoticeBoardScreen({Key? key, this.childId}) : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments;
    int? childId;
    
    // Handle dari notifikasi (Map) atau navigasi normal (int?)
    if (arguments is int) {
      childId = arguments;
    } else if (arguments is Map<String, dynamic> && arguments['childId'] != null) {
      childId = arguments['childId'] is int 
          ? arguments['childId'] 
          : int.tryParse(arguments['childId'].toString());
    } else {
      // Fallback: null (akan menampilkan semua announcement)
      childId = null;
    }
    
    return NoticeBoardScreen(childId: childId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NoticeBoardContainer(
        childId: childId,
        showBackButton: true,
      ),
    );
  }
}
