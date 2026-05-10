import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import 'folder_icons.dart';

class FolderEditResult {
  const FolderEditResult({required this.name, required this.iconKey});
  final String name;
  final String? iconKey;
}

/// Bottom sheet used for both creating a new folder and renaming/recoloring
/// an existing one. The form has a name field and a grid of icon options so
/// the user can pick a visual badge for the folder.
Future<FolderEditResult?> showFolderEditSheet(
  BuildContext context, {
  String? initialName,
  String? initialIconKey,
  String title = 'New folder',
  String confirm = 'Create',
}) {
  return showModalBottomSheet<FolderEditResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FolderEditSheet(
      title: title,
      confirm: confirm,
      initialName: initialName ?? '',
      initialIconKey: initialIconKey ?? 'folder',
    ),
  );
}

class _FolderEditSheet extends StatefulWidget {
  const _FolderEditSheet({
    required this.title,
    required this.confirm,
    required this.initialName,
    required this.initialIconKey,
  });

  final String title;
  final String confirm;
  final String initialName;
  final String initialIconKey;

  @override
  State<_FolderEditSheet> createState() => _FolderEditSheetState();
}

class _FolderEditSheetState extends State<_FolderEditSheet> {
  late final TextEditingController _nameCtrl;
  late String _iconKey;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _iconKey = widget.initialIconKey;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      FolderEditResult(name: name, iconKey: _iconKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FolderGlyph(
                    iconKey: _iconKey,
                    size: 44,
                    foreground: cs.primary,
                    innerColor: cs.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Folder name',
                  hintText: 'Office, Workplace, Entertainment…',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose an icon',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 56,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: kFolderIcons.length,
                itemBuilder: (_, i) {
                  final opt = kFolderIcons[i];
                  final selected = opt.key == _iconKey;
                  return InkWell(
                    onTap: () => setState(() => _iconKey = opt.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Tooltip(
                      message: opt.label,
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer
                              : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? cs.primary : Colors.transparent,
                            width: 1.6,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          opt.icon,
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(widget.confirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
