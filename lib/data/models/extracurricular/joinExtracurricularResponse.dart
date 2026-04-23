class JoinExtracurricularResponse {
  final int? id;
  final int? estrakulikulerId;
  final int? studentId;
  final int? status;
  final String? createdAt;
  final String? updatedAt;

  JoinExtracurricularResponse({
    this.id,
    this.estrakulikulerId,
    this.studentId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory JoinExtracurricularResponse.fromJson(Map<String, dynamic> json) {
    return JoinExtracurricularResponse(
      id: json['id'] as int?,
      estrakulikulerId: json['estrakulikuler_id'] as int?,
      studentId: json['student_id'] as int?,
      status: json['status'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estrakulikuler_id': estrakulikulerId,
      'student_id': studentId,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Status helper methods
  bool get isPending => status == 0;
  bool get isApproved => status == 1;
  bool get isRejected => status == 2;

  String get statusText {
    switch (status) {
      case 0:
        return 'Menunggu Persetujuan';
      case 1:
        return 'Disetujui';
      case 2:
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }
}
