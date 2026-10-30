import 'invoice_line.dart';

class InvoiceDraft {
  const InvoiceDraft({
    required this.businessName,
    required this.businessAddress,
    required this.customerName,
    required this.customerAddress,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.lines,
    this.businessLogoPath,
    this.businessPhone = '',
    this.businessEmail = '',
    this.businessGstin = '',
    this.customerPhone = '',
    this.customerGstin = '',
    this.dueDate,
    this.paymentStatus = 'Pending',
    this.paymentMode = 'UPI / Cash',
    this.bankName = '',
    this.bankAccount = '',
    this.bankIfsc = '',
    this.upiId = '',
    this.notes = '',
    this.terms = '',
    this.receiptImagePath,
    this.includeReceiptInPdf = true,
    this.watermarkType = 'none', // 'none' | 'text' | 'logo'
    this.watermarkText = 'PAID',
    this.watermarkOpacity = 0.12,
    this.watermarkPlacement = 'diagonal', // 'diagonal' | 'center'
  });

  final String? businessLogoPath;
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String businessGstin;

  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String customerGstin;

  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String paymentStatus;
  final String paymentMode;

  final String bankName;
  final String bankAccount;
  final String bankIfsc;
  final String upiId;

  final List<InvoiceLine> lines;
  final String notes;
  final String terms;

  // Receipt Attachment
  final String? receiptImagePath;
  final bool includeReceiptInPdf;

  // Custom PDF Watermark
  final String watermarkType;
  final String watermarkText;
  final double watermarkOpacity;
  final String watermarkPlacement;

  // Base subtotal (sum of qty * unitPrice)
  double get subtotal => lines.fold(0.0, (sum, line) => sum + line.baseAmount);

  // Total discounts applied across all lines
  double get totalDiscount =>
      lines.fold(0.0, (sum, line) => sum + line.discount);

  // Net taxable amount before tax
  double get taxableAmount =>
      lines.fold(0.0, (sum, line) => sum + line.discountedAmount);

  // Total GST / tax amount
  double get totalTax => lines.fold(0.0, (sum, line) => sum + line.taxAmount);

  // Grand total
  double get total => lines.fold(0.0, (sum, line) => sum + line.total);

  InvoiceDraft copyWith({
    String? businessLogoPath,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? businessGstin,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    String? customerGstin,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? paymentStatus,
    String? paymentMode,
    String? bankName,
    String? bankAccount,
    String? bankIfsc,
    String? upiId,
    List<InvoiceLine>? lines,
    String? notes,
    String? terms,
    String? receiptImagePath,
    bool? includeReceiptInPdf,
    String? watermarkType,
    String? watermarkText,
    double? watermarkOpacity,
    String? watermarkPlacement,
  }) {
    return InvoiceDraft(
      businessLogoPath: businessLogoPath ?? this.businessLogoPath,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      businessGstin: businessGstin ?? this.businessGstin,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      customerGstin: customerGstin ?? this.customerGstin,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      upiId: upiId ?? this.upiId,
      lines: lines ?? this.lines,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      includeReceiptInPdf: includeReceiptInPdf ?? this.includeReceiptInPdf,
      watermarkType: watermarkType ?? this.watermarkType,
      watermarkText: watermarkText ?? this.watermarkText,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkPlacement: watermarkPlacement ?? this.watermarkPlacement,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessLogoPath': businessLogoPath,
        'businessName': businessName,
        'businessAddress': businessAddress,
        'businessPhone': businessPhone,
        'businessEmail': businessEmail,
        'businessGstin': businessGstin,
        'customerName': customerName,
        'customerAddress': customerAddress,
        'customerPhone': customerPhone,
        'customerGstin': customerGstin,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'paymentStatus': paymentStatus,
        'paymentMode': paymentMode,
        'bankName': bankName,
        'bankAccount': bankAccount,
        'bankIfsc': bankIfsc,
        'upiId': upiId,
        'lines': lines.map((l) => l.toJson()).toList(),
        'notes': notes,
        'terms': terms,
        'receiptImagePath': receiptImagePath,
        'includeReceiptInPdf': includeReceiptInPdf,
        'watermarkType': watermarkType,
        'watermarkText': watermarkText,
        'watermarkOpacity': watermarkOpacity,
        'watermarkPlacement': watermarkPlacement,
      };

  factory InvoiceDraft.fromJson(Map<String, dynamic> map) => InvoiceDraft(
        businessLogoPath: map['businessLogoPath'] as String?,
        businessName: map['businessName'] as String? ?? '',
        businessAddress: map['businessAddress'] as String? ?? '',
        businessPhone: map['businessPhone'] as String? ?? '',
        businessEmail: map['businessEmail'] as String? ?? '',
        businessGstin: map['businessGstin'] as String? ?? '',
        customerName: map['customerName'] as String? ?? '',
        customerAddress: map['customerAddress'] as String? ?? '',
        customerPhone: map['customerPhone'] as String? ?? '',
        customerGstin: map['customerGstin'] as String? ?? '',
        invoiceNumber: map['invoiceNumber'] as String? ?? 'INV-001',
        invoiceDate: map['invoiceDate'] != null
            ? DateTime.tryParse(map['invoiceDate'] as String) ?? DateTime.now()
            : DateTime.now(),
        dueDate: map['dueDate'] != null
            ? DateTime.tryParse(map['dueDate'] as String)
            : null,
        paymentStatus: map['paymentStatus'] as String? ?? 'Pending',
        paymentMode: map['paymentMode'] as String? ?? 'UPI / Cash',
        bankName: map['bankName'] as String? ?? '',
        bankAccount: map['bankAccount'] as String? ?? '',
        bankIfsc: map['bankIfsc'] as String? ?? '',
        upiId: map['upiId'] as String? ?? '',
        lines: (map['lines'] as List<dynamic>?)
                ?.map((l) => InvoiceLine.fromJson(l as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: map['notes'] as String? ?? '',
        terms: map['terms'] as String? ?? '',
        receiptImagePath: map['receiptImagePath'] as String?,
        includeReceiptInPdf: map['includeReceiptInPdf'] as bool? ?? true,
        watermarkType: map['watermarkType'] as String? ?? 'none',
        watermarkText: map['watermarkText'] as String? ?? 'PAID',
        watermarkOpacity: (map['watermarkOpacity'] as num?)?.toDouble() ?? 0.12,
        watermarkPlacement: map['watermarkPlacement'] as String? ?? 'diagonal',
      );
}
