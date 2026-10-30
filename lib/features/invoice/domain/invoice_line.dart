class InvoiceLine {
  const InvoiceLine({
    this.id = '',
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.hsnCode = '',
    this.unit = 'Pcs',
    this.discount = 0.0,
    this.taxRate = 0.0,
  });

  final String id;
  final String description;
  final String hsnCode;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discount; // Flat discount on the item total or 0
  final double taxRate; // GST rate percentage: 0%, 5%, 12%, 18%, 28%

  double get baseAmount => quantity * unitPrice;
  double get discountedAmount => (baseAmount - discount).clamp(0.0, double.infinity);
  double get taxAmount => (discountedAmount * taxRate) / 100.0;
  double get total => discountedAmount + taxAmount;

  InvoiceLine copyWith({
    String? id,
    String? description,
    String? hsnCode,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? discount,
    double? taxRate,
  }) {
    return InvoiceLine(
      id: id ?? this.id,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'hsnCode': hsnCode,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
    'discount': discount,
    'taxRate': taxRate,
  };

  factory InvoiceLine.fromJson(Map<String, dynamic> map) => InvoiceLine(
    id: map['id'] as String? ?? '',
    description: map['description'] as String? ?? '',
    hsnCode: map['hsnCode'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
    unit: map['unit'] as String? ?? 'Pcs',
    unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
    taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
  );
}
