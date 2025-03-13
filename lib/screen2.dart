import 'dart:async';

import 'package:bb_factory_test_app/controller/charger_controller.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/repository/charger_ble_repository.dart';
import 'package:bb_factory_test_app/screen3.dart';
import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothTest extends StatefulWidget {
  String chargerId = '';
   BluetoothTest({super.key,required this.chargerId});

  @override
  State<BluetoothTest> createState() => _BluetoothTestState();
}

class _BluetoothTestState extends State<BluetoothTest> {
  final chargerController = Get.put(ChargerController());
  final chargerController1 = Get.find<ChargerController>();
  final controller = Get.find<Controller>();
bool testingStatus = false;
  final bleRepository = ChargerBLERepository();
  Timer? _timer;
  int _countdown = 150; // 2 minutes
  bool _isCountingDown = false;
  bool _isTimerStopped = false;
  void startCountdown() {
    setState(() {
      _countdown = 150;
      _isCountingDown = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();

        remoteStartStop();
        setState(() {
          _isTimerStopped = true;
          _isCountingDown = false;

        });
        print("Counting is Down : $_isCountingDown");
      }
    });
  }
String engineer_name = '';

  remoteStartStop() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    // final statusNotificationResp = await bleRepository
    //             .triggerStatusNotification(bluetoothModel: bluetoothModel.value);
    if (!_isCountingDown) {
      setState(() {
        _isCountingDown = true;
      });
    }

    print("ChargerStatus 1 : ${chargerController.currentChargerStatus}");

    if (chargerController.currentChargerStatus == ChargerStatus.PREPARING ||
        chargerController.currentChargerStatus == ChargerStatus.CHARGING ||
        chargerController.currentChargerStatus == ChargerStatus.FINISHING) {
      print("ChargerStatus : ${chargerController.currentChargerStatus}");

      if (chargerController.currentChargerStatus == ChargerStatus.CHARGING) {
        await chargerController.initiateCharge(startStop: "Stop");
        // setState(() {
        //   _countdown = 15;
        // });
        await chargerController.getListTransactions();

        await chargerController.getLastTransaction();
      await chargerController.getLifetimeStats();
      //  controller.listenToBLEChargerUpdates();
    await controller.getStatusNotification();
    engineer_name = preferences.getString('engineer_name')!;
    print("Charger Values : ${widget.chargerId}");
     print("Charger Values1 : ${chargerController1.chargerRealtimeModel.value.chargerId.toString()}");
    await controller.generateTestPdf(chargerId: widget.chargerId, voltage: chargerController.chargerRealtimeModel.value.voltageL1.toString(), power: chargerController.chargerRealtimeModel.value.power.toString(), energy: chargerController.chargerRealtimeModel.value.energy.toString(), current: chargerController.chargerRealtimeModel.value.currentL1.toString(),engineername: engineer_name,dateTime: DateTime.now().toIso8601String());
    setState(() {
      testingStatus = true;
    });
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
    setState(() {
      chargerController.currentChargerStatus;
    });
    if (_isTimerStopped == false) {
      startCountdown(); // Start countdown after function execution
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: AppBar(
            title: Text("Bluetooth Testing"),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ElevatedButton(
              //         onPressed: () async {
              //          await controller.disconnectCharger();
              //           Get.back();
              //         },
              //         child: const Text("Disconnect Charger"),
              //       ),
              Text("Charger ID : ${widget.chargerId}"),
              Text(
                  "Charger Status : ${chargerController1.currentChargerStatus.toString().split(".")[1]}"),
              chargerController1.currentChargerStatus.toString().split(".")[1]=="UNAVAILABLE" ?    Text("Kindly put charger into available mode"):chargerController1.currentChargerStatus.toString().split(".")[1]=="AVAILABLE"?Text('Kindly put charger into preparing mode'):Text(''),
              // StreamBuilder(stream: , builder: builder)
              // ElevatedButton(onPressed: remoteStartStop, child: Text("Remote Start/Stop"))
              _isCountingDown
                  ? Text("Count Down Time: $_countdown seconds",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))
                  : ElevatedButton(
                      onPressed: remoteStartStop,
                      child: const Text("Remote Start/Stop"),
                    ),
                   testingStatus?Text("Bluetooth Testing Status : Finish",): Text("Bluetooth Testing Status : In Progress",),
                  //  testingStatus?
                   ElevatedButton(onPressed: (){
Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>WifiTesting(chargerId: widget.chargerId,)));


                   }, child: Text("WIFI Testing"))
                  //  :Container()
            ],
          ),
        ));
  }
}
