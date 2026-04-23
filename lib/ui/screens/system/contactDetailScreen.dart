import 'package:eschool/cubits/system/contactCubit.dart';
import 'package:eschool/data/models/system/contact.dart';
import 'package:eschool/data/repositories/contactRepository.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class ContactDetailScreen extends StatefulWidget {
  final int contactId;
  
  const ContactDetailScreen({Key? key, required this.contactId}) : super(key: key);

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    final contactId = arguments['contactId'] as int;

    return BlocProvider(
      create: (context) => ContactDetailCubit(ContactRepository()),
      child: ContactDetailScreen(contactId: contactId),
    );
  }
}

class _ContactDetailScreenState extends State<ContactDetailScreen>
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

    // Load contact details
    context.read<ContactDetailCubit>().loadContactDetails(widget.contactId);
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
                "Detail Pesan",
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

  Widget _buildStatusBadge(String status, {bool hasAdminReply = false}) {
    Color badgeColor;
    List<Color> gradientColors;
    String label;
    IconData icon;

    if (hasAdminReply || status == 'replied') {
      badgeColor = Colors.blue.shade600;
      gradientColors = [Colors.blue.shade500, Colors.blue.shade700];
      label = 'Dibalas';
      icon = Icons.mark_email_read_rounded;
    } else if (status == 'new') {
      badgeColor = Colors.green.shade600;
      gradientColors = [Colors.green.shade500, Colors.green.shade700];
      label = 'Baru';
      icon = Icons.fiber_new_rounded;
    } else {
      badgeColor = Colors.grey.shade600;
      gradientColors = [Colors.grey.shade500, Colors.grey.shade700];
      label = 'Selesai';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.0,
            color: Colors.white,
          ),
          const SizedBox(width: 5.0),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Contact contact) {
    final bool hasAdminReply = contact.adminReply != null && contact.adminReply!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: hasAdminReply 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
              : Colors.grey.shade100,
          width: hasAdminReply ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          if (hasAdminReply)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 0),
              spreadRadius: -3,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject with icon and status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  Icons.subject_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  contact.subject,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              // Badge Status di samping subject
              _buildStatusBadge(
                contact.status, 
                hasAdminReply: contact.adminReply != null && contact.adminReply!.isNotEmpty,
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Divider modern dengan gradient
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade200,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Message Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16.0,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'Pesan',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  contact.message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14.0,
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // User Info Card
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Nama Pengirim',
                  contact.name,
                ),
                const SizedBox(height: 16.0),
                _buildInfoRow(
                  Icons.email_outlined,
                  'Email Pengirim',
                  contact.email,
                ),
                const SizedBox(height: 16.0),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  'Tanggal Dikirim',
                  DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(contact.createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            icon,
            size: 18.0,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminReply(Contact contact) {
    if (contact.adminReply == null || contact.adminReply!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balasan Admin',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    if (contact.repliedAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12.0,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(contact.repliedAt!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18.0),
          
          // Divider modern dengan gradient
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 18.0),
          
          // Reply Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'Balasan',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  contact.adminReply!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14.0,
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    await context.read<ContactDetailCubit>().loadContactDetails(widget.contactId);
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(
        bottom: 80.0,
        top: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
        ),
      ),
      child: Column(
        children: [
          // Contact Info Skeleton
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject skeleton
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Message skeleton
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 24),
                // User info skeleton
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: EdgeInsets.only(bottom: index < 2 ? 16 : 0),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildContent() {
    return BlocBuilder<ContactDetailCubit, ContactDetailState>(
      builder: (context, state) {
        if (state is ContactDetailLoading) {
          return _buildSkeletonLoading();
        }

        if (state is ContactDetailError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.0,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    state.errorMessage,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ContactDetailCubit>().loadContactDetails(widget.contactId);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ContactDetailLoaded) {
          final contact = state.contact;
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsetsDirectional.only(
                bottom: 80.0,
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ),
              ),
              child: Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: _buildContactInfo(contact),
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 200),
                    child: _buildAdminReply(contact),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(),
            ),
          ),

          // App Bar
          _buildAppBar(context),
        ],
      ),
    );
  }
}

