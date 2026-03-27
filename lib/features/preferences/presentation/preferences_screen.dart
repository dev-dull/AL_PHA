import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';
import 'package:alpha/features/tag/domain/tag.dart';
import 'package:alpha/features/tag/domain/tag_palette.dart';
import 'package:alpha/features/tag/providers/tag_providers.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Font ──────────────────────────────────────
          const _SectionHeader(title: 'Font'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'PatrickHand',
                  label: Text('Handwritten'),
                ),
                ButtonSegment(
                  value: '',
                  label: Text('System'),
                ),
              ],
              selected: {prefs.fontFamily ?? ''},
              onSelectionChanged: (s) {
                final v = s.first;
                notifier.update(
                  prefs.copyWith(
                    fontFamily: v.isEmpty ? null : v,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          const Divider(),

          // ── Appearance ────────────────────────────────
          const _SectionHeader(title: 'Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('System')),
                ButtonSegment(value: 1, label: Text('Light')),
                ButtonSegment(value: 2, label: Text('Dark')),
              ],
              selected: {prefs.themeModeIndex},
              onSelectionChanged: (s) => notifier
                  .update(prefs.copyWith(themeModeIndex: s.first)),
            ),
          ),
          const SizedBox(height: 16),

          const Divider(),

          // ── First day of week ─────────────────────────
          const _SectionHeader(title: 'First Day of Week'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: DateTime.monday,
                  label: Text('Monday'),
                ),
                ButtonSegment(
                  value: DateTime.sunday,
                  label: Text('Sunday'),
                ),
              ],
              selected: {prefs.firstDayOfWeek},
              onSelectionChanged: (s) => notifier
                  .update(prefs.copyWith(firstDayOfWeek: s.first)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Affects calendar overviews and new weekly boards. '
              'Existing boards keep their original column layout.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Divider(),

          // ── Tags ─────────────────────────────────────
          const _SectionHeader(title: 'Tags'),
          _TagManagementSection(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TagManagementSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(tagListProvider);
    final actions = ref.read(tagActionsProvider);

    return tagsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e'),
      ),
      data: (tags) => Column(
        children: [
          for (final tag in tags)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: TagPalette.colorFromValue(tag.color),
                radius: 12,
              ),
              title: Text(tag.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(context, actions, tag),
              ),
              onTap: () => _showTagDialog(
                context,
                actions,
                tags.length,
                existing: tag,
              ),
            ),
          if (tags.length < TagActions.maxTags)
            ListTile(
              leading: Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Add Tag',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              subtitle: Text(
                '${tags.length}/${TagActions.maxTags}',
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => _showTagDialog(
                context,
                actions,
                tags.length,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TagActions actions,
    Tag tag,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Delete "${tag.name}"? It will be removed from all tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await actions.delete(tag.id);
  }

  Future<void> _showTagDialog(
    BuildContext context,
    TagActions actions,
    int currentCount, {
    Tag? existing,
  }) async {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    var selectedColor =
        existing?.color ?? TagPalette.colors.first.value;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Tag' : 'New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tag name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TagPalette.colors.map((c) {
                  final isSelected = c.value == selectedColor;
                  return GestureDetector(
                    onTap: () => setDialogState(
                        () => selectedColor = c.value),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c.value),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurface,
                                width: 2.5,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(existing != null ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;
      if (existing != null) {
        await actions.update(
          existing.copyWith(name: name, color: selectedColor),
        );
      } else {
        await actions.create(name: name, color: selectedColor);
      }
    }
    nameCtrl.dispose();
  }
}
