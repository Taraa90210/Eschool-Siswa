import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/examTabSelectionCubit.dart';
import 'package:eschool/cubits/examsOnlineCubit.dart';
import 'package:eschool/cubits/submitOnlineExamAnswersCubit.dart';
import 'package:eschool/data/models/answerOption.dart';
import 'package:eschool/data/models/question.dart';
import 'package:eschool/data/repositories/onlineExamRepository.dart';
import 'package:eschool/ui/screens/home/homeScreen.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/secureScreen.dart';
import 'package:eschool/utils/vibrationHelper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:eschool/cubits/onlineExamQuestionsCubit.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/examQuestionStatusBottomSheetContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/examTimerContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/optionContainer.dart';
import 'package:eschool/ui/screens/exam/onlineExam/widgets/questionContainer.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/data/models/examOnline.dart';
import 'package:marquee/marquee.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

class ExamOnlineScreen extends StatefulWidget {
  final ExamOnline exam;
  const ExamOnlineScreen({Key? key, required this.exam}) : super(key: key);

  @override
  ExamOnlineScreenState createState() => ExamOnlineScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return BlocProvider(
      create: (context) => SubmitOnlineExamAnswersCubit(OnlineExamRepository()),
      child: ExamOnlineScreen(
        exam: arguments['exam'],
      ),
    );
  }
}

