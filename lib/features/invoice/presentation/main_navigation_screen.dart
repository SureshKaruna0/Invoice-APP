import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import '../application/invoice_form_controller.dart';
import 'steps/step1_business_details.dart';
import 'steps/step2_invoice_details.dart';
import 'steps/step3_items_and_total.dart';
import 'tabs/business_profile_tab.dart';
import 'tabs/invoice_history_tab.dart';
import 'widgets/floating_bottom_nav_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentTabIndex = index);
  }

  String _getTabSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Step 1: Business Details';
      case 1:
        return 'Step 2: Invoice & Customer';
      case 2:
        return 'Step 3: Items & Grand Total';
      case 3:
        return 'Invoices History & Records';
      case 4:
        return 'Business Profile & Settings';
      default:
        return 'GST Invoice & Billing';
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
              setState(() => _currentTabIndex = 0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Started fresh invoice with reset fields.'),
                  duration: Duration(seconds: 2),
                ),
              );
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
              // Screen 0: Business Details (Step 1)
              Step1BusinessDetails(
                onNext: () => setState(() => _currentTabIndex = 1),
              ),

              // Screen 1: Invoice Details (Step 2)
              Step2InvoiceDetails(
                onBack: () => setState(() => _currentTabIndex = 0),
                onNext: () => setState(() => _currentTabIndex = 2),
              ),

              // Screen 2: Items & Total (Step 3)
              Step3ItemsAndTotal(
                onBack: () => setState(() => _currentTabIndex = 1),
                onResetToFirstStep: () => setState(() => _currentTabIndex = 0),
              ),

              // Screen 3: Invoices History
              InvoiceHistoryTab(
                onOpenInvoice: (inv) {
                  ref.read(invoiceFormProvider.notifier).loadInvoice(inv);
                  setState(() => _currentTabIndex = 2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loaded ${inv.invoiceNumber} into editor.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Screen 4: EasyBill Profile & Settings
              BusinessProfileTab(
                onEditBusiness: () => setState(() => _currentTabIndex = 0),
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
