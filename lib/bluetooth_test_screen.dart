import 'dart:async';

import 'package:bb_factory_test_app/controller/charger_controller.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/repository/charger_ble_repository.dart';
import 'package:bb_factory_test_app/utils/enums/charger_status.dart';
import 'package:bb_factory_test_app/utils/enums/connection_status.dart';
import 'package:bb_factory_test_app/wifi_credential_screen.dart'; // Import keys
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bb_factory_test_app/models/bluetooth_model_new.dart';
import 'package:bb_factory_test_app/models/wifi_model_new.dart';
import 'package:bb_factory_test_app/utils/enums/store_state.dart';

class BluetoothTest extends StatefulWidget {
  String chargerId = '';
  BluetoothTest({super.key, required this.chargerId});

  @override
  State<BluetoothTest> createState() => _BluetoothTestState();
}

class _BluetoothTestState extends State<BluetoothTest> {
  final chargerController = Get.put(ChargerController());
  final controller = Get.find<Controller>();
  final bleRepository = ChargerBLERepository();
  final testingStatus = false.obs;
  Timer? _btTestTimer;
  int _btCountdown = 150;
  var _isBtCountingDown = false.obs;
  var _isBtTimerStopped = false.obs;
  String btVoltage = 'N/A';
  String btPower = 'N/A';
  String btEnergy = 'N/A';
  String btCurrent = 'N/A';
  final isBtToWifiCountdownRunning = false.obs;
  final btToWifiCountdown = 10.obs;
  Timer? _btToWifiTimer;
  final isWifiConnected = false.obs;
  final isWifiTestingFinished = false.obs;
  Timer? _wifiTestTimer;
  final wifiCountdown = 150.obs;
  final isWifiCountdownRunning = false.obs;
  final isWifiTimerStopped = false.obs;
  bool isWiFiConnecting = false;

  String engineer_name = '';
  final rfidAddStep = 0.obs;
  final isAddingRfid = false.obs;
  final addedRfidList = <String>[].obs;
  Timer? _rfidAddTimer;
  final rfidTestStep = 0.obs;
  final rfidTestResultsMap = <String, Map<String, dynamic>>{}.obs;
  final isRfidTestingFinished = false.obs;
  String rfid1Voltage = 'N/A';
  String rfid1Power = 'N/A';
  String rfid1Energy = 'N/A';
  String rfid1Current = 'N/A';
  String rfid2Voltage = 'N/A';
  String rfid2Power = 'N/A';
  String rfid2Energy = 'N/A';
  String rfid2Current = 'N/A';
  StreamSubscription<ChargerStatus?>? _statusSubscription;
  void startBtCountdown() {
    setState(() {
      _btCountdown = 150;
      _isBtCountingDown = true.obs;
      _isBtTimerStopped = false.obs;
    });

    _btTestTimer?.cancel();
    _btTestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_btCountdown > 0) {
        setState(() {
          _btCountdown--;
        });
      } else {
        timer.cancel();
        remoteStartStopBtTest();
        setState(() {
          _isBtTimerStopped = true.obs;
          _isBtCountingDown = false.obs;
        });
        print("BT Counting is Down : $_isBtCountingDown");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // controller.connectCharger();
    chargerController.connectionSwitch.value = 1;
    // controller.getStatusNotification();
  }

  remoteStartStopBtTest() async {
    // Renamed
    // SharedPreferences preferences = await SharedPreferences.getInstance(); // Moved engineer name fetch lower

    // Start timer only if not already running/stopped for BT test
    if (!_isBtCountingDown.value && !_isBtTimerStopped.value) {
      startBtCountdown();
    }

    print(
        "BT Test - ChargerStatus 1 : ${chargerController.chargerRealtimeModel.value.chargerStatus}");

    final currentStatus =
        chargerController.chargerRealtimeModel.value.chargerStatus;

    // Ensure we are connected via Bluetooth for this operation
    // if (controller.connectionSwitch.value != 1) {
    //   Fluttertoast.showToast(
    //       msg: "Not connected via Bluetooth for BT Test Start/Stop.");
    //   return;
    // }

    if (currentStatus == ChargerStatus.PREPARING ||
        currentStatus == ChargerStatus.CHARGING ||
        currentStatus == ChargerStatus.FINISHING) {
      print("BT Test - ChargerStatus : $currentStatus");

      if (currentStatus == ChargerStatus.CHARGING) {
        await chargerController.initiateCharge(startStop: "Stop");
        _btTestTimer?.cancel();
        setState(() {
          _isBtCountingDown = false.obs;
          _isBtTimerStopped = true.obs;
        });

        // Refresh status and capture measurements after stopping BT charge
        await controller.getStatusNotification();
        setState(() {
          btVoltage = chargerController.chargerRealtimeModel.value.voltageL1
                  ?.toString() ??
              'N/A';
          btPower =
              chargerController.chargerRealtimeModel.value.power?.toString() ??
                  'N/A';
          btEnergy =
              chargerController.chargerRealtimeModel.value.energy?.toString() ??
                  'N/A';
          btCurrent = chargerController.chargerRealtimeModel.value.currentL1
                  ?.toString() ??
              'N/A';
        });

        print(
            "BT Test - Captured Values: V=$btVoltage, P=$btPower, E=$btEnergy, C=$btCurrent");
        print(
            "BT Test - Charger Stopped, ChargerStatus: ${chargerController.chargerRealtimeModel.value.chargerStatus}");

        // Mark Bluetooth Test as Finished
        testingStatus.value = true;
        // *** Start the countdown to WiFi test ***
        startBtToWifiCountdown();
      } else {
        // PREPARING or FINISHING
        await chargerController.initiateCharge(startStop: "Start");
        // Countdown is started above if needed
      }
    } else if (currentStatus == ChargerStatus.AVAILABLE) {
      Fluttertoast.showToast(
          msg: "BT Test: Kindly attach charging gun to your car ");
    } else if (currentStatus == ChargerStatus.FINISHING) {
      Fluttertoast.showToast(
          msg: "BT Test: Kindly remove the charging gun from your car");
    } else {
      Fluttertoast.showToast(
          msg:
              "BT Test: Charger not in state for Start/Stop (Status: ${currentStatus?.toString().split('.').last ?? 'Unknown'})");
    }
  }

