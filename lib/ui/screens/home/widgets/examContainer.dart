import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/exam/examTabSelectionCubit.dart';
import 'package:eschool/data/models/academic/subject.dart';
import 'package:eschool/ui/widgets/examOfflineListContainer.dart';
import 'package:eschool/ui/widgets/examOnlineListContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/customBackButton.dart';

class ExamContainer extends StatelessWidget {
  final int? childId;
  final List<Subject>? subjects;
  const ExamContainer({Key? key, this.childId, this.subjects})
      : super(key: key);

  Widget _buildAppBar(
    BuildContext context,
    ExamTabSelectionState currentState,
  ) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarBiggerHeightPercentage - (Utils.appBarBiggerHeightPercentage * 0.1),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            children: [
              // Back button for parent mode
              context.read<AuthCubit>().isParent()
                  ? const CustomBackButton()
                  : const SizedBox(),
              
              // Screen title
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    Utils.getTranslatedLabel(examsKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),
              
              // Tab selector container
              Align(
                alignment: Alignment(0.0, 0.3),
                child: Container(
                  width: boxConstraints.maxWidth * (0.7),
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      // Offline Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context
                                .read<ExamTabSelectionCubit>()
                                .changeExamFilterTabTitle(offlineKey);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: currentState.examFilterTabTitle == offlineKey
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Utils.getTranslatedLabel(offlineKey),
                              style: TextStyle(
                                color: currentState.examFilterTabTitle == offlineKey
                                    ? Colors.white
                                    : Theme.of(context).scaffoldBackgroundColor,
                                fontWeight: currentState.examFilterTabTitle == offlineKey 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Online Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context
                                .read<ExamTabSelectionCubit>()
                                .changeExamFilterTabTitle(onlineKey);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: currentState.examFilterTabTitle == onlineKey
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Utils.getTranslatedLabel(onlineKey),
                              style: TextStyle(
                                color: currentState.examFilterTabTitle == onlineKey
                                    ? Colors.white
                                    : Theme.of(context).scaffoldBackgroundColor,
                                fontWeight: currentState.examFilterTabTitle == onlineKey 
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
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamTabSelectionCubit, ExamTabSelectionState>(
      builder: (context, state) {
        return Stack(
          children: [
            (context.read<ExamTabSelectionCubit>().isExamOnline())
                ? ExamOnlineListContainer(childId: childId, subjects: subjects)
                : ExamOfflineListContainer(
                    childId: childId,
                  ),
            Align(
              alignment: Alignment.topCenter,
              child: _buildAppBar(context, state),
            ),
          ],
        );
      },
    );
  }
}
