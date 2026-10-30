import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_invoice_maker/app/app_colors.dart';
import 'package:quick_invoice_maker/app/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Auto navigate after 2.3 seconds using GoRouter
    _navigationTimer = Timer(const Duration(milliseconds: 2300), _proceedToApp);
  }

  void _proceedToApp() {
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue1,
      body: InkWell(
        onTap: _proceedToApp,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Stack(
          children: [
            // Ambient glowing gradient circles in background
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue2.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red1.withValues(alpha: 0.18),
                ),
              ),
            ),

            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // EasyBill Logo Symbol
                      Container(
                        width: 96.w,
                        height: 96.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.red1, AppColors.blue2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.red1.withValues(alpha: 0.4),
                              blurRadius: 28.r,
                              offset: Offset(0, 10.h),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 52.sp,
                              color: AppColors.white1,
                            ),
                            Positioned(
                              right: 12.w,
                              bottom: 12.h,
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.green1,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '₹',
                                  style: TextStyle(
                                    color: AppColors.white1,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 26.h),

                      // Brand Name
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'EasyBill',
                            style: TextStyle(
                              color: AppColors.white1,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 7.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppColors.red1,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'PRO',
                              style: TextStyle(
                                color: AppColors.white1,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Tagline
                      Text(
                        'Smart Invoicing, GST Billing & Accounting',
                        style: TextStyle(
                          color: AppColors.blue8,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 38),

                      // Animated Loading indicator
                      SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: AppColors.blue3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.blue7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom trust badge
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_outlined,
                          size: 16, color: AppColors.blue7),
                      const SizedBox(width: 6),
                      Text(
                        '100% Offline · Instant PDF & Image Export',
                        style: TextStyle(
                          color: AppColors.white1.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
