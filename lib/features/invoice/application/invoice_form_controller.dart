import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/invoice_line.dart';

final invoiceFormProvider =
    StateNotifierProvider<InvoiceFormController, InvoiceFormState>(
  (ref) => InvoiceFormController(),
);

class InvoiceFormState {
  const InvoiceFormState({
    this.lines = const [
      InvoiceLine(description: 'Product / Service', quantity: 1, unitPrice: 0),
    ],
  });

  final List<InvoiceLine> lines;
  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  InvoiceFormState copyWith({List<InvoiceLine>? lines}) =>
      InvoiceFormState(lines: lines ?? this.lines);
}

class InvoiceFormController extends StateNotifier<InvoiceFormState> {
  InvoiceFormController() : super(const InvoiceFormState());

  void reset() => state = const InvoiceFormState();

  void addLine() => state = state.copyWith(lines: [
    ...state.lines,
    const InvoiceLine(description: '', quantity: 1, unitPrice: 0),
  ]);

  void updateLine(int index, InvoiceLine line) {
    final updated = [...state.lines];
    updated[index] = line;
    state = state.copyWith(lines: updated);
  }

  void removeLine(int index) {
    if (state.lines.length <= 1) return;
    final updated = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: updated);
  }
}
