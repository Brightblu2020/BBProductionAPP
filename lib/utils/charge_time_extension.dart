extension ChargeTimer on int {
  String getChargerTimer({required int stopSeconds}) {
    if (this != 0) {
      // final currTime =
      //     controller.chargeTime.value.millisecondsSinceEpoch ~/ 1000;
      // final currTime = stopSeconds ~/ 1000;
      final diff = stopSeconds - this;

      var hour = diff ~/ 3600;
      var mins = (diff - hour * 3600) ~/ 60;
      var secs = diff - (hour * 3600) - (mins * 60);

      var hh = hour.toString();
      var mm = mins.toString();
      var ss = secs.toString();

      if (hour < 10) {
        hh = hh.padLeft(2, "0");
      }

      if (mins < 10) {
        mm = mm.padLeft(2, "0");
      }

      if (secs < 10) {
        ss = ss.padLeft(2, "0");
      }

      return "$hh:$mm:$ss";
    }
    return "-";
  }
}
