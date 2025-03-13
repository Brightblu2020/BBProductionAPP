class WifiModel {
  WifiModel({
    required this.ssid,
    required this.rssi,
    required this.currentConnected,
  });

  factory WifiModel.fromJson(Map<String, dynamic> json) {
    return WifiModel(
      ssid: json['ssid'] as String,
      rssi: int.parse(json['rssi'] as String),
      currentConnected: false,
      // currentConnected: json['ssid'] as String,
    );
  }

  WifiModel copyWith({
    int? connectionId,
    bool? currentConnected,
    String? ssid,
    int? rssi,
  }) {
    return WifiModel(
      ssid: ssid ?? this.ssid,
      rssi: rssi ?? this.rssi,
      currentConnected: currentConnected ?? this.currentConnected,
    );
  }

  WifiModel clear() {
    return WifiModel(
      ssid: "",
      rssi: -1,
      currentConnected: false,
    );
  }

  final String ssid;
  final bool currentConnected;
  final int rssi;
}
