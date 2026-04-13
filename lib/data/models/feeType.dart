/// FeeType Model
///
/// Maps to the 'fees_types' table in the database.
/// Used for dynamic fee configuration from the backend.
class FeeType {
  final int id;
  final String name;
  final String code; // e.g., 'VA', 'QRIS', 'EW'
  final double flatFee;
  final double percentFee;
  final bool isActive;

  FeeType({
    required this.id,
    required this.name,
    required this.code,
    this.flatFee = 0.0,
    this.percentFee = 0.0,
    this.isActive = true,
  });

  factory FeeType.fromJson(Map<String, dynamic> json) {
    return FeeType(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      flatFee: double.tryParse(json['flat_fee'].toString()) ?? 0.0,
      percentFee: double.tryParse(json['percent_fee'].toString()) ?? 0.0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  double calculateFee(double amount) {
    return flatFee + (amount * (percentFee / 100));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'flat_fee': flatFee,
      'percent_fee': percentFee,
      'is_active': isActive ? 1 : 0,
    };
  }
}
