
import 'package:eschool/cubits/system/appSettingsCubit.dart';
import 'package:eschool/data/repositories/system/systemInfoRepository.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({Key? key}) : super(key: key);

  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();

  static Widget routeInstance() {
    return BlocProvider<AppSettingsCubit>(
      create: (context) => AppSettingsCubit(SystemRepository()),
      child: const TermsAndConditionScreen(),
    );
  }
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen>
    with SingleTickerProviderStateMixin {
  final String termsAndConditionType = "terms_condition";
  String? cachedData;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _loadCachedData();
    Future.delayed(Duration.zero, () {
      context
          .read<AppSettingsCubit>()
          .fetchAppSettings(type: termsAndConditionType);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cachedData = prefs.getString(termsAndConditionType);
    });
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
              Positioned(
                left: 10,
                top: -2,
                child: const CustomBackButton(),
              ),
              Text(
                Utils.getTranslatedLabel(termsAndConditionKey),
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, state) {
          return Stack(
            children: [
              // Animated Background Pattern
              AnimatedPositioned(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: BackgroundPainter(
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              // Main Content
              SingleChildScrollView(
                padding: EdgeInsets.only(
                    top: Utils.getScrollViewTopPadding(
                        context: context,
                        appBarHeightPercentage:
                            Utils.appBarSmallerHeightPercentage)),
                child: Column(
                  children: [
                    // Header Section
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.9),
                              primaryColor.withValues(alpha: 1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.gavel_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              Utils.getTranslatedLabel(termsAndConditionKey),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Utils.getTranslatedLabel(
                                  termsAndConditionDescriptionKey),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content Section
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: state is AppSettingsFetchSuccess
                          ? FadeIn(
                              child: HtmlWidget(
                                Utils.parseCustomHtml(state.appSettingsResult),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.black87,
                                ),
                                customStylesBuilder: (element) {
                                  if (element.localName == 'h1' ||
                                      element.localName == 'h2') {
                                    return {
                                      'color': primaryColor.toString(),
                                      'font-weight': 'bold',
                                      'margin': '16px 0',
                                    };
                                  }
                                  return null;
                                },
                              ),
                            )
                          : state is AppSettingsFetchFailure
                              ? ErrorContainer(
                                  errorMessageCode: state.errorMessage,
                                  onTapRetry: () {
                                    context
                                        .read<AppSettingsCubit>()
                                        .fetchAppSettings(
                                            type: termsAndConditionType);
                                  },
                                )
                              : const Center(
                                  child: CustomCircularProgressIndicator(),
                                ),
                    ),
                  ],
                ),
              ),

              _buildAppBar()
            ],
          );
        },
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Color color;

  BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < size.width; i += 20) {
      for (var j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => false;
}
