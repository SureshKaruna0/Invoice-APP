import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_form_controller.dart';

class BusinessProfileTab extends ConsumerWidget {
  const BusinessProfileTab({
    super.key,
    required this.onEditBusiness,
  });

  final VoidCallback onEditBusiness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceFormProvider);

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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.red1,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: AppColors.white1, size: 28),
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
                      state.businessName.isEmpty ? 'Your Business' : state.businessName,
                      style: const TextStyle(
                        color: AppColors.white1,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (state.businessGstin.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'GSTIN: ${state.businessGstin}',
                        style: const TextStyle(color: AppColors.blue8, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                    if (state.businessAddress.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        state.businessAddress,
                        style: const TextStyle(color: AppColors.grey5, fontSize: 13),
                      ),
                    ],
                    if (state.businessPhone.isNotEmpty || state.businessEmail.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (state.businessPhone.isNotEmpty) ...[
                            const Icon(Icons.phone, size: 14, color: AppColors.white1),
                            const SizedBox(width: 4),
                            Text(state.businessPhone, style: const TextStyle(color: AppColors.white1, fontSize: 12)),
                            const SizedBox(width: 14),
                          ],
                          if (state.businessEmail.isNotEmpty) ...[
                            const Icon(Icons.email, size: 14, color: AppColors.white1),
                            const SizedBox(width: 4),
                            Text(state.businessEmail, style: const TextStyle(color: AppColors.white1, fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Bank & Payment QR Setup Card
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
                            'Instant Payment Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoTile('UPI ID (Payment Link)', state.upiId.isEmpty ? 'Not specified' : state.upiId),
                      _infoTile('Bank Account', state.bankAccount.isEmpty ? 'Not specified' : state.bankAccount),
                      _infoTile('IFSC Code', state.bankIfsc.isEmpty ? 'Not specified' : state.bankIfsc),
                      _infoTile('Bank Name', state.bankName.isEmpty ? 'Not specified' : state.bankName),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // EasyBill App Features & Info Card
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
                          Icon(Icons.info_outline_rounded, size: 22, color: AppColors.blue2),
                          SizedBox(width: 8),
                          Text(
                            'About EasyBill Invoicing',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _featureRow(Icons.offline_bolt_rounded, '100% Offline & Private', 'No servers or accounts required. Your data remains strictly on your device.'),
                      const SizedBox(height: 10),
                      _featureRow(Icons.calculate_outlined, 'Indian GST Compliant', 'Calculates CGST, SGST, IGST, HSN codes, discounts, and amount in words.'),
                      const SizedBox(height: 10),
                      _featureRow(Icons.share_rounded, 'Multi-Media Export', 'Export and share invoices directly as PDF or PNG image cards on WhatsApp.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reset App Data
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red1,
                  side: const BorderSide(color: AppColors.red2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset Form?'),
                      content: const Text('This will clear the current draft and generate a fresh invoice number.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.red1),
                          onPressed: () {
                            ref.read(invoiceFormProvider.notifier).completeAndResetInvoice();
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Form has been reset with a new invoice number.')),
                            );
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Current Invoice Draft'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey4)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black2)),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.blue2),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.black2)),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.grey4)),
            ],
          ),
        ),
      ],
    );
  }
}
