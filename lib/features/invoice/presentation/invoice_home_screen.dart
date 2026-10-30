import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../application/invoice_form_controller.dart';
import '../application/invoice_pdf_service.dart';
import '../domain/invoice_draft.dart';
import '../domain/invoice_line.dart';

class InvoiceHomeScreen extends ConsumerStatefulWidget {
  const InvoiceHomeScreen({super.key});

  @override
  ConsumerState<InvoiceHomeScreen> createState() => _InvoiceHomeScreenState();
}

class _InvoiceHomeScreenState extends ConsumerState<InvoiceHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _businessAddress = TextEditingController();
  final _customer = TextEditingController();
  final _customerAddress = TextEditingController();
  final _number = TextEditingController(text: 'INV-001');
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_business, _businessAddress, _customer, _customerAddress, _number, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _export() async {
    if (!_formKey.currentState!.validate()) return;
    final state = ref.read(invoiceFormProvider);
    if (state.lines.any((e) => e.description.trim().isEmpty)) {
      AppSnackbar.showError('Enter a description for every item.');
      return;
    }
    setState(() => _busy = true);
    try {
      await InvoicePdfService.preview(InvoiceDraft(
        businessName: _business.text.trim(),
        businessAddress: _businessAddress.text.trim(),
        customerName: _customer.text.trim(),
        customerAddress: _customerAddress.text.trim(),
        invoiceNumber: _number.text.trim(),
        invoiceDate: _date,
        lines: state.lines,
        notes: _notes.text.trim(),
      ));
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError('PDF creation failed: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final money = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Invoice Maker', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(
          tooltip: 'Reset',
          onPressed: () {
            _business.clear(); _businessAddress.clear(); _customer.clear();
            _customerAddress.clear(); _number.text = 'INV-001'; _notes.clear();
            setState(() => _date = DateTime.now());
            ref.read(invoiceFormProvider.notifier).reset();
          },
          icon: const Icon(Icons.refresh_rounded),
        ), const SizedBox(width: 8)],
      ),
      body: SafeArea(child: Form(
        key: _formKey,
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;
          final sections = <Widget>[
            _heading('Your business', 'Details displayed on the invoice', Icons.storefront_outlined),
            _field(_business, 'Business name', required: false, icon: Icons.business_outlined),
            const SizedBox(height: 10),
            _field(_businessAddress, 'Business address (optional)', required: false, icon: Icons.location_on_outlined),
            const SizedBox(height: 22),
            _heading('Invoice details', 'Invoice number, date and customer', Icons.receipt_long_outlined),
            _field(_number, 'Invoice number', icon: Icons.tag),
            const SizedBox(height: 10),
            InkWell(onTap: _pickDate, child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Invoice date', prefixIcon: Icon(Icons.calendar_month_outlined)),
              child: Text(DateFormat('dd MMM yyyy').format(_date)),
            )),
            const SizedBox(height: 10),
            _field(_customer, 'Customer name', icon: Icons.person_outline),
            const SizedBox(height: 10),
            _field(_customerAddress, 'Customer address (optional)', required: false, icon: Icons.home_outlined),
            const SizedBox(height: 22),
            _heading('Items', 'Add products or services', Icons.inventory_2_outlined),
            ...List.generate(state.lines.length, (i) => _lineEditor(i, state.lines[i], money)),
            OutlinedButton.icon(
              onPressed: () => ref.read(invoiceFormProvider.notifier).addLine(),
              icon: const Icon(Icons.add), label: const Text('Add item'),
            ),
            const SizedBox(height: 18),
            _field(_notes, 'Notes (optional)', required: false, icon: Icons.notes, maxLines: 3),
            const SizedBox(height: 18),
            _total(state.subtotal, money),
            const SizedBox(height: 18),
            SizedBox(height: 54, child: FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_busy ? 'Preparing PDF…' : 'Preview & Export PDF'),
            )),
            const SizedBox(height: 14),
            const Text('Offline app · No account or server required · Save or share from the system print dialog',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF687086))),
          ];
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 16, vertical: 18),
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(children: sections.take(9).toList())),
                    const SizedBox(width: 24),
                    Expanded(child: Column(children: sections.skip(9).toList())),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections),
            )),
          );
        }),
      )),
    );
  }

  Widget _heading(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF687086))),
      ])),
    ]),
  );

  Widget _field(TextEditingController c, String label, {bool required = true, IconData? icon, int maxLines = 1}) =>
    TextFormField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon)),
      validator: required ? (v) => v == null || v.trim().isEmpty ? 'Please enter $label' : null : null,
    );

  Widget _lineEditor(int index, InvoiceLine line, NumberFormat money) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
      Row(children: [
        Expanded(child: Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(onPressed: () => ref.read(invoiceFormProvider.notifier).removeLine(index),
          icon: const Icon(Icons.delete_outline), tooltip: 'Remove item'),
      ]),
      TextFormField(
        key: ValueKey('desc-$index'),
        initialValue: line.description,
        decoration: const InputDecoration(labelText: 'Product / service'),
        onChanged: (v) => _updateLine(index, v, line.quantity, line.unitPrice),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(
          key: ValueKey('qty-$index'),
          initialValue: line.quantity.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Quantity'),
          onChanged: (v) => _updateLine(index, line.description, double.tryParse(v) ?? 0, line.unitPrice),
        )),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(
          key: ValueKey('price-$index'),
          initialValue: line.unitPrice.toStringAsFixed(2),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Unit price (₹)'),
          onChanged: (v) => _updateLine(index, line.description, line.quantity, double.tryParse(v) ?? 0),
        )),
      ]),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: Text('Amount: ${money.format(line.total)}',
        style: const TextStyle(fontWeight: FontWeight.w700))),
    ])),
  );

  void _updateLine(int index, String description, double quantity, double price) =>
    ref.read(invoiceFormProvider.notifier).updateLine(index,
      InvoiceLine(description: description, quantity: quantity, unitPrice: price));

  Widget _total(double amount, NumberFormat money) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF3659E3), Color(0xFF2439A6)]),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(children: [
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INVOICE TOTAL', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
        SizedBox(height: 6),
        Text('Subtotal / Grand total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ])),
      Text(money.format(amount), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
    ]),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date,
      firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null && mounted) setState(() => _date = picked);
  }
}
