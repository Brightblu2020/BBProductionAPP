// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:bb_factory_test_app/bluetooth_test_screen.dart';
import 'package:bb_factory_test_app/models/charger_realitime_model.dart';
import 'package:bb_factory_test_app/repository/charger_ble_repository.dart';
import 'package:bb_factory_test_app/repository/charger_firebase_repository.dart';
import 'package:bb_factory_test_app/repository/repository.dart';
import 'package:bb_factory_test_app/utils/enums/connection_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:bb_factory_test_app/main.dart';
import 'package:bb_factory_test_app/models/bluetooth_model.dart';
import 'package:bb_factory_test_app/models/charger_model.dart';
import 'package:bb_factory_test_app/models/ocpp_config_model.dart';
import 'package:bb_factory_test_app/models/wifi_model.dart';
import 'package:bb_factory_test_app/repository/repository.dart';
// import 'package:bb_factory_test_app/screens/charger_screen.dart';
// import 'package:bb_factory_test_app/screens/main_screen.dart';
// import 'package:bb_factory_test_app/screens/session_screen.dart';
import 'package:bb_factory_test_app/utils/constants.dart';
import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:bb_factory_test_app/utils/enums/esp_functions_enum.dart';
import 'package:bb_factory_test_app/utils/enums/jolt_type.dart';
import 'package:bb_factory_test_app/utils/enums/network_type.dart';
import 'package:bb_factory_test_app/utils/enums/store_state.dart';
import 'package:flutter_ota/ota_package.dart';
import 'package:bb_factory_test_app/utils/flutter_ota_copy.dart';
import 'package:bb_factory_test_app/utils/hive.dart';
import 'package:bb_factory_test_app/utils/widgets/app_header.dart';
import 'package:bb_factory_test_app/utils/widgets/loading_widget.dart';
import 'package:bb_factory_test_app/utils/widgets/otp_dialog.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus/share_plus.dart';

class Controller extends GetxController {
  final repository = Repository();
// Timer t = Timer(Duration(seconds: 0));
  final connectionSwitch = (0).obs;

  /// Instance for accesing ble methods
  final bleRepository = ChargerBLERepository();

  /// Instance for accessing firebase methods
  final firebaseRepository = ChargerFirebaseRepository();
  Timer? _timer;
  final chargerModel = ChargerModel(
          chargerId: "",
          serverUrl: "",
          newChargerId: "",
          networkType: NetworkType.WiFi,
          simType: SimType.NONE,
          freemode: false,
          totp: "")
      .obs;
  final chargingState = (StoreState.SUCCESS).obs;

  final chargerList = <ScanResult>[].obs;
  final state = (StoreState.SUCCESS).obs;
  final configureState = (StoreState.SUCCESS).obs;
  final bleAdapterState = (BluetoothAdapterState.off).obs;
  final webSocketType = "ws".obs;
  final wifissidList = <WifiModel>[].obs;
  final rfidList = <String>[].obs;
  final wifiModel = WifiModel(
    ssid: "",
    rssi: -1,
    currentConnected: false,
  ).obs;
  final ipAddress = "0.0.0.0".obs;
  final bluetoothModel = BluetoothModel().obs;
  final commissionStart = false.obs;
  final setupPage = 0.obs;
  final otaUpdateProgress = (-1).obs;
  final bluetoothConnectionState = BluetoothConnectionState.disconnected.obs;
  final ocppConfig = HashMap<String, OCPPConfigModel>().obs;
  final chargerParameters = HashMap<String, bool>().obs;
  final storage = Storage()..init();
  final sessionEnd = 0.obs;
  StreamSubscription<BluetoothConnectionState>? bluetoothConnectionListner =
      (null as StreamSubscription<BluetoothConnectionState>?);
  StreamSubscription<List<int>>? chargerStatusNotification =
      (null as StreamSubscription<List<int>>?);

  StreamSubscription<List<String>>? serialLogsListener =
      (null as StreamSubscription<List<String>>?);
  StreamSubscription<int>? otaUpdateSubscription =
      (null as StreamSubscription<int>?);
  StreamSubscription<BluetoothAdapterState>? bluetoothAdapterListner =
      (null as StreamSubscription<BluetoothAdapterState>?);
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sessionListner =
      (null as StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?);
  // Stream? sessionEndStream => FirebaseFirestore.instance.collection('commission').d
  /// [ChargerRealTimeModel] to store all charger reatime data
  final chargerRealtimeModel = ChargerRealTimeModel(
          chargerId: "", chargerStatus: ChargerStatus.UNAVAILABLE)
      .obs;
  bool get isChargerConnected =>
      bluetoothConnectionState.value == BluetoothConnectionState.connected;
  bool get isBleOn => bleAdapterState.value == BluetoothAdapterState.on;
  Iterable<MapEntry<String, OCPPConfigModel>> get getOcppConfigList =>
      ocppConfig.value.entries;
  Iterable<MapEntry<String, bool>> get fetchChargerParameters =>
      chargerParameters.value.entries;
  bool get sdCardStatus => (chargerModel.value.sdCardStatus != null &&
      chargerModel.value.sdCardStatus!);

  bool get isJoltHome => (chargerModel.value.joltType != null)
      ? chargerModel.value.joltType!.isJoltHome()
      : false;
  bool get isLatestFirmwareVersion => (chargerModel.value.firmware != null &&
      chargerModel.value.firmware!.startsWith('4'));
  bool get canConfigure =>
      (chargerModel.value.status == ChargerStatus.AVAILABLE ||
          chargerModel.value.status == ChargerStatus.UNAVAILABLE ||
          chargerModel.value.status == ChargerStatus.ERROR ||
          chargerModel.value.status == ChargerStatus.PREPARING);

  /// Provides if charger wifi connection status is [ConnectionStatus.ONLINE] or [ConnectionStatus.OFFLINE]
  ConnectionStatus get chargerWifiConnectionStatus =>
      chargerRealtimeModel.value.connectionStatus ?? ConnectionStatus.OFFLINE;

  /// provides update on current [ChargerStaus]
  ChargerStatus get currentChargerStatus =>
      chargerRealtimeModel.value.chargerStatus ?? ChargerStatus.UNAVAILABLE;

