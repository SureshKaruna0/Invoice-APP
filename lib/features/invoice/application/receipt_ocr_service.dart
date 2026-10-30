import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/invoice_line.dart';
import '../domain/ocr_extracted_invoice.dart';

class ReceiptOcrService {
  /// Parse receipt image using ML Kit Text Recognition with heuristic pattern analysis
  static Future<OcrExtractedInvoice> processReceiptImage(File imageFile) async {
    String recognizedText = '';
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText result = await recognizer.processImage(inputImage);
      recognizedText = result.text;
    } catch (_) {
      // Graceful fallback for non-supported platforms or camera errors
      recognizedText = 'Receipt Image OCR\nAmount: ₹0.00';
    } finally {
      await recognizer.close();
    }

    return parseReceiptText(recognizedText, imageFile.path);
  }

  /// Pure text parsing algorithm that extracts financial & invoice fields
  static OcrExtractedInvoice parseReceiptText(String text, String imagePath) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Vendor / Business Name (typically top lines that don't match meta tags)
    String vendor = '';
    FieldConfidence vendorConf = FieldConfidence.low;
    for (int i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (!lower.contains('tax') &&
          !lower.contains('invoice') &&
          !lower.contains('bill') &&
          !lower.contains('cash') &&
          !lower.contains('receipt') &&
          !lower.contains('gst') &&
          !lower.contains('tel') &&
          !lower.contains('phone') &&
          line.length > 2) {
        vendor = line;
        vendorConf = i == 0 ? FieldConfidence.high : FieldConfidence.medium;
        break;
      }
    }
    if (vendor.isEmpty && lines.isNotEmpty) {
      vendor = lines.first;
      vendorConf = FieldConfidence.low;
    }

    // 2. Invoice / Receipt Number
    String invoiceNo = '';
    FieldConfidence invConf = FieldConfidence.low;
    final invRegex = RegExp(
        r'(?:invoice|inv|bill|receipt|rcpt|order)\s*(?:no|num|number|#)?[:.\s-]*([A-Za-z0-9\-_/]+)',
        caseSensitive: false);
    for (final line in lines) {
      final match = invRegex.firstMatch(line);
      if (match != null && match.group(1) != null) {
        final val = match.group(1)!.trim();
        if (val.length >= 2) {
          invoiceNo = val;
          invConf = FieldConfidence.high;
          break;
        }
      }
    }
    if (invoiceNo.isEmpty) {
      invoiceNo = 'RCPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      invConf = FieldConfidence.low;
    }

    // 3. Date
    DateTime? invoiceDate;
    FieldConfidence dateConf = FieldConfidence.low;
    final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        try {
          final p1 = int.parse(match.group(1)!);
          final p2 = int.parse(match.group(2)!);
          var year = int.parse(match.group(3)!);
          if (year < 100) year += 2000;
          // Format could be DD/MM/YYYY or MM/DD/YYYY; assume DD/MM/YYYY if p1 > 12
          int day = p1;
          int month = p2;
          if (p1 <= 12 && p2 > 12) {
            day = p2;
            month = p1;
          }
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            invoiceDate = DateTime(year, month, day);
            dateConf = FieldConfidence.high;
            break;
          }
        } catch (_) {}
      }
    }
    invoiceDate ??= DateTime.now();

    // 4. GSTIN
    String gstin = '';
    FieldConfidence gstinConf = FieldConfidence.low;
    final gstinRegex = RegExp(r'\d{2}[A-Z]{5}\d{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}');
    for (final line in lines) {
      final match = gstinRegex.firstMatch(line.toUpperCase());
      if (match != null) {
        gstin = match.group(0)!;
        gstinConf = FieldConfidence.high;
        break;
      }
    }

    // 5. Total, Subtotal & Tax Amounts
    double total = 0.0;
    FieldConfidence totalConf = FieldConfidence.low;
    double subtotal = 0.0;
    FieldConfidence subtotalConf = FieldConfidence.low;
    double tax = 0.0;
    FieldConfidence taxConf = FieldConfidence.low;

    final numberPattern = RegExp(r'₹?\s*(\d+(?:[.,]\d{1,2})?)');

    for (int i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      // Total match
      if (l.contains('grand total') ||
          l.contains('total amount') ||
          l.contains('net amount') ||
          l.contains('amount payable') ||
          (l.contains('total') && !l.contains('sub') && !l.contains('tax'))) {
        final m = numberPattern.allMatches(lines[i]);
        if (m.isNotEmpty) {
          final rawVal = m.last.group(1)!.replaceAll(',', '');
          final val = double.tryParse(rawVal) ?? 0.0;
          if (val > total) {
            total = val;
            totalConf = FieldConfidence.high;
          }
        }
      }
      // Subtotal match
      if (l.contains('subtotal') || l.contains('sub total') || l.contains('base amount')) {
        final m = numberPattern.allMatches(lines[i]);
        if (m.isNotEmpty) {
          final rawVal = m.last.group(1)!.replaceAll(',', '');
          subtotal = double.tryParse(rawVal) ?? 0.0;
          subtotalConf = FieldConfidence.high;
        }
      }
      // Tax / GST match
      if (l.contains('cgst') || l.contains('sgst') || l.contains('igst') || l.contains('gst') || l.contains('tax')) {
        final m = numberPattern.allMatches(lines[i]);
        if (m.isNotEmpty) {
          final rawVal = m.last.group(1)!.replaceAll(',', '');
          final val = double.tryParse(rawVal) ?? 0.0;
          if (val > 0 && val < total) {
            tax += val;
            taxConf = FieldConfidence.medium;
          }
        }
      }
    }

    // 6. Payment Mode
    String paymentMode = 'UPI / Cash';
    FieldConfidence payConf = FieldConfidence.low;
    final lowerText = text.toLowerCase();
    if (lowerText.contains('upi') || lowerText.contains('gpay') || lowerText.contains('phonepe') || lowerText.contains('paytm')) {
      paymentMode = 'UPI';
      payConf = FieldConfidence.high;
    } else if (lowerText.contains('card') || lowerText.contains('visa') || lowerText.contains('mastercard') || lowerText.contains('pos')) {
      paymentMode = 'Card (POS)';
      payConf = FieldConfidence.high;
    } else if (lowerText.contains('cash')) {
      paymentMode = 'Cash';
      payConf = FieldConfidence.high;
    }

    // 7. Parse Items Lines
    final parsedLines = <InvoiceLine>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      // Skip meta rows
      if (lower.contains('total') ||
          lower.contains('subtotal') ||
          lower.contains('invoice') ||
          lower.contains('gstin') ||
          lower.contains('tax') ||
          lower.contains('date')) {
        continue;
      }

      // Look for a price at end of line (e.g., "Masala Dosa 2 80.00" or "Item A 150.00")
      final priceMatches = numberPattern.allMatches(line).toList();
      if (priceMatches.isNotEmpty && line.length > 3) {
        final lastMatch = priceMatches.last;
        final rawPrice = lastMatch.group(1)!.replaceAll(',', '');
        final price = double.tryParse(rawPrice) ?? 0.0;

        if (price > 0 && price <= (total > 0 ? total : 500000)) {
          // Check for quantity before price
          double qty = 1.0;
          if (priceMatches.length >= 2) {
            final rawQty = priceMatches[priceMatches.length - 2].group(1)!;
            final parsedQty = double.tryParse(rawQty) ?? 1.0;
            if (parsedQty > 0 && parsedQty < 1000) {
              qty = parsedQty;
            }
          }

          final descEndIdx = lastMatch.start;
          var desc = line.substring(0, descEndIdx).replaceAll(RegExp(r'[\d.,₹]+$'), '').trim();
          if (desc.isNotEmpty && desc.length >= 2) {
            parsedLines.add(InvoiceLine(
              id: 'ocr_item_${parsedLines.length + 1}',
              description: desc,
              quantity: qty,
              unitPrice: (price / qty).clamp(0.01, double.infinity),
              taxRate: 18.0,
            ));
          }
        }
      }
    }

    // If no line items successfully parsed from text, create a default consolidated item
    if (parsedLines.isEmpty) {
      parsedLines.add(InvoiceLine(
        id: 'ocr_item_1',
        description: vendor.isNotEmpty ? '$vendor Expense / Item' : 'Scanned Receipt Item',
        quantity: 1,
        unitPrice: total > 0 ? total : 0.0,
        taxRate: 18.0,
      ));
    }

    // If total wasn't detected but lines have amounts
    if (total == 0.0 && parsedLines.isNotEmpty) {
      total = parsedLines.fold(0.0, (sum, l) => sum + l.total);
    }
    if (subtotal == 0.0) {
      subtotal = total - tax;
    }

    return OcrExtractedInvoice(
      imagePath: imagePath,
      rawOcrText: text,
      vendorName: ExtractedField(value: vendor, confidence: vendorConf),
      invoiceNumber: ExtractedField(value: invoiceNo, confidence: invConf),
      date: ExtractedField(value: invoiceDate, confidence: dateConf),
      gstin: ExtractedField(value: gstin, confidence: gstinConf),
      subtotal: ExtractedField(value: subtotal > 0 ? subtotal : total, confidence: subtotalConf),
      taxAmount: ExtractedField(value: tax, confidence: taxConf),
      totalAmount: ExtractedField(value: total, confidence: totalConf),
      paymentMode: ExtractedField(value: paymentMode, confidence: payConf),
      lines: parsedLines,
    );
  }
}

