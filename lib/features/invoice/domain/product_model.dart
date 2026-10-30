class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.unit = 'Pcs',
    this.taxRate = 18.0,
    this.hsnCode = '',
  });

  final String id;
  final String name;
  final double unitPrice;
  final String unit;
  final double taxRate;
  final String hsnCode;

  ProductModel copyWith({
    String? id,
    String? name,
    double? unitPrice,
    String? unit,
    double? taxRate,
    String? hsnCode,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      taxRate: taxRate ?? this.taxRate,
      hsnCode: hsnCode ?? this.hsnCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unitPrice': unitPrice,
        'unit': unit,
        'taxRate': taxRate,
        'hsnCode': hsnCode,
      };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? 'Pcs',
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 18.0,
        hsnCode: json['hsnCode'] as String? ?? '',
      );
}

