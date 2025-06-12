import 'dart:async';
import 'dart:convert';

import 'package:bb_factory_test_app/controller/charger_controller.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/models/bluetooth_model_new.dart';
import 'package:bb_factory_test_app/models/charger_model.dart';
import 'package:bb_factory_test_app/repository/charger_ble_repository.dart';
import 'package:bb_factory_test_app/bluetooth_test_screen.dart';
import 'package:bb_factory_test_app/services/ble_service.dart';
import 'package:bb_factory_test_app/utils/constants.dart';
import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:bb_factory_test_app/utils/enums/store_state.dart';
import 'package:bb_factory_test_app/utils/widgets/app_header.dart';
import 'package:bb_factory_test_app/utils/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class MainWifiScreen extends StatefulWidget {
  const MainWifiScreen({super.key});

  @override
  State<MainWifiScreen> createState() => _MainWifiScreenState();
}

class _MainWifiScreenState extends State<MainWifiScreen> {
  final chargerController = Get.put(ChargerController());
  final BleService _bleService = BleService();
  StreamSubscription<List<int>>? _bootResponseSubscription;

  final bleRepository = ChargerBLERepository();
  bool start = false;
  remoteStartStop() async {
    // final statusNotificationResp = await bleRepository
    //             .triggerStatusNotification(bluetoothModel: bluetoothModel.value);

    print("ChargerStatus 1 : ${chargerController.currentChargerStatus}");

    if (chargerController.currentChargerStatus == ChargerStatus.PREPARING ||
        chargerController.currentChargerStatus == ChargerStatus.CHARGING ||
        chargerController.currentChargerStatus == ChargerStatus.FINISHING) {
      print("ChargerStatus : ${chargerController.currentChargerStatus}");

      if (chargerController.currentChargerStatus == ChargerStatus.CHARGING) {
        await chargerController.initiateCharge(startStop: "Stop");
      } else {
        await chargerController.initiateCharge(startStop: "Start");
      }
    } else if (chargerController.currentChargerStatus ==
        ChargerStatus.AVAILABLE) {
      Fluttertoast.showToast(msg: "Kindly attach charging gun to your car ");
    } else if (chargerController.currentChargerStatus ==
        ChargerStatus.FINISHING) {
      Fluttertoast.showToast(
          msg: "Kindly remove the charging gun from your car");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // remoteStartStop();
  }

  @override
  Widget build(BuildContext context) {
    //  final controller = Get.find<Controller>()..bluetoothAdapterState();
    final controller = Get.put(Controller()..bluetoothAdapterState());
    return Scaffold(
      appBar: AppHeader(
        actions: [
          Obx(
            () => IconButton(
              onPressed: () async {},
              icon: Icon((controller.isBleOn)
                  ? Icons.bluetooth
                  : Icons.bluetooth_disabled),
              color: (controller.isBleOn) ? Colors.blueAccent : Colors.red,
            ),
          )
        ],
      ),
      body: Obx(() {
        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: (controller.isBleOn)
                      ? _mainScreen(controller)
                      : _bluetoothStatus(),
                ),
              ],
            ),
            if (controller.state.value == StoreState.LOADING)
              const SpinKitCircle(
                color: Colors.blueAccent,
              )
          ],
        );
      }),
    );
  }

