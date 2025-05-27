// ignore_for_file: use_build_context_synchronously, unnecessary_cast, invalid_use_of_protected_member

import 'dart:async';
import 'dart:collection';
import 'dart:convert' show jsonDecode, ascii;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:bb_factory_test_app/utils/enums/connection_status.dart';
import 'package:bb_factory_test_app/utils/enums/dpm_status.dart';
import 'package:bb_factory_test_app/utils/enums/schedule_type.dart';
import 'package:bb_factory_test_app/models/bluetooth_model_new.dart';
import 'package:bb_factory_test_app/models/charger_model_new.dart';
import 'package:bb_factory_test_app/models/charger_realitime_model.dart';
import 'package:bb_factory_test_app/models/dpm_current_model.dart';
import 'package:bb_factory_test_app/models/firmware_update_model.dart';
import 'package:bb_factory_test_app/models/ocpp_config_model.dart';
import 'package:bb_factory_test_app/models/records_resp_model.dart';
import 'package:bb_factory_test_app/models/transaction_resp_model.dart';
import 'package:bb_factory_test_app/models/wifi_model_new.dart';
import 'package:bb_factory_test_app/repository/charger_ble_repository.dart';
import 'package:bb_factory_test_app/repository/charger_firebase_repository.dart';
import 'package:bb_factory_test_app/repository/transaction_repository.dart';
// import 'package:bb_factory_test_app/charger_module/screens/charger_setup_screen.dart';
import 'package:bb_factory_test_app/utils/charge_time_extension.dart';
import 'package:bb_factory_test_app/utils/charger_wifi_rfid_state.dart';
import 'package:bb_factory_test_app/utils/schedule_time_extension.dart';
import 'package:bb_factory_test_app/constants/app_style.dart';
import 'package:bb_factory_test_app/constants/color_constants.dart';
import 'package:bb_factory_test_app/constants/image_constants.dart';
import 'package:bb_factory_test_app/constants/size_config.dart';
import 'package:bb_factory_test_app/firebase_options.dart';
import 'package:bb_factory_test_app/hive/enums/hive_key_enum.dart';
import 'package:bb_factory_test_app/hive/hive.dart';
import 'package:bb_factory_test_app/hive/models/rfid_hive_model.dart';
import 'package:bb_factory_test_app/hive/models/schedule_hive_model.dart';
import 'package:bb_factory_test_app/hive/models/transaction_hive_model.dart';
// import 'package:bb_factory_test_app/main_module/controller/bottom_navigation_controller.dart';
// import 'package:bb_factory_test_app/users_module/controller/auth_controller.dart';
import 'package:bb_factory_test_app/utils/enums/manage_states.dart';
import 'package:bb_factory_test_app/utils/widgets/custom_button.dart';
import 'package:bb_factory_test_app/utils/widgets/custom_image_view.dart';
import 'package:bb_factory_test_app/utils/widgets/custom_textfield.dart';
// import 'package:bb_factory_test_app/widgets/custom_button.dart';
// import 'package:bb_factory_test_app/widgets/custom_image_view.dart';
// import 'package:bb_factory_test_app/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:collection';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:bb_factory_test_app/utils/esp_functions_enum.dart';

// extension BBDeviceService on BluetoothService {
//   BluetoothCharacteristic read() {
//     final index = characteristics.indexWhere((element) =>
//         element.uuid.toString() == "6e400003-b5a3-f393-e0a9-e50e24dcca9e");
//     characteristics[index].setNotifyValue(true);
//     return characteristics[index];
//   }

//   BluetoothCharacteristic write() {
//     final index = characteristics.indexWhere((element) =>
//         element.uuid.toString() == "6e400002-b5a3-f393-e0a9-e50e24dcca9e");
//     return characteristics[index];
//   }
// }

// extension HexToAscii on String {
//   String hexToAscii() => List.generate(
//         length ~/ 2,
//         (i) => String.fromCharCode(
//             int.parse(substring(i * 2, (i * 2) + 2), radix: 16)),
//       ).join();
// }

class ChargerController extends GetxController {
  // final wifiTimer = Stopwatch().obs;

  final hiveBox = HiveBox();
  final state = (StoreState.SUCCESS).obs;

  final bluetoothAvailable = true.obs;

  // connectionStatus
  final connectionStatus = (ConnectionStatus.OFFLINE).obs;

  /// 1 = BLE   0 = WIFI
  final connectionSwitch = (0).obs;

  /// Bluetooth instance for BLE communtications
  // final FlutterBluePlus = FlutterBluePlus.;

  /// Instance for realtime DB
  final realtimeDBIntance = FirebaseDatabase.instance;

  /// Instance of firestore DB
  final firebaseFirestore = FirebaseFirestore.instance;

  /// Instance for accesing ble methods
  final bleRepository = ChargerBLERepository();

  /// Instance for accessing firebase methods
  final firebaseRepository = ChargerFirebaseRepository();
  final ocppConfig = HashMap<String, OCPPConfigModel>().obs;

  /// Instance of user Auth
  User? get currentUser => FirebaseAuth.instance.currentUser;

  /// [ChargerModel] to store the basic charger info
  final chargerModel = ChargerModel(
    chargerId: "",
    userId: "",
    // remoteId: "",
  ).obs;

  /// [ChargerRealTimeModel] to store all charger reatime data
  final chargerRealtimeModel = ChargerRealTimeModel(
          chargerId: "", chargerStatus: ChargerStatus.UNAVAILABLE)
      .obs;

  /// [BluetoothModel] to store the charger bluetooth details
  final bluetoothModel = BluetoothModelNew().obs;

  /// [WifiModel] to store wifi connection details of current wifi.
  final wifiModel = WifiModel(ssid: "", rssi: 0).obs;

  /// Lists all wifi network's to which charger can get connected
  final wifiSSIDList = <WifiModel>[].obs;

  /// Represents the state of BLE device
  final bleconnectState = (StoreState.SUCCESS).obs;

  /// Page description for handling pages while adding a charger
  final addChargerPageController = 0.obs;

  /// A loading message to let user know what's the current connection status
  final connectionMessage = "".obs;

  /// Maintains connection of charger
  final connectionLoader = (StoreState.SUCCESS).obs;

  /// Maintains state of switching connections;
  final updateState = (StoreState.SUCCESS).obs;

  /// Maintains charging state
  final chargingState = (StoreState.SUCCESS).obs;

  /// Maintains state while in case of
  /// 1. Connecting to charger -> auth with MFA
  /// 2. Check wifi connection -> already connected to wifi.
  final checkChargerWifiState = (StoreState.SUCCESS).obs;

  /// Manage Plug and Play
  final plugAndPlay = false.obs;
  Iterable<MapEntry<String, OCPPConfigModel>> get getOcppConfigList =>
      ocppConfig.value.entries;
  final configureState = (StoreState.SUCCESS).obs;

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

  final chargerBLEConnectionMessage = "".obs;

  /// Listens to charger data via BLE Status Notifications
  StreamSubscription<List<int>>? getData =
      (null as StreamSubscription<List<int>>?);

  /// Listens to charger data via WIFI
  StreamSubscription<DatabaseEvent>? listener =
      (null as StreamSubscription<DatabaseEvent>?);

  StreamSubscription<BluetoothAdapterState>? bleState =
      (null as StreamSubscription<BluetoothAdapterState>?);

  StreamSubscription<BluetoothConnectionState>? chargerConnectionState =
      (null as StreamSubscription<BluetoothConnectionState>?);

  StreamSubscription? chargingListner = (null as StreamSubscription?);

  StreamSubscription<List<ScanResult>>? scanDevicesListener =
      (null as StreamSubscription<List<ScanResult>>?);

  /// Provides you list of bluetooth scanned devices as [ScanResult]
  final scanResultList = <ScanResult>[].obs;

  /// Determines current state for BLE scanning
  final scanning = (StoreState.SUCCESS).obs;

  /// Mainatins the state while updating configrations
  final updating = (StoreState.SUCCESS).obs;

  /// Flag for WiFi trigger
  final wifiTriggerFlag = false.obs;

  final resetState = (StoreState.SUCCESS).obs;

  /// Update Charger state
  final updateChargerState = (StoreState.SUCCESS).obs;

  /// Latest firmware detected name
  final latestFirmwareName = "".obs;

  final firmwareUpdateModel = FirmwareUpdateModel(
    percentageCompleted: 0,
    timeElapsed: 0,
    errorStatus: false,
    errorReason: "",
  ).obs;

  /// To determine if charger exists or not
  bool get chargerExists => chargerModel.value.chargerId != "";

  double get powerGuageMax => (chargerModel.value.phase != null)
      ? (chargerModel.value.phase == "Three.Phase")
          ? 22.4
          : 7.4
      : 7.4;

  /// Maintains charger timer
  final chargerTimer = "".obs;

  /// List of all [ChargerModel] for a user
  final chargersList = (<ChargerModel>[]).obs;

  /// Maintains charger list loading state
  final chargerListState = (StoreState.SUCCESS).obs;

  bool get hideFloatingActionButton =>
      chargerRealtimeModel.value.chargerStatus == ChargerStatus.PREPARING ||
      chargerRealtimeModel.value.chargerStatus == ChargerStatus.CHARGING;

  final slideToCharge = true.obs;

