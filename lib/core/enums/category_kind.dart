/// Whether a category is used for spending ([expense]) or earning ([income]).
///
/// The add-transaction picker shows only categories matching the selected
/// [TransactionType], so income and expense each get their own set.
enum CategoryKind { expense, income }
