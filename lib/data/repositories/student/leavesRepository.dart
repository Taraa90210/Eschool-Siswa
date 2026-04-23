import 'package:dio/dio.dart';
import 'package:eschool/data/models/student/leave.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';

enum LeaveType {
  sick('Sick'),
  leave('Leave');

  final String value;
  const LeaveType(this.value);
}

class LeavesRepository {
  Future<List<Leave>> fetchChildLeaves({
    required int childId,
    bool useParentApi = true,
  }) async {
    try {
      final result = await Api.get(
        url: Api.parentGetLeaves,
        useAuthToken: true,
        queryParameters: {'child_id': childId},
      );

      if (kDebugMode) {
        print("Response data for leaves: ${result['data']}");
      }

      if (result['data'] is! List) {
        throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
      }

      return (result['data'] as List).map((leave) {
        try {
          print(leave);
          return Leave.fromJson(Map<String, dynamic>.from(leave));
        } catch (e) {
          if (kDebugMode) {
            print("Error parsing leave: $e");
          }
          throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
        }
      }).toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  String _fmtBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(1)} ${units[unit]}';
  }

  MediaType _mediaTypeFor(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.bmp':
        return MediaType('image', 'bmp');
      case '.heic':
        return MediaType('image', 'heic');
      case '.tif':
      case '.tiff':
        return MediaType('image', 'tiff');
      case '.pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<void> applyLeave({
    required int childId,
    required String reason,
    required List<Map<String, String>> leaveDetails,
    List<String>? files,
  }) async {
    try {
      final formData = FormData();

      // Debug field dasar
      if (kDebugMode) {
        print("Child ID: $childId");
        print("Reason: $reason");
      }

      formData.fields.addAll([
        MapEntry('child_id', childId.toString()),
        MapEntry('reason', reason),
      ]);

      // Debug leave details
      if (kDebugMode) {
        print("\nLeave Details:");
        leaveDetails.asMap().forEach((index, detail) {
          print("Detail $index:");
          print("  Date: ${detail['date']}");
          print("  Type: ${detail['type']}");
        });
      }

      for (int i = 0; i < leaveDetails.length; i++) {
        formData.fields.addAll([
          MapEntry('leave_details[$i][date]', leaveDetails[i]['date']!),
          MapEntry('leave_details[$i][type]', leaveDetails[i]['type']!),
        ]);
      }

      // Files (upload-only, tanpa kompres)
      if (files != null && files.isNotEmpty) {
        if (kDebugMode) {
          print("\nFiles to upload:");
          files.asMap().forEach((index, filePath) {
            print("File $index: $filePath");
          });
        }

        for (int i = 0; i < files.length; i++) {
          try {
            final original = File(files[i]);
            if (!await original.exists()) continue;

            final ukuranAwal = _fmtBytes(original.lengthSync());
            if (kDebugMode) print("ukuran (awal): $ukuranAwal");

            // Tidak ada kompresi — langsung pakai file asli
            final toUpload = original;

            // ContentType mengikuti ekstensi file yang diupload
            final outExt = p.extension(toUpload.path).toLowerCase();
            final mediaType = _mediaTypeFor(outExt);

            final multipartFile = await MultipartFile.fromFile(
              toUpload.path,
              filename: p.basename(toUpload.path),
              contentType: mediaType,
            );

            // Jika backend butuh "files[]" tanpa index, ganti 'files[$i]' jadi 'files[]'
            formData.files.add(MapEntry('files[$i]', multipartFile));
          } catch (e) {
            // lanjut ke file berikutnya kalau ada error
            if (kDebugMode) {
              print('Gagal memproses file ${files[i]}: $e');
            }
          }
        }
      }

      if (kDebugMode) {
        print("\nForm Data Fields:");
        formData.fields.forEach((field) {
          print("${field.key}: ${field.value}");
        });

        print("\nForm Data Files:");
        formData.files.forEach((file) {
          print("${file.key}: ${file.value.filename}");
        });
      }

      final result = await Api.post(
        url: Api.parentApplyLeaves,
        body: formData,
        useAuthToken: true,
      );

      if (kDebugMode) {
        print("\nAPI Response:");
        print("Status: ${result['error'] == true ? 'Error' : 'Success'}");
        print("Message: ${result['message'] ?? 'No message'}");
        print("Full Response: $result");
      }

      if (result['error'] == true) {
        throw ApiException(result['message'] ??
            ErrorMessageKeysAndCode.defaultErrorMessageCode);
      }
    } catch (e) {
      if (kDebugMode) {
        print("\nError Details:");
        print("Type: ${e.runtimeType}");
        print("Message: $e");
      }
      throw ApiException(e.toString());
    }
  }
}
