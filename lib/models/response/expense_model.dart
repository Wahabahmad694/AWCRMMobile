import '../../utils/extractor.dart';

class ExpenseCategory {
  final String id;
  final String name;

  const ExpenseCategory({required this.id, required this.name});

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Category',
      );
}

class Expense {
  final String id;
  final String categoryId;
  final String categoryName;
  final int amountPaisa;
  final DateTime? expenseDate;
  final String method;
  final String? description;
  final String? receiptReference;
  final int version;
  final bool isVoid;

  const Expense({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amountPaisa,
    this.expenseDate,
    required this.method,
    this.description,
    this.receiptReference,
    this.version = 1,
    this.isVoid = false,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] is Map ? json['category'] as Map : const {};
    DateTime? dt;
    if (json['expense_date'] != null || json['created_at'] != null) {
      try {
        dt = DateTime.parse((json['expense_date'] ?? json['created_at']).toString()).toLocal();
      } catch (_) {}
    }
    return Expense(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? cat['id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? cat['name']?.toString() ?? 'General Expense',
      amountPaisa: Extractor.asInt(json['amount_paisa']),
      expenseDate: dt,
      method: json['method']?.toString() ?? 'cash',
      description: json['description']?.toString(),
      receiptReference: json['receipt_reference']?.toString(),
      version: Extractor.asInt(json['version'], 1),
      isVoid: json['voided_at'] != null || json['is_void'] == true,
    );
  }
}
