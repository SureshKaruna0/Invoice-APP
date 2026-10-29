import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/invoice_draft.dart';

class InvoicePdfService {
  static Future<void> preview(InvoiceDraft invoice) async {
    final doc = pw.Document();
    final money = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final date = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(invoice.businessName.isEmpty ? 'Your Business' : invoice.businessName,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                if (invoice.businessAddress.isNotEmpty) pw.Text(invoice.businessAddress),
              ],
            )),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('No: ${invoice.invoiceNumber}'),
              pw.Text('Date: $date'),
            ]),
          ],
        ),
        pw.SizedBox(height: 26),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          color: PdfColors.grey100,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('BILL TO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (invoice.customerAddress.isNotEmpty) pw.Text(invoice.customerAddress),
          ]),
        ),
        pw.SizedBox(height: 22),
        pw.TableHelper.fromTextArray(
          headers: ['Description', 'Qty', 'Unit price', 'Amount'],
          data: invoice.lines.map((line) => [
            line.description,
            line.quantity.toStringAsFixed(line.quantity % 1 == 0 ? 0 : 2),
            money.format(line.unitPrice),
            money.format(line.total),
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
          cellPadding: const pw.EdgeInsets.all(9),
          cellAlignments: {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 18),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Container(
          width: 230,
          padding: const pw.EdgeInsets.all(14),
          color: PdfColors.grey100,
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Grand Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.Text(money.format(invoice.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          ]),
        )),
        if (invoice.notes.trim().isNotEmpty) ...[
          pw.SizedBox(height: 24),
          pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(invoice.notes),
        ],
        pw.Spacer(),
        pw.Divider(),
        pw.Center(child: pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 10))),
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}
