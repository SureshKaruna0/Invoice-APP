import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../../application/invoice_form_controller.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceFormProvider);
    final logoPath = state.businessLogoPath;
    final hasLogo = logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Identity Hero Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue1, AppColors.black2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black6.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.white1,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.whiteTransparent, width: 2),
                                ),
                                child: hasLogo
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          File(logoPath),
                                          fit: BoxFit.cover,
                                          width: 72,
                                          height: 72,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.blue1,
                                          size: 34,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: InkWell(
                                onTap: () => _pickLogo(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.red1,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: AppColors.white1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white1,
                            side: const BorderSide(color: AppColors.whiteTransparent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: onEditBusiness,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Info'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.businessName.isEmpty ? 'Your Business Name' : state.businessName,
                      style: const TextStyle(
                        color: AppColors.white1,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.businessGstin.isNotEmpty
                          ? 'GSTIN: ${state.businessGstin}'
                          : 'GSTIN: Not provided',
                      style: const TextStyle(
                        color: AppColors.blue8,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.businessAddress.isNotEmpty
                          ? state.businessAddress
                          : 'Address: Not provided',
                      style: const TextStyle(color: AppColors.grey5, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: AppColors.white1),
                        const SizedBox(width: 4),
                        Text(
                          state.businessPhone.isNotEmpty ? state.businessPhone : 'No phone set',
                          style: const TextStyle(color: AppColors.white1, fontSize: 12),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.email, size: 14, color: AppColors.white1),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            state.businessEmail.isNotEmpty ? state.businessEmail : 'No email set',
                            style: const TextStyle(color: AppColors.white1, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _pickLogo(context, ref),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload_file_rounded, size: 14, color: AppColors.blue8),
                          const SizedBox(width: 4),
                          Text(
                            hasLogo ? 'Change Business Logo' : 'Upload Business Logo',
                            style: const TextStyle(
                              color: AppColors.blue8,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Bank & Payment Details Card
              Card(
                elevation: 0,
                color: AppColors.white1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.grey11),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 22, color: AppColors.green1),
                          SizedBox(width: 8),
                          Text(
                            'Bank & Payment Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoTile(
                        'UPI ID (Payment Link)',
                        state.upiId.isEmpty ? 'Not specified' : state.upiId,
                      ),
                      _infoTile(
                        'Bank Name',
                        state.bankName.isEmpty ? 'Not specified' : state.bankName,
                      ),
                      _infoTile(
                        'Account Number',
                        state.bankAccount.isEmpty ? 'Not specified' : state.bankAccount,
                      ),
                      _infoTile(
                        'IFSC Code',
                        state.bankIfsc.isEmpty ? 'Not specified' : state.bankIfsc,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Direct Button to Edit Business Information
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: AppColors.white1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  onPressed: onEditBusiness,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text(
                    'Edit Business Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey4)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.black2,
            ),
          ),
        ],
      ),
    );
  }
}
