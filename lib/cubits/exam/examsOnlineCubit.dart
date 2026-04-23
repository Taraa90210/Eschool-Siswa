// lib/cubits/examsOnlineCubit.dart
//
// Cubit untuk Online Exam dengan dukungan:
// - Fetch awal (getExamsOnline)
// - Infinite scroll (getMoreExamsOnline - append)
// - Numbered pagination (goToPage - replace)
// - Metadata pagination (from/to/total/prev/next)
// - Menyimpan last-used params agar pemanggilan berikutnya ringkas
//
// Catatan:
// - Untuk UI numbered pagination, panggil goToPage(page: X).
// - Untuk infinite scroll, panggil getMoreExamsOnline() saat mendekati bawah.
//
// Contoh di UI (PaginationBar):
// PaginationBar(
//   currentPage: state.currentPage,
//   lastPage: state.totalPage,
//   onTapPage: (p) => context.read<ExamsOnlineCubit>().goToPage(page: p),
// )

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eschool/data/models/exam/examOnline.dart';
import 'package:eschool/data/repositories/onlineExamRepository.dart';

/// ====== STATES ======

abstract class ExamsOnlineState {}

class ExamsOnlineInitial extends ExamsOnlineState {}

class ExamsOnlineFetchInProgress extends ExamsOnlineState {}

class ExamsOnlineFetchSuccess extends ExamsOnlineState {
  final List<ExamOnline> examList;

  /// Halaman saat ini & total halaman
  final int currentPage;
  final int totalPage;

  /// Metadata pagination (opsional untuk UI "Menampilkan x–y dari total")
  final int? from;
  final int? to;
  final int? total;

  /// URL halaman berikut/sebelumnya (jika diperlukan)
  final String? nextPageUrl;
  final String? prevPageUrl;

  /// Jika fetch more (append) sedang berjalan → true
  final bool fetchMoreExamsInProgress;

  /// Jika fetch more (append) error → true (agar UI bisa show retry)
  final bool moreExamsFetchError;

  /// Filter yang aktif (0 = semua)
  final int? classSubjectId;

  /// Penanda "sedang pindah halaman tertentu" (numbered pagination)
  final bool jumpingToPage;

  ExamsOnlineFetchSuccess({
    required this.examList,
    required this.currentPage,
    required this.totalPage,
    this.from,
    this.to,
    this.total,
    this.nextPageUrl,
    this.prevPageUrl,
    this.fetchMoreExamsInProgress = false,
    this.moreExamsFetchError = false,
    this.jumpingToPage = false,
    this.classSubjectId,
  });

  ExamsOnlineFetchSuccess copyWith({
    List<ExamOnline>? newExamList,
    int? newCurrentPage,
    int? newTotalPage,
    int? newFrom,
    int? newTo,
    int? newTotal,
    String? newNextPageUrl,
    String? newPrevPageUrl,
    bool? newFetchMoreExamsInProgress,
    bool? newMoreExamsFetchError,
    bool? newJumpingToPage,
    int? newClassSubjectId,
  }) {
    return ExamsOnlineFetchSuccess(
      examList: newExamList ?? examList,
      currentPage: newCurrentPage ?? currentPage,
      totalPage: newTotalPage ?? totalPage,
      from: (newFrom != null) ? newFrom : from,
      to: (newTo != null) ? newTo : to,
      total: (newTotal != null) ? newTotal : total,
      nextPageUrl: (newNextPageUrl != null) ? newNextPageUrl : nextPageUrl,
      prevPageUrl: (newPrevPageUrl != null) ? newPrevPageUrl : prevPageUrl,
      fetchMoreExamsInProgress:
          newFetchMoreExamsInProgress ?? fetchMoreExamsInProgress,
      moreExamsFetchError: newMoreExamsFetchError ?? moreExamsFetchError,
      jumpingToPage: newJumpingToPage ?? jumpingToPage,
      classSubjectId: newClassSubjectId ?? classSubjectId,
    );
  }
}

class ExamsOnlineFetchFailure extends ExamsOnlineState {
  final String errorMessage;

  /// Informasi tambahan (opsional) berguna saat debug
  final int? pageTried;
  final int? classSubjectId;

  ExamsOnlineFetchFailure(this.errorMessage, this.pageTried, this.classSubjectId);
}

/// ====== CUBIT ======

class ExamsOnlineCubit extends Cubit<ExamsOnlineState> {
  final OnlineExamRepository examRepository;

  ExamsOnlineCubit(this.examRepository) : super(ExamsOnlineInitial());

  /// Simpan parameter terakhir agar pemanggilan berikutnya tidak perlu dioper lagi
  int _lastClassSubjectId = 0;
  int _lastChildId = 0;
  bool _lastUseParentApi = false;

