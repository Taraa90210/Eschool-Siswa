import 'package:eschool/data/models/academics/lesson.dart';
import 'package:eschool/data/models/academics/studyMaterial.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customTabBarContainer.dart';
import 'package:eschool/ui/widgets/filesContainer.dart';
import 'package:eschool/ui/screens/chapterDetails/widgets/topicsContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/tabBarBackgroundContainer.dart';
import 'package:eschool/ui/widgets/videosContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChapterDetailsScreen extends StatefulWidget {
  final Lesson lesson;

  final int? childId;
  const ChapterDetailsScreen({Key? key, required this.lesson, this.childId})
      : super(key: key);

  @override
  State<ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;

    return ChapterDetailsScreen(
      lesson: arguments['lesson'],
      childId: arguments['childId'],
    );
  }
}

class _ChapterDetailsScreenState extends State<ChapterDetailsScreen> {
  late String _selectedTabTitleKey;
  late List<String> chapterContentTitles = [topicsKey, filesKey, videosKey];
  late List<String> availableTabs = [];

  @override
  void initState() {
    super.initState();
    // Initialize available tabs
    _initializeAvailableTabs();
    // Set the default selected tab to the leftmost available tab
    _selectedTabTitleKey =
        availableTabs.isNotEmpty ? availableTabs[0] : topicsKey;
  }

  void _initializeAvailableTabs() {
    if (widget.lesson.topics.isNotEmpty) {
      availableTabs.add(topicsKey);
    }

    if (widget.lesson.studyMaterials.any(
        (element) => element.studyMaterialType == StudyMaterialType.file)) {
      availableTabs.add(filesKey);
    }

    if (widget.lesson.studyMaterials.any((element) =>
        element.studyMaterialType == StudyMaterialType.youtubeVideo ||
        element.studyMaterialType == StudyMaterialType.uploadedVideoUrl)) {
      availableTabs.add(videosKey);
    }

    // Update chapter content titles based on available content
    chapterContentTitles = availableTabs;
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: availableTabs.length <= 1
          ? Utils.appBarSmallerHeightPercentage
          : Utils.appBarBiggerHeightPercentage,
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            children: [
              const CustomBackButton(),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    widget.lesson.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),
              _buildTabSelector(boxConstraints),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabSelector(BoxConstraints boxConstraints) {
    // If no tabs are available, return empty container
    if (availableTabs.isEmpty) {
      return SizedBox();
    }

    // If only one tab is available, show it centered
    if (availableTabs.length == 1) {
      return SizedBox();
    }

    // For multiple tabs, build dynamic tab layout
    return Stack(
      children: [
        AnimatedAlign(
          curve: Utils.tabBackgroundContainerAnimationCurve,
          duration: Utils.tabBackgroundContainerAnimationDuration,
          alignment: _getTabAlignment(),
          child: TabBarBackgroundContainer(
              boxConstraints: boxConstraints, items: availableTabs.length),
        ),
        ...availableTabs
            .map((tab) => CustomTabBarContainer(
                  boxConstraints: boxConstraints,
                  alignment: _getTabAlignment(
                      tabIndex: availableTabs.indexOf(tab),
                      tabCount: availableTabs.length),
                  isSelected: _selectedTabTitleKey == tab,
                  total: availableTabs.length,
                  onTap: () {
                    setState(() {
                      _selectedTabTitleKey = tab;
                    });
                  },
                  titleKey: tab,
                ))
            .toList(),
      ],
    );
  }

  AlignmentDirectional _getTabAlignment({int? tabIndex, int? tabCount}) {
    if (tabIndex == null || tabCount == null) {
      // For the background container
      int currentIndex = chapterContentTitles.indexOf(_selectedTabTitleKey);
      int total = chapterContentTitles.length;

      if (total <= 1) return AlignmentDirectional.center;

      double position = currentIndex / (total - 1);
      return AlignmentDirectional(
          position * 2 - 1, 0); // Maps 0->-1, 0.5->0, 1->1
    } else {
      // For the tab positions
      if (tabCount <= 1) return AlignmentDirectional.center;

      double position = tabIndex / (tabCount - 1);
      return AlignmentDirectional(
          position * 2 - 1, 0); // Maps 0->-1, 0.5->0, 1->1
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Show empty state when no tabs are available
          if (availableTabs.isEmpty) ...[
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(),
                child: NoDataContainer(
                  titleKey: noChaptersKey, // Show empty chapter message
                  animate: true,
                ),
              ),
            ),
          ] else ...[
            // Show normal content when tabs are available
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: availableTabs.length <= 1
                      ? Utils.appBarSmallerHeightPercentage
                      : Utils.appBarBiggerHeightPercentage,
                )),
                child: Column(
                  children: [
                    _selectedTabTitleKey == topicsKey
                        ? TopicsContainer(
                            topics: widget.lesson.topics,
                            childId: widget.childId,
                          )
                        : _selectedTabTitleKey == filesKey
                            ? FilesContainer(
                                files: widget.lesson.studyMaterials
                                    .where(
                                      (element) =>
                                          element.studyMaterialType ==
                                          StudyMaterialType.file,
                                    )
                                    .toList(),
                              )
                            : VideosContainer(
                                studyMaterials: widget.lesson.studyMaterials
                                    .where(
                                      (element) =>
                                          element.studyMaterialType ==
                                              StudyMaterialType.youtubeVideo ||
                                          element.studyMaterialType ==
                                              StudyMaterialType
                                                  .uploadedVideoUrl,
                                    )
                                    .toList(),
                              )
                  ],
                ),
              ),
            ),
          ],
          // App bar is always shown
          Align(
            alignment: Alignment.topCenter,
            child: _buildAppBar(),
          ),
        ],
      ),
    );
  }
}
