import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/password_generator.dart';
import '../../../../shared/widgets/app_button.dart';

Future<String?> showPasswordGenerator(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.black,
    builder: (_) => const _GeneratorSheet(),
  );
}

class _GeneratorSheet extends StatefulWidget {
  const _GeneratorSheet();

  @override
  State<_GeneratorSheet> createState() => _GeneratorSheetState();
}

class _GeneratorSheetState extends State<_GeneratorSheet> {
  PasswordGenOptions _opts = const PasswordGenOptions();
  String _value = '';

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() => _value = PasswordGenerator.generate(_opts));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generate password',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: AppType.subtitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.white),
                borderRadius: AppRadius.brMd,
              ),
              child: Text(
                _value,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontFamily: 'monospace',
                  fontSize: AppType.body,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Length: ${_opts.length}',
                  style: const TextStyle(color: AppTheme.white),
                ),
                Expanded(
                  child: Slider(
                    value: _opts.length.toDouble(),
                    min: 8,
                    max: 64,
                    divisions: 56,
                    onChanged: (v) {
                      setState(
                        () => _opts = _opts.copyWith(length: v.toInt()),
                      );
                      _regenerate();
                    },
                  ),
                ),
              ],
            ),
            _toggle('Lowercase', _opts.lower, (v) {
              setState(() => _opts = _opts.copyWith(lower: v));
              _regenerate();
            }),
            _toggle('Uppercase', _opts.upper, (v) {
              setState(() => _opts = _opts.copyWith(upper: v));
              _regenerate();
            }),
            _toggle('Digits', _opts.digits, (v) {
              setState(() => _opts = _opts.copyWith(digits: v));
              _regenerate();
            }),
            _toggle('Symbols', _opts.symbols, (v) {
              setState(() => _opts = _opts.copyWith(symbols: v));
              _regenerate();
            }),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Regenerate',
                    icon: Icons.refresh,
                    variant: AppButtonVariant.secondary,
                    onPressed: _regenerate,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Use this',
                    icon: Icons.check,
                    onPressed: () => Navigator.of(context).pop(_value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: AppTheme.white)),
      value: value,
      onChanged: onChanged,
    );
  }
}
