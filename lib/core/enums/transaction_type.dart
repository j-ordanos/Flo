/// Whether a transaction is money out ([expense]) or money in ([income]).
///
/// Stored as the enum name. Budgets, the "spent" total and analytics count
/// expenses only; income feeds the monthly income/balance figures.
enum TransactionType { expense, income }
