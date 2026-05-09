class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.companyName = '',
    this.taxOffice = '',
    this.taxId = '',
    this.companyPhone = '',
    this.companyAddress = '',
  });

  final String id;
  final String email;
  final String companyName;
  final String taxOffice;
  final String taxId;
  final String companyPhone;
  final String companyAddress;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      taxOffice: (json['taxOffice'] ?? '').toString(),
      taxId: (json['taxId'] ?? '').toString(),
      companyPhone: (json['companyPhone'] ?? '').toString(),
      companyAddress: (json['companyAddress'] ?? '').toString(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? companyName,
    String? taxOffice,
    String? taxId,
    String? companyPhone,
    String? companyAddress,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      taxOffice: taxOffice ?? this.taxOffice,
      taxId: taxId ?? this.taxId,
      companyPhone: companyPhone ?? this.companyPhone,
      companyAddress: companyAddress ?? this.companyAddress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'companyName': companyName,
      'taxOffice': taxOffice,
      'taxId': taxId,
      'companyPhone': companyPhone,
      'companyAddress': companyAddress,
    };
  }
}