  // --- Post-BT Countdown Logic ---
  void startBtToWifiCountdown() {
    btToWifiCountdown.value = 15; // Reset countdown
    isBtToWifiCountdownRunning.value = true;
    _btToWifiTimer?.cancel(); // Cancel any previous timer

    _btToWifiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (btToWifiCountdown.value > 0) {
        btToWifiCountdown.value--;
      } else {
        timer.cancel();
        isBtToWifiCountdownRunning.value = false;
        // Check if mounted before calling async function, although GetX might handle it
        if (mounted) {
          print("BT->WiFi Countdown finished, initiating WiFi connection...");
          _connectWifiUsingSavedCredentials();
        }
      }
    });
  }

  // Renamed and modified function to use saved credentials
  Future<void> _connectWifiUsingSavedCredentials() async {
    // Show some loading indicator? Maybe update button text?
    // For simplicity, just print for now.
    // controller.state.value = StoreState.LOADING;
    setState(() {
      isWiFiConnecting = true;
    });

    print("Attempting WiFi connection using saved credentials...");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? ssid = prefs.getString(wifiSsidKey);
    final String? password = prefs.getString(wifiPasswordKey);

    if (ssid == null || ssid.isEmpty) {
      Fluttertoast.showToast(
          msg: "Error: Saved WiFi SSID not found. Please restart the app.",
          toastLength: Toast.LENGTH_LONG);
      // Optionally navigate back to credential screen or show error dialog
      return;
    }
    // Password can be null/empty

    // Indicate connection attempt (optional, maybe disable button)
    // _isConnectingWifi.value = true; // Need to re-add if using loading state

    print("Connecting to SSID: $ssid");
    try {
      // Ensure we are connected via BLE if needed for setup calls?
      // Or assume switchConnections handles state correctly.

      // Use saved credentials
      await chargerController.connectToWifiNetwork(
          model: WifiModel(ssid: ssid, rssi: 0),
          ssidPass: password ?? "", // Use empty string if password is null
          context: context);

      await chargerController.switchConnections(
          index: 0, context: context); // Switch to WiFi

      print(
          "Connection Switch Value after switch: ${controller.connectionSwitch.value}");

      if (controller.connectionSwitch.value == 0) {
        Fluttertoast.showToast(msg: "WiFi Connected and Switched Successfully");
        setState(() {
          isWiFiConnecting = false;
        });
        isWifiConnected.value = true;

        // Reset WiFi test state
        isWifiTestingFinished.value = false;
        isWifiCountdownRunning.value = false;
        isWifiTimerStopped.value = false;
        wifiCountdown.value = 150;
        _wifiTestTimer?.cancel();

        // *** Automatically start WiFi test phase ***
        print("Automatically starting WiFi test phase...");
        await remoteStartStopWifiTest(); // Call the test function
      } else {
        Fluttertoast.showToast(
            msg: "Failed to switch connection to WiFi after connecting");
        // Optionally set isWifiConnected back to false?
        // isWifiConnected.value = false;
      }
    } catch (e) {
      print("Error during WiFi connection/switch: $e");
      Fluttertoast.showToast(
          msg: "Error connecting/switching to WiFi: ${e.toString()}");
      // Optionally set isWifiConnected back to false?
      // isWifiConnected.value = false;
    } finally {
      // Reset loading indicator if used
      // _isConnectingWifi.value = false;
    }
    // controller.state.value = StoreState.SUCCESS;
  }

  // ===========================
  // WiFi Test Functions
  // ===========================

  void startWifiTestCountdown() {
    // Added function
    wifiCountdown.value = 150;
    isWifiCountdownRunning.value = true;
    isWifiTimerStopped.value = false; // Reset timer stopped flag

    _wifiTestTimer?.cancel(); // Cancel any existing timer
    _wifiTestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (wifiCountdown.value > 0) {
        wifiCountdown.value--;
      } else {
        timer.cancel();
        // Check if mounted might not be needed if GetX handles controller lifecycle
        remoteStartStopWifiTest(); // Call WiFi stop
        isWifiTimerStopped.value =
            true; // Mark timer as stopped due to completion
        isWifiCountdownRunning.value = false;
        print("WiFi Counting is Down : ${isWifiCountdownRunning.value}");
      }
    });
  }

  remoteStartStopWifiTest() async {
    // Added function, adapted from screen3
    print(
        "WiFi Test - ChargerStatus 1 : ${chargerController.chargerRealtimeModel.value.chargerStatus}");
    print("Connection Switch : ${controller.connectionSwitch.value}");
    final currentStatus =
        chargerController.chargerRealtimeModel.value.chargerStatus;

    // Ensure we are connected via WiFi for this operation
    if (controller.connectionSwitch.value != 0) {
      Fluttertoast.showToast(
          msg: "Not connected via WiFi for WiFi Test Start/Stop.");
      return;
    }

    if (currentStatus == ChargerStatus.PREPARING ||
        currentStatus == ChargerStatus.CHARGING ||
        currentStatus == ChargerStatus.FINISHING) {
      print("WiFi Test - ChargerStatus : ${currentStatus}");

      if (currentStatus == ChargerStatus.CHARGING) {
        await chargerController.initiateCharge(startStop: "Stop");
        _wifiTestTimer?.cancel(); // Ensure timer is cancelled
        isWifiCountdownRunning.value = false;
        isWifiTimerStopped.value = true;
        // Mark WiFi Test as Finished - This allows RFID section to show up
        isWifiTestingFinished.value = true;

        // Switch back to BLE connection needed for adding/testing RFID
        Fluttertoast.showToast(
            msg:
                "WiFi Test complete. Switching back to Bluetooth for RFID testing...");
        await chargerController.switchConnections(index: 1, context: context);
      } else {
        // PREPARING or FINISHING
        await chargerController.initiateCharge(startStop: "Start");
        // Start countdown only if not already stopped and not already counting
        if (!isWifiTimerStopped.value && !isWifiCountdownRunning.value) {
          startWifiTestCountdown();
        }
      }
    } else if (currentStatus == ChargerStatus.AVAILABLE) {
      Fluttertoast.showToast(
          msg: "WiFi Test: Kindly attach charging gun to your car ");
      await controller.getStatusNotification();
    } else if (currentStatus == ChargerStatus.FINISHING) {
      Fluttertoast.showToast(
          msg: "WiFi Test: Kindly remove the charging gun from your car");
      await controller.getStatusNotification();
    } else {
      // UNAVAILABLE or other states
      Fluttertoast.showToast(
          msg:
              "WiFi Test: Charger not ready for remote start/stop. Status: ${currentStatus?.toString().split('.').last ?? 'Unknown'}");
      await controller.getStatusNotification();
    }
  }

  Future<void> _handleAddRfid() async {
    // Ensure we are connected via BLE
    if (chargerController.connectionSwitch.value != 1) {
      Fluttertoast.showToast(
          msg: "Must be connected via Bluetooth to add RFID.");
      return;
    }

    // Check if charger is in AVAILABLE state
    if (chargerController.chargerRealtimeModel.value.chargerStatus !=
        ChargerStatus.AVAILABLE) {
      Fluttertoast.showToast(
          msg:
              "Please ensure the charger is in AVAILABLE state before adding RFID.",
          toastLength: Toast.LENGTH_LONG);
      return;
    }

    isAddingRfid.value = true;
    int cardNum = rfidAddStep.value + 1;
    Fluttertoast.showToast(
        msg: "Tap RFID card $cardNum on charger within 30 seconds.",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 30);

    // Start a timeout timer for the user prompt
    _rfidAddTimer?.cancel();
    _rfidAddTimer = Timer(const Duration(seconds: 31), () {
      if (isAddingRfid.value) {
        // If still waiting after timeout
        isAddingRfid.value = false;
        Fluttertoast.showToast(msg: "RFID add timed out for card $cardNum.");
      }
    });

    try {
      debugPrint(
          "[RFID Add] Calling chargerController.addRfidTag() for card $cardNum");
      // Call the controller function to initiate adding
      // Assuming this function sends the command to the charger
      await chargerController.addRfidTag();
      debugPrint(
          "[RFID Add] chargerController.addRfidTag() finished. Waiting a moment to check list...");

      // Short delay and check list - replacing the long poll
      // A better approach would be for addRfidTag to return success/failure
      await Future.delayed(const Duration(seconds: 3));

      if (!isAddingRfid.value) {
        // Check if timeout already occurred
        debugPrint("[RFID Add] Timeout occurred before list check.");
        return; // Exit if timeout already handled state
      }

      int initialCount =
          addedRfidList.length; // Check against our local list size now
      await chargerController.getRFIDList(); // Refresh controller's list
      int currentControllerListCount = chargerController.rfidList.length;
      debugPrint(
          "[RFID Add] Refreshed list length: $currentControllerListCount, Initial local count: $initialCount");

      // Crude check: See if the controller's list has more items than our local added list
      // This assumes the controller list reflects successfully added cards promptly
      // And that getRFIDList is reliable.
      bool successDetected = false;
      if (currentControllerListCount > initialCount &&
          chargerController.rfidList.isNotEmpty) {
        // Try to find the new ID - might not be the last one if deletions happened elsewhere
        String newRfidId =
            chargerController.rfidList.last.id; // Fallback: assume last
        // More robust: Find ID in controller list not in addedRfidList
        var potentialNew = chargerController.rfidList.firstWhereOrNull(
            (rfidModel) => !addedRfidList.contains(rfidModel.id));
        if (potentialNew != null) {
          newRfidId = potentialNew.id;
          if (!addedRfidList.contains(newRfidId)) {
            // Ensure it's truly new to *this* screen's state
            addedRfidList.add(newRfidId);
            successDetected = true;
          }
        } else if (!addedRfidList.contains(newRfidId)) {
          // Fallback check if using last ID
          addedRfidList.add(newRfidId);
          successDetected = true;
        }
      }

      // Final state update based on detection
      _rfidAddTimer?.cancel();
      isAddingRfid.value = false;

      if (successDetected) {
        Fluttertoast.showToast(msg: "RFID card $cardNum added successfully!");
        rfidAddStep.value++;
        debugPrint("[RFID Add] Success processed.");
      } else {
        Fluttertoast.showToast(
            msg:
                "Failed to confirm RFID card $cardNum addition. Please check list manually.");
        debugPrint("[RFID Add] Failed to detect success after check.");
      }
    } catch (e) {
      debugPrint("[RFID Add] Error caught: ${e.toString()}");
      _rfidAddTimer?.cancel();
      isAddingRfid.value = false;
      Fluttertoast.showToast(msg: "Error adding RFID: ${e.toString()}");
    }
  }

  // Renamed from _startWaitingForRfidTap
  void _handleRfidTapDetection(int cardNumber) {
    // Determine the expected states based on the current step
    ChargerStatus expectedInitialStatus;
    ChargerStatus
        targetStatus1; // First target status (e.g., PREPARING for start, FINISHING for stop)
    ChargerStatus?
        targetStatus2; // Optional second target status (e.g., AVAILABLE after FINISHING for stop)
    String promptAction;

    if (rfidTestStep.value == 0 || rfidTestStep.value == 2) {
      // Waiting for Start tap
      expectedInitialStatus = ChargerStatus.AVAILABLE;
      targetStatus1 = ChargerStatus.PREPARING;
      targetStatus2 = null; // Only one step for start
      promptAction = "start";
    } else if (rfidTestStep.value == 1 || rfidTestStep.value == 3) {
      // Waiting for Stop tap
      expectedInitialStatus =
          ChargerStatus.PREPARING; // Initial state before stop tap
      targetStatus1 =
          ChargerStatus.FINISHING; // First state we expect after stop tap
      targetStatus2 = ChargerStatus
          .AVAILABLE; // Second state we expect (final state for stop)
      promptAction = "stop";
    } else {
      print("RFID Test: Invalid rfidTestStep ${rfidTestStep.value}");
      return; // Invalid state
    }

    Fluttertoast.showToast(
        msg: "Tap RFID Card $cardNumber to $promptAction test.",
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 15);

    if (chargerController.connectionSwitch.value != 1) {
      Fluttertoast.showToast(
          msg: "Must be connected via Bluetooth for RFID test.");
      rfidTestStep.value = (cardNumber == 1) ? 0 : 2;
      return;
    }

    final currentStatusVal =
        chargerController.chargerRealtimeModel.value.chargerStatus;
    if (currentStatusVal != expectedInitialStatus) {
      Fluttertoast.showToast(
          msg:
              "Charger not in $expectedInitialStatus state (current: $currentStatusVal). Please ensure charger is ready for card $cardNumber $promptAction tap.",
          toastLength: Toast.LENGTH_LONG);
      return;
    }

    _statusSubscription?.cancel();
    bool waitingForSecondStageOfStop =
        false; // Flag for the PREPARING -> FINISHING -> AVAILABLE sequence

    _statusSubscription = chargerController.chargerRealtimeModel
        .map((model) => model?.chargerStatus)
        .distinct()
        .listen((status) async {
      print(
          "RFID Test - Card $cardNumber ($promptAction) - Step: ${rfidTestStep.value}: Detected Status: $status. Expecting $targetStatus1 then $targetStatus2. Waiting for second stage: $waitingForSecondStageOfStop");

      if (!waitingForSecondStageOfStop && status == targetStatus1) {
        print(
            "RFID Card $cardNumber ($promptAction): Stage 1 detected ($expectedInitialStatus -> $targetStatus1).");

        if (promptAction == "start") {
          // Start action (AVAILABLE -> PREPARING)
          _statusSubscription?.cancel();
          if (rfidTestStep.value == 0) {
            // Card 1 Start
            rfidTestStep.value = 1;
            _handleRfidTapDetection(1);
          } else if (rfidTestStep.value == 2) {
            // Card 2 Start
            rfidTestStep.value = 3;
            _handleRfidTapDetection(2);
          }
        } else if (promptAction == "stop") {
          // Stop action, first part (PREPARING -> FINISHING)
          print(
              "RFID Card $cardNumber ($promptAction): Now waiting for AVAILABLE state (targetStatus2: $targetStatus2).");
          waitingForSecondStageOfStop = true; // Now wait for AVAILABLE
          // We don't cancel the subscription yet, we continue listening for targetStatus2
        }
      } else if (waitingForSecondStageOfStop &&
          status == targetStatus2 &&
          promptAction == "stop") {
        // Stop action, second part (FINISHING -> AVAILABLE)
        print(
            "RFID Card $cardNumber ($promptAction): Stage 2 detected (FINISHING -> $targetStatus2).");
        _statusSubscription?.cancel();

        print(
            "RFID Card $cardNumber ($promptAction): Waiting 3 seconds for charger to stabilize to AVAILABLE...");
        await Future.delayed(const Duration(seconds: 3));
        print(
            "RFID Card $cardNumber ($promptAction): Wait finished. Current status: ${chargerController.chargerRealtimeModel.value.chargerStatus}");

        if (rfidTestStep.value == 1) {
          // Card 1 Stop sequence complete
          rfidTestResultsMap['RFID Card 1'] = {
            'status': 'PASS',
            'remarks':
                'Start/Stop sequence (PREPARING->FINISHING->AVAILABLE) detected.'
          };
          rfidTestStep.value = 2;
          _handleRfidTapDetection(2);
        } else if (rfidTestStep.value == 3) {
          // Card 2 Stop sequence complete
          rfidTestResultsMap['RFID Card 2'] = {
            'status': 'PASS',
            'remarks':
                'Start/Stop sequence (PREPARING->FINISHING->AVAILABLE) detected.'
          };
          rfidTestStep.value = 4;
          isRfidTestingFinished.value = true;
          await _generateFinalPdf();
        }
      } else if (status != expectedInitialStatus &&
          status != targetStatus1 &&
          (!waitingForSecondStageOfStop || status != targetStatus2)) {
        // This condition catches unexpected status changes that deviate from the expected flow.
        // It checks if the status is not the initial one we started from,
        // not the first target we were aiming for,
        // and if we are in the second stage of stop, it's not the second target either.
        print(
            "RFID Test - Card $cardNumber ($promptAction) - Step: ${rfidTestStep.value}: Unexpected status change to $status detected.");
        Fluttertoast.showToast(
            msg:
                "RFID Test Card $cardNumber: Unexpected status ($status). Please reset charger state and retry.",
            toastLength: Toast.LENGTH_LONG);
        _statusSubscription?.cancel();
      }
    });
  }

  // This function's role is significantly reduced.
  // It's no longer stopping a timed charge.
  // It might be removed entirely if no UI element calls it.
  Future<void> remoteStartStopRfidTest() async {
    print(
        "remoteStartStopRfidTest called, but its primary function (stopping timed charge) is removed.");
    // Ensure we are connected via BLE (still good practice if any BLE command were to be sent)
    if (controller.connectionSwitch.value != 1) {
      Fluttertoast.showToast(
          msg: "Ensure BLE connection for any RFID operations.");
      // await chargerController.switchConnections(index: 1, context: context);
      // await Future.delayed(Duration(seconds: 2));
      // if (controller.connectionSwitch.value != 1 || !controller.isChargerConnected) {
      //   Fluttertoast.showToast(msg: "Failed to switch to BLE.");
      //   return;
      // }
      return;
    }

    // The original logic for stopping charge and capturing detailed measurements is removed
    // as the test now passes on status change from AVAILABLE to PREPARING.

    // If this function were to handle a manual "fail" or "skip" for a card test:
    // int currentCard = (rfidTestStep.value == 0 || rfidTestStep.value == 1) ? 1 : 2;
    // print("Manually stopping/failing test for RFID Card $currentCard.");
    // _statusSubscription?.cancel();

    // if (rfidTestStep.value == 0 || rfidTestStep.value == 1) { // Affecting Card 1
    //   rfidTestResultsMap['RFID Card 1'] = {
    //     'status': 'FAIL',
    //     'remarks': 'Test manually stopped or failed.'
    //   };
    //   rfidTestStep.value = 2;
    //   _startWaitingForRfidTap(2);
    // } else if (rfidTestStep.value == 2 || rfidTestStep.value == 3) { // Affecting Card 2
    //   rfidTestResultsMap['RFID Card 2'] = {
    //     'status': 'FAIL',
    //     'remarks': 'Test manually stopped or failed.'
    //   };
    //   rfidTestStep.value = 4;
    //   isRfidTestingFinished.value = true;
    //   await _generateFinalPdf();
    // }
  }

  // Helper to generate PDF at the end
  Future<void> _generateFinalPdf() async {
    print("Generating final PDF report...");
    SharedPreferences preferences = await SharedPreferences.getInstance();
    engineer_name = preferences.getString('engineer_name') ?? 'N/A';

    // Get Firmware and Charger Type for PDF
    final firmwareVersion =
        chargerController.chargerModel.value.firmware ?? 'N/A';
    final String chargerType = (() {
      final firmware = firmwareVersion;
      if (firmware.startsWith("v4.0") || firmware.startsWith("v5.0")) {
        return "Jolt Business";
      } else if (firmware.startsWith("BBJLv1.")) {
        return "Jolt Home";
      } else if (firmware.startsWith("v4.1") || firmware.startsWith("v5.1")) {
        return "Jolt Home Plus";
      } else {
        return "Unknown (${firmware.isNotEmpty ? firmware : 'N/A'})";
      }
    })();

    try {
      await controller.generateTestPdf(
        chargerId: widget.chargerId,
        // BT Values
        btVoltage: btVoltage, btPower: btPower, btEnergy: btEnergy,
        btCurrent: btCurrent,
        // WiFi Values
        wifiVoltage: chargerController.chargerRealtimeModel.value.voltageL1
                ?.toString() ??
            'N/A', // Recapture WiFi final state
        wifiPower:
            chargerController.chargerRealtimeModel.value.power?.toString() ??
                'N/A',
        wifiEnergy:
            chargerController.chargerRealtimeModel.value.energy?.toString() ??
                'N/A',
        wifiCurrent: chargerController.chargerRealtimeModel.value.currentL1
                ?.toString() ??
            'N/A',
        // RFID Values - RESTORED (passing N/A)
        rfid1Voltage: rfid1Voltage,
        rfid1Power: rfid1Power,
        rfid1Energy: rfid1Energy,
        rfid1Current: rfid1Current,
        rfid2Voltage: rfid2Voltage,
        rfid2Power: rfid2Power,
        rfid2Energy: rfid2Energy,
        rfid2Current: rfid2Current,
        // Other details
        firmwareVersion: firmwareVersion,
        chargerType: chargerType,
        engineername: engineer_name,
        dateTime: DateTime.now().toIso8601String(),
        // Test Times
        bluetoothTestTime:
            "${_btCountdown > 0 ? (150 - _btCountdown) : 150} seconds",
        wifiTestTime:
            "${wifiCountdown.value > 0 ? (150 - wifiCountdown.value) : 150} seconds",
        // RFID Test Times - RESTORED (passing N/A)
        rfidTestTime1: "N/A",
        rfidTestTime2: "N/A",
        // Results Maps - REMOVING bluetoothTestResults and wifiTestResults
        // bluetoothTestResults:
        //     rfidTestResultsMap.value, // Placeholder - use actual BT results map
        // wifiTestResults: rfidTestResultsMap
        //     .value, // Placeholder - use actual WiFi results map
        rfidTestResults: rfidTestResultsMap.value,
      );
      Fluttertoast.showToast(msg: "Final Test PDF Generated Successfully");
    } catch (e) {
      print("Error generating final PDF: $e");
      Fluttertoast.showToast(
          msg: "Error generating final Test PDF: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _btTestTimer?.cancel();
    _wifiTestTimer?.cancel();
    _btToWifiTimer?.cancel();
    _rfidAddTimer?.cancel(); // Cancel RFID add timer
    // _rfidTestTimer?.cancel(); // REMOVED RFID test timer
    _statusSubscription?.cancel(); // Cancel status listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Obx(() => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text("Charger Test: ${widget.chargerId}"),
              actions: [
                Obx(() {
                  final isBleConnected = controller.isChargerConnected &&
                      chargerController.connectionSwitch.value == 1;
                  return IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Disconnect Bluetooth',
                    onPressed: isBleConnected
                        ? () async {
                            Get.dialog(AlertDialog(
                              title: const Text('Disconnect?'),
                              content: const Text(
                                  'Are you sure you want to disconnect from the charger via Bluetooth?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Get.back(); // Close dialog first
                                    await controller.disconnectCharger();
                                    if (context.mounted) {
                                      Get.back(); // Pop screen after disconnect
                                    }
                                  },
                                  child: const Text('Disconnect',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ));
                          }
                        : null,
                    color: isBleConnected ? null : Colors.grey,
                  );
                }),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Charger Information",
                              style: textTheme.titleLarge),
                          const SizedBox(height: 12),
                          _buildInfoTile(Icons.perm_identity, "Charger ID",
                              widget.chargerId),
                          _buildInfoTile(
                              Icons.developer_board,
                              "Firmware Version",
                              chargerController.chargerModel.value.firmware ??
                                  'N/A'),
                          _buildInfoTile(Icons.memory, "Charger Type",
                              _getChargerTypeString()),
                          const Divider(height: 20),
                          Obx(() => _buildStatusTile(
                              "Charger Status",
                              chargerController
                                  .chargerRealtimeModel.value.chargerStatus,
                              // Convert ErrorCodes enum to string or use a default
                              chargerController.chargerRealtimeModel.value.error
                                      ?.toString()
                                      .split('.')
                                      .last ??
                                  'NONE')),
                          const SizedBox(height: 5),
                          Obx(() => _buildConnectionStatusTile()),
                        ],
                      ),
                    ),
                  ),
                  // Only show test cards if NOT Jolt Business
                  if (_getChargerTypeString() != "Jolt Business") ...[
                    _buildBluetoothTestCard(context),
                    Obx(() {
                      if (isBtToWifiCountdownRunning.value) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20.0, horizontal: 16.0),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: (15 - btToWifiCountdown.value) / 15.0,
                                minHeight: 6,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Switching to WiFi in ${btToWifiCountdown.value}s...",
                                style: textTheme.titleMedium
                                    ?.copyWith(color: colorScheme.primary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      } else if (testingStatus.value &&
                          !isWifiConnected.value) {
                        return const SizedBox(height: 20);
                      } else {
                        return const SizedBox.shrink();
                      }
                    }),
                    Obx(() => isWifiConnected.value
                        ? _buildWifiTestCard(context)
                        : const SizedBox.shrink()),
                    Obx(() =>
                        isWifiTestingFinished.value && rfidAddStep.value < 2
                            ? _buildRfidAddCard(context)
                            : const SizedBox.shrink()),
                    Obx(() =>
                        rfidAddStep.value == 2 && !isRfidTestingFinished.value
                            ? _buildRfidTestCard(context)
                            : const SizedBox.shrink()),
                  ],
                  // Add specific tests for Jolt Business here
                  if (_getChargerTypeString() == "Jolt Business") ...[
                    FutureBuilder<void>(
                      future: _configureWifiForBusiness(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                              'Error configuring WiFi: ${snapshot.error}');
                        } else {
                          // Check the boolean result from _configureWifiForBusiness
                          final bool? configSuccess = snapshot.data as bool?;
                          if (configSuccess == true) {
                            // Call softReset() if WiFi configuration was accepted
                            // chargerController.resetCharger(type: "Wifi");
                            return const Text(
                                'WiFi Configuration Accepted. Performing Soft Reset...');
                          } else if (configSuccess == false) {
                            return const Text('WiFi Configuration Rejected.');
                          } else {
                            return const Text(
                                'WiFi Configuration Attempted.'); // Handle null case
                          }
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          )),
    );
  }

  String _getChargerTypeString() {
    final firmware = chargerController.chargerModel.value.firmware ?? '';
    if (firmware.startsWith("4.0") || firmware.startsWith("5.0")) {
      return "Jolt Business";
    } else if (firmware.startsWith("BBJLv1.")) {
      return "Jolt Home";
    } else if (firmware.startsWith("4.1") || firmware.startsWith("5.1")) {
      return "Jolt Home Plus";
    } else {
      return "Unknown (${firmware.isNotEmpty ? firmware : 'N/A'})";
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text("$label: ",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(
      String label, ChargerStatus? status, String? errorCode) {
    IconData statusIcon;
    Color statusColor;
    String statusText = status?.toString().split(".").last ?? 'UNKNOWN';
    String detailText = "";

    switch (status) {
      case ChargerStatus.AVAILABLE:
        statusIcon = Icons.power_outlined;
        statusColor = Colors.blue;
        detailText = "Ready. Attach charging gun.";
        break;
      case ChargerStatus.PREPARING:
        statusIcon = Icons.hourglass_top_rounded;
        statusColor = Colors.orange;
        detailText = "Preparing charge...";
        break;
      case ChargerStatus.CHARGING:
        statusIcon = Icons.bolt;
        statusColor = Colors.green;
        detailText = "Charging active.";
        break;
      case ChargerStatus.FINISHING:
        statusIcon = Icons.hourglass_bottom_rounded;
        statusColor = Colors.lightBlue;
        detailText = "Finishing charge...";
        break;
      case ChargerStatus.SUSPENDED_EV:
      case ChargerStatus.SUSPENDED_EVSE:
        statusIcon = Icons.pause_circle_outline;
        statusColor = Colors.grey;
        detailText = "Charging suspended.";
        break;
      case ChargerStatus.ERROR:
        statusIcon = Icons.error_outline;
        statusColor = Colors.red;
        statusText = "ERROR";
        detailText = "Error Code: ${errorCode ?? 'N/A'}";
        break;
      case ChargerStatus.UNAVAILABLE:
      default:
        statusIcon = Icons.power_off_outlined;
        statusColor = Colors.redAccent;
        statusText = "UNAVAILABLE";
        detailText = "Charger offline or booting.";
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 12),
          Text("$label: ",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: statusColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
                if (detailText.isNotEmpty)
                  Text(
                    detailText,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.end,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusTile() {
    final isWifi = chargerController.connectionSwitch.value == 0;
    final connStatus = chargerController.connectionStatus.value;
    final statusText = connStatus.toString().split('.').last;
    final isConnected = connStatus == ConnectionStatus.ONLINE;

    IconData methodIcon = isWifi ? Icons.wifi : Icons.bluetooth;
    Color statusColor = isConnected ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(methodIcon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text("Connection: ",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isWiFiConnecting)
                  const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                if (isWiFiConnecting) const SizedBox(width: 8),
                Text(
                  isWiFiConnecting
                      ? "Connecting..."
                      : "${isWifi ? 'WiFi' : 'BLE'} - $statusText",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isWiFiConnecting ? Colors.orange : statusColor,
                      fontWeight: isConnected || isWiFiConnecting
                          ? FontWeight.bold
                          : FontWeight.normal),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTestCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isCharging =
        chargerController.chargerRealtimeModel.value.chargerStatus ==
            ChargerStatus.CHARGING;
    final bool canStartStop = chargerController.connectionSwitch.value == 1 &&
        (chargerController.chargerRealtimeModel.value.chargerStatus ==
                ChargerStatus.PREPARING ||
            chargerController.chargerRealtimeModel.value.chargerStatus ==
                ChargerStatus.CHARGING ||
            chargerController.chargerRealtimeModel.value.chargerStatus ==
                ChargerStatus.FINISHING);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Bluetooth Test",
                style:
                    textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
            const SizedBox(height: 16),
            Center(
              child: Obx(() {
                if (_isBtCountingDown.value) {
                  return Column(
                    children: [
                      CircularProgressIndicator(
                        value: (150 - _btCountdown) / 150.0,
                        strokeWidth: 6,
                      ),
                      const SizedBox(height: 10),
                      Text("BT Charge Timer: ${_btCountdown}s",
                          style: textTheme.titleMedium),
                    ],
                  );
                } else {
                  return ElevatedButton.icon(
                    icon: Icon(isCharging
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline),
                    label:
                        Text(isCharging ? "BT Remote Stop" : "BT Remote Start"),
                    onPressed: canStartStop ? remoteStartStopBtTest : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isCharging
                            ? colorScheme.error
                            : colorScheme.primary,
                        foregroundColor: colorScheme.onError,
                        minimumSize: const Size(200, 45),
                        textStyle: textTheme.labelLarge,
                        disabledBackgroundColor: Colors.grey[300]),
                  );
                }
              }),
            ),
            const SizedBox(height: 16),
            Obx(() =>
                _buildTestStatusIndicator(testingStatus.value, "Bluetooth")),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiTestCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isCharging =
        chargerController.chargerRealtimeModel.value.chargerStatus ==
            ChargerStatus.CHARGING;
    final bool canStop =
        isCharging && chargerController.connectionSwitch.value == 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. WiFi Test",
                style: textTheme.titleLarge
                    ?.copyWith(color: colorScheme.secondary)),
            const SizedBox(height: 16),
            Center(
              child: Obx(() {
                if (isWifiCountdownRunning.value) {
                  return Column(
                    children: [
                      CircularProgressIndicator(
                        value: (20 - wifiCountdown.value) / 20.0,
                        strokeWidth: 6,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(height: 10),
                      Text("WiFi Charge Timer: ${wifiCountdown.value}s",
                          style: textTheme.titleMedium),
                    ],
                  );
                } else if (canStop && !isWifiTestingFinished.value) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text("WiFi Remote Stop"),
                    onPressed: remoteStartStopWifiTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      minimumSize: const Size(200, 45),
                      textStyle: textTheme.labelLarge,
                    ),
                  );
                } else {
                  return SizedBox(
                      height: 45,
                      child: Center(
                        child: Text(
                          isWifiTestingFinished.value
                              ? "Test Complete"
                              : "Waiting for charger...",
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ));
                }
              }),
            ),
            const SizedBox(height: 16),
            Obx(() =>
                _buildTestStatusIndicator(isWifiTestingFinished.value, "WiFi")),
          ],
        ),
      ),
    );
  }

  Widget _buildRfidAddCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("3. Add RFID Cards",
                style:
                    textTheme.titleLarge?.copyWith(color: Colors.orange[800])),
            const SizedBox(height: 16),
            if (isAddingRfid.value)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(width: 15),
                    Text(
                        "Tap RFID Card ${rfidAddStep.value + 1} within 30s... ",
                        style: textTheme.titleMedium
                            ?.copyWith(color: Colors.orange[800])),
                  ],
                ),
              ),
            if (!isAddingRfid.value)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_card),
                  label: Text("Add RFID Card ${rfidAddStep.value + 1}"),
                  onPressed: _handleAddRfid,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 45),
                    textStyle: textTheme.labelLarge,
                  ),
                ),
              ),
            if (addedRfidList.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text("Added RFIDs:",
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: addedRfidList
                        .map((id) => Chip(
                              avatar: Icon(Icons.credit_card,
                                  color: Colors.grey[700]),
                              label: Text(id),
                              backgroundColor: Colors.grey[200],
                            ))
                        .toList(),
                  )),
            ],
            if (rfidAddStep.value == 2 && !isAddingRfid.value) ...[
              const SizedBox(height: 10),
              Center(
                child: Text("RFID Card Adding Complete.",
                    style: textTheme.bodyMedium?.copyWith(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRfidTestCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("4. RFID Test",
                style:
                    textTheme.titleLarge?.copyWith(color: Colors.purple[700])),
            const SizedBox(height: 20),
            Center(
              child: Obx(() {
                String promptText = "";
                Color promptColor = Colors.blue;
                IconData? promptIcon = Icons.touch_app_outlined;
                bool showProgress = false;

                if (rfidTestStep.value == 0) {
                  promptText = "Tap RFID Card 1 to START test";
                } else if (rfidTestStep.value == 1) {
                  promptText = "Tap RFID Card 1 AGAIN to STOP test";
                } else if (rfidTestStep.value == 2) {
                  promptText = "Tap RFID Card 2 to START test";
                } else if (rfidTestStep.value == 3) {
                  promptText = "Tap RFID Card 2 AGAIN to STOP test";
                } else if (rfidTestStep.value >= 4) {
                  promptText = "RFID Testing Finished";
                  promptColor = Colors.green;
                  promptIcon = Icons.check_circle_outline;
                } else {
                  promptText = "RFID Test: Unknown State";
                  promptColor = Colors.grey;
                  promptIcon = Icons.help_outline;
                }

                if (rfidTestStep.value == 0 ||
                    rfidTestStep.value == 1 ||
                    rfidTestStep.value == 2 ||
                    rfidTestStep.value == 3) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if ((rfidTestStep.value == 0 ||
                            rfidTestStep.value == 1 ||
                            rfidTestStep.value == 2 ||
                            rfidTestStep.value == 3) &&
                        _statusSubscription == null) {
                      final currentStatus = chargerController
                          .chargerRealtimeModel.value.chargerStatus;
                      final expectedInitialStatus =
                          (rfidTestStep.value == 0 || rfidTestStep.value == 2)
                              ? ChargerStatus.AVAILABLE
                              : ChargerStatus.PREPARING;
                      if (currentStatus == expectedInitialStatus) {
                        _handleRfidTapDetection(
                            (rfidTestStep.value == 0 || rfidTestStep.value == 1)
                                ? 1
                                : 2);
                      } else {
                        // Prompt user to fix state if needed - message now shown in handler
                      }
                    }
                  });
                  showProgress = _statusSubscription != null;
                }

                return Column(
                  children: [
                    if (promptIcon != null)
                      Icon(promptIcon, size: 40, color: promptColor),
                    if (promptIcon != null) const SizedBox(height: 10),
                    Text(promptText,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: promptColor)),
                    if (showProgress) const SizedBox(height: 15),
                    if (showProgress)
                      const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Obx(() => _buildTestStatusIndicator(
                isRfidTestingFinished.value, "RFID",
                baseColor: Colors.purple)),
            Obx(() => isRfidTestingFinished.value
                ? Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: Text("Final Test PDF Generated.",
                          style: TextStyle(color: Colors.purple)),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildTestStatusIndicator(bool isFinished, String testName,
      {Color? baseColor}) {
    final textTheme = Theme.of(context).textTheme;
    final icon = isFinished ? Icons.check_circle : Icons.hourglass_empty;
    final color = isFinished ? Colors.green : (baseColor ?? Colors.grey[600]);
    final statusText =
        isFinished ? "$testName Test: Finished" : "$testName Test: In Progress";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // New function to handle WiFi configuration for Jolt Business
  Future<bool?> _configureWifiForBusiness() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? ssid = prefs.getString(wifiSsidKey);
    final String? password = prefs.getString(wifiPasswordKey);

    if (ssid == null || ssid.isEmpty) {
      Fluttertoast.showToast(
          msg:
              "Error: Saved WiFi SSID not found. Cannot configure WiFi for Jolt Business.",
          toastLength: Toast.LENGTH_LONG);
      return false; // Return false if credentials not found
    }

    // Call the new method in Controller to change wifi details
    final bool? configAccepted = await controller.changeWifiDetailsInRepo(
      username: ssid,
      password: password ?? "",
    );

    // The changeWifiDetailsInRepo function already shows a toast message
    // based on the response, so no extra toast here.

    return configAccepted; // Return the result of the configuration attempt
  }
}
