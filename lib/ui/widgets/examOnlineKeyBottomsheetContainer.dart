import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/exam/examOnline.dart';
import 'package:eschool/cubits/exam/onlineExamQuestionsCubit.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:marquee/marquee.dart';

class ExamOnlineKeyBottomsheetContainer extends StatefulWidget {
  final ExamOnline exam;
  final Function navigateToExamScreen;
  const ExamOnlineKeyBottomsheetContainer({
    Key? key,
    required this.exam,
    required this.navigateToExamScreen,
  }) : super(key: key);

  @override
  ExamOnlineKeyBottomsheetContainerState createState() =>
      ExamOnlineKeyBottomsheetContainerState();
}

class ExamOnlineKeyBottomsheetContainerState
    extends State<ExamOnlineKeyBottomsheetContainer>
    with SingleTickerProviderStateMixin {
  late TextEditingController textEditingController = TextEditingController();
  late String errorMessage = "";
  late bool rulesAccepted = false;
  final double horizontalPaddingPercentage = 0.125;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  // Method to show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required ExamOnline exam,
    required Function navigateToExamScreen,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExamOnlineKeyBottomsheetContainer(
        exam: exam,
        navigateToExamScreen: navigateToExamScreen,
      ),
    );
  }

  Widget _buildAcceptRulesContainer() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal:
            MediaQuery.of(context).size.width * horizontalPaddingPercentage,
        vertical: 15.0,
      ),
      alignment: Alignment.center,
      child: InkWell(
        onTap: () {
          setState(() {
            rulesAccepted = !rulesAccepted;
          });
        },
        child: Row(
          children: [
            SizedBox(width: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rulesAccepted
                    ? Utils.getColorScheme(context).primary
                    : Colors.transparent,
                border: Border.all(
                  width: 1.5,
                  color: rulesAccepted
                      ? Utils.getColorScheme(context).primary
                      : Utils.getColorScheme(context).secondary,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: rulesAccepted
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.surface,
                      size: 16.0,
                    )
                  : const SizedBox(),
            ),
            SizedBox(width: 15),
            Text(
              Utils.getTranslatedLabel(iAgreeWithExamRulesKey),
              style: TextStyle(
                color: Utils.getColorScheme(context).secondary,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * (0.127),
        vertical: 10,
      ),
      child: Divider(
        color: Utils.getColorScheme(context).secondary.withValues(alpha: 0.3),
        thickness: 1,
      ),
    );
  }

  Widget _buildExamRules() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * (0.1),
        vertical: 10,
      ),
      child: HtmlWidget(
        context.read<SchoolConfigurationCubit>().fetchExamRules(),
        textStyle: const TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildExamKeyTextFieldContainer() {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(
        horizontal:
            MediaQuery.of(context).size.width * horizontalPaddingPercentage,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Utils.getColorScheme(context).surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
            child: Text(
              Utils.getTranslatedLabel(enterExamKey),
              style: TextStyle(
                color: Utils.getColorScheme(context).secondary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          TextField(
            controller: textEditingController,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Utils.getColorScheme(context).onSecondary,
              fontSize: 16,
            ),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.vpn_key_rounded,
                color: Utils.getColorScheme(context).primary.withValues(alpha: 0.7),
                size: 20,
              ),
              hintText: "XX...",
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isTextOverflow(String text, double maxWidth, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines || textPainter.size.width > maxWidth;
  }

  Widget _buildHeaderWithCloseButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Space for balance
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const textStyle = TextStyle(
                  color: Color(0xFFD32F2F), // Konsisten dengan palet merah soft
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                );
                final title = widget.exam.title ?? "";
                final isOverflow =
                    _isTextOverflow(title, constraints.maxWidth, textStyle);

                return FadeTransition(
                  opacity: _animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(_animation),
                    child: isOverflow
                        ? SizedBox(
                            height: 30,
                            child: Marquee(
                              text: title,
                              style: textStyle,
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              blankSpace: 20.0,
                              velocity: 50.0,
                              pauseAfterRound: const Duration(seconds: 1),
                              startPadding: 10.0,
                              accelerationDuration: const Duration(seconds: 1),
                              accelerationCurve: Curves.linear,
                              decelerationDuration:
                                  const Duration(milliseconds: 500),
                              decelerationCurve: Curves.easeOut,
                            ),
                          )
                        : Text(
                            title,
                            textAlign: TextAlign.center,
                            style: textStyle,
                          ),
                  ),
                );
              },
            ),
          ),
          BlocBuilder<OnlineExamQuestionsCubit, OnlineExamQuestionsState>(
            builder: (context, state) {
              final isLoading = state is OnlineExamQuestionsFetchInProgress;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 24.0,
                      color: Utils.getColorScheme(context).secondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnlineExamQuestionsCubit, OnlineExamQuestionsState>(
      bloc: context.read<OnlineExamQuestionsCubit>(),
      listener: (context, state) {
        if (state is OnlineExamQuestionsFetchFailure) {
          setState(() {
            errorMessage = state.errorMessage;
          });
        } else if (state is OnlineExamQuestionsFetchSuccess) {
          widget.navigateToExamScreen();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * (0.95),
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                _buildHeaderWithCloseButton(),

                // Main content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDivider(),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(_animation),
                          child: FadeTransition(
                            opacity: _animation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            (0.127),
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    Utils.getTranslatedLabel(examRulesKey),
                                    style: TextStyle(
                                      color: Utils.getColorScheme(context)
                                          .secondary,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                _buildExamRules(),
                              ],
                            ),
                          ),
                        ),
                        _buildDivider(),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_animation),
                          child: FadeTransition(
                            opacity: _animation,
                            child: Column(
                              children: [
                                _buildAcceptRulesContainer(),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      (0.015),
                                ),
                                _buildExamKeyTextFieldContainer(),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      (0.015),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: errorMessage.isEmpty
                                      ? SizedBox(height: 20)
                                      : Container(
                                          height: 30.0,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Utils.getColorScheme(context)
                                                .error
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            errorMessage,
                                            style: TextStyle(
                                              color:
                                                  Utils.getColorScheme(context)
                                                      .error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      (errorMessage.isEmpty ? 0.01 : 0.02),
                                ),
                                BlocBuilder<OnlineExamQuestionsCubit,
                                    OnlineExamQuestionsState>(
                                  bloc:
                                      context.read<OnlineExamQuestionsCubit>(),
                                  builder: (context, state) {
                                    bool isLoading = state
                                        is OnlineExamQuestionsFetchInProgress;

                                    return CustomRoundedButton(
                                      onTap: isLoading
                                          ? () {}
                                          : () {
                                              FocusScope.of(context).unfocus();
                                              if (!rulesAccepted) {
                                                setState(() {
                                                  errorMessage =
                                                      Utils.getTranslatedLabel(
                                                    pleaseAcceptExamRulesKey,
                                                  );
                                                });
                                              } else if (textEditingController
                                                      .text
                                                      .trim() ==
                                                  widget.exam.examKey
                                                      .toString()) {
                                                errorMessage = "";
                                                context
                                                    .read<
                                                        OnlineExamQuestionsCubit>()
                                                    .startExam(
                                                        exam: widget.exam);
                                              } else {
                                                setState(() {
                                                  errorMessage =
                                                      Utils.getTranslatedLabel(
                                                    enterValidExamKey,
                                                  );
                                                });
                                              }
                                            },
                                      textSize: 16.0,
                                      height: 55,
                                      widthPercentage: 0.75,
                                      titleColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      backgroundColor:
                                          Utils.getColorScheme(context).primary,
                                      buttonTitle: Utils.getTranslatedLabel(
                                        isLoading ? submittingKey : submitKey,
                                      ),
                                      showBorder: false,
                                      child: isLoading
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Theme.of(context)
                                                        .scaffoldBackgroundColor,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  Utils.getTranslatedLabel(
                                                      submittingKey),
                                                  style: TextStyle(
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .scaffoldBackgroundColor,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                    );
                                  },
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      (0.03),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
