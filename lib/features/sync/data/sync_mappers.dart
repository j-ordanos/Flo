import '../../../core/database/app_database.dart';
import '../../../core/enums/budget_period.dart';
import '../../../core/enums/sync_status.dart';
import '../../../core/enums/transaction_type.dart';

/// Drift row ⇄ Supabase JSON. `sync_status` is local-only and never sent.
/// Pulled rows are marked [SyncStatus.synced].

const syncTables = ['categories', 'expenses', 'budgets'];

DateTime _dt(dynamic v) => DateTime.parse(v as String).toUtc();
DateTime? _dtN(dynamic v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();
String _iso(DateTime d) => d.toUtc().toIso8601String();

// ── Expenses ──
Map<String, dynamic> expenseToJson(ExpenseRow r) => {
      'id': r.id,
      'user_id': r.userId,
      'amount_cents': r.amountCents,
      'type': r.type.name,
      'category_id': r.categoryId,
      'merchant': r.merchant,
      'note': r.note,
      'receipt_path': r.receiptPath,
      'date': _iso(r.date),
      'created_at': _iso(r.createdAt),
      'updated_at': _iso(r.updatedAt),
      'deleted_at': r.deletedAt == null ? null : _iso(r.deletedAt!),
    };

ExpenseRow expenseFromJson(Map<String, dynamic> m) => ExpenseRow(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      amountCents: (m['amount_cents'] as num).toInt(),
      type: TransactionType.values.byName(m['type'] as String? ?? 'expense'),
      categoryId: m['category_id'] as String,
      merchant: m['merchant'] as String?,
      note: m['note'] as String?,
      receiptPath: m['receipt_path'] as String?,
      date: _dt(m['date']),
      createdAt: _dt(m['created_at']),
      updatedAt: _dt(m['updated_at']),
      deletedAt: _dtN(m['deleted_at']),
      syncStatus: SyncStatus.synced,
    );

// ── Categories ──
Map<String, dynamic> categoryToJson(CategoryRow r) => {
      'id': r.id,
      'user_id': r.userId,
      'name': r.name,
      'icon': r.icon,
      'color_hex': r.colorHex,
      'kind': r.kind.name,
      'is_default': r.isDefault,
      'created_at': _iso(r.createdAt),
      'updated_at': _iso(r.updatedAt),
      'deleted_at': r.deletedAt == null ? null : _iso(r.deletedAt!),
    };

CategoryRow categoryFromJson(Map<String, dynamic> m) => CategoryRow(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      name: m['name'] as String,
      icon: m['icon'] as String,
      colorHex: m['color_hex'] as String,
      kind: CategoryKind.values.byName(m['kind'] as String? ?? 'expense'),
      isDefault: m['is_default'] as bool? ?? false,
      createdAt: _dt(m['created_at']),
      updatedAt: _dt(m['updated_at']),
      deletedAt: _dtN(m['deleted_at']),
      syncStatus: SyncStatus.synced,
    );

// ── Budgets ──
Map<String, dynamic> budgetToJson(BudgetRow r) => {
      'id': r.id,
      'user_id': r.userId,
      'category_id': r.categoryId,
      'limit_cents': r.limitCents,
      'period': r.period.name,
      'created_at': _iso(r.createdAt),
      'updated_at': _iso(r.updatedAt),
      'deleted_at': r.deletedAt == null ? null : _iso(r.deletedAt!),
    };

BudgetRow budgetFromJson(Map<String, dynamic> m) => BudgetRow(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      categoryId: m['category_id'] as String,
      limitCents: (m['limit_cents'] as num).toInt(),
      period: BudgetPeriod.values.byName(m['period'] as String),
      createdAt: _dt(m['created_at']),
      updatedAt: _dt(m['updated_at']),
      deletedAt: _dtN(m['deleted_at']),
      syncStatus: SyncStatus.synced,
    );
