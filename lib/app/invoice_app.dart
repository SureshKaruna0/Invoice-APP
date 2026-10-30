import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';
import 'app_router.dart';
import 'app_snackbar.dart';

class QuickInvoiceApp extends StatefulWidget {
  const QuickInvoiceApp({super.key});

  @override
  State<QuickInvoiceApp> createState() => _QuickInvoiceAppState();
}

class _QuickInvoiceAppState extends State<QuickInvoiceApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'EasyBill Invoice Maker',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: AppColors.lightColorScheme,
            scaffoldBackgroundColor: AppColors.grey12,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.white1,
              foregroundColor: AppColors.black2,
              elevation: 0,
            ),
            cardTheme: const CardThemeData(
              color: AppColors.white1,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.white1,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.blue2, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
