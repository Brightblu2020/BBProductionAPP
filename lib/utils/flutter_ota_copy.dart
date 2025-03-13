import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;

const int mtuOffsetForChunkSize = 3;
const int otaControlRequest = 0x01;
const int otaControlRequestAck = 0x02;
const int otaControlRequestNak = 0x03;
const int otaControlDone = 0x04;
const int otaControlDoneAck = 0x05;
const int otaControlDoneNak = 0x06;
const int otaControlRestart = 0x07;
const int otaControlRestartAck = 0x08;

class Logger {
  static void debug(Object? object) {
    if (kDebugMode) {
      // ignore: avoid_print
      print("$object");
    }
  }

  static void error(Object? object) {
    // ignore: avoid_print
    print('\x1B[31m$object\x1B[0m');
  }
}

Future<Uint8List> firmwareBinaryFromFile(String filePath) async {
  return File(filePath).readAsBytes();
}

Future<Uint8List> firmwareBinaryFromUrl(String url) async {
  try {
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw 'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}';
    }
  } catch (e) {
    // Handle other errors (e.g., timeout, network connectivity issues)
    throw 'Error fetching firmware from URL: $e';
  }
}

Future<Uint8List> firmwareBinaryFromPicker() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['bin'],
  );

  if (result == null || result.files.isEmpty) {
    throw 'Error getting firmware data: No file picked';
  }

  try {
    return firmwareBinaryFromFile(result.files.first.path!);
  } catch (e) {
    throw 'Error getting firmware data: $e';
  }
}

Future<bool> restartEsp32(BluetoothDevice device,
    BluetoothCharacteristic controlCharacteristic) async {
  await controlCharacteristic.write([otaControlRestart]);
  List<int> value =
      await controlCharacteristic.read().timeout(const Duration(seconds: 10));
  Logger.debug('value returned is this ------- $value');
  if (value[0] != otaControlRestartAck) {
    throw 'Restart Command Failed';
  }
  return true;
}

Stream<double> updateEsp32Firmware(
    BluetoothDevice device,
    BluetoothCharacteristic dataCharacteristic,
    BluetoothCharacteristic controlCharacteristic,
    Uint8List firmwareBinary) async* {
  bool updateIsDone = false;
  try {
    int mtuSize = 512;
    int chunkSize = mtuSize - mtuOffsetForChunkSize;

    // Prepare a byte list to write MTU size to controlCharacteristic
    Uint8List byteList = Uint8List(2);
    byteList[0] = chunkSize & 0xFF;
    byteList[1] = (chunkSize >> 8) & 0xFF;
    // write mtuSize to dataCharacteristic
    Logger.debug("Sending chunk size $chunkSize $byteList");
    await dataCharacteristic.write(byteList);

    await dataCharacteristic.write([otaControlRequest]);
    List<int> value =
        await dataCharacteristic.read().timeout(const Duration(seconds: 10));
    Logger.debug('value returned is this ------- ${value[0]}');
    // if (value[0] != otaControlRequestAck) {
    //   throw 'Start Command Failed';
    // }

    int packetNumber = 1;
    int totalPackets = (firmwareBinary.length / chunkSize).ceil();
    for (int i = 0; i < firmwareBinary.length; i += chunkSize) {
      int end = i + chunkSize;
      if (end > firmwareBinary.length) {
        end = firmwareBinary.length;
      }
      final chunk = firmwareBinary.sublist(i, end);
      double progress = (packetNumber / totalPackets);
      String roundedProgressPercentage =
          (progress * 100).toStringAsPrecision(3);
      if (progress >= 1.0) {
        // don't go to 100 until finish command has been acknowledged
        progress = 0.99;
      }
      Logger.debug(
          'Writing packet $packetNumber of $totalPackets ($roundedProgressPercentage%).');

      await dataCharacteristic.write(chunk);

      yield double.parse(roundedProgressPercentage);

      packetNumber++;
    }

    updateIsDone = true;

    await controlCharacteristic.write([otaControlDone]);

    // Check if controlCharacteristic reads 0x05, indicating OTA update finished
    value =
        await controlCharacteristic.read().timeout(const Duration(seconds: 10));
    Logger.debug('value returned is this ------- ${value[0]}');
    if (value[0] == otaControlDoneAck) {
      Logger.debug('OTA update finished');
      yield 1.0;
    } else {
      Logger.debug('OTA update failed');
      throw 'Finish Command Failed';
    }
  } catch (error) {
    Logger.error(error);
    if (updateIsDone && error.toString().contains("disconnected")) {
      yield 1.0;
    } else {
      yield* Stream.error(error);
    }
  }
}