  void testDialog() {
    Get.dialog(Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstant.whiteA700,
          borderRadius: BorderRadius.circular(
            getSize(17),
          ),
        ),
        height: getVerticalSize(200),
        width: getHorizontalSize(150),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Connecting via bluetooth",
              style: AppStyle.customTextStyle(
                fontWeight: FontWeight.w600,
                fontSize: getFontSize(16),
              ),
            ),
            SpinKitFadingCircle(
              color: ColorConstant.indigo900,
            ),
          ],
        ),
      ),
    ));
  }

  void bluetoothDialog() {
    Get.dialog(
      AlertDialog(
        surfaceTintColor: ColorConstant.whiteA700,
        title: Text(
          "Bluetooth",
          style: AppStyle.customTextStyle(
            fontWeight: FontWeight.w600,
            fontSize: getFontSize(20),
          ),
        ),
        content: Text(
          "Kindly turn on your Bluetooth",
          style: AppStyle.customTextStyle(
            fontWeight: FontWeight.w600,
            fontSize: getFontSize(20),
          ),
        ),
        actions: <Widget>[
          CustomButton(
            width: getHorizontalSize(30),
            text: (Platform.isAndroid) ? "On" : "Ok",
            shape: ButtonShape.CircleBorder18,
            variant: ButtonVariant.FillWhiteA700,
            onTap: () async {
              if (Platform.isAndroid) {
                try {
                  await FlutterBluePlus.turnOn();
                  Get.back();
                  await addChargerInitiate();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to turn on bluetooth');
                }
              } else {
                Fluttertoast.showToast(msg: "Kindly switch on your bluetooth");
              }
              Get.back();
            },
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void warningCurrentdialog() {
    Get.dialog(AlertDialog(
      surfaceTintColor: ColorConstant.whiteA700,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Warning",
            style: AppStyle.customTextStyle(
              fontWeight: FontWeight.w600,
              fontSize: getFontSize(18),
              color: ColorConstant.red700,
            ),
          ),
          Icon(
            Icons.warning_amber,
            color: Colors.amber,
            size: getSize(30),
          ),
        ],
      ),
      content: Text(
        "Do not exceed your sanctioned supply.\n\nIf you are unsure, contact your installer.",
        style: AppStyle.customTextStyle(
          fontWeight: FontWeight.w600,
          fontSize: getFontSize(16),
          color: ColorConstant.black900,
        ),
      ),
      actions: [
        Row(
          children: [
            CustomButton(
              width: getHorizontalSize(70),
              text: "Cancel",
              shape: ButtonShape.CircleBorder18,
              variant: ButtonVariant.FillWhiteA700,
              onTap: () async {
                Get.back();
              },
            ),
            const Spacer(),
            CustomButton(
              width: getHorizontalSize(80),
              text: "Proceed",
              shape: ButtonShape.CircleBorder18,
              variant: ButtonVariant.FillWhiteA700,
              onTap: () async {
                Get.back();
                changeCurrentLimitDialog();
              },
            ),
          ],
        ),
      ],
    ));
  }

  final setMaxCurrent = 0.obs;

  void changeCurrentLimitDialog() {
    setMaxCurrent.value = chargerRealtimeModel.value.maxCurrentLimit ?? 6;
    Get.dialog(
      AlertDialog(
        surfaceTintColor: ColorConstant.whiteA700,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: "Change current limt".tr,
                style: AppStyle.txtWorkSansRomanSemiBold18,
                children: [
                  TextSpan(
                    text: "\nfrom",
                    style: AppStyle.customTextStyle(
                      color: ColorConstant.black900,
                      fontSize: getFontSize(18),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  TextSpan(
                    text: "\t6A",
                    style: AppStyle.customTextStyle(
                      color: ColorConstant.blueA700,
                      fontSize: getFontSize(18),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: "\tto",
                    style: AppStyle.customTextStyle(
                      color: ColorConstant.black900,
                      fontSize: getFontSize(18),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  TextSpan(
                    text: "\t32A",
                    style: AppStyle.customTextStyle(
                      color: ColorConstant.blueA700,
                      fontSize: getFontSize(18),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
            CustomImageView(
              svgPath: ImageConstant.imgHome,
              height: getVerticalSize(25),
              width: getHorizontalSize(21),
              margin: getMargin(top: 5, bottom: 12),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: getVerticalSize(110),
          child: Obx(
            () {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${setMaxCurrent.value} Amps",
                    style: AppStyle.customTextStyle(
                      color: ColorConstant.blueA700,
                      fontSize: getFontSize(18),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Slider.adaptive(
                          // autofocus: true,
                          value: setMaxCurrent.value.toDouble(),
                          onChanged: (val) async {
                            if (chargerRealtimeModel.value.chargerStatus !=
                                ChargerStatus.UNAVAILABLE) {
                              setMaxCurrent.value = val.toInt();

                              debugPrint(
                                  '---- max current -- ${chargerRealtimeModel.value.maxCurrentLimit}');
                            } else {
                              Fluttertoast.showToast(msg: "Charger is offline");
                            }
                          },
                          onChangeStart: (val) {
                            debugPrint("---- $val -----");
                          },
                          onChangeEnd: (val) {},
                          // onChangeStart: (value) {},
                          min: 6,
                          max: 32,
                          activeColor: ColorConstant.blueA700,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: getPadding(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "min 6A",
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: AppStyle.txtWorkSansRomanRegular11,
                        ),
                        Text(
                          "max 32A",
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: AppStyle.txtWorkSansRomanRegular11,
                        )
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: <Widget>[
          CustomButton(
            width: getHorizontalSize(30),
            text: "Set",
            shape: ButtonShape.CircleBorder18,
            variant: ButtonVariant.FillWhiteA700,
            onTap: () async {
              await updateMaxCurrentLimit();
              Get.back();
            },
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Reset all pages
  void init() {
    // connectionSwitch.value = 0;
    // addChargerPageController.value = 0;
  }

  /// Initiating add charger procedure
  Future<void> addChargerInitiate() async {
    listenBluetoothState();

    if ((await FlutterBluePlus.adapterState.first) ==
        BluetoothAdapterState.on) {
      // if (await FlutterBluePlus.isOn) {
      chargingState.value = StoreState.LOADING;

      addChargerPageController.value = 1;
      crossFadeState.value = false;
      // scanDevices();
      startScan();

      chargingState.value = StoreState.SUCCESS;

      // Get.to(const ChargerConfigureScreen(
      //   showBack: true,
      // ));
    } else {
      bluetoothDialog();
    }
    // } else {

    // }
  }

  Future<void> getOcppConfigDetails() async {
    state.value = StoreState.LOADING;
    final resp =
        await bleRepository.getOCPPConfigDetails(model: bluetoothModel.value);
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

  /// Maintains current connectionStatus of charger
  Future<void> getChargerConnectionStatus() async {
    // BLE connection status
    if (connectionSwitch.value == 1) {
      if (bluetoothModel.value.bluetoothDevice != null &&
          await bluetoothModel.value.bluetoothDevice!.connectionState.first ==
              BluetoothConnectionState.connected &&
          chargerRealtimeModel.value.chargerId != "") {
        connectionStatus.value = ConnectionStatus.ONLINE;
      } else {
        connectionStatus.value = ConnectionStatus.OFFLINE;
      }
    }
    // WIFI connection status
    else {
      connectionStatus.value = await firebaseRepository
          .getChargerConnectionStatus(chargerId: chargerModel.value.chargerId);
    }
  }

  Future<void> configureOCPPConfiguration({
    required String key,
    required String value,
  }) async {
    configureState.value = StoreState.LOADING;
    final resp = await bleRepository.changeOCPPConfigDetails(
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

  /// Methods are called before logging out of the application
  /// Ensures that charger is [BluetoothConnectionState.disconnected]
  /// [getData] and [listener] streams are closed
  /// [addChargerPageController] and [connectionSwitch] is reset
  /// [ChargerModel] and [ChargerRealTimeModel] are reset.
  Future<void> disposeCharger() async {
    if (getData != null) {
      await getData!.cancel();
    }
    if (listener != null) {
      await listener!.cancel();
    }

    if (bleState != null) {
      await bleState!.cancel();
    }

    if (chargingListner != null) {
      chargingListner!.cancel();
    }

    if (bluetoothModel.value.bluetoothDevice != null) {
      await bluetoothModel.value.bluetoothDevice!.disconnect();
    }

    addChargerPageController.value = 0;

    chargerModel.value = ChargerModel(
      chargerId: "",
      userId: "",
      // remoteId: "",
    );

    chargerRealtimeModel.value = ChargerRealTimeModel(
        chargerId: "", chargerStatus: ChargerStatus.UNAVAILABLE);

    /// [BluetoothModel] to store the charger bluetooth details
    bluetoothModel.value = BluetoothModelNew();

    /// [WifiModel] to store wifi connection details of current wifi.
    wifiModel.value = WifiModel(ssid: "", rssi: 0);

    /// Lists all wifi network's to which charger can get connected
    wifiSSIDList.value = <WifiModel>[];

    // /// Update current [ScheduleHiveModel]
    // scheduleModel.value = ScheduleHiveModel(
    //   id: "",
    //   timeStart: 0,
    //   timeStop: 0,
    //   duration: 0,
    //   days: [0, 0, 0, 0, 0, 0, 0],
    //   active: false,
    //   type: -1,
    // );

    firmwareUpdateModel.value = FirmwareUpdateModel(
      percentageCompleted: 0,
      timeElapsed: 0,
      errorStatus: false,
      errorReason: "",
    );

    connectionSwitch.value = 0;
  }

  /// Used to switch connections
  Future<void> switchConnections(
      {required int index, BuildContext? context}) async {
    connectionSwitch.value = index;

    try {
      if (getData != null) {
        await getData!.cancel().then((value) =>
            debugPrint("BLE data listner stream cancelled sucessfully"));
      }

      if (bleState != null) {
        await bleState!
            .cancel()
            .then((value) => debugPrint("BLE  stream cancelled sucessfully"));
      }

      if (listener != null) {
        await listener!
            .cancel()
            .then((value) => debugPrint("Wifi stream cancelled"));
      }

      if (chargingListner != null) {
        await chargingListner!
            .cancel()
            .then((value) => debugPrint("wifi-charging stream cancelled"));
      }

      switch (index) {
        /// WIFI communication
        case 0:
          await disconnectBLE();
          await chargerConnection(onlyWifi: true);
          break;

        /// BLE communication
        case 1:
          await listenBluetoothState();
          await chargerConnection();
          break;
      }
    } catch (e) {
      debugPrint("------- switch connections issue ----- ${e.toString()}");
    }
  }

  Future<void> listenBluetoothState() async {
    // bleState = FlutterBluePlus.state.listen(
    //   (event) {
    //     bluetoothAvailable.value = event == BluetoothState.on;
    //   },
    // );
    debugPrint(
        "---- FlutterBluePlus.isOn -----${(await FlutterBluePlus.adapterState.first)}");
    bluetoothAvailable.value =
        (await FlutterBluePlus.adapterState.first) == BluetoothAdapterState.on;
  }

  void chargerConnectionListener() async {
    if (chargerConnectionState != null) {
      await chargerConnectionState!.cancel();
    }
    chargerConnectionState =
        bluetoothModel.value.bluetoothDevice!.connectionState.listen(
      (event) async {
        debugPrint("----- connection event ----- $event");
        if (event == BluetoothConnectionState.disconnected) {
          if (getData != null) {
            await getData!.cancel();
          }
          if (bleState != null) {
            await bleState!.cancel();
          }
          chargerRealtimeModel.value = ChargerRealTimeModel(
            chargerId: chargerModel.value.chargerId,
            chargerStatus: ChargerStatus.UNAVAILABLE,
          );
          connectionStatus.value = ConnectionStatus.OFFLINE;
          await chargerConnectionState!.cancel();
        }
      },
    );
  }

  /// Disconnect a current charger
  Future<void> disconnectBLE() async {
    try {
      await bluetoothModel.value.bluetoothDevice!.disconnect();
      debugPrint(
          "---- bluetoothModel.value.bluetoothDevice! ---- ${bluetoothModel.value.bluetoothDevice!.advName}");
    } catch (e) {
      debugPrint("--------- ble disconnect failure ---- ${e.toString()}");
      // Fluttertoast.showToast(msg: "Charger already disconnected");
    }
  }

  // void scanDevices() async {
  //   bool check = false;
  //   await FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
  //     print(state);

  //     if (state == BluetoothAdapterState.on) {
  //       // usually start scanning, connecting, etc
  //       check = true;
  //     } else {
  //       Fluttertoast.showToast(msg: "Please Turn on Bluetooth");
  //       // show an error to the user, etc
  //       check = false;
  //     }
  //   });
  //   if (check == false) {
  //     scanResultList.clear();
  //   }
  //   await FlutterBluePlus.startScan(withKeywords: ["BB"]);

  //   if ((await FlutterBluePlus.adapterState.first) ==
  //       BluetoothAdapterState.on) {
  //     //  if (scanDevicesListener == null) {
  //     scanDevicesListener ??= FlutterBluePlus.onScanResults
  //         //     .timeout(const Duration(seconds: 25), onTimeout: (data) {
  //         //   data.close();
  //         // })
  //         .listen((scanResult) {
  //       debugPrint("Scanning List");
  //       //if (scanResult.isNotEmpty) {
  //       scanResultList
  //         ..clear()
  //         ..addAll(scanResult);
  //       //}
  //     });
  //     // } else {
  //     //   try {
  //     //     scanDevicesListener!.cancel();
  //     //   } catch (e) {
  //     //     debugPrint("----- scanDevicesListner.cancel() ----- ${e.toString()}");
  //     //   }
  //     // }
  //   }
  // }

  /// Initates scanning for BLE devices and populates [scanResultList]
  Future<void> startScan() async {
    if ((await FlutterBluePlus.adapterState.first) ==
        BluetoothAdapterState.on) {
      scanning.value = StoreState.LOADING;

      final list = await bleRepository.getScanResults();

      /// To remove the chargers already registered with the user
      if (chargersList.value.isNotEmpty) {
        for (final model in chargersList) {
          final index = list.indexWhere((element) =>
              element.advertisementData.advName == model.chargerId);
          if (index != -1) {
            list.removeAt(index);
          }
        }
      }
      scanResultList
        ..clear()
        ..addAll(list);
      debugPrint("----- list scan results -----$list");

      scanning.value = StoreState.SUCCESS;
    } else {
      bluetoothDialog();
    }
  }

  // void startScan() {}

  Future<void> chargerConnection({
    bool? onlyWifi,
  }) async {
    try {
      // connectionSwitch.value = 0;
      connectionStatus.value = ConnectionStatus.OFFLINE;

      if (onlyWifi != null) {
        await connectToChargerViaWIFI();
      } else {
        await connectToChargerViaBLE();
      }
    } catch (e) {
      if (connectionSwitch.value == 1) {
        Fluttertoast.showToast(msg: "Charger connection failure");
      }
    }
  }

  /// Establish connection to charger via BLE
  Future<void> connectToChargerViaBLE({
    BluetoothDevice? device,
  }) async {
    if (bluetoothAvailable.value) {
      connectionLoader.value = StoreState.LOADING;
      connectionMessage.value = 'Connecting via Bluetooth';

      await disconnectBLE();

      connectionSwitch.value = 1;

      // connection to charger
      final bleModel = await bleRepository.connectToCharger(
        scanDevice: device,
        remoteId: chargerModel.value.chargerId,
      );

      // if connection was success
      if (bleModel != null) {
        bluetoothModel.value = bleModel;

        // BOOT NOTIFICATION TRIGGER
        final resultModel = await bleRepository.boot(bluetoothModel: bleModel);

        // UPDATE CONNECTION STATUS DEPNDING UPOB BOOT RESULT
        connectionStatus.value = (resultModel != null)
            ? ConnectionStatus.ONLINE
            : ConnectionStatus.OFFLINE;
        debugPrint("----- boot result --- connection $resultModel");

        // BOOT WAS SUCCESSFUL
        if (resultModel != null) {
          // REGISTER CHARGER (ONLY FIRST TIME)
          if (chargerModel.value.firmware == '' ||
              chargerModel.value.firmware == null) {
            await firebaseRepository.uploadChargerData(model: resultModel);
          }

          // MAKE CONNECTION LOADER SUCCESSFUL
          connectionLoader.value = StoreState.SUCCESS;

          final statusNotificationResp = await bleRepository
              .triggerStatusNotification(bluetoothModel: bluetoothModel.value);

          debugPrint("---- status notif --- data $statusNotificationResp");

          if (statusNotificationResp.isNotEmpty) {
            chargerRealtimeModel.value = chargerRealtimeModel.value
                .updateWith(data: statusNotificationResp);
          }

          // UPDATE [ChargerModel]
          chargerModel.value = resultModel;

          // // UPDATE [ChargerRealtimeModel]
          // await updateChargerRealtimeModel();

          // INTIATE THE BLE CHARGER LISTNER
          listenToBLEChargerUpdates();

          // A STREAM TO ALWAYS CHECK FOR CONNECTIVITY OF BLE
          chargerConnectionListener();
        }
      }

      // CHARGER FAILED TO CONNECT
      else {
        Fluttertoast.showToast(msg: "Charger failed to connect");
      }

      // IF BECAUSE OF SOME REASON THE CHARGER DIDN'T PROVIDE BOOT OR COULDN'T CONNECT SHUT DOWN CONNECTION LOADER
      if (connectionLoader.value == StoreState.LOADING) {
        connectionLoader.value = StoreState.SUCCESS;
      }
    }
    // WHEN BLE IS OFF
    else {
      Fluttertoast.showToast(msg: "Kindly switch on bluetooth");

      // SHOW BLE DIALOG ONLY IF [Platform.isAndroid]
      if (Platform.isAndroid) {
        bluetoothDialog();
      }
    }
  }

  /// flag for Wifi
  final wifiFlag = true.obs;

  /// Establish connection to charger via WIFI
  Future<void> connectToChargerViaWIFI() async {
    // connectionStatus.value =
    //     chargerRealtimeModel.value.connectionStatus ?? ConnectionStatus.OFFLINE;
    if (wifiFlag.value) {
      wifiFlag.value = false;
      connectionLoader.value = StoreState.LOADING;
      connectionMessage.value = "Connecting via WIFI...";

      if (getData != null) {
        await getData!.cancel();
      }

      // connectionSwitch.value = 0;

      await realtimeDBIntance
          .ref("chargers/${chargerModel.value.chargerId}/connectionStatus")
          .set(0);

      /// activated the firebase realtimeDB listener
      listenToWifiChargerUpdates();

      /// Wait for 12 secs to check if charger can connect to Firebase RealtimeDB
      // TODO: Keep a check of this time

      int time = 500;
      while (
          time >= 0 && chargerWifiConnectionStatus != ConnectionStatus.ONLINE) {
        // if (chargerWifiConnectionStatus == ConnectionStatus.ONLINE) {
        //   // connectionLoader.value = StoreState.SUCCESS;
        // connectionStatus.value = chargerWifiConnectionStatus;
        // }
        time--;
        if (connectionSwitch.value == 1) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 250));
        debugPrint("wifi time -------- $time");
      }
      if (time != 0) {
        connectionStatus.value = chargerWifiConnectionStatus;
      }
      connectionLoader.value = StoreState.SUCCESS;

      wifiFlag.value = true;

      if (chargerWifiConnectionStatus == ConnectionStatus.OFFLINE) {
        connectionLoader.value = StoreState.SUCCESS;
        chargerRealtimeModel.value = ChargerRealTimeModel(
          chargerId: chargerModel.value.chargerId,
          chargerStatus: ChargerStatus.UNAVAILABLE,
        );
        await switchConnections(index: 1);
      }
    }
    // await Future.delayed(const Duration(seconds: 10), () async {
    //   connectionLoader.value = StoreState.SUCCESS;
    //   if (chargerWifiConnectionStatus == ConnectionStatus.OFFLINE) {
    //     chargerRealtimeModel.value = ChargerRealTimeModel(
    //       chargerId: chargerModel.value.chargerId,
    //       chargerStatus: ChargerStatus.UNAVAILABLE,
    //     );
    //     await switchConnections(index: 1);
    //   } else {
    //     connectionStatus.value = chargerWifiConnectionStatus;
    //   }
    // });
  }

  // Future<void> triggerTransactionCount() async {
  //   final resp = await bleRepository.triggerTransactions(
  //       bluetoothModel: bluetoothModel.value);

  //   final id = await Cache().readVariable(key: chargerModel.value.chargerId);

  //   debugPrint("----- resp isolate ------ ${resp}");

  //   if (resp != null) {
  //     final port = ReceivePort();
  //     // final token = ServicesBinding.rootIsolateToken!;

  //     if (startIsolate.value) {
  //       return;
  //     } else {
  //       startIsolate.value = true;

  //       try {
  //         await FlutterIsolate.spawn(
  //           getTransactionMessages,
  //           [
  //             port.sendPort,
  //             {
  //               "count": resp,
  //               "id": id,
  //               "chargerId": chargerModel.value.chargerId,
  //             }
  //           ],
  //         );
  //       } finally {
  //         startIsolate.value = false;
  //         // FlutterIsolate.killAll();
  //       }
  //     }

  //     // RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  //     // await Isolate.spawn(_isolateMain, [rootIsolateToken, port]);
  //     // debugPrint("----- isolate ---- ${port.first}");
  //     // int count = resp;
  //     // int value = 0;
  //     // while (count >= 0) {
  //     //   await Future.delayed(const Duration(seconds: 1), () async {
  //     //     debugPrint("----- transactions no : ${value++}");
  //     //     await bleRepository.triggerTransactionsMessages(
  //     //         bluetoothModel: bluetoothModel.value);
  //     //   });
  //     //   count--;
  //     // }
  //   }
  // }

  // // static void _isolateMain(List<dynamic> list) async {

  // // }

  final plugPlayState = (StoreState.SUCCESS).obs;

  /// Defines Plug and Play mechanism
  Future<void> updatePlugPlay() async {
    print("Inside update plug & play");
    if (chargerRealtimeModel.value.freemode != null) {
      plugPlayState.value = StoreState.LOADING;

      chargerRealtimeModel.value.freemode =
          !chargerRealtimeModel.value.freemode!;

      if (!chargerRealtimeModel.value.freemode!) {
        // Fluttertoast.showToast(
        //     msg: "It will take about a min to deactivate Plug & Play",
        //     toastLength: Toast.LENGTH_LONG);
      }
      print("Connection switch value : ${connectionSwitch.value}");

      if (connectionSwitch.value == 1) {
        print("Inside connectionSwitch.value == 1");
        await bleRepository.plugAndPlay(
          result: (chargerRealtimeModel.value.freemode!) ? 1 : 0,
          bluetoothModel: bluetoothModel.value,
        );
        await bleRepository.triggerStatusNotification(
            bluetoothModel: bluetoothModel.value);
      }
      print("Before val : ${chargerRealtimeModel.value.freemode!}");
      final resp = await firebaseRepository.plugAndPlay(
        result: chargerRealtimeModel.value.freemode!,
        chargerId: chargerModel.value.chargerId,
      );
      if (chargerRealtimeModel.value.freemode!) {
        scheduleToggle.value = ScheduleType.PLUG_PLAY;
      } else {
        scheduleToggle.value = ScheduleType.NONE;
      }

      print("Final Resp : $resp");

      plugPlayState.value = StoreState.SUCCESS;
    } else {
      Fluttertoast.showToast(msg: "Charger is offline");
    }
  }

  // /// Connect to a [BluetoothDevice] which is registered for that user in Firebase DB
  // Future<bool> connectToARegisteredCharger() async {
  //   debugPrint("---- connect To a reg charger -------");

  //   try {
  //     /// Check if charger is already connected
  //     final connectedDevices = await FlutterBluePlus.connectedDevices;
  //     final index = connectedDevices.indexWhere(
  //         (element) => element.name == chargerModel.value.chargerId);
  //     if (index != -1) {
  //       connectionSwitch.value = 1;
  //       await configureCharger(device: connectedDevices[index]);
  //       debugPrint("--- charger already connected -------");
  //       final resp = await boot();
  //       debugPrint("---- boot reg charger --$resp");
  //       if (resp) {
  //         listenToBLEChargerUpdates();
  //       }
  //       Fluttertoast.showToast(msg: "Charger already connected");
  //       return true;
  //     }

  //     /// Starting the scan
  //     final respScan = await FlutterBluePlus.startScan(
  //       timeout: const Duration(seconds: 5),
  //     ) as List<ScanResult>;

  //     /// Connecting to the charger
  //     if (respScan.isNotEmpty) {
  //       final myDevice = respScan.indexWhere((element) =>
  //           element.device.name.trim() == chargerModel.value.chargerId.trim());
  //       if (myDevice != -1) {
  //         await connectToCharger(device: respScan[myDevice].device);
  //         if (await respScan[myDevice].device.state.first ==
  //             BluetoothDeviceState.connected) {
  //           final resp = await boot();
  //           if (resp) {
  //             listenToBLEChargerUpdates();
  //           }

  //           Fluttertoast.showToast(msg: "Charger Connected !");

  //           return true;
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: "Charger Failed to connect");
  //   }
  //   return false;
  // }

  void listenToWifiChargerUpdates() {
    final realTimeModelb = realtimeDBIntance
        .ref('chargers/${chargerModel.value.chargerId}')
        .onValue;

    Map<dynamic, dynamic> data = {};

    listener = realTimeModelb.listen((event) async {
      debugPrint("---- listeneing changes ----- to real time DB");

      data = event.snapshot.value as Map<dynamic, dynamic>;

      /// Updating [ChargerRealTimeModel]
      if (chargerRealtimeModel.value.voltageL1 == null) {
        chargerRealtimeModel.value = ChargerRealTimeModel.fromJson(
          data: data,
          chargerId: chargerModel.value.chargerId,
        );
      }

      /// Updating [ChargerRealTimeModel] when [ChargerStatus.FINISHING]
      // else if (chargerStatusFromString(data['chargerStatus'] as String) ==
      //     ChargerStatus.FINISHING) {
      //   chargerRealtimeModel.value = chargerRealtimeModel.value.copyWith(
      //     voltageL1: (data['vL1'] != null)
      //         ? double.parse(data['vL1'] as String)
      //         : null,
      //     voltageL2: (data['vL2'] != null)
      //         ? double.parse(data['vL2'] as String)
      //         : null,
      //     voltageL3: (data['vL2'] != null)
      //         ? double.parse(data['vL2'] as String)
      //         : null,
      //     currentL1: (data['iL1'] != null)
      //         ? double.parse(data['iL1'] as String)
      //         : null,
      //     currentL2: (data['iL2'] != null)
      //         ? double.parse(data['iL2'] as String)
      //         : null,
      //     currentL3: (data['iL2'] != null)
      //         ? double.parse(data['iL2'] as String)
      //         : null,
      //     chargerStatus:
      //         chargerStatusFromString(data['chargerStatus'] as String),
      //     connectionStatus: getConnectionStatus(data['connectionStatus']),
      //     initiateCharge: ((data['initiateCharge'] ?? 0) as int) == 1,
      //     freemode: ((data['freemode'].runtimeType == int)
      //         ? (data['freemode'] == 1 ? true : false)
      //         : data['freemode'] as bool),
      //     error: fromErrorCodes(code: (data["errorCode"] ?? "") as String),
      //     maxCurrentLimit: ((data['maxCurrentLimit'] ?? 0) as int),
      //   );
      // }

      /// Update [chargerRealtimeModel] whenever any other charger status is there
      else {
        // chargerRealtimeModel.value = chargerRealtimeModel.value.copyWith(
        //   voltageL1: (data['vL1'] != null)
        //       ? double.parse(data['vL1'] as String)
        //       : null,
        //   currentL1: (data['iL1'] != null)
        //       ? double.parse(data['iL1'] as String)
        //       : null,
        //   power: double.parse(data['totalSystemOutputPower'] as String),
        //   energy: double.parse(data['totalSystemOutputEnergy'] as String),
        //   chargerStatus:
        //       chargerStatusFromString(data['chargerStatus'] as String),
        //   connectionStatus: getConnectionStatus(data['connectionStatus']),
        //   initiateCharge: ((data['initiateCharge'] ?? 0) as int) == 1,
        //   freemode: ((data['freemode'].runtimeType == int)
        //       ? (data['freemode'] == 1 ? true : false)
        //       : data['freemode'] as bool),
        //   error: fromErrorCodes(code: (data["errorCode"] ?? "") as String),
        //   maxCurrentLimit: ((data['maxCurrentLimit'] ?? 0) as int),
        // );
        chargerRealtimeModel.value = chargerRealtimeModel.value
            .updateWith(data: Map<String, dynamic>.from(data));
      }

      // JUST TO MAINTAIN CHARGER START AND STOP TIME FOR CHARGING
      // if (connectionSwitch.value == 0) {
      await chargerStartStopWifi(data: data);
      // }

      // Updating connection status
      // connectionStatus.value = (chargerRealtimeModel.value.voltageL1 != null ||
      //         chargerRealtimeModel.value.voltageL1 != 0.0)
      //     ? ConnectionStatus.ONLINE
      //     : ConnectionStatus.OFFLINE;

      debugPrint(
          "------ charger model from wifi ---- ${chargerRealtimeModel.value.toMap()}");
    });
  }

  // /// To maintain energy, power and chargeTime in [ChargerStatus.FINISHING] state of [ChargerRealTimeModel]
  // bool chargerFlag = true;

  // /// Maintains chargerTime in [ChargerStatus.CHARGING] and [ChargerStatus.FINISHING] of [ChargerRealTimeModel]
  // final chargeTime = DateTime.now().obs;

  /// THIS BLE LISTNER UPDATING [ChargerRealTimeModel]
  void listenToBLEChargerUpdates() async {
    Map<String, dynamic> data = <String, dynamic>{};

    getData = bluetoothModel.value.readCharacterstic!.onValueReceived
        .listen((event) async {
      if (event.isNotEmpty) {
        // CONVERSION OF BLE MESSAGE
        final message = ascii.decode(event, allowInvalid: true);

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

              /// BUILDING [ChargerRealtimeModel] WHEN CHARGER GETS CONNECTED VERY FIRST TIME
              if (chargerRealtimeModel.value.voltageL1 == null) {
                chargerRealtimeModel.value = ChargerRealTimeModel.fromJson(
                  data: data,
                  chargerId: chargerModel.value.chargerId,
                );
              }

              /// UPDATING CHARGERMODEL CONTINIOUSLY WITH INCOMING [ESPFUNCTIONS.STATUS_NOTIFICATION]
              else {
                chargerRealtimeModel.value =
                    chargerRealtimeModel.value.updateWith(
                  data: data,
                  updateEnergyPower: chargerRealtimeModel.value.chargerStatus ==
                      ChargerStatus.FINISHING,
                );
              }

              if (chargerRealtimeModel.value.chargerStatus ==
                      ChargerStatus.FINISHING &&
                  chargerTimer.value == "") {
                chargerTimer.value = "00:00:00";
                int stopValue = (await firebaseRepository.realtimeDBIntance
                        .ref(
                            'chargers/${chargerModel.value.chargerId}/chargingTimerStop')
                        .get())
                    .value as int;
                int startValue = (await firebaseRepository.realtimeDBIntance
                        .ref(
                            'chargers/${chargerModel.value.chargerId}/chargingTimerStart')
                        .get())
                    .value as int;

                if (startValue != 0) {
                  if (stopValue == 0) {
                    stopValue = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                    await firebaseRepository.updateChargerVarFirebaseRTDB(
                      chargerId: chargerModel.value.chargerId,
                      value: "chargingTimerStop",
                      result: stopValue,
                    );
                  }
                  chargerTimer.value =
                      startValue.getChargerTimer(stopSeconds: stopValue);
                }
              }
            }

            /// Maintains ESPFUNCTIONS.FIRMWARE_NOTIFICATION[Firmware] updates coming here
            else if (respType == ESPFUNCTIONS.FIRMWARE_NOTIFICATION) {
              final list = jsonResp[1]["updateParameters"] as List<dynamic>;
              firmwareUpdateModel.value = firmwareUpdateModel.value.copyWith(
                percentageCompleted: int.parse(list[0]['value'] ?? "0"),
                timeElapsed: int.parse(list[1]['value'] ?? "0"),
                errorStatus:
                    (list.length > 2) ? list[2]['value'] ?? false : false,
                errorReason: (list.length > 3)
                    ? list[3]['value'] ?? "No Reason"
                    : "All good",
              );
              debugPrint(
                  "------ firmware updates --- ${firmwareUpdateModel.value.toMap()}");
            }

            /// Maintains ESPFUNCTIONS.CHARGER_TIMER
            else if (respType == ESPFUNCTIONS.CHARGER_TIMER &&
                connectionSwitch.value == 1) {
              final list = jsonResp[1]["timeParameters"] as List<dynamic>;
              debugPrint(
                  "---- timer resp ---- ${jsonResp[1]["timeParameters"]}");
              chargerTimer.value =
                  ((list[0]["value"] ?? "0000:00:00:00") as String)
                      .substring(5);
              if (list[0]["value"] == "0000:00:00:00") {
                if ((await firebaseRepository.realtimeDBIntance
                            .ref(
                                'chargers/${chargerModel.value.chargerId}/chargingTimerStart')
                            .get())
                        .value ==
                    0) {
                  await firebaseRepository.updateChargerVarFirebaseRTDB(
                    chargerId: chargerModel.value.chargerId,
                    value: "chargingTimerStart",
                    result: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  );
                }
              }
            } else if (respType == ESPFUNCTIONS.DPMNOTIFICATION &&
                connectionSwitch.value == 1) {
              debugPrint(
                  "--------- DPM Notification ---------- ${jsonResp.toString()}");

              final data = (jsonResp[1] as Map<String, dynamic>)['Params']
                  as List<dynamic>;

              final map = <String, dynamic>{};

              for (final kv in data) {
                map.addAll({kv['key']: kv['value']});
              }

              dpmModel.value = DpmCurrentModel.fromJson(map: map);
            }
            // }
            // catch(e){

            // }
          }
        } catch (e) {
          debugPrint("---- error by ble stream ---- ${e.toString()} -----");
        }
      }
    });
  }

  /// Maintain charger start stop consistently when only when charger connected via [WIFI]
  Future<void> chargerStartStopWifi(
      {required Map<dynamic, dynamic> data}) async {
    final start = (data["chargingTimerStart"] ?? 0) as int;
    final stop = (data["chargingTimerStop"] ?? 0) as int;

    debugPrint("---- $start charging timer -----$stop -----");

    // IF CHARGER IS AVAILABLE BUT CHARGER TIMER PARAMS ARE NOT UPDATED
    if (chargerRealtimeModel.value.chargerStatus == ChargerStatus.AVAILABLE &&
        (start != 0 || stop != 0)) {
      await firebaseRepository.updateChargerVarFirebaseRTDB(
        chargerId: chargerModel.value.chargerId,
        value: "chargingTimerStart",
        result: 0,
      );
      await firebaseRepository.updateChargerVarFirebaseRTDB(
        chargerId: chargerModel.value.chargerId,
        value: "chargingTimerStop",
        result: 0,
      );
    }

    /// IF CHARGER IS CHARGING
    if (chargerRealtimeModel.value.chargerStatus == ChargerStatus.CHARGING &&
        connectionSwitch.value == 0) {
      if (start != 0 && stop == 0) {
        // IF CHARGING LISTNER IS NULL THEN ONLY START A NEW ONE ELSE CONTINUE WITH THE OLDER ONE
        // if (chargingListner == null) {
        if (chargingListner != null) {
          chargingListner!.cancel();
        }
        chargingListner = Stream.periodic(const Duration(seconds: 1)).listen(
          (event) async {
            if (connectionSwitch.value == 1) {
              chargingListner!.cancel();
            }
            chargerTimer.value = start.getChargerTimer(
              stopSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            );
            debugPrint("---- charger timer value --- ${chargerTimer.value}");
          },
        );
      }
    }

    // WHEN CHARGING IS FINISHED
    else if (chargerRealtimeModel.value.chargerStatus ==
            ChargerStatus.FINISHING ||
        chargerRealtimeModel.value.chargerStatus ==
            ChargerStatus.SUSPENDED_EV ||
        chargerRealtimeModel.value.chargerStatus ==
            ChargerStatus.SUSPENDED_EVSE ||
        chargerRealtimeModel.value.chargerStatus == ChargerStatus.ERROR) {
      if (stop != 0 && start != 0) {
        chargerTimer.value = start.getChargerTimer(stopSeconds: stop);
        if (chargingListner != null) {
          await chargingListner!.cancel();
        }
      }
    }
  }

  // Future<void> updateChargerRealtimeModel() async {
  //   final json = await bleRepository.triggerStatusNotificationForPush(
  //       bluetoothModel: bluetoothModel.value);
  //   Map<String, dynamic> data = <String, dynamic>{};
  // for (final map in json["chargerParameters"] as List<dynamic>) {
  //   data.addIf(true, map['key'] as String, map['value']);
  // }
  //   debugPrint("---- ble result ---${data.toString()}");

  //   /// Updating [ChargerRealTimeModel]
  //   if (chargerRealtimeModel.value.voltageL1 == null) {
  //     chargerRealtimeModel.value = ChargerRealTimeModel.fromJson(
  //       data: data,
  //       chargerId: chargerModel.value.chargerId,
  //     );
  //   }

  //   /// Update [chargerRealtimeModel] whenever any other charger status is there
  //   else {
  //     chargerRealtimeModel.value = chargerRealtimeModel.value.copyWith(
  //       voltageL1:
  //           (data['vL1'] != null) ? double.parse(data['vL1'] as String) : null,
  //       voltageL2:
  //           (data['vL2'] != null) ? double.parse(data['vL2'] as String) : null,
  //       voltageL3:
  //           (data['vL3'] != null) ? double.parse(data['vL3'] as String) : null,
  //       currentL1:
  //           (data['iL1'] != null) ? double.parse(data['iL1'] as String) : null,
  //       currentL2:
  //           (data['iL2'] != null) ? double.parse(data['iL2'] as String) : null,
  //       currentL3:
  //           (data['iL3'] != null) ? double.parse(data['iL3'] as String) : null,
  //       power: double.parse(data['totalSystemOutputPower'] as String),
  //       energy: double.parse(data['totalSystemOutputEnergy'] as String),
  //       chargerStatus: chargerStatusFromString(data['chargerStatus'] as String),
  //       connectionStatus: getConnectionStatus(data['connectionStatus']),
  //       initiateCharge: ((data['initiateCharge'] ?? 0) as int) == 1,
  //       freemode: ((data['freemode'].runtimeType == int)
  //           ? (data['freemode'] == 1 ? true : false)
  //           : data['freemode'] as bool),
  //       error: fromErrorCodes(code: (data["errorCode"] ?? "") as String),
  //       maxCurrentLimit: ((data['maxCurrentLimit'] ?? 0) as int),
  //       chargeTime: (await firebaseRepository.getChargeFlagAndStart(
  //               value: "start", chargerId: chargerModel.value.chargerId)) ??
  //           0,
  //     );
  //   }

  //   // await chargerStartStop();

  //   // connectionStatus.value = (chargerRealtimeModel.value.voltageL1 != null ||
  //   //         chargerRealtimeModel.value.voltageL1 != 0.0)
  //   //     ? ConnectionStatus.ONLINE
  //   //     : ConnectionStatus.OFFLINE;
  //   // }
  // }

  // /// RETURNS ALL AVAILABLE WIFI SSID'S FROM THE CHARGER
  // Future<void> getWifiSsidList() async {
  //   scanning.value = StoreState.LOADING;
  //   // if (wifiModel.value.ssid == "") {
  //   await getWifiSsid();
  //   // }
  //   List<WifiModel> resp = [];
  //   //TODO: Update GETWIFISSID LIST
  //   await Future.delayed(const Duration(seconds: 8), () async {
  //     resp = await bleRepository.getWifiSsidList(model: bluetoothModel.value);
  //   });
  //   if (resp.isNotEmpty) {
  //     wifiSSIDList
  //       ..clear()
  //       ..addAll(resp);
  //   }

  //   scanning.value = StoreState.SUCCESS;
  // }

  // THIS MAINTAINS THE ANIMATION OF WIFI DIALOG BOX
  final crossFadeState = false.obs;

  // METHOD TO CHECK IF CHARGER IS CONNECTED WITH SOME WIFI
  Future<void> checkChargerHasWifi({
    WifiModel? ssidName,
  }) async {
    checkChargerWifiState.value = StoreState.LOADING;

    if (ssidName != null) {
      // if (wifiModel.value.currentConnected != null &&
      //     ssidName.ssid == wifiModel.value.currentConnected) {
      //   crossFadeState.value = false;
      // } else {
      //   crossFadeState.value = true;
      // }
      crossFadeState.value =
          !(ssidName.ssid == wifiModel.value.currentConnected);
    }

    /// Wifi network connection  is being tested
    // if (ssidName != null) {
    //   await Future.delayed(const Duration(seconds: 5), () async {
    //     crossFadeState.value = !(await bleRepository.checkSsidConnection(
    //       ssidName: ssidName.ssid,
    //       bluetoothModel: bluetoothModel.value,
    //     ));
    //     if (!crossFadeState.value) {
    //       wifiModel.value = ssidName;
    //     }
    //   });
    // }

    /// If charger auth is getting initiated
    // else {
    //   crossFadeState.value = true;
    // }

    checkChargerWifiState.value = StoreState.SUCCESS;
  }

  /// Connect to the selected WIFI
  Future<void> connectToWifiNetwork({
    required WifiModel model,
    required String ssidPass,
    required BuildContext context,
  }) async {
    // MAINTAIN THE STATE OF WIFI CONNECTION PART
    updating.value = StoreState.LOADING;

    wifiTriggerFlag.value = false;

    // MAINTAINS IF CHARGER CONNECTED WITH THE NETWORK OR NOT
    bool connectToWifiSsid = false;

    wifiModel.value = wifiModel.value.copyWith(
      ssid: model.ssid,
      rssi: model.rssi,
    );

    // WE CONNECT WITH DESIRED WIFI NETWORK AFTER A DELAY OF 5 SEC
    //TODO: NEED TO UPDATE THE TIME 5 SEC AND MAKE IT DYNAMIC
    // await Future.delayed(const Duration(seconds: 5), () async {
    connectToWifiSsid = await bleRepository.connectToWifiSsid(
      ssidName: model.ssid,
      ssidPass: ssidPass,
      bluetoothModel: bluetoothModel.value,
    );
    // });

    // CHARGER IS CONNECTED WITH THE NETWORK
    if (connectToWifiSsid) {
      // CHECKING FOR BB FIRMWARE >= 20
      if (int.parse(chargerModel.value.firmware!.substring(9)) >= 20) {
        debugPrint("------ new firmware ------");

        //-------------------- Implementation of wifi connection check
        int wifiStatus = 0, time = const Duration(minutes: 5).inSeconds;
        // disconnectCtr = 0;
        while (time >= 0) {
          await Future.delayed(const Duration(seconds: 1), () async {
            wifiStatus = await bleRepository.getWifiConnectionStatus(
                model: bluetoothModel.value);
          });
          time--;
          wifiModel.value = wifiModel.value.copyWith(connectionId: wifiStatus);

          if (wifiStatus == 3) {
            break;
          }
          // if (wifiStatus == 6) {
          //   disconnectCtr++;
          // }
          if (wifiStatus == 4 || wifiStatus == 5 || wifiTriggerFlag.value) {
            updating.value = StoreState.SUCCESS;
            wifiModel.value = wifiModel.value.copyWith(ssid: "", rssi: -1);
            Fluttertoast.showToast(
                msg: "Charger failed to connect the network");
            return;
          }
          // debugPrint("--- disconnect ctr ---- $disconnectCtr");
        }
        Fluttertoast.showToast(msg: "Wifi connection successful");
        // ---------------------------------------------------------------------------
        // CONFIRMING THE CHARGER IS CONNECTED SUCCESSFULLY
        await Future.delayed(
          const Duration(seconds: 2),
          () async {
            final checkWifiConfiguration =
                await bleRepository.checkWifiConfiguration(
              ssidName: model.ssid,
              bluetoothModel: bluetoothModel.value,
            );

            // IF CONNECTION IS SUCCESSFUL UPDATE THE [WIFIModel]
            if (checkWifiConfiguration) {
              // wifiModel.value = model;
              addChargerPageController.value++;
            } else {
              wifiModel.value = wifiModel.value.copyWith(ssid: "", rssi: -1);
            }
          },
        );
      } else {
        // //-------------------- Implementation of wifi connection check
        // int wifiStatus = 0, time = const Duration(minutes: 5).inSeconds;
        // // disconnectCtr = 0;
        // while (time >= 0) {
        //   await Future.delayed(const Duration(seconds: 1), () async {
        //     wifiStatus = await bleRepository.getWifiConnectionStatus(
        //         model: bluetoothModel.value);
        //   });
        //   time--;
        //   wifiModel.value = wifiModel.value.copyWith(connectionId: wifiStatus);

        //   if (wifiStatus == 3) {
        //     break;
        //   }
        //   // if (wifiStatus == 6) {
        //   //   disconnectCtr++;
        //   // }
        //   if (wifiStatus == 4 || wifiStatus == 5) {
        //     updating.value = StoreState.SUCCESS;
        //     Fluttertoast.showToast(
        //         msg: "Charger failed to connect the network");
        //     return;
        //   }
        //   // debugPrint("--- disconnect ctr ---- $disconnectCtr");
        // }
        // Fluttertoast.showToast(msg: "Wifi connection successful");
        // ---------------------------------------------------------------------------

        debugPrint("------ old firmware ------");

        // CONFIRMING THE CHARGER IS CONNECTED SUCCESSFULLY
        await Future.delayed(
          const Duration(seconds: 12),
          () async {
            final checkWifiConfiguration =
                await bleRepository.checkWifiConfiguration(
              ssidName: model.ssid,
              bluetoothModel: bluetoothModel.value,
            );

            // IF CONNECTION IS SUCCESSFUL UPDATE THE [WIFIModel]
            if (checkWifiConfiguration) {
              wifiModel.value = model;
              addChargerPageController.value++;
            } else {
              wifiModel.value = WifiModel(ssid: "", rssi: -1);
            }
          },
        );
      }
    }

    // IF CHARGER FAILED TO CONNECT WITH THE NETWORK
    if (wifiModel.value.ssid == "") {
      Fluttertoast.showToast(
          msg:
              "Failed to connect charger with your selected WiFi network, try again!");
    }

    // UPDATING THE LOADER
    updating.value = StoreState.SUCCESS;
  }

  Future<void> getWifiSsid() async {
    wifiModel.value = wifiModel.value.copyWith(
      currentConnected:
          await bleRepository.getWifiSSID(model: bluetoothModel.value),
    );
  }

  /// This is used to initiate charger to charger via BLE
  Future<void> initiateCharge({required String startStop}) async {
    chargingState.value = StoreState.LOADING;

    try {
      // int? resp;

      /// CHARGING INITATED VIA BLE
      if (connectionSwitch.value == 1) {
        if (startStop == "Start") {
          Fluttertoast.showToast(msg: "Charging initated");
        } else {
          Fluttertoast.showToast(msg: "Charging stopped");
        }
        await bleRepository.initateCharge(
          result: startStop,
          bluetoothModel: bluetoothModel.value,
        );
      }

      /// INITIATED VIA FIREBASE
      else {
        debugPrint("--- intiate charger via firebase ----");
        if (startStop == "Start") {
          Fluttertoast.showToast(msg: "Charging initated");
        } else {
          Fluttertoast.showToast(msg: "Charging stopped");
        }
        await firebaseRepository.initiateChargerWifi(
            model: chargerModel.value, start: startStop == "Start");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Please try again");
    }

    chargingState.value = StoreState.SUCCESS;
  }

  // ------------------------------------------------- RFID ---------------------------------------------------------------------------//

  /// List of all [SetupState.RFID]'s
  final rfidList = <RfidHiveModel>[].obs;

  /// List of all [SetupState.RFID]'s nicknames
  final rfidListNicknames = (<String, String>{}).obs;

  /// Add RFID loading state
  final addRFIDLoader = (StoreState.SUCCESS).obs;

  /// Stopwatch to check add rfid
  final addRFIDTime = (DateTime.now()).obs;

  Future<void> getRFIDList({bool? addDelay, bool? deleteDelay}) async {
    scanning.value = StoreState.LOADING;

    try {
      List<RfidHiveModel> list = [];

      /// Fetch the hiveList for RFID's
      final hiveList =
          await HiveBox().getRfidLists(chargerId: chargerModel.value.chargerId);
      if (hiveList.isNotEmpty) {
        rfidList.clear();
        rfidList.addAll(hiveList);
      }

      // Fetch the list from BLE
      if (connectionSwitch.value == 1 &&
          connectionStatus.value == ConnectionStatus.ONLINE) {
        if ((addDelay != null || deleteDelay != null)) {
          await Future.delayed(const Duration(seconds: 5), () async {
            list = await bleRepository.getListRFID(model: bluetoothModel.value);
          });
        } else {
          list = await bleRepository.getListRFID(model: bluetoothModel.value);
        }
      }

      // check if any new RFID is coming from BLE
      if (list.isNotEmpty && rfidList.isNotEmpty) {
        manageRfidSyncHive(listFromBle: list);
      }
      // if hive was completely empty
      else if (hiveList.isEmpty && list.isNotEmpty) {
        rfidList.clear();
        rfidList.addAll(list);
        rfidList.refresh();
      }
      // if (hiveList.isNotEmpty && list.isNotEmpty) {

      //   // if (addDelay != null) {
      //   //   addRfidTagName(rfid: rfidList.value.last.id);
      //   // }
      // }

      // rfidListNicknames.value = await hiveBox.getRfidLists(
      //   chargerId: chargerModel.value.chargerId,
      // );
    } catch (e) {
      debugPrint("---- getRFIDList exception --- ${e.toString()}");
    }

    scanning.value = StoreState.SUCCESS;
  }

  void manageRfidSyncHive({required List<RfidHiveModel> listFromBle}) {
    for (final model in listFromBle) {
      final index = rfidList.indexWhere((element) => element.id == model.id);
      // if the RFID is not present
      if (index == -1) {
        if (!model.id.startsWith("BB")) {
          // addRfidTagName(rfid: model, index: index); // Commented out call
        }
        // else{

        // }
      }
    }
  }

  Future<void> addRfidTag() async {
    if (chargerRealtimeModel.value.chargerStatus != ChargerStatus.CHARGING) {
      addRFIDLoader.value = StoreState.LOADING;
      addRFIDTime.value = DateTime.now();
      // Fluttertoast.showToast(msg: "Tap RFID card on charger within 30 secs");

      final resp = await bleRepository.addRFIDTag(model: bluetoothModel.value);

      if (resp) {
        addRFIDLoader.value = StoreState.SUCCESS;
        Fluttertoast.showToast(msg: "RFID added successfully");
        await getRFIDList(addDelay: true);
      } else {
        addRFIDLoader.value = StoreState.ERROR;
        Fluttertoast.showToast(msg: "Failed to add RFID");
      }
    } else {
      Fluttertoast.showToast(
        msg:
            "Please wait for charge session to complete before you add a new RFID",
        timeInSecForIosWeb: 10,
      );
    }
  }

  /// Update the Rfid nickname
  Future<void> addRfidTagName(
      {required RfidHiveModel rfid, required int index}) async {
    final nameController =
        TextEditingController(text: (rfid.name != "") ? rfid.name : null);

    customBottomSheet(
      controller: nameController,
      title: "a nickname",
      maxLength: 15,
      func: () async {
        if (nameController.value.text != "") {
          // rfidListNicknames[rfid] = nameController.text.trim();
          rfid = rfid.copyWith(name: nameController.text.trim());

          //  if the rfid was not present
          if (index == -1) {
            rfidList.add(rfid);
          }
          //  if the rfid name was updated
          else {
            rfidList.removeAt(index);
            rfidList.insert(index, rfid);
          }

          rfidList.refresh();

          /// Updating hive data structure
          await hiveBox.writeToDB(
            key: HiveKey.rfid,
            data: rfidList,
            chargerId: chargerModel.value.chargerId,
          );

          /// Refresh List[RfidHiveModel]
          rfidList.refresh();
          Get.back();

          // /// Fetch RFID nicknames from HIVE
          // rfidListNicknames.value = await hiveBox.getRfidLists(
          //     chargerId: chargerModel.value.chargerId);
        } else {
          Fluttertoast.showToast(msg: "Enter name");
        }
      },
    );

    // rfidListNicknames.value = await hiveBox.getRfidLists();
    // final textController = TextEditingController();
    // Get.dialog(AlertDialog(
    //   title: Text(
    //     "RFID Nickname",
    //     style: AppStyle.customTextStyle(
    //       fontWeight: FontWeight.w600,
    //       fontSize: getFontSize(18),
    //     ),
    //   ),
    //   content: SizedBox(
    //     height: getVerticalSize(100),
    //     child: Column(
    //       children: [
    //         Text(
    //           "Nickname",
    //           style: AppStyle.customTextStyle(
    //             fontWeight: FontWeight.w500,
    //             fontSize: getFontSize(16),
    //           ),
    //         ),
    //         CustomTextFormField(
    //           focusNode: FocusNode(),
    //           textInputType: TextInputType.name,
    //           controller: textController,
    //           margin: getMargin(
    //             top: 10,
    //             bottom: 20,
    //           ),
    //           // enabled:
    //           //     ((controller.text != "") && widget.isRegistration != null)
    //           //         ? false
    //           //         : true,
    //           // validator: validator,
    //           variant: TextFormFieldVariant.OutlineIndigo900,
    //           textInputAction: TextInputAction.done,
    //         ),
    //       ],
    //     ),
    //   ),
    //   actions: [
    //     Row(
    //       children: [
    //         CustomButton(
    //           width: getHorizontalSize(70),
    //           text: "Cancel",
    //           shape: ButtonShape.CircleBorder18,
    //           variant: ButtonVariant.FillWhiteA700,
    //           onTap: () async {
    //             Get.back();
    //           },
    //         ),
    //         const Spacer(),
    //         CustomButton(
    //           width: getHorizontalSize(80),
    //           text: "Proceed",
    //           shape: ButtonShape.CircleBorder18,
    //           variant: ButtonVariant.FillWhiteA700,
    //           onTap: () async {
    //             if (textController.text != "") {
    //               model = model.copyWith(name: textController.text.trim());
    //             } else {
    //               Fluttertoast.showToast(msg: "Invalid name");
    //             }
    //             Get.back();
    //           },
    //         ),
    //       ],
    //     ),
    //   ],
    // ));
  }

  // final errorTextForBottomSheet = "".obs;
  void customBottomSheet({
    required TextEditingController controller,
    required VoidCallback func,
    required String title,
    int? maxLength,
  }) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: getHorizontalSize(12),
          vertical: getVerticalSize(20),
        ),
        height: getVerticalSize(340),
        decoration: BoxDecoration(
          color: ColorConstant.whiteA700,
          borderRadius: BorderRadius.circular(
            getSize(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    "Provide $title",
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: AppStyle.customTextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: getFontSize(17),
                      color: ColorConstant.indigo900,
                    ),
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle,
                        color: ColorConstant.red700,
                        size: getSize(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: getVerticalSize(15),
            ),
            Text.rich(TextSpan(
              text: "Enter Name",
              style: AppStyle.customTextStyle(
                fontWeight: FontWeight.w600,
                fontSize: getFontSize(18),
              ),
              children: [
                TextSpan(
                  text: (maxLength != null)
                      ? "\n(Maximum length $maxLength characters)"
                      : "",
                  style: AppStyle.customTextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: getFontSize(16),
                  ),
                ),
              ],
            )
                // overflow: TextOverflow.ellipsis,
                // textAlign: TextAlign.left,
                // style: AppStyle.txtWorkSansRomanRegular14Black900,
                ),
            CustomTextFormField(
              inputFormatters: [
                LengthLimitingTextInputFormatter(maxLength),
              ],
              focusNode: FocusNode(),
              textInputType: TextInputType.name,
              controller: controller,
              margin: getMargin(
                // left: 33,
                top: 10,
                // right: 32,
                bottom: 20,
              ),
              validator: (value) {
                if (value != null) {
                  if (value == "") {
                    return "Enter Name";
                  }
                }
                return null;
              },
              onChanged: (value) {},
              variant: TextFormFieldVariant.OutlineIndigo900,
              textInputAction: TextInputAction.done,
            ),
            Padding(
              padding: getPadding(top: 20),
              child: CustomButton(
                height: getVerticalSize(
                  36,
                ),
                width: getHorizontalSize(
                  170,
                ),
                onTap: func,
                text: "Done",
                variant: ButtonVariant.OutlineIndigo900,
                alignment: Alignment.center,
              ),
            ),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          getSize(15),
        ),
      ),
      isDismissible: false,
    );
  }

  Future<void> deleteRfidTag(
      {required RfidHiveModel model, required int index}) async {
    final resp = await bleRepository.deleteRFIDTag(
      model: bluetoothModel.value,
      tag: model.id,
    );
    if (resp) {
      // deletion from the rfidList
      rfidList.removeAt(index);

      // deletion from hive
      await HiveBox().writeToDB(
        key: HiveKey.rfid,
        data: rfidList,
        chargerId: chargerModel.value.chargerId,
      );

      Fluttertoast.showToast(msg: "RFID deleted successfully");

      await getRFIDList(deleteDelay: true);
    } else {
      Fluttertoast.showToast(msg: "Failed to delete RFID");
    }
  }

  // ------------------------------------------------------- RFID ----------------------------------------------------------------------//

  Future<void> updateMaxCurrentLimit() async {
    bool? resp;

    chargerRealtimeModel.value = chargerRealtimeModel.value
        .copyWith(maxCurrentLimit: setMaxCurrent.value);

    if (connectionSwitch.value == 1 &&
        chargerRealtimeModel.value.chargerStatus != ChargerStatus.UNAVAILABLE) {
      resp = await bleRepository.setMaxCurrentLimit(
          model: bluetoothModel.value,
          limit: chargerRealtimeModel.value.maxCurrentLimit!);
    }
    resp = await firebaseRepository.updateMaxCurrentLimit(
      maxCurrentLimit: chargerRealtimeModel.value.maxCurrentLimit!,
      chargerId: chargerModel.value.chargerId,
    );

    if (resp != null) {
      Fluttertoast.showToast(msg: "Max current limit updated successfully");
    } else {
      Fluttertoast.showToast(msg: "Failed to update max current limit");
    }
  }

  // // ------------------------------- Delete charger -----------------------//

  // Future<void> deleteCharger({required String chargerId}) async {
  //   final isActive = chargerModel.value.chargerId == chargerId;

  //   /// Update firestore by removing usedId and making last used false
  //   final resp = await firebaseRepository.deleteCharger(chargerId: chargerId);

  //   /// Delete the Hive box
  //   final hiveResp = await HiveBox().deleteBox(chargerId: chargerId);

  //   if (resp && hiveResp) {
  //     Fluttertoast.showToast(msg: "Charger deleted successfully");

  //     /// If active charger
  //     if (isActive) {
  //       await disposeCharger();
  //     }

  //     await getListMyChargers();
  //   }
  // }

  // ---------------------------------------------------------- Firebase ------------------------------------------------------------------------//

  // Future<bool> checkIfChargerExists() async {
  //   final result = await firebaseRepository.checkIfChargerExists();
  //   debugPrint("---- charger exist result --- $result");
  //   if (result != null) {
  //     chargerModel.value = result;

  //     /// Fetch chargerNicknames from HIVE
  //     chargerNicknameList.value = await hiveBox.getChargerNicknames();
  //     switchConnections(index: 1);

  //     debugPrint("--- fetched model ---- ${chargerModel.value.toMap()}");
  //     Get.find<BottomNavigationController>().navPage.value = 0;
  //     return true;
  //   }

  //   /// If user has no registered chargers
  //   else {
  //     return false;
  //   }
  // }

  /// Enable and disable this button to prevent repeated calls
  final firmwareUpdateButton = true.obs;

  // Future<void> getLatestFirmware() async {
  //   updateChargerState.value = StoreState.LOADING;

  //   latestFirmwareName.value = "";
  //   final resp = await firebaseRepository.getChargerFirmwareList();
  //   if (resp != null) {
  //     if (chargerModel.value.firmware != resp) {
  //       latestFirmwareName.value = resp;
  //     } else {
  //       Fluttertoast.showToast(
  //           msg: "Charger is already updates to the latest version");
  //     }
  //   }

  //   updateChargerState.value = StoreState.SUCCESS;
  // }

  Future<void> updateFirmware() async {
    if (firmwareUpdateButton.value) {
      updateState.value = StoreState.LOADING;

      firmwareUpdateButton.value = false;

      // await Future.delayed(const Duration(seconds: 10), () {});

      final connectStatus = await firebaseRepository.getChargerConnectionStatus(
          chargerId: chargerModel.value.chargerId);

      if (connectStatus == ConnectionStatus.ONLINE) {
        if (latestFirmwareName.value !=
            ("${chargerModel.value.firmware}.bin")) {
          final updateResp = await bleRepository.updateChargerFirmware(
            firmware: latestFirmwareName.value,
            bluetoothModel: bluetoothModel.value,
          );
          if (updateResp != null) {}
        } else {
          Fluttertoast.showToast(msg: "Charger is already updated");
        }
      } else {
        Fluttertoast.showToast(msg: "Charger is not connected to wifi");
      }

      firmwareUpdateButton.value = true;

      updateState.value = StoreState.SUCCESS;
    } else {
      Fluttertoast.showToast(msg: "Firmware download in progress");
    }
  }

  Future<void> hardReset() async {
    resetState.value = StoreState.LOADING;
    if (connectionStatus.value == ConnectionStatus.ONLINE) {
      if (connectionSwitch.value == 1) {
        if (await bleRepository.hardReset(
            bluetoothModel: bluetoothModel.value)) {
          Fluttertoast.showToast(msg: "Charger factory reset successfully");
        } else {
          Fluttertoast.showToast(msg: "Charger factory reset failed");
        }
      } else {
        Fluttertoast.showToast(msg: "Please connect charger via bluetooth");
      }
    } else {
      Fluttertoast.showToast(msg: 'Charger is offline');
    }

    resetState.value = StoreState.SUCCESS;
  }

  Future<void> softReset() async {
    resetState.value = StoreState.LOADING;

    if (connectionStatus.value == ConnectionStatus.ONLINE) {
      if (connectionSwitch.value == 1) {
        if (await bleRepository.softReset(
            bluetoothModel: bluetoothModel.value)) {
          Fluttertoast.showToast(msg: "Charger rebooted successfully");
        } else {
          Fluttertoast.showToast(msg: "Charger reboot failed");
        }
      } else {
        Fluttertoast.showToast(msg: "Connect to charger via bluetooth");
      }
    } else {
      Fluttertoast.showToast(msg: "Charger is offline");
    }

    resetState.value = StoreState.SUCCESS;
  }

  final chargerNicknameList = (HashMap<String, String>()).obs;

  // Future<void> getListMyChargers({ChargerModel? model}) async {
  //   chargerListState.value = StoreState.LOADING;
  //   final userId = Get.find<AuthController>().currentUser!.uid;

  //   if (model != null) {
  //     await firebaseRepository.updateChargerStatus(
  //       userId: userId,
  //       chargerId: model.chargerId,
  //     );

  //     latestFirmwareName.value = "";

  //     firmwareUpdateModel.value = FirmwareUpdateModel(
  //       percentageCompleted: 0,
  //       timeElapsed: 0,
  //       errorStatus: false,
  //       errorReason: "",
  //     );

  //     wifiModel.value = WifiModel(ssid: "", rssi: -1);

  //     chargerRealtimeModel.value = ChargerRealTimeModel(
  //       chargerId: model.chargerId,
  //       chargerStatus: ChargerStatus.UNAVAILABLE,
  //     );

  //     chargerModel.value = model;

  //     switchConnections(index: 1);
  //   }

  //   // Refetching done to update the status of list
  //   final resp = await firebaseRepository.getListChargers(userId: userId);

  //   /// Fetch chargerNickNames from HIVE
  //   chargerNicknameList.value = await hiveBox.getChargerNicknames();

  //   if (resp.isNotEmpty) {
  //     chargersList
  //       ..clear()
  //       ..addAll(resp);
  //   } else {
  //     chargersList.value = <ChargerModel>[];
  //     Fluttertoast.showToast(msg: "No available chargers found");
  //   }

  //   chargerListState.value = StoreState.SUCCESS;
  // }

  final checkChargerUserState = (StoreState.SUCCESS).obs;

  // Future<void> checkChargerUser({required ScanResult scanResult}) async {
  //   checkChargerUserState.value = StoreState.LOADING;
  //   final model = ChargerModel(
  //     chargerId: scanResult.device.advName,
  //     userId: Get.find<AuthController>().userModel.value.userId!,
  //     // remoteId: scanResult.device.remoteId.str,
  //   );

  //   final resp = await firebaseRepository.checkChargerUser(
  //     model: model,
  //   );

  //   if (resp) {
  //     chargerModel.value = model;

  //     // await FlutterBluePlus.stopScan();
  //     // scanDevicesListener!.cancel();
  //     // scanDevicesListener = null;

  //     addChargerPageController.value++;
  //   } else {
  //     Fluttertoast.showToast(msg: "The Charger is already registered");
  //   }

  //   checkChargerUserState.value = StoreState.LOADING;
  // }

  // ---------------------------------------------- Schedule Charging -------------------------------------------------------------------//

  /// This shows the current schedule
  // final sheduleModel = ScheduleHiveModel(
  //   startTime: 0,
  //   days: [1, 1, 1, 1, 1, 1, 1],
  //   id: "",
  //   active: false,
  // ).obs;

  /// This is to update/add new schedule
  // final addScheduleModel = ScheduleModel(
  //   startTime: 0,
  //   days: [1, 1, 1, 1, 1, 1, 1],
  //   id: "",
  //   hrs: 0,
  //   active: false,
  // ).obs;
  final scheduleModel = ScheduleHiveModel(
    id: "",
    timeStart: 0,
    timeStop: 0,
    duration: 0,
    days: [0, 0, 0, 0, 0, 0, 0],
    active: false,
    type: -1,
  ).obs;
  final addScheduleModel = ScheduleHiveModel(
    id: "",
    timeStart: 0,
    timeStop: 0,
    duration: 3600,
    days: [1, 1, 1, 1, 1, 1, 1],
    active: false,
    type: -1,
  ).obs;

  final startTime = TimeOfDay.now().obs;
  final stopTime = TimeOfDay.now().obs;
  final scheduleDuration = Duration.zero.obs;
  final scheduleToggle = (ScheduleType.NONE).obs;
  final scheduleState = (StoreState.SUCCESS).obs;

  int get durationText =>
      ((DateTime.now()).add(scheduleDuration.value)).millisecondsSinceEpoch;

  /// List Of all schedules for [ChargerModel]
  final schedulesList = (<ScheduleHiveModel>[]).obs;

  /// To manage schedule list fetch state
  final scheduleListState = (StoreState.SUCCESS).obs;

  void removeScheduleDialog({required ScheduleHiveModel model}) {
    // if (model.id != scheduleModel.value.id) {597082631
    if (connectionSwitch.value == 0) {
      Fluttertoast.showToast(msg: "Please connect charger via bluetooth");
    } else if (connectionSwitch.value == 1 &&
        connectionStatus.value == ConnectionStatus.ONLINE) {
      myGetDialog(
          title: "Delete Schedule",
          subTitle: "Do you want to delete schedule?",
          callback: () async {
            await deactivateSchedule(type: scheduleToggle.value);
            Get.back();
          });
      // Get.dialog(AlertDialog(
      //   surfaceTintColor: ColorConstant.whiteA700,
      //   title: Text(
      //     "Delete Schedule?",
      //     style: AppStyle.customTextStyle(
      //       fontWeight: FontWeight.w600,
      //       fontSize: getFontSize(18),
      //       color: ColorConstant.red700,
      //     ),
      //   ),
      //   content: Text(
      //     "Would you like to delete this schedule?",
      //     style: AppStyle.customTextStyle(
      //       fontWeight: FontWeight.w600,
      //       fontSize: getFontSize(18),
      //     ),
      //   ),
      //   actions: [
      //     Row(
      //       children: [
      //         CustomButton(
      //           width: getHorizontalSize(70),
      //           text: "Cancel",
      //           shape: ButtonShape.CircleBorder18,
      //           variant: ButtonVariant.FillWhiteA700,
      //           onTap: () async {
      //             Get.back();
      //           },
      //         ),
      //         const Spacer(),
      //         CustomButton(
      //           width: getHorizontalSize(80),
      //           text: "Proceed",
      //           shape: ButtonShape.CircleBorder18,
      //           variant: ButtonVariant.FillWhiteA700,
      //           onTap: () async {
      //             await deactivateSchedule(type: scheduleToggle.value);
      //             Get.back();
      //           },
      //         ),
      //       ],
      //     ),
      //   ],
      // ));
    } else {
      Fluttertoast.showToast(msg: "Charger is offline");
    }
    // } else {
    //   Fluttertoast.showToast(msg: "Cannot delete activated schedule");
    // }
  }

  // Future<void> removeSchedule({required ScheduleHiveModel model}) async {
  //   final index = schedulesList.indexWhere((element) => element.id == model.id);

  //   debugPrint("----- ${scheduleModel.value.id} ------- ${model.id} ----");

  //   if (index != -1) {
  //     debugPrint("--- remove schedule model ---- ${model.id}");

  //     deleteSchedule();

  //     schedulesList.removeAt(index);
  //     schedulesList.refresh();

  //     // await hiveBox.writeHiveSchedule(list: schedulesList.value);
  //     await hiveBox.writeToDB(
  //       key: HiveKey.schedule,
  //       data: scanResultList.value,
  //     );
  //   } else {
  //     debugPrint("----- schedule not found -------");
  //   }
  // }

  void addScheduleDialog(
      {required BuildContext context, required ScheduleType type}) {
    // if (connectionSwitch.value == 0) {
    //   Fluttertoast.showToast(msg: "Please connect charger via bluetooth");
    // } else {
    addScheduleModel.value = ScheduleHiveModel(
      id: "",
      timeStart: 0,
      timeStop: 0,
      duration: 3600,
      days: [1, 1, 1, 1, 1, 1, 1],
      active: false,
      type: -1,
    );

    scheduleDuration.value = Duration.zero;

    List<String> weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    Get.dialog(AlertDialog(
      surfaceTintColor: ColorConstant.whiteA700,
      // backgroundColor: ColorConstant.whiteA700,
      title: Text(
        "Select time",
        style: AppStyle.customTextStyle(
          fontWeight: FontWeight.w600,
          fontSize: getFontSize(18),
        ),
      ),
      content: Container(
        height: getVerticalSize(300),
        child: Obx(() {
          return Column(
            children: [
              Divider(
                color: ColorConstant.gray500,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Start Time",
                    style: AppStyle.customTextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: getFontSize(17),
                    ),
                  ),
                  Container(
                    height: getVerticalSize(20),
                    width: getHorizontalSize(1),
                    decoration: BoxDecoration(color: ColorConstant.gray500),
                  ),
                  GestureDetector(
                    onTap: () {
                      infoBits(
                        title: "Duration",
                        subTitle:
                            "Refers to the time the charger will be authorized before being connected to the vehicle",
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          "Duration",
                          style: AppStyle.customTextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: getFontSize(17),
                          ),
                        ),
                        SizedBox(
                          width: getHorizontalSize(7),
                        ),
                        Icon(
                          Icons.info_outline,
                          color: ColorConstant.black900,
                          size: getSize(20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                color: ColorConstant.gray500,
              ),
              SizedBox(
                height: getVerticalSize(8),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        startTimeString,
                        style: AppStyle.customTextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: getFontSize(18),
                        ),
                      ),
                      SizedBox(
                        height: getVerticalSize(7),
                      ),
                      GestureDetector(
                        onTap: () async {
                          startTime.value = (await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                initialEntryMode: TimePickerEntryMode.dial,
                                // orientation: Orientation.landscape,
                                builder: (_, Widget? child) {
                                  return Theme(
                                    data: ThemeData(
                                      useMaterial3: true,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: false,
                                        ),
                                        child: child!,
                                      ),
                                    ),
                                  );
                                },
                              )) ??
                              TimeOfDay.now();
                        },
                        child: Text(
                          "Pick",
                          style: AppStyle.customTextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: getFontSize(18),
                            color: ColorConstant.indigo900,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: getVerticalSize(20),
                    width: getHorizontalSize(1),
                  ),
                  Column(
                    children: [
                      Text(
                        //TODO: change this
                        // "${addScheduleModel.value.duration ~/ 3600} hr",
                        // "$durationText secs",
                        scheduleDuration.value.duration(),
                        style: AppStyle.customTextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: getFontSize(18),
                        ),
                      ),
                      SizedBox(
                        height: getVerticalSize(7),
                      ),
                      GestureDetector(
                        onTap: () async {
                          // hourSelectionDialog();
                          String errorText = "";
                          final widget = CupertinoTimerPicker(
                            mode: CupertinoTimerPickerMode.hm,
                            initialTimerDuration: const Duration(minutes: 1),
                            onTimerDurationChanged: (duration) {
                              if (duration.inMinutes == 0) {
                                errorText =
                                    "Please set the minimum duration of atleast 1 minute";
                              } else {
                                errorText = "";
                              }
                              scheduleDuration.value = duration;
                            },
                          );

                          final radius = BorderRadius.only(
                            topLeft: Radius.circular(getSize(20)),
                            topRight: Radius.circular(getSize(20)),
                          );

                          Get.bottomSheet(
                              Container(
                                height: getVerticalSize(420),
                                padding: const EdgeInsets.only(top: 6.0),
                                decoration: BoxDecoration(
                                  color: ColorConstant.whiteA700,
                                  borderRadius: radius,
                                ),
                                margin: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom,
                                ),
                                // color: CupertinoColors.systemBackground
                                //     .resolveFrom(context),
                                child: SafeArea(
                                    child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          width: getSize(30),
                                        ),
                                        Text(
                                          "Select Duration",
                                          style: AppStyle.customTextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: getFontSize(18),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            if (scheduleDuration.value ==
                                                Duration.zero) {
                                              Fluttertoast.showToast(
                                                  msg: "Invalid duration");
                                              return;
                                            }
                                            Get.back();
                                          },
                                          icon: Icon(
                                            CupertinoIcons.xmark_circle,
                                            color: ColorConstant.red700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: getVerticalSize(10),
                                    ),
                                    // Offstage(
                                    //   offstage: errorText == "",
                                    //   child: Text(
                                    //     errorText,
                                    //     style: AppStyle.customTextStyle(
                                    //       fontWeight: FontWeight.w500,
                                    //       fontSize: getFontSize(16),
                                    //       color: ColorConstant.red700,
                                    //     ),
                                    //   ),
                                    // ),
                                    // SizedBox(
                                    //   height: getVerticalSize(10),
                                    // ),
                                    widget,
                                    SizedBox(
                                      height: getVerticalSize(10),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getHorizontalSize(30),
                                      ),
                                      child: CustomButton(
                                        onTap: () {
                                          if (scheduleDuration.value ==
                                              Duration.zero) {
                                            Fluttertoast.showToast(
                                                msg: "Invalid duration");
                                            return;
                                          }
                                          Get.back();
                                        },
                                        variant: ButtonVariant.OutlineIndigo900,
                                        text: "Done",
                                      ),
                                    ),
                                  ],
                                )),
                              ),
                              shape:
                                  RoundedRectangleBorder(borderRadius: radius));

                          // showCupertinoModalPopup(
                          //     context: context,
                          //     builder: (_) {
                          //       return Container(
                          //         height: getVerticalSize(300),
                          //         padding: const EdgeInsets.only(top: 6.0),
                          //         decoration: BoxDecoration(
                          //           borderRadius: BorderRadius.only(
                          //             topLeft: radius,
                          //             topRight: radius,
                          //           ),
                          //         ),
                          //         margin: EdgeInsets.only(
                          //           bottom: MediaQuery.of(context)
                          //               .viewInsets
                          //               .bottom,
                          //         ),
                          //         color: CupertinoColors.systemBackground
                          //             .resolveFrom(context),
                          //         child: SafeArea(child: widget),
                          //       );
                          //     });
                        },
                        child: Text(
                          "Pick",
                          style: AppStyle.customTextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: getFontSize(18),
                            color: ColorConstant.indigo900,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: getPadding(top: 40, bottom: 20),
                    child: Text(
                      "Days:",
                      textAlign: TextAlign.left,
                      style: AppStyle.customTextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: getFontSize(17)),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0, 1, 2, 3, 4, 5, 6]
                    .map(
                      (e) => Expanded(
                        child: Text(
                          weekdays[e],
                          textAlign: TextAlign.center,
                          style: AppStyle.customTextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: getFontSize(15),
                            color: ColorConstant.black900,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0, 1, 2, 3, 4, 5, 6]
                    .map(
                      (e) => Expanded(
                        child: Checkbox(
                          value: addScheduleModel.value.days[e] == 1,
                          onChanged: ((value) {
                            if (value != null) {
                              final list = addScheduleModel.value.days;
                              if (value) {
                                list[e] = 1;
                              } else {
                                list[e] = 0;
                              }
                              addScheduleModel.value =
                                  addScheduleModel.value.copyWith(days: list);
                            }
                          }),
                          activeColor: ColorConstant.indigo900,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        }),
      ),
      actions: [
        Row(
          children: [
            CustomButton(
              width: getHorizontalSize(70),
              text: "Cancel",
              shape: ButtonShape.CircleBorder18,
              variant: ButtonVariant.FillWhiteA700,
              onTap: () async {
                Get.back();
              },
            ),
            const Spacer(),
            CustomButton(
              width: getHorizontalSize(80),
              text: "Proceed",
              shape: ButtonShape.CircleBorder18,
              variant: ButtonVariant.FillWhiteA700,
              onTap: () async {
                if (scheduleDuration.value == Duration.zero) {
                  Fluttertoast.showToast(msg: "Duration cannot be set to zero");
                  return;
                }
                await addSchedule(type: type);
                Get.back();
              },
            ),
          ],
        ),
      ],
    ));
    // }
  }

  void hourSelectionDialog() {
    addScheduleModel.value = addScheduleModel.value.copyWith(duration: 3600);
    Get.dialog(
      AlertDialog(
        surfaceTintColor: ColorConstant.whiteA700,
        title: Obx(() {
          return Text(
            "Select hours: ${addScheduleModel.value.duration ~/ 3600}",
            style: AppStyle.customTextStyle(
                fontWeight: FontWeight.w600, fontSize: getFontSize(16)),
          );
        }),
        content: Obx(() {
          debugPrint("----- slider : ${addScheduleModel.value.duration}");
          return SizedBox(
            height: getVerticalSize(50),
            child: Slider.adaptive(
                min: 1,
                max: 12,
                activeColor: ColorConstant.blueA700,
                value: (addScheduleModel.value.duration ~/ 3600).toDouble(),
                onChanged: (value) {
                  final data = value * 3600;
                  debugPrint("---- slider changed value ---- $data");
                  addScheduleModel.value =
                      addScheduleModel.value.copyWith(duration: data.toInt());
                }),
          );
        }),
        actions: [
          Row(
            children: [
              CustomButton(
                width: getHorizontalSize(70),
                text: "Cancel",
                shape: ButtonShape.CircleBorder18,
                variant: ButtonVariant.FillWhiteA700,
                onTap: () async {
                  // await bleRepository.deleteSchedule(
                  //   bluetoothModel: bluetoothModel.value,
                  // );
                  Get.back();
                },
              ),
              const Spacer(),
              CustomButton(
                width: getHorizontalSize(80),
                text: "Proceed",
                shape: ButtonShape.CircleBorder18,
                variant: ButtonVariant.FillWhiteA700,
                onTap: () async {
                  Get.back();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get startTimeString {
    String res = "";
    if (startTime.value.hour < 10) {
      res += '0';
    }
    res += "${startTime.value.hour}";

    res += " : ";

    if (startTime.value.minute < 10) {
      res += '0';
    }
    res += "${startTime.value.minute}";

    return res;
    // return "00 : 00";
  }

  void _setScheduleStartEndTime() {
    final timeOfDay = startTime.value;
    final hours = addScheduleModel.value.duration;

    debugPrint("scheduleDuration : ${scheduleDuration.value.inSeconds}");

    final startDateTime = DateTime.now().copyWith(
      hour: timeOfDay.hour,
      minute: timeOfDay.minute,
      second: 0,
    );

    addScheduleModel.value = addScheduleModel.value.copyWith(
      active: true,
      timeStart: startDateTime.millisecondsSinceEpoch ~/ 1000,
      // TODO: change in timeStop and duration
      // timeStop: (startDateTime.millisecondsSinceEpoch + (hours * 1000)) ~/ 1000,
      // duration: hours,
      timeStop: (startDateTime.millisecondsSinceEpoch +
              (scheduleDuration.value.inMilliseconds)) ~/
          1000,
      duration: scheduleDuration.value.inSeconds,
      type: (scheduleToggle.value == ScheduleType.FREE_SCHEDULE) ? 0 : 1,
      // id: "${startDateTime.millisecondsSinceEpoch ~/ 1000}${((startDateTime.millisecondsSinceEpoch ~/ 1000) + (hours * 1000))}${addScheduleModel.value.duration}",
      id: "${startDateTime.millisecondsSinceEpoch ~/ 1000}${(startDateTime.millisecondsSinceEpoch + (scheduleDuration.value.inMilliseconds)) ~/ 1000}${addScheduleModel.value.duration}",
    );
  }

  //TODO: Earlier implementation
  // Future<void> getSchedules() async {
  //   scheduleState.value = StoreState.LOADING;

  //   ScheduleHiveModel? model;

  //   /// Fetch [ScheduleHiveModel] from BLE
  //   if (connectionSwitch.value == 1) {
  //     model = await bleRepository.getSchedule(model: bluetoothModel.value);
  //   }

  //   /// Get all schedules stored inside Hive
  //   final list = await HiveBox().getHiveSchedules(
  //     chargerId: chargerModel.value.chargerId,
  //   );

  //   /// If an active [ScheduleHiveModel] found
  //   if (model != null) {
  //     /// Update the current model
  //     scheduleModel.value = model;

  //     /// Update the List[ScheduleHiveModel]
  //     schedulesList.clear();
  //     schedulesList.add(model);
  //     schedulesList.refresh();

  //     if (list.isEmpty) {
  //       /// Write the changes to Hive
  //       await HiveBox().writeToDB(
  //         key: HiveKey.schedule,
  //         data: schedulesList.value,
  //         chargerId: chargerModel.value.chargerId,
  //       );
  //     }
  //   } else {
  //     scheduleModel.value = ScheduleHiveModel(
  //       id: "",
  //       timeStart: 0,
  //       timeStop: 0,
  //       duration: 0,
  //       days: [0, 0, 0, 0, 0, 0, 0],
  //       active: false,
  //     );

  //     /// If List[ScheduleHiveModel] is available
  //     if (list.isNotEmpty) {
  //       schedulesList.clear();
  //       schedulesList.addAll(list);

  //       scheduleModel.value = list.first;

  //       schedulesList.refresh();
  //     }

  //     /// If the list is empty
  //     else {
  //       scheduleState.value = StoreState.ERROR;
  //       Fluttertoast.showToast(msg: "No schedules found");
  //       return;
  //     }
  //   }

  //   scheduleState.value = StoreState.SUCCESS;
  // }

  Future<void> getSchedules() async {
    if (connectionSwitch.value != 1 ||
        connectionStatus.value == ConnectionStatus.OFFLINE) {
      return;
    }

    scheduleToggle.value = ScheduleType.NONE;

    if (chargerRealtimeModel.value.freemode!) {
      scheduleToggle.value = ScheduleType.PLUG_PLAY;
      return;
    }

    scheduleListState.value = StoreState.LOADING;

    ScheduleHiveModel? model;

    if (connectionSwitch.value == 1) {
      model = await bleRepository.getSchedule(
        model: bluetoothModel.value,
      );
      if (model != null) {
        scheduleModel.value = model;
        scheduleToggle.value = getScheduleType(type: model.type);
        scheduleListState.value = StoreState.SUCCESS;
        return;
      }
    }

    scheduleListState.value = StoreState.ERROR;
  }

  // Future<void> getSchedules() async {
  //   ScheduleHiveModel? model;
  //   List<ScheduleHiveModel> list;

  //   scheduleState.value = StoreState.LOADING;

  //   if (connectionSwitch.value == 1) {
  //     model = await bleRepository.getSchedule(model: bluetoothModel.value);
  //     if (model != null) {
  //       scheduleModel.value = model;
  //     }
  //   }
  //   list = await HiveBox()
  //       .getHiveSchedules(chargerId: chargerModel.value.chargerId);

  //   // When there is no activeModel or list obtained
  //   if (model == null && list.isEmpty) {
  //     return;
  //   }
  //   // When there is activeModel but list is empty
  //   if (list.isEmpty) {
  //     list.add(model!);
  //     schedulesList
  //       ..clear()
  //       ..addAll(list);
  //     schedulesList.refresh();
  //   }
  //   // When the activeModel is null and list is not empty
  //   else if (model == null) {
  //     final listModel =
  //         list.firstWhereOrNull((element) => element.active == true);

  //     if (listModel != null) {
  //       scheduleModel.value = listModel;
  //       scheduleModel.refresh();
  //       // Activate this schedule by passing it to the charger
  //     }

  //     schedulesList
  //       ..clear()
  //       ..addAll(list);
  //     schedulesList.refresh();
  //   }
  //   // active list and active model
  //   else {
  //     final index = list.indexWhere((element) => element.id == model!.id);
  //     if (!list[index].active) {
  //       list[index] = list[index].copyWith(active: true);
  //     }

  //     schedulesList
  //       ..clear()
  //       ..addAll(list);
  //     schedulesList.refresh();
  //   }

  //   scheduleState.value = StoreState.SUCCESS;
  // }

  //TODO: Earlier implementation
  // Future<void> addSchedule() async {
  //   /// Deletion of exisitng schedule
  //   if (scheduleModel.value.active) {
  //     await deleteSchedule();
  //   }

  //   /// Set the schedule time
  //   _setScheduleStartEndTime();

  //   /// Activate the schedule
  //   await activateSchedule(
  //     model: addScheduleModel.value,
  //     isNew: true,
  //   );
  // }

  Future<void> addSchedule({required ScheduleType type}) async {
    if (type.toggleValue() == -1) {
      return;
    }
    debugPrint("------ schedule type : ${type.toggleValue()} ------- ");

    _setScheduleStartEndTime();

    //TODO: Add type to this function
    final value = await bleRepository.activateSchedule(
      bluetoothModel: bluetoothModel.value,
      model: addScheduleModel.value,
      type: type,
    );
    if (value) {
      debugPrint(
          "---- addScheduleModel ------ ${addScheduleModel.value.toMap()}");
      scheduleModel.value = addScheduleModel.value;
      scheduleToggle.value = type;
      scheduleModel.refresh();
      scheduleListState.value = StoreState.SUCCESS;
      // await getSchedules();
    } else {
      scheduleToggle.value = ScheduleType.NONE;
      scheduleListState.value = StoreState.ERROR;
      Fluttertoast.showToast(msg: "Failed to add schedule");
    }
  }

  // TODO:Earlier implementation
  // Future<void> deleteSchedule() async {
  //   /// Deactivate schedule
  //   await deactivateSchedule(model: scheduleModel.value);

  //   /// Clear the scheduleslist
  //   schedulesList.clear();
  //   schedulesList.refresh();

  //   /// Delete from Hive
  //   await HiveBox().deleteAllSchedules(
  //     chargerId: chargerModel.value.chargerId,
  //   );
  // }
  Future<void> deleteSchedule() async {
    if (scheduleModel.value.id == "") {
      return;
    }
    final value = await bleRepository.deleteSchedule(
        bluetoothModel: bluetoothModel.value);
    if (value) {
      scheduleModel.value = scheduleModel.value.remove();
      scheduleModel.refresh();
      scheduleToggle.value = ScheduleType.NONE;
      scheduleListState.value = StoreState.ERROR;
    } else {
      Fluttertoast.showToast(msg: "Failed to delete the schedule");
    }
  }

  //TODO: Earlier implementation
  Future<void> activateSchedule({
    required ScheduleType type,
    required BuildContext context,
  }) async {
    if (type == scheduleToggle.value) {
      return;
    }

    scheduleState.value = StoreState.LOADING;

    await deactivateSchedule(type: scheduleToggle.value);

    switch (type) {
      case ScheduleType.PLUG_PLAY:
        final value = await bleRepository.plugAndPlay(
          result: 1,
          bluetoothModel: bluetoothModel.value,
        );
        if (value) {
          scheduleToggle.value = ScheduleType.PLUG_PLAY;
          scheduleListState.value = StoreState.ERROR;
        } else {
          scheduleToggle.value = ScheduleType.NONE;
        }
        break;
      case ScheduleType.FREE_SCHEDULE:
        addScheduleDialog(context: context, type: type);
        break;
      case ScheduleType.TARIFF_SCHEDULE:
        addScheduleDialog(context: context, type: type);
        break;
      case ScheduleType.NONE:
        break;
    }

    scheduleState.value = StoreState.SUCCESS;
  }

  // Future<void> activateSchedule({
  //   required ScheduleHiveModel model,
  //   bool? isNew,
  // }) async {
  //   if (model.active && isNew == null) {
  //     return;
  //   }

  //   model = model.copyWith(active: true);

  //   await bleRepository.activateSchedule(
  //     bluetoothModel: bluetoothModel.value,
  //     model: model,
  //   );

  //   scheduleModel.value = model;
  //   scheduleModel.refresh();

  //   if (isNew != null) {
  //     schedulesList.insert(0, model);
  //   } else {
  //     final index =
  //         schedulesList.indexWhere((element) => element.id == model.id);
  //     if (index != -1) {
  //       schedulesList
  //         ..removeAt(index)
  //         ..insert(index, model);
  //     }
  //   }

  //   schedulesList.refresh();

  //   await HiveBox().writeToDB(
  //     key: HiveKey.schedule,
  //     data: schedulesList.value,
  //   );
  // }

  //TODO: Earlier Implementation
  // Future<void> deactivateSchedule({required ScheduleHiveModel model}) async {
  //   /// If already deactivated
  //   if (!model.active) {
  //     Fluttertoast.showToast(msg: "Schedule not active");
  //   }

  //   /// Deactivate activated schedule
  //   else {
  //     model = model.copyWith(active: false);

  //     /// Deactivate schedule
  //     final resp = await bleRepository.deleteSchedule(
  //         bluetoothModel: bluetoothModel.value);

  //     if (resp) {
  //       /// Update current schdule
  //       scheduleModel.value = model;

  //       /// Update list of schedules
  //       schedulesList.clear();
  //       schedulesList.add(model);
  //       // schedulesList.refresh();

  //       /// Update Hive with the status
  //       await HiveBox().writeToDB(
  //         key: HiveKey.schedule,
  //         data: schedulesList.value,
  //         chargerId: chargerModel.value.chargerId,
  //       );

  //       await getSchedules();
  //     }
  //   }
  // }
  Future<void> deactivateSchedule({required ScheduleType type}) async {
    // if (type == scheduleToggle.value) {
    //   return;
    // }

    scheduleState.value = StoreState.LOADING;

    switch (type) {
      case ScheduleType.PLUG_PLAY:
        if (chargerRealtimeModel.value.freemode!) {
          final value = await bleRepository.plugAndPlay(
            result: 0,
            bluetoothModel: bluetoothModel.value,
          );
          if (value) {
            scheduleToggle.value = ScheduleType.NONE;
          }
        }
        break;
      case ScheduleType.FREE_SCHEDULE:
        await deleteSchedule();
        break;
      case ScheduleType.TARIFF_SCHEDULE:
        await deleteSchedule();
        break;
      case ScheduleType.NONE:
        break;
    }

    scheduleState.value = StoreState.SUCCESS;
  }

  // ---------------------------------------------- Schedule Charging -------------------------------------------------------------------//

  // ---------------------------------------------- Transaction -------------------------------------------------------------------------//
  final transactionType = 0.obs;
  final downloadedTransactions = 0.obs;
  final transactionLoadingState = (StoreState.SUCCESS).obs;
  final transactionDownloadState = (StoreState.SUCCESS).obs;
  final chargeSessionModel = TransactionRespModel().obs;
  final transactionRepository = TransactionRepository();
  final date = (DateTime.now().millisecondsSinceEpoch).obs;
  final maxY = (5 as num).obs;
  final chartFactor = (2 as num).obs;
  final recordsModel = RecordsRespModel(size: 0).obs;
  bool startIsolate = false;
  final monthEnergy = true.obs;
  final lifeTimeStats = (0.0).obs;
  final lastTransactionModel = TransactionHiveModel(
    id: 0,
    timeStart: 0,
    timeStop: 0,
    meterValues: 0,
    idTag: "",
  ).obs;

  Future<void> getTransactions() async {
    transactionLoadingState.value = StoreState.LOADING;
    final respModel = await transactionRepository.getChargingSessions(
      chargerId: chargerModel.value.chargerId,
      date: (date.value).toString(),
      type: (transactionType.value).toString(),
      isEnergy: monthEnergy.value,
    );
    try {
      maxY.value = 10.0;
      if (respModel != null) {
        chargeSessionModel.value = respModel;
        debugPrint(
            "---- chargeSessionModel ----- ${chargeSessionModel.value.toMap().toString()}");
        double totalEnergy = 0;
        for (final data in respModel.data!) {
          if (data.value != null) {
            final list = (data.value as List<dynamic>).cast<num>();
            if (list.isNotEmpty) {
              totalEnergy = (list.fold(0, (p, c) => p + c));
              maxY.value = list.fold(maxY.value, (p, c) => (p > c) ? p : c);
              debugPrint("----- maxY.value ---- ${maxY.value}");
            }
          }
        }
        chargeSessionModel.value =
            chargeSessionModel.value.copyWith(totalEnergy: totalEnergy);
      } else {
        debugPrint("------ no transactions found ------");
      }
      if ((maxY.value.toInt()) > 0) {
        chartFactor.value = (((maxY.value.toDouble())) / 5).toPrecision(2);
      }
      // debugPrint("---- chart factor ${chartFactor.value} ------");
    } catch (e) {
      debugPrint("------ getTransactions ----- ${e.toString()}");
    }
    transactionLoadingState.value = StoreState.SUCCESS;
  }

  Future<void> getTransactionsCount() async {
    transactionLoadingState.value = StoreState.LOADING;
    final count = await bleRepository.triggerTransactions(
      bluetoothModel: bluetoothModel.value,
    );
    if (count != null) {
      recordsModel.value = recordsModel.value.copyWith(size: count);
      if (count > 0) {
        Get.dialog(AlertDialog(
          surfaceTintColor: ColorConstant.whiteA700,
          title: Text(
            "Transactions detected!",
            style: AppStyle.customTextStyle(
              fontWeight: FontWeight.w600,
              fontSize: getFontSize(18),
              color: ColorConstant.red700,
            ),
          ),
          content: Text(
            "Stored transaction detected, would you like to retrieve them?\n\n$count records found!",
            style: AppStyle.customTextStyle(
              fontWeight: FontWeight.w600,
              fontSize: getFontSize(16),
              color: ColorConstant.black900,
            ),
          ),
          actions: [
            Row(
              children: [
                CustomButton(
                  width: getHorizontalSize(70),
                  text: "Cancel",
                  shape: ButtonShape.CircleBorder18,
                  variant: ButtonVariant.FillWhiteA700,
                  onTap: () async {
                    Get.back();
                  },
                ),
                const Spacer(),
                CustomButton(
                  width: getHorizontalSize(80),
                  text: "Proceed",
                  shape: ButtonShape.CircleBorder18,
                  variant: ButtonVariant.FillWhiteA700,
                  onTap: () async {
                    Get.back();
                    await getListTransactions();
                  },
                ),
              ],
            ),
          ],
        ));
      }
    } else {
      debugPrint("------ no transactions from BLE found -----");
    }
    transactionLoadingState.value = StoreState.SUCCESS;
  }

  Future<void> getListTransactions() async {
    transactionDownloadState.value = StoreState.LOADING;

    final list = await bleRepository.triggerTransactionsMessages(
      bluetoothModel: bluetoothModel.value,
      count: recordsModel.value.size,
    );
    if (list.isNotEmpty) {
      try {
        await hiveBox.writeToDB(
          key: HiveKey.transaction,
          data: list,
          chargerId: chargerModel.value.chargerId,
        );
      } catch (e) {
        debugPrint("------ getListTransactions ---- ${e.toString()}");
      }
      // finally {
      //   recordsModel.value = recordsModel.value.copyWith(size: 0);
      // }
    } else {
      Fluttertoast.showToast(msg: "Failed to download transactions");
    }
    transactionDownloadState.value = StoreState.SUCCESS;

    // await getTransactionsCount();
    await pushTransactionsToFirebase();

    /// Get all transaction from firebase
    date.value = DateTime.now().millisecondsSinceEpoch;
    await getTransactions();

    /// Get the last activity
    await getLastTransaction();

    /// Get the liftime stats
    await getLifetimeStats();
  }

  Future<void> getLastTransaction() async {
    transactionLoadingState.value = StoreState.LOADING;

    final model = await firebaseRepository.getLastTransaction(
        chargerId: chargerModel.value.chargerId);
    print("Model : $model");
    if (model != null) {
      /// Writing Last Transaction to Hive
      await hiveBox.writeToDB(
        key: HiveKey.lastTransaction,
        data: model,
        chargerId: chargerModel.value.chargerId,
      );
      debugPrint(
          "---- last transaction ---- ${(model.timeStop - model.timeStart)} ----- ${model.id}");
    } else {
      debugPrint("failed to get last transaction");
    }

    /// Fetch last transaction record
    final lastRecord = await hiveBox.getLastTransaction(
      chargerId: chargerModel.value.chargerId,
    );

    // /// Getting RFID's
    // await getRFIDList();

    if (lastRecord != null) {
      lastTransactionModel.value = lastRecord;
      if (lastRecord.idTag == "") {
        // final index =
        //     rfidList.indexWhere((element) => element.id == lastRecord.idTag);
        // if (index != -1) {
        //   lastTransactionModel.value =
        //       lastTransactionModel.value.copyWith(idTag: rfidList[index].name);
        // }
        lastTransactionModel.value = lastTransactionModel.value
            .copyWith(idTag: chargerModel.value.chargerId);
      }
      // else {
      //   lastTransactionModel.value = lastTransactionModel.value
      //       .copyWith(idTag: chargerModel.value.chargerId);
      // }
    }

    //TODO: Updated RFID
    // /// Fetch RFID Nicknames to show on Last Activity Widget
    // rfidListNicknames.value = await hiveBox.getRfidLists(
    //   chargerId: chargerModel.value.chargerId,
    // );

    transactionLoadingState.value = StoreState.SUCCESS;
  }

  Future<void> pushTransactionsToFirebase() async {
    /// Fetch transactions from HIVE DB
    final transactions = await HiveBox().getTransactions(
      chargerId: chargerModel.value.chargerId,
    );

    debugPrint(
        "---- hive transaxctions to firebase ------- ${transactions.toString()}");

    //push transactions to firebase
    if (transactions != null && transactions.isNotEmpty) {
      await ChargerFirebaseRepository().postTransactions(
        list: transactions,
        chargerId: chargerModel.value.chargerId,
      );

      await HiveBox().deleteTransactions(
        chargerId: chargerModel.value.chargerId,
      );
    } else {
      debugPrint("---- no transactions -----");
    }
    // final port = ReceivePort();
    // if (startIsolate) {
    //   return;
    // } else {
    //   startIsolate = true;

    //   try {
    //     await FlutterIsolate.spawn(
    //       _threadTransactions,
    //       [
    //         port.sendPort,
    //         {
    //           // "count": resp,
    //           // "id": id,
    //           "chargerId": chargerModel.value.chargerId,
    //         }
    //       ],
    //     );
    //   } finally {
    //     startIsolate = false;
    //     // FlutterIsolate.killAll();
    //   }
    // }
  }

  @pragma('vm:entry-point')
  static void _threadTransactions(List<dynamic> list) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final data = list[1] as Map<String, dynamic>;

      /// push to cache Hive DB
      await HiveBox().init();

      /// Fetch transactions from HIVE DB
      final transactions = await HiveBox().getTransactions(
        chargerId: data['chargerId'] as String,
      );

      // intialise firebase
      if (Platform.isIOS) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );

      //push transactions to firebase
      if (transactions != null && transactions.isNotEmpty) {
        await ChargerFirebaseRepository().postTransactions(
          list: transactions,
          chargerId: data['chargerId'] as String,
        );

        await HiveBox().deleteTransactions(
          chargerId: data['chargerId'] as String,
        );
      }
    } catch (e) {
      debugPrint("error with Isolate ---- ${e.toString()}");
    }
    FlutterIsolate.current.kill();
  }

  // Stream<DocumentSnapshot<Map<String, dynamic>>> getEnergyConsumed() {
  //   return firebaseRepository.getEnergyConsumed(
  //     chargerId: chargerModel.value.chargerId,
  //   );
  // }
  Future<void> getLifetimeStats() async {
    final resp = await firebaseRepository.getEnergyConsumed(
        chargerId: chargerModel.value.chargerId);
    if (resp != null) {
      /// Update Life time stats on Hive
      await hiveBox.writeToDB(
        key: HiveKey.energyConsumed,
        data: resp,
        chargerId: chargerModel.value.chargerId,
      );
    }

    lifeTimeStats.value = await hiveBox.getLifeTimeStats(
      chargerId: chargerModel.value.chargerId,
    );
  }

  void infoBits({
    required String title,
    required String subTitle,
    bool? dpmError,
    Color? color,
    double? fontSize,
  }) {
    Get.dialog(AlertDialog(
      surfaceTintColor: ColorConstant.whiteA700,
      title: Text(
        title,
        style: AppStyle.customTextStyle(
          fontWeight: FontWeight.w600,
          fontSize: getFontSize(fontSize ?? 16),
          color: color ?? ColorConstant.indigoA700,
        ),
      ),
      content: Text(
        subTitle,
        style: AppStyle.customTextStyle(
          fontWeight: FontWeight.w600,
          fontSize: getFontSize(fontSize ?? 16),
        ),
      ),
      actions: [
        CustomButton(
          width: getHorizontalSize(80),
          text: "Ok",
          shape: ButtonShape.CircleBorder18,
          variant: ButtonVariant.FillWhiteA700,
          onTap: () async {
            if (dpmError != null) {
              await changeDpmStatus(status: DpmStatus.OFF);
            }
            Get.back();
          },
        ),
      ],
    ));
  }

  // ------------------------------------------------- transaction ---------------------------------------------------------------
  void myGetDialog({
    required String title,
    required String subTitle,
    VoidCallback? callback,
    Color? color,
    double? fontSize,
  }) {
    Get.dialog(AlertDialog(
      surfaceTintColor: ColorConstant.whiteA700,
      title: Text(
        title,
        style: AppStyle.customTextStyle(
          fontWeight: FontWeight.w600,
          fontSize: getFontSize(fontSize ?? 16),
          color: color ?? ColorConstant.indigoA700,
        ),
      ),
      content: Text(
        subTitle,
        style: AppStyle.customTextStyle(
          fontWeight: FontWeight.w600,
          fontSize: getFontSize(fontSize ?? 16),
        ),
      ),
      actions: [
        CustomButton(
          width: getHorizontalSize(80),
          text: "No",
          shape: ButtonShape.CircleBorder18,
          variant: ButtonVariant.FillWhiteA700,
          onTap: () async {
            Get.back();
          },
        ),
        CustomButton(
          width: getHorizontalSize(80),
          text: "Yes",
          shape: ButtonShape.CircleBorder18,
          variant: ButtonVariant.FillWhiteA700,
          onTap: callback,
        ),
      ],
    ));
  }

  // ----------------------------------------------------------------- Dynamic power management --------------------------------------------------//

  final dpmStatus = (DpmStatus.OFF).obs;
  final dpmState = (StoreState.SUCCESS).obs;
  final setPower = ("").obs;
  final dpmModel =
      DpmCurrentModel(il1: "0", il2: "0", il3: "0", ilMax: "0", iLAvl: "0").obs;

  Future<void> checkDpmStatus() async {
    dpmState.value = StoreState.LOADING;
    final resp = await bleRepository.getDpmCheck(model: bluetoothModel.value);
    if (resp == null) {
      dpmState.value = StoreState.SUCCESS;
      Get.back();
      Fluttertoast.showToast(msg: "Failed to find BRIGHTBLU power manager");
      return;
    }
    if (resp) {
      await Future.delayed(const Duration(seconds: 2), () async {
        await getDpmStatus();
      });

      await Future.delayed(const Duration(seconds: 2), () async {
        await getDpmPower();
      });

      dpmState.value = StoreState.SUCCESS;
    } else {
      dpmState.value = StoreState.ERROR;
    }
  }

  Future<void> getDpmStatus() async {
    // dpmState.value = StoreState.LOADING;
    final resp = await bleRepository.getDpmStatus(model: bluetoothModel.value);
    if (resp == null) {
      Fluttertoast.showToast(msg: "Failed to get dpmStatus");
      return;
    }
    if (resp == DpmStatus.OFF) {
      setPower.value = "0";
    } else {
      await getDpmPower();
    }
    dpmStatus.value = resp;
  }

  Future<void> getDpmPower() async {
    final resp = await bleRepository.getDpmPower(model: bluetoothModel.value);
    if (resp == null) {
      return;
    }

    setPower.value = resp;
  }

  Future<void> changeDpmStatus({required DpmStatus status}) async {
    dpmState.value = StoreState.LOADING;

    final resp = await bleRepository.changeDpmStatus(
      model: bluetoothModel.value,
      status: status,
    );
    if (resp == null || !resp) {
      return;
    }
    if (status == DpmStatus.ON) {
      await Future.delayed(const Duration(seconds: 2), () async {
        await getDpmPower();
      });
    }

    dpmStatus.value = status;

    dpmState.value = StoreState.SUCCESS;
  }

  Future<void> changeDpmPower() async {
    // debugPrint("----- dpm power ----- ${setPower.value}");
    final resp = await bleRepository.changeDpmPower(
      model: bluetoothModel.value,
      power: setPower.value,
    );
    if (resp == null || !resp) {
      return;
    }
    Fluttertoast.showToast(msg: "Power updated");
  }
}
