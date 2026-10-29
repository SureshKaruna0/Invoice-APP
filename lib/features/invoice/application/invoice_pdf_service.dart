import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/invoice_draft.dart';
import 'number_to_words.dart';

class InvoicePdfService {
  /// Generate the pw.Document with EasyBill GST-compliant styling
  static pw.Document buildPdfDocument(InvoiceDraft invoice) {
    final doc = pw.Document();
    final money =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');
    final invoiceDateStr = dateFormat.format(invoice.invoiceDate);
    final dueDateStr = invoice.dueDate != null
        ? dateFormat.format(invoice.dueDate!)
        : 'Upon Receipt';

    final hasTax = invoice.totalTax > 0;
    final hasDiscount = invoice.totalDiscount > 0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E2538),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFD32F2F),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'ORIGINAL FOR RECIPIENT',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Business & Invoice Meta
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Seller details
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      invoice.businessName.isEmpty
                          ? 'Your Business Name'
                          : invoice.businessName,
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                    if (invoice.businessAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(invoice.businessAddress,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                    ],
                    if (invoice.businessPhone.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text('Phone: ${invoice.businessPhone}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                    ],
                    if (invoice.businessEmail.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text('Email: ${invoice.businessEmail}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                    ],
                    if (invoice.businessGstin.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: const PdfColor.fromInt(0xFF3F51B5),
                              width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          'GSTIN: ${invoice.businessGstin}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: const PdfColor.fromInt(0xFF1A237E)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 14),

              // Invoice Details Card
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfMetaRow('Invoice No:', invoice.invoiceNumber),
                      _pdfMetaRow('Invoice Date:', invoiceDateStr),
                      _pdfMetaRow('Due Date:', dueDateStr),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Status:',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color:
                                  invoice.paymentStatus.toLowerCase() == 'paid'
                                      ? PdfColors.green100
                                      : PdfColors.amber100,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(3)),
                            ),
                            child: pw.Text(
                              invoice.paymentStatus.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: invoice.paymentStatus.toLowerCase() ==
                                        'paid'
                                    ? PdfColors.green900
                                    : PdfColors.amber900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Bill To Section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF4F6F9),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILLED TO (CUSTOMER DETAILS)',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: const PdfColor.fromInt(0xFF334155)),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.customerName.isEmpty
                      ? 'Customer'
                      : invoice.customerName,
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                if (invoice.customerPhone.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text('Mobile: ${invoice.customerPhone}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700)),
                ],
                if (invoice.customerAddress.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(invoice.customerAddress,
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700)),
                ],
                if (invoice.customerGstin.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text('GSTIN: ${invoice.customerGstin}',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Itemized Table
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              'Item Description',
              'Qty',
              'Rate',
              if (hasDiscount) 'Disc',
              if (hasTax) 'GST %',
              'Amount',
            ],
            data: List.generate(invoice.lines.length, (i) {
              final line = invoice.lines[i];
              return [
                '${i + 1}',
                line.description +
                    (line.hsnCode.isNotEmpty ? '\nHSN: ${line.hsnCode}' : ''),
                '${line.quantity % 1 == 0 ? line.quantity.toInt() : line.quantity} ${line.unit}',
                money.format(line.unitPrice),
                if (hasDiscount) money.format(line.discount),
                if (hasTax)
                  '${line.taxRate % 1 == 0 ? line.taxRate.toInt() : line.taxRate}%',
                money.format(line.total),
              ];
            }),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E2538)),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              if (hasDiscount) 4: pw.Alignment.centerRight,
              if (hasTax) (hasDiscount ? 5 : 4): pw.Alignment.centerRight,
              (hasDiscount && hasTax ? 6 : (hasDiscount || hasTax ? 5 : 4)):
                  pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 12),

          // Calculation & Total Section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Amount in words & Bank Details
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice Amount In Words:',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700)),
                    pw.Text(
                      numberToIndianWords(invoice.total),
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1A237E)),
                    ),
                    pw.SizedBox(height: 10),

                    // Bank & UPI Section
                    if (invoice.bankName.isNotEmpty ||
                        invoice.upiId.isNotEmpty ||
                        invoice.bankAccount.isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('BANK & PAYMENT DETAILS',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8)),
                            if (invoice.bankName.isNotEmpty)
                              pw.Text('Bank: ${invoice.bankName}',
                                  style: const pw.TextStyle(fontSize: 8)),
                            if (invoice.bankAccount.isNotEmpty)
                              pw.Text('A/C No: ${invoice.bankAccount}',
                                  style: const pw.TextStyle(fontSize: 8)),
                            if (invoice.bankIfsc.isNotEmpty)
                              pw.Text('IFSC: ${invoice.bankIfsc}',
                                  style: const pw.TextStyle(fontSize: 8)),
                            if (invoice.upiId.isNotEmpty)
                              pw.Text('UPI ID: ${invoice.upiId}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8,
                                      color:
                                          const PdfColor.fromInt(0xFF2E7D32))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 14),

              // Summary Box
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      _pdfSummaryRow(
                          'Subtotal:', money.format(invoice.subtotal)),
                      if (hasDiscount)
                        _pdfSummaryRow('Total Discount:',
                            '-${money.format(invoice.totalDiscount)}'),
                      if (hasTax)
                        _pdfSummaryRow(
                            'Total GST:', money.format(invoice.totalTax)),
                      pw.Divider(thickness: 1, color: PdfColors.grey400),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Grand Total:',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12)),
                          pw.Text(
                            money.format(invoice.total),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 13,
                              color: const PdfColor.fromInt(0xFF1E2538),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Terms and Signature
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (invoice.notes.isNotEmpty) ...[
                      pw.Text('Notes:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text(invoice.notes,
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 6),
                    ],
                    if (invoice.terms.isNotEmpty) ...[
                      pw.Text('Terms & Conditions:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text(invoice.terms,
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'For ${invoice.businessName.isEmpty ? 'Your Business' : invoice.businessName}',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 38),
                    pw.Container(height: 0.8, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signatory',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey300),
          pw.Center(
            child: pw.Text(
              'Thank you for your business! · Made with EasyBill Invoice Maker',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _pdfMetaRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  static pw.Widget _pdfSummaryRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  /// Generates the raw PDF bytes
  static Future<Uint8List> generatePdfBytes(InvoiceDraft invoice) async {
    final doc = buildPdfDocument(invoice);
    return await doc.save();
  }

  /// Generates a high-quality PNG image of the invoice (page 1)
  static Future<Uint8List> generateInvoiceImage(InvoiceDraft invoice) async {
    final pdfBytes = await generatePdfBytes(invoice);
    await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 200)) {
      return await page.toPng();
    }
    throw Exception('Failed to rasterize invoice into image.');
  }

  /// Launches the system print dialog and preview
  static Future<void> preview(InvoiceDraft invoice) async {
    final pdfBytes = await generatePdfBytes(invoice);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  /// Shares the PDF via standard OS share sheet
  static Future<void> sharePdf(InvoiceDraft invoice) async {
    final bytes = await generatePdfBytes(invoice);
    final tempDir = await getTemporaryDirectory();
    final cleanNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${tempDir.path}/Invoice_$cleanNum.pdf');
    await file.writeAsBytes(bytes, flush: true);

    final text = getWhatsAppShareText(invoice);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path,
              mimeType: 'application/pdf', name: 'Invoice_$cleanNum.pdf')
        ],
        text: text,
        subject:
            'Invoice #${invoice.invoiceNumber} from ${invoice.businessName}',
      ),
    );
  }

  /// Shares the generated Invoice as an image (PNG)
  static Future<void> shareImage(InvoiceDraft invoice) async {
    final imageBytes = await generateInvoiceImage(invoice);
    final tempDir = await getTemporaryDirectory();
    final cleanNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${tempDir.path}/Invoice_$cleanNum.png');
    await file.writeAsBytes(imageBytes, flush: true);

    final text = getWhatsAppShareText(invoice);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: 'image/png', name: 'Invoice_$cleanNum.png')
        ],
        text: text,
        subject:
            'Invoice #${invoice.invoiceNumber} from ${invoice.businessName}',
      ),
    );
  }

  /// Generates professional message text for WhatsApp or SMS
  static String getWhatsAppShareText(InvoiceDraft invoice) {
    final money =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    final dateStr = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);

    final buffer = StringBuffer();
    buffer.writeln('📋 *INVOICE: ${invoice.invoiceNumber}*');
    buffer.writeln(
        'From: *${invoice.businessName.isNotEmpty ? invoice.businessName : "Our Business"}*');
    if (invoice.customerName.isNotEmpty) {
      buffer.writeln('To: *${invoice.customerName}*');
    }
    buffer.writeln('Date: $dateStr');
    buffer.writeln('---------------------------');
    buffer.writeln('💰 *Total Amount: ${money.format(invoice.total)}*');
    buffer.writeln('Status: *${invoice.paymentStatus.toUpperCase()}*');
    if (invoice.upiId.isNotEmpty) {
      buffer.writeln('UPI Payment ID: `${invoice.upiId}`');
    }
    buffer.writeln('---------------------------');
    buffer.writeln('Thank you for your business! 🙏');
    return buffer.toString();
  }
}
