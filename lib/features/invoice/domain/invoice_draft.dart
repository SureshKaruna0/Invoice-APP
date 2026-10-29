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
    this.terms = '1. Goods once sold will not be accepted back or exchanged.\n2. Payment is due within 15 days of invoice date.',
  });

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

  // Base subtotal (sum of qty * unitPrice)
  double get subtotal => lines.fold(0.0, (sum, line) => sum + line.baseAmount);

  // Total discounts applied across all lines
  double get totalDiscount => lines.fold(0.0, (sum, line) => sum + line.discount);

  // Net taxable amount before tax
  double get taxableAmount => lines.fold(0.0, (sum, line) => sum + line.discountedAmount);

  // Total GST / tax amount
  double get totalTax => lines.fold(0.0, (sum, line) => sum + line.taxAmount);

  // Grand total
  double get total => lines.fold(0.0, (sum, line) => sum + line.total);

  InvoiceDraft copyWith({
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
  }) {
    return InvoiceDraft(
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
    );
  }
}
