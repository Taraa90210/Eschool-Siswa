import 'dart:convert';

import 'package:eschool/data/models/academic/assignmentList.dart';
import 'package:eschool/data/models/exam/examList.dart';

import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:flutter/foundation.dart';

class ReportRepository {
  Future<Map<String, dynamic>> getExamOnlineReport({
    int? page,
    required int classSubjectId,
    required int childId,
    required bool useParentApi,
  }) async {
    try {
      final result = await Api.get(
        url: useParentApi
            ? Api.parentOnlineExamReport
            : Api.studentOnlineExamReport,
        useAuthToken: true,
        queryParameters: {
          'class_subject_id': classSubjectId,
          if (page != 0 && page != null) 'page': page,
          if (useParentApi) 'child_id': childId,
        },
      );

      print(
          "URL: ${useParentApi ? Api.parentOnlineExamReport : Api.studentOnlineExamReport}");
      final prettyJson = const JsonEncoder.withIndent("  ").convert({
          'class_subject_id': classSubjectId,
          if (page != 0 && page != null) 'page': page,
          if (useParentApi) 'child_id': childId,
        });
      final lines = prettyJson.split('\n');
      for (int i = 0; i < lines.length; i++) {
        print("${lines[i]}");
      }

      print("Response");

      final prettyJson2 = const JsonEncoder.withIndent("  ").convert(result['data']);
      final lines2 = prettyJson2.split('\n');
      for (int i = 0; i < lines2.length; i++) {
        print("${lines2[i]}");
      }

      final resultData = result['data'];
      if (resultData is List && resultData.isEmpty) {
        throw ApiException(ErrorMessageKeysAndCode.noOnlineExamReportFoundCode);
      }
      return {
        "examList": ExamList.fromJson(Map.from(resultData['exam_list'])),
        "attempted": resultData['attempted'],
        "missedExams": resultData['missed_exams'],
        "totalExams": resultData['total_exams'],
        "percentage": resultData['percentage'],
        "totalObtainedMarks": resultData['total_obtained_marks'],
        "totalMarks": resultData['total_marks'],
      };
    } catch (e) {
      print(e.toString());
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> getAssignmentReport({
    int? page,
    required int classSubjectId,
    required int childId,
    required bool useParentApi,
  }) async {
    try {
      final result = await Api.get(
        url: useParentApi
            ? Api.parentAssignmentReport
            : Api.studentAssignmentReport,
        useAuthToken: true,
        queryParameters: {
          if (classSubjectId != 0) 'class_subject_id': classSubjectId,
          if (page != 0) 'page': page,
          if (useParentApi) 'child_id': childId,
        },
      );
      final resultData = result['data'];

      return {
        "assignmentList": AssignmentList.fromJson(
          resultData['submitted_assignment_with_points_data'],
        ),
        "assignments": resultData['assignments'],
        "submittedAssignments": resultData['submitted_assignments'],
        "unsubmittedAssignments": resultData['unsubmitted_assignments'],
        "percentage": resultData['percentage'],
        "totalObtainedPoints": resultData['total_obtained_points'],
        "totalPoints": resultData['total_points'],
      };
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      throw ApiException(e.toString());
    }
  }
}
