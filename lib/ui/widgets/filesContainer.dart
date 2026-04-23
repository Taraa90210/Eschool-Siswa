import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FilesContainer extends StatefulWidget {
  final List<StudyMaterial> files;
  const FilesContainer({Key? key, required this.files}) : super(key: key);

  @override
  State<FilesContainer> createState() => _FilesContainerState();
}

class _FilesContainerState extends State<FilesContainer> {
  final Color accentColor = const Color(0xFFE94F4F);

  Widget _buildFileDetailsContainer(StudyMaterial file, int index) {
    return Animate(
      effects: [
        FadeEffect(
            delay: Duration(milliseconds: 100 * index),
            duration: const Duration(milliseconds: 300)),
        SlideEffect(
            delay: Duration(milliseconds: 100 * index),
            duration: const Duration(milliseconds: 300),
            begin: const Offset(0.5, 0),
            end: const Offset(0, 0)),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0, left: 12.0, right: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.8),
              accentColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              offset: const Offset(2, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Utils.openDownloadBottomsheet(
                context: context,
                storeInExternalStorage: false,
                studyMaterial: file,
              );
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              child: Row(
                children: [
                  // File icon based on extension
                  _getFileIcon(file.fileExtension),
                  const SizedBox(width: 16),
                  // File details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${file.fileName}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ".${file.fileExtension} • ${_getFileSizeText(file)}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Download button with hover effect
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Animate(
                      autoPlay: false,
                      onPlay: (controller) => controller.loop(count: 1),
                      effects: const [
                        ScaleEffect(
                          begin: Offset(1, 1),
                          end: Offset(1.1, 1.1),
                          duration: Duration(milliseconds: 200),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileExtension) {
    IconData iconData;
    Color iconColor = Colors.white;

    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf_rounded;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.article_rounded;
        break;
      case 'xls':
      case 'xlsx':
        iconData = Icons.table_chart_rounded;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image_rounded;
        break;
      case 'mp3':
      case 'wav':
        iconData = Icons.audio_file_rounded;
        break;
      case 'mp4':
      case 'mov':
        iconData = Icons.video_file_rounded;
        break;
      default:
        iconData = Icons.insert_drive_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  String _getFileSizeText(StudyMaterial file) {
    // This is just a placeholder as the model might not have file size
    // You can replace this with actual file size if available
    return "File";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) {
      return Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 600)),
          SlideEffect(
              begin: Offset(0, 0.2),
              end: Offset.zero,
              duration: Duration(milliseconds: 600))
        ],
        child: Container(
          padding: const EdgeInsets.all(20),
          child: const NoDataContainer(titleKey: noFilesUploadedKey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.files.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return _buildFileDetailsContainer(widget.files[index], index);
      },
    );
  }
}
