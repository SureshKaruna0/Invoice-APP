import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/invoice_draft.dart';
import 'number_to_words.dart';

class InvoicePdfService {
  // In-memory cache for fonts to avoid re-fetching on every PDF generation (Phase 1 Performance)
  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  /// Loads and caches full Unicode fonts supporting Indian Rupee symbol (₹ U+20B9)
  static Future<void> _ensureFontsLoaded() async {
    if (_cachedRegularFont != null && _cachedBoldFont != null) return;
    try {
      _cachedRegularFont = await PdfGoogleFonts.notoSansRegular();
      _cachedBoldFont = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      try {
        _cachedRegularFont = await PdfGoogleFonts.robotoRegular();
        _cachedBoldFont = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        // Fallback for strict offline environments
        _cachedRegularFont = pw.Font.helvetica();
        _cachedBoldFont = pw.Font.helveticaBold();
      }
    }
  }

  /// Builds the complete executive PDF document with Zoho-inspired layout
  static Future<pw.Document> buildPdfDocumentAsync(InvoiceDraft invoice) async {
    await _ensureFontsLoaded();
    return _buildDocument(invoice, _cachedRegularFont, _cachedBoldFont);
  }

  /// Synchronous builder with cached fonts or fallbacks
  static pw.Document buildPdfDocument(InvoiceDraft invoice) {
    return _buildDocument(invoice, _cachedRegularFont ?? pw.Font.helvetica(),
        _cachedBoldFont ?? pw.Font.helveticaBold());
  }

  static pw.Document _buildDocument(
      InvoiceDraft invoice, pw.Font? regularFont, pw.Font? boldFont) {
    final doc = pw.Document(
      theme: regularFont != null && boldFont != null
          ? pw.ThemeData.withFont(base: regularFont, bold: boldFont)
          : null,
    );

    final money =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');
    final invoiceDateStr = dateFormat.format(invoice.invoiceDate);
    final dueDateStr = invoice.dueDate != null
        ? dateFormat.format(invoice.dueDate!)
        : 'Upon Receipt';

    final hasDiscount = invoice.totalDiscount > 0;
    final hasTax = invoice.totalTax > 0;

    pw.MemoryImage? logoImage;
    if (invoice.businessLogoPath != null &&
        invoice.businessLogoPath!.isNotEmpty) {
      final file = File(invoice.businessLogoPath!);
      if (file.existsSync()) {
        try {
          logoImage = pw.MemoryImage(file.readAsBytesSync());
        } catch (_) {}
      }
    }

    // Receipt Image Attachment
    pw.MemoryImage? receiptImage;
    if (invoice.includeReceiptInPdf &&
        invoice.receiptImagePath != null &&
        invoice.receiptImagePath!.isNotEmpty) {
      final file = File(invoice.receiptImagePath!);
      if (file.existsSync()) {
        try {
          receiptImage = pw.MemoryImage(file.readAsBytesSync());
        } catch (_) {}
      }
    }

    // Watermark Background Builder (Phase 5)
    pw.Widget buildWatermarkBackground(pw.Context context) {
      if (invoice.watermarkType == 'none') {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: PdfColors.white),
        );
      }

