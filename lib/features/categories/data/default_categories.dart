/// A category created for every new user on first run.
class DefaultCategory {
  const DefaultCategory(this.name, this.icon, this.colorHex);

  final String name;
  final String icon; // icon key resolved by the UI registry
  final String colorHex; // RRGGBB
}

/// The seven default categories from the design spec.
const List<DefaultCategory> kDefaultCategories = [
  DefaultCategory('Food', 'food', 'F59E0B'),
  DefaultCategory('Transport', 'transport', '3B82F6'),
  DefaultCategory('Shopping', 'shopping', 'EC4899'),
  DefaultCategory('Health', 'health', 'EF4444'),
  DefaultCategory('Entertainment', 'entertainment', '8B5CF6'),
  DefaultCategory('Bills', 'bills', '10B981'),
  DefaultCategory('Other', 'other', '6B7280'),
];
