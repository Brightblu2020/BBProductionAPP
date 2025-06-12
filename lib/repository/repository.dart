import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:bb_factory_test_app/models/bluetooth_model.dart';
import 'package:bb_factory_test_app/models/charger_model.dart';
import 'package:bb_factory_test_app/models/ocpp_config_model.dart';
import 'package:bb_factory_test_app/models/wifi_model.dart';
import 'package:bb_factory_test_app/utils/enums/esp_functions_enum.dart';
import 'package:bb_factory_test_app/utils/enums/network_type.dart';
import 'package:path_provider/path_provider.dart';

class BLEMessage {
  final String data;
  final String timestamp;

  BLEMessage({required this.data, required this.timestamp});
// Convert the instance to a JSON-friendly map
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() => 'BLEMessage(data: $data, timestamp: $timestamp)';
}

class Repository {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? logCharacteristic;

  // Private callback variables
  Function(BluetoothDevice device)? _onDeviceConnected;
  Function(BluetoothCharacteristic characteristic)? _onLogCharacteristicFound;

  // Add BleService members
  BluetoothCharacteristic? rxCharacteristic;
  BluetoothCharacteristic? txCharacteristic;

  final StreamController<List<int>> _responseStreamController =
      StreamController<List<int>>.broadcast();

  // Getter and setter for `onDeviceConnected`
  Function(BluetoothDevice device)? get onDeviceConnected => _onDeviceConnected;
  set onDeviceConnected(Function(BluetoothDevice device)? callback) {
    _onDeviceConnected = callback;
  }

  // // Getter and setter for `onLogCharacteristicFound`

  BluetoothCharacteristic get onLogCharacteristicFound => logCharacteristic!;
  set onLogCharacteristicFound(BluetoothCharacteristic characteristic) {
    logCharacteristic = characteristic;
    // print("Setter invoked with: $callback");
    // if (callback.isNull) {
    //   print("Callback is null.");
    // } else {
    //   print("Callback is valid and being set.");
    // }
    // _onLogCharacteristicFound = callback;

    print("_onLogCharacteristicFound : $_onLogCharacteristicFound");
  }

// StreamController to broadcast logCharacteristic updates
  final StreamController<BluetoothCharacteristic?>
      _logCharacteristicController =
      StreamController<BluetoothCharacteristic?>.broadcast();

  // Getter for the logCharacteristic stream
  Stream<BluetoothCharacteristic?> get logCharacteristicStream =>
      _logCharacteristicController.stream;

  final StreamController<String> _responseController =
      StreamController<String>.broadcast();

  StreamSubscription<List<int>>? getData =
      (null as StreamSubscription<List<int>>?);

  Stream<String> get responseStream => _responseController.stream;
  static const String requestOTPUrl =
      // "http://127.0.0.1:5001/comissioningappbrightblu/us-central1/commissionAuth"
      "https://commissionauth-atlx2q3jjq-uc.a.run.app";
  static const String verifyOTPUrl =
      // "http://127.0.0.1:5001/comissioningappbrightblu/us-central1/verifyOTP"
      "https://verifyotp-atlx2q3jjq-uc.a.run.app";
  // Singleton Pattern (optional, if you want to access this globally)
  static final Repository _instance = Repository._internal();
  factory Repository() => _instance;
  // Repository._internal();
// StreamController to manage the list
  final _controller = StreamController<List<String>>.broadcast();

  // Internal list to store values
  final List<String> _values = [];

  // Getter for the stream
  Stream<List<String>> get stream => _controller.stream;
  Repository._internal() {
    _controller.sink.add(_values);
  }
  // Method to add a value to the list
  void addValue(String value) {
    print("\nBefore adding values : $value");
    _values.add(value);
    print("Before adding values 1 : $_values    ${_values.length}");
    _controller.sink.add(_values); // Emit updated list
  }

  // Get the current list
  List<String> get currentList => _values;
  void dispose() {
    _controller.close();
  }

  final _dio = Dio();
  Future<void> startListening({
    required BluetoothModel model,
    required bool status,
  }) async {
    print("Sending packet : [ChangeConfiguration,{key:bleSerial,value:true}]");
    try {
      final resp = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"bleSerial","value":"true"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      print("Resp : $resp");
      if (resp != null) {
        _responseController.add(resp.toString());

        // Add response to the stream
      }
      await Future.delayed(Duration(seconds: 1)); // Control polling rate
    } catch (e) {
      debugPrint("----errr---- $e");
    }
  }

  /// Standard fucntion to get BLE responses from stream depending upon Provided [ESPFUNCTIONS]
  // Future<Map<String, dynamic>> _getBLEResponse({
  //   required String message,
  //   required ESPFUNCTIONS bleResponse,
  //   required BluetoothModel bluetoothModel,
  //   int? index,
  // }) async {
  //   if (bluetoothModel.writeCharacterstic != null) {
  //     final result = <String, dynamic>{};
  //     try {
  //       await bluetoothModel.writeCharacterstic!.write(
  //         utf8.encode(message),
  //         withoutResponse: false,
  //       );
  //     } catch (e) {
  //       debugPrint("------ BLE response error ----- ${e.toString()}");
  //     }
  //     try {
  //       final completer = Completer<Map<String, dynamic>>();
  //       final subscription = bluetoothModel.readCharacterstic!.onValueReceived
  //           .timeout(const Duration(seconds: 10), onTimeout: (data) {
  //         data.close();
  //         debugPrint("---- ble reponse timeout ----");
  //         completer.complete({});
  //       }).listen((data) async {
  //         debugPrint("------ data received  -------- ${data.toString()}");
  //         if (data.isNotEmpty) {
  //           final message = utf8.decode(data, allowMalformed: true);
  //           if (message.isNotEmpty && message[0] == "[") {
  //             final list = jsonDecode(message) as List<dynamic>;
  //             if (bleResponse == ESPFUNCTIONS.TRIGGER_MESSAGE ||
  //                 getESPNotifications(list[0] as String) == bleResponse) {
  //               // subscription?.cancel();
  //               debugPrint("----- BLE message --- $message");

