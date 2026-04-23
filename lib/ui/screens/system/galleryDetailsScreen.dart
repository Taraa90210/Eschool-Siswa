import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/system/gallery.dart';
import 'package:eschool/data/models/academic/sessionYear.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:readmore/readmore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class GalleryDetailsScreen extends StatefulWidget {
  final Gallery gallery;
  final SessionYear sessionYear;

  GalleryDetailsScreen(
      {Key? key, required this.gallery, required this.sessionYear})
      : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return GalleryDetailsScreen(
      gallery: arguments['gallery'] as Gallery,
      sessionYear: arguments['sessionYear'] as SessionYear,
    );
  }

  @override
  State<GalleryDetailsScreen> createState() => _GalleryDetailsScreenState();
}

class _GalleryDetailsScreenState extends State<GalleryDetailsScreen> {
  String selectedTabTitleKey = photosKey;
  Duration tabChangeAnimationDuration = const Duration(milliseconds: 400);

  /// Sanitasi URL gambar: konversi http:// → https:// agar gambar baru
  /// yang diupload backend tidak gagal dimuat karena mixed-content.
  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // ✅ Reset orientation ke portrait saat keluar dari screen gallery
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Widget _buildTabBarContainer() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            // offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return Stack(
          children: [
            AnimatedAlign(
              duration: tabChangeAnimationDuration,
              curve: Curves.easeInOut,
              alignment: selectedTabTitleKey == photosKey
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              child: Container(
                margin: EdgeInsetsDirectional.all(5),
                width: boxConstraints.maxWidth * (0.5) - 10,
                height: boxConstraints.maxHeight - 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabTitleKey = photosKey;
                      });
                    },
                    child: Container(
                      height: boxConstraints.maxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Utils.getTranslatedLabel(photosKey),
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: selectedTabTitleKey == photosKey
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabTitleKey = videosKey;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: boxConstraints.maxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Text(
                        Utils.getTranslatedLabel(videosKey),
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: selectedTabTitleKey == videosKey
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  void _showFullScreenImage(BuildContext context, int index) {
    final photos = widget.gallery.getImages();
    final PageController pageController = PageController(initialPage: index);
    int currentPage = index;

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
                          itemCount: photos.length,
                          onPageChanged: (page) {
                            setState(() {
                              currentPage = page;
                            });
                          },
                          itemBuilder: (context, currentIndex) {
                            final galleryFile = photos[currentIndex];
                            return Center(
                              child: GestureDetector(
                                // Prevent taps on the image from closing (for better zoom experience)
                                onTap: () {
                                  // Stop propagation by doing nothing
                                },
                                child: PinchZoom(
                                  maxScale: 2.5,
                                  child: Hero(
                                    tag: "gallery_image_${galleryFile.id}",
                                    child: galleryFile.isSvgImage()
                                        ? SvgPicture.network(
                                            _fixUrl(galleryFile.fileUrl),
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
                                            imageUrl:
                                                _fixUrl(galleryFile.fileUrl),
                                            placeholder: (context, url) =>
                                                Center(
                                              child:
                                                  CustomCircularProgressIndicator(
                                                indicatorColor: Colors.white,
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error,
                                                        color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Title and edit date
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photos[currentPage].fileName ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Updated: ${photos[currentPage].updatedAt != null ? Utils.formatDate(DateTime.parse(photos[currentPage].updatedAt!)) : 'N/A'}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
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
                              GestureDetector(
                                onTap: () {
                                  final galleryFile = photos[currentPage];
                                  Utils.openDownloadBottomsheet(
                                    context: context,
                                    storeInExternalStorage: true,
                                    studyMaterial: StudyMaterial(
                                      id: galleryFile.id ?? 0,
                                      fileName: galleryFile.fileName!,
                                      fileUrl: galleryFile.fileUrl ?? "",
                                      fileExtension:
                                          galleryFile.fileExtension ?? "",
                                      fileThumbnail:
                                          galleryFile.fileThumbnail ?? "",
                                      studyMaterialType: StudyMaterialType.file,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.download,
                                      color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Close button
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Image counter
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${currentPage + 1}/${photos.length}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
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

  void _showFullScreenVideo(BuildContext context, int index) {
    final videos = widget.gallery.getVideos();
    if (videos.isEmpty || index >= videos.length) return;

    final PageController pageController = PageController(initialPage: index);
    int currentPage = index;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              return PopScope(
                canPop: true,
                onPopInvokedWithResult: (didPop, result) async {
                  // ✅ Reset orientation ke portrait saat back button
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]);
                },
                child: GestureDetector(
                  onTap: () {
                    // Close on tap anywhere on the screen
                    // ✅ Reset orientation sebelum pop
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                    Navigator.of(context).pop();
                  },
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: SafeArea(
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: pageController,
                            itemCount: videos.length,
                            onPageChanged: (page) {
                              setState(() {
                                currentPage = page;
                              });
                            },
                            itemBuilder: (context, currentIndex) {
                              final galleryFile = videos[currentIndex];
                              if (galleryFile.fileUrl == null ||
                                  galleryFile.fileUrl!.isEmpty) {
                                return Center(
                                    child: Text("Invalid video URL",
                                        style: TextStyle(color: Colors.white)));
                              }

                              // Extract YouTube ID from URL
                              String? youtubeId = YoutubePlayer.convertUrlToId(
                                  galleryFile.fileUrl!);
                              if (youtubeId == null) {
                                return Center(
                                    child: Text("Invalid YouTube URL",
                                        style: TextStyle(color: Colors.white)));
                              }

                              return Center(
                                child: GestureDetector(
                                  // Prevent taps on the video from closing
                                  onTap: () {
                                    // Stop propagation by doing nothing
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.width *
                                        9 /
                                        16, // 16:9 aspect ratio
                                    child: YoutubePlayer(
                                      controller: YoutubePlayerController(
                                        initialVideoId: youtubeId,
                                        flags: const YoutubePlayerFlags(
                                          autoPlay: false,
                                          mute: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Title and controls
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Row(
                              children: [
                                // Copy link button
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: videos[currentPage].fileUrl!));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.link,
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Close button
                                GestureDetector(
                                  onTap: () {
                                    // ✅ Reset orientation sebelum pop
                                    SystemChrome.setPreferredOrientations([
                                      DeviceOrientation.portraitUp,
                                    ]);
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Video counter
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${currentPage + 1}/${videos.length}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildPhotosContainer() {
    return LayoutBuilder(builder: (context, boxConstraints) {
      final photos = widget.gallery.getImages();
      if (photos.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              Utils.getTranslatedLabel(noPhotosAvailableKey),
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: photos
            .map((galleryFile) => GestureDetector(
                  onTap: () {
                    // _showFullScreenImage(
                    //     context,
                    //     widget.gallery.getImages().indexWhere(
                    //             (element) => element.id == galleryFile.id)
                    //         as String);
                    _showFullScreenImage(
                      context,
                      widget.gallery.getImages().indexWhere(
                          (element) => element.id == galleryFile.id),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: galleryFile.isSvgImage()
                          ? SvgPicture.network(
                              _fixUrl(galleryFile.fileUrl),
                              fit: BoxFit.cover,
                              width: boxConstraints.maxWidth * 0.48,
                              height: boxConstraints.maxWidth * 0.48,
                              placeholderBuilder: (context) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: _fixUrl(galleryFile.fileUrl),
                              fit: BoxFit.cover,
                              width: boxConstraints.maxWidth * 0.48,
                              height: boxConstraints.maxWidth * 0.48,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.error,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                    ),
                  ),
                ))
            .toList(),
      );
    });
  }

  Widget _buildVideosContainer() {
    final videos = widget.gallery.getVideos();
    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            Utils.getTranslatedLabel(noVideosAvailableKey),
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: videos
          .map((galleryFile) => Container(
                margin: EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      YoutubePlayer(
                          controller: YoutubePlayerController(
                        initialVideoId: YoutubePlayer.convertUrlToId(
                              galleryFile.fileUrl ?? "",
                            ) ??
                            "",
                        flags: const YoutubePlayerFlags(
                          autoPlay: false,
                          hideThumbnail: true,
                          hideControls: true,
                        ),
                      )),
                      GestureDetector(
                        onTap: () {
                          _showFullScreenVideo(
                            context,
                            widget.gallery.getVideos().indexWhere(
                                (element) => element.id == galleryFile.id),
                          );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: MediaQuery.of(context).size.width,
                          height: 180,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAppBar(String title) {
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
              Text(
                Utils.getTranslatedLabel(title),
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 25,
                top: MediaQuery.of(context).size.height *
                    Utils.appBarMediumtHeightPercentage),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured image
                Container(
                  height: 220,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: _fixUrl(widget.gallery.thumbnail),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // Title and description
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 5),
                  child: Text(
                    widget.gallery.title ?? "",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  thickness: 1,
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: ReadMoreText(
                    widget.gallery.description ?? "",
                    trimLines: 3,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: Utils.getTranslatedLabel(showMoreKey),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    trimExpandedText: '',
                    moreStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // Tab bar
                _buildTabBarContainer(),

                const SizedBox(height: 20),

                // Content based on selected tab
                AnimatedSwitcher(
                  duration: tabChangeAnimationDuration,
                  child: selectedTabTitleKey == photosKey
                      ? _buildPhotosContainer()
                      : _buildVideosContainer(),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _buildAppBar(widget.sessionYear.name ?? ""),
          )
        ],
      ),
    );
  }
}
