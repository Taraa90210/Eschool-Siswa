import 'package:animate_do/animate_do.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/data/models/academics/subject.dart';
import 'package:eschool/ui/widgets/subjectImageContainer.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class StudentSubjectsContainer extends StatelessWidget {
  final String subjectsTitleKey;
  final List<Subject> subjects;
  final int? childId;
  final bool? header;
  final bool showReport;
  final bool animate;
  const StudentSubjectsContainer({
    Key? key,
    this.childId,
    required this.subjects,
    required this.subjectsTitleKey,
    this.showReport = false,
    this.animate = true,
    this.header = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width *
            Utils.screenContentHorizontalPaddingInPercentage,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan styling yang konsisten
          if (header == true) _buildHeader(context),

          // Jarak yang lebih dekat antara header dan konten
          SizedBox(height: 20),

          // Grid mata pelajaran
          _buildSubjectsGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return animate
        ? FadeInLeft(
            duration: Duration(milliseconds: 600),
            child: Row(
              children: [
                // Menambahkan ikon untuk memperjelas bagian
                Icon(
                  FontAwesomeIcons.bookOpen,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  size: 22.0,
                ),
                SizedBox(width: 10),
                Text(
                  Utils.getTranslatedLabel(subjectsTitleKey),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20.0,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          )
        : Row(
            children: [
              Icon(
                FontAwesomeIcons.bookOpen,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                size: 22.0,
              ),
              SizedBox(width: 10),
              Text(
                Utils.getTranslatedLabel(subjectsTitleKey),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20.0,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          );
  }

  Widget _buildSubjectsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, boxConstraints) {
        // Menggunakan Wrap dengan spacing yang disesuaikan
        return Wrap(
          spacing:
              boxConstraints.maxWidth * 0.05, // Mengurangi spacing horizontal
          runSpacing: 16, // Menambahkan spacing vertikal yang konsisten
          children: List.generate(subjects.length, (index) => index)
              .map(
                (index) => _buildSubjectContainer(
                  boxConstraints: boxConstraints,
                  context: context,
                  subject: subjects[index],
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSubjectContainer({
    required BoxConstraints boxConstraints,
    required Subject subject,
    required BuildContext context,
  }) {
    // Lebar sedikit lebih besar agar 3 item muat per baris
    final itemWidth = boxConstraints.maxWidth * 0.3;

    return GestureDetector(
      onTap: () {
        if (showReport) {
          Get.toNamed(
            Routes.subjectWiseDetailedReport,
            arguments: {
              "subject": subject,
              "childId": childId ?? 0,
            },
          );
        } else {
          bool shouldNavigateToSubjectDetailsScreen = Utils.isModuleEnabled(
                  context: context,
                  moduleId: announcementManagementModuleId.toString()) ||
              Utils.isModuleEnabled(
                  context: context,
                  moduleId: lessonManagementModuleId.toString());

          if (shouldNavigateToSubjectDetailsScreen) {
            Get.toNamed(
              Routes.subjectDetails,
              arguments: {
                "childId": childId,
                "subject": subject,
              },
            );
          }
        }
      },
      child: Container(
        width: itemWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kontainer untuk gambar mata pelajaran dengan elevasi
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 7,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SubjectImageContainer(
                showShadow: false,
                animate: animate,
                width: itemWidth,
                height: itemWidth,
                radius: 20,
                subject: subject,
              ),
            ),
            const SizedBox(height: 10),
            // Nama mata pelajaran dengan styling yang lebih modern
            Text(
              subject.getSubjectName(context: context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Utils.getColorScheme(context).onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            )
          ],
        ),
      ),
    );
  }
}