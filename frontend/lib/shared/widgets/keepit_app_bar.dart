import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              colorFilter: ColorFilter.mode(
                Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
                BlendMode.srcIn,
              ),
            ),
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
