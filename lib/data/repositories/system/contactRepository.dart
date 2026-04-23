import 'dart:convert';
import 'package:eschool/data/models/system/contact.dart';
import 'package:eschool/data/models/system/contactResponse.dart';
import 'package:eschool/data/models/system/contactStats.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class ContactRepository {
  // Submit new contact (Authenticated - linked to user for tracking)
  Future<Contact> submitContact({
    required String name,
    required String email,
    required String subject,
    required String message,
    required String type, // "inquiry" or "report"
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'type': type,
      };

      if (kDebugMode) {
        print("Submitting contact to support with data: $body");
      }

      final result = await Api.post(
        url: Api.submitContact,
        body: body,
        useAuthToken: true, // Authenticated - so users can see their history
      );

      if (kDebugMode) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(result);
        final lines = jsonStr.split('\n');
        for (var line in lines) {
          print(line);
        }
      }

      return Contact.fromJson(result['data']);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // Get contacts list (Authenticated)
  Future<ContactResponse> getContacts({
    int? page,
    String? type, // "inquiry" or "report"
    String? status, // "new", "replied", "closed"
    String? search,
    int? perPage,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (page != null && page > 0) 'page': page,
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        if (perPage != null && perPage > 0) 'per_page': perPage,
      };

      if (kDebugMode) {
        print("Getting contacts with parameters: $queryParameters");
      }

      final result = await Api.get(
        url: Api.getContacts,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(result);
        final lines = jsonStr.split('\n');
        for (var line in lines) {
          print(line);
        }
      }

      return ContactResponse.fromJson(result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // Get specific contact details (Authenticated)
  Future<Contact> getContactDetails({required int contactId}) async {
    try {
      final url = "${Api.getContactDetails}/$contactId";

      if (kDebugMode) {
        print("Getting contact details for ID: $contactId");
      }

      final result = await Api.get(
        url: url,
        useAuthToken: true,
      );

      if (kDebugMode) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(result);
        final lines = jsonStr.split('\n');
        for (var line in lines) {
          print(line);
        }
      }

      return Contact.fromJson(result['data']);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // Get contact statistics (Authenticated - Admin only)
  Future<ContactStats> getContactStats() async {
    try {
      if (kDebugMode) {
        print("Getting contact statistics");
      }

      final result = await Api.get(
        url: Api.getContactStats,
        useAuthToken: true,
      );

      if (kDebugMode) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(result);
        final lines = jsonStr.split('\n');
        for (var line in lines) {
          print(line);
        }
      }

      return ContactStats.fromJson(result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
