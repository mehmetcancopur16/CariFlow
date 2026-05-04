class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.currentBalance,
    this.notes,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double currentBalance;
  final String? notes;
  final bool isActive;

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'currentBalance': currentBalance,
      'notes': notes,
      'isActive': isActive,
    };
  }
}
