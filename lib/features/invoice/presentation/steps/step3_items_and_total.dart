import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_form_controller.dart';
import '../../application/number_to_words.dart';
import '../../domain/invoice_line.dart';
import '../widgets/invoice_share_bottom_sheet.dart';

class Step3ItemsAndTotal extends ConsumerStatefulWidget {
  const Step3ItemsAndTotal({
    super.key,
    required this.onBack,
    this.onResetToFirstStep,
  });

  final VoidCallback onBack;
  final VoidCallback? onResetToFirstStep;

  @override
  ConsumerState<Step3ItemsAndTotal> createState() => _Step3ItemsAndTotalState();
}

class _Step3ItemsAndTotalState extends ConsumerState<Step3ItemsAndTotal> {
  late final TextEditingController _notes;
  late final TextEditingController _terms;

  @override
  void initState() {
    super.initState();
    final state = ref.read(invoiceFormProvider);
    _notes = TextEditingController(text: state.notes);
    _terms = TextEditingController(text: state.terms);
  }

  @override
  void dispose() {
    _notes.dispose();
    _terms.dispose();
    super.dispose();
  }

  void _saveNotesAndTerms() {
    ref.read(invoiceFormProvider.notifier).updateNotesAndTerms(
          notes: _notes.text.trim(),
          terms: _terms.text.trim(),
        );
  }

