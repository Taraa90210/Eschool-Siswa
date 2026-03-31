import 'package:eschool/app/routes.dart';
import 'package:eschool/data/models/topic.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class TopicsContainer extends StatelessWidget {
  final List<Topic> topics;
  final int? childId;
  const TopicsContainer({Key? key, required this.topics, this.childId})
      : super(key: key);

  // Soft red accent color
  static const Color accentColor = Color(0xFFE94F4F);

  Widget _buildTopicDetailsContainer({
    required Topic topic,
    required BuildContext context,
    required int index,
  }) {
    return Animate(
      effects: [
        SlideEffect(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          begin: Offset(0.2, 0),
          end: Offset.zero,
        ),
        FadeEffect(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0, left: 12.0, right: 12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            Get.toNamed(
              Routes.topicDetails,
              arguments: {"topic": topic, "childId": childId},
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic header with accent gradient
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(1),
                        accentColor.withOpacity(0.9)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                // Topic content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Utils.getTranslatedLabel(topicDescriptionKey),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                          fontSize: 14.0,
                          height: 1.5,
                        ),
                      ),
                      // Interactive element
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (topics.isEmpty) {
    //   return const NoDataContainer(
    //     titleKey: noTopicsKey,
    //   ).animate().fadeIn(duration: const Duration(milliseconds: 400));
    // }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topics.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return _buildTopicDetailsContainer(
          topic: topics[index],
          context: context,
          index: index,
        );
      },
    );
  }
}
