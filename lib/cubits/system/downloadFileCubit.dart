import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/data/repositories/subjectRepository.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

abstract class DownloadFileState {}

class DownloadFileInitial extends DownloadFileState {}

class DownloadFileInProgress extends DownloadFileState {
  final double uploadedPercentage;
  DownloadFileInProgress(this.uploadedPercentage);
}

class DownloadFileSuccess extends DownloadFileState {
  final String downloadedFileUrl;
  DownloadFileSuccess(this.downloadedFileUrl);
}

class DownloadFileProcessCanceled extends DownloadFileState {}

class DownloadFileFailure extends DownloadFileState {
  final String errorMessage;
  DownloadFileFailure(this.errorMessage);
}

class DownloadFileCubit extends Cubit<DownloadFileState> {
  final SubjectRepository _subjectRepository;
  DownloadFileCubit(this._subjectRepository) : super(DownloadFileInitial());

  final CancelToken _cancelToken = CancelToken();

  void _downloadedFilePercentage(double percentage) {
    emit(DownloadFileInProgress(percentage));
  }

  Future<void> writeFileFromTempStorage({
    required String sourcePath,
    required String destinationPath,
  }) async {
    final tempFile = File(sourcePath);
    final byteData = await tempFile.readAsBytes();
    final downloadedFile = File(destinationPath);
    await downloadedFile.writeAsBytes(
      byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
  }

  /// Cek izin dan buat folder eSchool di Downloads
  Future<Directory?> getExternalDirectory() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    bool isAndroid11OrAbove = androidInfo.version.sdkInt >= 30;
    Permission permission = isAndroid11OrAbove
        ? Permission.manageExternalStorage
        : Permission.storage;

    if (!await permission.isGranted) {
      if (!await permission.request().isGranted) {
        debugPrint('Izin akses penyimpanan ditolak');
        return null;
      }
    }

    const String eSchoolPath = '/storage/emulated/0/Download/eSchool/';
    final Directory eSchoolDir = Directory(eSchoolPath);

    if (!await eSchoolDir.exists()) {
      await eSchoolDir.create(recursive: true);
      debugPrint('Folder eSchool dibuat di $eSchoolPath');
    }

    return eSchoolDir;
  }

  /// Pastikan fileName tidak double ekstensi
  String getSafeFileName(String fileName, String fileExtension) {
    if (fileName.toLowerCase().endsWith('.$fileExtension'.toLowerCase())) {
      return fileName;
    }
    return "$fileName.$fileExtension";
  }

  Future<void> downloadFile({
    required StudyMaterial studyMaterial,
    required bool storeInExternalStorage,
  }) async {
    emit(DownloadFileInProgress(0.0));

    try {
      final safeFileName =
          getSafeFileName(studyMaterial.fileName, studyMaterial.fileExtension);

      // Temp file untuk download
      final Directory tempDir = await getTemporaryDirectory();
      final tempFileSavePath = "${tempDir.path}/$safeFileName";

      // Download dari repository
      await _subjectRepository.downloadStudyMaterialFile(
        cancelToken: _cancelToken,
        fileName: safeFileName,
        savePath: tempFileSavePath,
        updateDownloadedPercentage: _downloadedFilePercentage,
        url: studyMaterial.fileUrl,
      );

      if (storeInExternalStorage) {
        final Directory? externalDir = await getExternalDirectory();
        if (externalDir == null) {
          emit(DownloadFileFailure(
              ErrorMessageKeysAndCode.permissionNotGivenCode));
          openAppSettings();
          return;
        }

        final String downloadFilePath = p.join(externalDir.path, safeFileName);

        await writeFileFromTempStorage(
          sourcePath: tempFileSavePath,
          destinationPath: downloadFilePath,
        );

        emit(DownloadFileSuccess(downloadFilePath));
      } else {
        // Simpan di app dir (aman)
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String savePath = p.join(appDir.path, safeFileName);

        await writeFileFromTempStorage(
          sourcePath: tempFileSavePath,
          destinationPath: savePath,
        );

        emit(DownloadFileSuccess(savePath));
      }
    } catch (e) {
      if (_cancelToken.isCancelled) {
        emit(DownloadFileProcessCanceled());
      } else {
        emit(DownloadFileFailure(e.toString()));
      }
    }
  }

  void cancelDownloadProcess() {
    _cancelToken.cancel();
  }
}


