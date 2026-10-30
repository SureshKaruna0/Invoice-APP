import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../../application/invoice_form_controller.dart';
import '../../domain/invoice_draft.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({
    super.key,
    required this.onCreateInvoice,
    required this.onScanReceipt,
    required this.onOpenInvoice,
    required this.onOpenInvoicesList,
    required this.onOpenCustomers,
    required this.onOpenProducts,
  });

  final VoidCallback onCreateInvoice;
  final VoidCallback onScanReceipt;
  final ValueChanged<InvoiceDraft> onOpenInvoice;
  final VoidCallback onOpenInvoicesList;
  final VoidCallback onOpenCustomers;
  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 1 Performance: granular selector on savedInvoices
    final savedInvoices =
        ref.watch(invoiceFormProvider.select((s) => s.savedInvoices));
    final businessName =
        ref.watch(invoiceFormProvider.select((s) => s.businessName));

    final money =
        NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy');

    double totalBilled = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;

    for (final inv in savedInvoices) {
      totalBilled += inv.total;
      if (inv.paymentStatus.toLowerCase() == 'paid') {
        totalPaid += inv.total;
      } else {
        totalPending += inv.total;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.grey12,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Executive Welcome Card (Zoho Books Quality)
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.black2, AppColors.blue1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black6.withValues(alpha: 0.15),
                    blurRadius: 14.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        businessName.isNotEmpty ? businessName : 'EasyBill Mart',
                        style: TextStyle(
                          color: AppColors.white1,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.red1,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            color: AppColors.white1,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Financial Dashboard & Billing Overview',
                    style: TextStyle(
                      color: AppColors.blue8,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          label: 'TOTAL BILLED',
                          value: money.format(totalBilled),
                          color: AppColors.white1,
                          badgeColor: AppColors.blue7,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _metricCard(
                          label: 'COLLECTED',
                          value: money.format(totalPaid),
                          color: AppColors.green1,
                          badgeColor: AppColors.green1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _metricCard(
                    label: 'RECEIVABLES / PENDING',
                    value: money.format(totalPending),
                    color: AppColors.orange2,
                    badgeColor: AppColors.orange2,
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // Quick Actions Bar
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.black2,
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.add_rounded,
                    label: 'New Invoice',
                    color: AppColors.blue1,
                    onTap: onCreateInvoice,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _actionButton(
                    icon: Icons.document_scanner_rounded,
                    label: 'Scan Receipt',
                    color: AppColors.red1,
                    onTap: onScanReceipt,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _actionButton(
                    icon: Icons.people_alt_outlined,
                    label: 'Customers',
                    color: AppColors.black4,
                    onTap: onOpenCustomers,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _actionButton(
                    icon: Icons.inventory_2_outlined,
                    label: 'Catalog',
                    color: AppColors.green3,
                    onTap: onOpenProducts,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Recent Invoices Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Invoices (${savedInvoices.length})',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black2,
                  ),
                ),
                if (savedInvoices.isNotEmpty)
                  TextButton(
                    onPressed: onOpenInvoicesList,
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue2,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),

            // Invoices List / Empty State
            if (savedInvoices.isEmpty) ...[
              Container(
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.white1,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.grey11),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 40.sp, color: AppColors.grey4),
                    SizedBox(height: 10.h),
                    Text(
                      'No Invoices Generated Yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black2,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Create your first GST invoice or scan an existing physical receipt to get started.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12.sp, color: AppColors.grey13),
                    ),
                    SizedBox(height: 14.h),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      onPressed: onCreateInvoice,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create New Invoice'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: savedInvoices.length > 5 ? 5 : savedInvoices.length,
                itemBuilder: (context, index) {
                  final inv = savedInvoices[index];
                  final isPaid = inv.paymentStatus.toLowerCase() == 'paid';
                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.only(bottom: 8.h),
                    color: AppColors.white1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: const BorderSide(color: AppColors.grey11),
                    ),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                      onTap: () => onOpenInvoice(inv),
                      title: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.grey10,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              inv.invoiceNumber,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black1,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColors.green1.withValues(alpha: 0.15)
                                  : AppColors.orange2.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              inv.paymentStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: isPaid
                                    ? AppColors.green1
                                    : AppColors.orange2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          '${inv.customerName.isEmpty
                                  ? 'Customer'
                                  : inv.customerName} · ${dateFormat.format(inv.invoiceDate)}',
                          style: TextStyle(
                              fontSize: 11.5.sp, color: AppColors.grey13),
                        ),
                      ),
                      trailing: Text(
                        money.format(inv.total),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required Color color,
    required Color badgeColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.white1.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.blue8,
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: AppColors.white1,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey11),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18.sp, color: color),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.black2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
