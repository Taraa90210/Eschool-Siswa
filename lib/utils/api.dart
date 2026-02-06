import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/utils/DownloadHelper.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class ApiException implements Exception {
  String errorMessage;

  ApiException(this.errorMessage);

  @override
  String toString() {
    return errorMessage;
  }
}

// ignore: avoid_classes_with_only_static_members
class Api {
  static Map<String, dynamic> headers() {
    final String jwtToken = AuthRepository().getJwtToken();
    final schoolCode = AuthRepository().schoolCode;

    if (kDebugMode) {
      print(jwtToken);
    }

    return {
      "Authorization": "Bearer $jwtToken",
      "school_code": schoolCode,
      // "localtonet-skip-warning": "true",
      "Accept": "application/json",
    };
  }

  ///[General Apis]
  //Apis that will be use in both student and parent app
  //
  static String logout = "${databaseUrl}logout";
  static String settings = "${databaseUrl}settings";
  static String holidays = "${databaseUrl}holidays";

  static String changePassword = "${databaseUrl}change-password";
  static String getSchoolGallery = "${databaseUrl}gallery";
  static String getSchoolSessionYears = "${databaseUrl}session-years";
  static String getUsers = "${databaseUrl}users";
  static String getUserChatHistory = "${databaseUrl}users/chat/history";
  static String chatMessages = "${databaseUrl}message";
  static String readMessages = "${databaseUrl}message/read";
  static String deleteMessages = "${databaseUrl}delete/message";

  //

  //
  ///[Student app apis]
  //
  static String studentLogin = "${databaseUrl}student/login";
  static String studentProfile = "${databaseUrl}student/get-profile-data";
  static String studentSubjects = "${databaseUrl}student/subjects";
  //get subjects of given class
  static String classSubjects = "${databaseUrl}student/class-subjects";
  static String studentTimeTable = "${databaseUrl}student/timetable";
  static String studentExamList = "${databaseUrl}student/get-exam-list";
  static String studentExamStatus =
      "${databaseUrl}student/get-online-exam-status";

  static String getSchoolSettingDetails =
      "${databaseUrl}student/school-settings";

  static String studentExamDetails = "${databaseUrl}student/get-exam-details";
  static String selectStudentElectiveSubjects =
      "${databaseUrl}student/select-subjects";
  static String getLessonsOfSubject = "${databaseUrl}student/lessons";
  static String getstudyMaterialsOfTopic =
      "${databaseUrl}student/lesson-topics";
  static String getStudentAttendance = "${databaseUrl}student/attendance";
  static String getAssignments = "${databaseUrl}student/assignments";
  static String submitAssignment = "${databaseUrl}student/submit-assignment";
  static String generalAnnouncements = "${databaseUrl}student/announcements";
  static String guardianDetailsOfStudent =
      "${databaseUrl}student/guradian-details";
  static String deleteAssignment =
      "${databaseUrl}student/delete-assignment-submission";

  static String studentResults = "${databaseUrl}student/exam-marks";
  static String requestResetPassword = "${databaseUrl}student/forgot-password";

  static String studentExamOnlineList =
      "${databaseUrl}student/get-online-exam-list";
  static String studentExamOnlineQuestions =
      "${databaseUrl}student/get-online-exam-questions";
  static String studentSubmitOnlineExamAnswers =
      "${databaseUrl}student/submit-online-exam-answers";

  static String studentOnlineExamResultList =
      "${databaseUrl}student/get-online-exam-result-list";

  static String studentOnlineExamResult =
      "${databaseUrl}student/get-online-exam-result";

  static String studentOnlineExamReport =
      "${databaseUrl}student/get-online-exam-report";
  static String studentAssignmentReport =
      "${databaseUrl}student/get-assignments-report";

  static String getStudentSliders = "${databaseUrl}student/sliders";

  // Fitur Tambahan E-School versi 1.3.3 Student - Galang
  static String getSubjectAttendance =
      "${databaseUrl}student/subject-attendance";

  static String getSystemInformation = "${databaseUrl}/api/information";

  //
  ///[Parent app apis]
  //
  static String subjectsByChildId = "${databaseUrl}parent/subjects";
  static String parentLogin = "${databaseUrl}parent/login";

  //
  static String childProfileDetails =
      "${databaseUrl}parent/get-child-profile-data";
  static String lessonsOfSubjectParent = "${databaseUrl}parent/lessons";
  static String getstudyMaterialsOfTopicParent =
      "${databaseUrl}parent/lesson-topics";
  static String getAssignmentsParent = "${databaseUrl}parent/assignments";
  static String getParentChildSchoolSettingDetails =
      "${databaseUrl}parent/school-settings";
  static String getStudentAttendanceParent = "${databaseUrl}parent/attendance";
  static String getStudentTimetableParent = "${databaseUrl}parent/timetable";
  static String getStudentExamListParent = "${databaseUrl}parent/get-exam-list";
  static String getStudentResultsParent = "${databaseUrl}parent/exam-marks";
  static String getStudentExamDetailsParent =
      "${databaseUrl}parent/get-exam-details";
  static String updateGuardianPhoto = "${databaseUrl}parent/profile";

