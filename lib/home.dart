import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/main_wifi_screen.dart';
import 'package:bb_factory_test_app/utils/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _engineerNameController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveData() async {
    String engineerName = _engineerNameController.text.trim();
    String dateTime = _dateTimeController.text.trim();
SharedPreferences prefs = await SharedPreferences.getInstance();
    if (engineerName.isNotEmpty && dateTime.isNotEmpty) {
      await _firestore.collection('test_details').add({
        'engineer_name': engineerName,
        'test_date_time': dateTime,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved successfully!')),
      );
      prefs.setString('engineer_name', engineerName);
      prefs.setString('test_date_time', dateTime);
      _engineerNameController.clear();

      _dateTimeController.clear();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainWifiScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final controller = Get.find<Controller>()..bluetoothAdapterState();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _engineerNameController,
              decoration: const InputDecoration(
                labelText: "Name of Engineer",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateTimeController,
              decoration: const InputDecoration(
                labelText: "Date & Time of Test",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveData,
              child: const Text("Save Data"),
            ),
          ],
        ),
      ),
    );
  }
}
