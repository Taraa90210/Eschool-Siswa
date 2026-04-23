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
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();

  static Widget routeInstance() {
    return BlocProvider<AppSettingsCubit>(
      create: (context) => AppSettingsCubit(SystemRepository()),
      child: const PrivacyPolicyScreen(),
    );
  }
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  final String privacyPolicyType = "privacy_policy";
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    Future.delayed(Duration.zero, () {
      context
          .read<AppSettingsCubit>()
          .fetchAppSettings(type: privacyPolicyType);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Stack(
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
          Container(
            child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
              builder: (context, state) {
                if (state is AppSettingsFetchSuccess) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                        top: Utils.getScrollViewTopPadding(
                            context: context,
                            appBarHeightPercentage:
                                Utils.appBarSmallerHeightPercentage)),
                    child: Column(
                      children: [
                        // Hero Section
                        FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: _buildHeroSection(),
                        ),

                        // Privacy Features Section
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.security,
                                  title: "Keamanan Data",
                                  description: "Data Anda selalu aman",
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFeatureCard(
                                  icon: Icons.lock,
                                  title: "Privasi",
                                  description: "Terjamin 100%",
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Main Content
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: _buildContentSection(
                              Utils.parseCustomHtml(state.appSettingsResult)),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AppSettingsFetchFailure) {
                  return Center(
                    child: ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: () {
                        context
                            .read<AppSettingsCubit>()
                            .fetchAppSettings(type: privacyPolicyType);
                      },
                    ),
                  );
                }
                return Center(
                  child: CustomCircularProgressIndicator(
                    indicatorColor: primaryColor,
                  ),
                );
              },
            ),
          ),

          _buildAppBar()
        ],
      ),
    );
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
                "Kebijakan Privasi",
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ]),
      ),
    );
  }

  Widget _buildHeroSection() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.9);

    return Container(
      height: MediaQuery.of(context).size.height * 0.3, // Responsive height
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            bottom: -50,
            child: Icon(
              Icons.security,
              size: 200,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.privacy_tip,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  Utils.getTranslatedLabel(privacyPolicyKey),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      Utils.getTranslatedLabel(privacyPolicyDescKey),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        height: 170, // Fixed height for symmetry
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: primaryColor,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(String content) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryColorHex =
        '#${primaryColor.toARGB32().toRadixString(16).substring(2)}';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: HtmlWidget(
        content,
        customStylesBuilder: (element) {
          if (element.localName == 'p') {
            return {
              'font-family': 'Poppins',
              'font-size': '16px',
              'line-height': '1.8',
              'color': '#333333',
              'margin': '16px 0',
            };
          }
          if (element.localName == 'h1' ||
              element.localName == 'h2' ||
              element.localName == 'h3') {
            return {
              'font-family': 'Poppins',
              'color': primaryColorHex,
              'margin': '24px 0 16px 0',
            };
          }
          return null;
        },
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black87,
          height: 1.8,
        ),
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
