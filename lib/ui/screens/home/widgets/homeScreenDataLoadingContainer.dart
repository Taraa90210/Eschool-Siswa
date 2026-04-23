import 'package:eschool/data/models/academics/announcement.dart';
import 'package:eschool/data/models/academics/subject.dart';
import 'package:eschool/ui/widgets/announcementDetailsContainer.dart';
import 'package:eschool/ui/widgets/studentSubjectsContainer.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreenDataLoadingContainer extends StatelessWidget {
  final bool addTopPadding;
  const HomeScreenDataLoadingContainer(
      {super.key, required this.addTopPadding});

  @override
  Widget build(BuildContext context) {
    // Dummy data for skeletonizer
    final dummyAnnouncements = List.generate(
      2,
      (index) => Announcement(
        id: index,
        title: 'Loading Announcement Title Sample',
        description:
            'This is a sample description for the announcement loading state. It should be long enough to show a proper skeleton.',
        createdAt: DateTime.now(),
      ),
    );

    final dummySubjects = List.generate(
      6,
      (index) => Subject(
        id: index,
        name: 'Subject Name',
        image: '',
        type: 'Theory',
      ),
    );

    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: EdgeInsets.only(
            top: addTopPadding ? Utils.screenContentTopPadding / 2 : 25),
        children: [
          // Slider Skeleton
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * (0.075),
            ),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25),
            ),
            height: MediaQuery.of(context).size.height *
                Utils.appBarBiggerHeightPercentage,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * (0.025),
          ),
          // Announcements Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: dummyAnnouncements
                  .map((announcement) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AnnouncementDetailsContainer(
                          announcement: announcement,
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * (0.025),
          ),
          // Subjects Skeleton
          StudentSubjectsContainer(
            subjects: dummySubjects,
            subjectsTitleKey: 'My Subjects',
            header: true,
            animate: false,
          ),
        ],
      ),
    );
  }
}
