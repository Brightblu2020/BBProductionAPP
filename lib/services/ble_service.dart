import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/constants.dart';
import 'dart:io' show Platform;

class BleService {
  static final BleService _instance = BleService._internal();

  factory BleService() => _instance;

  BleService._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? rxCharacteristic;
  BluetoothCharacteristic? txCharacteristic;

  final StreamController<List<int>> _responseStreamController =
      StreamController<List<int>>.broadcast();
  Stream<List<int>> get responseStream => _responseStreamController.stream;

  Future<bool> isBluetoothAvailable() async {
    try {
      // Check if Bluetooth is available
      bool available = await FlutterBluePlus.isAvailable;

      // On iOS, also check if Bluetooth is turned on
      if (available && Platform.isIOS) {
        try {
          // Listen to the adapter state stream
          bool isOn = false;
          await for (BluetoothAdapterState state
              in FlutterBluePlus.adapterState) {
            isOn = state == BluetoothAdapterState.on;
            if (state == BluetoothAdapterState.on ||
                state == BluetoothAdapterState.off) {
              break; // We got a definitive state
            }
          }

          if (!isOn) {
            print('Bluetooth not turned on');
            return false;
          }
        } catch (e) {
          print('Error checking Bluetooth state: $e');
          return false;
        }
      }

      return available;
    } catch (e) {
      print('Error checking Bluetooth availability: $e');
      return false;
    }
  }

  Future<void> startScan() async {
    try {
      // Check if already scanning using a safer method
      bool isCurrentlyScanning = false;
      await for (bool scanning in FlutterBluePlus.isScanning) {
        isCurrentlyScanning = scanning;
        break; // We only need the current state
      }

      // Stop any existing scan first
      if (isCurrentlyScanning) {
        await FlutterBluePlus.stopScan();
      }

      // Start scan with appropriate timeout
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      print('Error starting scan: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error stopping scan: $e');
      rethrow;
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // If already connected to another device, disconnect first
      await disconnect();

      // Set the new device as connected device
      connectedDevice = device;

      // Connect with iOS-specific options
      if (Platform.isIOS) {
        await device.connect(
          autoConnect: false,
          timeout: const Duration(seconds: 15),
        );
      } else {
        await device.connect();
      }

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      bool foundCharacteristics = false;

      // Find the correct service and characteristics
      for (BluetoothService service in services) {
        final String serviceUuid = service.serviceUuid.toString().toLowerCase();

        if (serviceUuid == Constants.SERVICE_UUID_1.toLowerCase() ||
            serviceUuid == Constants.SERVICE_UUID_2.toLowerCase()) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            String uuid =
                characteristic.characteristicUuid.toString().toLowerCase();

            if (uuid == Constants.CHARACTERISTIC_UUID_RX_1.toLowerCase() ||
                uuid == Constants.CHARACTERISTIC_UUID_RX_2.toLowerCase()) {
              rxCharacteristic = characteristic;
              foundCharacteristics = true;
            } else if (uuid ==
                    Constants.CHARACTERISTIC_UUID_TX_1.toLowerCase() ||
                uuid == Constants.CHARACTERISTIC_UUID_TX_2.toLowerCase()) {
              txCharacteristic = characteristic;
              foundCharacteristics = true;

              try {
                // Subscribe to notifications
                await characteristic.setNotifyValue(true);
                characteristic.onValueReceived.listen((value) {
                  _responseStreamController.add(value);
                });
              } catch (e) {
                print('Error setting notification: $e');
              }
            }
          }
        }
      }

      if (!foundCharacteristics) {
        throw Exception('Required BLE characteristics not found on device');
      }
    } catch (e) {
      print('Error connecting to device: $e');
      // Make sure to clean up on error
      await disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }

      connectedDevice = null;
      rxCharacteristic = null;
      txCharacteristic = null;
    }
  }

  Future<void> sendBootNotification() async {
    if (rxCharacteristic != null) {
      try {
        final bootMessage = [
          "BootNotification",
          {
            "currentTime":
                DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
            "appVersion": Constants.APP_VERSION,
          },
        ];

        final String jsonMessage = jsonEncode(bootMessage);
        final List<int> bytes = utf8.encode(jsonMessage);

        // On iOS, we should ensure the characteristic is writable
        if (Platform.isIOS) {
          final properties = rxCharacteristic!.properties;
          if (!properties.write && !properties.writeWithoutResponse) {
            throw Exception('RX Characteristic is not writable');
          }
        }

        // Use the appropriate write method based on characteristic properties
        if (rxCharacteristic!.properties.writeWithoutResponse) {
          await rxCharacteristic!.write(bytes, withoutResponse: true);
        } else {
          await rxCharacteristic!.write(bytes);
        }
      } catch (e) {
        print('Error sending boot notification: $e');
        rethrow;
      }
    } else {
      throw Exception('RX Characteristic not found');
    }
  }

  Future<void> sendMessage(String command, Map<String, dynamic> params) async {
    if (rxCharacteristic != null) {
      try {
        final message = [command, params];
        final String jsonMessage = jsonEncode(message);
        final List<int> bytes = utf8.encode(jsonMessage);

        // Use the appropriate write method based on characteristic properties
        if (rxCharacteristic!.properties.writeWithoutResponse) {
          await rxCharacteristic!.write(bytes, withoutResponse: true);
        } else {
          await rxCharacteristic!.write(bytes);
        }
      } catch (e) {
        print('Error sending message: $e');
        rethrow;
      }
    } else {
      throw Exception('RX Characteristic not found');
    }
  }

  void dispose() {
    disconnect();
    _responseStreamController.close();
  }
}