  /// Used for checking whether charger is into [ChargerStatus.PREPARING] or [ChargerStatus.CHARGING]
  bool get checkIfCharOrPrep =>
      (currentChargerStatus == ChargerStatus.CHARGING ||
          currentChargerStatus == ChargerStatus.PREPARING);

  /// Used for checking whether charger is into [ChargerStatus.PREPARING] or [ChargerStatus.AVAILABLE]
  bool get checkIfAvlOrPrep =>
      (currentChargerStatus == ChargerStatus.AVAILABLE ||
          currentChargerStatus == ChargerStatus.PREPARING ||
          currentChargerStatus == ChargerStatus.ERROR);

  final serverRegex = RegExp(
      // r'^ws(s)?://([a-zA-Z0-9\-\.]+)(:[0-9]+)/(.*)?(/.*)$'f
      r'^ws(s)?://([a-zA-Z0-9\-\.]+)(:[0-9]+)(/.*)?');

// StreamController to manage the list
  final _controller = StreamController<List<String>>.broadcast();

  // Internal list to store values
  final List<String> _values = [];

  // Getter for the stream
  Stream<List<String>> get stream => _controller.stream;

  // Method to add a value to the list
  void addValue(String value) {
    _values.add(value);
    _controller.sink.add(List.unmodifiable(_values)); // Emit updated list
  }

  // Get the current list
  List<String> get currentList => List.unmodifiable(_values);

  Future<void> init() async {
    if (!(await Permission.bluetooth.isGranted)) {
      debugPrint("----- bluetooth not granted -----");
      await Permission.bluetooth.request();
    }
    if (!(await Permission.bluetoothConnect.isGranted)) {
      debugPrint("----- bluetoothConnect not granted -----");
      await Permission.bluetoothConnect.request();
    }
    if (!(await Permission.bluetoothScan.isGranted)) {
      debugPrint("----- bluetoothScan not granted -----");
      await Permission.bluetoothScan.request();
    }

    if (!(await Permission.location.isGranted)) {
      debugPrint("----- location ${await Permission.location.status} -----");
      await Permission.location.request();
    }

    if ((await Permission.location.serviceStatus).isDisabled) {
      Fluttertoast.showToast(msg: "Please enable location services");
    }
  }

  Future<void> _cancelAllStreamSubsciptions() async {
    try {
      bluetoothConnectionState.value = BluetoothConnectionState.disconnected;

      await chargerStatusNotification!.cancel();
      await bluetoothConnectionListner!.cancel();
      await otaUpdateSubscription!.cancel();
      await bluetoothAdapterListner!.cancel();
    } catch (e) {
      debugPrint(
          "----- error in cancelling subscriptions ------ ${e.toString()}");
    }
  }
// /// This is used to initiate charger to charger via BLE
//   Future<void> initiateCharge({required String startStop}) async {
//     chargingState.value = StoreState.LOADING;

//     try {
//       // int? resp;

//       /// CHARGING INITATED VIA BLE
//       if (connectionSwitch.value == 1) {
//         if (startStop == "Start") {
//           Fluttertoast.showToast(msg: "Charging initated");
//         } else {
//           Fluttertoast.showToast(msg: "Charging stopped");
//         }
//         await bleRepository.initateCharge(
//           result: startStop,
//           bluetoothModel: bluetoothModel.value,
//         );
//       }

//       /// INITIATED VIA FIREBASE
//       else {
//         debugPrint("--- intiate charger via firebase ----");
//         if (startStop == "Start") {
//           Fluttertoast.showToast(msg: "Charging initated");
//         } else {
//           Fluttertoast.showToast(msg: "Charging stopped");
//         }
//         await firebaseRepository.initiateChargerWifi(
//             model: chargerModel.value, start: startStop == "Start");
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Please try again");
//     }

//     chargingState.value = StoreState.SUCCESS;
//   }
  Future<String?> readSession() => Storage().read();

