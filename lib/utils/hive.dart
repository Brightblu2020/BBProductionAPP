import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class Storage {
  static const String authBox = 'AuthBox';
  Future<void> init() async {
    try {
      debugPrint("---- hive initalized ----");
      final appDocumentDirectory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);
    } catch (e) {
      debugPrint("----- hive intialization error ------ ${e.toString()}");
    }
  }

  Future<void> write({required String data}) async {
    try {
      final box = await Hive.openBox(authBox);
      final key = await read();
      if (key == null || key == "") {
        await box.delete('auth');
      }
      await box.put('auth', data);
      await box.close();
    } catch (e) {
      debugPrint("---- failed to write in hive ----${e.toString()}");
    }
  }

  Future<String?> read() async {
    try {
      final box = await Hive.openBox(authBox);
      return await box.get('auth', defaultValue: "");
    } catch (e) {
      debugPrint("----- failed to get from hive ------- ${e.toString()}");
    }
    return null;
  }
}
