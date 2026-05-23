import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../../categories/domain/entities/category.dart';
import '../domain/entities/expense.dart';

/// Builds a CSV of expenses and opens the system share sheet.
class CsvExportService {
  const CsvExportService();

  Future<void> exportExpenses(
    List<Expense> expenses,
    Map<String, Category> categoriesById,
  ) async {
    final rows = <List<dynamic>>[
      const ['Date', 'Category', 'Merchant', 'Note', 'Amount'],
      for (final e in expenses)
        [
          e.date.toIso8601String(),
          categoriesById[e.categoryId]?.name ?? '',
          e.merchant ?? '',
          e.note ?? '',
          (e.amountCents / 100).toStringAsFixed(2),
        ],
    ];
    final csvString = Csv().encode(rows);
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(csvString)),
      mimeType: 'text/csv',
      name: 'flo_expenses.csv',
    );
    await SharePlus.instance.share(ShareParams(files: [file]));
  }
}
