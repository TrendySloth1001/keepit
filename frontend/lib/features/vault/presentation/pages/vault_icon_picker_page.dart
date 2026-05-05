import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../data/icon_catalog.dart';

/// Full-screen searchable icon picker. Pops with the selected `iconKey`.
class VaultIconPickerPage extends StatefulWidget {
  const VaultIconPickerPage({super.key, this.initial});

  final String? initial;

  @override
  State<VaultIconPickerPage> createState() => _VaultIconPickerPageState();
}

class _VaultIconPickerPageState extends State<VaultIconPickerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _query = '';
  late String? _selected;

  static const _tabs = [
    null,
    IconGroup.cloud,
    IconGroup.dev,
    IconGroup.finance,
    IconGroup.social,
    IconGroup.entertainment,
    IconGroup.productivity,
    IconGroup.shopping,
    IconGroup.travel,
    IconGroup.generic,
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = _tabs[_tab.index];
    final results = IconCatalog.search(_query, group: group);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Choose an icon'),
        actions: [
          TextButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
            child: const Text('Use'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search 100+ icons',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppTheme.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppTheme.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.fg,
                  unselectedLabelColor: AppTheme.muted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.w500),
                  tabs: _tabs
                      .map((g) => Tab(text: g == null ? 'All' : g.label))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: results.isEmpty
          ? _empty()
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: results.length,
              itemBuilder: (_, i) {
                final c = results[i];
                final isSelected = c.key == _selected;
                return _IconCell(
                  icon: c,
                  selected: isSelected,
                  onTap: () => setState(() => _selected = c.key),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SizedBox(
            height: AppLayout.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _selected == null
                    ? 'Pick an icon'
                    : 'Use ${IconCatalog.resolve(_selected).label}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.muted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No icons match "$_query"',
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      );
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final CatalogIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.short,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.hairline,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VaultIcon(iconKey: icon.key, size: 44),
              const SizedBox(height: 6),
              Text(
                icon.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
