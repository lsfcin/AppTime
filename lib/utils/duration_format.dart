String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else {
    return '${minutes}m';
  }
}
