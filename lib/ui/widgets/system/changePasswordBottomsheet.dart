import 'package:eschool/cubits/auth/changePasswordCubit.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ChangePasswordBottomsheet extends StatefulWidget {
  const ChangePasswordBottomsheet({Key? key}) : super(key: key);

  @override
  State<ChangePasswordBottomsheet> createState() =>
      _ChangePasswordBottomsheetState();
}

class _ChangePasswordBottomsheetState extends State<ChangePasswordBottomsheet> {
  final TextEditingController _currentPasswordTextEditingController =
      TextEditingController();
  final TextEditingController _newPasswordTextEditingController =
      TextEditingController();
  final TextEditingController _confirmNewPasswordTextEditingController =
      TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmNewPassword = true;

  @override
  void dispose() {
    _currentPasswordTextEditingController.dispose();
    _newPasswordTextEditingController.dispose();
    _confirmNewPasswordTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(30),
          topRight: const Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.06,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 15),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTextField(
                      controller: _currentPasswordTextEditingController,
                      hintKey: currentPasswordKey,
                      hideText: _hideCurrentPassword,
                      toggleVisibility: () {
                        setState(() {
                          _hideCurrentPassword = !_hideCurrentPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: _buildTextField(
                      controller: _newPasswordTextEditingController,
                      hintKey: newPasswordKey,
                      hideText: _hideNewPassword,
                      toggleVisibility: () {
                        setState(() {
                          _hideNewPassword = !_hideNewPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: _buildTextField(
                      controller: _confirmNewPasswordTextEditingController,
                      hintKey: confirmNewPasswordKey,
                      hideText: _hideConfirmNewPassword,
                      toggleVisibility: () {
                        setState(() {
                          _hideConfirmNewPassword = !_hideConfirmNewPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child:
                        BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
                      listener: (context, state) {
                        if (state is ChangePasswordFailure) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: Utils.getErrorMessageFromErrorCode(
                              context,
                              state.errorMessage,
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          );
                        } else if (state is ChangePasswordSuccess) {
                          Get.back(result: {"error": false});
                        }
                      },
                      builder: (context, state) {
                        return PopScope(
                          canPop: state is! ChangePasswordInProgress,
                          child: GestureDetector(
                            onTap: state is ChangePasswordInProgress
                                ? null
                                : () => _handleSubmit(context, state),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 48,
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: state is ChangePasswordInProgress
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        Utils.getTranslatedLabel(submitKey),
                                        style: GoogleFonts.poppins(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Utils.getTranslatedLabel(changePasswordKey),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (context.read<ChangePasswordCubit>().state
                    is ChangePasswordInProgress) {
                  return;
                }
                Get.back();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintKey,
    required bool hideText,
    required VoidCallback toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: hideText,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: Utils.getTranslatedLabel(hintKey),
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              hideText ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context, ChangePasswordState state) {
    FocusScope.of(context).unfocus();
    if (_currentPasswordTextEditingController.text.trim().isEmpty ||
        _newPasswordTextEditingController.text.trim().isEmpty ||
        _confirmNewPasswordTextEditingController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterAllFieldKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_newPasswordTextEditingController.text.trim() !=
        _confirmNewPasswordTextEditingController.text.trim()) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(newPasswordAndConfirmSameKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_newPasswordTextEditingController.text.trim().length <
        minimumPasswordLength) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage:
            Utils.getTranslatedLabel(minimumPasswordLenghtIs6CharactersKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    context.read<ChangePasswordCubit>().changePassword(
          currentPassword: _currentPasswordTextEditingController.text.trim(),
          newPassword: _newPasswordTextEditingController.text.trim(),
          newConfirmedPassword:
              _confirmNewPasswordTextEditingController.text.trim(),
        );
  }
}