  //               result.addAll((index != null && list.length > 2)
  //                   ? (list[index])
  //                   : list[1] as Map<String, dynamic>);
  //               completer.complete(result);
  //               // debugPrint("---- map data added --- $result");
  //             }
  //           } else {
  //             debugPrint("error in data $message");
  //           }
  //         }
  //       });
  //       result
  //         ..clear()
  //         ..addAll(await completer.future);
  //       await subscription.cancel();
  //     } catch (e) {
  //       debugPrint('Stream empty $e');
  //     }
  //     // debugPrint("---- map data added --- $result");
  //     return result;
  //   }
  //   return {};
  // }

  //Start Logs
// BluetoothDevice? connectedDevice;
//   BluetoothCharacteristic? logCharacteristic;

  // StreamController for broadcasting BLE logs
  final StreamController<String> _logStreamController =
      StreamController<String>.broadcast();

  // Expose a stream for BLE logs
  Stream<String> get bleLogStream => _logStreamController.stream;

//   Future<void> listenToBLEChargerUpdates(BluetoothModel bluetoothModel) async {
//     bluetoothModel.readCharacterstic!.onValueReceived.listen((event) {
//       if (event.isNotEmpty) {
//         final message = ascii.decode(event, allowInvalid: true);
// print("MESSAGE - $message");
//         try {
//           // Decode the BLE message
//           final List<dynamic> parsedMessage = json.decode(message);
//           print("Parsed MSG : $parsedMessage");
//           if (parsedMessage.length == 2 && parsedMessage[1] is Map) {
//             final content = parsedMessage[1];
//             print("Content : $content");
//             final bleMessage = BLEMessage(
//               data: content['data'],
//               timestamp: content['timestamp'],
//             );
//             print("Final BLE : $bleMessage");
//             _logStreamController.add(jsonEncode(bleMessage)); // Broadcast log
//             debugPrint('Log Added: $bleMessage');
//           } else {
//             debugPrint('Unexpected message format: $message');
//           }
//         } catch (e) {
//           debugPrint('Error parsing message: $e');
//           debugPrint('Raw message: $message');
//           debugPrint('********************');
//         }
//       }
//     });
//   }
  Future<void> listenToBLEChargerUpdates(BluetoothModel bluetoothModel) async {
    bluetoothModel.readCharacterstic!.onValueReceived.listen((event) {
      if (event.isNotEmpty) {
        final message = ascii.decode(event, allowInvalid: true);
        print("MESSAGE - $message");
        try {
          // Decode the BLE message
          final List<dynamic> parsedMessage = json.decode(message);
          print("Parsed MSG : $parsedMessage");
          if (parsedMessage.length == 2 && parsedMessage[1] is Map) {
            final content = parsedMessage[1];
            print("Content : $content");

            final bleMessage = BLEMessage(
              data: content['data'],
              timestamp: content['timestamp'],
            );
            print("Final BLE : $bleMessage");

            // Use toJson before broadcasting

            _logStreamController.add(jsonEncode(bleMessage.toJson()));
            debugPrint('Log Added: $bleMessage');
          } else {
            debugPrint('Unexpected message format: $message');
          }
        } catch (e) {
          debugPrint('Error parsing message: $e');
          debugPrint('Raw message: $message');
          debugPrint('********************');
        }
      }
    });
  }

  Future<void> sendEnableLogsCommand(
      BluetoothModel bluetoothModel, bool start) async {
    final command = start
        ? '["ChangeConfiguration",{"key":"bleSerial","value":"true"}]'
        : '["ChangeConfiguration",{"key":"bleSerial","value":"false"}]';

    final response = await _getBLEResponse(
      message: command,
      bleResponse:
          start ? ESPFUNCTIONS.BLE_LOGS : ESPFUNCTIONS.CHANGE_CONFIGRATION,
      bluetoothModel: bluetoothModel,
    );

    debugPrint("Response from BLE command: $response");

    if (start && response.isNotEmpty) {
      listenToBLEChargerUpdates(bluetoothModel); // Start listening
    }
    // else
    // {
    //   _logStreamController.close();
    // }
  }
  // Future<List> listenToBLEChargerUpdates(BluetoothModel bluetoothModel) async {
  //   List logs = [];
  //   Map<String, dynamic> data = <String, dynamic>{};
  //   // final bluetoothModel = BluetoothModel().obs;
  //   // print("BLUETOOTH MODEL : ${bluetoothModel.value.toString()}");
  //   getData =
  //       bluetoothModel.readCharacterstic!.onValueReceived.listen((event) async {
  //     if (event.isNotEmpty) {
  //       // CONVERSION OF BLE MESSAGE
  //       final message = ascii.decode(event, allowInvalid: true);
  //       // print("MESSAGE1 -- ${message['data']}");

  //       try {
  //         // Attempt to parse the message assuming it conforms to the expected format.
  //         final List<dynamic> parsedMessage = json.decode(message);
  //         if (parsedMessage.length == 2 && parsedMessage[1] is Map) {
  //           final Map<String, dynamic> content = parsedMessage[1];

  //           final bleMessage = BLEMessage(
  //             data: content['data'] ?? 'Unknown',
  //             timestamp: content['timestamp'] ?? 'Unknown',
  //           );
  //           logs.add(bleMessage);
  //           print(bleMessage);
  //           // Perform any other actions with bleMessage as needed.
  //         } else {
  //           print('Unexpected message format: $message');
  //         }
  //       } catch (e) {
  //         print('Error parsing message: $e');
  //         print('Raw message: $message');
  //       }
  //     } else {
  //       print("EVENT -- $event");
  //     }
  //   });
  //   return logs;
  // }

