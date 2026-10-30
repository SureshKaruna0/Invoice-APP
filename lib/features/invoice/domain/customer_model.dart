class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.gstin = '',
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gstin;

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstin,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
      };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        gstin: json['gstin'] as String? ?? '',
      );
}