  static String generalAnnouncementsParent =
      "${databaseUrl}parent/announcements";

  static String getStudentTeachersParent = "${databaseUrl}parent/teachers";
  static String forgotPassword = "${databaseUrl}forgot-password";

  static String getStudentFeesDetailParent = "${databaseUrl}parent/fees";
  static String addFeesTransaction =
      "${databaseUrl}parent/add-fees-transaction";
  static String failPaymentTransaction =
      "${databaseUrl}parent/fail-payment-transaction";
  static String storeFeesParent = "${databaseUrl}parent/store-fees";

  static String getPaidFeesListParent = "${databaseUrl}parent/fees-paid-list";
  static String downloadFeesPaidReceiptParent =
      "${databaseUrl}parent/fees-paid-receipt-pdf";

  static String parentExamOnlineList =
      "${databaseUrl}parent/get-online-exam-list";
  static String parentOnlineExamResultList =
      "${databaseUrl}parent/get-online-exam-result-list";
  static String parentOnlineExamResult =
      "${databaseUrl}parent/get-online-exam-result";
  static String parentOnlineExamReport =
      "${databaseUrl}parent/get-online-exam-report";
  static String parentAssignmentReport =
      "${databaseUrl}parent/get-assignments-report";

  static String getFeesTransactions =
      "${databaseUrl}parent/fees-transactions-list";

  static String getParentSliders = "${databaseUrl}parent/sliders";

  static String payChildCompulsoryFees =
      "${databaseUrl}parent/fees/compulsory/pay";

  static String payChildOptionalFees = "${databaseUrl}parent/fees/optional/pay";
  static String confirmPayment = "${databaseUrl}payment-confirmation";
  static String getTransactions = "${databaseUrl}payment-transactions";
  static String downloadFeeReceipt = "${databaseUrl}parent/fees/receipt";
  static String downloadStudentResult = "${databaseUrl}student-exan-result-pdf";

  // Payment submission endpoints - Updated to match API documentation
  static String submitSinglePayment = "${databaseUrl}parent/fees/pay-bill";
  static String submitBulkPayment = "${databaseUrl}parent/fees/pay-bill-bulk";
  static String submitInstallmentPayment =
      "${databaseUrl}parent/fees/pay-installment";
  static String verifyPaymentStatus =
      "${databaseUrl}parent/fees/payment-status";

  // Xendit payment gateway endpoints (DEMO - will be implemented in backend)
  static String createXenditInvoice = "${databaseUrl}parent/fees/xendit/create";
  static String getXenditStatus = "${databaseUrl}parent/fees/xendit/status";

  // Fitur tambahan Eschool - Galang

  static String getSubjectAttendanceParent =
      "${databaseUrl}parent/subject-attendance";

  static String parentApplyLeaves = "${databaseUrl}parent/apply-leaves";

  static String parentGetLeaves = "${databaseUrl}parent/child-leaves";

  // Contact/Support endpoints
  static String submitContact = "${databaseUrl}contact/submit";
  static String getContacts = "${databaseUrl}contacts";
  static String getContactDetails = "${databaseUrl}contacts";
  static String getContactStats = "${databaseUrl}contacts/stats";

  // Extracurricular endpoints
  static String getExtracurriculars =
      "${databaseUrl}student/extracurricular/show";
  static String getMyExtracurriculars = "${databaseUrl}student/my-eskul";
  static String joinExtracurricular = "${databaseUrl}student/join-eskul";

  // static Future<Map<String, dynamic>> post({
  //   required Map<String, dynamic> body,
  //   required String url,
  //   required bool useAuthToken,
  //   Map<String, dynamic>? queryParameters,
  //   CancelToken? cancelToken,
  //   Function(int, int)? onSendProgress,
  //   Function(int, int)? onReceiveProgress,
  // }) async {
  //   try {
  //     final Dio dio = Dio();
  //     final FormData formData =
  //         FormData.fromMap(body, ListFormat.multiCompatible);
  //     if (kDebugMode) {
  //       print("API Called POST: $url with $body");
  //       print("Body Params: $body");
  //     }
  //     final response = await dio.post(
  //       url,
  //       data: formData,
  //       queryParameters: queryParameters,
  //       cancelToken: cancelToken,
  //       onReceiveProgress: onReceiveProgress,
  //       onSendProgress: onSendProgress,
  //       options: useAuthToken ? Options(headers: headers()) : null,
  //     );

  //     if (kDebugMode) {
  //       print("Response: ${response.data}");
  //     }
  //     if (response.data['error']) {
  //       throw ApiException(response.data['code'].toString());
  //     }
  //     return Map.from(response.data);
  //   } on DioException catch (e) {
  //     if (kDebugMode) {
  //       print(e.response?.data);
  //     }
  //     if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
  //       throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
  //     }
  //     throw ApiException(
  //       e.error is SocketException
  //           ? ErrorMessageKeysAndCode.noInternetCode
  //           : ErrorMessageKeysAndCode.defaultErrorMessageCode,
  //     );
  //   } on ApiException catch (e) {
  //     throw ApiException(e.errorMessage);
  //   } catch (e) {
  //     throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
  //   }
  // }