  // Future<List> sendEnableLogsCommand(
  //     BluetoothModel bluetoothModel, bool start) async {
  //   log("BLE model : ${bluetoothModel.bluetoothDevice}");
  //   List logs = [];
  //   final message = jsonEncode({
  //     "ChangeConfiguration": {"key": "bleSerial", "value": "true"}
  //   });
  //   final ReceivePort receivePort = ReceivePort();

  //   if (start) {
  //     final response = await _getBLEResponse(
  //       message: '["ChangeConfiguration",{"key":"bleSerial","value":"true"}]',
  //       bleResponse: ESPFUNCTIONS.BLE_LOGS,
  //       bluetoothModel: bluetoothModel,
  //     );
  //     debugPrint("Response from BLE command: $response");

  //     if (response.isNotEmpty) {
  //       debugPrint("---- Status AAA ----- ${response.toString()} ");
  //       listenToBLEChargerUpdates(bluetoothModel);
  //     }
  //     // return response;
  //   } else {
  //     final response = await _getBLEResponse(
  //       message: '["ChangeConfiguration",{"key":"bleSerial","value":"false"}]',
  //       bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
  //       bluetoothModel: bluetoothModel,
  //     );
  //     if (response.isNotEmpty) {
  //       debugPrint("---- Status AAA ----- ${response.toString()} ");
  //     }
  //   }
  //   return logs;
  // }

  Future<List> getBLEResponseForLogs({
    required String message,
    required ESPFUNCTIONS bleResponse,
    required BluetoothModel bluetoothModel,
    int? noOfpackets,
  }) async {
    final result = <String, dynamic>{};
    List finalList = [];
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
        int packets = noOfpackets ?? 1;
        final subscription = bluetoothModel.readCharacterstic!.onValueReceived
            .timeout(const Duration(seconds: 30), onTimeout: (data) {
          data.close();
          debugPrint("---- ble reponse timeout for logs----");
          completer.complete("");
        }).listen((data) async {
          log("Listen for logs : $data");
          debugPrint(
              "------ stream data received for logs  -------- ${utf8.decode(data, allowMalformed: true)} -------");

          if (data.isNotEmpty) {
            final bleMessage = utf8.decode(data, allowMalformed: true);
            print("BLE Msgs : $bleMessage");
            if (bleMessage.isNotEmpty &&
                bleMessage.startsWith('["Logs') &&
                !bleMessage.startsWith('["Logs",{"data":"bleSerial: "')) {
              print("We are in true for logs");
              res += bleMessage;
              packets--;
            }
            if (packets <= 0) completer.complete(res);
          } else {
            debugPrint("error in data at logs $message");
          }
        });
        res = await completer.future;
        await subscription.cancel();
        log("Res : $res");
        if (res.isNotEmpty) {
          //     result
          // ..clear()
          // ..addAll(_processBLEData1(data: res, bleFuntion: bleResponse));
          //     result
          // ..clear()
          // ..addAll(_processBLEData1(data: res, bleFuntion: bleResponse));
          debugPrint(
              "---- map data added 1--- ${_processBLEData1(data: res, bleFuntion: bleResponse)}");
          finalList = _processBLEData1(data: res, bleFuntion: bleResponse);
        }
      } catch (e) {
        debugPrint('Stream empty logs $e');
      }
      debugPrint("---- map data added --- $result");
      return finalList;
    }
    return [];
  }

  List _processBLEData1(
      {required String data, required ESPFUNCTIONS bleFuntion}) {
    try {
      String processOutput = data;
      log("ProcessedOutput Response : $processOutput");
      final result = jsonDecode(processOutput) as List<dynamic>;
      final result1 = jsonDecode(processOutput);

      debugPrint(
          "----- processedOutput logs : ${result.runtimeType}   ${result.toList().toString()}      Result 1 ${result1}------");
      // if (getESPNotifications(result[0] as String) == bleFuntion) {
      // return result[1] as Map<String, dynamic>;
      log("Processed OUTPUT - ${result1}");
      return result1;
      // }
    } catch (e) {
      debugPrint("------ processOutput exception --- ${e.toString()}");
    }

    return [];
  }

