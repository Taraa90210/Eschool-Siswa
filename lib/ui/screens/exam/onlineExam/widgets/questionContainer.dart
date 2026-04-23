import 'package:eschool/data/models/exam/question.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:eschool/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class QuestionContainer extends StatefulWidget {
  final Question? question;
  final Color? questionColor;
  final String fontFamily;
  final double fontScale;
  final int? questionNumber;

  const QuestionContainer(
      {Key? key,
      this.question,
      this.questionColor,
      this.questionNumber,
      this.fontFamily = 'Roboto',
      this.fontScale = 1.0,
      s})
      : super(key: key);

  @override
  State<QuestionContainer> createState() => _QuestionContainerState();
}

class _QuestionContainerState extends State<QuestionContainer> {
  final Color primaryRedColor = const Color(0xFFDD4A48);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Padding luar lebih besar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.questionNumber != null
                      ? Container(
                          padding: const EdgeInsets.all(
                              12), // Padding nomor soal lebih besar
                          decoration: BoxDecoration(
                            color: primaryRedColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${widget.questionNumber}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // Teks nomor soal lebih besar
                            ),
                          ),
                        )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideX(begin: -0.3, end: 0)
                      : const SizedBox.shrink(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: HtmlWidget(
                        // kasih key biar rebuild total kalau scale/family berubah
                        key: ValueKey(
                          'question_${widget.fontFamily}_${widget.fontScale.toStringAsFixed(2)}',
                        ),

                        // HTML tanpa font-size hardcoded
                        "<span style='line-height: 1.5;'>${widget.question?.question ?? 'No question available'}</span>",

                        // Styling dinamis, tapi TANPA font-size
                        customStylesBuilder: (element) {
                          if (element.localName == 'span') {
                            return {
                              'color': '#333333',
                              'font-family': widget.fontFamily,
                              'line-height': '1.5',
                            };
                          }
                          return null;
                        },

                        // Kontrol ukuran langsung dari TextStyle
                        textStyle: TextStyle(
                          fontFamily: widget.fontFamily,
                          fontSize: 16 *
                              widget
                                  .fontScale, // ⬅️ ini yg bikin langsung berubah
                          height: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(duration: 800.ms),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!(widget.question?.image ?? "").isEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                      bottom: 16), // Perbaikan: ubah 'custom' menjadi 'bottom'
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  height: MediaQuery.of(context).size.height * 0.225,
                  child: CachedNetworkImage(
                    errorWidget: (context, image, _) => Center(
                      child: Icon(
                        Icons.error,
                        color: primaryRedColor,
                        size: 40,
                      ),
                    ),
                    imageBuilder: (context, imageProvider) {
                      return Hero(
                        tag: "question_image_${widget.questionNumber}",
                        child: Material(
                          child: InkWell(
                            onTap: () {
                              _showFullScreenImage(
                                  context, widget.question!.image!);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  // Perbaikan: hapus 'whether'
                                  padding: const EdgeInsets.all(
                                      10), // Padding ikon zoom lebih besar
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    imageUrl: widget.question!.image!,
                    placeholder: (context, url) => Center(
                      child: CustomCircularProgressIndicator(
                        indicatorColor: primaryRedColor,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1200.ms)
                    .scaleXY(begin: 0.9, end: 1.0),
              if (!(widget.question?.note ?? "").isEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(15), // Padding catatan lebih besar
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FontAwesomeIcons.circleInfo,
                          size: 16, color: primaryRedColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.question!.note!,
                          style: TextStyle(
                            fontSize: 15.0, // Teks catatan lebih besar
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1400.ms)
                    .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: "question_image_${widget.questionNumber}",
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) => Center(
                          child: CustomCircularProgressIndicator(
                            indicatorColor: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.black),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
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
}
