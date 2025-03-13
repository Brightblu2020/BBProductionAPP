import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothModelNew {
  BluetoothModelNew({
    this.bluetoothService,
    this.bluetoothDevice,
    this.readCharacterstic,
    this.writeCharacterstic,
  });

  BluetoothService? bluetoothService;
  BluetoothDevice? bluetoothDevice;
  BluetoothCharacteristic? readCharacterstic;
  BluetoothCharacteristic? writeCharacterstic;
  String? alreadyRegistered;

  factory BluetoothModelNew.fromJson(
    BluetoothService service,
    BluetoothDevice device,
    BluetoothCharacteristic readCharacterstic,
    BluetoothCharacteristic writeCharacterstic,
  ) {
    return BluetoothModelNew(
      bluetoothService: service,
      bluetoothDevice: device,
      readCharacterstic: readCharacterstic,
      writeCharacterstic: writeCharacterstic,
    );
  }
}
