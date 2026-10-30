import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../../application/invoice_form_controller.dart';
import '../widgets/customer_directory_modal.dart';
import '../widgets/product_catalog_modal.dart';

class BusinessProfileTab extends ConsumerWidget {
  const BusinessProfileTab({
    super.key,
    required this.onEditBusiness,
  });

  final VoidCallback onEditBusiness;

  Future<void> _pickLogo(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file != null) {
        ref.read(invoiceFormProvider.notifier).updateBusinessLogo(file.path);
        if (context.mounted) {
          AppSnackbar.showSuccess('Business logo updated!');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError('Failed to select logo: $e');
      }
    }
  }

  void _showWatermarkDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(invoiceFormProvider);
    String type = state.watermarkType;
    final textCtrl = TextEditingController(text: state.watermarkText);
    double opacity = state.watermarkOpacity;
    String placement = state.watermarkPlacement;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Default PDF Watermark'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Watermark Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['none', 'text', 'logo'].map((t) {
                    final sel = type == t;
                    return ChoiceChip(
                      label: Text(t.toUpperCase()),
                      selected: sel,
                      onSelected: (_) => setDlgState(() => type = t),
                    );
                  }).toList(),
                ),
                if (type == 'text') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Watermark Text',
                      hintText: 'e.g. PAID, ORIGINAL, TAX INVOICE',
                    ),
                  ),
                ],
                if (type != 'none') ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Opacity',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('${(opacity * 100).toInt()}%'),
                    ],
                  ),
                  Slider(
                    value: opacity,
                    min: 0.04,
                    max: 0.30,
                    divisions: 13,
                    onChanged: (v) => setDlgState(() => opacity = v),
                  ),
                  const SizedBox(height: 8),
                  const Text('Placement',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Diagonal')),
                          selected: placement == 'diagonal',
                          onSelected: (_) => setDlgState(() => placement = 'diagonal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Center')),
                          selected: placement == 'center',
                          onSelected: (_) => setDlgState(() => placement = 'center'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(invoiceFormProvider.notifier).setWatermarkSettings(
                      type: type,
                      text: textCtrl.text.trim().toUpperCase(),
                      opacity: opacity,
                      placement: placement,
                    );
                AppSnackbar.showSuccess('Default watermark settings saved');
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceFormProvider);
    final logoPath = state.businessLogoPath;
    final hasLogo =
        logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync();

    final inr =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Identity Hero Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue1, AppColors.black2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black6.withValues(alpha: 0.18),
                      blurRadius: 16.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo Avatar with tap to upload/change
                        Stack(
                          children: [
                            InkWell(
                              onTap: () => _pickLogo(context, ref),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                width: 72.w,
                                height: 72.w,
                                decoration: BoxDecoration(
                                  color: AppColors.white1,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                      color: AppColors.whiteTransparent,
                                      width: 2),
                                ),
                                child: hasLogo
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(14.r),
                                        child: Image.file(
                                          File(logoPath),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 32.sp,
                                          color: AppColors.grey4,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.blue2,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasLogo ? Icons.edit : Icons.add,
                                  size: 12.sp,
                                  color: AppColors.white1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.whiteTransparent,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded,
                                  color: AppColors.green1, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text(
                                'EasyBill PRO SaaS',
                                style: TextStyle(
                                  color: AppColors.white1,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      state.businessName.isNotEmpty
                          ? state.businessName
                          : 'Your Business Name',
                      style: TextStyle(
                        color: AppColors.white1,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      state.businessGstin.isNotEmpty
                          ? 'GSTIN: ${state.businessGstin}'
                          : 'GSTIN: Not provided',
                      style: TextStyle(
                        color: AppColors.blue8,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      state.businessAddress.isNotEmpty
                          ? state.businessAddress
                          : 'Address: Not provided',
                      style: TextStyle(
                          color: AppColors.grey5, fontSize: 13.sp),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        const Icon(Icons.phone,
                            size: 14, color: AppColors.white1),
                        SizedBox(width: 4.w),
                        Text(
                          state.businessPhone.isNotEmpty
                              ? state.businessPhone
                              : 'No phone set',
                          style: TextStyle(
                              color: AppColors.white1, fontSize: 12.sp),
                        ),
                        SizedBox(width: 14.w),
                        const Icon(Icons.email,
                            size: 14, color: AppColors.white1),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            state.businessEmail.isNotEmpty
                                ? state.businessEmail
                                : 'No email set',
                            style: TextStyle(
                                color: AppColors.white1, fontSize: 12.sp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Directory & Catalog Shortcuts
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: AppColors.grey11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => CustomerDirectoryModal.show(context),
                      icon: const Icon(Icons.people_alt_outlined, size: 18),
                      label: Text('Customer Directory (${state.savedCustomers.length})',
                          style: TextStyle(fontSize: 12.sp, color: AppColors.black2)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: AppColors.grey11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () => ProductCatalogModal.show(context),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: Text('Product Catalog (${state.savedProducts.length})',
                          style: TextStyle(fontSize: 12.sp, color: AppColors.black2)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Bank & Payment Details Card
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
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 22.sp, color: AppColors.green1),
                          SizedBox(width: 8.w),
                          Text(
                            'Bank & Payment Details',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _infoTile(
                        'UPI ID (Instant QR)',
                        state.upiId.isEmpty ? 'Not specified' : state.upiId,
                      ),
                      _infoTile(
                        'Bank Name',
                        state.bankName.isEmpty ? 'Not specified' : state.bankName,
                      ),
                      _infoTile(
                        'Account Number',
                        state.bankAccount.isEmpty
                            ? 'Not specified'
                            : state.bankAccount,
                      ),
                      _infoTile(
                        'IFSC Code',
                        state.bankIfsc.isEmpty ? 'Not specified' : state.bankIfsc,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // PDF Watermark Card (Phase 5)
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
                          Row(
                            children: [
                              Icon(Icons.branding_watermark_rounded,
                                  size: 20.sp, color: AppColors.blue1),
                              SizedBox(width: 8.w),
                              Text(
                                'Custom PDF Watermark',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black2,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _showWatermarkDialog(context, ref),
                            child: const Text('Configure'),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Place a subtle watermark (company logo or text like PAID / ORIGINAL) behind PDF invoices.',
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.grey4),
                      ),
                      SizedBox(height: 10.h),
                      _infoTile(
                        'Status',
                        state.watermarkType == 'none'
                            ? 'Disabled'
                            : '${state.watermarkType.toUpperCase()} (${state.watermarkText})',
                      ),
                      _infoTile(
                        'Opacity',
                        '${(state.watermarkOpacity * 100).toInt()}% (${state.watermarkPlacement})',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Indian Rupee Formatting Verification Card (Phase 7)
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
                        children: [
                          Icon(Icons.currency_rupee_rounded,
                              size: 20.sp, color: AppColors.green1),
                          SizedBox(width: 8.w),
                          Text(
                            'Indian Rupee (₹) Unicode & Numbering',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'All exported PDFs, printing documents and screens use verified Unicode ₹ (U+20B9) with Indian number grouping (lakhs & crores).',
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.grey4),
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 6.h,
                        children: [
                          _currencyChip(inr.format(1000)),
                          _currencyChip(inr.format(12500)),
                          _currencyChip(inr.format(125000)),
                          _currencyChip(inr.format(1000000)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Edit Business Button
              SizedBox(
                height: 52.h,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: AppColors.white1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                  onPressed: onEditBusiness,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(
                    'Edit Business Details & Bank Info',
                    style: TextStyle(
                        fontSize: 14.5.sp, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currencyChip(String formatted) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.grey10,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.grey11),
      ),
      child: Text(
        formatted,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.black2,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey4)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black2,
            ),
          ),
        ],
      ),
    );
  }
}