  void _onPreviewAndExport() {
    final state = ref.read(invoiceFormProvider);
    if (state.lines.isEmpty) {
      _showError('Please add at least one item.');
      return;
    }
    if (state.lines.any((item) => item.description.trim().isEmpty)) {
      _showError('Please enter a description / name for every item.');
      return;
    }

    _saveNotesAndTerms();

    final draft = ref.read(invoiceFormProvider).toDraft();

    // Open the EasyBill share and export bottom sheet
    InvoiceShareBottomSheet.show(
      context,
      draft,
      onShareCompleted: () {
        ref.read(invoiceFormProvider.notifier).completeAndResetInvoice();
        if (widget.onResetToFirstStep != null) {
          widget.onResetToFirstStep!();
        } else {
          widget.onBack();
        }
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red1,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddItemDialog() {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0');
    final discCtrl = TextEditingController(text: '0');
    final hsnCtrl = TextEditingController();
    String unit = 'Pcs';
    double taxRate = 18.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Product or Service',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black2)),
                  IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Item Name / Description *',
                  hintText: 'e.g. Office Chair Ergonomic',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: hsnCtrl,
                      decoration: InputDecoration(
                        labelText: 'HSN / SAC Code',
                        hintText: 'e.g. 9403',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: DropdownButtonFormField<String>(
                      initialValue: unit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        'Pcs',
                        'Nos',
                        'Kg',
                        'Box',
                        'Meter',
                        'Set',
                        'Hour',
                        'Day'
                      ].map((u) {
                        return DropdownMenuItem(value: u, child: Text(u));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => unit = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Unit Price (₹)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: discCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Discount (₹)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('GST / Tax Rate %',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey4)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                  final isSel = taxRate == rate;
                  return ChoiceChip(
                    label: Text('${rate.toInt()}%'),
                    selected: isSel,
                    selectedColor: AppColors.blue8,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSel ? AppColors.blue3 : AppColors.black1,
                    ),
                    onSelected: (_) => setDialogState(() => taxRate = rate),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final desc = descCtrl.text.trim();
                    if (desc.isEmpty) {
                      _showError('Enter item description');
                      return;
                    }
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final disc = double.tryParse(discCtrl.text.trim()) ?? 0.0;

                    ref.read(invoiceFormProvider.notifier).addLine(
                          InvoiceLine(
                            description: desc,
                            quantity: qty,
                            unitPrice: price,
                            discount: disc,
                            taxRate: taxRate,
                            unit: unit,
                            hsnCode: hsnCtrl.text.trim(),
                          ),
                        );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add to Invoice',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.white1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final money =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Progress Indicator
              _buildStepHeader(
                stepNumber: 3,
                title: 'Items & Grand Total',
                subtitle:
                    'Add products, rates, discounts, GST, and preview invoice',
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(height: 18),

              // Items Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items List (${state.lines.length})',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black2),
                  ),
                  TextButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 18, color: AppColors.blue2),
                    label: const Text('Add Product',
                        style: TextStyle(
                            color: AppColors.blue2,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items Cards
              ...List.generate(state.lines.length, (i) {
                return _buildItemCard(i, state.lines[i], money);
              }),

              // Quick Add Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.grey14),
                      ),
                      onPressed: () =>
                          ref.read(invoiceFormProvider.notifier).addLine(),
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.black2),
                      label: const Text('Add Blank Item',
                          style: TextStyle(color: AppColors.black2)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.blue2),
                        foregroundColor: AppColors.blue2,
                      ),
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: const Text('Detailed Item',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notes & Terms Card
              Card(
                elevation: 0,
                color: AppColors.white1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.grey11),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes & Payment Terms',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black2),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notes,
                        onChanged: (_) => _saveNotesAndTerms(),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText:
                              'e.g. Dispatched with bill and warranty card',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _terms,
                        onChanged: (_) => _saveNotesAndTerms(),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Terms & Conditions',
                          hintText:
                              'e.g. 1. Goods once sold will not be taken back.',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Grand Total Summary Card
              _buildGrandTotalCard(state, money),
              const SizedBox(height: 24),

              // Navigation and Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: AppColors.grey14),
                        ),
                        onPressed: () {
                          _saveNotesAndTerms();
                          widget.onBack();
                        },
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.black2),
                        label: const Text('Back',
                            style: TextStyle(color: AppColors.black2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.red1,
                          foregroundColor: AppColors.white1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: AppColors.red1.withValues(alpha: 0.4),
                        ),
                        onPressed: _onPreviewAndExport,
                        icon: const Icon(Icons.share_rounded, size: 20),
                        label: const Text(
                          'Preview & Export',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3),
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
    );
  }

  Widget _buildItemCard(int index, InvoiceLine line, NumberFormat money) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.grey11),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.grey10,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.description.isEmpty
                        ? 'New Item ${index + 1}'
                        : line.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.black2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(invoiceFormProvider.notifier).removeLine(index),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.red1, size: 20),
                  tooltip: 'Delete item',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('desc-$index-${line.description}'),
              initialValue: line.description,
              decoration: InputDecoration(
                labelText: 'Item Name / Description *',
                hintText: 'e.g. Wireless Mouse',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onChanged: (v) {
                ref.read(invoiceFormProvider.notifier).updateLine(
                      index,
                      line.copyWith(description: v),
                    );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: ValueKey('qty-$index-${line.quantity}'),
                    initialValue: line.quantity % 1 == 0
                        ? line.quantity.toInt().toString()
                        : line.quantity.toString(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = double.tryParse(v) ?? 0.0;
                      ref.read(invoiceFormProvider.notifier).updateLine(
                            index,
                            line.copyWith(quantity: val),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    key: ValueKey('rate-$index-${line.unitPrice}'),
                    initialValue: line.unitPrice
                        .toStringAsFixed(line.unitPrice % 1 == 0 ? 0 : 2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Rate (₹)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = double.tryParse(v) ?? 0.0;
                      ref.read(invoiceFormProvider.notifier).updateLine(
                            index,
                            line.copyWith(unitPrice: val),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<double>(
                    initialValue: line.taxRate,
                    decoration: InputDecoration(
                      labelText: 'GST %',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    items: [0.0, 5.0, 12.0, 18.0, 28.0].map((r) {
                      return DropdownMenuItem(
                          value: r, child: Text('${r.toInt()}%'));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(invoiceFormProvider.notifier).updateLine(
                              index,
                              line.copyWith(taxRate: v),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  line.taxRate > 0
                      ? 'Tax: ${money.format(line.taxAmount)}'
                      : 'Tax-Free',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey4),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grey10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Total: ${money.format(line.total)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.black2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(InvoiceFormState state, NumberFormat money) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.black2, AppColors.blue1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.black6.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: AppColors.blue7, size: 22),
              SizedBox(width: 8),
              Text(
                'INVOICE CALCULATION & TOTAL',
                style: TextStyle(
                  color: AppColors.blue8,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryLine('Subtotal (Base Value)', money.format(state.subtotal)),
          if (state.totalDiscount > 0)
            _summaryLine(
                'Discount Savings', '- ${money.format(state.totalDiscount)}',
                isDiscount: true),
          if (state.totalTax > 0)
            _summaryLine('Total GST / Tax', money.format(state.totalTax)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.whiteTransparent, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                    color: AppColors.white1,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
              Text(
                money.format(state.total),
                style: const TextStyle(
                  color: AppColors.green1,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            numberToIndianWords(state.total),
            style: const TextStyle(
                color: AppColors.grey11,
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.grey11, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? AppColors.red1 : AppColors.white1,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        color: AppColors.orange1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brown3),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange2,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange2.withValues(alpha: 0.3),
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
                    color: AppColors.brown4,
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
