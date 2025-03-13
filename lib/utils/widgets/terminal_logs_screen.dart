import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/repository/repository.dart';
import 'package:bb_factory_test_app/utils/widgets/app_header.dart';

class TerminalLogScreen extends StatefulWidget {
  @override
  _TerminalLogScreenState createState() => _TerminalLogScreenState();
}

class _TerminalLogScreenState extends State<TerminalLogScreen> {
  final controller = Get.find<Controller>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  List<String> logs = [];
  bool isReceivingLogs = false;
  StreamSubscription<String>? _logSubscription; // Subscription for log stream

  @override
  void initState() {
    super.initState();

    // Listen to BLE logs stream
    _logSubscription = controller.bleLogStream.listen((log) {
      if (mounted) {
        setState(() {
          logs.add(log); // Add new log
          _scrollToBottom(); // Scroll to bottom for new logs
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the subscription to avoid memory leaks
    // _logSubscription?.cancel();
    // _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onStartPressed() async {
    setState(() {
      isReceivingLogs = true;
    });

    // Start logging via controller
    controller.toggleBleLogging(true, controller.bluetoothModel.value);
  }

  Future<void> _onStopPressed() async {
    setState(() {
      isReceivingLogs = false;
    });

    // Stop logging via controller
    controller.toggleBleLogging(false, controller.bluetoothModel.value);
    _logSubscription!.cancel();
    logs.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        appDrawer: false,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Logs Display
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  try {
                    final logEntry = jsonDecode(logs[index]);
                    final dataValue = logEntry['data'];
                    final timeStamp = logEntry['timestamp'].toString();
                    final utcTime = DateTime.parse(timeStamp);
                    final istTime =
                        utcTime.add(const Duration(hours: 5, minutes: 30));
                    final formattedTimeStamp =
                        DateFormat('HH:mm:ss').format(istTime);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 8.0),
                      child: Text(
                        "$formattedTimeStamp :: $dataValue",
                        style: const TextStyle(
                            color: Colors.green, fontFamily: 'Courier'),
                      ),
                    );
                  } catch (_) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                      child: Text(
                        'Invalid log format',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          // Start/Stop Buttons
          // Container(
          //   padding: const EdgeInsets.all(8.0),
          //   color: Colors.black,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       ElevatedButton(
          //         onPressed: isReceivingLogs ? null : _onStartPressed,
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: Colors.green,
          //         ),
          //         child: const Text(
          //           "Start",
          //           style: TextStyle(color: Colors.black),
          //         ),
          //       ),
          //       ElevatedButton(
          //         onPressed: isReceivingLogs ? _onStopPressed : null,
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: Colors.red,
          //         ),
          //         child: const Text(
          //           "Stop",
          //           style: TextStyle(color: Colors.black),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TextField for input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // "Go" Button
                // ElevatedButton(
                //   onPressed: _onGoPressed,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.green,
                //   ),
                //   child: const Text(
                //     "Start",
                //     style: TextStyle(color: Colors.black),
                //   ),
                // ),
                ElevatedButton(
                  onPressed: isReceivingLogs ? null : _onStartPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    "Start",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                // ElevatedButton(
                //   onPressed: _stopPressed,
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.green,
                //   ),
                //   child: const Text(
                //     "Stop",
                //     style: TextStyle(color: Colors.black),
                //   ),
                // ),
                ElevatedButton(
                  onPressed: isReceivingLogs ? _onStopPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    "Stop",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
