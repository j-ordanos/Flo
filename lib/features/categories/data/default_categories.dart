import '../../../core/enums/category_kind.dart';

/// A category created for every new user on first run.
class DefaultCategory {
  const DefaultCategory(this.name, this.icon, this.colorHex,
      {this.kind = CategoryKind.expense});

  final String name;
  final String icon; // icon key resolved by the UI registry
  final String colorHex; // RRGGBB
  final CategoryKind kind;
}

/// The seven default expense categories from the Flo design tokens.
const List<DefaultCategory> kDefaultCategories = [
  DefaultCategory('Food', 'food', 'F59E0B'),
  DefaultCategory('Transport', 'transport', '3B82F6'),
  DefaultCategory('Shopping', 'shopping', 'EC4899'),
  DefaultCategory('Health', 'health', '10B981'),
  DefaultCategory('Entertainment', 'entertainment', '8B5CF6'),
  DefaultCategory('Bills', 'bills', 'EF4444'),
  DefaultCategory('Other', 'other', '64748B'),
];

/// Default income categories, seeded alongside the expense ones.
const List<DefaultCategory> kDefaultIncomeCategories = [
  DefaultCategory('Salary', 'salary', '10B981', kind: CategoryKind.income),
  DefaultCategory('Freelance', 'freelance', '06B6D4',
      kind: CategoryKind.income),
  DefaultCategory('Business', 'business', '8B5CF6', kind: CategoryKind.income),
  DefaultCategory('Investment', 'investment', 'F59E0B',
      kind: CategoryKind.income),
  DefaultCategory('Gift', 'gift_income', 'EC4899', kind: CategoryKind.income),
  DefaultCategory('Other', 'other', '64748B', kind: CategoryKind.income),
];

/// All defaults (expense + income), used by seeding.
const List<DefaultCategory> kAllDefaultCategories = [
  ...kDefaultCategories,
  ...kDefaultIncomeCategories,
];
