import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';

class EasyBillFloatingNavBar extends StatelessWidget {
  const EasyBillFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // 5 items corresponding to modern financial app workflow:
    // 0: Dashboard (Financial KPIs & Recent Invoices)
    // 1: Create / Edit Wizard (Step 1, 2, 3)
    // 2: Smart Receipt Scan (AI OCR & Original Receipt Attachment)
    // 3: Invoices History (Filter, Search, Details)
    // 4: Settings & Profile (Business details, Watermark, Catalog, Indian Rupee)
    final items = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      _NavItem(
        icon: Icons.add_circle_outline_rounded,
        activeIcon: Icons.add_circle_rounded,
        label: 'Create',
      ),
      _NavItem(
        icon: Icons.document_scanner_outlined,
        activeIcon: Icons.document_scanner_rounded,
        label: 'Scan OCR',
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Invoices',
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];

    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
        height: 60.h,
        decoration: BoxDecoration(
          color: AppColors.black2, // Sleek dark slate pill as in user image
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black6.withValues(alpha: 0.35),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
            BoxShadow(
              color: AppColors.blue2.withValues(alpha: 0.12),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
          border: Border.all(
            color: AppColors.white1.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = currentIndex == index;
            final item = items[index];

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(24.r),
                splashColor: AppColors.white1.withValues(alpha: 0.1),
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top active indicator bar (as seen in the user screenshot)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 14.w : 0,
                      height: 3.h,
                      margin: EdgeInsets.only(bottom: 4.h),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.blue7 : Colors.transparent,
                        borderRadius: BorderRadius.circular(2.r),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.blue7.withValues(alpha: 0.6),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 1.h),
                                ),
                              ]
                            : null,
                      ),
                    ),

                    // Icon
                    Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 22.sp,
                      color: isSelected ? AppColors.white1 : AppColors.grey4,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
