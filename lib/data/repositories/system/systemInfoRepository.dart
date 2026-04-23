import 'dart:convert';

import 'package:eschool/data/models/system/holiday.dart';
import 'package:eschool/utils/system/api.dart';

class SystemRepository {
  Future<dynamic> fetchSettings({required String type}) async {
    try {
      final result = await Api.get(
        queryParameters: {"type": type},
        url: Api.settings,
        useAuthToken: false,
      );

      // Extract the string value if it's wrapped in a Map with a 'value' key
      if (result['data'] is Map &&
          (result['data'] as Map).containsKey('value')) {
        return result['data']['value'].toString();
      }

      return result['data'];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, String>> getSysInfo() async {
    try {
      final result =
          await Api.get(url: Api.getSystemInformation, useAuthToken: true);

      if (result['data'] is List) {
        return {for (var item in result['data']) item['key']: item['value']};
      } else {
        throw ApiException("Invalid data format");
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> fetchHolidays({int? childId}) async {
    try {
      final result = await Api.get(
          queryParameters: {"child_id": childId},
          url: Api.holidays,
          useAuthToken: true);

      // Pretty print the JSON response for debugging
      final jsonStr = const JsonEncoder.withIndent('  ').convert(result);
      final lines = jsonStr.split('\n');
      for (var line in lines) {
        print(line);
      }

      return (result['data'] as List).map((e) => Holiday.fromJson(e)).toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
