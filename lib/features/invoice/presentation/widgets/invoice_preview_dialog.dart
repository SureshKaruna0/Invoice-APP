import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_pdf_service.dart';
import '../../domain/invoice_draft.dart';
import 'invoice_share_bottom_sheet.dart';

class InvoicePreviewDialog extends StatelessWidget {
  const InvoicePreviewDialog({
    super.key,
    required this.invoice,
    this.onEdit,
    this.onShareCompleted,
  });

  final InvoiceDraft invoice;
  final VoidCallback? onEdit;
  final VoidCallback? onShareCompleted;

  static Future<void> show(
    BuildContext context,
    InvoiceDraft invoice, {
    VoidCallback? onEdit,
    VoidCallback? onShareCompleted,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InvoicePreviewDialog(
          invoice: invoice,
          onEdit: onEdit,
          onShareCompleted: onShareCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey12,
      appBar: AppBar(
        backgroundColor: AppColors.white1,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black2),
          onPressed: () {
            Navigator.of(context).pop();
            if (onEdit != null) onEdit!();
          },
          tooltip: 'Return to Edit',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  invoice.invoiceNumber.isNotEmpty
                      ? invoice.invoiceNumber
                      : 'Draft Invoice',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: invoice.invoiceType == 'Cash'
                        ? AppColors.green1.withValues(alpha: 0.15)
                        : AppColors.blue1.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${invoice.invoiceType.toUpperCase()} INVOICE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: invoice.invoiceType == 'Cash'
                          ? AppColors.green1
                          : AppColors.blue1,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Realistic A4 Document Preview',
              style: TextStyle(fontSize: 11.5, color: AppColors.grey4),
            ),
          ],
        ),
        actions: [
          // Edit button
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              if (onEdit != null) onEdit!();
            },
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.blue2),
            label: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.blue2,
              ),
            ),
          ),
          // Share & Export button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red1,
                foregroundColor: AppColors.white1,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                InvoiceShareBottomSheet.show(
                  context,
                  invoice,
                  onShareCompleted: () {
                    Navigator.of(context).pop();
                    if (onShareCompleted != null) onShareCompleted!();
                  },
                );
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text(
                'Share / Export',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (PdfPageFormat format) =>
            InvoicePdfService.generatePdfBytes(invoice),
        initialPageFormat: PdfPageFormat.a4,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        maxPageWidth: 700,
        pdfFileName: 'Invoice_${invoice.invoiceNumber}.pdf',
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Generating realistic A4 preview…',
                style: TextStyle(fontSize: 13, color: AppColors.grey4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