  // Update kode Eschool 1.3.3 ke 1.4.1 post - Galang
  static Future<Map<String, dynamic>> post({
    required dynamic
        body, // Ubah tipe dari Map<String, dynamic> menjadi dynamic
    required String url,
    required bool useAuthToken,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final Dio dio = Dio();
      dynamic dataToSend;

      // Cek apakah body sudah berupa FormData
      if (body is FormData) {
        dataToSend = body;
      } else if (body is Map<String, dynamic>) {
        dataToSend = FormData.fromMap(body, ListFormat.multiCompatible);
      } else {
        throw ApiException("Invalid body type");
      }

      if (kDebugMode) {
        print("API Called POST: $url with $body");
        print("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: dataToSend,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        options: useAuthToken ? Options(headers: headers()) : null,
      );

      if (kDebugMode) {
        print("Response: ${response.data}");
      }
      if (response.data['error'] == true) {
        throw ApiException(response.data['code'].toString());
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Url is $url");
        print(e.response?.data);
        print(e.response?.statusCode);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }

      if (e.response?.statusCode == 302) {
        print("Redirected: ${e.response?.data}");
        throw ApiException("Redirected: ${e.response?.data}");
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> get({
    required String url,
    required bool useAuthToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Dio dio = Dio();

      if (kDebugMode) {
        print(url);
        print(queryParameters);
      }

      final response = await dio.get(
        url,
        queryParameters: queryParameters,
        options: useAuthToken ? Options(headers: headers()) : null,
      );

      if (response.data is Map &&
          response.data['error'] != null &&
          response.data['error']) {
        if (kDebugMode) {
          print("Url $url");
          print(response.data);
        }
        throw ApiException(
            response.data['message'] ?? response.data['code'].toString());
      }

      if (response.data is Map) {
        return Map.from(response.data);
      }
      return {"data": response.data};
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Url is $url");
        print(e.response?.data);
        print(e.response?.statusCode);
      }

      if (e.response?.statusCode == 429) {
        throw ApiException(ErrorMessageKeysAndCode.tooManyAttemps);
      }

      if (e.response?.statusCode == 401) {
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage.toString());
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print("DEBUG ERRORRR");
        print(e.toString());
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

// import 'dart:io';  // pastikan ada ini di atas file untuk HttpHeaders

  static Future<void> download({
    required String url,
    required CancelToken cancelToken,
    required String savePath,
    required Function(double)
        updateDownloadedPercentage, // kirim 0..100 atau -1
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          followRedirects: true,
          // biar Authorization & header lain kepakai
          headers: {
            ...headers(),
            // nonaktifkan kompresi supaya Content-Length lebih sering muncul
            HttpHeaders.acceptEncodingHeader: 'identity',
          },
          // boleh baca body saat 4xx (supaya error mapping tetap dapat data)
          receiveDataWhenStatusError: true,
          validateStatus: (s) => (s ?? 0) < 500,
        ),
      );

      await dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            // aman: 0..100
            updateDownloadedPercentage((count / total) * 100.0);
          } else {
            // server tidak kirim total -> indeterminate
            updateDownloadedPercentage(-1);
          }
        },
      );
    } on DioException catch (e) {
      // mapping error-mu yang lama tetap dipertahankan
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }
      if (e.response?.statusCode == 404) {
        throw ApiException(ErrorMessageKeysAndCode.fileNotFoundErrorCode);
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

// Simple helper untuk set mimeType berdasarkan ekstensi
  static String _getMimeType(String fileName) {
    print("File name: $fileName");
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  static String sanitizeFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      // ambil nama tanpa ekstensi terakhir
      final name = parts.sublist(0, parts.length - 1).join('.');
      final ext = parts.last.toLowerCase();
      return '$name.$ext'; // pastikan hanya satu ekstensi
    }
    return fileName;
  }
  // static Future<bool> checkAndRequestStoragePermission() async {
  //   if (Platform.isAndroid) {
  //     var status = await Permission.storage.status;
  //     if (!status.isGranted) {
  //       status = await Permission.storage.request();
  //       if (!status.isGranted) {
  //         return false;
  //       }
  //     }
  //   }
  //   return true;
  // }

  static Future<Map<String, dynamic>> delete({
    required String url,
    required bool useAuthToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Dio dio = Dio();

      if (kDebugMode) {
        print("API Called DELETE: $url");
        print("Query Params: $queryParameters");
      }

      final response = await dio.delete(
        url,
        queryParameters: queryParameters,
        options: useAuthToken ? Options(headers: headers()) : null,
      );

      if (response.data['error'] != null && response.data['error']) {
        if (kDebugMode) {
          print("Url $url");
          print(response.data);
        }
        throw ApiException(
            response.data['message'] ?? response.data['code'].toString());
      }

      return Map.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Url is $url");
        print(e.response?.data);
        print(e.response?.statusCode);
      }

      if (e.response?.statusCode == 401) {
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage.toString());
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  // Fitur baru Eschool versi 1.3.3 - Galang
}
