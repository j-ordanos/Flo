import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Time window the analytics screen reports on.
enum AnalyticsPeriod { day, week, month }

class AnalyticsPeriodNotifier extends Notifier<AnalyticsPeriod> {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.month;

  void set(AnalyticsPeriod period) => state = period;
}

final analyticsPeriodProvider =
    NotifierProvider<AnalyticsPeriodNotifier, AnalyticsPeriod>(
  AnalyticsPeriodNotifier.new,
);
