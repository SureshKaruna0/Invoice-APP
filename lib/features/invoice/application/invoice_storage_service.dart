import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/customer_model.dart';
import '../domain/invoice_draft.dart';
import '../domain/product_model.dart';

class InvoiceStorageService {
  static const String _keyInvoices = 'easybill_saved_invoices_v1';
  static const String _keyCustomers = 'easybill_customers_v1';
  static const String _keyProducts = 'easybill_products_v1';
  static const String _keyBusinessProfile = 'easybill_business_profile_v1';

  /// Save Invoices List
  static Future<void> saveInvoices(List<InvoiceDraft> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = invoices.map((i) => i.toJson()).toList();
    await prefs.setString(_keyInvoices, jsonEncode(jsonList));
  }

  /// Load Invoices List
  static Future<List<InvoiceDraft>> loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyInvoices);
    if (str == null || str.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => InvoiceDraft.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save Customers
  static Future<void> saveCustomers(List<CustomerModel> customers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = customers.map((c) => c.toJson()).toList();
    await prefs.setString(_keyCustomers, jsonEncode(jsonList));
  }

  /// Load Customers
  static Future<List<CustomerModel>> loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyCustomers);
    if (str == null || str.isEmpty) {
      // Default demo customer for smooth immediate UX
      return [
        const CustomerModel(
          id: 'cust_1',
          name: 'Sharma Enterprises',
          phone: '+91 98765 43210',
          email: 'sharma@enterprises.in',
          address: '42 MG Road, Bangalore, Karnataka',
          gstin: '29ABCDE1234F1Z5',
        ),
        const CustomerModel(
          id: 'cust_2',
          name: 'Patel & Co',
          phone: '+91 98220 12345',
          email: 'accounts@patelandco.com',
          address: 'Shop 12, Ring Road Market, Surat, Gujarat',
          gstin: '24AAAAA0000A1Z5',
        ),
      ];
    }
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save Products
  static Future<void> saveProducts(List<ProductModel> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = products.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProducts, jsonEncode(jsonList));
  }

  /// Load Products
  static Future<List<ProductModel>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyProducts);
    if (str == null || str.isEmpty) {
      // Default sample catalog
      return [
        const ProductModel(
          id: 'prod_1',
          name: 'Professional Consulting / Service',
          unitPrice: 2500.0,
          unit: 'Hour',
          taxRate: 18.0,
          hsnCode: '998311',
        ),
        const ProductModel(
          id: 'prod_2',
          name: 'Web & Mobile App Development',
          unitPrice: 15000.0,
          unit: 'Set',
          taxRate: 18.0,
          hsnCode: '998314',
        ),
        const ProductModel(
          id: 'prod_3',
          name: 'Software License Annual Subscription',
          unitPrice: 4999.0,
          unit: 'Nos',
          taxRate: 18.0,
          hsnCode: '997331',
        ),
      ];
    }
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save Business Profile
  static Future<void> saveBusinessProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBusinessProfile, jsonEncode(profile));
  }

  /// Load Business Profile
  static Future<Map<String, dynamic>?> loadBusinessProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyBusinessProfile);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

