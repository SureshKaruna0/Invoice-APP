import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_pdf_service.dart';
import '../../domain/invoice_draft.dart';

class InvoiceShareBottomSheet extends StatefulWidget {
  const InvoiceShareBottomSheet({
    super.key,
    required this.invoice,
    this.onShareCompleted,
  });

  final InvoiceDraft invoice;
  final VoidCallback? onShareCompleted;

  static Future<void> show(
    BuildContext context,
    InvoiceDraft invoice, {
    VoidCallback? onShareCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvoiceShareBottomSheet(
        invoice: invoice,
        onShareCompleted: onShareCompleted,
      ),
    );
  }

  @override
  State<InvoiceShareBottomSheet> createState() => _InvoiceShareBottomSheetState();
}

class _InvoiceShareBottomSheetState extends State<InvoiceShareBottomSheet> {
  bool _isBusy = false;
  String _statusText = '';

  void _notifyComplete() {
    if (widget.onShareCompleted != null) {
      widget.onShareCompleted!();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invoice shared & saved! Values reset for next invoice.'),
          backgroundColor: AppColors.green1,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _shareViaWhatsApp() async {
    setState(() {
      _isBusy = true;
      _statusText = 'Preparing WhatsApp share with invoice…';
    });
    try {
      await InvoicePdfService.shareImage(widget.invoice);
      _notifyComplete();
    } catch (e) {
      if (mounted) {
        _showToast('Share failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sharePdfDocument() async {
    setState(() {
      _isBusy = true;
      _statusText = 'Generating PDF document…';
    });
    try {
      await InvoicePdfService.sharePdf(widget.invoice);
      _notifyComplete();
    } catch (e) {
      if (mounted) {
        _showToast('PDF share failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _shareInvoiceImage() async {
    setState(() {
      _isBusy = true;
      _statusText = 'Rasterizing invoice image (PNG)…';
    });
    try {
      await InvoicePdfService.shareImage(widget.invoice);
      _notifyComplete();
    } catch (e) {
      if (mounted) {
        _showToast('Image share failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _printOrSavePdf() async {
    setState(() {
      _isBusy = true;
      _statusText = 'Opening system print dialog…';
    });
    try {
      await InvoicePdfService.preview(widget.invoice);
      _notifyComplete();
    } catch (e) {
      if (mounted) {
        _showToast('Print preview failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _copyInvoiceText() {
    final text = InvoicePdfService.getWhatsAppShareText(widget.invoice);
    Clipboard.setData(ClipboardData(text: text));
    _showToast('Invoice summary copied to clipboard! Ready to paste.');
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey11,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Close Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.red2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColors.red1, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share & Export Invoice',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black2,
                        ),
                      ),
                      Text(
                        'Share via WhatsApp, PDF, high-res Image or Print',
                        style: TextStyle(fontSize: 12, color: AppColors.grey4),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.grey18),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Invoice Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.black2, AppColors.black5],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black6.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.blue7.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.invoice.invoiceNumber,
                          style: const TextStyle(
                            color: AppColors.blue8,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        dateFormat.format(widget.invoice.invoiceDate),
                        style: const TextStyle(color: AppColors.grey15, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BILLED TO',
                              style: TextStyle(color: AppColors.grey15, fontSize: 10, letterSpacing: 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.invoice.customerName.isEmpty ? 'Customer' : widget.invoice.customerName,
                              style: const TextStyle(
                                color: AppColors.white1,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'GRAND TOTAL',
                            style: TextStyle(color: AppColors.grey15, fontSize: 10, letterSpacing: 1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            money.format(widget.invoice.total),
                            style: const TextStyle(
                              color: AppColors.green1,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isBusy) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 3, color: AppColors.blue2),
                    const SizedBox(height: 10),
                    Text(
                      _statusText,
                      style: const TextStyle(fontSize: 13, color: AppColors.grey4, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Grid of Sharing Options
              Row(
                children: [
                  Expanded(
                    child: _buildShareButton(
                      title: 'Share on WhatsApp',
                      subtitle: 'Direct billing chat',
                      icon: Icons.chat_rounded,
                      iconColor: AppColors.white1,
                      backgroundColor: const Color(0xFF25D366),
                      textColor: AppColors.white1,
                      onTap: _shareViaWhatsApp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShareButton(
                      title: 'Share as PDF',
                      subtitle: 'Official doc format',
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: AppColors.white1,
                      backgroundColor: AppColors.red1,
                      textColor: AppColors.white1,
                      onTap: _sharePdfDocument,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildShareButton(
                      title: 'Share as Image',
                      subtitle: 'PNG photo card',
                      icon: Icons.image_rounded,
                      iconColor: AppColors.black2,
                      backgroundColor: AppColors.grey10,
                      textColor: AppColors.black2,
                      onTap: _shareInvoiceImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShareButton(
                      title: 'Print / Save PDF',
                      subtitle: 'System print dialog',
                      icon: Icons.print_rounded,
                      iconColor: AppColors.black2,
                      backgroundColor: AppColors.grey10,
                      textColor: AppColors.black2,
                      onTap: _printOrSavePdf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Secondary Quick Action: Copy Text Summary
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: AppColors.grey14),
                ),
                onPressed: _copyInvoiceText,
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.grey13),
                label: const Text(
                  'Copy Formatted Text Summary (For SMS & Chat)',
                  style: TextStyle(color: AppColors.black1, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.black6.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
