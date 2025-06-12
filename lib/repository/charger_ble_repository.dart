import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:bb_factory_test_app/controller/charger_controller.dart';
import 'package:bb_factory_test_app/utils/enums/dpm_status.dart';
import 'package:bb_factory_test_app/utils/enums/schedule_type.dart';
import 'package:bb_factory_test_app/models/bluetooth_model_new.dart';
import 'package:bb_factory_test_app/models/charger_model_new.dart';
import 'package:bb_factory_test_app/models/ocpp_config_model.dart';
import 'package:bb_factory_test_app/models/wifi_model.dart';
import 'package:bb_factory_test_app/utils/esp_functions_enum.dart';
import 'package:bb_factory_test_app/hive/enums/hive_key_enum.dart';
import 'package:bb_factory_test_app/hive/hive.dart';
import 'package:bb_factory_test_app/hive/models/rfid_hive_model.dart';
import 'package:bb_factory_test_app/hive/models/schedule_hive_model.dart';
import 'package:bb_factory_test_app/hive/models/transaction_hive_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

extension Scan on FlutterBluePlus {
  static Future<List<ScanResult>> startScanWithResult({
    List<Guid> withServices = const [],
    Duration? timeout,
    bool androidUsesFineLocation = false,
  }) async {
    if (FlutterBluePlus.isScanningNow) {
      throw Exception("Another scan is already in progress");
    }

    List<ScanResult> output = [];

    var subscription = FlutterBluePlus.onScanResults.listen((result) {
      output = result;
    }, onError: (e, stackTrace) {
      throw Exception(e);
    });

    FlutterBluePlus.startScan(
      withServices: withServices,
      timeout: timeout,
      removeIfGone: null,
      oneByOne: false,
      androidUsesFineLocation: androidUsesFineLocation,
    );

    // wait scan complete
    await FlutterBluePlus.isScanning.where((e) => e == false).first;

    subscription.cancel();

    return output;
  }
}

class ChargerBLERepository {
  /// Bluetooth instance for BLE communtications
  // final FlutterBluePlus = FlutterBluePlus.instance;

  /// Current signed in user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  /// Standard fucntion to get BLE responses from stream depending upon Provided [ESPFUNCTIONS]
  Future<Map<String, dynamic>> getBLEResponse({
    required String message,
    required ESPFUNCTIONS bleResponse,
    required BluetoothModelNew bluetoothModel,
    int? index,
  }) async {
    if (bluetoothModel.writeCharacterstic != null) {
      final result = <String, dynamic>{};
      bool flag = true;
      try {
        await bluetoothModel.writeCharacterstic!.write(
          utf8.encode(message),
          withoutResponse: false,
        );
      } catch (e) {
        debugPrint("------ BLE response error ----- ${e.toString()}");
      }
      try {
        final completer = Completer<Map<String, dynamic>>();
        final subscription = bluetoothModel.readCharacterstic!.onValueReceived
            .timeout(const Duration(seconds: 25), onTimeout: (data) {
          data.close();
          debugPrint("---- ble reponse timeout ----");
          completer.complete({});
        }).listen((data) async {
          if (flag) {
            flag = false;
          }
          if (!flag) {
            if (data.isNotEmpty) {
              final message = utf8.decode(data, allowMalformed: true);
              // debugPrint("--- boot recv -- $message");
              // final message = ascii.decode(data, allowInvalid: true);
              if (message.isNotEmpty && message[0] == "[") {
                final list = jsonDecode(message) as List<dynamic>;
                // debugPrint(" list data ${bleResponse.name} ---- $list");
                if (bleResponse == ESPFUNCTIONS.TRIGGER_MESSAGE ||
                    getESPNotifications(list[0] as String) == bleResponse) {
                  // subscription?.cancel();
                  debugPrint("----- BLE message --- $message");

                  result.addAll((index != null && list.length > 2)
                      ? (list[index])
                      : list[1] as Map<String, dynamic>);
                  completer.complete(result);
                  // debugPrint("---- map data added --- $result");
                }
              } else {
                // return some value to stop processing

                debugPrint("error in data $message");
              }
            }
          }
        });
        result
          ..clear()
          ..addAll(await completer.future);
        await subscription.cancel();
      } catch (e) {
        debugPrint('Stream empty $e');
      }
      // debugPrint("---- map data added --- $result");
      return result;
    }
    return {};
  }

  Future<bool?> changeOCPPConfigDetails({
    required BluetoothModelNew model,
    required String key,
    required String value,
  }) async {
    try {
      final resp = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"$key","value":"$value"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- ocpp config accepted ---- $key");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint(
          "----- failure in configuring the server details ---- ${e.toString()}");
    }

