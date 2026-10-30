import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../../application/invoice_form_controller.dart';
import '../../domain/product_model.dart';

class ProductCatalogModal extends ConsumerStatefulWidget {
  const ProductCatalogModal({
    super.key,
    this.onProductSelected,
  });

  final ValueChanged<ProductModel>? onProductSelected;

  static Future<ProductModel?> show(BuildContext context) {
    return showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductCatalogModal(
        onProductSelected: (p) => Navigator.pop(ctx, p),
      ),
    );
  }

  @override
  ConsumerState<ProductCatalogModal> createState() =>
      _ProductCatalogModalState();
}

class _ProductCatalogModalState extends ConsumerState<ProductCatalogModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  final money =
      NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

  void _showAddProductDialog([ProductModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null ? existing.unitPrice.toString() : '');
    final hsnCtrl = TextEditingController(text: existing?.hsnCode ?? '');
    String unit = existing?.unit ?? 'Pcs';
    double taxRate = existing?.taxRate ?? 18.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(existing == null ? 'Add Item / Service' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Product / Service Name *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Unit Price (₹) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: ['Pcs', 'Nos', 'Kg', 'Box', 'Meter', 'Hour', 'Set']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDlgState(() => unit = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: hsnCtrl,
                        decoration:
                            const InputDecoration(labelText: 'HSN / SAC Code'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<double>(
                        initialValue: taxRate,
                        decoration: const InputDecoration(labelText: 'GST %'),
                        items: [0.0, 5.0, 12.0, 18.0, 28.0]
                            .map((r) => DropdownMenuItem(
                                value: r, child: Text('${r.toInt()}%')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDlgState(() => taxRate = v);
                        },
                      ),
                    ),
                  ],
                ),
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
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                if (name.isEmpty) {
                  AppSnackbar.showError('Please enter item name');
                  return;
                }
                final prod = ProductModel(
                  id: existing?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  unitPrice: price,
                  unit: unit,
                  taxRate: taxRate,
                  hsnCode: hsnCtrl.text.trim(),
                );
                ref.read(invoiceFormProvider.notifier).saveProduct(prod);
                AppSnackbar.showSuccess('Product saved to catalog');
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
  Widget build(BuildContext context) {
    final products =
        ref.watch(invoiceFormProvider.select((s) => s.savedProducts));
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.hsnCode.toLowerCase().contains(query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.white1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey5,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Products & Services Catalog',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black2,
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                ),
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Search Bar
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search products by name or HSN…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 12.h),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No products in catalog',
                      style: TextStyle(color: AppColors.grey4, fontSize: 13.sp),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.only(bottom: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          side: const BorderSide(color: AppColors.grey11),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (widget.onProductSelected != null) {
                              widget.onProductSelected!(p);
                            }
                          },
                          title: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${money.format(p.unitPrice)} / ${p.unit} · ${p.taxRate.toInt()}% GST${p.hsnCode.isNotEmpty ? ' · HSN: ${p.hsnCode}' : ''}',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.grey13,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showAddProductDialog(p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.red1),
                                onPressed: () {
                                  ref
                                      .read(invoiceFormProvider.notifier)
                                      .deleteProduct(p.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