      pw.Widget watermarkContent;
      if (invoice.watermarkType == 'logo' && logoImage != null) {
        watermarkContent = pw.Opacity(
          opacity: invoice.watermarkOpacity.clamp(0.03, 0.35),
          child: pw.Image(logoImage,
              width: 280, height: 280, fit: pw.BoxFit.contain),
        );
      } else {
        final text = invoice.watermarkText.isNotEmpty
            ? invoice.watermarkText.toUpperCase()
            : (invoice.paymentStatus.toLowerCase() == 'paid'
                ? 'PAID'
                : 'ORIGINAL');
        watermarkContent = pw.Opacity(
          opacity: invoice.watermarkOpacity.clamp(0.03, 0.35),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 60,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
              letterSpacing: 6.0,
            ),
          ),
        );
      }

      if (invoice.watermarkPlacement == 'diagonal') {
        watermarkContent =
            pw.Transform.rotate(angle: -0.55, child: watermarkContent);
      }

      return pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          children: [
            pw.Container(color: PdfColors.white),
            pw.Center(child: watermarkContent),
          ],
        ),
      );
    }

    // PAGE 1: Master Invoice Page
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          buildBackground: buildWatermarkBackground,
        ),
        build: (context) => [
          // Executive Top Header Banner (Zoho Books Style)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1A202E),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 10,
                      height: 10,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF3984FE),
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'TAX INVOICE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: invoice.paymentStatus.toLowerCase() == 'paid'
                        ? const PdfColor.fromInt(0xFF27AE60)
                        : const PdfColor.fromInt(0xFFE74C3C),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    invoice.paymentStatus.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Business Profile & Invoice Meta Row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Seller details
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) ...[
                      pw.Container(
                        width: 54,
                        height: 54,
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    ],
                    pw.Text(
                      invoice.businessName.isEmpty
                          ? 'Your Business'
                          : invoice.businessName,
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1A202E)),
                    ),
                    if (invoice.businessAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(invoice.businessAddress,
                          style: const pw.TextStyle(
                              fontSize: 9.5, color: PdfColors.grey700)),
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
                              color: const PdfColor.fromInt(0xFF3366FF),
                              width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          'GSTIN: ${invoice.businessGstin}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8.5,
                              color: const PdfColor.fromInt(0xFF3C2D89)),
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
                    color: const PdfColor.fromInt(0xFFF8F9FA),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfMetaRow('Invoice No:', invoice.invoiceNumber),
                      _pdfMetaRow('Invoice Date:', invoiceDateStr),
                      _pdfMetaRow('Due Date:', dueDateStr),
                      _pdfMetaRow('Payment Mode:', invoice.paymentMode),
                      _pdfMetaRow('Payment Status:', invoice.paymentStatus),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Bill To Card
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              color: PdfColors.white,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO / CUSTOMER',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF3366FF),
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        invoice.customerName.isEmpty
                            ? 'Valued Customer'
                            : invoice.customerName,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      if (invoice.customerAddress.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.customerAddress,
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                      ],
                      if (invoice.customerPhone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('Phone: ${invoice.customerPhone}',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: PdfColors.grey700)),
                      ],
                    ],
                  ),
                ),
                if (invoice.customerGstin.isNotEmpty) ...[
                  pw.Container(
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF1F3F4),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'GSTIN: ${invoice.customerGstin}',
                      style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Items Table (Zoho Books Style)
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder(
              horizontalInside: const pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE3E6EA), width: 0.6),
              bottom: const pw.BorderSide(
                  color: PdfColor.fromInt(0xFF1A202E), width: 1.2),
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
              letterSpacing: 0.5,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1A202E),
            ),
            headerPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            headers: [
              '#',
              'ITEM DESCRIPTION',
              'HSN/SAC',
              'QTY',
              'RATE (₹)',
              if (hasDiscount) 'DISC (₹)',
              if (hasTax) 'GST %',
              'AMOUNT (₹)',
            ],
            data: invoice.lines.asMap().entries.map((entry) {
              final i = entry.key;
              final line = entry.value;
              return [
                '${i + 1}',
                line.description.isEmpty ? 'Item ${i + 1}' : line.description,
                line.hsnCode.isEmpty ? '-' : line.hsnCode,
                '${line.quantity % 1 == 0 ? line.quantity.toInt() : line.quantity} ${line.unit}',
                money.format(line.unitPrice),
                if (hasDiscount)
                  line.discount > 0 ? money.format(line.discount) : '-',
                if (hasTax) '${line.taxRate.toInt()}%',
                money.format(line.total),
              ];
            }).toList(),
            columnWidths: {
              0: const pw.FixedColumnWidth(20),
              1: const pw.FlexColumnWidth(3.8),
              2: const pw.FixedColumnWidth(48),
              3: const pw.FixedColumnWidth(44),
              4: const pw.FixedColumnWidth(56),
              if (hasDiscount) 5: const pw.FixedColumnWidth(48),
              if (hasTax) 6: const pw.FixedColumnWidth(38),
              7: const pw.FixedColumnWidth(64),
            },
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              if (hasDiscount) 5: pw.Alignment.centerRight,
              if (hasTax) 6: pw.Alignment.centerRight,
              7: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 12),

          // Summary Section & Bank Details Row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Bank & Payment Details + Rupee Amount in Words
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Amount in Words (Indian numbering system)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF1F3F4),
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'AMOUNT IN WORDS (INR):',
                            style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF3C2D89)),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            numberToIndianWords(invoice.total),
                            style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: const PdfColor.fromInt(0xFF1A202E)),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // Bank Account Info
                    if (invoice.bankAccount.isNotEmpty ||
                        invoice.upiId.isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: const PdfColor.fromInt(0xFFDFE1E4),
                              width: 0.6),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(4)),
                          color: PdfColors.white,
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'BANK & PAYMENT DETAILS',
                                    style: pw.TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.grey700),
                                  ),
                                  pw.SizedBox(height: 3),
                                  if (invoice.bankName.isNotEmpty)
                                    pw.Text('Bank: ${invoice.bankName}',
                                        style: const pw.TextStyle(fontSize: 8)),
                                  if (invoice.bankAccount.isNotEmpty)
                                    pw.Text('A/C No: ${invoice.bankAccount}',
                                        style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold)),
                                  if (invoice.bankIfsc.isNotEmpty)
                                    pw.Text('IFSC: ${invoice.bankIfsc}',
                                        style: const pw.TextStyle(fontSize: 8)),
                                  if (invoice.upiId.isNotEmpty)
                                    pw.Text('UPI ID: ${invoice.upiId}',
                                        style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                            color: const PdfColor.fromInt(
                                                0xFF3366FF))),
                                ],
                              ),
                            ),
                            // Optional UPI QR code for fast scanning
                            if (invoice.upiId.isNotEmpty) ...[
                              pw.Container(
                                width: 50,
                                height: 50,
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  border:
                                      pw.Border.all(color: PdfColors.grey300),
                                  borderRadius: const pw.BorderRadius.all(
                                      pw.Radius.circular(4)),
                                ),
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data:
                                      'upi://pay?pa=${invoice.upiId}&pn=${Uri.encodeComponent(invoice.businessName)}&am=${invoice.total.toStringAsFixed(2)}&cu=INR',
                                  width: 46,
                                  height: 46,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 14),

              // Grand Total Summary Card
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF8F9FA),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    children: [
                      _pdfSummaryRow(
                          'Subtotal (Base):', money.format(invoice.subtotal)),
                      if (hasDiscount)
                        _pdfSummaryRow('Discount Savings:',
                            '- ${money.format(invoice.totalDiscount)}'),
                      if (hasTax) ...[
                        _pdfSummaryRow('Taxable Amount:',
                            money.format(invoice.taxableAmount)),
                        _pdfSummaryRow(
                            'Total GST / Tax:', money.format(invoice.totalTax)),
                      ],
                      pw.Divider(color: PdfColors.grey400, thickness: 0.8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Grand Total:',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            money.format(invoice.total),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF27AE60),
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
          pw.SizedBox(height: 12),

          // Notes & Terms
          if (invoice.notes.isNotEmpty || invoice.terms.isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (invoice.notes.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Notes:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.notes,
                            style: const pw.TextStyle(
                                fontSize: 7.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                if (invoice.notes.isNotEmpty && invoice.terms.isNotEmpty)
                  pw.SizedBox(width: 12),
                if (invoice.terms.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Terms & Conditions:',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(invoice.terms,
                            style: const pw.TextStyle(
                                fontSize: 7.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          // Footer Signatory
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'This is a computer generated invoice and does not require physical signature.',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 110,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey500, width: 0.8)),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text('Authorized Signatory',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // PAGE 2: Optional Scanned Original Receipt Attachment Page (Phase 4)
    if (receiptImage != null) {
      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(32),
          ),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Attachment Header
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1A202E),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ATTACHED ORIGINAL RECEIPT / VOUCHER',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    pw.Text(
                      'Page 2 of 2',
                      style: const pw.TextStyle(
                          color: PdfColors.grey400, fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Text(
                'Original source document attached to Invoice #${invoice.invoiceNumber}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),

              // Fitted Receipt Image with Border
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 1.0),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    color: PdfColors.grey50,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Image(
                    receiptImage!,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Verified & Attached via EasyBill PRO Smart Receipt Scanner',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return doc;
  }

  static pw.Widget _pdfMetaRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  static pw.Widget _pdfSummaryRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  /// Generates the raw PDF bytes
  static Future<Uint8List> generatePdfBytes(InvoiceDraft invoice) async {
    final doc = await buildPdfDocumentAsync(invoice);
    return await doc.save();
  }

  /// Generates a high-quality PNG image of the invoice (page 1) with an explicit solid white background
  static Future<Uint8List> generateInvoiceImage(InvoiceDraft invoice) async {
    final pdfBytes = await generatePdfBytes(invoice);
    await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 200)) {
      final ui.Image rasterImage = await page.toImage();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(0, 0, rasterImage.width.toDouble(),
            rasterImage.height.toDouble()),
      );

      // Explicitly paint solid white background so image is NEVER dark/transparent on dark mode devices
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, rasterImage.width.toDouble(),
            rasterImage.height.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );

      // Draw the rendered invoice document on top of the white background
      canvas.drawImage(rasterImage, ui.Offset.zero, ui.Paint());

      final picture = recorder.endRecording();
      final finalImage =
          await picture.toImage(rasterImage.width, rasterImage.height);
      final byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
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

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path,
              mimeType: 'application/pdf', name: 'Invoice_$cleanNum.pdf')
        ],
        subject:
            'Invoice #${invoice.invoiceNumber} from ${invoice.businessName}',
      ),
    );
  }

  /// Shares the generated Invoice as an image (PNG file)
  static Future<void> shareImage(InvoiceDraft invoice) async {
    final imageBytes = await generateInvoiceImage(invoice);
    final tempDir = await getTemporaryDirectory();
    final cleanNum = invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${tempDir.path}/Invoice_$cleanNum.png');
    await file.writeAsBytes(imageBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: 'image/png', name: 'Invoice_$cleanNum.png')
        ],
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
