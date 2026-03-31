import 'package:eschool/cubits/forgotPasswordRequestCubit.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:flutter/services.dart';

class ForgotPasswordRequestBottomsheet extends StatefulWidget {
  const ForgotPasswordRequestBottomsheet({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordRequestBottomsheet> createState() =>
      _ForgotPasswordRequestBottomsheetState();
}

class _ForgotPasswordRequestBottomsheetState
    extends State<ForgotPasswordRequestBottomsheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailTextEditingController =
      TextEditingController();

  late AnimationController _animationController;
  final FocusNode _emailFocusNode = FocusNode();

  // Define the red color scheme
  final Color _primaryRed = const Color(0xFFE63946);
  final Color _secondaryRed = const Color(0xFFFF8A80);
  final Color _textDark = const Color(0xFF1D3557);
  final Color _bgWhite = Colors.white; // Changed to white

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _emailFocusNode.addListener(_handleFocusChange);

    // Start the animation when the bottomsheet opens
    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailTextEditingController.dispose();
    _animationController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.075,
        right: MediaQuery.of(context).size.width * 0.075,
        top: MediaQuery.of(context).size.height * 0.03,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: _bgWhite, // Using white color here
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom handle for the bottom sheet
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _secondaryRed,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Title with animation
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        color: _primaryRed,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Utils.getTranslatedLabel(forgotPasswordKey),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Subtitle with instruction
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Text(
                    "Masukkan informasi akun Anda untuk mendapatkan email pemulihan kata sandi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textDark,
                    ),
                  ),
                ),
              ),
            ),

            // Email input field
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
                  ),
                ),
                child: _buildInputField(
                  icon: Icons.email_rounded,
                  hintText: Utils.getTranslatedLabel(emailKey),
                  controller: _emailTextEditingController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Submit button
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: BlocConsumer<ForgotPasswordRequestCubit,
                    ForgotPasswordRequestState>(
                  listener: (context, state) {
                    if (state is ForgotPasswordRequestFailure) {
                      Utils.showCustomSnackBar(
                        context: context,
                        errorMessage: Utils.getErrorMessageFromErrorCode(
                          context,
                          state.errorMessage,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      );
                    } else if (state is ForgotPasswordRequestSuccess) {
                      Get.back(result: {
                        "error": false,
                        "email": _emailTextEditingController.text.trim(),
                      });
                    }
                  },
                  builder: (context, state) {
                    return PopScope(
                      canPop: context.read<ForgotPasswordRequestCubit>().state
                          is! ForgotPasswordRequestInProgress,
                      child: _buildSubmitButton(context, state),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Back to login button
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    if (context.read<ForgotPasswordRequestCubit>().state
                        is! ForgotPasswordRequestInProgress) {
                      Get.back();
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: _primaryRed.withOpacity(0.8),
                  ),
                  label: Text(
                    "Kembali",
                    style: TextStyle(
                      color: _primaryRed.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType? keyboardType,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? _primaryRed : Colors.grey[300]!,
          width: isFocused ? 2.0 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: _primaryRed.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          color: _textDark,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Icon(
              icon,
              color: isFocused ? _primaryRed : Colors.grey[400],
              size: 22,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () => controller.clear(),
                )
              : null,
          // Add a bottom line for extra clarity
          // enabledBorder: UnderlineInputBorder(
          //   borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5),
          // ),
          // focusedBorder: UnderlineInputBorder(
          //   borderSide: BorderSide(color: _primaryRed, width: 0.5),
          // ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSubmitButton(
      BuildContext context, ForgotPasswordRequestState state) {
    final isLoading = state is ForgotPasswordRequestInProgress;

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              FocusScope.of(context).unfocus();

              if (_emailTextEditingController.text.trim().isEmpty) {
                Utils.showCustomSnackBar(
                  context: context,
                  errorMessage: Utils.getTranslatedLabel(
                    pleaseEnterEmailKey,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                );
                _emailFocusNode.requestFocus();
                return;
              }

              // Add haptic feedback for button press
              HapticFeedback.mediumImpact();

              context.read<ForgotPasswordRequestCubit>().requestforgotPassword(
                  email: _emailTextEditingController.text.trim());
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: isLoading ? 0 : 5,
        shadowColor: _primaryRed.withOpacity(0.5),
        minimumSize: const Size(200, 55),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Utils.getTranslatedLabel(submitKey),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.send_rounded,
                  size: 20,
                ),
              ],
            ),
    );
  }
}
