import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_snackbar.dart';
import '../application/invoice_form_controller.dart';
import '../domain/invoice_draft.dart';
import 'invoice_details_screen.dart';
import 'smart_receipt_scan_screen.dart';
import 'steps/step1_business_details.dart';
import 'steps/step2_invoice_details.dart';
import 'steps/step3_items_and_total.dart';
import 'tabs/business_profile_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/invoice_history_tab.dart';
import 'widgets/customer_directory_modal.dart';
import 'widgets/floating_bottom_nav_bar.dart';
import 'widgets/product_catalog_modal.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentTabIndex;
  int _wizardStep = 0; // 0: Business, 1: Invoice & Customer, 2: Items & Total

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentTabIndex = index);
  }

  void _openInvoiceDetails(InvoiceDraft invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailsScreen(
          invoice: invoice,
          onEditInvoice: () {
            setState(() {
              _currentTabIndex = 1;
              _wizardStep = 2;
            });
          },
          onInvoiceDeleted: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  String _getTabSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Financial Overview & KPIs';
      case 1:
        return _wizardStep == 0
            ? 'Step 1 of 3: Business Details'
            : _wizardStep == 1
                ? 'Step 2 of 3: Invoice & Customer'
                : 'Step 3 of 3: Items & Grand Total';
      case 2:
        return 'Smart Receipt AI Scanner';
      case 3:
        return 'Invoices History & Records';
      case 4:
        return 'Settings, Watermark & Rupee';
      default:
        return 'GST Billing & Invoicing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.grey12,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.white1,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.red1, AppColors.blue1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue1.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: AppColors.white1,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Text(
                      'EasyBill',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppColors.black2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.red1,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  _getTabSubtitle(_currentTabIndex),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey4,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quick New Invoice Button across all tabs
          IconButton(
            tooltip: 'New Fresh Invoice',
            onPressed: () {
              ref
                  .read(invoiceFormProvider.notifier)
                  .completeAndResetInvoice();
              setState(() {
                _currentTabIndex = 1;
                _wizardStep = 0;
              });
              AppSnackbar.showInfo('Started fresh invoice with reset fields.');
            },
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.blue1,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Screens Stack
          IndexedStack(
            index: _currentTabIndex,
            children: [
              // Screen 0: Executive Financial Dashboard
              DashboardTab(
                onCreateInvoice: () {
                  setState(() {
                    _currentTabIndex = 1;
                    _wizardStep = 0;
                  });
                },
                onScanReceipt: () {
                  setState(() => _currentTabIndex = 2);
                },
                onOpenInvoice: _openInvoiceDetails,
                onOpenInvoicesList: () {
                  setState(() => _currentTabIndex = 3);
                },
                onOpenCustomers: () => CustomerDirectoryModal.show(context),
                onOpenProducts: () => ProductCatalogModal.show(context),
              ),

              // Screen 1: Invoice Creation & Edit Wizard
              IndexedStack(
                index: _wizardStep,
                children: [
                  Step1BusinessDetails(
                    onNext: () => setState(() => _wizardStep = 1),
                  ),
                  Step2InvoiceDetails(
                    onBack: () => setState(() => _wizardStep = 0),
                    onNext: () => setState(() => _wizardStep = 2),
                  ),
                  Step3ItemsAndTotal(
                    onBack: () => setState(() => _wizardStep = 1),
                    onResetToFirstStep: () => setState(() => _wizardStep = 0),
                  ),
                ],
              ),

              // Screen 2: Smart Receipt AI Scanner (Phase 3 & 4)
              SmartReceiptScanScreen(
                onInvoiceCreated: () {
                  setState(() {
                    _currentTabIndex = 1;
                    _wizardStep = 2; // Jump to Items & Total for verification
                  });
                },
              ),

              // Screen 3: Invoices History & Filter
              InvoiceHistoryTab(
                onOpenInvoice: _openInvoiceDetails,
              ),

              // Screen 4: Business Settings, Watermark & Profile
              BusinessProfileTab(
                onEditBusiness: () {
                  setState(() {
                    _currentTabIndex = 1;
                    _wizardStep = 0;
                  });
                },
              ),
            ],
          ),

          // Floating Bottom Navigation Bar (Hidden smoothly when keyboard is open)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              offset: isKeyboardOpen ? const Offset(0, 1.8) : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isKeyboardOpen ? 0.0 : 1.0,
                child: isKeyboardOpen
                    ? const SizedBox.shrink()
                    : EasyBillFloatingNavBar(
                        currentIndex: _currentTabIndex,
                        onTap: _onTabTapped,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
