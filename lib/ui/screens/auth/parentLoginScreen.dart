import 'dart:math';
import 'dart:ui';
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/auth/forgotPasswordRequestCubit.dart';
import 'package:eschool/cubits/auth/signInCubit.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/ui/screens/auth/widgets/forgotPasswordRequestBottomsheet.dart';
import 'package:eschool/ui/screens/auth/widgets/termsAndConditionAndPrivacyPolicyContainer.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();

  static Widget routeInstance() {
    return BlocProvider<SignInCubit>(
      child: const ParentLoginScreen(),
      create: (_) => SignInCubit(AuthRepository()),
    );
  }
}

class _ParentLoginScreenState extends State<ParentLoginScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _backgroundAnimationController;
  late final AnimationController _formAnimationController;
  late final AnimationController _logoAnimationController;
  late final AnimationController _floatingParticlesController;
  late final AnimationController _pulseAnimationController;

  // Animations for background elements
  late final Animation<double> _backgroundFadeAnimation;

  // Animations for form elements
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<double> _formFadeAnimation;

  // Animations for individual form fields
  late final Animation<Offset> _emailSlideAnimation;
  late final Animation<Offset> _passwordSlideAnimation;
  late final Animation<Offset> _buttonSlideAnimation;
  late final Animation<Offset> _switchToStudentSlideAnimation;

  // Logo animation
  late final Animation<double> _logoScaleAnimation;

  late final Animation<double> _pulseAnimation;

  // Text controllers
  final TextEditingController _emailTextEditingController =
      TextEditingController(
          text: showDefaultCredentials ? defaultParentEmail : null);

  final TextEditingController _passwordTextEditingController =
      TextEditingController(
          text: showDefaultCredentials ? defaultParentPassword : null);

  // State variables
  bool _hidePassword = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _rememberMe = false;

  // Auth repository for Remember Me
  late final AuthRepository _authRepository;

  // Focus nodes
  late final FocusNode _emailFocusNode = FocusNode();
  late final FocusNode _passwordFocusNode = FocusNode();

  // Colors
  final Color _primaryRed = const Color(0xFFE63946);
  final Color _secondaryRed = const Color(0xFFFF8A80);

  final Color _bgWhite = const Color(0xFFF1FAEE);

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _initializeAnimations();
    _setupFocusListeners();
    _startAnimations();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final rememberMe = _authRepository.getRememberMeParent();
    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailTextEditingController.text = _authRepository.getSavedEmail();
        _passwordTextEditingController.text =
            _authRepository.getSavedParentPassword();
      });
    }
  }

  void _initializeAnimations() {
    // Initialize controllers with different durations
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _floatingParticlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Background animations
    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Form animations
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    // Individual field animations with staggered timing
    _emailSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _passwordSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _switchToStudentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Logo animations
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 60,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() {
    _backgroundAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _formAnimationController.forward();
    });
  }

  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    _floatingParticlesController.dispose();
    _pulseAnimationController.dispose();
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _signInParent() {
    if (_emailTextEditingController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterEmailKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_passwordTextEditingController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterPasswordKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    // Save or clear credentials based on Remember Me checkbox
    if (_rememberMe) {
      _authRepository.setRememberMeParent(true);
      _authRepository.setSavedEmail(_emailTextEditingController.text.trim());
      _authRepository
          .setSavedParentPassword(_passwordTextEditingController.text.trim());
    } else {
      _authRepository.clearParentCredentials();
    }

    context.read<SignInCubit>().signInUser(
          userId: _emailTextEditingController.text.trim(),
          password: _passwordTextEditingController.text.trim(),
          isStudentLogin: false,
        );
  }

  void _showForgotPasswordBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isDismissible: true,
      builder: (context) => Container(
        // margin: EdgeInsets.only(
        //   bottom: MediaQuery.of(context).viewInsets.bottom /
        //       3, // This makes the bottom sheet expand with keyboard
        // ),
        child: Container(
          // constraints: BoxConstraints(
          //   maxHeight: MediaQuery.of(context).size.height * 0.6,
          // ),
          // decoration: BoxDecoration(
          //   color: Theme.of(context).scaffoldBackgroundColor,
          //   borderRadius: const BorderRadius.only(
          //     topLeft: Radius.circular(20),
          //     topRight: Radius.circular(20),
          //   ),
          // ),
          child: BlocProvider(
            create: (_) => ForgotPasswordRequestCubit(AuthRepository()),
            child: const ForgotPasswordRequestBottomsheet(),
          ),
        ),
      ),
    ).then((value) {
      if (value != null && !value['error']) {
        Utils.showCustomSnackBar(
          context: context,
          errorMessage: "${Utils.getTranslatedLabel(
            passwordUpdateLinkSentKey,
          )}",
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        );
      }
    });
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                _primaryRed.withValues(alpha: 0.9),
                _primaryRed.withRed((_primaryRed.r * 255.0 * 0.85).round()),
                _secondaryRed.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Animated pattern
              Opacity(
                opacity: _backgroundFadeAnimation.value * 0.7,
                child: CustomPaint(
                  painter: ModernBackgroundPatternPainter(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                  size: Size.infinite,
                ),
              ),

              // Floating particles
              // AnimatedBuilder(
              //   animation: _floatingParticlesController,
              //   builder: (context, _) {
              //     return CustomPaint(
              //       painter: EnhancedFloatingParticlesPainter(
              //         animation: _floatingParticlesController.value,
              //         particleColor: Colors.white.withValues(alpha: 0.09),
              //       ),
              //       size: Size.infinite,
              //     );
              //   },
              // ),

              // Decorative elements
              Positioned(
                top: -80,
                right: -80,
                child: AnimatedBuilder(
                  animation: _backgroundFadeAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _backgroundFadeAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondaryRed.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: -20,
                child: AnimatedBuilder(
                  animation: _backgroundFadeAnimation,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _backgroundFadeAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _secondaryRed.withValues(alpha: 0.3),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassyFormContainer() {
    return FadeTransition(
      opacity: _formFadeAnimation,
      child: SlideTransition(
        position: _formSlideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 4.0,
                sigmaY: 4.0,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildLoginFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_logoAnimationController, _pulseAnimationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value * _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _bgWhite,
              boxShadow: [
                BoxShadow(
                  color: _primaryRed.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primaryRed.withValues(alpha: 0.9),
                      _primaryRed,
                    ],
                    center: Alignment.topLeft,
                    radius: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRememberMeAndForgotPasswordRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me Checkbox
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value!;
                  });
                },
                activeColor: _primaryRed,
                checkColor: Colors.white,
                fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return _primaryRed;
                    }
                    return Colors.transparent;
                  },
                ),
                side: WidgetStateBorderSide.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.selected)
                        ? _primaryRed
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Text(
                "Ingat Saya",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        // Forgot Password Button
        TextButton(
          onPressed: _showForgotPasswordBottomSheet,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            "${Utils.getTranslatedLabel(forgotPasswordKey)}?",
            style: TextStyle(
              color: _primaryRed,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return SlideTransition(
      position: _buttonSlideAnimation,
      child: BlocConsumer<SignInCubit, SignInState>(
        listener: (context, state) {
          if (state is SignInSuccess) {
            context.read<AuthCubit>().authenticateUser(
                  schoolCode: "",
                  jwtToken: "",
                  isStudent: state.isStudentLogIn,
                  parent: state.parent,
                  student: state.student,
                  children: state.children,
                );

            // ✅ CEK apakah ada pending notification yang perlu dibuka
            try {
              final authBox = Hive.box(authBoxKey);
              final pendingRoute = authBox.get(pendingNotificationRouteKey);
              final pendingArguments =
                  authBox.get(pendingNotificationArgumentsKey);

              if (pendingRoute != null && pendingRoute is String) {
                debugPrint(
                    '🔔 Login berhasil! Redirect ke pending notification: $pendingRoute');
                debugPrint('🔔 Arguments: $pendingArguments');

                // Clear pending notification
                authBox.delete(pendingNotificationRouteKey);
                authBox.delete(pendingNotificationArgumentsKey);

                // Navigate to parentHome first, then to pending notification
                Get.offNamedUntil(
                    Routes.parentHome, (Route<dynamic> route) => false);

                // Delay untuk memastikan home screen sudah ready
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (pendingArguments != null && pendingArguments is Map) {
                    Get.toNamed(pendingRoute, arguments: pendingArguments);
                  } else {
                    Get.toNamed(pendingRoute);
                  }
                });
              } else {
                // Normal login flow tanpa pending notification
                Get.offNamedUntil(
                    Routes.parentHome, (Route<dynamic> route) => false);
              }
            } catch (e) {
              debugPrint('⚠️ Error saat cek pending notification: $e');
              // Fallback ke normal login flow
              Get.offNamedUntil(
                  Routes.parentHome, (Route<dynamic> route) => false);
            }
          } else if (state is SignInFailure) {
            Utils.showCustomSnackBar(
              context: context,
              errorMessage: double.tryParse(state.errorMessage) != null
                  ? Utils.getErrorMessageFromErrorCode(
                      context, state.errorMessage)
                  : state.errorMessage,
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        },
        builder: (context, state) {
          return Container(
            width: double.infinity,
            height: 60,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primaryRed.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: state is SignInInProgress
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      _signInParent();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: state is SignInInProgress
                  ? const CustomCircularProgressIndicator(
                      strokeWidth: 3,
                      widthAndHeight: 24,
                      indicatorColor: Colors.white,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Utils.getTranslatedLabel(signInKey),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchToStudentButton() {
    return SlideTransition(
      position: _switchToStudentSlideAnimation,
      child: BlocBuilder<SignInCubit, SignInState>(
        builder: (context, state) {
          return Container(
            margin: const EdgeInsets.only(top: 24),
            child: TextButton(
              onPressed: state is SignInInProgress
                  ? null
                  : () => Get.offNamed(Routes.studentLogin),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Utils.getTranslatedLabel(loginAsKey),
                    style: TextStyle(
                      fontSize: 15.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${Utils.getTranslatedLabel(studentKey)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                      color: _primaryRed,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _primaryRed,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required bool obscureText,
    required IconData icon,
    required Animation<Offset> slideAnimation,
    Widget? suffixWidget,
    required bool isFocused,
    required FocusNode focusNode,
  }) {
    final Color darkTextColor = const Color(0xFF303030);

    return SlideTransition(
      position: slideAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: _primaryRed.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
          border: Border.all(
            color: isFocused ? _primaryRed : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Text(
                labelText,
                style: TextStyle(
                  color: isFocused ? _primaryRed : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  child: Center(
                    child: Icon(
                      icon,
                      color: isFocused ? _primaryRed : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscureText,
                    style: TextStyle(
                      color: darkTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                  ),
                ),
                if (suffixWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: suffixWidget,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _buildAnimatedLogo()),
        const SizedBox(height: 24),
        Text(
          Utils.getTranslatedLabel(letsSignInKey),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF303030),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${Utils.getTranslatedLabel(welcomeBackKey)}, ${Utils.getTranslatedLabel(youHaveBeenMissedKey)}",
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 28),
        _buildElegantTextField(
          controller: _emailTextEditingController,
          hintText: Utils.getTranslatedLabel(emailKey),
          labelText: Utils.getTranslatedLabel(emailKey),
          obscureText: false,
          icon: FontAwesomeIcons.envelope,
          slideAnimation: _emailSlideAnimation,
          isFocused: _isEmailFocused,
          focusNode: _emailFocusNode,
        ),
        _buildElegantTextField(
          controller: _passwordTextEditingController,
          hintText: "••••••••",
          labelText: Utils.getTranslatedLabel(passwordKey),
          obscureText: _hidePassword,
          icon: FontAwesomeIcons.lock,
          slideAnimation: _passwordSlideAnimation,
          suffixWidget: IconButton(
            icon: Icon(
              _hidePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
              color: _isPasswordFocused ? _primaryRed : Colors.grey.shade500,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                _hidePassword = !_hidePassword;
              });
            },
          ),
          isFocused: _isPasswordFocused,
          focusNode: _passwordFocusNode,
        ),
        const SizedBox(height: 12),
        _buildRememberMeAndForgotPasswordRow(),
        const SizedBox(height: 8),
        _buildSignInButton(),
        Center(child: _buildSwitchToStudentButton()),
        const SizedBox(height: 16),
        const Center(
          child: TermsAndConditionAndPrivacyPolicyContainer(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // Stylish background with animated elements
            _buildAnimatedBackground(),

            // Main scrollable content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildGlassyFormContainer(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernBackgroundPatternPainter extends CustomPainter {
  final Color color;

  ModernBackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double spacing = 40;
    final double dashLength = 5;
    final double dashSpace = 5;

    // Draw diagonal dashed lines
    for (double i = -size.height; i <= size.width + size.height; i += spacing) {
      double x = i;
      double y = 0;

      while (x < size.width && y < size.height) {
        // Draw a small dash
        canvas.drawLine(
          Offset(x, y),
          Offset(x + dashLength, y + dashLength),
          paint,
        );

        x += dashLength + dashSpace;
        y += dashLength + dashSpace;
      }
    }

    // Draw subtle circles
    for (int i = 0; i < 10; i++) {
      final double x = (i * spacing * 1.5) % size.width;
      final double y = (i * spacing * 2) % size.height;
      final double radius = 25 + (i % 3) * 15;

      final circlePaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(ModernBackgroundPatternPainter oldDelegate) => false;
}

class EnhancedFloatingParticlesPainter extends CustomPainter {
  final double animation;
  final Color particleColor;
  final int particleCount = 30;

  EnhancedFloatingParticlesPainter({
    required this.animation,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // final custom random = Random(42);

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 10;
      final randomX = Random(seed);
      final randomY = Random(seed + 5);
      final randomSize = Random(seed + 10);

      final x = randomX.nextDouble() * size.width;
      final baseSpeed = randomY.nextDouble() * 0.6 + 0.2; // Different speeds
      final y =
          (randomY.nextDouble() * size.height + animation * 100 * baseSpeed) %
              size.height;

      // Different sizes and opacities for particles
      final radius = randomSize.nextDouble() * 3 + 1;
      final opacity = randomSize.nextDouble() * 0.5 + 0.3;

      final paint = Paint()
        ..color = particleColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Add glow effect to some particles
      if (i % 3 == 0) {
        final glowPaint = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(Offset(x, y), radius * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(EnhancedFloatingParticlesPainter oldDelegate) => true;
}
