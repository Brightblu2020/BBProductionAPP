// ignore_for_file: constant_identifier_names

enum ScheduleType {
  /// Normal freemode the charger stays authenticated as long as user wants
  PLUG_PLAY,

  /// The charger will go into freemode but only for a scheduled period of time
  /// The user can authenticate the charger by any means (app, RFID) outside the window
  FREE_SCHEDULE,

  /// The charger will go into freemode but only for a scheduled period of time
  /// However, the user will not be able to authenticate charging through any means otuside this window
  /// The charger will stay in UNAVAILABLE mode.
  TARIFF_SCHEDULE,

  NONE,
}

ScheduleType getScheduleType({required int type}) {
  switch (type) {
    case 0:
      return ScheduleType.FREE_SCHEDULE;
    case 1:
      return ScheduleType.TARIFF_SCHEDULE;
    default:
      return ScheduleType.NONE;
  }
}

extension ScheduleUtility on ScheduleType {
  String name() {
    switch (this) {
      case ScheduleType.PLUG_PLAY:
        return "Plug & Play";
      case ScheduleType.FREE_SCHEDULE:
        return "Set Plug & Play Schedule";
      case ScheduleType.TARIFF_SCHEDULE:
        return "Set Tariff Schedule";
      case ScheduleType.NONE:
        return "None";
    }
  }

  String subTitle() {
    switch (this) {
      case ScheduleType.PLUG_PLAY:
        return 'Turning on this switch will activate "Plug & Play" mode until turned off.\n\nThis mode will allow you to charge your car without authentication.';
      case ScheduleType.FREE_SCHEDULE:
        return 'Turning on this switch will activate "Plug & Play" mode for the selected period of time.\n\nOutside this time period only authorised users can use the charger';
      case ScheduleType.TARIFF_SCHEDULE:
        return 'Turning on this switch will activate the "Tariff Mode" during the selected period of time.\n\nThis will allow you to charge your car without authentication during the set schedule.\n\nOutside this time period the charger will remain unavailable and cannot be authorised.';
      case ScheduleType.NONE:
        return "None";
    }
  }

  int toggleValue() {
    switch (this) {
      case ScheduleType.PLUG_PLAY:
        return -1;
      case ScheduleType.FREE_SCHEDULE:
        return 0;
      case ScheduleType.TARIFF_SCHEDULE:
        return 1;
      case ScheduleType.NONE:
        return -1;
    }
  }
}
