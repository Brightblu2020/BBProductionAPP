import 'dart:async';

import 'package:bb_factory_test_app/controller/charger_controller.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/models/bluetooth_model.dart';
import 'package:bb_factory_test_app/models/wifi_model_new.dart';
import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WifiTesting extends StatefulWidget {
  String chargerId='';
WifiTesting({required this.chargerId});
  @override
  _WifiTestingState createState() => _WifiTestingState();
}

class _WifiTestingState extends State<WifiTesting> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isConnected = false;
  final chargerController = Get.put(ChargerController());
  final chargerController1 = Get.find<ChargerController>();
  Controller _controller = Controller();
    final controller1 = Get.find<Controller>();
  final controller = Get.find<Controller>();
bool testingStatus = false;
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
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Stat : ${controller1.connectionSwitch.value}");
  }
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    Future<void> connectToWifi() async {
      print("${ssidController.text.trim()}");
      print("${passwordController.text.trim()}");
      await chargerController1.connectToWifiNetwork(
          model: WifiModel(ssid: ssidController.text, rssi: 0),
          ssidPass: passwordController.text,
          context: context);
          await chargerController1.switchConnections(index: 0,context: context);
      print(controller1.connectionSwitch.value);
    print("Stat1 : ${chargerController1.connectionSwitch.value}");
if(chargerController1.connectionSwitch.value == 0){
      setState(() {
        isConnected = true;
      });
    // await chargerController1.updatePlugPlay();
    
}


    }

    return Scaffold(
      appBar: AppBar(title: Text("WiFi Testing")),
      body: Center(
        child: isConnected
            ? Column(
              children: [
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
// Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>WifiTesting()));


                   }, child: Text("WIFI Testing"))
              ],
            )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: ssidController,
                      decoration: InputDecoration(
                        labelText: "WiFi SSID",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "WiFi Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: connectToWifi,
                      child: Text("Submit"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
