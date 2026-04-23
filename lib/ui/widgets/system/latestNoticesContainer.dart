import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/system/noticeBoardCubit.dart';
import 'package:eschool/ui/widgets/academic/announcementDetailsContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/announcementShimmerLoadingContainer.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LatestNoticiesContainer extends StatelessWidget {
  final bool animate;
  final int? childId;
  const LatestNoticiesContainer({
    Key? key,
    this.animate = true,
    this.childId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width *
            (Utils.screenContentHorizontalPaddingInPercentage / 2),
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Decorative background pattern
            Positioned(
              right: -20,
              top: -20,
              child: BlocBuilder<NoticeBoardCubit, NoticeBoardState>(
                builder: (context, state) {
                  final bool isEmpty = state is NoticeBoardFetchSuccess &&
                      state.announcements.isEmpty;
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: isEmpty ? 0.02 : 0.05),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: BlocBuilder<NoticeBoardCubit, NoticeBoardState>(
                builder: (context, state) {
                  final bool isEmpty = state is NoticeBoardFetchSuccess &&
                      state.announcements.isEmpty;
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: isEmpty ? 0.03 : 0.08),
                    ),
                  );
                },
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: BlocBuilder<NoticeBoardCubit, NoticeBoardState>(
                builder: (context, state) {
                  if (state is NoticeBoardFetchSuccess) {
                    final announcements = state.announcements.length >
                            numberOfLatestNoticesInHomeScreen
                        ? state.announcements
                            .sublist(0, numberOfLatestNoticesInHomeScreen)
                            .toList()
                        : state.announcements;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section
                        _buildHeader(context),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            thickness: 1,
                          ),
                        ),

                        // Notices list with animations
                        ...List.generate(
                          announcements.length,
                          (index) => _buildAnnouncementItem(
                              context, announcements[index], index),
                        ),

                        // Show "Tidak ada pengumuman" message when announcements list is empty
                        if (announcements.isEmpty)
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: Column(
                                children: [
                                  Text(
                                    Utils.getTranslatedLabel(
                                        noticeBoardEmptyKey),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  if (state is NoticeBoardFetchInProgress ||
                      state is NoticeBoardInitial) {
                    return _buildLoadingState(context);
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(
      BuildContext context, dynamic announcement, int index) {
    if (animate) {
      return FadeInLeft(
        duration: Duration(milliseconds: 400 + (index * 100)),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.2, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)?.animation ??
                  AlwaysStoppedAnimation(1.0),
              curve: Interval(
                0.1 + (index * 0.1),
                0.6 + (index * 0.1),
                curve: Curves.easeOutQuad,
              ),
            ),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: 2),
            child: AnnouncementDetailsContainer(
              announcement: announcement,
            ),
          ),
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnnouncementDetailsContainer(
          announcement: announcement,
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.bullhorn,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 12),
          // Section title with consistent styling
          Text(
            Utils.getTranslatedLabel(latestNoticesKey),
            style: TextStyle(
              color: Utils.getColorScheme(context).secondary,
              fontWeight: FontWeight.w700,
              fontSize: 20.0,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // View all button with consistent styling
          InkWell(
            onTap: () {
              Get.toNamed(Routes.noticeBoard, arguments: childId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Utils.getTranslatedLabel(viewAllKey),
                    style: TextStyle(
                      color: Utils.getColorScheme(context).primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Utils.getColorScheme(context).primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Utils.getColorScheme(context).surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Utils.getColorScheme(context).surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Utils.getColorScheme(context).surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),

        // Divider shimmer
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            height: 1,
            color: Utils.getColorScheme(context).surfaceContainerHighest,
          ),
        ),

        // Notice items shimmer
        ...List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const AnnouncementShimmerLoadingContainer(),
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * (0.02),
        ),
      ],
    );
  }
}
