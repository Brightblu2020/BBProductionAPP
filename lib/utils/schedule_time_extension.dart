extension ScheduleUtility on Duration {
  String duration() {
    int min = inMinutes - (inHours) * 60;
    return "${inHours}h ${min}m";
  }
}
