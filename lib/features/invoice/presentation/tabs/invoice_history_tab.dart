import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_form_controller.dart';
import '../../application/invoice_pdf_service.dart';
import '../../domain/invoice_draft.dart';
import '../widgets/invoice_share_bottom_sheet.dart';

class InvoiceHistoryTab extends ConsumerStatefulWidget {
  const InvoiceHistoryTab({
    super.key,
    required this.onOpenInvoice,
  });

  final ValueChanged<InvoiceDraft> onOpenInvoice;

  @override
  ConsumerState<InvoiceHistoryTab> createState() => _InvoiceHistoryTabState();
}

class _InvoiceHistoryTabState extends ConsumerState<InvoiceHistoryTab> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final money = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');

    final invoices = state.savedInvoices.where((inv) {
      if (_filter != 'All' && inv.paymentStatus.toLowerCase() != _filter.toLowerCase()) {
        return false;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchNum = inv.invoiceNumber.toLowerCase().contains(q);
        final matchCust = inv.customerName.toLowerCase().contains(q);
        return matchNum || matchCust;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter header
        Container(
          color: AppColors.white1,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search by invoice number or customer…',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['All', 'Paid', 'Pending'].map((f) {
                  final isSel = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSel,
                      selectedColor: AppColors.blue1,
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.white1 : AppColors.grey2,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Invoices List
        Expanded(
          child: invoices.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.grey5),
                        const SizedBox(height: 14),
                        const Text(
                          'No Invoices Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black1),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create an invoice using the wizard to see records and export history here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.grey4),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final isPaid = inv.paymentStatus.toLowerCase() == 'paid';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.white1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.grey11),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => widget.onOpenInvoice(inv),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue8,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          inv.invoiceNumber,
                                          style: const TextStyle(
                                            color: AppColors.blue1,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (inv.receiptImagePath != null &&
                                            inv.receiptImagePath!.isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.attachment_rounded,
                                              size: 13,
                                              color: AppColors.blue1),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPaid ? AppColors.green2 : AppColors.brown3,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      inv.paymentStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: isPaid ? AppColors.green3 : AppColors.orange2,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inv.customerName.isEmpty ? 'Unnamed Customer' : inv.customerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: AppColors.black2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateFormat.format(inv.invoiceDate),
                                          style: const TextStyle(color: AppColors.grey4, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    money.format(inv.total),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.black2,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 22, color: AppColors.grey10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => InvoicePdfService.preview(inv),
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.blue2),
                                    label: const Text('View PDF', style: TextStyle(color: AppColors.blue2)),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.red2,
                                      foregroundColor: AppColors.red1,
                                    ),
                                    onPressed: () => InvoiceShareBottomSheet.show(context, inv),
                                    icon: const Icon(Icons.share_rounded, size: 16),
                                    label: const Text('Share'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
