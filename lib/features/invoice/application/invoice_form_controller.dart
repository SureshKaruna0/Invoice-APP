import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/invoice_draft.dart';
import '../domain/invoice_line.dart';

final invoiceFormProvider =
    StateNotifierProvider<InvoiceFormController, InvoiceFormState>(
  (ref) => InvoiceFormController(),
);

class InvoiceFormState {
  const InvoiceFormState({
    this.businessLogoPath,
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessEmail = '',
    this.businessGstin = '',
    this.bankName = '',
    this.bankAccount = '',
    this.bankIfsc = '',
    this.upiId = '',
    this.customerName = '',
    this.customerAddress = '',
    this.customerPhone = '',
    this.customerGstin = '',
    this.invoiceNumber = 'INV-001',
    this.invoiceDate,
    this.dueDate,
    this.paymentStatus = 'Pending',
    this.paymentMode = 'UPI / Cash',
    this.notes = '',
    this.terms = '',
    this.currentStep = 0,
    this.lines = const [
      InvoiceLine(
        id: 'line_initial_1',
        description: '',
        quantity: 1,
        unitPrice: 0.0,
      ),
    ],
    this.savedInvoices = const [],
  });

  final String? businessLogoPath;
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String businessGstin;

  final String bankName;
  final String bankAccount;
  final String bankIfsc;
  final String upiId;

  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String customerGstin;

  final String invoiceNumber;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final String paymentStatus;
  final String paymentMode;

  final String notes;
  final String terms;
  final int currentStep; // 0: Business, 1: Invoice & Customer, 2: Items & Total
  final List<InvoiceLine> lines;
  final List<InvoiceDraft> savedInvoices;

  DateTime get activeInvoiceDate => invoiceDate ?? DateTime.now();

  double get subtotal => lines.fold(0.0, (sum, line) => sum + line.baseAmount);
  double get totalDiscount =>
      lines.fold(0.0, (sum, line) => sum + line.discount);
  double get taxableAmount =>
      lines.fold(0.0, (sum, line) => sum + line.discountedAmount);
  double get totalTax => lines.fold(0.0, (sum, line) => sum + line.taxAmount);
  double get total => lines.fold(0.0, (sum, line) => sum + line.total);

  InvoiceDraft toDraft() => InvoiceDraft(
        businessLogoPath: businessLogoPath,
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        businessEmail: businessEmail,
        businessGstin: businessGstin,
        customerName: customerName,
        customerAddress: customerAddress,
        customerPhone: customerPhone,
        customerGstin: customerGstin,
        invoiceNumber: invoiceNumber,
        invoiceDate: activeInvoiceDate,
        dueDate: dueDate,
        paymentStatus: paymentStatus,
        paymentMode: paymentMode,
        bankName: bankName,
        bankAccount: bankAccount,
        bankIfsc: bankIfsc,
        upiId: upiId,
        lines: lines,
        notes: notes,
        terms: terms,
      );

  InvoiceFormState copyWith({
    String? businessLogoPath,
    bool clearLogo = false,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? businessGstin,
    String? bankName,
    String? bankAccount,
    String? bankIfsc,
    String? upiId,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    String? customerGstin,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? paymentStatus,
    String? paymentMode,
    String? notes,
    String? terms,
    int? currentStep,
    List<InvoiceLine>? lines,
    List<InvoiceDraft>? savedInvoices,
  }) {
    return InvoiceFormState(
      businessLogoPath:
          clearLogo ? null : (businessLogoPath ?? this.businessLogoPath),
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      businessGstin: businessGstin ?? this.businessGstin,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      upiId: upiId ?? this.upiId,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      customerGstin: customerGstin ?? this.customerGstin,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      currentStep: currentStep ?? this.currentStep,
      lines: lines ?? this.lines,
      savedInvoices: savedInvoices ?? this.savedInvoices,
    );
  }
}

