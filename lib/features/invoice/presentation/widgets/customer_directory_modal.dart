import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../../application/invoice_form_controller.dart';
import '../../domain/customer_model.dart';

class CustomerDirectoryModal extends ConsumerStatefulWidget {
  const CustomerDirectoryModal({
    super.key,
    this.onCustomerSelected,
  });

  final ValueChanged<CustomerModel>? onCustomerSelected;

  static Future<CustomerModel?> show(BuildContext context) {
    return showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomerDirectoryModal(
        onCustomerSelected: (c) => Navigator.pop(ctx, c),
      ),
    );
  }

  @override
  ConsumerState<CustomerDirectoryModal> createState() =>
      _CustomerDirectoryModalState();
}

class _CustomerDirectoryModalState
    extends ConsumerState<CustomerDirectoryModal> {
  final TextEditingController _searchCtrl = TextEditingController();

  void _showAddCustomerDialog([CustomerModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final gstinCtrl = TextEditingController(text: existing?.gstin ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer / Business Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Billing Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gstinCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'GSTIN (Optional)'),
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
              if (name.isEmpty) {
                AppSnackbar.showError('Please enter customer name');
                return;
              }
              final cust = CustomerModel(
                id: existing?.id ?? 'cust_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                gstin: gstinCtrl.text.trim().toUpperCase(),
              );
              ref.read(invoiceFormProvider.notifier).saveCustomer(cust);
              AppSnackbar.showSuccess('Customer saved');
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers =
        ref.watch(invoiceFormProvider.select((s) => s.savedCustomers));
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.contains(query) ||
          c.gstin.toLowerCase().contains(query);
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
          // Drag handle
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
                'Customer Directory',
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
                onPressed: () => _showAddCustomerDialog(),
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
              hintText: 'Search by name, phone, or GSTIN…',
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
                      'No customers found',
                      style: TextStyle(color: AppColors.grey4, fontSize: 13.sp),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.only(bottom: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          side: const BorderSide(color: AppColors.grey11),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (widget.onCustomerSelected != null) {
                              widget.onCustomerSelected!(c);
                            }
                          },
                          title: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (c.phone.isNotEmpty) c.phone,
                              if (c.gstin.isNotEmpty) 'GSTIN: ${c.gstin}',
                              if (c.address.isNotEmpty) c.address,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.grey13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showAddCustomerDialog(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.red1),
                                onPressed: () {
                                  ref
                                      .read(invoiceFormProvider.notifier)
                                      .deleteCustomer(c.id);
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
