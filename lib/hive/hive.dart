import 'dart:collection';

import 'package:bb_factory_test_app/hive/enums/hive_key_enum.dart';
import 'package:bb_factory_test_app/hive/models/rfid_hive_model.dart';
import 'package:bb_factory_test_app/hive/models/schedule_hive_model.dart';
import 'package:bb_factory_test_app/hive/models/transaction_hive_model.dart';
import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveBox {
  static const String hiveBox = 'brightBluBox';
  static const String transactionListKey = 'transactionBoxList';
  static const String scheduleKey = 'schedules';
  static const String energyConsumed = 'energyConsumed';
  static const String lastTransaction = 'lastTransaction';
  static const String rfid = 'rfid';
  static const String chargerNicknames = 'chargerNicknames';
  static const String chargerList = 'chargerList';

  Future<void> init() async {
    try {
      final appDocumentDirectory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);
      Hive
        ..registerAdapter(TransactionHiveModelAdapter())
        ..registerAdapter(ScheduleHiveModelAdapter())
        ..registerAdapter(RfidHiveModelAdapter());

      await Hive.openBox('brightBluBox');
      // transactionBoxList =
      //     await Hive.openBox<List<TransactionHiveModel>>(transactionBox);
    } catch (e) {
      debugPrint("----- hive init error ---- ${e.toString()}");
    }
  }

  _printListData(
      {required List<ScheduleHiveModel> printList, required bool isWrite}) {
    for (final model in printList) {
      debugPrint(
          "---- ${(isWrite) ? "Hive write" : "Hive delete"} ----- ${model.toMap()}");
    }
  }

  /// A function to write in the HIVEDB depending upon [HiveKey]
  Future<void> writeToDB({
    dynamic data,
    required HiveKey key,
    String? chargerId,
  }) async {
    final box = await Hive.openBox(chargerId ?? hiveBox);
    await box
        .put(key.getHiveKeys(), data)
        .then((value) => debugPrint("----- write to hive successful ----"));
    await Hive.close();
  }

  // -------------------------------------------------------------- Transactions ---------------------------------------------------------------//
  Future<List<TransactionHiveModel>?> getTransactions(
      {required String chargerId}) async {
    final box = await Hive.openBox(chargerId);
    final list = ((await box.get(transactionListKey) ?? []) as List<dynamic>)
        .cast<TransactionHiveModel>();
    await Hive.close();
    return list;
  }

  Future<void> deleteTransactions({required String chargerId}) async {
    final box = await Hive.openBox(chargerId);
    await box.delete(transactionListKey);
    await Hive.close();
  }

  Future<TransactionHiveModel?> getLastTransaction(
      {required String chargerId}) async {
    final box = await Hive.openBox(chargerId);
    final model = await box.get(lastTransaction);
    if (model != null) {
      return (model as TransactionHiveModel);
    }
    return null;
  }

  // -------------------------------------------------------------- Transactions --------------------------------------------------------------- //

  // -------------------------------------------------------------- Schedule --------------------------------------------------------------------//

  Future<List<ScheduleHiveModel>> getHiveSchedules(
      {required String chargerId}) async {
    final box = await Hive.openBox(chargerId);
    final list =
        (await box.get(scheduleKey, defaultValue: [])) as List<dynamic>;
    debugPrint("---- box list --- ${list.toString()}");
    await Hive.close();
    return list.cast<ScheduleHiveModel>();
  }

  Future<void> deleteAllSchedules({required String chargerId}) async {
    final box = await Hive.openBox(chargerId);
    await box.delete(scheduleKey);
    await Hive.close();
    // _printListData(printList: (await getHiveSchedules()), isWrite: false);
  }

  Future<void> deleteSelectedSchedule({required String chargerId}) async {}

  // -------------------------------------------------------------- Schedule --------------------------------------------------------------------//

  // -------------------------------------------------------------- Lifetime Stats --------------------------------------------------------------------//

  Future<double> getLifeTimeStats({required String chargerId}) async {
    final box = await Hive.openBox(chargerId);
    final list = ((await box.get(energyConsumed) ?? 0.0) as double);
    await Hive.close();
    return list;
  }

  // -------------------------------------------------------------- Lifetime Stats --------------------------------------------------------------------//

  // -------------------------------------------------------------- RFID -----------------------------------------------------------------------------//

  Future<List<RfidHiveModel>> getRfidLists({required String chargerId}) async {
    try {
      final box = await Hive.openBox(chargerId);
      final list = (await box.get(
        rfid,
        defaultValue: [],
      )) as List<dynamic>;
      // final result = HashMap<String, String>.from(list);
      await Hive.close();
      return list.cast<RfidHiveModel>();
    } catch (e) {
      debugPrint("---- hive error getRfidList --- ${e.toString()}");
    }
    return <RfidHiveModel>[];
  }

  // -------------------------------------------------------------- RFID -----------------------------------------------------------------------------//

  Future<HashMap<String, String>> getChargerNicknames() async {
    final box = await Hive.openBox(hiveBox);
    final list = ((await box.get(
      chargerNicknames,
      defaultValue: <String, String>{},
    )) as Map<dynamic, dynamic>);
    final result = HashMap<String, String>.from(list);
    await Hive.close();
    return result;
  }

  Future<HashMap<String, String>> getChargerList() async {
    final box = await Hive.openBox(hiveBox);
    final list = ((await box.get(
      chargerList,
      defaultValue: <String, String>{},
    )) as Map<dynamic, dynamic>);
    final result = HashMap<String, String>.from(list);
    await Hive.close();
    return result;
  }

  Future<bool> deleteBox({String? chargerId}) async {
    try {
      if (chargerId != null) {
        await Hive.deleteBoxFromDisk(chargerId);
      } else {
        await Hive.deleteFromDisk();
      }
      return true;
    } catch (e) {
      debugPrint("----- hive deletion failure ---- ${e.toString()}");
    }
    return false;
  }
}
