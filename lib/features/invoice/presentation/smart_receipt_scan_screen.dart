import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../application/invoice_form_controller.dart';
import '../application/receipt_ocr_service.dart';
import '../domain/ocr_extracted_invoice.dart';

class SmartReceiptScanScreen extends ConsumerStatefulWidget {
  const SmartReceiptScanScreen({
    super.key,
    required this.onInvoiceCreated,
  });

  final VoidCallback onInvoiceCreated;

  @override
  ConsumerState<SmartReceiptScanScreen> createState() =>
      _SmartReceiptScanScreenState();
}

class _SmartReceiptScanScreenState
    extends ConsumerState<SmartReceiptScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  OcrExtractedInvoice? _extractedData;

  // Editable Controllers for review stage
  late TextEditingController _vendorCtrl;
  late TextEditingController _invoiceNoCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _gstinCtrl;

  @override
  void initState() {
    super.initState();
    _vendorCtrl = TextEditingController();
    _invoiceNoCtrl = TextEditingController();
    _totalCtrl = TextEditingController();
    _gstinCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _totalCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (file == null) return;

      final imageFile = File(file.path);
      setState(() {
        _selectedImage = imageFile;
        _isProcessing = true;
        _extractedData = null;
      });

      // Run AI / OCR text recognition service
      final extracted = await ReceiptOcrService.processReceiptImage(imageFile);

      setState(() {
        _isProcessing = false;
        _extractedData = extracted;
        _vendorCtrl.text = extracted.vendorName.value;
        _invoiceNoCtrl.text = extracted.invoiceNumber.value;
        _totalCtrl.text = extracted.totalAmount.value.toStringAsFixed(2);
        _gstinCtrl.text = extracted.gstin.value;
      });

      AppSnackbar.showSuccess('Receipt scanned & fields extracted!');
    } catch (e) {
      setState(() => _isProcessing = false);
      AppSnackbar.showError('Failed to process receipt: $e');
    }
  }

  void _confirmAndImportInvoice() {
    if (_extractedData == null || _selectedImage == null) return;

    final updatedTotal =
        double.tryParse(_totalCtrl.text.trim()) ?? _extractedData!.totalAmount.value;

    // Update lines if user changed total
    final updatedLines = [..._extractedData!.lines];
    if (updatedLines.length == 1 && updatedTotal > 0) {
      final line = updatedLines[0];
      updatedLines[0] = line.copyWith(
        description: _vendorCtrl.text.trim().isNotEmpty
            ? '${_vendorCtrl.text.trim()} Expense'
            : line.description,
        unitPrice: updatedTotal,
      );
    }

    final finalizedData = _extractedData!.copyWith(
      vendorName: ExtractedField(value: _vendorCtrl.text.trim()),
      invoiceNumber: ExtractedField(value: _invoiceNoCtrl.text.trim()),
      gstin: ExtractedField(value: _gstinCtrl.text.trim().toUpperCase()),
      totalAmount: ExtractedField(value: updatedTotal),
      lines: updatedLines,
    );

    ref.read(invoiceFormProvider.notifier).loadFromOcr(finalizedData);
    AppSnackbar.showSuccess('Invoice pre-filled with attached receipt image!');
    widget.onInvoiceCreated();
  }

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return Scaffold(
      backgroundColor: AppColors.grey12,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Hero Banner
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.black2, AppColors.blue1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.blue4.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.document_scanner_rounded,
                            color: AppColors.blue7, size: 24.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Receipt to Invoice',
                              style: TextStyle(
                                color: AppColors.white1,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Instant AI OCR scanning with original image attachment',
                              style: TextStyle(
                                color: AppColors.blue8,
                                fontSize: 11.5.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Scan Action Buttons (Camera / Gallery)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _pickAndProcessImage(ImageSource.camera),
                      icon: Icon(Icons.camera_alt_rounded, size: 20.sp),
                      label: Text('Camera Scan',
                          style: TextStyle(
                              fontSize: 13.5.sp, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(
                    height: 52.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.blue1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _pickAndProcessImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library_rounded,
                          size: 20.sp, color: AppColors.blue1),
                      label: Text('Upload Image',
                          style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue1)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),

            // Processing State
            if (_isProcessing) ...[
              Container(
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.white1,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.grey11),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: 16.h),
                    Text(
                      'Analyzing receipt text & amounts…',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Extracting vendor, invoice number, items, and GST calculations',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12.sp, color: AppColors.grey4),
                    ),
                  ],
                ),
              ),
            ],

            // Extracted Review Stage (Phase 3 Confirmation)
            if (!_isProcessing && _extractedData != null) ...[
              Card(
                elevation: 0,
                color: AppColors.white1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: const BorderSide(color: AppColors.grey11),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Review Extracted Details',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black2,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.green1.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'OCR Parsed',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Thumbnail of scanned receipt
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            height: 120.h,
                            width: double.infinity,
                            color: AppColors.grey10,
                            child: Image.file(_selectedImage!,
                                fit: BoxFit.cover),
                          ),
                        ),
                      SizedBox(height: 14.h),

                      // Vendor Name Field with Confidence Badge
                      _fieldWithConfidence(
                        controller: _vendorCtrl,
                        label: 'Vendor / Business Name',
                        confidence: _extractedData!.vendorName.confidence,
                      ),
                      SizedBox(height: 10.h),

                      // Invoice Number Field
                      _fieldWithConfidence(
                        controller: _invoiceNoCtrl,
                        label: 'Invoice / Receipt Number',
                        confidence: _extractedData!.invoiceNumber.confidence,
                      ),
                      SizedBox(height: 10.h),

                      // GSTIN & Total Row
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _fieldWithConfidence(
                              controller: _gstinCtrl,
                              label: 'GSTIN (Optional)',
                              confidence: _extractedData!.gstin.confidence,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            flex: 5,
                            child: _fieldWithConfidence(
                              controller: _totalCtrl,
                              label: 'Total Amount (₹)',
                              confidence: _extractedData!.totalAmount.confidence,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Parsed Items List Preview
                      Text(
                        'Extracted Line Items (${_extractedData!.lines.length})',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ..._extractedData!.lines.map((item) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 6.h, horizontal: 8.w),
                          margin: EdgeInsets.only(bottom: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.grey10,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                money.format(item.total),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 18.h),

                      // Action Button
                      SizedBox(
                        height: 52.h,
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: _confirmAndImportInvoice,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(
                            'Import & Create Invoice',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Empty state placeholder
            if (!_isProcessing && _extractedData == null) ...[
              Container(
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  color: AppColors.white1,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.grey11),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 48.sp, color: AppColors.grey4),
                    SizedBox(height: 12.h),
                    Text(
                      'Ready to Scan',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Snap a physical bill or upload a voucher photo. EasyBill PRO extracts vendor, amounts, items, and tax automatically.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12.sp, color: AppColors.grey13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fieldWithConfidence({
    required TextEditingController controller,
    required String label,
    required FieldConfidence confidence,
    TextInputType? keyboardType,
  }) {
    final isHigh = confidence == FieldConfidence.high;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black2)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isHigh
                    ? AppColors.green1.withValues(alpha: 0.15)
                    : AppColors.orange2.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: Text(
                isHigh ? 'High match' : 'Verify',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: isHigh ? AppColors.green1 : AppColors.orange2,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 13.sp),
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          ),
        ),
      ],
    );
  }
}