class InvoiceFormController extends StateNotifier<InvoiceFormState> {
  InvoiceFormController()
      : super(InvoiceFormState(
          invoiceDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 15)),
        ));

  void setStep(int step) {
    if (step >= 0 && step <= 2) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateBusinessLogo(String? path) {
    if (path == null) {
      state = state.copyWith(clearLogo: true);
    } else {
      state = state.copyWith(businessLogoPath: path);
    }
  }

  void updateBusinessDetails({
    String? logoPath,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? gstin,
    String? bankName,
    String? bankAccount,
    String? bankIfsc,
    String? upiId,
  }) {
    state = state.copyWith(
      businessLogoPath: logoPath,
      businessName: name,
      businessAddress: address,
      businessPhone: phone,
      businessEmail: email,
      businessGstin: gstin,
      bankName: bankName,
      bankAccount: bankAccount,
      bankIfsc: bankIfsc,
      upiId: upiId,
    );
  }

  void updateInvoiceDetails({
    String? number,
    DateTime? date,
    DateTime? dueDate,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    String? customerGstin,
    String? paymentStatus,
    String? paymentMode,
  }) {
    state = state.copyWith(
      invoiceNumber: number,
      invoiceDate: date,
      dueDate: dueDate,
      customerName: customerName,
      customerAddress: customerAddress,
      customerPhone: customerPhone,
      customerGstin: customerGstin,
      paymentStatus: paymentStatus,
      paymentMode: paymentMode,
    );
  }

  void updateNotesAndTerms({String? notes, String? terms}) {
    state = state.copyWith(
      notes: notes,
      terms: terms,
    );
  }

  void addLine([InvoiceLine? line]) {
    final uniqueId = 'line_${DateTime.now().microsecondsSinceEpoch}';
    final lineToAdd = line != null
        ? (line.id.isEmpty ? line.copyWith(id: uniqueId) : line)
        : InvoiceLine(
            id: uniqueId,
            description: '',
            quantity: 1,
            unitPrice: 0.0,
          );
    state = state.copyWith(lines: [
      ...state.lines,
      lineToAdd,
    ]);
  }

  void updateLine(int index, InvoiceLine line) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = [...state.lines];
    final existingId = updated[index].id;
    final finalized = (line.id.isEmpty && existingId.isNotEmpty)
        ? line.copyWith(id: existingId)
        : line;
    updated[index] = finalized;
    state = state.copyWith(lines: updated);
  }

  void removeLine(int index) {
    if (state.lines.length <= 1) return;
    final updated = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: updated);
  }

  void saveCurrentInvoiceToHistory() {
    final draft = state.toDraft();
    final existingIndex = state.savedInvoices
        .indexWhere((e) => e.invoiceNumber == draft.invoiceNumber);
    List<InvoiceDraft> updated;
    if (existingIndex >= 0) {
      updated = [...state.savedInvoices];
      updated[existingIndex] = draft;
    } else {
      updated = [draft, ...state.savedInvoices];
    }
    state = state.copyWith(savedInvoices: updated);
  }

  void completeAndResetInvoice() {
    saveCurrentInvoiceToHistory();
    final nextNumber =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    state = state.copyWith(
      invoiceNumber: nextNumber,
      customerName: '',
      customerAddress: '',
      customerPhone: '',
      customerGstin: '',
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 15)),
      paymentStatus: 'Pending',
      currentStep: 0,
      lines: [
        InvoiceLine(
          id: 'line_${DateTime.now().microsecondsSinceEpoch}',
          description: '',
          quantity: 1,
          unitPrice: 0.0,
        ),
      ],
      notes: '',
      terms: '',
    );
  }

  void loadInvoice(InvoiceDraft draft) {
    state = state.copyWith(
      businessLogoPath: draft.businessLogoPath,
      businessName: draft.businessName,
      businessAddress: draft.businessAddress,
      businessPhone: draft.businessPhone,
      businessEmail: draft.businessEmail,
      businessGstin: draft.businessGstin,
      customerName: draft.customerName,
      customerAddress: draft.customerAddress,
      customerPhone: draft.customerPhone,
      customerGstin: draft.customerGstin,
      invoiceNumber: draft.invoiceNumber,
      invoiceDate: draft.invoiceDate,
      dueDate: draft.dueDate,
      paymentStatus: draft.paymentStatus,
      paymentMode: draft.paymentMode,
      bankName: draft.bankName,
      bankAccount: draft.bankAccount,
      bankIfsc: draft.bankIfsc,
      upiId: draft.upiId,
      lines: draft.lines,
      notes: draft.notes,
      terms: draft.terms,
      currentStep: 0,
    );
  }

  void reset() {
    final nextNumber =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    state = state.copyWith(
      invoiceNumber: nextNumber,
      customerName: '',
      customerAddress: '',
      customerPhone: '',
      customerGstin: '',
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 15)),
      paymentStatus: 'Pending',
      currentStep: 0,
      lines: const [
        InvoiceLine(description: '', quantity: 1, unitPrice: 0),
      ],
      notes: '',
      terms: '',
    );
  }
}
