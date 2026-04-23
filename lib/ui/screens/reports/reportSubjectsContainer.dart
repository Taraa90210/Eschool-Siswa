import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/academic/studentSubjectAndSlidersCubit.dart';
import 'package:eschool/data/models/academics/subject.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoaders/subjectsShimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/studentSubjectsContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ReportSubjectsContainer extends StatefulWidget {
  final int? childId;
  final List<Subject>? subjects;
  const ReportSubjectsContainer({Key? key, this.childId, this.subjects})
      : super(key: key);

  @override
  ReportSubjectsContainerState createState() => ReportSubjectsContainerState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return ReportSubjectsContainer(
      childId: arguments['childId'],
      subjects: arguments['subjects'],
    );
  }
}

class ReportSubjectsContainerState extends State<ReportSubjectsContainer> {
  List<Subject>? subjects;

  @override
  void initState() {
    super.initState();
    if (widget.subjects != null) subjects = List.from(widget.subjects!);
  }

  Widget _buildAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              context.read<AuthCubit>().isParent()
                  ? const Positioned(
                      left: 10,
                      top: -2,
                      child: const CustomBackButton(),
                    )
                  : const SizedBox(),
              Text(
                Utils.getTranslatedLabel(subjectsKey),
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ]),
      ),
    );
  }

  Widget _buildMySubjects() {
    // remove blank subject entry [added for all assignment filter from previous screen]
    if (context.read<AuthCubit>().isParent() && subjects != null) {
      subjects!.removeWhere((element) => element.id == 0);
    }

    // Helper: center-kan NoData di ruang di antara spacer atas & bawah
    Widget _centerNoData(String message) {
      final mq = MediaQuery.of(context);
      final safeHeight = mq.size.height - mq.padding.top - mq.padding.bottom;
      final topPad = mq.size.height * Utils.appBarSmallerHeightPercentage;
      final bottomPad = Utils.getScrollViewTopPadding(
        context: context,
        appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
      );
      final centerMinHeight =
          (safeHeight - topPad - bottomPad).clamp(0.0, double.infinity);

      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: centerMinHeight.toDouble()),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NoDataContainer(
                  titleKey: "Belum ada mata pelajaran untuk semester ini."),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  (Utils.appBarSmallerHeightPercentage),
            ),

            // === Cabang ORANG TUA ===
            if (context.read<AuthCubit>().isParent()) ...[
              if ((subjects ?? []).isEmpty)
                _centerNoData("Belum ada mata pelajaran untuk semester ini.")
              else
                StudentSubjectsContainer(
                  subjects: subjects!,
                  subjectsTitleKey: '', // already shown in title
                  childId: widget.childId,
                  showReport: true,
                ),
            ] else
              // === Cabang SISWA (via Cubit) ===
              ...[
              BlocBuilder<StudentSubjectsAndSlidersCubit,
                  StudentSubjectsAndSlidersState>(
                builder: (context, state) {
                  if (state is StudentSubjectsAndSlidersFetchSuccess) {
                    final cubit =
                        context.read<StudentSubjectsAndSlidersCubit>();
                    final list = cubit.getSubjects();

                    if (list.isEmpty) {
                      return _centerNoData("Tidak ada data untuk ditampilkan.");
                    }

                    return StudentSubjectsContainer(
                      subjects: list,
                      subjectsTitleKey: '', // already shown in title
                      childId: context.read<AuthCubit>().getStudentDetails().id,
                      showReport: true,
                    );
                  }

                  if (state is StudentSubjectsAndSlidersFetchFailure) {
                    return Center(
                      child: ErrorContainer(
                        errorMessageCode: state.errorMessage,
                        onTapRetry: () {
                          context
                              .read<StudentSubjectsAndSlidersCubit>()
                              .fetchSubjectsAndSliders(
                                useParentApi:
                                    (context.read<AuthCubit>().isParent()),
                                isSliderModuleEnable: Utils.isModuleEnabled(
                                  context: context,
                                  moduleId: sliderManagementModuleId.toString(),
                                ),
                              );
                        },
                      ),
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * (0.025),
                      ),
                      const SubjectsShimmerLoadingContainer(),
                    ],
                  );
                },
              ),
            ],

            // Spacer bawah
            SizedBox(
              height: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return (context.read<AuthCubit>().isParent())
        ? Scaffold(
            body: Stack(
              children: [
                _buildMySubjects(),
                Align(
                  alignment: Alignment.topCenter,
                  child: _buildAppBar(),
                ),
              ],
            ),
          )
        : Stack(
            children: [
              _buildMySubjects(),
              Align(
                alignment: Alignment.topCenter,
                child: _buildAppBar(),
              ),
            ],
          );
  }
}
