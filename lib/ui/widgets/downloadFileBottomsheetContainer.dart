import 'package:eschool/cubits/system/downloadFileCubit.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class DownloadFileBottomsheetContainer extends StatefulWidget {
  final StudyMaterial studyMaterial;
  final bool storeInExternalStorage;
  final bool showMessages;

  const DownloadFileBottomsheetContainer({
    Key? key,
    required this.studyMaterial,
    required this.storeInExternalStorage,
    this.showMessages = false,
  }) : super(key: key);

  @override
  State<DownloadFileBottomsheetContainer> createState() =>
      _DownloadFileBottomsheetContainerState();
}

class _DownloadFileBottomsheetContainerState
    extends State<DownloadFileBottomsheetContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    Future.delayed(Duration.zero, () {
      context.read<DownloadFileCubit>().downloadFile(
            studyMaterial: widget.studyMaterial,
            storeInExternalStorage: widget.storeInExternalStorage,
          );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeBottomSheet() {
    if (context.read<DownloadFileCubit>().state is DownloadFileInProgress) {
      context.read<DownloadFileCubit>().cancelDownloadProcess();
    }
    _animationController.reverse().then((_) {
      Get.back();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (context.read<DownloadFileCubit>().state is DownloadFileInProgress) {
          context.read<DownloadFileCubit>().cancelDownloadProcess();
        }
      },
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Utils.getTranslatedLabel(fileDownloadingKey),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: _closeBottomSheet,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.file_present_rounded,
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.studyMaterial.fileName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BlocConsumer<DownloadFileCubit, DownloadFileState>(
                listener: (context, state) {
                  if (state is DownloadFileSuccess) {
                    Get.back(
                      result: {
                        "error": false,
                        "filePath": state.downloadedFileUrl
                      },
                    );
                    if (widget.showMessages) {
                      Utils.showCustomSnackBar(
                        context: context,
                        errorMessage: Utils.getTranslatedLabel(
                            fileDownloadedSuccessfullyKey),
                        backgroundColor: Colors.green[700]!,
                      );
                    }
                  } else if (state is DownloadFileFailure) {
                    Get.back(
                        result: {"error": true, "message": state.errorMessage});
                    if (widget.showMessages) {
                      Utils.showCustomSnackBar(
                        context: context,
                        errorMessage:
                            Utils.getTranslatedLabel(fileDownloadingFailedKey),
                        backgroundColor: colorScheme.error,
                      );
                    }
                  }
                },
                builder: (context, state) {
                  if (state is DownloadFileInProgress) {
                    final pct = state.uploadedPercentage; // 0..100 atau -1
                    final double? progress =
                        (pct < 0) ? null : (pct * 0.01); // null = indeterminate

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Utils.getTranslatedLabel("downloading"),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            // if (pct >=
                            //     0) // sembunyikan teks persen saat indeterminate
                            //   Text(
                            //     "${pct.toStringAsFixed(0)}%",
                            //     style: textTheme.bodyMedium?.copyWith(
                            //       fontWeight: FontWeight.w600,
                            //       color: colorScheme.primary,
                            //     ),
                            //   ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                progress, // <— ini yang bikin animasi indeterminate kalau -1
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary.withValues(alpha: 0.8),
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _closeBottomSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(100, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(Utils.getTranslatedLabel(cancelKey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