//TODO: We can add any error widget here or illustrations
  Widget _bluetoothStatus() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            text: "Your bluetooth adapted is off",
            style: Constants.customTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: "\n\nKindly enable bluetooth to continue",
                style: Constants.customTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainScreen(Controller controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    text: "Welcome",
                    style: Constants.customTextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                    children: [
                      TextSpan(
                        text: "\nHere are your BRIGHTBLU chargers",
                        style: Constants.customTextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await controller.startScan();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.blueAccent,
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text.rich(
              TextSpan(
                text: "\nNote:",
                style: Constants.customTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
                children: [
                  TextSpan(
                    text: "\n1. Press reload to scan for BRIGHTBLU chargers.",
                    style: Constants.customTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: "\n2. Kindly verify the chargerID before connecting.",
                    style: Constants.customTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            // child: Obx(
            //   () {
            //     switch (controller.state.value) {
            //       case StoreState.LOADING:
            //         return const StateWidget(
            //           state: StoreState.LOADING,
            //           data: "",
            //         );
            //       case StoreState.SUCCESS:
            //         return _chargersList(controller);
            //       case StoreState.ERROR:
            // return const StateWidget(
            //   state: StoreState.ERROR,
            //   data: "Failed to fetch the chargers",
            // );
            //       case StoreState.EMPTY:
            //         return const StateWidget(
            //           state: StoreState.EMPTY,
            //           data: "No chargers found",
            //         );
            //     }
            //   },
            // ),
            child: StreamBuilder(
                stream: FlutterBluePlus.scanResults,
                builder: (_, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    if (snapshot.data!.isEmpty) {
                      return const StateWidget(
                        state: StoreState.EMPTY,
                        data: "No chargers found",
                      );
                    }
                    snapshot.data!.removeWhere((element) =>
                        (element.device.advName == "" ||
                            element.device.advName.length < 14));
                    return _chargersList(
                      controller: controller,
                      list: snapshot.data!,
                    );
                  }
                  const Text("data");
                  return const StateWidget(
                    state: StoreState.ERROR,
                    data: "Failed to fetch the chargers",
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _chargersList({
    required List<ScanResult> list,
    required Controller controller,
  }) {
    // final list = controller.chargerList;
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          child: ListView.separated(
            itemBuilder: (_, index) {
              return ListTile(
                title: Text(
                  list[index].device.advName,
                  style: Constants.customTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: ElevatedButton(
                  //TODO: Connection logic
                  onPressed: () async {
                    // await controller.connectCharger(
                    //   device: list[index].device,
                    // );
                    await chargerController.connectToChargerViaBLE(
                        device: list[index].device);
                    await controller.connectCharger(device: list[index].device);
//                     await _bleService.connectToDevice(list[index].device);
//                     await _bleService.sendBootNotification();
// // Listen for response
//                     _bootResponseSubscription =
//                         _bleService.responseStream.listen(
//                       (response) async {
//                         try {
//                           // Cancel the subscription immediately after receiving the first response
//                           await _bootResponseSubscription?.cancel();
//                           _bootResponseSubscription = null;

//                           // Close the connecting dialog
//                           if (mounted && Navigator.canPop(context)) {
//                             // Navigator.of(context).pop();
//                           }

//                           // Parse the response
//                           final responseStr = String.fromCharCodes(response);
//                           print('Received boot response: $responseStr');

//                           // Parse the JSON response
//                           List<dynamic> responseData = jsonDecode(responseStr);
//                           if (responseData.length >= 2 &&
//                               responseData[0] == "BootNotification" &&
//                               responseData[1] is Map) {
//                             Map<String, dynamic> info = responseData[1];
//                             final charger = ChargerModel.fromBLE(
//                               chargerId: list[index].device.advName.toString(),
//                               phase: info['phase']
//                                   as String?, // Assuming 'phase' key exists
//                               connector: double.tryParse(info['connectors']
//                                   .toString()), // Assuming 'connectors' key exists
//                               firmware: (info['chargePointFirmwareVersion'] ??
//                                       info['FirmwareVersion'])
//                                   as String?, // Assuming firmware keys exist
//                               joltType: info['chargePointModel']
//                                   as String?, // Assuming 'chargePointModel' key exists
//                             );

//                             if (!mounted) return;

//                             // Determine charger type based on firmware
//                             final firmwareVersion = charger.firmware ?? '';
//                             String chargerType = "Unknown";

//                             if (firmwareVersion.startsWith("4.0") ||
//                                 firmwareVersion.startsWith("5.0")) {
//                               chargerType = "Jolt Business";
//                             } else if (firmwareVersion.startsWith("BBJLv1.")) {
//                               chargerType = "Jolt Home";
//                             } else if (firmwareVersion.startsWith("4.1") ||
//                                 firmwareVersion.startsWith("5.1")) {
//                               chargerType = "Jolt Home Plus";
//                             }

//                             print(
//                                 'Detected Charger Type: $chargerType (Firmware: $firmwareVersion)');

//                             // Navigate based on charger type
//                             Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => BluetoothTest(
//                                           chargerId: list[index]
//                                               .device
//                                               .advName
//                                               .toString(),
//                                         )));
//                           } else {
//                             if (!mounted) return;
//                             setState(() {
//                               // _errorMessage = 'Invalid response format from device';
//                               Fluttertoast.showToast(
//                                   msg: 'Invalid response format from device');
//                             });
//                           }
//                         } catch (e) {
//                           if (!mounted) return;
//                           setState(() {
//                             // _errorMessage = 'Error processing device response: $e';
//                             Fluttertoast.showToast(
//                                 msg:
//                                     'Error processing device response: ${e.toString()}');
//                           });
//                         }
//                       },
//                       onError: (error) {
//                         // Close the connecting dialog
//                         if (mounted && Navigator.canPop(context)) {
//                           Navigator.of(context).pop();
//                         }

//                         setState(() {
//                           // _errorMessage = 'Error receiving response: $error';
//                         });
//                       },
//                     );
                    // remoteStartStop();
                    // Navigator.pushReplacement(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => BluetoothTest(
                    //               chargerId:
                    //                   list[index].device.advName.toString(),
                    //             )));
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.blueAccent),
                  ),
                  child: const Text(
                    "Connect",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, index) {
              return const SizedBox(
                height: 10,
              );
            },
            itemCount: list.length,
          ),
        ),
        // SizedBox(
        //     height: 50,
        //     child: GestureDetector(
        //         onTap: () {
        //           showDialog(
        //             context: context,
        //             builder: (context) => const SSIDDialog(),
        //           );
        //         },
        //         child: const Text("Tap to enter SSID manually.")))
      ],
    );
  }
}
