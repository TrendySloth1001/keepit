import 'dart:async';

import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';

class SafeClipboard {
  SafeClipboard._();
  static Timer? _wipeTimer;

  /// Copies text and schedules a wipe so a copied password does not linger
  /// in the system clipboard indefinitely.
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _wipeTimer?.cancel();
    _wipeTimer = Timer(AppDurations.clipboardLifetime, () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
}
