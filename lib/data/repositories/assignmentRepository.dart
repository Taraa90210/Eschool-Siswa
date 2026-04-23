import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eschool/data/models/academic/assignment.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/imageCompress.dart'; // <-- util kompres (DartImagePreprocessor)
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class AssignmentRepository {
  // ===== Helper lokal (logging & MIME) =====
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

  MediaType _mediaTypeForExt(String ext) {
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
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<Map<String, dynamic>> fetchAssignments({
    int? page,
    int? assignmentId,
    int? classSubjectId,
    required int isSubmitted,
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {
        "assignment_id": assignmentId ?? 0,
        "class_subject_id": classSubjectId ?? 0,
        "page": page ?? 0,
        "is_submitted": isSubmitted
      };

      if (queryParameters['assignment_id'] == 0) {
        queryParameters.remove('assignment_id');
      }

      if (queryParameters['class_subject_id'] == 0) {
        queryParameters.remove('class_subject_id');
      }

      if (queryParameters['page'] == 0) {
        queryParameters.remove('page');
      }

      if (useParentApi) {
        queryParameters.addAll({"child_id": childId});
      }

      final result = await Api.get(
        url: useParentApi ? Api.getAssignmentsParent : Api.getAssignments,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      print("RESULT");

      final encoder = JsonEncoder.withIndent('  '); // 2 spaces
      final resultJson = encoder.convert(result);

      final lines = resultJson.split('\n');
      for (final line in lines) {
        print(line);
      }

      final data = result['data'];

      // If data is String (empty response), return empty list
      if (data is String) {
        return {
          "assignments": <Assignment>[],
          "totalPage": 0,
          "currentPage": 0,
        };
      }

      // If data is a List (because Api.get wrapped it)
      if (data is List) {
        return {
          "assignments": data.map((e) {
            return Assignment.fromJson(Map.from(e));
          }).toList(),
          "totalPage": 0, // No pagination info in list
          "currentPage": 0,
        };
      }

      // If data is Map (standard paginated response)
      if (data is Map && data.containsKey('data')) {
        return {
          "assignments": (data['data'] as List).map((e) {
            return Assignment.fromJson(Map.from(e));
          }).toList(),
          "totalPage": data['last_page'] as int,
          "currentPage": data['current_page'] as int,
        };
      }

      // Fallback or empty if structure is unknown
      return {
        "assignments": <Assignment>[],
        "totalPage": 0,
        "currentPage": 0,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<AssignmentSubmission> submitAssignment({
    required int assignmentId,
    required List<String> filePaths,
    required CancelToken cancelToken,
    required Function updateUploadAssignmentPercentage,
    required String answerText,
  }) async {
    try {
      // Target kompres super kecil ~10 KB
      const int kTargetBytes = 10 * 1024; // 10 KB
      const int kStartMaxDim = 720; // start resize

      final formData = FormData();

      // Field biasa
      formData.fields.add(MapEntry("assignment_id", assignmentId.toString()));
      formData.fields.add(MapEntry("text", answerText));

      // Siapkan file (kompres + log)
      for (int i = 0; i < filePaths.length; i++) {
        final path = filePaths[i];
        final f = File(path);

        if (!await f.exists()) {
          if (kDebugMode)
            debugPrint('[Assignment] SKIP: file tidak ditemukan: $path');
          continue;
        }

        final before = await f.length();

        // Kompres agresif (flatten alpha -> JPEG, turunkan kualitas & dimensi, boleh grayscale)
        final File compressed = await DartImagePreprocessor.processFile(f,
            maxBytes: kTargetBytes,
            maxDimension: kStartMaxDim,
            flattenAlphaToWhite: true);

        final after = await compressed.length();

        if (kDebugMode) {
          final name = p.basename(f.path);
          final saved = before - after > 0 ? before - after : 0;
          final pct = before > 0 ? (saved / before * 100) : 0.0;
          debugPrint(
              '[Assignment] $name | ${_fmtBytes(before)} → ${_fmtBytes(after)} '
              '(hemat ${_fmtBytes(saved)} ~ ${pct.toStringAsFixed(1)}%)');
        }

        final outExt = p.extension(compressed.path).toLowerCase();
        final mediaType = _mediaTypeForExt(outExt);

        final mf = await MultipartFile.fromFile(
          compressed.path,
          filename: p.basename(compressed.path), // pakai nama hasil kompres
          contentType: mediaType,
        );

        // Laravel-friendly: files[] atau files[$i]
        formData.files.add(MapEntry('files[]', mf));
      }

      final result = await Api.post(
        body: formData,
        url: Api.submitAssignment,
        useAuthToken: true,
        cancelToken: cancelToken,
        onSendProgress: (count, total) {
          updateUploadAssignmentPercentage((count / total) * 100);
        },
      );

      print("RESSLT");

      final data = result['data'];
      if (data is List) {
        final assignmentSubmissions = data;
        return AssignmentSubmission.fromJson(
          Map.from(
            assignmentSubmissions.isEmpty ? {} : assignmentSubmissions.first,
          ),
        );
      } else if (data is Map<String, dynamic>) {
        return AssignmentSubmission.fromJson(Map.from(data));
      } else {
        throw ApiException("Unexpected data format: ${data.runtimeType}");
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteAssignment({
    required int assignmentSubmissionId,
  }) async {
    try {
      await Api.post(
        body: {"assignment_submission_id": assignmentSubmissionId},
        url: Api.deleteAssignment,
        useAuthToken: true,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