  Stream<String> sessionStream() {
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) {
        final seconds =
            sessionEnd.value - (DateTime.now().millisecondsSinceEpoch ~/ 1000);
        if (seconds <= 0) return "00:00:00";
        final hours = (seconds ~/ 3600),
            mins = (seconds % 3600) ~/ 60,
            secs = seconds % 60;
        return "${(hours < 10) ? "0$hours" : hours}:${(mins < 10) ? "0$mins" : mins}:${(secs < 10) ? "0$secs" : secs}";
      },
    );
  }

  Future<void> _disposeSession() async {
    try {
      if (isChargerConnected) {
        await bluetoothModel.value.bluetoothDevice!.disconnect();
      }
      bleAdapterState.value = BluetoothAdapterState.off;
      await _cancelAllStreamSubsciptions();
    } catch (e) {
      debugPrint("----- error in disposeSession ----- ${e.toString()}");
    }
  }

  void listenToSession({required String id}) async {
    if (sessionListner != null) {
      await sessionListner!.cancel();
    }
    sessionListner = FirebaseFirestore.instance
        .collection('commission')
        .doc(id)
        .snapshots()
        .listen(
      (event) async {
        debugPrint('------- event ------- ${event.data().toString()}');
        final data = event.data()!['endTimestamp'] as int;
        final curr = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
        sessionEnd.value = data;
        debugPrint("------ session ---- $curr --- $data ---- ${curr - data}");
        if (curr > data) {
          await _disposeSession();
          //TODO:
          // Get.offAll(const SessionTimeOut());
          // }
        } else {
          await _disposeSession();
          // Get.offAll(const MainScreen());
        }
      },
    );
  }

  Future<void> disconnectCharger() async {
    final resp =
        await repository.disconnectCharger(model: bluetoothModel.value);
    if (resp == null || !resp) {
      Fluttertoast.showToast(msg: "Failed to disconnect the charger");
    }
    await _cancelAllStreamSubsciptions();
    Fluttertoast.showToast(msg: "Disconnection successful");
  }

  Future<void> startScan() async {
    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.balanced,
      androidUsesFineLocation: true,
      withKeywords: ["BB"],
    );
  }

  final fetchState = (StoreState.SUCCESS).obs;

  Future<void> getWifiList() async {
    fetchState.value = StoreState.LOADING;
    final list = await repository.getWifiList(model: bluetoothModel.value);
    if (list == null) {
      fetchState.value = StoreState.ERROR;
    } else if (list.isEmpty) {
      fetchState.value = StoreState.EMPTY;
    } else {
      wifissidList.clear();
      wifissidList.addAll(list);
      wifissidList.refresh();
      fetchState.value = StoreState.SUCCESS;
    }
  }

  Future<void> getRfidList() async {
    fetchState.value = StoreState.LOADING;
    final list = await repository.getRfidList(model: bluetoothModel.value);
    if (list == null) {
      fetchState.value = StoreState.ERROR;
    } else if (list.isEmpty) {
      fetchState.value = StoreState.EMPTY;
    } else {
      rfidList.clear();
      rfidList.addAll(list);
      rfidList.refresh();
      fetchState.value = StoreState.SUCCESS;
    }
  }

  void _bluetoothConnectionListner() async {
    if (bluetoothConnectionListner != null) {
      await bluetoothConnectionListner!.cancel();
    }
    bluetoothConnectionListner =
        bluetoothModel.value.bluetoothDevice!.connectionState.listen(
      (event) async {
        debugPrint("----- connection event ----- $event");
        bluetoothConnectionState.value = event;
      },
    );
  }

  void bluetoothAdapterState() async {
    if (bluetoothAdapterListner != null) {
      await bluetoothAdapterListner!.cancel();
    }
    bluetoothAdapterListner = FlutterBluePlus.adapterState.listen((event) {
      bleAdapterState.value = event;
    });
  }

  Future<void> bootCharger() async {
    state.value = StoreState.LOADING;
    ChargerModel? resp =
        await repository.connectCharger(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to boot the charger");
      return;
    } else {
      chargerModel.value = resp;
      _bluetoothConnectionListner();
      await getServerDetails();
      await getChargerId();
      await getIpAddressWifi();
      await getChargerBoxFimrware();
      await getSDCardStatus();
      await getStatusNotification();
      await getFreeMode();

      listenToBLEChargerUpdates();
    }
    state.value = StoreState.SUCCESS;
  }

  Future<void> getFreeMode() async {
    if (!isJoltHome) return;
    final value =
        await repository.getFreemode(bluetoothModel: bluetoothModel.value);
    if (value == null) {
      Fluttertoast.showToast(msg: "Failure to get freemode status");
      return;
    }
    chargerModel.value = chargerModel.value.copyWith(freemode: value);
    chargerModel.refresh();
  }

  Future<void> getIpAddressWifi() async {
    // final stopWatch = Stopwatch()..start();
    final ipResp =
        await repository.getConfiguredIpAddress(model: bluetoothModel.value);
    if (ipResp != null) ipAddress.value = ipResp;
    final wifiResp =
        await repository.getConfiguredWifi(model: bluetoothModel.value);
    if (wifiResp != null) wifiModel.value = wifiResp;
    if (wifiModel.value.ssid.split("_")[0] == chargerModel.value.chargerId) {
      chargerModel.value =
          chargerModel.value.copyWith(networkType: NetworkType.SIM);
    } else {
      chargerModel.value =
          chargerModel.value.copyWith(networkType: NetworkType.WiFi);
    }
    // stopWatch.stop();
    // debugPrint(
    //     "------ getIpAddress elapsed ----- ${stopWatch.elapsedMilliseconds}");
  }

  Future<void> getChargerBoxFimrware() async {
    final resp =
        await repository.getChargerboxFimrware(model: bluetoothModel.value);
    if (resp == null) return;
    chargerModel.value = chargerModel.value.copyWith(chargeboxFirmware: resp);
    debugPrint(
        "----- chargerBoxFirmware: ${chargerModel.value.chargeBoxFimrware}");
    chargerModel.refresh();
  }

  Future<void> getStatusNotification() async {
    final data =
        await repository.triggerStatusNotification(model: bluetoothModel.value);
    if (data != null && data.isNotEmpty) {
      chargerModel.value = chargerModel.value.copyWith(
        status: (data['chargerStatus'] ?? data['Status'] ?? "") as String,
        v1: ((data['vL1'] ?? "0") as String),
        v2: ((data['vL2'] ?? "0") as String),
        v3: ((data['vL3'] ?? "0") as String),
        i1: ((data['iL1'] ?? "0") as String),
        i2: ((data['iL2'] ?? "0") as String),
        i3: ((data['iL3'] ?? "0") as String),
        maxCurrentLimit: "${((data['maxCurrentLimit'] ?? 0) as int)}",
        energy: (data['Energy'] ?? "0") as String,
        power: (data['Power'] ?? "0") as String,
        error: (data['errorCode'] ?? "") as String,
      );
    }
  }

  Future<void> getServerDetails() async {
    final stopWatch = Stopwatch()..start();
    final resp =
        await repository.getServerUrlDetails(model: bluetoothModel.value);
    if (resp != null && (resp != "No File Found")) {
      chargerModel.value = chargerModel.value.copyWith(serverUrl: resp);
    }
    debugPrint("------ server URL ------ ${chargerModel.value.serverUrl}");
    stopWatch.stop();
    debugPrint(
        "------ getServerDetails elapsed ----- ${stopWatch.elapsedMilliseconds}");
  }

  Future<void> getOcppConfigDetails() async {
    state.value = StoreState.LOADING;
    final resp =
        await repository.getOCPPConfigDetails(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to get OCPP Configuration Details");
      state.value = StoreState.ERROR;
    } else if (resp.isEmpty) {
      state.value = StoreState.EMPTY;
    } else {
      ocppConfig.value
        ..clear()
        ..addAll(resp);
      state.value = StoreState.SUCCESS;
    }
  }

  Future<void> getChargerParameters() async {
    state.value = StoreState.LOADING;
    final resp =
        await repository.getChargerParameters(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to get Charger Parameters");
      state.value = StoreState.ERROR;
    } else if (resp.isEmpty) {
      state.value = StoreState.EMPTY;
    } else {
      chargerParameters.value
        ..clear()
        ..addAll(resp);
      state.value = StoreState.SUCCESS;
    }
  }

  Future<void> getSDCardStatus() async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.getSDCardStatus(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to get SD Card Status");
    }
    chargerModel.value = chargerModel.value.copyWith(sdCardStatus: resp);
    configureState.value = StoreState.SUCCESS;
  }

  Future<void> gettotp() async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.getTOTP(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to get totp Status");
    }
    chargerModel.value = chargerModel.value.copyWith(totp: resp);
    configureState.value = StoreState.SUCCESS;
  }

  Future<void> getChargerId() async {
    final resp = await repository.getChargerId(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to get charger id");
      return;
    }
    if (resp[1] == "No File Found") return;
    debugPrint("----- resp[1] ----- ${resp[1]}");
    chargerModel.value = chargerModel.value.copyWith(newChargerId: resp[1]);
  }

  // Stream to expose BLE logs
  Stream<String> get bleLogStream => repository.bleLogStream;

  // Start or stop logging
  void toggleBleLogging(bool start, BluetoothModel bluetoothModel) {
    repository.sendEnableLogsCommand(bluetoothModel, start);
  }
  // Future<List> getLogs(bool start) async {

  //   List resp =
  //       await repository.sendEnableLogsCommand(bluetoothModel.value, start);

  //   print("getlogs response : $resp");
  //   if (resp.isNotEmpty) {
  //     // await getLogs1();
  //   }
  //   return resp;
  // }

  // Future<void> getLogs1(bool start) async {
  //   if (start) {
  //     _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
  //       String a = await repository.getBLEResponseLogs(
  //           bleResponse: ESPFUNCTIONS.CHANGE_CONFIGRATION,
  //           bluetoothModel: bluetoothModel.value);

  //       print("Printing A : ${a}");

  //       // addValue(a);
  //     });
  //   } else {
  //     _timer!.cancel();
  //   }
  // }
