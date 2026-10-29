import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_form_controller.dart';

class Step1BusinessDetails extends ConsumerStatefulWidget {
  const Step1BusinessDetails({
    super.key,
    required this.onNext,
  });

  final VoidCallback onNext;

  @override
  ConsumerState<Step1BusinessDetails> createState() => _Step1BusinessDetailsState();
}

class _Step1BusinessDetailsState extends ConsumerState<Step1BusinessDetails> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _gstin;
  late final TextEditingController _address;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccount;
  late final TextEditingController _bankIfsc;
  late final TextEditingController _upiId;

  @override
  void initState() {
    super.initState();
    final state = ref.read(invoiceFormProvider);
    _name = TextEditingController(text: state.businessName);
    _phone = TextEditingController(text: state.businessPhone);
    _email = TextEditingController(text: state.businessEmail);
    _gstin = TextEditingController(text: state.businessGstin);
    _address = TextEditingController(text: state.businessAddress);
    _bankName = TextEditingController(text: state.bankName);
    _bankAccount = TextEditingController(text: state.bankAccount);
    _bankIfsc = TextEditingController(text: state.bankIfsc);
    _upiId = TextEditingController(text: state.upiId);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _gstin.dispose();
    _address.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _bankIfsc.dispose();
    _upiId.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(invoiceFormProvider.notifier).updateBusinessDetails(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      gstin: _gstin.text.trim().toUpperCase(),
      address: _address.text.trim(),
      bankName: _bankName.text.trim(),
      bankAccount: _bankAccount.text.trim(),
      bankIfsc: _bankIfsc.text.trim().toUpperCase(),
      upiId: _upiId.text.trim(),
    );
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    _saveData();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                _buildStepHeader(
                  stepNumber: 1,
                  title: 'Business Information',
                  subtitle: 'Enter your company or store details for the invoice header',
                  icon: Icons.storefront_rounded,
                ),
                const SizedBox(height: 18),

                // Primary Business Card
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
                            Icon(Icons.business_center_outlined, size: 20, color: AppColors.blue1),
                            SizedBox(width: 8),
                            Text(
                              'Company & Tax Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _name,
                          onChanged: (_) => _saveData(),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Business / Company Name *',
                            hintText: 'e.g. Sharma Enterprises',
                            prefixIcon: const Icon(Icons.business),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter your business name' : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phone,
                                onChanged: (_) => _saveData(),
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: '+91 98765 43210',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _email,
                                onChanged: (_) => _saveData(),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'contact@company.com',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _gstin,
                          onChanged: (_) => _saveData(),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'GSTIN / Tax ID (Optional)',
                            hintText: '29ABCDE1234F1Z5',
                            prefixIcon: const Icon(Icons.receipt_outlined),
                            helperText: '15-digit Indian GST number displayed on tax invoice',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _address,
                          onChanged: (_) => _saveData(),
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Business Address',
                            hintText: 'Shop No, Street, City, State, Pincode',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bank & Payment Collection Card
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
                            Icon(Icons.account_balance_outlined, size: 20, color: AppColors.green1),
                            SizedBox(width: 8),
                            Text(
                              'Bank & UPI Details (For Payments)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'These details will appear on the invoice for customer wire transfer & UPI payments.',
                          style: TextStyle(fontSize: 12, color: AppColors.grey4),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _upiId,
                          onChanged: (_) => _saveData(),
                          decoration: InputDecoration(
                            labelText: 'UPI ID (Google Pay / PhonePe / Paytm)',
                            hintText: 'yourbusiness@upi',
                            prefixIcon: const Icon(Icons.qr_code_2_rounded, color: AppColors.green1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _bankName,
                          onChanged: (_) => _saveData(),
                          decoration: InputDecoration(
                            labelText: 'Bank Name',
                            hintText: 'e.g. HDFC Bank / State Bank of India',
                            prefixIcon: const Icon(Icons.account_balance),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: TextFormField(
                                controller: _bankAccount,
                                onChanged: (_) => _saveData(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Account Number',
                                  hintText: '50200012345678',
                                  prefixIcon: const Icon(Icons.pin),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: TextFormField(
                                controller: _bankIfsc,
                                onChanged: (_) => _saveData(),
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'IFSC Code',
                                  hintText: 'HDFC0001234',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Next Step Button
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: AppColors.white1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Next: Invoice & Customer Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader({
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue8,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue4.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blue1,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue1.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  color: AppColors.white1,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $stepNumber of 3: $title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
