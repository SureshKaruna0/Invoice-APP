import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_form_controller.dart';
import '../widgets/customer_directory_modal.dart';

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

  late String _invoiceType; // 'Cash' | 'Credit'
  late String _paymentTerms; // 'Due on Receipt', 'Net 7 Days', 'Net 15 Days', 'Net 30 Days', 'Custom'
  late DateTime _invoiceDate;
  DateTime? _dueDate;
  DateTime? _paymentDate;
  late String _paymentTime;
  late String _paymentStatus;
  late String _paymentMode;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final state = ref.read(invoiceFormProvider);
    _invoiceNumber = TextEditingController(text: state.invoiceNumber);
    _customerName = TextEditingController(text: state.customerName);
    _customerPhone = TextEditingController(text: state.customerPhone);
    _customerAddress = TextEditingController(text: state.customerAddress);
    _customerGstin = TextEditingController(text: state.customerGstin);

    _invoiceType = state.invoiceType;
    _paymentTerms = state.paymentTerms;
    _invoiceDate = state.activeInvoiceDate;
    _dueDate = state.dueDate ?? InvoiceFormController.calculateDueDate(_invoiceDate, _paymentTerms);
    _paymentDate = state.paymentDate ?? _invoiceDate;
    _paymentTime = state.paymentTime.isNotEmpty
        ? state.paymentTime
        : DateFormat('hh:mm a').format(DateTime.now());
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

  void _syncFromState(InvoiceFormState state) {
    if (_invoiceNumber.text != state.invoiceNumber) {
      _invoiceNumber.text = state.invoiceNumber;
    }
    if (_customerName.text != state.customerName) {
      _customerName.text = state.customerName;
    }
    if (_customerPhone.text != state.customerPhone) {
      _customerPhone.text = state.customerPhone;
    }
    if (_customerAddress.text != state.customerAddress) {
      _customerAddress.text = state.customerAddress;
    }
    if (_customerGstin.text != state.customerGstin) {
      _customerGstin.text = state.customerGstin;
    }
    setState(() {
      _invoiceType = state.invoiceType;
      _paymentTerms = state.paymentTerms;
      _invoiceDate = state.activeInvoiceDate;
      _dueDate = state.dueDate;
      _paymentDate = state.paymentDate;
      _paymentTime = state.paymentTime;
      _paymentStatus = state.paymentStatus;
      _paymentMode = state.paymentMode;
    });
  }

  void _saveData() {
    ref.read(invoiceFormProvider.notifier).updateInvoiceDetails(
      number: _invoiceNumber.text.trim(),
      date: _invoiceDate,
      dueDate: _dueDate,
      invoiceType: _invoiceType,
      paymentTerms: _paymentTerms,
      paymentDate: _paymentDate,
      paymentTime: _paymentTime,
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

  void _onInvoiceTypeChanged(String newType) {
    if (_invoiceType == newType) return;
    setState(() {
      _invoiceType = newType;
      if (newType == 'Cash') {
        _paymentStatus = 'Paid';
        _paymentDate ??= _invoiceDate;
        if (_paymentTime.isEmpty) {
          _paymentTime = DateFormat('hh:mm a').format(DateTime.now());
        }
        if (_paymentMode.isEmpty || _paymentMode == 'UPI / Cash') {
          _paymentMode = 'Cash';
        }
      } else {
        _paymentStatus = 'Pending';
        if (_paymentTerms.isEmpty) _paymentTerms = 'Net 15 Days';
        _dueDate = InvoiceFormController.calculateDueDate(_invoiceDate, _paymentTerms);
      }
    });
    _saveData();
  }

  void _onPaymentTermsChanged(String terms) {
    setState(() {
      _paymentTerms = terms;
      if (terms != 'Custom') {
        _dueDate = InvoiceFormController.calculateDueDate(_invoiceDate, terms);
      }
    });
    _saveData();
  }

  Future<void> _pickDate({
    required BuildContext context,
    required bool isInvoiceDate,
    bool isPaymentDate = false,
  }) async {
    final initial = isPaymentDate
        ? (_paymentDate ?? _invoiceDate)
        : (isInvoiceDate ? _invoiceDate : (_dueDate ?? _invoiceDate));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: isPaymentDate
          ? 'SELECT PAYMENT DATE'
          : (isInvoiceDate ? 'SELECT INVOICE DATE' : 'SELECT DUE DATE'),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
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
        if (isPaymentDate) {
          _paymentDate = picked;
        } else if (isInvoiceDate) {
          _invoiceDate = picked;
          if (_paymentTerms != 'Custom') {
            _dueDate = InvoiceFormController.calculateDueDate(_invoiceDate, _paymentTerms);
          } else if (_dueDate != null && _dueDate!.isBefore(_invoiceDate)) {
            _dueDate = _invoiceDate;
          }
        } else {
          // Due date
          if (picked.isBefore(_invoiceDate)) {
            _dueDate = _invoiceDate;
          } else {
            _dueDate = picked;
            _paymentTerms = 'Custom';
          }
        }
      });
      _saveData();
    }
  }

  void _setTodayDate({required bool isInvoiceDate, bool isPaymentDate = false}) {
    setState(() {
      final now = DateTime.now();
      if (isPaymentDate) {
        _paymentDate = now;
      } else if (isInvoiceDate) {
        _invoiceDate = now;
        if (_paymentTerms != 'Custom') {
          _dueDate = InvoiceFormController.calculateDueDate(_invoiceDate, _paymentTerms);
        }
      } else {
        _dueDate = now;
        _paymentTerms = 'Custom';
      }
    });
    _saveData();
  }

  Future<void> _pickPaymentTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();
    try {
      final parts = _paymentTime.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      initialTime = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
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
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() {
        _paymentTime = DateFormat('hh:mm a').format(dt);
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InvoiceFormState>(invoiceFormProvider, (prev, next) {
      if (prev?.invoiceNumber != next.invoiceNumber ||
          prev?.customerName != next.customerName ||
          prev?.customerPhone != next.customerPhone ||
          prev?.invoiceType != next.invoiceType) {
        _syncFromState(next);
      }
    });

    final isCash = _invoiceType == 'Cash';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Header
                _buildStepHeader(
                  stepNumber: 2,
                  title: 'Invoice & Customer Details',
                  subtitle: 'Specify invoice type, numbering, payment terms and client details',
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(height: 18),

                // Card 1: Invoice Type & Terms
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
                        // Card Header
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 20, color: AppColors.blue2),
                            SizedBox(width: 8),
                            Text(
                              'Invoice Meta & Payment Terms',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Professional Cash / Credit Segmented Switcher
                        _buildInvoiceTypeSegmentedControl(isCash),
                        const SizedBox(height: 18),

                        // Row 1 (Two-Column): Invoice Number & Invoice Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Column 1: Invoice Number
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _invoiceNumber,
                                onChanged: (_) => _saveData(),
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Invoice Number *',
                                  hintText: 'e.g. INV-001',
                                  prefixIcon: const Icon(Icons.tag_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Enter invoice number' : null,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Column 2: Invoice Date (with DD/MM/YYYY + Today shortcut)
                            Expanded(
                              flex: 5,
                              child: _buildDateField(
                                label: 'Invoice Date',
                                date: _invoiceDate,
                                icon: Icons.event_available_rounded,
                                onTap: () => _pickDate(
                                  context: context,
                                  isInvoiceDate: true,
                                ),
                                onToday: () => _setTodayDate(isInvoiceDate: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2 (Two-Column Dynamic): Cash Fields OR Credit Fields
                        if (isCash) ...[
                          // Cash Mode: Payment Method & Payment Date/Time
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Payment Method Dropdown
                              Expanded(
                                flex: 5,
                                child: DropdownButtonFormField<String>(
                                  initialValue: ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Cheque']
                                          .contains(_paymentMode)
                                      ? _paymentMode
                                      : 'Cash',
                                  decoration: InputDecoration(
                                    labelText: 'Payment Method',
                                    prefixIcon: const Icon(Icons.payments_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                    DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                                    DropdownMenuItem(value: 'Card', child: Text('Card (Debit/Credit)')),
                                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _paymentMode = val);
                                      _saveData();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Payment Time & Date Picker
                              Expanded(
                                flex: 5,
                                child: InkWell(
                                  onTap: () async {
                                    await _pickDate(
                                      context: context,
                                      isInvoiceDate: false,
                                      isPaymentDate: true,
                                    );
                                    if (context.mounted) {
                                      await _pickPaymentTime(context);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Paid On & Time',
                                      prefixIcon: const Icon(Icons.schedule_rounded),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.today_rounded, size: 18),
                                        tooltip: 'Set to Current Time',
                                        onPressed: () {
                                          setState(() {
                                            _paymentDate = DateTime.now();
                                            _paymentTime = DateFormat('hh:mm a').format(DateTime.now());
                                          });
                                          _saveData();
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      isDense: true,
                                    ),
                                    child: Text(
                                      '${_dateFormatter.format(_paymentDate ?? _invoiceDate)} · $_paymentTime',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Credit Mode: Payment Terms & Due Date
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Payment Terms Dropdown
                              Expanded(
                                flex: 5,
                                child: DropdownButtonFormField<String>(
                                  initialValue: [
                                    'Due on Receipt',
                                    'Net 7 Days',
                                    'Net 15 Days',
                                    'Net 30 Days',
                                    'Custom',
                                  ].contains(_paymentTerms)
                                      ? _paymentTerms
                                      : 'Net 15 Days',
                                  decoration: InputDecoration(
                                    labelText: 'Payment Terms',
                                    prefixIcon: const Icon(Icons.hourglass_top_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Due on Receipt', child: Text('Due on Receipt')),
                                    DropdownMenuItem(value: 'Net 7 Days', child: Text('Net 7 Days')),
                                    DropdownMenuItem(value: 'Net 15 Days', child: Text('Net 15 Days')),
                                    DropdownMenuItem(value: 'Net 30 Days', child: Text('Net 30 Days')),
                                    DropdownMenuItem(value: 'Custom', child: Text('Custom Due Date')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) _onPaymentTermsChanged(val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Due Date Field (with DD/MM/YYYY + Today shortcut)
                              Expanded(
                                flex: 5,
                                child: _buildDateField(
                                  label: 'Due Date',
                                  date: _dueDate ?? _invoiceDate,
                                  icon: Icons.event_busy_rounded,
                                  onTap: () => _pickDate(
                                    context: context,
                                    isInvoiceDate: false,
                                  ),
                                  onToday: () => _setTodayDate(isInvoiceDate: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Row 3: Payment Status
                        Row(
                          children: [
                            const Text(
                              'Payment Status:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Wrap(
                              spacing: 8,
                              children: ['Paid', 'Pending', 'Partial'].map((status) {
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
                                    fontSize: 12,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Customer / Client Details (Billed To)
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
                        // Header with Pick from Directory Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_pin_rounded, size: 20, color: AppColors.red1),
                                SizedBox(width: 8),
                                Text(
                                  'Customer / Client Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black2,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.blue8,
                                foregroundColor: AppColors.blue1,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                final picked = await CustomerDirectoryModal.show(context);
                                if (picked != null) {
                                  setState(() {
                                    _customerName.text = picked.name;
                                    _customerPhone.text = picked.phone;
                                    _customerAddress.text = picked.address;
                                    _customerGstin.text = picked.gstin;
                                  });
                                  _saveData();
                                }
                              },
                              icon: const Icon(Icons.contacts_rounded, size: 15),
                              label: const Text('Pick Customer'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter recipient information or pick a saved party from your directory.',
                          style: TextStyle(fontSize: 12, color: AppColors.grey4),
                        ),
                        const SizedBox(height: 16),

                        // Two-Column Row: Customer Name & Mobile / WhatsApp
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _customerName,
                                onChanged: (_) => _saveData(),
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Customer / Company Name *',
                                  hintText: 'Enter client name',
                                  prefixIcon: const Icon(Icons.person_outline_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Enter customer name' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _customerPhone,
                                onChanged: (_) => _saveData(),
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Mobile / WhatsApp',
                                  hintText: 'e.g. 9876543210',
                                  prefixIcon: const Icon(Icons.chat_rounded, color: AppColors.green1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Customer GSTIN Field
                        TextFormField(
                          controller: _customerGstin,
                          onChanged: (_) => _saveData(),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Customer GSTIN (For B2B Tax Invoices)',
                            hintText: '15-digit GSTIN (e.g. 29ABCDE1234F1Z5)',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Customer Billing Address
                        TextFormField(
                          controller: _customerAddress,
                          onChanged: (_) => _saveData(),
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Customer Billing Address (Optional)',
                            hintText: 'Shop / Street / City / Pincode',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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

  /// Professional Cash vs Credit Segmented Switcher (Zoho Books Style)
  Widget _buildInvoiceTypeSegmentedControl(bool isCash) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey11),
      ),
      child: Row(
        children: [
          // Credit Invoice Tab
          Expanded(
            child: InkWell(
              onTap: () => _onInvoiceTypeChanged('Credit'),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isCash ? AppColors.white1 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isCash
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: !isCash ? AppColors.blue1 : AppColors.grey4,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Credit Invoice',
                      style: TextStyle(
                        fontWeight: !isCash ? FontWeight.w800 : FontWeight.w600,
                        color: !isCash ? AppColors.blue1 : AppColors.grey4,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Cash Invoice Tab
          Expanded(
            child: InkWell(
              onTap: () => _onInvoiceTypeChanged('Cash'),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isCash ? AppColors.white1 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isCash
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payments_rounded,
                      size: 18,
                      color: isCash ? AppColors.green1 : AppColors.grey4,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cash Invoice',
                      style: TextStyle(
                        fontWeight: isCash ? FontWeight.w800 : FontWeight.w600,
                        color: isCash ? AppColors.green1 : AppColors.grey4,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean Date Picker Field with DD/MM/YYYY formatting and "Today" shortcut chip
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onToday,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: IconButton(
            icon: const Icon(Icons.today_rounded, size: 18),
            tooltip: 'Set to Today',
            onPressed: onToday,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        child: Text(
          _dateFormatter.format(date),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