class ExamOnlineScreenState extends State<ExamOnlineScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ExamTimerContainerState> timerKey =
      GlobalKey<ExamTimerContainerState>();
  late AudioPlayer _audioPlayer;
  late PageController pageController = PageController();
  Map<int, TextEditingController> textControllers = {};

  bool isExitDialogOpen = false;
  bool isExamQuestionStatusBottomsheetOpen = false;
  bool isExamCompleted = false;
  bool isSubmissionInProgress = false;
  bool isLoadingLocalData = true;
  final MethodChannel platform = MethodChannel("com.eschool/audio");

  double? _screenHeight;

  int currentQuestionIndex = 0;
  Map<int, dynamic> _selectedAnswersWithQuestionId = {};
  final Set<int> _doubtfulQuestionIds = {};

  Timer? canGiveExamAgainTimer;
  bool canGiveExamAgain = true;

  int canGiveExamAgainTimeInSeconds = 5;

  // Seed untuk pengacakan
  late int _seed;

  double _fontScale = 1.3; // default sama kayak 1.3em kamu
  String _fontFamily = 'Roboto'; // default

  void _openFontSettings() {
    showFontSettingsBottomSheet(
      context,
      initialFontScale: _fontScale,
      initialFontFamily: _fontFamily,
      onFontScaleChanged: (v) => setState(() => _fontScale = v),
      onFontFamilyChanged: (v) => setState(() => _fontFamily = v),
    );
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    // Menggunakan FlutterWindowManager untuk mengunci layar
    Future.microtask(() async {
      await SecureScreen.enableSecure();
      print(">> SecureScreen ENABLED");
    });

    _loadLocalExamData().then((_) {
      setState(() {
        isLoadingLocalData = false;
      });

      // Mulai timer setelah data dimuat
      Future.delayed(Duration.zero, () {
        timerKey.currentState?.startTimer();
      });
    });

    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
  }

  // Fungsi untuk menyimpan data ujian secara lokal
  Future<void> _saveLocalExamData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final examData = {
        'examId': widget.exam.id,
        'seed': _seed,
        'answers': Map<String, dynamic>.from(_selectedAnswersWithQuestionId
            .map((key, value) => MapEntry(key.toString(), value))),
        'textAnswers': Map<String, String>.from(textControllers.map(
            (key, controller) => MapEntry(key.toString(), controller.text))),
      };
      await prefs.setString('exam_data', jsonEncode(examData));
    } catch (e) {
      debugPrint('Error saving local exam data: $e');
    }
  }

  // Fungsi untuk memuat data ujian dari penyimpanan lokal
  Future<void> _loadLocalExamData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final examDataString = prefs.getString('exam_data');

      if (examDataString != null && examDataString.isNotEmpty) {
        final examData = jsonDecode(examDataString) as Map<String, dynamic>;
        final storedExamId = examData['examId'];

        // Jika ID ujian cocok, muat data
        if (storedExamId == widget.exam.id) {
          _seed = examData['seed'];

          // UBAH DISINI

          // Konversi jawaban yang tersimpan
          final Map<String, dynamic> storedAnswers = examData['answers'];
          _selectedAnswersWithQuestionId = storedAnswers.map(
            (key, value) => MapEntry(int.parse(key), value),
          );

          // Muat data teks jawaban jika ada
          if (examData.containsKey('textAnswers')) {
            final Map<String, dynamic> storedTextAnswers =
                examData['textAnswers'];
            storedTextAnswers.forEach((key, value) {
              final controller = TextEditingController(text: value.toString());
              textControllers[int.parse(key)] = controller;
            });
          }
        } else {
          // Jika ID ujian tidak cocok, hapus data lama dan buat seed baru
          await _clearLocalExamData();
          _seed = Random().nextInt(1 << 32);
        }
      } else {
        // Jika tidak ada data tersimpan, buat seed baru
        _seed = Random().nextInt(1 << 32);
      }
    } catch (e) {
      debugPrint('Error loading local exam data: $e');
      _seed = Random().nextInt(1 << 32);
    }
  }

  // Fungsi untuk menghapus data ujian lokal
  Future<void> _clearLocalExamData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('exam_data');
    } catch (e) {
      debugPrint('Error clearing local exam data: $e');
    }
  }

  // Fungsi deterministik untuk mengacak berdasarkan seed dan questionId
  List<T> _deterministicShuffle<T>(List<T> items, int seed) {
    if (items.isEmpty) return items;

    final List<T> result =
        List.from(items); // Salin daftar agar tidak mengubah aslinya

    // Algoritma Fisher-Yates dengan Linear Congruential Generator (LCG)
    for (int i = result.length - 1; i > 0; i--) {
      seed = (seed * 1103515245 + 12345) &
          0x7fffffff; // LCG untuk angka acak deterministik
      int j = seed % (i + 1);

      // Swap elemen
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }

    return result;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    Future.microtask(() async {
      await SecureScreen.disableSecure();
    });
    WidgetsBinding.instance.removeObserver(this);
    canGiveExamAgainTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  double getScreenHeight(BuildContext context) {
    _screenHeight ??= MediaQuery.of(context).size.height;
    return _screenHeight!;
  }

  Future<void> setMaxVolume() async {
    const MethodChannel platform = MethodChannel('com.eschool/audio');
    try {
      await platform.invokeMethod('setMaxVolume');
    } on PlatformException catch (e) {
      print("Gagal set volume: ${e.message}");
    }
  }

  void setCanGiveExamTimer() {
    canGiveExamAgainTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (canGiveExamAgainTimeInSeconds == 0) {
        timer.cancel();
        _audioPlayer.stop();
        canGiveExamAgain = false;
        FocusScope.of(context).unfocus();
        await Future.delayed(Duration(milliseconds: 100));
        if (!isExamCompleted) submitExamAnswers(forced: true);
      } else {
        canGiveExamAgainTimeInSeconds--;
      }
    });
  }

  Future<void> _handleAppPause() async {
    await setMaxVolume();
    await platform.invokeMethod("startNativeTimer");
    _saveLocalExamData();
    setCanGiveExamTimer();
  }

  Future<void> _handletransition() async {
    try {
      // Force vibration for exam security - bypasses user settings
      // This ensures exam integrity by alerting when app is switched
      await VibrationHelper.examAppSwitchAlert();
      await _audioPlayer.setAsset('assets/sound/sirene.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(1.0); // volume maksimum
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Gagal memutar audio: $e');
    }
  }

  Future<void> markExamAsCompleted(int examId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList('completedExamIds') ?? [];
    if (!ids.contains(examId.toString())) {
      ids.add(examId.toString());
      await prefs.setStringList('completedExamIds', ids);
    }
  }

  Future<void> _handleBack() async {
    final result = await platform.invokeMethod("cancelNativeTimer");
    if (result == "submit") {
      _audioPlayer.stop();
      FocusScope.of(context).unfocus();
      await Future.delayed(Duration(milliseconds: 100));
      if (!isExamCompleted) submitExamAnswers(forced: true);
    } else if (result == "back") {
      _audioPlayer.stop(); // User kembali tepat waktu
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !isExamCompleted) {
      _handleAppPause();
    } else if (state == AppLifecycleState.inactive) {
      _handletransition();
    } else if (state == AppLifecycleState.resumed) {
      _handleBack();
    }
  }

  void onBackPress() {
    isExitDialogOpen = true;
    if (!isExamCompleted) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.question_mark, size: 48, color: Colors.redAccent),
              SizedBox(height: 16),
              Text(
                Utils.getTranslatedLabel(quitExamKey),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      child: Text(Utils.getTranslatedLabel(yesKey)),
                      onPressed: () async {
                        isExamCompleted = true;
                        await submitExamAnswers(forced: true);
                        await _clearLocalExamData(); // Hapus data lokal saat keluar dari ujian
                        Get.back();
                        Get.until((route) => route.isFirst);
                        HomeScreen.homeScreenKey.currentState!
                            .changeBottomNavItem(0);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        Utils.getTranslatedLabel(noKey),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        isExamCompleted = true;
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).then((value) {
        isExitDialogOpen = false;
      });
    }
  }

  void showFontSettingsBottomSheet(
    BuildContext context, {
    required double initialFontScale, // misal 1.3 = 100%
    required String initialFontFamily,
    required ValueChanged<double> onFontScaleChanged,
    required ValueChanged<String> onFontFamilyChanged,
  }) {
    double localScale = initialFontScale;
    String localFamily = initialFontFamily;

    final fonts = <String>[
      'Roboto',
      'Montserrat',
      'Arial',
      'Times New Roman',
      'Courier New',
      'Open Sans',
      'Lato',
      'Verdana',
      'Georgia',
      'Calibri',
      'Helvetica',
      'Poppins',
      'Nunito',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.text_fields,
                      color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    "Pengaturan Font",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Pilihan font
              const Text(
                "Jenis Font",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: localFamily,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: fonts
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: TextStyle(fontFamily: f),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => localFamily = v);
                  onFontFamilyChanged(v);
                },
              ),

              const SizedBox(height: 24),

              // Scale (ukuran teks)
              const Text(
                "Ukuran Font",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.format_size,
                          color: Theme.of(context).colorScheme.primary),
                      Expanded(
                          child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Theme.of(context)
                              .colorScheme
                              .primary, // warna track aktif
                          inactiveTrackColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.3), // warna track non-aktif
                          thumbColor: Theme.of(context)
                              .colorScheme
                              .primary, // warna bulatan
                          overlayColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2), // efek saat ditekan
                          valueIndicatorColor: Theme.of(context)
                              .colorScheme
                              .primary, // background value label
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white, // teks di label indicator
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Slider(
                          value: localScale,
                          min: 0.8,
                          max: 2.5,
                          divisions: 12,
                          label:
                              "${(localScale * 100).round()}%", // ini akan pakai style di atas
                          onChanged: (v) {
                            setState(() => localScale = v);
                            onFontScaleChanged(v);
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Preview
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Preview Teks Soal",
                    style: TextStyle(
                      fontFamily: localFamily,
                      fontSize: 16 * localScale,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOnlineExamAppbar(BuildContext context) {
    DateTime endDate = DateTime.parse(widget.exam.endDate!);
    DateTime now = DateTime.now();
    int examDuration = endDate.difference(now).inMinutes;
    if (endDate.isBefore(now)) {
      // Jika waktu ujian sudah berakhir, tampilkan dialog selesai ujian
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isExamCompleted) {
          showDialog(
            context: context,
            builder: (context) => buildExamCompleteDialog(),
          ).then((value) {
            isExamCompleted = true;
            _clearLocalExamData(); // Hapus data lokal saat ujian selesai
          });
        }
      });
    }

    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage + 0.02,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 15.0),
                child: CustomBackButton(onTap: onBackPress)),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              widget.exam.subject?.getSubjectName(context: context) ?? "",
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: MediaQuery.of(context).size.width * 0.7, // Limit width
                child:
                    widget.exam.title != null && widget.exam.title!.length > 20
                        ? Container(
                            height: 25, // Fixed height to match Text height
                            alignment: Alignment.center, // Center alignment
                            child: Marquee(
                              text: widget.exam.title! + " ",
                              style: TextStyle(
                                color: Utils.getColorScheme(context).surface,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Center vertical alignment
                              velocity: 30.0,
                              pauseAfterRound: Duration(seconds: 1),
                              startPadding: 10.0,
                            ),
                          )
                        : Text(
                            widget.exam.title ?? "",
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Utils.getColorScheme(context).surface,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 5.0, end: 5.0),
                child: IconButton(
                  onPressed: () {
                    _openFontSettings();
                  },
                  icon: Icon(
                    Icons.text_fields_outlined,
                    color: Utils.getColorScheme(context).surface,
                  ),
                )),
          ),
          Align(
            alignment: AlignmentDirectional.center,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 25.0),
              child: ExamTimerContainer(
                navigateToResultScreen: finishExamOnline,
                examDurationInMinutes: examDuration,
                key: timerKey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showExamQuestionStatusBottomSheet() {
    final submitOnlineExamAnswersCubit =
        context.read<SubmitOnlineExamAnswersCubit>();
    isExamQuestionStatusBottomsheetOpen = true;
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5.0,
      context: context,
      isDismissible: !isSubmissionInProgress,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (context) {
        return ExamQuestionStatusBottomSheetContainer(
            examName: widget.exam.title ?? "",
            submitOnlineExamAnswersCubit: submitOnlineExamAnswersCubit,
            onlineExamId: widget.exam.id ?? 0,
            submittedAnswers: _selectedAnswersWithQuestionId,
            doubtfulQuestionIds: _doubtfulQuestionIds,
            navigateToResultScreen: finishExamOnline,
            pageController: pageController,
            seed: _seed);
      },
    );
  }

  void submitQuestionAnswer(Question question, AnswerOption answerOption) {
    int submittedAnswerIds = _selectedAnswersWithQuestionId[question.id] ?? -1;

    if (submittedAnswerIds == answerOption.id) {
      _selectedAnswersWithQuestionId.remove(question.id);
    } else {
      submittedAnswerIds = answerOption.id ?? -1;
      _selectedAnswersWithQuestionId[question.id ?? 0] = submittedAnswerIds;
    }

    setState(() {});
    // Simpan jawaban secara lokal setiap kali jawaban diperbarui
    _saveLocalExamData();
  }

  Future<void> submitExamAnswers({bool forced = false}) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration(milliseconds: 100));
    if (_doubtfulQuestionIds.isNotEmpty && !forced) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage:
            "Masih ada soal yang ragu-ragu. Hapus tanda ragu untuk lanjut.",
        backgroundColor:
            Colors.orange.shade700, // Warna oranye untuk status ragu-ragu
      );
      timerKey.currentState?.resumeTimer();
      return; // Hentikan proses submit jika ada soal yang masih ragu.
    }

    final totalQuestions =
        context.read<OnlineExamQuestionsCubit>().getQuestions().length;

    // ✅ Cek apakah soal belum semua dijawab
    final isIncomplete = _selectedAnswersWithQuestionId.length < totalQuestions;

    if (isIncomplete && !forced) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseAnswerAllQuestionsKey),
        backgroundColor: Utils.getColorScheme(context).error,
      );
      timerKey.currentState?.resumeTimer();
      return;
    }

    // ✅ Jika forced atau semua sudah dijawab → submit
    setState(() {
      isSubmissionInProgress = true;
    });

    context.read<SubmitOnlineExamAnswersCubit>().submitAnswers(
        examId: widget.exam.id ?? 0, answers: _selectedAnswersWithQuestionId);
    markExamAsCompleted(widget.exam.id!);
    Future.delayed(Duration.zero, () {
      timerKey.currentState?.cancelTimer();
    });
    SecureScreen.disableSecure();
  }

  Future<void> finishExamOnline() async {
    print("ONGKEH");

    print("ONGKEH2");

    if (isExamQuestionStatusBottomsheetOpen && !isSubmissionInProgress) {
      print("ONGKEH3");
      Get.back();
    }
    print("ONGKEH4");
    if (isExitDialogOpen) {
      print("ONGKEH5");
      Get.back();
    }
    print("ONGKEH6");
    if (!isExamCompleted) {
      print("SUBMITTING");
      FocusScope.of(context).unfocus();
      await Future.delayed(Duration(milliseconds: 100));
      submitExamAnswers();
    }
  }

  Widget buildBottomButton() {
    return Container(
      width: getScreenHeight(context) * (0.345),
      height: getScreenHeight(context) * (0.045),
      decoration: BoxDecoration(
        color: Utils.getColorScheme(context).primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: IconButton(
        onPressed: () {
          showExamQuestionStatusBottomSheet();
        },
        padding: EdgeInsets.zero,
        color: Utils.getColorScheme(context).surface,
        highlightColor: Colors.transparent,
        icon: const Icon(
          Icons.keyboard_arrow_up_rounded,
          size: 30,
        ),
      ),
    );
  }

  String toRomanNumeral(int number) {
    if (number < 1) {
      return "Angka harus lebih besar dari 0";
    }

    List<int> values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    List<String> symbols = [
      "M",
      "CM",
      "D",
      "CD",
      "C",
      "XC",
      "L",
      "XL",
      "X",
      "IX",
      "V",
      "IV",
      "I"
    ];

    String result = "";
    int num = number;

    for (int i = 0; i < values.length; i++) {
      while (num >= values[i]) {
        result += symbols[i];
        num -= values[i];
      }
    }

    while (num > 0) {
      result += "M";
      num -= 1000;
    }

    return result;
  }

  String toBaseAZ(int number) {
    if (number < 1) {
      return "Angka harus lebih besar dari 0";
    }

    String result = "";
    int num = number;

    while (num > 0) {
      int remainder = (num - 1) % 26;
      result = String.fromCharCode(65 + remainder) + result;
      num = (num - 1) ~/ 26;
    }

    return result;
  }

  Widget _buildNavigationControls(Question question, int totalQuestions) {
    final bool isDoubtful = _doubtfulQuestionIds.contains(question.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tombol Soal Sebelumnya
          // IconButton(
          //   icon: const Icon(Icons.arrow_back_ios),
          //   onPressed: isFirstQuestion
          //       ? null // Nonaktifkan tombol jika ini soal pertama
          //       : () {
          //           pageController.previousPage(
          //             duration: const Duration(milliseconds: 400),
          //             curve: Curves.easeInOut,
          //           );
          //         },
          // ),

          // Tombol Tandai Ragu-ragu
          // Ganti tombol lama dengan ElevatedButton.icon yang baru ini
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                if (isDoubtful) {
                  _doubtfulQuestionIds.remove(question.id);
                } else {
                  _doubtfulQuestionIds.add(question.id ?? 0);
                }
              });
            },
            icon: Icon(
              isDoubtful ? Icons.flag : Icons.flag_outlined,
              size: 20,
            ),
            label: Text(isDoubtful ? "Hapus Ragu" : "Tandai Ragu"),
            style: ElevatedButton.styleFrom(
              // Terapkan gaya berdasarkan kondisi isDoubtful
              backgroundColor: isDoubtful
                  ? Colors.orange.shade600 // Warna solid saat ragu-ragu
                  : Theme.of(context)
                      .scaffoldBackgroundColor, // Warna latar belakang saat normal
              foregroundColor: isDoubtful
                  ? Colors.white // Warna teks/ikon putih saat ragu-ragu
                  : Colors
                      .orange.shade600, // Warna teks/ikon primer saat normal

              // Bentuk tombol yang konsisten dengan tombol submit
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),

              // Beri garis tepi saat kondisi normal agar terlihat
              side: isDoubtful
                  ? BorderSide.none
                  : BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),

              // Atur padding dan elevasi
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation:
                  isDoubtful ? 4.0 : 0.0, // Efek terangkat saat ragu-ragu

              // Gaya teks yang konsisten
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Tombol Soal Berikutnya
          // IconButton(
          //   icon: const Icon(Icons.arrow_forward_ios),
          //   onPressed: isLastQuestion
          //       ? null // Nonaktifkan tombol jika ini soal terakhir
          //       : () {
          //           pageController.nextPage(
          //             duration: const Duration(milliseconds: 400),
          //             curve: Curves.easeInOut,
          //           );
          //         },
          // ),
        ],
      ),
    );
  }

  Widget _buildQuestions() {
    if (isLoadingLocalData) {
      return Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<OnlineExamQuestionsCubit, OnlineExamQuestionsState>(
      builder: (context, state) {
        if (state is OnlineExamQuestionsFetchSuccess) {
          final questions = _deterministicShuffle(state.questions, _seed);
          return PageView.builder(
            onPageChanged: (index) {
              currentQuestionIndex = index;
              setState(() {});
            },
            controller: pageController,
            itemCount: state.questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                  ),
                  bottom: getScreenHeight(context) * 0.06,
                ),
                child: Column(
                  children: [
                    QuestionContainer(
                      questionColor: Utils.getColorScheme(context).secondary,
                      questionNumber: index + 1,
                      question: question,
                      fontScale: _fontScale,
                      fontFamily: _fontFamily,
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    ...(() {
                      if ((question.type == 'multiple_choice' ||
                              question.type == 'true_false') &&
                          currentQuestionIndex == index)
                        FocusScope.of(context).unfocus();

                      // Acak opsi saat ditampilkan dengan seed konstan
                      final options = (question.type == 'multiple_choice')
                          ? _deterministicShuffle(question.options ?? [], _seed)
                          : (question.options ?? []);

                      return options.asMap().entries.map(
                        (entry) {
                          int index =
                              entry.key + 1; // Ubah ke urutan mulai dari 1
                          var option = entry.value;

                          return OptionContainer(
                            choice: question.choice_style == 'roman_uppercase'
                                ? toRomanNumeral(index).toUpperCase()
                                : question.choice_style == 'roman_lowercase'
                                    ? toRomanNumeral(index).toLowerCase()
                                    : question.choice_style ==
                                            'alphabet_uppercase'
                                        ? toBaseAZ(index).toUpperCase()
                                        : question.choice_style ==
                                                'alphabet_lowercase'
                                            ? toBaseAZ(index).toLowerCase()
                                            : question.choice_style == 'numeric'
                                                ? index.toString()
                                                : null,
                            question: question,
                            fontScale: _fontScale,
                            fontFamily: _fontFamily,
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.85,
                              maxHeight: getScreenHeight(context) *
                                  Utils.questionContainerHeightPercentage,
                            ),
                            answerOption: option,
                            submittedAnswerIds:
                                _selectedAnswersWithQuestionId[question.id] ??
                                    -1,
                            submitAnswer: submitQuestionAnswer,
                          );
                        },
                      ).toList();
                    }()),
                    ...(question.type == 'numeric'
                        ? [
                            if (currentQuestionIndex == index)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: textControllers.putIfAbsent(
                                      question.id ?? -1,
                                      () => TextEditingController()),
                                  keyboardType: TextInputType.number,
                                  autofocus: false, // Prevent automatic focus
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: Utils.getTranslatedLabel(
                                        enterNumericAnswerKey),
                                  ),
                                  onChanged: (value) {
                                    value = value.replaceAll(',', '.');
                                    try {
                                      double.parse(value);
                                      if (value.isNotEmpty) {
                                        _selectedAnswersWithQuestionId[
                                            question.id ?? -1] = value;
                                      } else {
                                        _selectedAnswersWithQuestionId
                                            .remove(question.id);
                                      }
                                      // Simpan perubahan lokal
                                      _saveLocalExamData();
                                    } catch (e) {
                                      _selectedAnswersWithQuestionId
                                          .remove(question.id);
                                      _saveLocalExamData();
                                    }
                                  },
                                  style: TextStyle(
                                    fontSize: 16 * _fontScale,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                              )
                          ]
                        : []),
                    ...(question.type == 'short_answer'
                        ? [
                            if (currentQuestionIndex == index)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: textControllers.putIfAbsent(
                                      question.id ?? -1,
                                      () => TextEditingController()),
                                  maxLength: 128,
                                  maxLines: 2,
                                  autofocus: false, // Prevent automatic focus
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: Utils.getTranslatedLabel(
                                          fillAssignmentTextKey)),
                                  onChanged: (value) {
                                    _selectedAnswersWithQuestionId[
                                        question.id ?? -1] = value;
                                    // Simpan perubahan lokal
                                    _saveLocalExamData();
                                  },
                                  style: TextStyle(
                                    fontSize: 16 * _fontScale,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                              )
                          ]
                        : []),
                    ...(question.type == 'essay'
                        ? [
                            if (currentQuestionIndex == index)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: textControllers.putIfAbsent(
                                      question.id ?? -1,
                                      () => TextEditingController()),
                                  maxLength: 225,
                                  maxLines: 8,
                                  autofocus: false, // Prevent automatic focus
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: Utils.getTranslatedLabel(
                                          fillAssignmentTextKey)),
                                  onChanged: (value) {
                                    _selectedAnswersWithQuestionId[
                                        question.id ?? -1] = value;
                                    // Simpan perubahan lokal
                                    _saveLocalExamData();
                                  },
                                  style: TextStyle(
                                    fontSize: 16 * _fontScale,
                                    fontFamily: _fontFamily,
                                  ),
                                ),
                              )
                          ]
                        : []),
                    const SizedBox(height: 20), // Beri sedikit jarak
                    _buildNavigationControls(question, state.questions.length),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget buildExamCompleteDialog() {
    print("Exam completed dialog opened");
    isExamCompleted = true;
    return Container(
      alignment: Alignment.center,
      color: Utils.getColorScheme(context).secondary.withValues(alpha: 0.5),
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/payment_success.json",
              animate: true,
            ),
            Text(
              Utils.getTranslatedLabel(examCompletedKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Utils.getColorScheme(context).secondary,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          CustomRoundedButton(
            backgroundColor: Utils.getColorScheme(context).primary,
            buttonTitle: Utils.getTranslatedLabel(homeKey),
            titleColor: Theme.of(context).scaffoldBackgroundColor,
            showBorder: false,
            textSize: 16.0,
            widthPercentage: 0.3,
            height: 45,
            onTap: () {
              _clearLocalExamData(); // Hapus data lokal saat kembali ke beranda
              Get.back();
              Get.until((route) => route.isFirst);
              HomeScreen.homeScreenKey.currentState!.changeBottomNavItem(0);
            },
          ),
          CustomRoundedButton(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            buttonTitle: Utils.getTranslatedLabel(resultKey),
            titleColor: Utils.getColorScheme(context).primary,
            textSize: 16.0,
            showBorder: true,
            borderColor: Utils.getColorScheme(context).primary,
            widthPercentage: 0.3,
            height: 45,
            onTap: () {
              _clearLocalExamData(); // Hapus data lokal saat melihat hasil
              context.read<ExamsOnlineCubit>().getExamsOnline(
                  classSubjectId: context
                              .read<ExamTabSelectionCubit>()
                              .state
                              .examFilterByClassSubjectId ==
                          0
                      ? 0
                      : widget.exam.classSubjectId ?? 0,
                  childId: 0,
                  useParentApi: false);

              Get.offNamed(
                Routes.resultOnline,
                arguments: {
                  "examId": widget.exam.id,
                  "examName": widget.exam.title,
                  "subjectName":
                      widget.exam.subject?.getSubjectName(context: context) ??
                          "",
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        onBackPress();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: buildBottomButton(),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        body: Stack(
          children: [
            _buildQuestions(),
            buildOnlineExamAppbar(context),
            BlocConsumer<SubmitOnlineExamAnswersCubit,
                SubmitOnlineExamAnswersState>(
              listener: (context, state) {
                if (state is SubmitOnlineExamAnswersFailure) {
                  isSubmissionInProgress = false;
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: int.tryParse(state.errorMessage) != null
                        ? Utils.getErrorMessageFromErrorCode(
                            context, state.errorMessage,
                            source: "ujian")
                        : state.errorMessage,
                    backgroundColor: Utils.getColorScheme(context).error,
                  );
                }
                if (state is SubmitOnlineExamAnswersSuccess) {
                  isExamQuestionStatusBottomsheetOpen = true;
                  isSubmissionInProgress = false;
                  _clearLocalExamData();
                  setState(() {}); // Hapus data lokal saat pengiriman berhasil
                }
                if (state is SubmitOnlineExamAnswersInProgress) {
                  isSubmissionInProgress = true;
                }
              },
              builder: (context, state) {
                if (state is SubmitOnlineExamAnswersSuccess) {
                  return buildExamCompleteDialog();
                }
                if (isSubmissionInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
