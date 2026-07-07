/// Utility for formatting [Duration] values into human-readable strings.
/// Pure functions — no side effects, easily testable.
abstract final class DurationFormatter {
  /// Formats [duration] as `m:ss` or `h:mm:ss`.
  ///
  /// Examples:
  /// - 3 minutes 5 seconds → `3:05`
  /// - 1 hour 2 minutes 5 seconds → `1:02:05`
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    // Don't pad minutes for short tracks (3:05 not 03:05)
    return '${minutes == 0 ? '0' : minutes}:$ss';
  }

  /// Formats milliseconds as `m:ss`.
  static String fromMilliseconds(int ms) =>
      format(Duration(milliseconds: ms));

  /// Formats total seconds as a short label: `3m`, `1h 2m`.
  static String toLabel(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