    return null;
  }

  Future<ChargerModel?> boot(
      {required BluetoothModelNew bluetoothModel}) async {
    try {
      final resp = await getBLEResponse(
        message:
            '["BootNotification",{"currentTime":${(DateTime.now().millisecondsSinceEpoch ~/ 1000).toString()},"appType":"JOLTCONTROL"}]',
        bleResponse: ESPFUNCTIONS.BOOT_NOTIFICATION,
        bluetoothModel: bluetoothModel,
      );
      debugPrint('----- resp $resp');
      if (resp.isNotEmpty && (resp['status'] as String) == "Accepted") {
        /// Fetch chargersList from HIVE DB
        // final map = await HiveBox().getChargerList();

        return ChargerModel.fromBLE(
          chargerId: bluetoothModel.bluetoothDevice!.advName,
          remoteId: bluetoothModel.bluetoothDevice!.remoteId.str,
          userId: (currentUser != null) ? currentUser!.uid : "",
          phase: (resp['phase'] as String),
          connector: resp['connectors'],
          chargerName: "",
          firmware: (resp['chargePointFirmwareVersion'] ??
              resp['FirmwareVersion']) as String,
          chargerType: (resp['chargePointModel'] ?? "") as String,
          // firmware: resp['FirmwareVersion'] as String,
        );
      }
    } catch (e) {
      debugPrint("--- boot exceptiom ---- ${e.toString()}");
      Fluttertoast.showToast(msg: "Charger boot failure");
    }
    return null;
  }

  // /// Connect to a un-registered charger
  // Future<BluetoothModel?> connectToCharger(
  //     {required String chargerId, BluetoothDevice? givenDevice}) async {
  //   BluetoothDevice device;

  //   final connectedDevices = await FlutterBluePlus.connectedDevices;
  //   int index =
  //       connectedDevices.indexWhere((element) => element.name == chargerId);

  //   // Charger is connected
  //   if (index != -1) {
  //     device = connectedDevices[index];
  //     Fluttertoast.showToast(msg: "Charger was already connected");
  //   }

  //   /// When charger is not connected
  //   else {
  //     try {
  //       // charger is regsitered but not connected
  //       if (givenDevice == null) {
  //         final scanResult = await FlutterBluePlus.startScan(
  //           timeout: const Duration(seconds: 15),
  //         ) as List<ScanResult>;

  //         final deviceIndex =
  //             scanResult.indexWhere((e) => e.device.name == chargerId);
  //         debugPrint(
  //             "-- my devices --- ${scanResult[deviceIndex].device.name}");
  //         device = scanResult[deviceIndex].device;
  //       }
  //       // charger is not registered as well as not connected
  //       else {
  //         // await ChargerFirebaseRepository().uploadChargerData(model: model)
  //         device = givenDevice;
  //       }
  //       try {
  //         await device.connect(
  //           autoConnect: true,
  //           timeout: const Duration(seconds: 20),
  //         );
  //         Fluttertoast.showToast(msg: "Charger connected");
  //       } catch (e) {
  //         Fluttertoast.showToast(msg: "Failed to connect to charger");
  //       }
  //     } catch (e) {
  //       return null;
  //     }
  //   }

  //   final bluetoothModel = await configureCharger(device: device);
  //   return bluetoothModel;
  // }

  /// Connect to a un-registered charger
  // Future<BluetoothModel?> connectToCharger(
  //     {required String chargerId,
  //     BluetoothDevice? givenDevice}) async {
  //   BluetoothDevice device;
  //   Map<String, String> chargerList;
  //   bool connected = true;

  // try {
  //   chargerList = await HiveBox().getChargerList();
  // } catch (e) {
  //   chargerList = {};
  //   debugPrint("------ reading issue ---- ${e.toString()}");
  // }

  //   // If charger is a registered charger
  //   if (chargerList.isNotEmpty) {
  //     debugPrint("----- device registered ------- ${chargerList.toString()}");

  //     device = BluetoothDevice.fromId(
  //       chargerList.keys.first,
  //     );

  //     // if the device was already connected
  // if (FlutterBluePlus.connectedDevices
  //         .indexWhere((element) => element.advName == device.advName) !=
  //     -1) {
  //   Fluttertoast.showToast(msg: "Charger was already connected");
  // } else {
  //       try {
  //         // if (Platform.isAndroid) {
  //         //   await device.requestMtu(517);
  //         // }

  //         await device
  //             .connect(
  //           autoConnect: false,
  //           mtu: 517,
  //           timeout: const Duration(seconds: 20),
  //         )
  //             .then((value) async {
  //           debugPrint("----- adv name ---- ${device.advName}");
  //           // if (Platform.isAndroid) {
  //           //   await device.requestMtu(517);
  //           // }
  //         });

  //         Fluttertoast.showToast(msg: "Charger connection successful");
  //       } catch (e) {
  //         debugPrint("----- ble connection error with reg ${e.toString()}");
  //         connected = false;
  //         Fluttertoast.showToast(msg: "Charger failed to connect");
  //       }
  //     }
  //   }

  //   // If a charger is not registered
  //   else {
  //     debugPrint("----- device not registered ------");
  //     final scanResult = [];
  // try {
  //   await FlutterBluePlus.startScan(
  //     timeout: const Duration(seconds: 15),
  //     // withKeywords: ["BB"],
  //     // withServices: [Guid("180D")],
  //   );
  //   int startTime = DateTime.now().millisecondsSinceEpoch;
  //   StreamSubscription<List<ScanResult>>? scanStream;
  //   scanStream = FlutterBluePlus.scanResults.listen((event) async {
  //     debugPrint(
  //         "------ scanEvenets ---- ${event.toString()} --- ${startTime} ---- ${DateTime.now().millisecondsSinceEpoch}");
  //     if (DateTime.now().millisecondsSinceEpoch - startTime > 15000) {
  //       await scanStream!
  //           .cancel()
  //           .then((value) => debugPrint("---- scan stream cancelled ----"));
  //     }
  //     if (event.isNotEmpty) {
  //       scanResult.addAll(event);
  //       // await scanStream!
  //       //     .cancel()
  //       //     .then((value) => debugPrint("---- scan stream cancelled ----"));
  //     }
  //   });
  // } catch (e) {
  //   debugPrint("----- scanResult ----- ${e.toString()}");
  // }

  //     debugPrint("----- scanResult --------- ${scanResult.toString()}");

  //     if (scanResult.isEmpty) {
  //       return null;
  //     }

  //     final deviceIndex =
  //         scanResult.indexWhere((e) => e.device.advName == chargerId);
  //     debugPrint("-- my devices --- ${scanResult[deviceIndex].device.advName}");

  //     device = scanResult[deviceIndex].device;

  //     try {
  //       await HiveBox().writeToDB(
  //         key: HiveKey.chargerList,
  //         data: {device.remoteId.str: device.advName},
  //       );
  //     } catch (e) {
  //       debugPrint("----- write error ------- ${e.toString()}");
  //     }

  //     try {
  //       await device
  //           .connect(
  //         autoConnect: false,
  //         mtu: 517,
  //         timeout: const Duration(seconds: 20),
  //       )
  //           .then((value) async {
  //         // if (Platform.isAndroid) {
  //         //   await device.requestMtu(517);
  //         // }
  //       });

  //       Fluttertoast.showToast(msg: "Charger connection successful");
  //     } catch (e) {
  //       debugPrint("----- ble connection error ${e.toString()}");
  //       connected = false;
  //       Fluttertoast.showToast(msg: "Charger failed to connect");
  //     }
  //   }

  //   // final connectedDevices = await FlutterBluePlus.connectedDevices;
  //   // int index =
  //   //     connectedDevices.indexWhere((element) => element.name == chargerId);

  //   // // Charger is connected
  //   // if (index != -1) {
  //   //   device = connectedDevices[index];
  //   //   Fluttertoast.showToast(msg: "Charger was already connected");
  //   // }

  //   // /// When charger is not connected
  //   // else {
  //   //   try {
  //   //     // charger is regsitered but not connected
  //   //     if (givenDevice == null) {
  //   //   final scanResult = await FlutterBluePlus.startScan(
  //   //     timeout: const Duration(seconds: 15),
  //   //   ) as List<ScanResult>;

  //   //   final deviceIndex =
  //   //       scanResult.indexWhere((e) => e.device.name == chargerId);
  //   //   debugPrint(
  //   //       "-- my devices --- ${scanResult[deviceIndex].device.name}");
  //   //   device = scanResult[deviceIndex].device;
  //   // }
  //   //     // charger is not registered as well as not connected
  //   //     else {
  //   //       // await ChargerFirebaseRepository().uploadChargerData(model: model)
  //   //       device = givenDevice;
  //   //     }
  //   //     try {
  //   //       await device.connect(
  //   //         autoConnect: true,
  //   //         timeout: const Duration(seconds: 20),
  //   //       );
  //   //       Fluttertoast.showToast(msg: "Charger connected");
  //   //     } catch (e) {
  //   //       Fluttertoast.showToast(msg: "Failed to connect to charger");
  //   //     }
  //   //   } catch (e) {
  //   //     return null;
  //   //   }
  //   // }
  //   if (!connected) {
  //     return null;
  //   }
  //   final bluetoothModel = await configureCharger(
  //     device: device,
  //   );
  //   return bluetoothModel;
  // }

  Future<BluetoothModelNew?> connectToCharger(
      {BluetoothDevice? scanDevice, String? remoteId}) async {
    BluetoothDevice? device;
    bool connectionSuccess = true;
    // bool alreadyConnected = false;

    Map<String, String> chargerList = {};

    /// I am coming after scan
    if (scanDevice != null) {
      device = scanDevice;
    }

    /// I am directly comming to connect
    else {
      // try {
      //   await device!.disconnect();
      // } catch (e) {
      //   debugPrint("---- charger disconnection failed ---- ${e.toString()}");
      // }

      /// If [BluetoothDevice] was already connected then we won't be able to see it in the scanResults

      // final index = (await FlutterBluePlus.systemDevices)
      //     .indexWhere((element) => element.advName == remoteId);
      // if (index != -1) {
      //   device = FlutterBluePlus.connectedDevices[index];
      //   // alreadyConnected = true;

      //   Fluttertoast.showToast(msg: "Charger was already connected");
      // }

      // /// If the [BluetoothDevice] is not connected
      // else {

      try {
        chargerList = await HiveBox().getChargerList();
        if (chargerList.containsKey(remoteId)) {
          device = BluetoothDevice.fromId(chargerList[remoteId]!);
          await device.disconnect();
          debugPrint(
              "------ found BLE device already ---- ${device.advName} --- ");
        }
      } catch (e) {
        debugPrint("------ reading issue ---- ${e.toString()}");
        // return null;
      }

      try {
        final list = await getScanResults();
        debugPrint("----- scanResultList in connection --- ${list.toString()}");
        if (list.isNotEmpty) {
          final index =
              list.indexWhere((element) => element.device.advName == remoteId);
          if (index != -1) {
            device = list[index].device;
          }
        }
      } catch (e) {
        debugPrint("----- device connection ScanResult ----- ${e.toString()}");
        return null;
      }
    }
    // }

    // if device is still null after scan and from HIVEDB
    if (device == null) {
      return null;
    }

    // Try connecting to the bluetoothDevice
    if (!device.isConnected) {
      try {
        await device.connect(
          autoConnect: false,
          mtu: 517,
          timeout: const Duration(seconds: 20),
        );
      } catch (e) {
        connectionSuccess = false;
        debugPrint(
            "----- device connect fail after scan ------ ${e.toString()}");
      }
    }

    if (connectionSuccess) {
      try {
        chargerList[device.advName] = device.remoteId.str;

        await HiveBox().writeToDB(
          key: HiveKey.chargerList,
          data: chargerList,
          chargerId: device.advName,
        );
      } catch (e) {
        debugPrint(
            "----- device hive write fail after scan ------ ${e.toString()}");
      }
    }
    // }

    if (connectionSuccess) {
      return configureCharger(device: device);
    }
    return null;
  }

  Future<List<ScanResult>> getScanResults() async {
    if (FlutterBluePlus.isScanningNow) {
      debugPrint("Another scan is already in progress");
      await FlutterBluePlus.stopScan();
    }

    List<ScanResult> output = [];

    var subscription = FlutterBluePlus.scanResults.listen((result) {
      output = result;
      debugPrint(
          "----- FlutterBluePlus.onScanResults ----- ${result.toString()}");
    }, onError: (e, stackTrace) {
      throw Exception(e);
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 3),
      // removeIfGone: null,
      withKeywords: ["BB"],
      // oneByOne: true,
      androidScanMode: AndroidScanMode.balanced,
      androidUsesFineLocation: true,
    );

    // wait scan complete
    await FlutterBluePlus.isScanning.where((e) => e == false).first;

    subscription.cancel();

    return output;
  }

  // Future<List<ScanResult>> scanDevices() async {
  //   List<ScanResult> scanResult = <ScanResult>[];
  //   try {
  //     await FlutterBluePlus.startScan(timeout: const Duration(seconds: 25));

  //     bool flag = true;

  //     final completer = Completer<List<ScanResult>>();
  //     final subscription = FlutterBluePlus.onScanResults
  //         .timeout(const Duration(seconds: 25), onTimeout: (data) {
  //       data.close();
  //       debugPrint("---- ble reponse timeout ----");
  //       try {
  //         completer.complete(scanResult);
  //       } catch (e) {
  //         debugPrint("errror scanning already complete ----${e.toString()}");
  //       }
  //     }).listen((data) async {
  //       if (flag) {
  //         flag = false;
  //       }
  //       if (!flag) {
  //         if (data.isNotEmpty) {
  //           scanResult.addAll(data);
  //           try {
  //             completer.complete(scanResult);
  //           } catch (e) {
  //             debugPrint(
  //                 "errror scanning already complete ----${e.toString()}");
  //           }
  //         }
  //       }
  //     });
  //     scanResult
  //       ..clear()
  //       ..addAll(await completer.future);
  //     await subscription.cancel();
  //   } catch (e) {
  //     debugPrint('Stream empty $e');
  //   }

  //   return scanResult;
  // }

  Future<BluetoothModelNew?> configureCharger(
      {required BluetoothDevice device}) async {
    /// setting message MTU bytes
    try {
      /// discover services
      final servicesList = await device.discoverServices();

      /// Our required service
      int index = servicesList.indexWhere((element) =>
          element.uuid.toString() == "6e400001-b5a3-f393-e0a9-e50e24dcca9e");

      if (index < 0) {
        index = servicesList.indexWhere((element) =>
            element.uuid.toString() == "fb1e4001-54ae-4a28-9f74-dfccb248601d");
      }

      /// Index of our read characterstic
      int readIndex = servicesList[index].characteristics.indexWhere(
          (element) =>
              element.uuid.toString() ==
              "6e400003-b5a3-f393-e0a9-e50e24dcca9e");
      if (readIndex < 0) {
        readIndex = servicesList[index].characteristics.indexWhere((element) =>
            element.uuid.toString() == "fb1e4003-54ae-4a28-9f74-dfccb248601d");
      }

      /// Index of our write characterstic
      int writeIndex = servicesList[index].characteristics.indexWhere(
          (element) =>
              element.uuid.toString() ==
              "6e400002-b5a3-f393-e0a9-e50e24dcca9e");

      if (writeIndex < 0) {
        writeIndex = servicesList[index].characteristics.indexWhere((element) =>
            element.uuid.toString() == "fb1e4002-54ae-4a28-9f74-dfccb248601d");
      }

      await servicesList[index]
          .characteristics[readIndex]
          .setNotifyValue(true)
          .then((value) => debugPrint("--- set notify value $value"));

      return BluetoothModelNew.fromJson(
        servicesList[index],
        device,
        servicesList[index].characteristics[readIndex],
        servicesList[index].characteristics[writeIndex],
      );
    } catch (e) {
      debugPrint("---- ble congiure issue ---- ${e.toString()}");
    }
    return null;
  }

  /// Returns a list of all wifi connections that the charger can connect to
  Future<List<WifiModel>> getWifiSsidList(
      {required BluetoothModelNew model}) async {
    final result = <WifiModel>[];

    final resp = await getBLEResponse(
      message: '["GetConfiguration",{"key":"listSsid"}]',
      bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
      bluetoothModel: model,
    );

    if (resp.isNotEmpty) {
      final data = resp["ssidList"] as List<dynamic>;
      if (data.isNotEmpty) {
        final list = <WifiModel>[];
        for (final ssid in data) {
          final model = WifiModel.fromJson(ssid as Map<String, dynamic>);
          if (list.indexWhere((element) => element.ssid == model.ssid) == -1) {
            list.add(model);
          }
        }
        result
          ..clear()
          ..addAll(list);
      }
    }

    return result;
  }

  Future<int> getWifiConnectionStatus(
      {required BluetoothModelNew model}) async {
    try {
      final resp = await getBLEResponse(
        message:
            '["TriggerMessage",{"requestedMessage":"wifiStatusNotification"}]',
        bleResponse: ESPFUNCTIONS.TRIGGER_MESSAGE,
        bluetoothModel: model,
        index: 3,
      );
      debugPrint("----- trigger wifi status ----- $resp");
      if (resp.isNotEmpty) {
        return resp['value'];
      }
    } catch (e) {
      debugPrint("------ error in wifiStatusNotification ---- ${e.toString()}");
    }
    return 0;
  }

  /// Connects to selected wifi network
  Future<bool> connectToWifiSsid({
    required String ssidName,
    required String ssidPass,
    required BluetoothModelNew bluetoothModel,
  }) async {
    //configure the name
    final respName = await getBLEResponse(
      message: '["ChangeConfiguration",{"key":"wifiSsid","value":"$ssidName"}]',
      bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
      bluetoothModel: bluetoothModel,
    );

    if (respName.isNotEmpty && respName['status'] as String == "Accepted") {
      debugPrint("---- wifi name accepted");

      /// Wifi password configure

      Map<String, dynamic> respPass = {};
      int i = 50;
      // await Future.delayed(const Duration(seconds: 5), () async {
      //   respPass = await getBLEResponse(
      //     message:
      //         '["ChangeConfiguration",{"key":"wifiPassword","value":"$ssidPass"}]',
      //     bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
      //     bluetoothModel: bluetoothModel,
      //   );
      // });
      while (i > 0) {
        i--;
      }

      // Configure the password
      respPass = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"wifiPassword","value":"$ssidPass"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );

      if (respPass.isNotEmpty && respPass['status'] as String == "Accepted") {
        debugPrint("---- wifi password accepted");
        return true;
      }
    }

    return false;
  }

  /// Checks the wifi connection with selected wifi-ssid
  Future<bool> checkSsidConnection({
    required String ssidName,
    required BluetoothModelNew bluetoothModel,
  }) async {
    final resp = await getBLEResponse(
      message: '["GetConfiguration",{"key":"wifiSsid"}]',
      bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
      bluetoothModel: bluetoothModel,
    );
    if (resp.isNotEmpty && resp['value'] as String == ssidName) {
      debugPrint("---- already configured ");
      return true;
    }
    return false;
  }

  Future<String> getWifiSSID({required BluetoothModelNew model}) async {
    final resp = await getBLEResponse(
      message: '["GetConfiguration",{"key":"wifiSsid"}]',
      bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
      bluetoothModel: model,
    );
    if (resp['value'] != "" || resp['value'] != null) {
      return resp['value'];
    }
    return "";
  }

  /// Checks overall wifi configuration i.e IP-Adress, Wifi Ssid Name
  Future<bool> checkWifiConfiguration({
    required String ssidName,
    required BluetoothModelNew bluetoothModel,
  }) async {
    final resp = await getBLEResponse(
      message: '["GetConfiguration",{"key":"ipAddress"}]',
      bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
      bluetoothModel: bluetoothModel,
    );
    bool ssidConnected = false;
    await Future.delayed(const Duration(seconds: 5), () async {
      ssidConnected = await checkSsidConnection(
        ssidName: ssidName,
        bluetoothModel: bluetoothModel,
      );
    });

    if (resp.isNotEmpty &&
        resp['value'] as String != "0.0.0.0" &&
        ssidConnected) {
      return true;
    }
    return false;
  }

  Future<void> initateCharge({
    required String result,
    required BluetoothModelNew bluetoothModel,
  }) async {
    try {
      final respName = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"remoteTransaction","value":"$result"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      if (respName.isEmpty || respName['status'] as String != "Accepted") {
        Fluttertoast.showToast(msg: "Failed to $result charging");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to $result charging");
    }
  }

  Future<bool> plugAndPlay({
    required int result,
    required BluetoothModelNew bluetoothModel,
  }) async {
    try {
      debugPrint("---- freemode -- $result");
      final respName = await getBLEResponse(
        message: '["ChangeConfiguration",{"key":"freemode","value":$result}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      if (respName.isEmpty || respName['status'] as String != "Accepted") {
        Fluttertoast.showToast(msg: "Failed to to put charger on freemode");
      } else {
        return true;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to to put charger on freemode");
    }
    return false;
  }

  Future<List<RfidHiveModel>> getListRFID(
      {required BluetoothModelNew model}) async {
    final result = <RfidHiveModel>[];

    try {
      final resp = await getBLEResponse(
        message: '["GetConfiguration",{"key":"rfidTag"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      debugPrint("----- rfid resp ----- $resp");
      if (resp.isNotEmpty) {
        final data = resp["rfidList"] as List<dynamic>;

        if (data.isNotEmpty) {
          for (final rfid in data) {
            final model = RfidHiveModel(id: rfid['rfid'] as String, name: "");
            result.add(model);
          }
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get rfid's");
    }

    return result;
  }

  Future<Map<String, dynamic>> _getBLEResponse({
    required String message,
    required ESPFUNCTIONS bleResponse,
    required BluetoothModelNew bluetoothModel,
    int?
        noOfpackets, // This parameter is now optional and not used for completion detection
  }) async {
    final result = <String, dynamic>{};
    if (bluetoothModel.writeCharacterstic != null) {
      try {
        await bluetoothModel.writeCharacterstic!.write(
          utf8.encode(message),
          withoutResponse: false,
        );
      } catch (e) {
        debugPrint("------ BLE response error ----- ${e.toString()}");
      }

      try {
        final completer = Completer<String>();
        String res = "";

        final subscription = bluetoothModel.readCharacterstic!.onValueReceived
            .timeout(const Duration(seconds: 20), onTimeout: (data) {
          data.close();
          debugPrint("---- ble reponse timeout ----");
          completer.complete("");
        }).listen((data) async {
          debugPrint(
              "------ stream data received  -------- ${utf8.decode(data, allowMalformed: true)} -------");

          if (data.isNotEmpty) {
            print("Data is not empty : $data");
            final bleMessage = utf8.decode(data, allowMalformed: true);
            if (bleMessage.isNotEmpty) {
              print("bleMessage is not empty : $bleMessage");

              // Add the new chunk to our buffer
              res += bleMessage;

              // Check if we have a complete JSON packet (ends with }])
              if (_isJsonPacketComplete(res)) {
                debugPrint("Complete JSON packet detected: $res");
                completer.complete(res);
              }
            }
          } else {
            debugPrint("error in data $message");
          }
        });

        res = await completer.future;
        await subscription.cancel();

        if (res.isNotEmpty) {
          result
            ..clear()
            ..addAll(_processBLEData(data: res, bleFuntion: bleResponse));
        }
      } catch (e) {
        debugPrint('Stream empty $e');
      }

      // debugPrint("---- map data added --- $result");
      return result;
    }
    return {};
  }

  /// Check if the JSON packet is complete by detecting }] at the end
  bool _isJsonPacketComplete(String data) {
    try {
      // Trim whitespace and check if ends with }]
      String trimmed = data.trim();

      // Basic check for JSON array completion
      if (!trimmed.endsWith('}]')) {
        return false;
      }

      // Additional validation: try to parse as JSON to ensure it's valid
      try {
        jsonDecode(trimmed);
        return true;
      } catch (e) {
        // If JSON parsing fails, the packet might be incomplete
        debugPrint("JSON parsing failed, packet might be incomplete: $e");
        return false;
      }
    } catch (e) {
      debugPrint("Error checking packet completion: $e");
      return false;
    }
  }

  Map<String, dynamic> _processBLEData(
      {required String data, required ESPFUNCTIONS bleFuntion}) {
    try {
      String processOutput = data.trim(); // Trim any whitespace
      print("processOutput - $processOutput");

      final result = jsonDecode(processOutput);
      debugPrint(
          "----- processedOutput : ${result.runtimeType}  ------ ${result[0]}");

      if (getESPNotifications(result[0] as String) == bleFuntion) {
        print("Inside if getESPNotifications - $result");
        return result[1] as Map<String, dynamic>;
      } else {
        print("Inside else getESPNotifications - $result");
      }
    } catch (e) {
      debugPrint("------ processOutput exception --- ${e.toString()}");
      debugPrint("------ problematic data --- $data");
    }

    return {};
  }

// Alternative version with more robust JSON validation
  bool _isJsonPacketCompleteRobust(String data) {
    String trimmed = data.trim();

    // Quick check for basic structure
    if (!trimmed.startsWith('[') || !trimmed.endsWith('}]')) {
      return false;
    }

    // Count brackets to ensure they're balanced
    int squareBrackets = 0;
    int curlyBrackets = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < trimmed.length; i++) {
      String char = trimmed[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        switch (char) {
          case '[':
            squareBrackets++;
            break;
          case ']':
            squareBrackets--;
            break;
          case '{':
            curlyBrackets++;
            break;
          case '}':
            curlyBrackets--;
            break;
        }
      }
    }

    // Check if brackets are balanced and we end with proper structure
    bool balanced = squareBrackets == 0 && curlyBrackets == 0;
    bool endsCorrectly = trimmed.endsWith('}]');

    if (balanced && endsCorrectly) {
      // Final validation: try to parse as JSON
      try {
        jsonDecode(trimmed);
        return true;
      } catch (e) {
        debugPrint("JSON validation failed: $e");
        return false;
      }
    }

    return false;
  }

  Future<HashMap<String, OCPPConfigModel>?> getOCPPConfigDetails(
      {required BluetoothModelNew model}) async {
    try {
      final map = HashMap<String, OCPPConfigModel>();
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"getOcppConfiguration"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
        noOfpackets: 6,
      );
      if (resp.isNotEmpty) {
        debugPrint("---- ocppconfig  ----- ${resp.toString()} ");
        final values = resp['value'] as List<dynamic>;
        for (final mp in values) {
          final model =
              OCPPConfigModel.fromjson(json: mp as Map<String, dynamic>);
          map[model.key] = model;
        }
      }
      return map;
    } catch (e) {
      debugPrint("------- could not get ocppConfig ${e.toString()}");
    }

    return null;
  }

  Future<bool> addRFIDTag({
    required BluetoothModelNew model,
  }) async {
    try {
      final resp = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"addRfidTag","value":"scanRFID"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      debugPrint("---- adding rfid tag resp ----- $resp");
      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<bool> deleteRFIDTag({
    required BluetoothModelNew model,
    required String tag,
  }) async {
    try {
      final resp = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"deleteRfidTag","value":"$tag"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      debugPrint("---- deleting rfid tag resp ----- $resp");
      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<bool?> setMaxCurrentLimit({
    required BluetoothModelNew model,
    required int limit,
  }) async {
    try {
      final resp = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"maxCurrentLimit","value":$limit}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      debugPrint("---- updating max current limit ----- $resp");
      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<int?> getChargingTime(
      {required BluetoothModelNew bluetoothModel}) async {
    try {
      final resp = await getBLEResponse(
        message: '["TriggerMessage",{"requestedMessage":"chargingTimer"}]',
        bleResponse: ESPFUNCTIONS.TRIGGER_MESSAGE,
        bluetoothModel: bluetoothModel,
      );
      debugPrint("---- charger timer ---- $resp");
      if (resp.isNotEmpty) {
        return (resp['chargingTimer']);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error in fetching charger time ${e.toString()}");
    }
    return null;
  }

  Future<bool?> updateChargerFirmware(
      {required String firmware,
      required BluetoothModelNew bluetoothModel}) async {
    try {
      final resp = await getBLEResponse(
        message: '["FirmwareUpdate",{"key":"fileName","value":"$firmware"}]',
        bleResponse: ESPFUNCTIONS.FIRMWARE_UPDATE,
        bluetoothModel: bluetoothModel,
      );
      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        return true;
      }
    } catch (e) {}
    return null;
  }

  Future<bool> hardReset({required BluetoothModelNew bluetoothModel}) async {
    try {
      final resp = await getBLEResponse(
        message: '["ChangeConfiguration",{"key":"hardReset","value":""}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<bool> softReset({required BluetoothModelNew bluetoothModel}) async {
    try {
      final resp = await getBLEResponse(
        message: '["ChangeConfiguration",{"key":"softReset","value":""}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        return true;
      }
    } catch (e) {}
    return false;
  }

  Future<Map<String, dynamic>> triggerStatusNotification(
      {required BluetoothModelNew bluetoothModel}) async {
    try {
      final resp = await getBLEResponse(
        message: '["TriggerMessage",{"requestedMessage":"StatusNotification"}]',
        bleResponse: ESPFUNCTIONS.TRIGGER_MESSAGE,
        bluetoothModel: bluetoothModel,
      );
      debugPrint("---- status notification trigger ---- $resp");
      if (resp.isNotEmpty) {
        final data = <String, dynamic>{};
        for (final map
            in (resp["chargerParameters"] ?? resp["Params"]) as List<dynamic>) {
          data.addIf(true, map['key'] as String, map['value']);
        }
        return data;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Status notification error ${e.toString()}");
    }
    return {};
  }

  Future<Map<String, dynamic>> triggerStatusNotificationForPush(
      {required BluetoothModelNew bluetoothModel}) async {
    try {
      final resp = await getBLEResponse(
        message: '["TriggerMessage",{"requestedMessage":"StatusNotification"}]',
        bleResponse: ESPFUNCTIONS.TRIGGER_MESSAGE,
        bluetoothModel: bluetoothModel,
      );
      debugPrint("---- status notification trigger ---- $resp");
      if (resp.isNotEmpty) {
        final data = <String, dynamic>{};
        for (final map
            in (resp["chargerParameters"] ?? resp["Params"]) as List<dynamic>) {
          data.addIf(true, map['key'] as String, map['value']);
        }
        return data;
      }
    } catch (e) {
      debugPrint(
          "--------------------- Status notification error ${e.toString()} -----------");
      Fluttertoast.showToast(msg: "Status notification error ${e.toString()}");
    }
    return {};
  }

  Future<bool> activateSchedule({
    required BluetoothModelNew bluetoothModel,
    required ScheduleHiveModel model,
    required ScheduleType type,
  }) async {
    try {
      debugPrint("----- scheduleType ----- ${type.name()}");
      int value = (type == ScheduleType.FREE_SCHEDULE) ? 0 : 1;
      final resp = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key": "addSchedule","value": [{"days": ${model.days}, "timeStart":"${model.timeStart}","duration": "${model.duration}", "type": $value}]}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      debugPrint("----- activate schedule resp ---- ${resp.toString()}");
      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        // HiveBox().init;
        // return (await softReset(bluetoothModel: bluetoothModel));
        return true;
      }
    } catch (e) {
      debugPrint("----- activation schedule failed ----- ${e.toString()}");
    }
    return false;
  }

  Future<bool> deleteSchedule({
    required BluetoothModelNew bluetoothModel,
    bool? reboot,
  }) async {
    // [{"days": "${model.days}", "timeStart":"${model.timeStart ~/ 1000}","duration": "${model.duration * 60 * 60}"}]}]
    try {
      final resp = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key": "deleteSchedule","value": ""}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      debugPrint("----- delete schedule resp ---- ${resp.toString()}");
      if (resp.isNotEmpty &&
          (resp['status'] as String == "Accepted" ||
              resp['status'] as String == "Rejected")) {
        // if (reboot == null && resp['status'] as String != "Rejected") {
        //   // return (await softReset(bluetoothModel: bluetoothModel));
        //   return true;
        // }
        return true;
      }
    } catch (e) {
      debugPrint("----- activation schedule failed ----- ${e.toString()}");
    }
    return false;
  }

  Future<ScheduleHiveModel?> getSchedule(
      {required BluetoothModelNew model}) async {
    try {
      final resp = await getBLEResponse(
        message: '["GetConfiguration",{"key":"getSchedule"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      debugPrint(
          "----- get schedule resp ----- $resp ----- ${resp['value'].runtimeType}");
      if (resp.isNotEmpty && resp['value'] != 0) {
        debugPrint("------ schedule model ble ---- ${ScheduleHiveModel.fromJson(
          data: (resp['value'] as List<dynamic>)[0],
          id: "id",
          // type: resp['type'] as int,
        ).toMap()}");
        ScheduleHiveModel model = ScheduleHiveModel.fromJson(
          data: (resp['value'] as List<dynamic>)[0],
          id: "id",
          // type: resp['type'] as int,
        );
        model = model.copyWith(active: true);
        return model;
      } else {
        //Fluttertoast.showToast(msg: "No schedule");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get schedule");
    }

    return null;
  }

  Future<int?> triggerTransactions(
      {required BluetoothModelNew bluetoothModel}) async {
    try {
      final transactionCountResp = await getBLEResponse(
        message: '["TriggerMessage",{"requestedMessage":"transactionCount"}]',
        bleResponse: ESPFUNCTIONS.TRIGGER_MESSAGE,
        bluetoothModel: bluetoothModel,
      );
      if (transactionCountResp.isNotEmpty &&
          (transactionCountResp['value'] as int) > 0) {
        debugPrint(
            "------ transactioncount resp ------ ${transactionCountResp.toString()}");
        // await triggerTransactionsMessages(bluetoothModel: bluetoothModel);
        return (transactionCountResp['value'] as int);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Transactions trigger error ${e.toString()}");
    }
    return null;
  }

  Future<List<TransactionHiveModel>> triggerTransactionsMessages({
    required BluetoothModelNew bluetoothModel,
    required int count,
  }) async {
    final controller = Get.find<ChargerController>();
    final list = <TransactionHiveModel>[];
    try {
      int ctr = count;
      controller.downloadedTransactions.value = 0;
      controller.downloadedTransactions.refresh();
      Map<String, dynamic> message = {};

      debugPrint("------ start time :  ${DateTime.now().toLocal()} -----");

      while (ctr >= 0) {
        // await Future.delayed(const Duration(seconds: 1), () async {
        message = await getBLEResponse(
          message:
              '["TriggerMessage",{"requestedMessage":"TransactionMessage"}]',
          bleResponse: ESPFUNCTIONS.TRIGGER_MESSAGE,
          bluetoothModel: bluetoothModel,
        );
        // });

        debugPrint("---- records from charger message ----- $message");

        if (message.isNotEmpty && message['transactionId'] != "NA") {
          final model = TransactionHiveModel.fromJson(data: message);
          debugPrint("------ BLE from charger -------- ${model.toMap()}");
          controller.downloadedTransactions.value += 1;
          list.add(model);
        }

        ctr--;
      }

      debugPrint("------ end time :  ${DateTime.now().toLocal()} -----");

      return list;
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Transactions message trigger error ${e.toString()}");
    }

    return list;
  }

  Future<bool?> getDpmCheck({required BluetoothModelNew model}) async {
    try {
      final resp = await getBLEResponse(
        message: '["GetConfiguration",{"key":"dpmCheck"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty || resp['value'] == "") return null;
      if (resp['value'] == "BBPM1") {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("-------- error in getDpmCheck() -------- ${e.toString()}");
    }

    return null;
  }

  Future<DpmStatus?> getDpmStatus({required BluetoothModelNew model}) async {
    try {
      final resp = await getBLEResponse(
        message: '["GetConfiguration",{"key":"dpmStatus"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty || resp['value'] == "") return null;
      if (resp['value'] == "DPMOFF") return DpmStatus.OFF;
      return DpmStatus.ON;
    } catch (e) {
      debugPrint("-------- error in getDpmStatus() -------- ${e.toString()}");
    }

    return null;
  }

  Future<String?> getDpmPower({required BluetoothModelNew model}) async {
    try {
      final resp = await getBLEResponse(
        message: '["GetConfiguration",{"key":"dpmPower"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      debugPrint("------- dpmPower ----------- ${resp.toString()}");
      if (resp.isEmpty || resp['value'] == "") return null;
      return (resp['value'] as String);
    } catch (e) {
      debugPrint("-------- error in getDpmPower() -------- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> changeDpmStatus(
      {required BluetoothModelNew model, required DpmStatus status}) async {
    try {
      final resp = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"dpmStatus","value": "${status.name()}"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      debugPrint("------- changeDpmStats ------ ${resp.toString()}");
      if (resp.isEmpty || resp['value'] == "") return null;
      if (resp['value'] == "Rejected") return false;
      return true;
    } catch (e) {
      debugPrint(
          "-------- error in changeDpmStatus() -------- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> changeDpmPower(
      {required BluetoothModelNew model, required String power}) async {
    try {
      final resp = await getBLEResponse(
        message:
            '["ChangeConfiguration",{"key": "dpmPower","value": "$power"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty || resp['value'] == "") return null;
      if (resp['value'] == "Rejected") return false;
      return true;
    } catch (e) {
      debugPrint("-------- error in changeDpmPower() -------- ${e.toString()}");
    }

    return null;
  }
}
