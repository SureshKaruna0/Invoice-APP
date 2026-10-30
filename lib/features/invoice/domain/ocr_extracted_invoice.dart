import 'invoice_line.dart';

enum FieldConfidence {
  high,
  medium,
  low,
}

class ExtractedField<T> {
  const ExtractedField({
    required this.value,
    this.confidence = FieldConfidence.medium,
    this.rawText = '',
  });

  final T value;
  final FieldConfidence confidence;
  final String rawText;

  ExtractedField<T> copyWith({
    T? value,
    FieldConfidence? confidence,
    String? rawText,
  }) {
    return ExtractedField<T>(
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
    );
  }
}

class OcrExtractedInvoice {
  OcrExtractedInvoice({
    required this.imagePath,
    required this.rawOcrText,
    required this.vendorName,
    required this.invoiceNumber,
    required this.date,
    required this.gstin,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.lines,
  });

  final String imagePath;
  final String rawOcrText;
  final ExtractedField<String> vendorName;
  final ExtractedField<String> invoiceNumber;
  final ExtractedField<DateTime?> date;
  final ExtractedField<String> gstin;
  final ExtractedField<double> subtotal;
  final ExtractedField<double> taxAmount;
  final ExtractedField<double> totalAmount;
  final ExtractedField<String> paymentMode;
  final List<InvoiceLine> lines;

  OcrExtractedInvoice copyWith({
    String? imagePath,
    String? rawOcrText,
    ExtractedField<String>? vendorName,
    ExtractedField<String>? invoiceNumber,
    ExtractedField<DateTime?>? date,
    ExtractedField<String>? gstin,
    ExtractedField<double>? subtotal,
    ExtractedField<double>? taxAmount,
    ExtractedField<double>? totalAmount,
    ExtractedField<String>? paymentMode,
    List<InvoiceLine>? lines,
  }) {
    return OcrExtractedInvoice(
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      vendorName: vendorName ?? this.vendorName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      gstin: gstin ?? this.gstin,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      lines: lines ?? this.lines,
    );
  }
}

