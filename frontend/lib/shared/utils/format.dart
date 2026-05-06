String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String formatRelativeTime(DateTime then) {
  final delta = DateTime.now().difference(then);
  if (delta.inSeconds < 60) return 'just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  if (delta.inDays < 30) return '${(delta.inDays / 7).floor()}w ago';
  if (delta.inDays < 365) return '${(delta.inDays / 30).floor()}mo ago';
  return '${(delta.inDays / 365).floor()}y ago';
}

/// Compact countdown until [target]. Returns "Expired" once the moment has
/// passed so callers can render a single string without branching.
String formatCountdown(DateTime target) {
  final delta = target.difference(DateTime.now());
  if (delta.isNegative) return 'Expired';
  if (delta.inDays >= 1) {
    final days = delta.inDays;
    final hours = delta.inHours - days * 24;
    return hours == 0 ? '${days}d' : '${days}d ${hours}h';
  }
  if (delta.inHours >= 1) {
    final hours = delta.inHours;
    final mins = delta.inMinutes - hours * 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
  }
  if (delta.inMinutes >= 1) return '${delta.inMinutes}m';
  return '${delta.inSeconds}s';
}
