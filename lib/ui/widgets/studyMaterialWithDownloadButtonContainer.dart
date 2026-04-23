import 'package:dotted_border/dotted_border.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/ui/widgets/downloadFileButton.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class StudyMaterialWithDownloadButtonContainer extends StatelessWidget {
  final BoxConstraints boxConstraints;
  final StudyMaterial studyMaterial;
  final int type;
  const StudyMaterialWithDownloadButtonContainer({
    Key? key,
    required this.boxConstraints,
    required this.studyMaterial,
    this.type = 1,
  }) : super(key: key);

  IconData _getFileTypeIcon() {
    final fileName = studyMaterial.fileName.toLowerCase();

    if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.gif')) {
      return Icons.image;
    } else if (fileName.endsWith('.mp4') ||
        fileName.endsWith('.avi') ||
        fileName.endsWith('.mov') ||
        fileName.endsWith('.mkv')) {
      return Icons.video_file;
    } else if (fileName.endsWith('.mp3') ||
        fileName.endsWith('.wav') ||
        fileName.endsWith('.ogg')) {
      return Icons.audio_file;
    } else if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Icons.slideshow;
    } else {
      return Icons.insert_drive_file;
    }
  }

  void _downloadFile(BuildContext context) {
    Utils.openDownloadBottomsheet(
      context: context,
      storeInExternalStorage: false,
      studyMaterial: studyMaterial,
    );
  }

  Widget build(BuildContext context) {
    if (type == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 10),
        child: GestureDetector(
          onTap: () {
            Utils.openDownloadBottomsheet(
              context: context,
              storeInExternalStorage: false,
              studyMaterial: studyMaterial,
            );
          },
          child: DottedBorder(
            borderType: BorderType.RRect,
            dashPattern: const [10, 10],
            radius: const Radius.circular(10.0),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
            child: Container(
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(horizontal: 7.5, vertical: 7.5),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.7),
                    child: Text(
                      studyMaterial.fileName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  DownloadFileButton(
                    studyMaterial: studyMaterial,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _downloadFile(context),
        child: Container(
          width: boxConstraints.maxWidth, // Gunakan lebar yang dibatasi
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type == 3
                      ? Color(0xFFFFFFFF)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileTypeIcon(),
                  size: 30,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
