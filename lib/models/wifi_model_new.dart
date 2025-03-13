class WifiModel {
  WifiModel({
    required this.ssid,
    required this.rssi,
    this.currentConnected,
    this.connectionId,
  });

  factory WifiModel.fromJson(Map<String, dynamic> json) {
    return WifiModel(
      ssid: json['ssid'] as String,
      rssi: int.parse(json['rssi'] as String),
      // currentConnected: json['ssid'] as String,

      connectionId: 0,
    );
  }

  WifiModel copyWith({
    int? connectionId,
    String? currentConnected,
    String? ssid,
    int? rssi,
  }) {
    return WifiModel(
      ssid: ssid ?? this.ssid,
      rssi: rssi ?? this.rssi,
      currentConnected: currentConnected ?? this.currentConnected,
      connectionId: connectionId,
    );
  }

  final String ssid;
  final String? currentConnected;
  final int rssi;
  final int? connectionId;
}