//End
  Future<String> getBLEResponseLogs({
    required ESPFUNCTIONS bleResponse,
    required BluetoothModel bluetoothModel,
    int? noOfpackets,
  }) async {
    final result = <String, dynamic>{};
    List<dynamic> finalList = [];
    if (bluetoothModel.writeCharacterstic != null) {
      try {
        final completer = Completer<String>();
        String res = "";
        int packets = noOfpackets ?? 1;
        final subscription = bluetoothModel.readCharacterstic!.onValueReceived
            .timeout(const Duration(seconds: 30), onTimeout: (data) {
          data.close();
          debugPrint("---- ble reponse timeout ----");
          completer.complete("");
        }).listen((data) async {
          log("Listen in logs: $data");
          debugPrint(
              "------ stream data received  in logs -------- ${utf8.decode(data, allowMalformed: true)} -------");

          if (data.isNotEmpty) {
            final bleMessage = utf8.decode(data, allowMalformed: true);

            if (bleMessage.isNotEmpty) {
              print("We are in true in logs");
              res += bleMessage;
              packets--;
            } else {
              print("--- BLE MSG : $bleMessage");
              addValue(bleMessage);
            }
            if (packets <= 0) completer.complete(res);
          } else {
            debugPrint("error in data logs ");
          }
        });
        res = await completer.future;
        await subscription.cancel();
        log("Res logs current : $res");
        if (res.isNotEmpty) {
          // result
          //   ..clear()
          //   ..addAll(_processBLEData1(data: res, bleFuntion: bleResponse));
          addValue(res);
          finalList.add(res);
          // debugPrint("---- map data added finalList b4--- $finalList");

          return res;
        }
      } catch (e) {
        debugPrint('Stream empty $e');
      }
      debugPrint("---- map data added finalList--- $finalList");
      // return res;
    }
    return '';
  }

  Future<Map<String, dynamic>> _getBLEResponse({
    required String message,
    required ESPFUNCTIONS bleResponse,
    required BluetoothModel bluetoothModel,
    int? noOfpackets,
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
        int packets = noOfpackets ?? 1;
        final subscription = bluetoothModel.readCharacterstic!.onValueReceived
            .timeout(const Duration(seconds: 10), onTimeout: (data) {
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

              res += bleMessage;
              packets--;
            }
            if (packets <= 0) completer.complete(res);
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

  Map<String, dynamic> _processBLEData(
      {required String data, required ESPFUNCTIONS bleFuntion}) {
    try {
      String processOutput = data;
      print("processOutput - $processOutput");
      final result = jsonDecode(processOutput);
      debugPrint(
          "----- processedOutput : ${result.runtimeType}  ------ ${result[0]}");
      if (getESPNotifications(result[0] as String) == bleFuntion) {
        print("Inside if getESPNotifications - $result");

        return result[1] as Map<String, dynamic>;
        // return result;
      } else {
        print("Inside else getESPNotifications - $result");
      }
    } catch (e) {
      debugPrint("------ processOutput exception --- ${e.toString()}");
    }

    return {};
  }
//Commented because of OCPP Configuration
  // Future<Map<String, dynamic>> _getBLEResponse({
  //   required String message,
  //   required ESPFUNCTIONS bleResponse,
  //   required BluetoothModel bluetoothModel,
  //   int? noOfpackets,
  // }) async {
  //   final result = <String, dynamic>{};
  //   if (bluetoothModel.writeCharacterstic != null) {
  //     try {
  //       await bluetoothModel.writeCharacterstic!.write(
  //         utf8.encode(message),
  //         withoutResponse: false,
  //       );
  //     } catch (e) {
  //       debugPrint("------ BLE response error ----- ${e.toString()}");
  //     }
  //     try {
  //       final completer = Completer<String>();
  //       String res = "";
  //       int packets = noOfpackets ?? 1;
  //       final subscription = bluetoothModel.readCharacterstic!.onValueReceived
  //           .timeout(const Duration(seconds: 60), onTimeout: (data) {
  //         data.close();
  //         debugPrint("---- ble reponse timeout ----");
  //         completer.complete("");
  //       }).listen((data) async {
  //         log("Listen : $data");
  //         debugPrint(
  //             "------ stream data received  -------- ${utf8.decode(data, allowMalformed: true)} -------");

  //         if (data.isNotEmpty) {
  //           final bleMessage = utf8.decode(data, allowMalformed: true);

  //           if (bleMessage.isNotEmpty && bleMessage.startsWith("[")) {
  //             print("We are in true");
  //             res += bleMessage;
  //             packets--;
  //           }
  //           if (packets <= 0) completer.complete(res);
  //         } else {
  //           debugPrint("error in data $message");
  //         }
  //       });
  //       res = await completer.future;
  //       await subscription.cancel();
  //       log("Res : $res");
  //       if (res.isNotEmpty) {
  //         result
  //           ..clear()
  //           ..addAll(_processBLEData(data: res, bleFuntion: bleResponse));
  //       }
  //     } catch (e) {
  //       debugPrint('Stream empty $e');
  //     }
  //     // debugPrint("---- map data added --- $result");
  //     return result;
  //   }
  //   return {};
  // }

//Commented because of OCPP configuration
  // Map<String, dynamic> _processBLEData(
  //     {required String data, required ESPFUNCTIONS bleFuntion}) {
  //   try {
  //     String processOutput = data;
  //     log("ProcessedOutput Response : $processOutput");
  //     final result = jsonDecode(processOutput) as List<dynamic>;
  //     debugPrint("----- processedOutput : ${result.runtimeType}  ${result.toList().toString()}------");
  //     if (getESPNotifications(result[0] as String) == bleFuntion) {
  //       print('ProcessedOutput if');
  //       return result[1] as Map<String, dynamic>;
  //       // return result;
  //     }
  //   } catch (e) {
  //     debugPrint("------ processOutput exception --- ${e.toString()}");
  //   }

  //   return {};
  // }

  Future<List<ScanResult>?> scanChargers() async {
    try {
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
        // withServices: [Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")],
        // removeIfGone: null,
        // withKeywords: ["BB", "bb"],
        // oneByOne: true,
        androidScanMode: AndroidScanMode.balanced,
        androidUsesFineLocation: true,
      );

      // wait scan complete
      await FlutterBluePlus.isScanning.where((e) => e == false).first;

      subscription.cancel();

      // Updating the list with only brightblu chargers

      output
          .removeWhere((element) => (!element.device.advName.startsWith("BB")));

      return output;
    } catch (e) {
      debugPrint(
          "------ error in scanning BLE devices ------- ${e.toString()}");
    }

    return null;
  }

  Future<List<ScanResult>> _filterBLEDevices(
      {required List<ScanResult> list}) async {
    final result = <ScanResult>[];

    final alternateServiceUUID = Guid("fb1e4001-54ae-4a28-9f74-dfccb248601d");
    final serviceUUID = Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
    for (final model in list) {
      await model.device.discoverServices();
      final index = model.device.servicesList.indexWhere((element) =>
          element.serviceUuid.str == serviceUUID.str ||
          element.serviceUuid.str == alternateServiceUUID.str);
      debugPrint("Index : $index");
      if (index != -1) result.add(model);
    }

    return result;
  }

  Future<bool?> _connectBLE({required BluetoothDevice device}) async {
    try {
      if (device.isConnected) return true;
      await device.connect(
        autoConnect: false,
        mtu: 512,
        timeout: const Duration(seconds: 20),
      );
      return device.isConnected;
    } catch (e) {
      debugPrint("------ failed to connect to BLE device ----${e.toString()}");
    }
    return null;
  }

  Future<BluetoothModel?> configureCharger(
      {required BluetoothDevice device}) async {
    try {
      final isConnected = await _connectBLE(device: device);

      if (isConnected != null && isConnected) {
        if (Platform.isAndroid) {
          await device.requestMtu(517);
        }
        connectedDevice = device;
        await discoverServices1(isConnected);

        /// discover services
        final servicesList = await device.discoverServices();

        print("Service List : ");
        for (var i = 0; i < servicesList.length; i++) {
          log("Service --- $i - ${servicesList[i].characteristics}");
        }

        List<BluetoothService> services = await device.discoverServices();

        //    int indexNotify = servicesList.indexWhere((element) =>
        //     element.uuid.toString() ==
        //     // "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
        //     "fb1e4001-54ae-4a28-9f74-dfccb248601d");

        // if (indexNotify == -1) {
        //   indexNotify = servicesList.indexWhere((element) =>
        //           element.uuid.toString() ==
        //           "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
        //           // "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        //       // "fb1e4001-54ae-4a28-9f74-dfccb248601d"
        //       );
        // }
        //

// if(indexNotify != -1){
//   logCharacteristic = services[0].characteristics[indexNotify];
// }

        /// Our required service
        int index = servicesList.indexWhere((element) =>
                element.uuid.toString() ==
                "6e400001-b5a3-f393-e0a9-e50e24dcca9e"

            // "fb1e4001-54ae-4a28-9f74-dfccb248601d"
            );
        print("Index 1 - $index");
        if (index == -1) {
          index = servicesList.indexWhere((element) =>
              element.uuid.toString() ==
              // "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
              // "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
              "fb1e4001-54ae-4a28-9f74-dfccb248601d");
        }

        if (index == -1) return null;

        /// Index of our read characterstic
        int readIndex = servicesList[index].characteristics.indexWhere(
            (element) =>
                element.uuid.toString() ==
                "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
            // "fb1e4003-54ae-4a28-9f74-dfccb248601d"
            );
        print("Read index : $readIndex");

        if (readIndex == -1) {
          print("If read index");

          readIndex =
              servicesList[index].characteristics.indexWhere((element) =>
                  element.uuid.toString() ==
                  //    "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
                  // "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
                  "fb1e4003-54ae-4a28-9f74-dfccb248601d");
        }

        /// Index of our write characterstic
        int writeIndex = servicesList[index].characteristics.indexWhere(
            (element) =>
                element.uuid.toString() ==
                "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
            // "fb1e4002-54ae-4a28-9f74-dfccb248601d"
            );

        if (writeIndex == -1) {
          print("If write index");
          writeIndex =
              servicesList[index].characteristics.indexWhere((element) =>
                  element.uuid.toString() ==
                  //  "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
                  // "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
                  "fb1e4002-54ae-4a28-9f74-dfccb248601d");
        }

        // Index of our notify characterstic
        int notifyIndex = servicesList[index].characteristics.indexWhere(
            (element) =>
                element.uuid.toString() ==
                "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
            // "fb1e4002-54ae-4a28-9f74-dfccb248601d"
            );

        if (notifyIndex == -1) {
          notifyIndex =
              servicesList[index].characteristics.indexWhere((element) =>
                  element.uuid.toString() ==
                  // "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
                  // "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
                  "fb1e4002-54ae-4a28-9f74-dfccb248601d");
        }

        if (readIndex == -1 || writeIndex == -1 || notifyIndex == -1)
          return null;

        await servicesList[index]
            .characteristics[readIndex]
            .setNotifyValue(true)
            .then((value) => debugPrint("--- set notify value $value"));

        return BluetoothModel.fromJson(
          servicesList[index],
          device,
          servicesList[index].characteristics[readIndex],
          servicesList[index].characteristics[writeIndex],
          servicesList[index].characteristics[notifyIndex],
        );
      }
    } catch (e) {
      debugPrint("---- ble congiure issue ---- ${e.toString()}");
    }
    return null;
  }

  Future<void> discoverServices1(bool isConnected) async {
    print("Is Connected : $isConnected");
    if (!isConnected) {
      log("Device not connected");
    } else {
      try {
        List<BluetoothService> services =
            await connectedDevice!.discoverServices();

        for (var i = 0; i < services.length; i++) {
          log("Logs : ${services[i]}");
        }

        for (BluetoothService service in services) {
          // Check if this is the target service
          print("LogCharacteristic ServiceUUID ${service.uuid.toString()}");

          if (services[2].serviceUuid.toString() ==
              "fb1e4001-54ae-4a28-9f74-dfccb248601d") {
            for (BluetoothCharacteristic characteristic
                in service.characteristics) {
              // Check if this is the target characteristic
              print(
                  "LogCharacteristic ${service.serviceUuid}  ${characteristic.properties.notify}");

              if (service.serviceUuid.toString() ==
                      "fb1e4001-54ae-4a28-9f74-dfccb248601d" &&
                  characteristic.properties.notify) {
                print("LogCharacteristic If");

                logCharacteristic = characteristic;

                if (logCharacteristic == null) return;

                // Subscribe to the characteristic
                await characteristic.setNotifyValue(true);
                print("Sending Command");
                // Send command to enable logs
                String command = jsonEncode([
                  "ChangeConfiguration",
                  {"key": "bleSerial", "value": "true"}
                ]);
                await characteristic.write(utf8.encode(command),
                    withoutResponse: true);

                characteristic.lastValueStream.listen((value) {
                  // setState(() {
                  //   logs.add(utf8.decode(value));
                  // });
                  print("Final Logs : ${utf8.decode(value)}");
                });
                Future.delayed(const Duration(seconds: 20));
                String command1 = jsonEncode([
                  "ChangeConfiguration",
                  {"key": "bleSerial", "value": "false"}
                ]);
                await characteristic.write(utf8.encode(command1),
                    withoutResponse: true);

                // Unsubscribe from the characteristic
                await characteristic.setNotifyValue(false);

                //   _logCharacteristicController.add(logCharacteristic);

                //   // Log the characteristic found
                //   print("LogCharacteristic Found: $logCharacteristic");

                //   // // Trigger or set the callback
                //   if (onLogCharacteristicFound != null) {
                //     print("Triggering onLogCharacteristicFound callback");
                //     print("LogCharacteristic Found if: $logCharacteristic");

                //     onLogCharacteristicFound = logCharacteristic!;
                //     break; // Exit once the correct characteristic is found
                //   } else {
                //     print("onLogCharacteristicFound is not set. Setting it now.");
                //     print("LogCharacteristic Found else: $logCharacteristic");
                //     // Set the callback
                //     onLogCharacteristicFound = logCharacteristic!;

                //     // onLogCharacteristicFound = (logCharacteristic) {
                //     //   print(
                //     //       "Log characteristic received in callback: ${logCharacteristic}");
                //     //   // Handle further logic if needed
                //     //   // onLogCharacteristicFound!(logCharacteristic);
                //     //   logCharacteristic = characteristic;
                //     // };

                //     // Trigger the newly set callback
                //     print("Triggering the newly set callback");
                //     // onLogCharacteristicFound!(logCharacteristic!);
                //     break; // Exit once the correct characteristic is found
                //   }
              }
            }
          }
        }
      } catch (e) {
        print("We are into catch : $e");
      }
    }
  }

  Future<ChargerModel?> connectCharger({required BluetoothModel model}) async {
    try {
      final resp = await _bootCharger(model: model);
      if (resp != null) return resp;
      return ChargerModel(
        chargerId: "",
        serverUrl: "",
        newChargerId: "",
        networkType: NetworkType.WiFi,
        simType: SimType.NONE,
        freemode: false,
      );
    } catch (e) {
      debugPrint("------- failed to connect to charger ------ ${e.toString()}");
    }

    return null;
  }

  Future<bool?> disconnectCharger({required BluetoothModel model}) async {
    try {
      await model.bluetoothDevice!.disconnect(queue: false);
      return model.bluetoothDevice!.isDisconnected;
    } catch (e) {
      debugPrint("------ failure in disconnection ----- ${e.toString()}");
    }
    return null;
  }

  Future<ChargerModel?> _bootCharger({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message:
            '["BootNotification",{"currentTime":${(DateTime.now().millisecondsSinceEpoch ~/ 1000).toString()},"appVersion":"JOLTINSTALLPARTNER"}]',
        bleResponse: ESPFUNCTIONS.BOOT_NOTIFICATION,
        bluetoothModel: model,
      );
      debugPrint('----- resp $resp');
      if (resp.isNotEmpty && (resp['status'] as String) == "Accepted") {
        /// Fetch chargersList from HIVE DB
        // final map = await HiveBox().getChargerList();

        debugPrint("------ ble name ------ ${model.bluetoothDevice!.advName}");

        return ChargerModel.fromBLE(
          chargerId: model.bluetoothDevice!.advName,
          phase: (resp['phase'] as String),
          connector: double.parse(resp['connectors'].toString()),
          firmware: (resp['chargePointFirmwareVersion'] ??
              resp['FirmwareVersion']) as String,
          joltType: resp['chargePointModel'],
          // firmware: resp['FirmwareVersion'] as String,
        );
      }
    } catch (e) {
      debugPrint("--- charger boot exceptiom ---- ${e.toString()}");
    }
    return null;
  }

  Future<List<WifiModel>?> getWifiList({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"listSsid"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
        noOfpackets: 2,
      );
      // Fluttertoast.showToast(
      //     msg: "wifi response $resp", toastLength: Toast.LENGTH_LONG);
      if (resp.isNotEmpty) {
        final data = resp["ssidList"] as List<dynamic>;
        // Fluttertoast.showToast(
        //     msg: "wifi response list $data", toastLength: Toast.LENGTH_LONG);
        if (data.isNotEmpty) {
          final list = <WifiModel>[];
          for (final ssid in data) {
            final model = WifiModel.fromJson(ssid as Map<String, dynamic>);
            list.add(model);
            // if (list.indexWhere((element) => element.ssid == model.ssid) ==
            //     -1) {
            //   list.add(model);
            // }
          }
          return list;
        }
      }
      return <WifiModel>[];
    } catch (e) {
      debugPrint("------- could not get wifi ssids ${e.toString()}");
    }

    return null;
  }

  Future<List<String>?> getRfidList({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"rfidList"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isNotEmpty) {
        final data = resp["rfidList"] as List<dynamic>;
        if (data.isNotEmpty) {
          return data.map((e) => e["rfid"] as String).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint("------- could not get rfid ${e.toString()}");
    }

    return null;
  }

  Future<WifiModel?> getConfiguredWifi({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"wifiSsid"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isNotEmpty) {
        debugPrint("---- Wifi model received ----- ${resp.toString()} ");
        return WifiModel.fromJson(
          {
            "ssid": resp['value'] as String,
            "rssi": "0",
          },
        );
      }
      return WifiModel(
        ssid: "",
        rssi: -1,
        currentConnected: false,
      );
    } catch (e) {
      debugPrint("------- could not get wifi ssids ${e.toString()}");
    }

    return null;
  }

  Stream<String> listenToSerialLogs() async* {
    debugPrint("Inside Serial Logs");
    final bluetoothModel = BluetoothModel().obs;
    print("listen L : ${bluetoothModel.value}");
    try {
      final resp = await getBLEResponseLogs(
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel.value,
      );
      print("Listening : ${resp.toString()}");

      yield resp.toString();
    } catch (e) {
      debugPrint("------- could not get logs");
      yield* Stream.error(e);
    }
  }

  // Stream<String> getSerialLogs({required BluetoothModel model, required bool status}) async* {
  //   debugPrint("Inside Serial Logs");
  //   try {
  //     final resp = await _getBLEResponse(
  //       message: '["ChangeConfiguration",{"key":"bleSerial","value":"true"}]',
  //       bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
  //       bluetoothModel: model,
  //     );
  //   print(resp.toString());

  //    yield resp.toString();

  //   } catch (e) {
  //     debugPrint("------- could not get logs");
  //      yield* Stream.error(e);
  //   }

  // }

  //   Future<void> startListening({required BluetoothModel model, required bool status}) async {
  //   while (true) {
  //     final resp = await _getBLEResponse(
  //       message: '["ChangeConfiguration",{"key":"bleSerial","value":$status}]',
  //       bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
  //       bluetoothModel: model,
  //     );

  //     // Emit the response into the stream
  //     if (resp != null) {
  //       _responseController.add(resp.toString());
  //     }
  //     // Delay to prevent overwhelming the device
  //     await Future.delayed(Duration(seconds: 1)); // Adjust as needed
  //   }
  // }

  Future<String?> getConfiguredIpAddress(
      {required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"ipAddress"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isNotEmpty) {
        debugPrint("---- ipAddress received ----- ${resp.toString()} ");
        return resp['value'] as String;
      }
      return "0.0.0.0";
    } catch (e) {
      debugPrint("------- could not get ipAddress ${e.toString()}");
    }

    return null;
  }

  Future<List<String>?> getChargerId({required BluetoothModel model}) async {
    try {
      final respDefault = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"defaultChargerId"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      final respOcpp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"ocppChargerId"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );

      final result = <String>["", ""];

      if (respDefault.isNotEmpty) {
        result[0] = respDefault['value'] as String;
      }

      if (respOcpp.isNotEmpty) {
        result[1] = respOcpp['value'] as String;
      }

      return result;
    } catch (e) {
      debugPrint("------- could not get ipAddress ${e.toString()}");
    }

    return null;
  }

  Future<String?> getServerUrlDetails({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"serverURL"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isNotEmpty) {
        debugPrint("---- serverUrl received ----- ${resp.toString()} ");
        return resp['value'] as String;
      }
      return "";
    } catch (e) {
      debugPrint("------- could not get serverUrl ${e.toString()}");
    }

    return null;
  }

  Future<HashMap<String, OCPPConfigModel>?> getOCPPConfigDetails(
      {required BluetoothModel model}) async {
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

  Future<HashMap<String, bool>?> getChargerParameters(
      {required BluetoothModel model}) async {
    try {
      final map = HashMap<String, bool>();
      const groundMask = "GNDMSK", tempMask = "TMPMSK", smpMask = "SMPMSK";
      // --------------- Ground Mask ------------
      final respG = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"$groundMask"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (respG.isNotEmpty) {
        debugPrint(
            "---- ChargerParameters : GNDMSK  ----- ${respG.toString()} ");
        map[groundMask] = respG['value'] as bool;
      }

      // --------------- Temprature Mask ------------
      final respT = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"$tempMask"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (respT.isNotEmpty) {
        debugPrint(
            "---- ChargerParameters : TMPMSK  ----- ${respT.toString()} ");
        map[tempMask] = respT['value'] as bool;
      }

      // --------------- SMPS Mask ------------
      final respS = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"$smpMask"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (respS.isNotEmpty) {
        debugPrint(
            "---- ChargerParameters : GNDMSK  ----- ${respS.toString()} ");
        map[smpMask] = respS['value'] as bool;
      }

      return map;
    } catch (e) {
      debugPrint("------- could not get chargerParameters ${e.toString()}");
    }

    return null;
  }

  Future<String?> getChargerboxFimrware({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"chargeBoxFirmware"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty) return "";
      return resp['value'] as String;
    } catch (e) {
      debugPrint("------ error in getChargerboxFimrware -----${e.toString()}");
    }
    return null;
  }

  Future<bool?> getFreemode({required BluetoothModel bluetoothModel}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"freemode"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      if (resp.isEmpty) return null;
      if ((resp['value'] as String) == "true") {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("------ error in freemode -----${e.toString()}");
    }
    return null;
  }

  Future<bool?> getSDCardStatus({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"sdCardStatus"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty) return false;
      return resp['value'] as bool;
    } catch (e) {
      debugPrint("------ error in getChargerboxFimrware -----${e.toString()}");
    }
    return null;
  }

  Future<String?> getTOTP({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["GetConfiguration",{"key":"generateOTP"}]',
        bleResponse: ESPFUNCTIONS.GET_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty) return "";
      return resp['value'] as String;
    } catch (e) {
      debugPrint("------ error in getting TOTP -----${e.toString()}");
    }
    return null;
  }

  Future<bool?> changeWifiDetails({
    required String username,
    required String password,
    required BluetoothModel model,
  }) async {
    try {
      final resp = await _getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"wifiConfiguration","value":"$username:$password"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- wifi name accepted");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("----- failure in configuring the wifi ---- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> changeDeviceIDDetails({
    required BluetoothModel model,
    required String name,
  }) async {
    try {
      final resp = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"deviceId","value":"$name"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- device ID accepted");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint(
          "----- failure in configuring the device ID ---- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> changeServerUrlDetails({
    required BluetoothModel model,
    required String url,
  }) async {
    try {
      final resp = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"URL","value":"$url"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- server url accepted");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint(
          "----- failure in configuring the server details ---- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> changeOCPPConfigDetails({
    required BluetoothModel model,
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

  Future<bool?> changeChargerParameters({
    required BluetoothModel model,
    required String key,
    required bool value,
  }) async {
    try {
      final resp = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"$key","value":"$value"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- chargerParameter $key is accepted -------");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("---- chargerParameter $key is failed ----- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> basicAuthDetails({
    required BluetoothModel model,
    required String username,
    required String password,
  }) async {
    try {
      debugPrint("--- UsernamePassword : $username:$password");
      final resp = await _getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"basicAuth","value":"$username:$password"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- basicAuth accepted");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint(
          "----- failure in configuring the basicAuth ---- ${e.toString()}");
    }

    // return null;
  }

  Future<bool?> configureMaxCurrentLimit({
    required BluetoothModel model,
    required String current,
  }) async {
    try {
      final resp = await _getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"maxCurrentLimit","value":"$current"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- maxcurrentLimit is accepted");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint(
          "----- failure in configuring the maxCurrentLimit ---- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> configureAddRfid({required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"addRfid"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty) return null;
      if (resp['status'] as String == "Accepted") return true;
      return false;
    } catch (e) {
      debugPrint("------ failure in adding Rfid ---- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> configureDeleteRfid(
      {required BluetoothModel model, required String rfid}) async {
    try {
      final resp = await _getBLEResponse(
        message:
            '["ChangeConfiguration",{"key":"deleteRfid", "value":"$rfid"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );
      if (resp.isEmpty) return null;
      if (resp['status'] as String == "Accepted") return true;
      return false;
    } catch (e) {
      debugPrint("------ failure in deleting Rfid ---- ${e.toString()}");
    }

    return null;
  }

  Future<bool?> changeFreemode({
    required bool value,
    required BluetoothModel bluetoothModel,
  }) async {
    try {
      debugPrint("---- freemode -- $value");
      final respName = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"freemode","value":$value}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: bluetoothModel,
      );
      if (respName.isEmpty || respName['status'] as String != "Accepted") {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("------ Failed to to put charger on freemode ---------");
    }
    return null;
  }

  Future<bool?> resetCharger({
    required BluetoothModel model,
    required String type,
  }) async {
    try {
      final resp = await _getBLEResponse(
        message: '["ChangeConfiguration",{"key":"reset","value":"$type"}]',
        bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
        bluetoothModel: model,
      );

      if (resp.isNotEmpty && resp['status'] as String == "Accepted") {
        debugPrint("---- charger reset is accepted");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("----- failure to reset the charger ---- ${e.toString()}");
    }

    return null;
  }

  //TODO: Fetch values and update the [ChargerModel]

  Future<Map<String, dynamic>?> triggerStatusNotification(
      {required BluetoothModel model}) async {
    try {
      final resp = await _getBLEResponse(
        message: '["TriggerMessage",{"requestedMessage":"StatusNotification"}]',
        bleResponse: ESPFUNCTIONS.STATUS_NOTIFICATION,
        bluetoothModel: model,
      );
      final data = <String, dynamic>{};
      if (resp.isNotEmpty) {
        for (final map in resp["Params"] as List<dynamic>) {
          data.addIf(true, map['key'] as String, map['value']);
        }
      }
      return data;
    } catch (e) {
      debugPrint(
          "------ error in triggerStatusNotification ------${e.toString()}");
    }
    return null;
  }

  Future<String?> requestOTP({required Map<String, dynamic> data}) async {
    try {
      final resp = await _dio.get(
        requestOTPUrl,
        queryParameters: data,
      );

      // final resp = await http.get(Uri.parse(_urlHelper(requestOTPUrl, data)));
      if (resp.statusCode == 200) {
        debugPrint("------ requestOTP ---------- ${resp.data.runtimeType}");
        final body = ((resp.data) as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        final response =
            ((resp.data) as Map<String, dynamic>)['response'] as String;
        if (response == "1") {
          return body['startTimestamp'].toString();
        } else {
          return "";
        }
      }
    } catch (e) {
      debugPrint("----- error in requesting OTP -------- ${e.toString()}");
    }
    return null;
  }

  Future<bool?> verifyOTP({required Map<String, dynamic> data}) async {
    try {
      final resp = await _dio.get(
        verifyOTPUrl,
        queryParameters: data,
      );
      if (resp.statusCode == 200) {
        debugPrint("------ verifyOTP ----------- ${resp.data}");
        final body = (resp.data) as Map<String, dynamic>;
        if (body['response'] == "1") {
          return true;
        } else if (body['response'] == "0") {
          return false;
        } else {
          Fluttertoast.showToast(msg: "Kindly request a new OTP");
          return false;
        }
      }
    } catch (e) {
      debugPrint("----- error in verifying OTP -------- ${e.toString()}");
    }
    return null;
  }

  Future<String?> getLatestFirmwareFirebase() async {
    try {
      // debugPrint(await firebaseStorage.list());
      final firebaseStorage = FirebaseStorage.instance.ref("/3.0");
      final resp = await firebaseStorage.list();
      String result = "";
      int max = 0;
      for (final firmware in resp.items) {
        final metaData = await firmware.getMetadata();
        if (metaData.updated!.millisecondsSinceEpoch >= max) {
          result = firmware.name;
          max = metaData.updated!.millisecondsSinceEpoch;
        }
      }
      debugPrint("------ firestorage result ---$result");
      return result;
    } on FirebaseException catch (e) {
      debugPrint("Fetch update failure. ${e.message}");
    }

    return null;
  }

  Future<File?> downloadFirmware() async {
    try {
      // debugPrint(await firebaseStorage.list());
      final firebaseStorage = FirebaseStorage.instance.ref("/3.0");
      final resp = await firebaseStorage.list();
      final directory = await getApplicationDocumentsDirectory();
      File result = File('${directory.path}/firmware.bin');
      try {
        if ((await result.length()) != 0) {
          await result.delete().then(
              (value) => debugPrint("------ file existed now deleted -----"));
          result = File('${directory.path}/firmware.bin');
        }
      } catch (e) {
        debugPrint("----- failure in deleting the file ------");
      }
      int max = 0, i = 0, index = 0;
      for (i = 0; i < resp.items.length; i++) {
        final metaData = await resp.items[i].getMetadata();
        if (metaData.updated!.millisecondsSinceEpoch >= max) {
          index = i;
          max = metaData.updated!.millisecondsSinceEpoch;
        }
      }
      final bytes = await resp.items[index].getData();
      if (bytes != null) {
        return await result.writeAsBytes(bytes);
      }
      debugPrint("------ firestorage result ---$result");
      // return result;
    } catch (e) {
      debugPrint("Fetch update failure. ${e.toString()}");
    }

    return null;
  }

  // Add the sendMessage function
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
}
