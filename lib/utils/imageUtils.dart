import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/academics/studyMaterial.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ImageItem {
  final String? id;
  final String? fileUrl;
  final String? fileName;
  final String? fileExtension;
  final String? fileThumbnail;
  final String? updatedAt;

  ImageItem({
    this.id,
    this.fileUrl,
    this.fileName,
    this.fileExtension,
    this.fileThumbnail,
    this.updatedAt,
  });

  bool isSvgImage() {
    return fileExtension?.toLowerCase() == 'svg';
  }
}

class ImageUtils {
  /// Show a full-screen image popup with zoom, swipe, and download functionality
  ///
  /// [context] - Build context
  /// [images] - List of images to display
  /// [initialIndex] - Starting index (default: 0)
  /// [showDownload] - Whether to show download button (default: true)
  /// [showImageInfo] - Whether to show image name and date (default: true)
  /// [heroTagPrefix] - Prefix for Hero animation tags (default: "image")
  static void showFullScreenImage({
    required BuildContext context,
    required List<ImageItem> images,
    int initialIndex = 0,
    bool showDownload = true,
    bool showImageInfo = true,
    String heroTagPrefix = "image",
  }) {
    if (images.isEmpty) return;

    final PageController pageController =
        PageController(initialPage: initialIndex);
    int currentPage = initialIndex;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              return GestureDetector(
                onTap: () {
                  // Close on tap anywhere on the screen
                  Navigator.of(context).pop();
                },
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: pageController,
                          itemCount: images.length,
                          onPageChanged: (page) {
                            setState(() {
                              currentPage = page;
                            });
                          },
                          itemBuilder: (context, currentIndex) {
                            final imageItem = images[currentIndex];
                            return Center(
                              child: GestureDetector(
                                // Prevent taps on the image from closing (for better zoom experience)
                                onTap: () {
                                  // Stop propagation by doing nothing
                                },
                                child: SizedBox.expand(
                                  child: InteractiveViewer(
                                    maxScale: 3.0,
                                    panEnabled: true,
                                    scaleEnabled: true,
                                    minScale: 1.0,
                                    child: Hero(
                                      tag:
                                          "${heroTagPrefix}_${imageItem.id ?? currentIndex}",
                                      child: imageItem.isSvgImage()
                                          ? SvgPicture.network(
                                              imageItem.fileUrl ?? "",
                                              fit: BoxFit.contain,
                                              placeholderBuilder: (context) =>
                                                  Center(
                                                child:
                                                    CustomCircularProgressIndicator(
                                                  indicatorColor: Colors.white,
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: imageItem.fileUrl ?? "",
                                              fit: BoxFit.contain,
                                              placeholder: (context, url) =>
                                                  Center(
                                                child:
                                                    CustomCircularProgressIndicator(
                                                  indicatorColor: Colors.white,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                padding: const EdgeInsets.all(20),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.error_outline,
                                                      color: Colors.white,
                                                      size: 48,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      Utils.getTranslatedLabel(
                                                          failedToLoadImageKey),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Image info (title and date)
                        if (showImageInfo)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (images[currentPage].fileName != null)
                                    Text(
                                      images[currentPage].fileName!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  if (images[currentPage].updatedAt !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Updated: ${Utils.formatDate(DateTime.parse(images[currentPage].updatedAt!))}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        // Control buttons
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Row(
                            children: [
                              // Download button
                              if (showDownload)
                                GestureDetector(
                                  onTap: () {
                                    final imageItem = images[currentPage];
                                    Utils.openDownloadBottomsheet(
                                      context: context,
                                      storeInExternalStorage: true,
                                      studyMaterial: StudyMaterial(
                                        id: int.tryParse(imageItem.id ?? "0") ??
                                            0,
                                        fileName: imageItem.fileName ?? "image",
                                        fileUrl: imageItem.fileUrl ?? "",
                                        fileExtension:
                                            imageItem.fileExtension ?? "",
                                        fileThumbnail:
                                            imageItem.fileThumbnail ?? "",
                                        studyMaterialType:
                                            StudyMaterialType.file,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.download,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              if (showDownload) const SizedBox(width: 8),

                              // Close button
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Image counter
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${currentPage + 1} / ${images.length}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// Convert Gallery files to ImageItem list
  static List<ImageItem> fromGalleryFiles(List<dynamic> galleryFiles) {
    return galleryFiles
        .map((file) => ImageItem(
              id: file.id?.toString(),
              fileUrl: file.fileUrl,
              fileName: file.fileName,
              fileExtension: file.fileExtension,
              fileThumbnail: file.fileThumbnail,
              updatedAt: file.updatedAt,
            ))
        .toList();
  }

  /// Convert simple string URLs to ImageItem list
  static List<ImageItem> fromUrls(List<String> urls, {List<String>? names}) {
    return urls.asMap().entries.map((entry) {
      final index = entry.key;
      final url = entry.value;
      return ImageItem(
        id: index.toString(),
        fileUrl: url,
        fileName: names != null && names.length > index
            ? names[index]
            : "Image ${index + 1}",
        fileExtension: url.split('.').last.toLowerCase(),
      );
    }).toList();
  }

  /// Simple single image popup
  static void showSingleImage({
    required BuildContext context,
    required String imageUrl,
    String? imageName,
    bool showDownload = true,
    String heroTag = "single_image",
  }) {
    final imageItem = ImageItem(
      id: "0",
      fileUrl: imageUrl,
      fileName: imageName ?? "Image",
      fileExtension: imageUrl.split('.').last.toLowerCase(),
    );

    showFullScreenImage(
      context: context,
      images: [imageItem],
      initialIndex: 0,
      showDownload: showDownload,
      showImageInfo: imageName != null,
      heroTagPrefix: heroTag,
    );
  }
}
