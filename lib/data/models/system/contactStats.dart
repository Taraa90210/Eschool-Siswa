class ContactStats {
  final int totalContacts;
  final int totalInquiries;
  final int totalReports;
  final int newContacts;
  final int repliedContacts;
  final int closedContacts;
  final int recentContacts;

  ContactStats({
    required this.totalContacts,
    required this.totalInquiries,
    required this.totalReports,
    required this.newContacts,
    required this.repliedContacts,
    required this.closedContacts,
    required this.recentContacts,
  });

  factory ContactStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    
    return ContactStats(
      totalContacts: data['total_contacts'] ?? 0,
      totalInquiries: data['total_inquiries'] ?? 0,
      totalReports: data['total_reports'] ?? 0,
      newContacts: data['new_contacts'] ?? 0,
      repliedContacts: data['replied_contacts'] ?? 0,
      closedContacts: data['closed_contacts'] ?? 0,
      recentContacts: data['recent_contacts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_contacts': totalContacts,
      'total_inquiries': totalInquiries,
      'total_reports': totalReports,
      'new_contacts': newContacts,
      'replied_contacts': repliedContacts,
      'closed_contacts': closedContacts,
      'recent_contacts': recentContacts,
    };
  }

  // Helper methods
  double get replyRate {
    if (totalContacts == 0) return 0.0;
    return (repliedContacts / totalContacts) * 100;
  }

  double get closeRate {
    if (totalContacts == 0) return 0.0;
    return (closedContacts / totalContacts) * 100;
  }
}