  /// Fetch awal (halaman 1 by default)
  Future<void> getExamsOnline({
    int? page,
    required int classSubjectId,
    required int childId,
    required bool useParentApi,
  }) async {
    // simpan parameter terakhir
    _lastClassSubjectId = classSubjectId;
    _lastChildId = childId;
    _lastUseParentApi = useParentApi;

    emit(ExamsOnlineFetchInProgress());
    try {
      final value = await examRepository.getExamsOnline(
        classSubjectId: classSubjectId,
        page: page,
        childId: childId,
        useParentApi: useParentApi,
      );

      emit(
        ExamsOnlineFetchSuccess(
          classSubjectId: classSubjectId,
          examList: (value['examList'] as List<ExamOnline>?) ?? const [],
          currentPage: value['currentPage'] as int? ?? 0,
          totalPage: value['totalPage'] as int? ?? 0,
          from: value['from'] as int?,
          to: value['to'] as int?,
          total: value['total'] as int?,
          nextPageUrl: value['nextPageUrl'] as String?,
          prevPageUrl: value['prevPageUrl'] as String?,
          fetchMoreExamsInProgress: false,
          moreExamsFetchError: false,
          jumpingToPage: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getExamsOnline error: $e');
      }
      emit(ExamsOnlineFetchFailure(e.toString(), page, classSubjectId));
    }
  }

  /// Infinite scroll: ambil halaman berikutnya dan **append** ke list
  Future<void> getMoreExamsOnline({
    int? childId,
    bool? useParentApi,
  }) async {
    if (state is! ExamsOnlineFetchSuccess) return;

    final s = state as ExamsOnlineFetchSuccess;

    // Sudah tidak ada halaman berikut
    if (s.currentPage >= s.totalPage) return;

    // Jika sedang append, jangan dobel panggilan
    if (s.fetchMoreExamsInProgress) return;

    emit(s.copyWith(newFetchMoreExamsInProgress: true, newMoreExamsFetchError: false));

    try {
      final value = await examRepository.getExamsOnline(
        page: s.currentPage + 1,
        classSubjectId: s.classSubjectId ?? _lastClassSubjectId,
        childId: childId ?? _lastChildId,
        useParentApi: useParentApi ?? _lastUseParentApi,
      );

      final newList = List<ExamOnline>.from(s.examList)
        ..addAll((value['examList'] as List<ExamOnline>?) ?? const []);

      emit(
        s.copyWith(
          newExamList: newList,
          newCurrentPage: value['currentPage'] as int? ?? s.currentPage,
          newTotalPage: value['totalPage'] as int? ?? s.totalPage,
          newFrom: value['from'] as int?,
          newTo: value['to'] as int?,
          newTotal: value['total'] as int?,
          newNextPageUrl: value['nextPageUrl'] as String?,
          newPrevPageUrl: value['prevPageUrl'] as String?,
          newFetchMoreExamsInProgress: false,
          newMoreExamsFetchError: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getMoreExamsOnline error: $e');
      }
      emit(
        s.copyWith(
          newFetchMoreExamsInProgress: false,
          newMoreExamsFetchError: true,
        ),
      );
    }
  }
  Future<void> goToPage({
    required int page,
    int? childId,
    bool? useParentApi,
  }) async {
    if (state is! ExamsOnlineFetchSuccess) return;

    final s = state as ExamsOnlineFetchSuccess;

    if (page < 1) page = 1;
    if (s.totalPage > 0 && page > s.totalPage) page = s.totalPage;

    emit(s.copyWith(newJumpingToPage: true, newMoreExamsFetchError: false));

    try {
      final value = await examRepository.getExamsOnline(
        page: page,
        classSubjectId: s.classSubjectId ?? _lastClassSubjectId,
        childId: childId ?? _lastChildId,
        useParentApi: useParentApi ?? _lastUseParentApi,
      );

      emit(
        s.copyWith(
          newExamList: (value['examList'] as List<ExamOnline>?) ?? const [],
          newCurrentPage: value['currentPage'] as int? ?? page,
          newTotalPage: value['totalPage'] as int? ?? s.totalPage,
          newFrom: value['from'] as int?,
          newTo: value['to'] as int?,
          newTotal: value['total'] as int?,
          newNextPageUrl: value['nextPageUrl'] as String?,
          newPrevPageUrl: value['prevPageUrl'] as String?,
          newFetchMoreExamsInProgress: false,
          newMoreExamsFetchError: false,
          newJumpingToPage: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('goToPage error: $e');
      }
      emit(
        s.copyWith(
          newJumpingToPage: false,
          newMoreExamsFetchError: true,
        ),
      );
    }
  }

  Future<void> refresh() async {
    await getExamsOnline(
      page: 1,
      classSubjectId: _lastClassSubjectId,
      childId: _lastChildId,
      useParentApi: _lastUseParentApi,
    );
  }

  bool hasMore() {
    if (state is ExamsOnlineFetchSuccess) {
      final s = state as ExamsOnlineFetchSuccess;
      return s.currentPage < s.totalPage;
    }
    return false;
  }
}
