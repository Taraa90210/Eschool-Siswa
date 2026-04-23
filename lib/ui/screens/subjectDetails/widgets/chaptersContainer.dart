
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/academic/subjectLessonsCubit.dart';
import 'package:eschool/data/models/academics/lesson.dart';
import 'package:eschool/data/models/academics/studyMaterial.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ChaptersContainer extends StatefulWidget {
  final int classSubjectId;
  final int? childId;
  const ChaptersContainer(
      {Key? key, required this.classSubjectId, this.childId})
      : super(key: key);

  @override
  State<ChaptersContainer> createState() => _ChaptersContainerState();
}

class _ChaptersContainerState extends State<ChaptersContainer> {
  // Map untuk melacak status ekspansi deskripsi per lesson
  Map<int, bool> _expandedDescriptions = {};

  Widget _buildChapterDetailsContainer({required Lesson lesson}) {
    final bool isExpanded = _expandedDescriptions[lesson.id] ?? false;

    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: () {
          Get.toNamed(Routes.chapterDetails,
              arguments: {"lesson": lesson, "childId": widget.childId});
        },
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFAF1F1), // Darker background
                Color(0xFFFEFAFA), // Slightly darker white
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08), // Darker shadow
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Color(0xFFFFDEDE).withValues(alpha: 0.4), // Darker border
              width: 1.5, // Slightly thicker
            ),
          ),
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    Utils.getTranslatedLabel(chapterNameKey),
                    style: TextStyle(
                      color: Color(0xFFC62828), // Darker red
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: Text(
                  lesson.name,
                  style: TextStyle(
                    color: Color(0xFF212121), // Darker text
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Content type indicators
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Topics indicator
                    if (lesson.topics.length > 0) ...[
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFEEEEFB), // Darker blue background
                          borderRadius: BorderRadius.circular(30),
                          border:
                              Border.all(color: Color(0xFFD0D0F0), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.topic_outlined,
                              color: Color(0xFF3F51B5), // Darker blue
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "${lesson.topics.length} Topik",
                              style: TextStyle(
                                color: Color(0xFF3F51B5), // Darker blue
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10)
                    ],

                    // Files indicator
                    if (lesson.studyMaterials
                            .where((element) =>
                                element.studyMaterialType ==
                                StudyMaterialType.file)
                            .length >
                        0) ...[
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F5E8), // Darker green background
                          borderRadius: BorderRadius.circular(30),
                          border:
                              Border.all(color: Color(0xFFCCE8CC), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              color: Color(0xFF2E7D32), // Darker green
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "${lesson.studyMaterials.where((element) => element.studyMaterialType == StudyMaterialType.file).length} File",
                              style: TextStyle(
                                color: Color(0xFF2E7D32), // Darker green
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10)
                    ],

                    // Videos indicator
                    if (lesson.studyMaterials
                            .where(
                              (element) =>
                                  element.studyMaterialType ==
                                      StudyMaterialType.youtubeVideo ||
                                  element.studyMaterialType ==
                                      StudyMaterialType.uploadedVideoUrl,
                            )
                            .length >
                        0)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFF9E4C7), // Darker orange background
                          borderRadius: BorderRadius.circular(30),
                          border:
                              Border.all(color: Color(0xFFEDD3AD), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: Color(0xFFE65100), // Darker orange
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "${lesson.studyMaterials.where(
                                    (element) =>
                                        element.studyMaterialType ==
                                            StudyMaterialType.youtubeVideo ||
                                        element.studyMaterialType ==
                                            StudyMaterialType.uploadedVideoUrl,
                                  ).length} Video",
                              style: TextStyle(
                                color: Color(0xFFE65100), // Darker orange
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              if (lesson.studyMaterials
                          .where(
                            (element) =>
                                element.studyMaterialType ==
                                    StudyMaterialType.youtubeVideo ||
                                element.studyMaterialType ==
                                    StudyMaterialType.uploadedVideoUrl,
                          )
                          .length >
                      0 ||
                  lesson.studyMaterials
                          .where((element) =>
                              element.studyMaterialType ==
                              StudyMaterialType.file)
                          .length >
                      0 ||
                  lesson.topics.length > 0)
                SizedBox(height: 16),
              Divider(
                color: Color(0xFFD32F2F)
                    .withValues(alpha: 0.15), // Slightly darker divider
                height: 1,
                thickness: 1.5, // Thicker divider
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Text(
                    Utils.getTranslatedLabel(chapterDescriptionKey),
                    style: TextStyle(
                      color: Color(0xFFC62828), // Darker red
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                decoration: BoxDecoration(
                  color: Color(0xFFFFECEC), // Darker red background
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Color(0xFFFFD5D5), width: 1.5), // Darker border
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.description,
                      style: TextStyle(
                        color: Color(0xFF333344), // Darker text
                        fontWeight: FontWeight.w400,
                        fontSize: 15.0,
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.start,
                      maxLines: isExpanded ? null : 4,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    if (lesson.description.split('\n').length > 4 ||
                        lesson.description.length > 120)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _expandedDescriptions[lesson.id] = !isExpanded;
                              });
                            },
                            icon: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                            label: Text(
                              isExpanded
                                  ? 'Baca Lebih Sedikit'
                                  : 'Baca Selengkapnya',
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Color(0xFFB71C1C), // Darker red
                              backgroundColor:
                                  Color(0xFFF4D5D5), // Darker button background
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterDetailsShimmerContainer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        width: MediaQuery.of(context).size.width * 0.85,
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    margin: EdgeInsetsDirectional.only(
                        end: boxConstraints.maxWidth * 0.7),
                  ),
                ),
                const SizedBox(height: 5),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    margin: EdgeInsetsDirectional.only(
                        end: boxConstraints.maxWidth * 0.5),
                  ),
                ),
                const SizedBox(height: 15),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    margin: EdgeInsetsDirectional.only(
                        end: boxConstraints.maxWidth * 0.7),
                  ),
                ),
                const SizedBox(height: 5),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    margin: EdgeInsetsDirectional.only(
                        end: boxConstraints.maxWidth * 0.5),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectLessonsCubit, SubjectLessonsState>(
      builder: (context, state) {
        if (state is SubjectLessonsFetchSuccess) {
          return state.lessons.isEmpty
              ? const NoDataContainer(titleKey: noChaptersKey)
              : Column(
                  children: List.generate(
                    state.lessons.length,
                    (index) => Animate(
                      effects: listItemAppearanceEffects(
                          itemIndex: index,
                          totalLoadedItems: state.lessons.length),
                      child: _buildChapterDetailsContainer(
                          lesson: state.lessons[index]),
                    ),
                  ),
                );
        }
        if (state is SubjectLessonsFetchFailure) {
          return ErrorContainer(
            errorMessageCode: state.errorMessage,
            onTapRetry: () {
              context.read<SubjectLessonsCubit>().fetchSubjectLessons(
                    classSubjectId: widget.classSubjectId,
                    useParentApi: context.read<AuthCubit>().isParent(),
                    childId: widget.childId,
                  );
            },
          );
        }
        return Column(
          children: List.generate(5, (index) => index)
              .map((e) => _buildChapterDetailsShimmerContainer())
              .toList(),
        );
      },
    );
  }
}
