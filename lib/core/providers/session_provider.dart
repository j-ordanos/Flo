import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Owner id for local data. Overridden by the authenticated user's id in P5;
/// until then everything belongs to [kLocalUserId].
final currentUserIdProvider = Provider<String>((ref) => kLocalUserId);
