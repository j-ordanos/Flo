import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/shimmer_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/category_providers.dart';
import '../widgets/add_category_sheet.dart';
import '../widgets/category_avatar.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'New category',
            icon: const Icon(Icons.add),
            onPressed: () => showAddCategorySheet(context),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const ShimmerList(),
        error: (_, _) => const ErrorView(message: 'Could not load categories.'),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyView(
              icon: Icons.category_outlined,
              title: 'No categories',
              message: 'Add a category to start organising spend.',
              action: FilledButton.icon(
                onPressed: () => showAddCategorySheet(context),
                icon: const Icon(Icons.add),
                label: const Text('New category'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < categories.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 64),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        leading: CategoryAvatar(
                          iconKey: categories[i].icon,
                          colorHex: categories[i].colorHex,
                          size: 40,
                        ),
                        title: Text(categories[i].name),
                        subtitle: categories[i].isDefault
                            ? Text('Default',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.hintColor))
                            : null,
                        trailing:
                            Icon(Icons.chevron_right, color: theme.hintColor),
                        onTap: () =>
                            showAddCategorySheet(context, initial: categories[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
