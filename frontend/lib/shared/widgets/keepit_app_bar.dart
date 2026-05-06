import 'package:flutter/material.dart';

import 'keepit_logo.dart';

class KeepItAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  const KeepItAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeepItLogo(
            size: 32,
            foregroundColor:
                Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
            showBackground: false,
          ),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
