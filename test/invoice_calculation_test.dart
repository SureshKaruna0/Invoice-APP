import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/features/invoice/application/invoice_form_controller.dart';
import 'package:quick_invoice_maker/features/invoice/application/number_to_words.dart';
import 'package:quick_invoice_maker/features/invoice/application/receipt_ocr_service.dart';
import 'package:quick_invoice_maker/features/invoice/domain/invoice_draft.dart';
import 'package:quick_invoice_maker/features/invoice/domain/invoice_line.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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

  group('Indian Number to Words & Indian Rupee Formatting (Phase 7)', () {
    test('converts basic amounts correctly', () {
      expect(numberToIndianWords(0), 'Rupees Zero Only');
      expect(numberToIndianWords(100), 'Rupees One Hundred Only');
      expect(numberToIndianWords(1250),
          'Rupees One Thousand Two Hundred and Fifty Only');
      expect(numberToIndianWords(105000), 'Rupees One Lakh Five Thousand Only');
    });

    test('Indian Rupee symbol (₹) and Indian number grouping (lakhs & crores)', () {
      final inr = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
      expect(inr.format(1000), '₹1,000.00');
      expect(inr.format(12500), '₹12,500.00');
      expect(inr.format(125000), '₹1,25,000.00');
      expect(inr.format(1000000), '₹10,00,000.00'); // 10 Lakhs (Indian numbering standard: 3 digits then pairs of 2)
      expect(inr.currencySymbol, '₹');
    });
  });

  group('Receipt OCR Parser (Phase 3)', () {
    test('accurately extracts vendor, invoice number, and amounts from receipt text', () {
      const sampleOcr = '''
      ABC RESTAURANT & CAFE
      MG Road, Bangalore
      GSTIN: 29ABCDE1234F1Z5
      Invoice No: INV-9872
      Date: 28/10/2026
      Veg Burger 2 120.00
      Cold Coffee 1 80.00
      Subtotal: 200.00
      CGST 2.5%: 5.00
      SGST 2.5%: 5.00
      Grand Total: 210.00
      Paid via UPI
      ''';

      final result = ReceiptOcrService.parseReceiptText(sampleOcr, '/tmp/receipt.jpg');
      expect(result.vendorName.value.contains('ABC RESTAURANT'), isTrue);
      expect(result.invoiceNumber.value, 'INV-9872');
      expect(result.totalAmount.value, 210.0);
      expect(result.gstin.value, '29ABCDE1234F1Z5');
      expect(result.paymentMode.value, 'UPI');
      expect(result.lines.isNotEmpty, isTrue);
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

    test('controller saves invoice to history and handles watermark & receipt', () {
      final controller = InvoiceFormController();
      controller.setWatermarkSettings(type: 'text', text: 'PAID', opacity: 0.15, placement: 'diagonal');
      controller.setReceiptImage('/tmp/test_receipt.jpg');
      controller.setIncludeReceiptInPdf(true);

      expect(controller.state.watermarkType, 'text');
      expect(controller.state.watermarkText, 'PAID');
      expect(controller.state.watermarkOpacity, 0.15);
      expect(controller.state.receiptImagePath, '/tmp/test_receipt.jpg');
      expect(controller.state.includeReceiptInPdf, isTrue);

      controller.saveCurrentInvoiceToHistory();
      expect(controller.state.savedInvoices.isNotEmpty, isTrue);

      final draft = controller.state.toDraft();
      expect(draft.watermarkText, 'PAID');
      expect(draft.receiptImagePath, '/tmp/test_receipt.jpg');
    });
  });
}