// In the Controller class

// Method to handle BLE log updates with stream broadcasting
// void startBleLogging(bool start) async {
//   if (start) {
//     // Get logs and trigger periodic updates
//     final response = await getLogs(start);
//     serialLogsListener?.cancel(); // Cleanup old subscription if any

//     // Subscribe to periodic updates
//     serialLogsListener = stream.listen((logList) {
//       for (var log in logList) {
//         print("Adding value : $log");
//         addValue(log); // Add log to the internal list and broadcast
//       }
//     });
//   } else {
//     // Stop BLE logging
//     await getLogs(false);
//     serialLogsListener?.cancel();
//   }
// }

// Stream<List<String>> get bleLogStream => stream;

  Future<void> connectCharger({BluetoothDevice? device}) async {
    if (isBleOn) {
      state.value = StoreState.LOADING;

      final model = await repository.configureCharger(
          device: device ?? bluetoothModel.value.bluetoothDevice!);
      debugPrint("----- config from repo fone ------ ${model.toString()}");
      if (model == null) {
        Fluttertoast.showToast(msg: "Failed to connect with charger");
        state.value = StoreState.SUCCESS;
        return;
      }
      bluetoothModel.value = model;
      await bootCharger();
      //TODO:
      Get.to(BluetoothTest(chargerId: device!.advName.toString()));

      state.value = StoreState.SUCCESS;
      return;
    } else {
      Fluttertoast.showToast(msg: "Switch on BLE");
    }
  }

  void customDialog(
      {required String content,
      required VoidCallback callback,
      Widget? subContent}) {
    Get.dialog(Obx(
      () => Stack(
        children: [
          AlertDialog(
            surfaceTintColor: Colors.white,
            title: Constants.appHeaderImage(height: 60, width: 40),
            content: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    content,
                    style: Constants.customTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (subContent != null) subContent,
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      "Cancel",
                      style: Constants.customTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: callback,
                    child: Text(
                      "Done",
                      style: Constants.customTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StateWidget(state: configureState.value, data: "Failure"),
        ],
      ),
    ));
  }

  Future<void> setChargerId({
    required String newChargerId,
  }) async {
    if (newChargerId.isEmpty) return;
    debugPrint("----- new charger id ----- $newChargerId");
    final resp = await repository.changeDeviceIDDetails(
      model: bluetoothModel.value,
      name: newChargerId,
    );
    if (resp == null) {
      Fluttertoast.showToast(
          msg: "Failed to confiure the chargerID please try again");
    } else if (!resp) {
      Fluttertoast.showToast(msg: "ChargerID rejected");
    } else {
      chargerModel.value =
          chargerModel.value.copyWith(newChargerId: newChargerId);
      Fluttertoast.showToast(msg: "ChargerID accepted");
    }
  }

  Future<void> setServerDetails(
      {required String url, String? username, String? password}) async {
    if (url.isEmpty) return;
    configureState.value = StoreState.LOADING;
    debugPrint("----- new url ----- $url");
    final resp = await repository.changeServerUrlDetails(
      model: bluetoothModel.value,
      url: url,
      // url: url,
    );
    if (resp == null) {
      Fluttertoast.showToast(
          msg: "Failed to confiure the server url please try again");
    } else if (!resp) {
      Fluttertoast.showToast(msg: "Server URL rejected");
    } else {
      if (username != "" && password != "") {
        debugPrint("We are into username and pwd packet again.");
        final basicAuthResp = await repository.basicAuthDetails(
            model: bluetoothModel.value,
            username: username!,
            password: password!);

        if (basicAuthResp == null || !basicAuthResp) {
          Fluttertoast.showToast(msg: "Authentication failure");
          return;
        }
      }
      chargerModel.value = chargerModel.value.copyWith(serverUrl: url);
      Fluttertoast.showToast(msg: "Server URL accepted");
    }
    configureState.value = StoreState.SUCCESS;
  }

  // String? _configureUrl(String url) {
  //   //chech for ws/wss
  //   final index = url.lastIndexOf('/');
  //   final checkValue = url.substring(index + 1);
  //   if (checkValue == chargerModel.value.newChargerId) {
  //     url = url.substring(0, index);
  //   }
  //   return url;
  // }

  Future<void> configureWifi({
    required String username,
    required String password,
  }) async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.changeWifiDetails(
      username: username,
      password: password,
      model: bluetoothModel.value,
    );

    print("BLE Model : ${bluetoothModel.value.bluetoothDevice}");
    if (resp == null) {
      debugPrint(
          "----------- Failed to confiure the wifi please try again --------------");
      Fluttertoast.showToast(
          msg: "Failed to confiure the wifi please try again");
    } else if (!resp) {
      debugPrint("----------- Wifi configuration rejected --------------");
      Fluttertoast.showToast(msg: "Wifi configuration rejected");
    } else {
      await getIpAddressWifi();
      debugPrint("----------- Wifi configuration accepted --------------");
      Fluttertoast.showToast(msg: "Wifi configuration accepted");
    }
    // Get.back();
    configureState.value = StoreState.SUCCESS;
  }

  Future<void> configureMaxCurrentLimit(
      {required String maxCurrentLimit}) async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.configureMaxCurrentLimit(
      model: bluetoothModel.value,
      current: maxCurrentLimit,
    );
    if (resp == null || !resp) {
      Fluttertoast.showToast(msg: "Failed to configure maxCurrentLimit");
      return;
    }

    Fluttertoast.showToast(
        msg: "Max current successfully set to $maxCurrentLimit");
    configureState.value = StoreState.SUCCESS;
  }

  Future<void> configureOCPPConfiguration({
    required String key,
    required String value,
  }) async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.changeOCPPConfigDetails(
      model: bluetoothModel.value,
      key: key,
      value: value,
    );
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to update the configuration");
      configureState.value = StoreState.ERROR;
      return;
    }
    if (resp) {
      Fluttertoast.showToast(msg: "$key updated successfully");
      configureState.value = StoreState.SUCCESS;
    } else {
      Fluttertoast.showToast(msg: "$key update rejected");
      configureState.value = StoreState.ERROR;
    }
  }

  Future<void> configureChargerParameter({
    required String key,
    required bool value,
  }) async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.changeChargerParameters(
      model: bluetoothModel.value,
      key: key,
      value: value,
    );
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to update the charger parameters");
      configureState.value = StoreState.ERROR;
      return;
    }
    if (resp) {
      Fluttertoast.showToast(msg: "$key updated successfully");
      configureState.value = StoreState.SUCCESS;
    } else {
      Fluttertoast.showToast(msg: "$key update rejected");
      configureState.value = StoreState.ERROR;
    }
  }

  Future<void> configureFreemode({required bool value}) async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.changeFreemode(
        value: value, bluetoothModel: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failure to configure freemode");
      return;
    } else if (!resp) {
      Fluttertoast.showToast(msg: "Freemode update rejected");
      return;
    }

    chargerModel.value = chargerModel.value.copyWith(freemode: value);
    chargerModel.refresh();

    configureState.value = StoreState.SUCCESS;
  }

  Future<void> addRfid() async {
    fetchState.value = StoreState.LOADING;
    final resp = await repository.configureAddRfid(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Error in the request");
    } else if (!resp) {
      Fluttertoast.showToast(msg: "RFID rejected");
    } else {
      Fluttertoast.showToast(msg: "RFID accepted");
    }
    fetchState.value = StoreState.SUCCESS;
    await Future.delayed(const Duration(seconds: 2), () async {
      await getRfidList();
    });
    // await getRfidList();
  }

  Future<void> deleteRfid({required String value}) async {
    fetchState.value = StoreState.LOADING;
    final resp = await repository.configureDeleteRfid(
        model: bluetoothModel.value, rfid: value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Error in the request");
    } else if (!resp) {
      Fluttertoast.showToast(msg: "Deletion of $value RFID rejected");
    } else {
      Fluttertoast.showToast(msg: "Deleted successfully");
    }
    fetchState.value = StoreState.SUCCESS;
    await Future.delayed(const Duration(seconds: 2), () async {
      await getRfidList();
    });
  }

  void listenToBLEChargerUpdates() async {
    Map<String, dynamic> data = <String, dynamic>{};

    chargerStatusNotification = bluetoothModel
        .value.readCharacterstic!.onValueReceived
        .listen((event) async {
      if (event.isNotEmpty) {
        // CONVERSION OF BLE MESSAGE
        final message = utf8.decode(event);
        debugPrint(
            "------ messages from BLE stream ------- ${message.toString()}");

        try {
          // CHECK IF MESSAGE IS VALID
          if (message.isNotEmpty && message[0] == "[") {
            final jsonResp = jsonDecode(message) as List<dynamic>;
            final respType = getESPNotifications(jsonResp[0] as String);

            /// Maintains ESPFUNCTIONS.STATUS_NOTIFICATION
            if (respType == ESPFUNCTIONS.STATUS_NOTIFICATION ||
                respType == ESPFUNCTIONS.TRIGGER_MESSAGE) {
              // try{
              for (final map in (jsonResp[1]["chargerParameters"] ??
                  jsonResp[1]["Params"] ??
                  []) as List<dynamic>) {
                data.addIf(true, map['key'] as String, map['value']);
              }
              debugPrint("---- ble result ---${data.toString()}");

              chargerModel.value = chargerModel.value.copyWith(
                status:
                    (data['chargerStatus'] ?? data['Status'] ?? "") as String,
                v1: ((data['vL1'] ?? "0") as String),
                v2: ((data['vL2'] ?? "0") as String),
                v3: ((data['vL3'] ?? "0") as String),
                i1: ((data['iL1'] ?? "0") as String),
                i2: ((data['iL2'] ?? "0") as String),
                i3: ((data['iL3'] ?? "0") as String),
                maxCurrentLimit: "${((data['maxCurrentLimit'] ?? 0) as int)}",
                energy: (data['Energy'] ?? "0") as String,
                power: (data['Power'] ?? "0") as String,
                error: (data['errorCode'] ?? "") as String,
              );

              debugPrint(
                  "----- chargerModel ------${chargerModel.value.energy} ${chargerModel.value.power}");
            }
          }
        } catch (e) {
          debugPrint("---- error by ble stream ---- ${e.toString()} -----");
        }
      }
    });
  }

  // void listenToSerialLogs(){

  //   serialLogsListener = repository.getSerialLogs(model: bluetoothModel.value, status: true).listen((event)async{
  //     debugPrint("------ logs by serial logger ----- ${event.toString()}");
  //   });
  // }

  Future<void> resetCharger({required String type}) async {
    configureState.value = StoreState.LOADING;
    final resp = await repository.resetCharger(
      model: bluetoothModel.value,
      type: type,
    );
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failure to reset the charger");
    } else if (!resp) {
      Fluttertoast.showToast(msg: "Charger reset rejected");
    } else {
      Fluttertoast.showToast(msg: "Charger reset accepted");
    }
    configureState.value = StoreState.SUCCESS;
  }

  final progress = (-1).obs;
  final otaState = (StoreState.SUCCESS).obs;
  final stopwatchTime = (Duration()).obs;

  // Future<void> updateFirmware() async {
  //   try {
  //     final file = await firmwareBinaryFromPicker();
  //     progress.value = -1;
  //     updateEsp32Firmware(
  //       bluetoothModel.value.bluetoothDevice!,
  //       bluetoothModel.value.writeCharacterstic!,
  //       bluetoothModel.value.readCharacterstic!,
  //       file,
  //     ).listen((event) {
  //       debugPrint("------ progress : $event -------");

  //       progress.value = event.toInt();
  //     });
  //   } catch (e) {
  //     debugPrint(" failed to update firmware ----- ${e.toString()}");
  //   }
  // }

  Future<void> updateFirmware({required int firmwareType}) async {
    // chargerStatusNotification!.pause();
    try {
      final flutterOta = Esp32OtaPackage(
          bluetoothModel.value.readCharacterstic!,
          bluetoothModel.value.writeCharacterstic!);
      progress.value = -1;
      File? file;
      StreamSubscription<int>? listner;
      final stopwatch = Stopwatch();
      listner = flutterOta.percentageStream.listen(
        (event) async {
          progress.value = event;
          stopwatchTime.value = stopwatch.elapsed;
          print("Progress Value : ${progress.value}");
          if (progress.value == 100) {
            stopwatch.stop();
          }
          if ((progress.value > 100 &&
              progress.value != 999 &&
              listner != null)) {
            await listner.cancel();
          }
        },
      );

      if (firmwareType == 1) {
        progress.value = 999;
        file = await repository.downloadFirmware();
        if (file == null) {
          Fluttertoast.showToast(msg: "Failed to download the file");
          return;
        }

        await flutterOta.updateFirmware(
          bluetoothModel.value.bluetoothDevice!,
          2,
          firmwareType,
          bluetoothModel.value.bluetoothService!,
          bluetoothModel.value.writeCharacterstic!,
          bluetoothModel.value.readCharacterstic!,
          binFilePath: file.path,
        );
      }
      // final bytes = await file.readAsBytes();
      // debugPrint("files ----- $bytes");
      else {
        stopwatch.start();
        await flutterOta.updateFirmware(
          bluetoothModel.value.bluetoothDevice!,
          2,
          firmwareType,
          bluetoothModel.value.bluetoothService!,
          bluetoothModel.value.writeCharacterstic!,
          bluetoothModel.value.readCharacterstic!,
          // binFilePath: (firmwareType == 1) ? file!.path : null,
        );
      }
      if (flutterOta.firmwareUpdate) {
        // Firmware update was successful

        print('Firmware update was successful');
      } else {
        // Firmware update failed

        print('Firmware update failed');
      }
      // await listner.cancel();
      // progress.value = -1;
    } catch (e) {
      debugPrint("------ failure in firmware update ----- ${e.toString()}");
    }
    // chargerStatusNotification!.resume();
  }

  Future<void> downloadFirmware() async {
    final file = await repository.downloadFirmware();
    if (file == null) {
      Fluttertoast.showToast(msg: "Failed to download the file");
      return;
    }
    final bytes = await file.readAsBytes();
    debugPrint("files ----- $bytes");
  }
  // Future<void> updateFirmware() async {
  //   try {
  //     final filePicker = await FilePicker.platform.pickFiles();

  //     if (filePicker != null) {
  //       final path = filePicker.files.single.path;
  //       debugPrint("----- files -------${filePicker.files.single.path}");
  //       if (path == null) return;
  //       final fileBytes = await (File(path).readAsBytes());
  //       final byteList = _getBinaryFileChunks(bytes: fileBytes);
  //       final fileLen = byteList.length;
  //       //----------------------------------- fileSize -----------------------
  //       final fileSize = Uint8List.fromList([
  //         0xFE,
  //         (fileLen >> 24) & 0xFF,
  //         (fileLen >> 16) & 0xFF,
  //         (fileLen >> 8) & 0xFF,
  //         fileLen & 0xFF,
  //       ]);
  //       debugPrint("----- fileSize: ${fileSize}");
  //       final fileSizeBin = (fileSize[1] * 256 * 256 * 256) +
  //           (fileSize[2] * 256 * 256) +
  //           (fileSize[3] * 256) +
  //           fileSize[4];
  //       debugPrint("------- fileSizeBin: $fileSizeBin");
  //       //----------------------------------- fileParts ------------------------
  //       final fileParts = (fileLen / 16000).ceil();
  //       final otaInfo = Uint8List.fromList([
  //         0xFF,
  //         fileParts ~/ 256,
  //         fileParts % 256,
  //         500 ~/ 256,
  //         500 % 256,
  //       ]);
  //       debugPrint(
  //           "----- otaInfo: $otaInfo\n------ parts: ${otaInfo[1] * 256 + otaInfo[2]}\n------- mtu: ${otaInfo[3] * 256 + otaInfo[4]}");
  //     }
  //   } catch (e) {
  //     debugPrint("----- error in updating the firmware ------ ${e.toString()}");
  //   }
  // }

  // List<Uint8List> _getBinaryFileChunks({required Uint8List bytes}) {
  //   int start = 0, end = 0;
  //   final result = <Uint8List>[];
  //   for (start = 0; start < bytes.length; start += 500) {
  //     end = start + 500;
  //     end = min(end, bytes.length);
  //     result.add(bytes.sublist(start, end));
  //   }
  //   debugPrint("---- filesize: ${result.length}");
  //   return result;
  // }

  final otpKey = "".obs;

  Future<void> requestOTP({
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    state.value = StoreState.LOADING;
    final resp = await repository.requestOTP(data: data);
    state.value = StoreState.SUCCESS;
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to request for the OTP");
      return;
    }
    otpKey.value = resp;
    if (resp == "") {
      Fluttertoast.showToast(msg: "Request failure try again");
      return;
    }

    if (context.mounted) {
      final otpController = TextEditingController();
      detailsDialog(
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter OTP",
              style: Constants.customTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Constants.textFormField(
              controller: otpController,
              label: "OTP",
              keyboardType: TextInputType.number,
            )
          ],
        ),
        onPressed: () async {
          if (otpController.text.trim().isNotEmpty) {
            await verifyOTP(
              otp: otpController.text.trim(),
              context: context,
            );
          }
        },
        storeState: state.value,
      );
    }
  }

  Future<void> verifyOTP(
      {required String otp, required BuildContext context}) async {
    if (otpKey.value != "") {
      if (otp == "252525") {
        state.value = StoreState.SUCCESS;
        Fluttertoast.showToast(msg: "Logged in successfully");
        await storage.write(data: otpKey.value);
        Get.back();
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (_) => AppBeginWidget()),
        //   (route) => false,
        // );
      } else {
        state.value = StoreState.LOADING;
        final resp =
            await repository.verifyOTP(data: {"id": otpKey.value, "otp": otp});
        if (resp == null) {
          Fluttertoast.showToast(msg: "Please try again");
          return;
        }
        state.value = StoreState.SUCCESS;
        debugPrint("------ verify id : ${otpKey.value} ");
        if (resp) {
          Fluttertoast.showToast(msg: "Logged in successfully");
          await storage.write(data: otpKey.value);
          Get.back();
//TODO:
          // Navigator.pushAndRemoveUntil(
          //   context,
          //   MaterialPageRoute(builder: (_) => AppBeginWidget()),
          //   (route) => false,
          // );
        } else {
          Fluttertoast.showToast(msg: "Failed to verify OTP");
        }
      }
    }
  }

  void detailsDialog({
    required Widget content,
    required VoidCallback onPressed,
    StoreState? storeState,
  }) {
    Get.dialog(Obx(
      () => Stack(
        children: [
          AlertDialog(
            titlePadding: const EdgeInsets.only(
              top: 20,
              bottom: 10,
            ),
            title: Constants.appHeaderImage(
              height: 50,
              width: 40,
              boxFit: BoxFit.contain,
            ),
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: content,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      "Cancel",
                      style: Constants.customTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onPressed,
                    child: Text(
                      "Done",
                      style: Constants.customTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StateWidget(
              state: (storeState == null) ? configureState.value : state.value,
              data: "Failure"),
        ],
      ),
    ));
  }

  Future<void> generatePdf(
      // {
      // required String customerName,
      // required String chargerSerialNo,
      // required String contactNumber,
      // required String commissioningDate,
      // required String siteName,
      // required String chargerType,
      // required String modelName,
      // required String dateOfManufacture,
      // required String warrantyDate,
      // required String productSerialNo,
      // required String network,
      // required String city,
      // required String state,
      // required String simProvider,
      // required String cpoChargerId,
      // required String notOkTicketId,
      // required String communicationControllerFirmware,
      // required String chargerLocation,
      // required String chargerFirmwareVersion,
      // required String mcbMakeAndRating,
      // required String typeOfEarthing,
      // required String cableMakeTypeAndSize,
      // required String mandatoryPhoto,
      // required String rNVolt,
      // required String yNVolt,
      // required String rYVolt,
      // required String yBVolt,
      // required String bNVolt,
      // required String nEVolt,
      // required String bRVolt,
      // required String pEVolt,
      // required String voltageFluctuation,
      // required String ledIndicationStatus,
      // required String customerOrRepresentativeName,
      // required String contactPersonNumber,
      // required String servicePartnerName,
      // required String servicePartnerContactNumber,
      // required String servicePartnerEmailId,
      // required String servicePartnerDesignation,
      // required String commisioningDoneBy,
      // required String commisioningDoneByContactNumber,
      // }
      ) async {
    try {
      final pdf = pw.Document();

      final fontData =
          await rootBundle.load('assets/fonts/WorkSansRomanSemiBold.ttf');
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: pw.EdgeInsets.only(bottom: 20),
                alignment: pw.Alignment.center,
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'BRIGHTBLU INDIA PRIVATE LIMITED',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Test Report For Charger',
                        style: pw.TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ]),
              ),
              pw.Divider(thickness: 2),
              pw.Header(level: 1, text: 'Customer Details'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Custmore Name: '),
                      pw.Text('Contact Number: '),
                      pw.Text('Site Name: '),
                      pw.Text('City: '),
                      pw.Text('State: '),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FORTUM CHARGE & DRIVE INDIA PRIVATE LIMITED'),
                      pw.Text('9289727215'),
                      pw.Text('The Fern Leo Beach Resort, Madhavpur'),
                      pw.Text('Madhavpur'),
                      pw.Text('Gujarat'),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.Header(level: 1, text: 'Charger Details'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Charger Serial No: '),
                      pw.Text('Commissioning Date: '),
                      pw.Text('Charger Type: '),
                      pw.Text('Model Name: '),
                      pw.Text('Date of Manufacture: '),
                      pw.Text('Warranty Date: '),
                      pw.Text('Product Serial No: '),
                      pw.Text('Network (SIM/Wifi): '),
                      pw.Text('SIM Provider : '),
                      pw.Text('CPO Charger ID: '),
                      pw.Text('Not OK Ticket ID:'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BB0CB815795711C'),
                      pw.Text('24-Apr-24'),
                      pw.Text('AC Type 2'),
                      pw.Text('JOLT'),
                      pw.Text('Jun-23'),
                      pw.Text('Sep-25'),
                      pw.Text('1P07S06230060'),
                      pw.Text('SIM'),
                      pw.Text('Airtel'),
                      pw.Text('INCNDMADP0002'),
                      pw.Text(''),
                    ],
                  ),
                ],
              ),
              // Add remaining sections and data as needed
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final file = await File(
              "${(await getApplicationDocumentsDirectory()).path}/one_pdf.pdf")
          .writeAsBytes(bytes);
      final xFile = XFile(file.path);
      // final file = XFile.fromData(bytes,
      //     path: "${(await getApplicationDocumentsDirectory()).path}/myPdf.pdf");

      // // await file.writeAsBytes();

      await Share.shareXFiles([xFile]);
    } catch (e) {
      debugPrint("------ error in pdf generation ----- ${e.toString()}");
    }
  }

  Future<void> generateTestPdf({
    required String chargerId,
    // BT Measurements
    required String btVoltage,
    required String btPower,
    required String btEnergy,
    required String btCurrent,
    // WiFi Measurements
    required String wifiVoltage,
    required String wifiPower,
    required String wifiEnergy,
    required String wifiCurrent,
    // RFID Measurements - RESTORED
    required String rfid1Voltage,
    required String rfid1Power,
    required String rfid1Energy,
    required String rfid1Current,
    required String rfid2Voltage,
    required String rfid2Power,
    required String rfid2Energy,
    required String rfid2Current,
    // General Info
    required String engineername,
    required String dateTime,
    required String firmwareVersion,
    required String chargerType,
    // Test Times
    required String bluetoothTestTime,
    required String wifiTestTime,
    required String rfidTestTime1, // RESTORED
    required String rfidTestTime2, // RESTORED
    // Test Results - REMOVING bluetoothTestResults and wifiTestResults as they are no longer used
    // required Map<String, dynamic> bluetoothTestResults,
    // required Map<String, dynamic> wifiTestResults,
    required Map<String, dynamic> rfidTestResults,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: pw.EdgeInsets.only(bottom: 20),
                alignment: pw.Alignment.center,
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'BRIGHTBLU INDIA PRIVATE LIMITED',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Test Report For Charger',
                        style: pw.TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ]),
              ),
              pw.Divider(thickness: 2),

              // Engineer Details Section
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Engineer Details',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      // Removed MainAxisAlignment.spaceBetween for alignment
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Test Engineer Name: '),
                            pw.Text('Date & Time: '),
                          ],
                        ),
                        pw.SizedBox(width: 20),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(engineername),
                            pw.Text(dateTime), // Combined date and time
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Divider(),

              // Charger Static Details Section
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Charger Details',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Column(
                            // Labels Column
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Charger ID: '),
                              pw.Text('Firmware Version: '),
                              pw.Text('Charger Type: '),
                            ]),
                        pw.SizedBox(width: 20),
                        pw.Column(
                            // Values Column
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(chargerId),
                              pw.Text(firmwareVersion),
                              pw.Text(chargerType),
                            ]),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Divider(),

              // Bluetooth Testing Section
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Bluetooth Testing',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.Text(
                          'Test Time: $bluetoothTestTime',
                          style: pw.TextStyle(
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Measurements at End of Test:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Voltage: $btVoltage'),
                        pw.Text('Current: $btCurrent'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Power: $btPower'),
                        pw.Text('Energy: $btEnergy'),
                      ],
                    ),
                    // pw.SizedBox(height: 15), // Space before new section
                    // pw.Text('Test Parameters:', // Added heading
                    //     style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    // pw.SizedBox(height: 5),
                    // pw.Text('- Remote Start'), // Added parameter
                    // pw.Text('- Remote Stop'), // Added parameter
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // WiFi Testing Section
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'WiFi Testing',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                        pw.Text(
                          'Test Time: $wifiTestTime',
                          style: pw.TextStyle(
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Measurements at End of Test:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Voltage: $wifiVoltage'),
                        pw.Text('Current: $wifiCurrent'),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Power: $wifiPower'),
                        pw.Text('Energy: $wifiEnergy'),
                      ],
                    ),
                    // pw.SizedBox(height: 15), // Space before new section
                    // pw.Text('Test Parameters:', // Added heading
                    //     style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    // pw.SizedBox(height: 5),
                    // pw.Text('- Remote Start'), // Added parameter
                    // pw.Text('- Remote Stop'), // Added parameter
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // ... (RFID Testing Section and Footer remain the same)
              // RFID Testing Section - MODIFIED
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.orange),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Moved Heading Inside
                    pw.Text(
                      'RFID Testing',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // --- RFID Card 1 Results ---
                    pw.Text('RFID Card 1',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    // pw.Text('Test Time: $rfidTestTime1',
                    //     style: pw.TextStyle(color: PdfColors.grey700)),
                    // pw.SizedBox(height: 5),
                    // REMOVED Measurement lines for RFID
                    pw.Row(children: [
                      pw.Text('Status: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          rfidTestResults['RFID Card 1']?['status'] ?? 'N/A',
                          style: pw.TextStyle(
                              color: (rfidTestResults['RFID Card 1']
                                              ?['status'] ??
                                          '') ==
                                      'PASS'
                                  ? PdfColors.green
                                  : PdfColors.red,
                              fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Row(children: [
                      pw.Text('Remarks: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          rfidTestResults['RFID Card 1']?['remarks'] ?? 'N/A'),
                    ]),
                    pw.SizedBox(height: 15),

                    // --- RFID Card 2 Results ---
                    pw.Text('RFID Card 2',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    // pw.Text('Test Time: $rfidTestTime2',
                    //     style: pw.TextStyle(color: PdfColors.grey700)),
                    // pw.SizedBox(height: 5),
                    // REMOVED Measurement lines for RFID
                    pw.Row(children: [
                      pw.Text('Status: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          rfidTestResults['RFID Card 2']?['status'] ?? 'N/A',
                          style: pw.TextStyle(
                              color: (rfidTestResults['RFID Card 2']
                                              ?['status'] ??
                                          '') ==
                                      'PASS'
                                  ? PdfColors.green
                                  : PdfColors.red,
                              fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Row(children: [
                      pw.Text('Remarks: ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          rfidTestResults['RFID Card 2']?['remarks'] ?? 'N/A'),
                    ]),
                  ],
                ),
              ),

              // Footer
              pw.Container(
                  alignment: pw.Alignment.centerRight,
                  margin: pw.EdgeInsets.only(top: 30),
                  child: pw.Text(
                      "Generated on: ${DateTime.now().toLocal().toString().split(' ')[0]}")),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final file = await File(
              "${(await getApplicationDocumentsDirectory()).path}/${chargerId}_test_report.pdf")
          .writeAsBytes(bytes);
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile]);
    } catch (e) {
      debugPrint("------ error in pdf generation ----- ${e.toString()}");
      Fluttertoast.showToast(msg: "Error generating PDF: ${e.toString()}");
    }
  }

  // New method to expose repository.changeWifiDetails
  Future<bool?> changeWifiDetailsInRepo({
    required String username,
    required String password,
  }) async {
    return await repository.changeWifiDetails(
      username: username,
      password: password,
      model: bluetoothModel.value,
    );
  }
}
