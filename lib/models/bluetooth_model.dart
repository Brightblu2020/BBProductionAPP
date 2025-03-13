import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothModel {
  BluetoothModel({
    this.bluetoothService,
    this.bluetoothDevice,
    this.readCharacterstic,
    this.writeCharacterstic,
    this.notifyCharacterstic
  });

  BluetoothService? bluetoothService;
  BluetoothDevice? bluetoothDevice;
  BluetoothCharacteristic? readCharacterstic;
  BluetoothCharacteristic? writeCharacterstic;
  BluetoothCharacteristic? notifyCharacterstic;

  String? alreadyRegistered;

  factory BluetoothModel.fromJson(
    BluetoothService service,
    BluetoothDevice device,
    BluetoothCharacteristic readCharacterstic,
    BluetoothCharacteristic writeCharacterstic,
  BluetoothCharacteristic notifyCharacterstic

  ) {
    return BluetoothModel(
      bluetoothService: service,
      bluetoothDevice: device,
      readCharacterstic: readCharacterstic,
      writeCharacterstic: writeCharacterstic,
      notifyCharacterstic: notifyCharacterstic
    );
  }
}
