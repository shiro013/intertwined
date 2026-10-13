import 'package:flutter_test/flutter_test.dart';
import 'package:intertwined/core/utils/time_ago.dart';

void main() {
  DateTime ago(Duration d) => DateTime.now().subtract(d);

  test('under a minute is "just now"', () {
    expect(timeAgo(ago(const Duration(seconds: 5))), 'just now');
  });
  test('minutes, hours and days', () {
    expect(timeAgo(ago(const Duration(minutes: 5, seconds: 1))), '5m ago');
    expect(timeAgo(ago(const Duration(hours: 3, minutes: 1))), '3h ago');
    expect(timeAgo(ago(const Duration(days: 2, hours: 1))), '2d ago');
  });
  test('a week or older falls back to a plain date', () {
    final old = DateTime.now().subtract(const Duration(days: 30));
    final t = old.toLocal();
    expect(timeAgo(old), '${t.day}/${t.month}/${t.year}');
  });
}
