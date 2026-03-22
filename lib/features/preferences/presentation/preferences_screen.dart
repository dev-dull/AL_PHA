import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/features/preferences/providers/preferences_providers.dart';

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
              'Affects weekly board columns and calendar grids. '
              'New weeks will use the updated start day.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Divider(),

          // ── Categories (placeholder) ──────────────────
          const _SectionHeader(title: 'Categories'),
          ListTile(
            leading: Icon(
              Icons.category_outlined,
              color: theme.colorScheme.onSurface
                  .withValues(alpha: 0.4),
            ),
            title: Text(
              'Color-coded task categories',
              style: TextStyle(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            trailing: const Chip(
              label: Text('Coming soon'),
              visualDensity: VisualDensity.compact,
            ),
          ),
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
