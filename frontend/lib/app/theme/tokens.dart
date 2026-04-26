import 'package:flutter/widgets.dart';

/// Spacing scale. Use these constants instead of magic numbers.
/// Step = 4 px so values compose predictably.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets page = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}

class AppIconSize {
  AppIconSize._();
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double huge = 48;
}

class AppType {
  AppType._();
  static const double display = 32;
  static const double title = 22;
  static const double subtitle = 18;
  static const double body = 14;
  static const double caption = 12;
  static const double micro = 11;
}

class AppDurations {
  AppDurations._();
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 400);

  /// Idle time before the vault auto-locks.
  static const Duration autoLock = Duration(minutes: 3);

  /// Time after which a copied password is wiped from the clipboard.
  static const Duration clipboardLifetime = Duration(seconds: 30);
}

class AppLayout {
  AppLayout._();
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double appBarHeight = 56;
  static const double fabSize = 56;
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;
  static const double dividerThickness = 1;
}
