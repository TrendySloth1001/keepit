import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/password_generator.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final score = PasswordGenerator.strength(password);
    final color = score < 0.3
        ? AppTheme.error
        : score < 0.6
        ? AppTheme.warning
        : AppTheme.success;
    final label = score < 0.3
        ? 'Weak'
        : score < 0.6
        ? 'Fair'
        : score < 0.85
        ? 'Strong'
        : 'Excellent';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.brSm,
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.white),
                    borderRadius: AppRadius.brSm,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: score,
                  child: Container(color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          password.isEmpty ? '—' : label,
          style: TextStyle(color: color, fontSize: AppType.micro),
        ),
      ],
    );
  }
}
