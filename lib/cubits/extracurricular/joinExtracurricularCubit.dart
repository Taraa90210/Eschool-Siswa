import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/repositories/extracurricular/extracurricularRepository.dart';
import 'package:eschool/data/models/extracurricular/joinExtracurricularResponse.dart';
import 'package:eschool/utils/api.dart';

abstract class JoinExtracurricularState {}

class JoinExtracurricularInitial extends JoinExtracurricularState {}

class JoinExtracurricularInProgress extends JoinExtracurricularState {}

class JoinExtracurricularSuccess extends JoinExtracurricularState {
  final String message;
  final JoinExtracurricularResponse? data;

  JoinExtracurricularSuccess(this.message, {this.data});
}

class JoinExtracurricularFailure extends JoinExtracurricularState {
  final String errorMessage;

  JoinExtracurricularFailure(this.errorMessage);
}

class JoinExtracurricularCubit extends Cubit<JoinExtracurricularState> {
  final ExtracurricularRepository _extracurricularRepository;

  JoinExtracurricularCubit(this._extracurricularRepository) : super(JoinExtracurricularInitial());

  Future<void> joinExtracurricular({
    required int extracurricularId,
    required int studentId,
    required String nisn,
  }) async {
    emit(JoinExtracurricularInProgress());
    try {
      final result = await _extracurricularRepository.joinExtracurricular(
        extracurricularId: extracurricularId,
        studentId: studentId,
        nisn: nisn,
      );

      // Check for success - handle both boolean and string values
      final isSuccess = result['success'] == true || result['success'] == 'true' || result['success'] == 1;
      
      if (isSuccess) {
        emit(JoinExtracurricularSuccess(
          result['message'] ?? 'Pendaftaran ekstrakurikuler berhasil dikirim, menunggu persetujuan.',
          data: result['data'],
        ));
      } else {
        emit(JoinExtracurricularFailure(
          result['message'] ?? 'Gagal mendaftar ekstrakurikuler',
        ));
      }
    } catch (e) {
      String errorMessage = 'Terjadi kesalahan saat mendaftar ekstrakurikuler';
      
      if (e is ApiException) {
        // Handle specific API errors based on contract
        String apiError = e.errorMessage.toLowerCase();
        
        if (apiError.contains('409') || apiError.contains('sudah terdaftar') || apiError.contains('already registered')) {
          errorMessage = 'Kamu sudah terdaftar di ekstrakurikuler ini.';
        } else if (apiError.contains('422') || apiError.contains('validasi') || apiError.contains('validation')) {
          errorMessage = 'Data yang dikirim tidak valid. Silakan coba lagi.';
        } else if (apiError.contains('401') || apiError.contains('unauthorized')) {
          errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        } else if (apiError.contains('403') || apiError.contains('forbidden')) {
          errorMessage = 'Anda tidak memiliki izin untuk mendaftar ekstrakurikuler ini.';
        } else if (apiError.contains('404') || apiError.contains('not found')) {
          errorMessage = 'Ekstrakurikuler tidak ditemukan.';
        } else if (apiError.contains('500') || apiError.contains('server error')) {
          errorMessage = 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
        } else {
          errorMessage = e.errorMessage;
        }
      }
      
      emit(JoinExtracurricularFailure(errorMessage));
    }
  }

  void reset() {
    emit(JoinExtracurricularInitial());
  }
}
