import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class LeaveDetail {
  final int id;
  final int? leaveId;
  final String date;
  final String type;
  final int schoolId;
  final String? fileName;
  final String? fileUrl;
  final String? fileExtension;
  final String? typeDetail;
  final bool isFile;

  LeaveDetail({
    required this.id,
    required this.leaveId,
    required this.date,
    required this.type,
    required this.schoolId,
    this.fileName,
    this.fileUrl,
    this.fileExtension,
    this.typeDetail,
    this.isFile = false,
  });

  factory LeaveDetail.fromJson(Map<String, dynamic> json,
      {bool isFile = false}) {
    print("Parsing LeaveDetail ID: ${json['id']}");
    print("Parsing LeaveDetail leaveId: ${json['leave_id']}");
    print("Parsing LeaveDetail date: ${json['date']}");
    print(json);

    return LeaveDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      leaveId: int.tryParse(json['leave_id'].toString()) ?? 0,
      date: json['date'] ?? '',
      type: json['type'] ?? '',
      schoolId: int.tryParse(json['school_id'].toString()) ?? 0,
      isFile: isFile,
      fileName: isFile ? json['file_name'] : null,
      fileUrl: isFile ? json['file_url'] : null,
      fileExtension: isFile ? json['file_extension'] : null,
      typeDetail: isFile ? json['type_detail'] : null,
    );
  }

  String get formattedDate {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing date $date: $e");
      }
      return date; // Return original date string if parsing fails
    }
  }
}

class Leave {
  final int id;
  final int userId;
  final String reason;
  final String type;
  final String fromDate;
  final String toDate;
  final int status;
  final int schoolId;
  final int leaveMasterId;
  final String rejectReason;
  final String createdAt;
  final String updatedAt;
  final List<LeaveDetail> leaveDetail;
  final List<LeaveDetail> fileDetail;

  Leave({
    required this.id,
    required this.userId,
    required this.reason,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.schoolId,
    required this.rejectReason,
    required this.leaveMasterId,
    required this.createdAt,
    required this.updatedAt,
    required this.leaveDetail,
    required this.fileDetail,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    print("Parsing Leave ID: ${json['id']}");
    print("Raw JSON for Leave: $json");
    print(json);

    final leaveDetails = (json['leave_detail'] as List?)?.map((detail) {
          print("Parsing leave detail: $detail");
          return LeaveDetail.fromJson(Map<String, dynamic>.from(detail));
        }).toList() ??
        [];

    final fileDetails = (json['file'] as List?)?.map((file) {
          print("Parsing file detail: $file");
          return LeaveDetail.fromJson(Map<String, dynamic>.from(file),
              isFile: true);
        }).toList() ??
        [];

    return Leave(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      reason: json['reason'] ?? '',
      type: json['type'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      rejectReason: json['rejection_reason'] ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
      schoolId: int.tryParse(json['school_id'].toString()) ?? 0,
      leaveMasterId: int.tryParse(json['leave_master_id'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      leaveDetail: leaveDetails,
      fileDetail: fileDetails,
    );
  }
}
