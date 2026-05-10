import 'package:flutter/material.dart';

/// Catalog of pickable folder icons. The string keys are stored on the server
/// (`iconKey`) so they must remain stable; only add new keys, never rename.
class FolderIconOption {
  const FolderIconOption(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

const kFolderIcons = <FolderIconOption>[
  FolderIconOption('folder', 'Folder', Icons.folder_rounded),
  FolderIconOption('work', 'Work', Icons.work_rounded),
  FolderIconOption('briefcase', 'Office', Icons.business_center_rounded),
  FolderIconOption('school', 'School', Icons.school_rounded),
  FolderIconOption('home', 'Home', Icons.home_rounded),
  FolderIconOption('family', 'Family', Icons.family_restroom_rounded),
  FolderIconOption('person', 'Personal', Icons.person_rounded),
  FolderIconOption('finance', 'Finance', Icons.account_balance_rounded),
  FolderIconOption('card', 'Cards', Icons.credit_card_rounded),
  FolderIconOption('shopping', 'Shopping', Icons.shopping_bag_rounded),
  FolderIconOption('travel', 'Travel', Icons.flight_takeoff_rounded),
  FolderIconOption('entertainment', 'Entertainment', Icons.movie_rounded),
  FolderIconOption('music', 'Music', Icons.music_note_rounded),
  FolderIconOption('games', 'Games', Icons.sports_esports_rounded),
  FolderIconOption('health', 'Health', Icons.favorite_rounded),
  FolderIconOption('fitness', 'Fitness', Icons.fitness_center_rounded),
  FolderIconOption('cloud', 'Cloud', Icons.cloud_rounded),
  FolderIconOption('server', 'Servers', Icons.dns_rounded),
  FolderIconOption('code', 'Code', Icons.code_rounded),
  FolderIconOption('lock', 'Security', Icons.lock_rounded),
  FolderIconOption('key', 'Keys', Icons.vpn_key_rounded),
  FolderIconOption('book', 'Notes', Icons.menu_book_rounded),
  FolderIconOption('star', 'Favorites', Icons.star_rounded),
  FolderIconOption('gift', 'Gifts', Icons.card_giftcard_rounded),
];

IconData folderIconFor(String? key) {
  if (key == null) return Icons.folder_rounded;
  for (final o in kFolderIcons) {
    if (o.key == key) return o.icon;
  }
  return Icons.folder_rounded;
}

/// Renders a folder silhouette with the chosen [iconKey] nested inside, the
/// way Mac Finder shows category folders (folder shape + glyph badge). Falls
/// back to a plain folder shape if [iconKey] is null or `'folder'`.
class FolderGlyph extends StatelessWidget {
  const FolderGlyph({
    super.key,
    required this.iconKey,
    this.size = 36,
    this.background,
    this.foreground,
    this.innerColor,
  });

  final String? iconKey;
  final double size;

  /// Background of the rounded square containing the folder.
  final Color? background;

  /// Color of the folder silhouette and the inner glyph.
  final Color? foreground;

  /// Color of the inner glyph (defaults to [foreground]).
  final Color? innerColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = foreground ?? cs.primary;
    final inner = innerColor ?? cs.onPrimary;
    final showInner = iconKey != null && iconKey != 'folder';
    final children = <Widget>[
      Icon(Icons.folder_rounded, size: size, color: fg),
      if (showInner)
        // Nudge the inner glyph down into the body of the folder shape (the
        // Material folder icon's body sits below its tab).
        Padding(
          padding: EdgeInsets.only(top: size * 0.18),
          child: Icon(
            folderIconFor(iconKey),
            size: size * 0.42,
            color: inner,
          ),
        ),
    ];
    final stack = SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: children),
    );
    if (background == null) return stack;
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular((size + 8) * 0.26),
      ),
      alignment: Alignment.center,
      child: stack,
    );
  }
}
