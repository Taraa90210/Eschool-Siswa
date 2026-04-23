import 'package:dio/dio.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/system/api.dart'; // For ApiException
import 'package:flutter/foundation.dart';
import 'dart:io';

/// API utility specifically for JSON requests
/// This is a separate utility from api.dart to avoid modifying existing code
/// Use this for APIs that require Content-Type: application/json
///
/// Note: ErrorMessageMapper is now in errorMessageKeysAndCodes.dart
class ApiJson {
  // Private constructor to prevent instantiation
  ApiJson._();

  // Singleton Dio instance with timeout configuration
  // Bug-safety: Reuse instance for better performance
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 15), // Connection timeout
      receiveTimeout: Duration(seconds: 15), // Response timeout
      sendTimeout: Duration(seconds: 15), // Send timeout
    ),
  );

  /// Get headers with Authorization and school_code
  /// Same as Api.headers() but explicitly includes Content-Type: application/json
  static Map<String, dynamic> headers() {
    final String jwtToken = AuthRepository().getJwtToken();
    final schoolCode = AuthRepository().schoolCode;

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════');
      print('🔍 [DEBUG] ApiJson Headers Validation');
      print('═══════════════════════════════════════════════════════');

      // Token validation
      print('🔑 FULL TOKEN: $jwtToken');
      print('📏 TOKEN LENGTH: ${jwtToken.length}');
      print('✅ TOKEN EXISTS: ${jwtToken.isNotEmpty}');
      print(
          '✅ TOKEN FORMAT: ${jwtToken.contains('|') ? 'Valid (has pipe)' : 'Invalid (no pipe)'}');

      // School code validation
      print('🏫 SCHOOL CODE: $schoolCode');
      print('📏 SCHOOL CODE LENGTH: ${schoolCode.length}');
      print('✅ SCHOOL CODE EXISTS: ${schoolCode.isNotEmpty}');

      // Header preview
      print('───────────────────────────────────────────────────────');
      print('📤 HEADERS BEING SENT:');
      print('   Authorization: Bearer $jwtToken');
      print('   school-code: $schoolCode');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('═══════════════════════════════════════════════════════');
    }

    return {
      "Authorization": "Bearer $jwtToken",
      "school-code":
          schoolCode, // Use dash to avoid Nginx stripping underscore headers
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  /// POST request with JSON body (not FormData)
  /// Use this for payment confirmation and other APIs requiring JSON
  static Future<Map<String, dynamic>> post({
    required Map<String, dynamic> body,
    required String url,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      // Performance: Use singleton Dio instance
      if (kDebugMode) {
        print('📤 ApiJson POST: $url');
        print('Body: $body');
        print('Headers: ${headers()}');
      }

      final response = await _dio.post(
        url,
        data: body, // Send as JSON, not FormData
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(headers: headers()),
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('Response Data: ${response.data}');
      }

      // Check if response has error field
      if (response.data is Map && response.data['error'] == true) {
        throw ApiException(response.data['message'] ??
            response.data['code']?.toString() ??
            'Unknown error');
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ ApiJson Error:');
        print('URL: $url');
        print('Status Code: ${e.response?.statusCode}');
        print('Response: ${e.response?.data}');
      }

      // Handle specific status codes
      if (e.response?.statusCode == 401) {
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════');
          print('❌ [ERROR 401] UNAUTHENTICATED');
          print('═══════════════════════════════════════════════════════');
          print('📍 URL: $url');
          print('📤 Request Headers:');
          print('   ${headers()}');
          print('📥 Response: ${e.response?.data}');
          print('───────────────────────────────────────────────────────');
          print('💡 POSSIBLE CAUSES:');
          print('   1. Token is missing or empty');
          print('   2. Token is invalid or expired');
          print('   3. Token format is wrong (missing "Bearer " prefix)');
          print('   4. Backend auth:sanctum middleware not deployed');
          print('───────────────────────────────────────────────────────');
          print('🔧 TROUBLESHOOTING STEPS:');
          print('   1. Check if token exists in log above');
          print('   2. Try logging out and logging in again');
          print('   3. Test with cURL using token from log');
          print('   4. Contact backend team if issue persists');
          print('═══════════════════════════════════════════════════════');
        }
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 404) {
        throw ApiException('Resource not found');
      }
      if (e.response?.statusCode == 422) {
        throw ApiException(e.response?.data['message'] ?? 'Validation error');
      }
      if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }

      // Handle network errors
      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }

      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  /// GET request with proper headers
  static Future<Map<String, dynamic>> get({
    required String url,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      // Performance: Use singleton Dio instance
      if (kDebugMode) {
        print('📤 ApiJson GET: $url');
        print('Headers: ${headers()}');
      }

      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(headers: headers()),
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('Response Data: ${response.data}');
      }

      if (response.data is Map && response.data['error'] == true) {
        throw ApiException(response.data['message'] ??
            response.data['code']?.toString() ??
            'Unknown error');
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ ApiJson Error:');
        print('URL: $url');
        print('Status Code: ${e.response?.statusCode}');
        print('Response: ${e.response?.data}');
      }

      if (e.response?.statusCode == 401) {
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 404) {
        throw ApiException('Resource not found');
      }
      if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }

      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }

      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }
}
