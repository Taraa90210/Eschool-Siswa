import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/academic/subjectAnnouncementsCubit.dart';
import 'package:eschool/cubits/academic/subjectLessonsCubit.dart';
import 'package:eschool/data/models/academic/subject.dart';
import 'package:eschool/data/repositories/academic/announcementRepository.dart';
import 'package:eschool/data/repositories/academic/subjectRepository.dart';
import 'package:eschool/ui/screens/academic/subjectDetails/widgets/announcementContainer.dart';
import 'package:eschool/ui/screens/academic/subjectDetails/widgets/chaptersContainer.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Subject subject;
  final int? childId;
  const SubjectDetailsScreen({Key? key, required this.subject, this.childId})
      : super(key: key);

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;

    return MultiBlocProvider(
      providers: [
        BlocProvider<SubjectLessonsCubit>(
          create: (_) => SubjectLessonsCubit(SubjectRepository()),
        ),
        BlocProvider<SubjectAnnouncementCubit>(
          create: (_) => SubjectAnnouncementCubit(AnnouncementRepository()),
        ),
      ],
      child: SubjectDetailsScreen(
        childId: arguments['childId'],
        subject: arguments['subject'],
      ),
    );
  }
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  late String _selectedTabTitle = chaptersKey;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(_subjectAnnouncementScrollListener);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      initializeTabBar();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_subjectAnnouncementScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  bool isLessonManagementModuleEnable() => Utils.isModuleEnabled(
      context: context, moduleId: lessonManagementModuleId.toString());

  bool isAnnouncementManagementModuleEnable() => Utils.isModuleEnabled(
      context: context, moduleId: announcementManagementModuleId.toString());

  void initializeTabBar() {
    if (isLessonManagementModuleEnable() &&
        isAnnouncementManagementModuleEnable()) {
      context.read<SubjectLessonsCubit>().fetchSubjectLessons(
            classSubjectId: widget.subject.classSubjectId ?? 0,
            useParentApi: context.read<AuthCubit>().isParent(),
            childId: widget.childId,
          );
      context.read<SubjectAnnouncementCubit>().fetchSubjectAnnouncement(
            useParentApi: context.read<AuthCubit>().isParent(),
            classSubjectId: widget.subject.classSubjectId ?? 0,
            childId: widget.childId,
          );
      _selectedTabTitle = chaptersKey;
    } else {
      if (isAnnouncementManagementModuleEnable()) {
        context.read<SubjectAnnouncementCubit>().fetchSubjectAnnouncement(
              useParentApi: context.read<AuthCubit>().isParent(),
              classSubjectId: widget.subject.classSubjectId ?? 0,
              childId: widget.childId,
            );
        _selectedTabTitle = announcementKey;
      }
      if (isLessonManagementModuleEnable()) {
        context.read<SubjectLessonsCubit>().fetchSubjectLessons(
              classSubjectId: widget.subject.classSubjectId ?? 0,
              useParentApi: context.read<AuthCubit>().isParent(),
              childId: widget.childId,
            );
        _selectedTabTitle = chaptersKey;
      }
    }

    //
    setState(() {});
  }

  void _subjectAnnouncementScrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (_selectedTabTitle == announcementKey) {
        if (context.read<SubjectAnnouncementCubit>().hasMore()) {
          context.read<SubjectAnnouncementCubit>().fetchMoreAnnouncements(
                useParentApi: context.read<AuthCubit>().isParent(),
                classSubjectId: widget.subject.classSubjectId ?? 0,
                childId: widget.childId,
              );
        }
        //to scroll to last in order for users to see the progress
        Future.delayed(const Duration(milliseconds: 10), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
          );
        });
      }
    }
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarBiggerHeightPercentage - (Utils.appBarBiggerHeightPercentage * 0.1),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            children: [
              // Back Button
              const CustomBackButton(),
              
              // Screen Title
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    widget.subject.getSubjectName(context: context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),
              
              // Tab Selector
              Align(
                alignment: Alignment(0.0, 0.3),
                child: Visibility(
                  visible: isAnnouncementManagementModuleEnable() && isLessonManagementModuleEnable(),
                  child: Container(
                    width: boxConstraints.maxWidth * (0.7),
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        // Chapters Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabTitle = chaptersKey;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 5.0,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTabTitle == chaptersKey
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Utils.getTranslatedLabel(chaptersKey),
                                style: TextStyle(
                                  color: _selectedTabTitle == chaptersKey
                                      ? Colors.white
                                      : Theme.of(context).scaffoldBackgroundColor,
                                  fontWeight: _selectedTabTitle == chaptersKey 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Announcements Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabTitle = announcementKey;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 5.0,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTabTitle == announcementKey
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Utils.getTranslatedLabel(announcementKey),
                                style: TextStyle(
                                  color: _selectedTabTitle == announcementKey
                                      ? Colors.white
                                      : Theme.of(context).scaffoldBackgroundColor,
                                  fontWeight: _selectedTabTitle == announcementKey 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  replacement: Container(
                    width: boxConstraints.maxWidth * (0.7),
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      Utils.getTranslatedLabel(
                        isAnnouncementManagementModuleEnable() ? announcementKey : chaptersKey
                      ),
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: CustomRefreshIndicator(
              onRefreshCallback: () {
                if (isAnnouncementManagementModuleEnable()) {
                  context
                      .read<SubjectAnnouncementCubit>()
                      .fetchSubjectAnnouncement(
                        useParentApi: context.read<AuthCubit>().isParent(),
                        classSubjectId: widget.subject.classSubjectId ?? 0,
                        childId: widget.childId,
                      );
                }
                if (isLessonManagementModuleEnable()) {
                  context.read<SubjectLessonsCubit>().fetchSubjectLessons(
                        classSubjectId: widget.subject.classSubjectId ?? 0,
                        useParentApi: context.read<AuthCubit>().isParent(),
                        childId: widget.childId,
                      );
                }
              },
              displacment: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarBiggerHeightPercentage,
              ),
              child: SizedBox(
                height: double.maxFinite,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: Utils.getScrollViewTopPadding(
                      context: context,
                      appBarHeightPercentage:
                          Utils.appBarBiggerHeightPercentage,
                    ),
                  ),
                  child: Column(
                    children: [
                      _selectedTabTitle == chaptersKey
                          ? ChaptersContainer(
                              childId: widget.childId,
                              classSubjectId:
                                  widget.subject.classSubjectId ?? 0,
                            )
                          : AnnouncementContainer(
                              classSubjectId:
                                  widget.subject.classSubjectId ?? 0,
                              childId: widget.childId,
                            )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _buildAppBar(),
          ),
        ],
      ),
    );
  }
}
