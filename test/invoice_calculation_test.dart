import 'package:flutter_test/flutter_test.dart';
import 'package:quick_invoice_maker/features/invoice/application/invoice_form_controller.dart';
import 'package:quick_invoice_maker/features/invoice/application/number_to_words.dart';
import 'package:quick_invoice_maker/features/invoice/domain/invoice_draft.dart';
import 'package:quick_invoice_maker/features/invoice/domain/invoice_line.dart';

void main() {
  group('Invoice Calculations', () {
    test('invoice subtotal and total are calculated correctly with basic lines',
        () {
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
      expect(invoice.subtotal, 350.0);
      expect(invoice.total, 350.0);
    });

    test('invoice calculates GST tax, discount, and taxable amount correctly',
        () {
      final invoice = InvoiceDraft(
        businessName: 'EasyBill Mart',
        businessAddress: 'Bangalore',
        customerName: 'Kaveri Traders',
        customerAddress: 'MG Road',
        invoiceNumber: 'INV-2026-001',
        invoiceDate: DateTime(2026, 1, 1),
        lines: const [
          InvoiceLine(
            description: 'Cotton Shirts',
            quantity: 10,
            unitPrice: 200, // 2000
            discount: 100, // discounted = 1900
            taxRate: 5, // tax = 95 -> total = 1995
          ),
          InvoiceLine(
            description: 'Formal Pants',
            quantity: 2,
            unitPrice: 500, // 1000
            discount: 0, // discounted = 1000
            taxRate: 18, // tax = 180 -> total = 1180
          ),
        ],
      );

      expect(invoice.subtotal, 3000.0);
      expect(invoice.totalDiscount, 100.0);
      expect(invoice.taxableAmount, 2900.0);
      expect(invoice.totalTax, 275.0);
      expect(invoice.total, 3175.0);
    });
  });

  group('Indian Number to Words', () {
    test('converts basic amounts correctly', () {
      expect(numberToIndianWords(0), 'Rupees Zero Only');
      expect(numberToIndianWords(100), 'Rupees One Hundred Only');
      expect(numberToIndianWords(1250),
          'Rupees One Thousand Two Hundred and Fifty Only');
      expect(numberToIndianWords(105000), 'Rupees One Lakh Five Thousand Only');
    });
  });

  group('InvoiceFormController', () {
    test('controller initializes with default state and modifies lines', () {
      final controller = InvoiceFormController();
      expect(controller.state.lines.isNotEmpty, isTrue);

      final initialCount = controller.state.lines.length;
      controller.addLine(const InvoiceLine(
          description: 'New Item', quantity: 2, unitPrice: 50));
      expect(controller.state.lines.length, initialCount + 1);

      controller.removeLine(controller.state.lines.length - 1);
      expect(controller.state.lines.length, initialCount);
    });

    test('controller saves invoice to history and reloads draft', () {
      final controller = InvoiceFormController();
      controller.saveCurrentInvoiceToHistory();
      expect(controller.state.savedInvoices.isNotEmpty, isTrue);

      final draft = controller.state.toDraft();
      expect(draft.invoiceNumber, controller.state.invoiceNumber);
    });
  });
}
