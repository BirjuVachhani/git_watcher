extension DurationExt on Duration {
  String prettify() {
    final days = inDays;
    final hours = inHours - (days * 24);
    final minutes = inMinutes - (days * 24 * 60) - (hours * 60);
    final seconds =
        inSeconds - (days * 24 * 60 * 60) - (hours * 60 * 60) - (minutes * 60);

    final List<String> parts = [];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0) parts.add('${seconds}s');

    return parts.join(' ');
  }
}
