import 'package:flutter_test/flutter_test.dart';
import 'package:quick_invoice_maker/features/invoice/domain/invoice_draft.dart';
import 'package:quick_invoice_maker/features/invoice/domain/invoice_line.dart';

void main() {
  test('invoice subtotal and total are calculated correctly', () {
    final invoice = InvoiceDraft(
      businessName: 'Demo',
      businessAddress: '',
      customerName: 'Customer',
      customerAddress: '',
      invoiceNumber: 'INV-001',
      invoiceDate: DateTime(2026, 1, 1),
      lines: const [
        InvoiceLine(description: 'A', quantity: 2, unitPrice: 100),
        InvoiceLine(description: 'B', quantity: 3, unitPrice: 50),
      ],
    );
    expect(invoice.subtotal, 350);
    expect(invoice.total, 350);
  });
}
