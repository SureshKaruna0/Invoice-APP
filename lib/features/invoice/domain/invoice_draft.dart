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
    this.notes = '',
  });

  final String businessName;
  final String businessAddress;
  final String customerName;
  final String customerAddress;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final List<InvoiceLine> lines;
  final String notes;

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);
  double get total => subtotal;
}
