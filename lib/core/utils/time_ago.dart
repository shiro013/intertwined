/// "just now", "5m ago", "3h ago", "2d ago", lalu tanggal biasa.
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final t = time.toLocal();
  return '${t.day}/${t.month}/${t.year}';
}
