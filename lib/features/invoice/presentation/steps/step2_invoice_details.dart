import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_form_controller.dart';

class Step2InvoiceDetails extends ConsumerStatefulWidget {
  const Step2InvoiceDetails({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<Step2InvoiceDetails> createState() => _Step2InvoiceDetailsState();
}

class _Step2InvoiceDetailsState extends ConsumerState<Step2InvoiceDetails> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _invoiceNumber;
  late final TextEditingController _customerName;
  late final TextEditingController _customerPhone;
  late final TextEditingController _customerAddress;
  late final TextEditingController _customerGstin;

  late DateTime _invoiceDate;
  DateTime? _dueDate;
  late String _paymentStatus;
  late String _paymentMode;

  @override
  void initState() {
    super.initState();
    final state = ref.read(invoiceFormProvider);
    _invoiceNumber = TextEditingController(text: state.invoiceNumber);
    _customerName = TextEditingController(text: state.customerName);
    _customerPhone = TextEditingController(text: state.customerPhone);
    _customerAddress = TextEditingController(text: state.customerAddress);
    _customerGstin = TextEditingController(text: state.customerGstin);

    _invoiceDate = state.activeInvoiceDate;
    _dueDate = state.dueDate ?? _invoiceDate.add(const Duration(days: 15));
    _paymentStatus = state.paymentStatus;
    _paymentMode = state.paymentMode;
  }

  @override
  void dispose() {
    _invoiceNumber.dispose();
    _customerName.dispose();
    _customerPhone.dispose();
    _customerAddress.dispose();
    _customerGstin.dispose();
    super.dispose();
  }

  void _saveData() {
    ref.read(invoiceFormProvider.notifier).updateInvoiceDetails(
      number: _invoiceNumber.text.trim(),
      date: _invoiceDate,
      dueDate: _dueDate,
      customerName: _customerName.text.trim(),
      customerPhone: _customerPhone.text.trim(),
      customerAddress: _customerAddress.text.trim(),
      customerGstin: _customerGstin.text.trim().toUpperCase(),
      paymentStatus: _paymentStatus,
      paymentMode: _paymentMode,
    );
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    _saveData();
    widget.onNext();
  }

  Future<void> _pickDate({required bool isInvoiceDate}) async {
    final initial = isInvoiceDate ? _invoiceDate : (_dueDate ?? _invoiceDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.blue1,
              onPrimary: AppColors.white1,
              surface: AppColors.white1,
              onSurface: AppColors.black2,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
          if (_dueDate != null && _dueDate!.isBefore(_invoiceDate)) {
            _dueDate = _invoiceDate.add(const Duration(days: 15));
          }
        } else {
          _dueDate = picked;
        }
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

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
                  stepNumber: 2,
                  title: 'Invoice & Customer Details',
                  subtitle: 'Specify invoice numbering, dates, and client information',
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(height: 18),

                // Invoice Identifiers & Dates Card
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
                            Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.blue2),
                            SizedBox(width: 8),
                            Text(
                              'Invoice Meta & Terms',
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
                          controller: _invoiceNumber,
                          onChanged: (_) => _saveData(),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Invoice Number *',
                            hintText: 'e.g. INV-2026-001',
                            prefixIcon: const Icon(Icons.tag_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter invoice number' : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(isInvoiceDate: true),
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Invoice Date',
                                    prefixIcon: const Icon(Icons.event_available),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    dateFormat.format(_invoiceDate),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(isInvoiceDate: false),
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Due Date',
                                    prefixIcon: const Icon(Icons.event_busy),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    _dueDate != null ? dateFormat.format(_dueDate!) : 'Upon Receipt',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment Status Chips
                        const Text(
                          'Payment Status',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey2),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Pending', 'Paid', 'Partial'].map((status) {
                            final isSel = _paymentStatus == status;
                            return ChoiceChip(
                              label: Text(status),
                              selected: isSel,
                              selectedColor: status == 'Paid'
                                  ? AppColors.green2
                                  : status == 'Pending'
                                      ? AppColors.brown3
                                      : AppColors.blue8,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? (status == 'Paid'
                                        ? AppColors.green3
                                        : status == 'Pending'
                                            ? AppColors.orange2
                                            : AppColors.blue1)
                                    : AppColors.grey2,
                              ),
                              onSelected: (_) {
                                setState(() => _paymentStatus = status);
                                _saveData();
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer (Billed To) Card
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
                            Icon(Icons.person_pin_rounded, size: 20, color: AppColors.red1),
                            SizedBox(width: 8),
                            Text(
                              'Customer / Party Details (Billed To)',
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
                          'Enter the client details who will receive this invoice and payment request.',
                          style: TextStyle(fontSize: 12, color: AppColors.grey4),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _customerName,
                          onChanged: (_) => _saveData(),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Customer / Client Name *',
                            hintText: 'e.g. Ramesh Kumar / Kaveri Traders',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter customer name' : null,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _customerPhone,
                          onChanged: (_) => _saveData(),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Customer Mobile / WhatsApp Number',
                            hintText: '+91 98765 00000',
                            prefixIcon: const Icon(Icons.chat_rounded, color: AppColors.green1),
                            helperText: 'Used for direct WhatsApp invoice dispatch',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _customerAddress,
                          onChanged: (_) => _saveData(),
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Customer Billing Address (Optional)',
                            hintText: 'Plot / Flat, Street, City, State',
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _customerGstin,
                          onChanged: (_) => _saveData(),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Customer GSTIN (For B2B Invoices)',
                            hintText: '29ABCDE5678F1Z2',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation Buttons Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: AppColors.grey14),
                          ),
                          onPressed: () {
                            _saveData();
                            widget.onBack();
                          },
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.black2),
                          label: const Text('Back', style: TextStyle(color: AppColors.black2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: SizedBox(
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
                            'Next: Items & Total',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
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
