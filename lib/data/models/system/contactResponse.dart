import 'contact.dart';

class ContactResponse {
  final int currentPage;
  final int lastPage;
  final int total;
  final List<Contact> contacts;

  ContactResponse({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.contacts,
  });

  factory ContactResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final contactsList = (data['data'] ?? []) as List;
    
    return ContactResponse(
      currentPage: data['current_page'] ?? 1,
      lastPage: data['last_page'] ?? 1,
      total: data['total'] ?? 0,
      contacts: contactsList
          .map((contactJson) => Contact.fromJson(Map<String, dynamic>.from(contactJson)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'total': total,
      'data': contacts.map((contact) => contact.toJson()).toList(),
    };
  }

  bool get hasMorePages => currentPage < lastPage;
}
