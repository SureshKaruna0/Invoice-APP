import 'package:flutter/material.dart';
import '../features/invoice/presentation/invoice_home_screen.dart';

class QuickInvoiceApp extends StatelessWidget {
  const QuickInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Quick Invoice Maker',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3659E3)),
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    home: const InvoiceHomeScreen(),
  );
}
