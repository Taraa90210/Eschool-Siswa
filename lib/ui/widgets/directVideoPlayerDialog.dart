import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/screens/playVideo/widgets/videoControlsContainer.dart';
import 'package:eschool/ui/screens/playVideo/widgets/playPauseButton.dart';

// Fitur tambahan Eschool 1.3.3 - Galang
class DirectVideoPlayerDialog extends StatefulWidget {
  final StudyMaterial currentlyPlayingVideo;
  final List<StudyMaterial> relatedVideos;

  const DirectVideoPlayerDialog(
      {Key? key,
      required this.currentlyPlayingVideo,
      required this.relatedVideos})
      : super(key: key);

  @override
  _DirectVideoPlayerDialogState createState() =>
      _DirectVideoPlayerDialogState();
}

class _DirectVideoPlayerDialogState extends State<DirectVideoPlayerDialog>
    with TickerProviderStateMixin {
  late StudyMaterial currentlyPlayingStudyMaterialVideo;
  late bool assignedVideoController = false;

  YoutubePlayerController? _youtubePlayerController;
  VideoPlayerController? _videoPlayerController;

  late final AnimationController controlsMenuAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late Animation<double> controlsMenuAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: controlsMenuAnimationController,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void initState() {
    currentlyPlayingStudyMaterialVideo = widget.currentlyPlayingVideo;

    if (currentlyPlayingStudyMaterialVideo.studyMaterialType ==
        StudyMaterialType.youtubeVideo) {
      _loadYoutubeController();
    } else {
      _loadVideoController();
    }
    super.initState();
  }

  void _loadVideoController() {
    if (currentlyPlayingStudyMaterialVideo.fileUrl.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(currentlyPlayingStudyMaterialVideo.fileUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )..initialize().then((_) {
          setState(() {
            _videoPlayerController?.play();
          });
        }).catchError((error) {
          print("Error initializing VideoPlayer: $error");
        });
      assignedVideoController = true;
    }
  }

  void _loadYoutubeController() {
    try {
      String? youTubeId = YoutubePlayer.convertUrlToId(
        currentlyPlayingStudyMaterialVideo.fileUrl,
      );

      if (youTubeId != null) {
        _youtubePlayerController = YoutubePlayerController(
          initialVideoId: youTubeId,
          flags: const YoutubePlayerFlags(
            hideThumbnail: true,
            hideControls: true,
          ),
        );
        assignedVideoController = true;
      }
    } catch (e) {
      print("Error loading YouTube controller: $e");
      // Handle YouTube player initialization errors gracefully
      if (mounted) {
        setState(() {
          assignedVideoController = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // ✅ Reset orientation ke portrait saat keluar dari dialog
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    controlsMenuAnimationController.dispose();
    _youtubePlayerController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Widget _buildVideoControlMenuContainer() {
    return AnimatedBuilder(
      animation: controlsMenuAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: controlsMenuAnimation.value,
          child: GestureDetector(
            onTap: () {
              if (controlsMenuAnimationController.isCompleted) {
                controlsMenuAnimationController.reverse();
              } else {
                controlsMenuAnimationController.forward();
              }
            },
            child: Container(
              color: Colors.black45,
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 10,
                        start: 10,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Center(
                    child: PlayPauseButtonContainer(
                      isYoutubeVideo: currentlyPlayingStudyMaterialVideo
                              .studyMaterialType ==
                          StudyMaterialType.youtubeVideo,
                      controlsAnimationController:
                          controlsMenuAnimationController,
                      youtubePlayerController: _youtubePlayerController,
                      videoPlayerController: _videoPlayerController,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 15, left: 10, right: 10),
                      child: VideoControlsContainer(
                        isYoutubeVideo: currentlyPlayingStudyMaterialVideo
                                .studyMaterialType ==
                            StudyMaterialType.youtubeVideo,
                        youtubePlayerController: _youtubePlayerController,
                        videoPlayerController: _videoPlayerController,
                        controlsAnimationController:
                            controlsMenuAnimationController,
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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(10),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.95,
        child: Column(
          children: [
            // Video Player
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    // ✅ Gunakan Positioned.fill + FittedBox untuk mengisi space maksimal dengan aspect ratio terjaga
                    Positioned.fill(
                      child: assignedVideoController
                          ? (currentlyPlayingStudyMaterialVideo
                                      .studyMaterialType ==
                                  StudyMaterialType.youtubeVideo
                              ? FittedBox(
                                  fit: BoxFit
                                      .contain, // ✅ Contain = max size dengan aspect ratio terjaga
                                  child: SizedBox(
                                    width: 16 * 100,
                                    height: 9 * 100,
                                    child: YoutubePlayerBuilder(
                                      player: YoutubePlayer(
                                        controller: _youtubePlayerController!,
                                        showVideoProgressIndicator: true,
                                        progressIndicatorColor: Colors.red,
                                        aspectRatio: 16 / 9,
                                      ),
                                      builder: (context, player) {
                                        return player;
                                      },
                                    ),
                                  ),
                                )
                              : _videoPlayerController!.value.isInitialized
                                  ? FittedBox(
                                      fit: BoxFit.contain,
                                      child: SizedBox(
                                        width: _videoPlayerController!
                                            .value.size.width,
                                        height: _videoPlayerController!
                                            .value.size.height,
                                        child: VideoPlayer(
                                            _videoPlayerController!),
                                      ),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: 16 * 100,
                                        height: 9 * 100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: CachedNetworkImageProvider(
                                                currentlyPlayingStudyMaterialVideo
                                                    .fileThumbnail,
                                              ),
                                            ),
                                          ),
                                          child:
                                              CustomCircularProgressIndicator(),
                                        ),
                                      ),
                                    ))
                          : SizedBox(),
                    ),
                    _buildVideoControlMenuContainer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
