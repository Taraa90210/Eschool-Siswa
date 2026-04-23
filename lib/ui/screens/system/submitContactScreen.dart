import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/system/contactSubmissionCubit.dart';
import 'package:eschool/data/repositories/system/contactRepository.dart';
import 'package:eschool/ui/widgets/system/contactForm.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';

class SubmitContactScreen extends StatefulWidget {
  const SubmitContactScreen({Key? key}) : super(key: key);

  @override
  State<SubmitContactScreen> createState() => _SubmitContactScreenState();

  static Widget routeInstance() {
    return BlocProvider(
      create: (context) => ContactSubmissionCubit(ContactRepository()),
      child: const SubmitContactScreen(),
    );
  }
}

class _SubmitContactScreenState extends State<SubmitContactScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAppBar(BuildContext context) {
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
            Positioned(
              top: -1,
              child: Text(
                "Kirim Pesan",
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit({
    required String name,
    required String email,
    required String subject,
    required String message,
    required String type,
  }) {
    context.read<ContactSubmissionCubit>().submitContact(
      name: name,
      email: email,
      subject: subject,
      message: message,
      type: type,
    );
  }

  void _handleSuccess() {
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 12.0),
              const             Text(
              'Berhasil!',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Pesan Anda telah berhasil dikirim ke tim support. Balasan akan muncul di menu Riwayat Pesan dalam 1-2 hari kerja.',
          style: TextStyle(fontSize: 14.0),
        ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Get.back(); // Go back to previous screen
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleError(String errorMessage) {
    Utils.showCustomSnackBar(
      context: context,
      errorMessage: errorMessage,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Content
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsetsDirectional.only(
                bottom: Utils.getScrollViewBottomPadding(context) + 20,
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ),
              ),
              child: BlocListener<ContactSubmissionCubit, ContactSubmissionState>(
                listener: (context, state) {
                  if (state is ContactSubmissionSuccess) {
                    _handleSuccess();
                  } else if (state is ContactSubmissionFailure) {
                    _handleError(state.errorMessage);
                  }
                },
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          FadeInDown(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(16.0),
                                        ),
                                        child: const Icon(
                                          Icons.contact_support,
                                          color: Colors.white,
                                          size: 24.0,
                                        ),
                                      ),
                                      const SizedBox(width: 16.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hubungi Support',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: 20.0,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Kirim pertanyaan atau laporkan masalah aplikasi',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                fontSize: 14.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),

                          // Form Section
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 100),
                            child: BlocBuilder<ContactSubmissionCubit, ContactSubmissionState>(
                              builder: (context, state) {
                                // Get user data from AuthCubit
                                final authCubit = context.read<AuthCubit>();
                                String userName = '';
                                String userEmail = '';
                                bool isStudent = false;
                                String? studentInfo;
                                
                                if (authCubit.state is Authenticated) {
                                  final authState = authCubit.state as Authenticated;
                                  
                                  if (authState.isStudent) {
                                    isStudent = true;
                                    // For student, get name and generate proper email format
                                    final student = authCubit.getStudentDetails();
                                    userName = student.getFullName();
                                    
                                    // Priority: email from childUserDetails -> admission_no format -> mobile
                                    String? rawEmail = student.childUserDetails?.email;
                                    
                                    // Check if email is valid or is admission_no
                                    if (rawEmail != null && rawEmail.isNotEmpty) {
                                      // If email contains @, it's already in email format
                                      if (rawEmail.contains('@')) {
                                        userEmail = rawEmail;
                                      } else {
                                        // Email is admission_no, convert to email format
                                        userEmail = '${rawEmail}@student.eschool.id';
                                      }
                                    } else if (student.admissionNo != null && student.admissionNo!.isNotEmpty) {
                                      // Use admission number as email
                                      userEmail = '${student.admissionNo}@student.eschool.id';
                                    } else if (student.mobile != null && student.mobile!.isNotEmpty) {
                                      // Last resort: use mobile as identifier
                                      userEmail = '${student.mobile}@student.eschool.id';
                                    } else {
                                      // Fallback to student ID
                                      userEmail = 'student${student.id}@student.eschool.id';
                                    }
                                    
                                    // Info message for students
                                    studentInfo = 'ID ini digunakan untuk identifikasi Anda. Balasan dari support akan muncul di menu Riwayat Pesan.';
                                  } else {
                                    // For parent, get parent's name and email
                                    final parent = authCubit.getParentDetails();
                                    userName = parent.getFullName();
                                    userEmail = parent.email ?? '';
                                  }
                                }
                                
                                return ContactForm(
                                  onSubmit: _handleSubmit,
                                  isLoading: state is ContactSubmissionLoading,
                                  initialName: userName,
                                  initialEmail: userEmail,
                                  isStudent: isStudent,
                                  studentInfo: studentInfo,
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32.0),

                          // Info Section
                          FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Text(
                                        'Pesan Anda akan diproses dalam 1-2 hari kerja. Tim support kami siap membantu masalah teknis dan pertanyaan seputar aplikasi.',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                          fontSize: 13.0,
                                          height: 1.4,
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
              ),
            ),
          ),

          // App Bar
          _buildAppBar(context),
        ],
      ),
    );
  }
}
