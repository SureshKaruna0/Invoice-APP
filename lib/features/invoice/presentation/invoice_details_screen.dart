import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../application/invoice_form_controller.dart';
import '../application/invoice_pdf_service.dart';
import '../domain/invoice_draft.dart';
import 'widgets/invoice_share_bottom_sheet.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  const InvoiceDetailsScreen({
    super.key,
    required this.invoice,
    required this.onEditInvoice,
    required this.onInvoiceDeleted,
  });

  final InvoiceDraft invoice;
  final VoidCallback onEditInvoice;
  final VoidCallback onInvoiceDeleted;

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen> {
  late InvoiceDraft _currentInvoice;
  final money =
      NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
  }

  void _togglePaymentStatus() {
    final newStatus =
        _currentInvoice.paymentStatus.toLowerCase() == 'paid' ? 'Pending' : 'Paid';
    setState(() {
      _currentInvoice = _currentInvoice.copyWith(paymentStatus: newStatus);
    });
    ref
        .read(invoiceFormProvider.notifier)
        .updateInvoicePaymentStatus(_currentInvoice.invoiceNumber, newStatus);
    AppSnackbar.showSuccess('Status updated to $newStatus');
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text(
            'Are you sure you want to delete ${_currentInvoice.invoiceNumber}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red1),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(invoiceFormProvider.notifier)
                  .deleteInvoice(_currentInvoice.invoiceNumber);
              AppSnackbar.showInfo(
                  'Invoice ${_currentInvoice.invoiceNumber} deleted');
              widget.onInvoiceDeleted();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReceiptFullscreen(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(12.w),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.black6,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.white1, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = _currentInvoice.paymentStatus.toLowerCase() == 'paid';
    final hasReceipt = _currentInvoice.receiptImagePath != null &&
        _currentInvoice.receiptImagePath!.isNotEmpty &&
        File(_currentInvoice.receiptImagePath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.grey12,
      appBar: AppBar(
        title: Text(
          _currentInvoice.invoiceNumber,
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.black2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.blue1),
            tooltip: 'Edit Invoice',
            onPressed: () {
              ref
                  .read(invoiceFormProvider.notifier)
                  .loadInvoice(_currentInvoice);
              Navigator.pop(context);
              widget.onEditInvoice();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red1),
            tooltip: 'Delete Invoice',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.white1,
            boxShadow: [
              BoxShadow(
                color: AppColors.black6.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: const BorderSide(color: AppColors.blue1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  onPressed: () => InvoicePdfService.preview(_currentInvoice),
                  icon: Icon(Icons.print_outlined, size: 18.sp, color: AppColors.blue1),
                  label: Text('Print / PDF',
                      style: TextStyle(color: AppColors.blue1, fontSize: 13.sp)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: AppColors.red1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  onPressed: () {
                    InvoiceShareBottomSheet.show(context, _currentInvoice);
                  },
                  icon: Icon(Icons.share_rounded, size: 18.sp, color: AppColors.white1),
                  label: Text('Share Invoice',
                      style: TextStyle(
                          color: AppColors.white1,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner with 1-Tap Toggle
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.green1.withValues(alpha: 0.12)
                    : AppColors.orange2.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isPaid ? AppColors.green1 : AppColors.orange2,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPaid
                            ? Icons.check_circle_rounded
                            : Icons.access_time_filled_rounded,
                        color: isPaid ? AppColors.green1 : AppColors.orange2,
                        size: 22.sp,
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPaid ? 'PAYMENT RECEIVED' : 'PAYMENT PENDING',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color:
                                  isPaid ? AppColors.green1 : AppColors.orange2,
                            ),
                          ),
                          Text(
                            'Grand Total: ${money.format(_currentInvoice.total)}',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _togglePaymentStatus,
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      backgroundColor: AppColors.white1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text(
                      isPaid ? 'Mark Pending' : 'Mark Paid',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isPaid ? AppColors.orange2 : AppColors.green1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Customer & Metadata Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
                side: const BorderSide(color: AppColors.grey11),
              ),
              color: AppColors.white1,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black2,
                          ),
                        ),
                        Text(
                          dateFormat.format(_currentInvoice.invoiceDate),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.grey4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _currentInvoice.customerName.isEmpty
                          ? 'Customer'
                          : _currentInvoice.customerName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue1,
                      ),
                    ),
                    if (_currentInvoice.customerAddress.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        _currentInvoice.customerAddress,
                        style: TextStyle(fontSize: 13.sp, color: AppColors.grey13),
                      ),
                    ],
                    if (_currentInvoice.customerPhone.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        'Phone: ${_currentInvoice.customerPhone}',
                        style: TextStyle(fontSize: 12.sp, color: AppColors.grey13),
                      ),
                    ],
                    if (_currentInvoice.customerGstin.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.grey10,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'GSTIN: ${_currentInvoice.customerGstin}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Attached Scanned Receipt Section (Phase 4)
            if (hasReceipt) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  side: const BorderSide(color: AppColors.grey11),
                ),
                color: AppColors.white1,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attachment_rounded,
                                  size: 18.sp, color: AppColors.blue2),
                              SizedBox(width: 6.w),
                              Text(
                                'Attached Original Receipt',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.black2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.green1.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      InkWell(
                        onTap: () => _showReceiptFullscreen(
                            _currentInvoice.receiptImagePath!),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          height: 140.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: AppColors.grey14),
                            color: AppColors.grey12,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9.r),
                                child: Image.file(
                                  File(_currentInvoice.receiptImagePath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: AppColors.black6.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in_rounded,
                                        size: 16.sp, color: AppColors.white1),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Tap to view receipt image',
                                      style: TextStyle(
                                          color: AppColors.white1,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined,
                              size: 14.sp, color: AppColors.grey4),
                          SizedBox(width: 4.w),
                          Text(
                            _currentInvoice.includeReceiptInPdf
                                ? 'Included as attachment page in exported PDF'
                                : 'Attachment excluded from PDF export',
                            style: TextStyle(
                                fontSize: 11.sp, color: AppColors.grey4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Line Items Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
                side: const BorderSide(color: AppColors.grey11),
              ),
              color: AppColors.white1,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items Breakdown (${_currentInvoice.lines.length})',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black2,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...List.generate(_currentInvoice.lines.length, (i) {
                      final item = _currentInvoice.lines[i];
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == _currentInvoice.lines.length - 1
                                  ? Colors.transparent
                                  : AppColors.grey11,
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 10.r,
                              backgroundColor: AppColors.grey10,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black2),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description.isEmpty
                                        ? 'Item ${i + 1}'
                                        : item.description,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black2,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit} × ${money.format(item.unitPrice)}${item.taxRate > 0
                                            ? ' (${item.taxRate.toInt()}% GST)'
                                            : ''}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppColors.grey4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              money.format(item.total),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                    _summaryRow('Subtotal', money.format(_currentInvoice.subtotal)),
                    if (_currentInvoice.totalDiscount > 0)
                      _summaryRow('Discount Savings',
                          '- ${money.format(_currentInvoice.totalDiscount)}',
                          isDiscount: true),
                    if (_currentInvoice.totalTax > 0)
                      _summaryRow(
                          'Total GST', money.format(_currentInvoice.totalTax)),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total',
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.w800)),
                        Text(
                          money.format(_currentInvoice.total),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.green1,
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
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isDiscount ? AppColors.green1 : AppColors.black2,
            ),
          ),
        ],
      ),
    );
  }
}
