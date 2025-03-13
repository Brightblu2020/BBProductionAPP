import 'package:bb_factory_test_app/utils/enums/connection_status.dart';
import 'package:bb_factory_test_app/models/charger_model_new.dart';
import 'package:bb_factory_test_app/models/schedule_model.dart';
import 'package:bb_factory_test_app/hive/models/transaction_hive_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChargerFirebaseRepository {
  /// Instance for realtime DB
  final realtimeDBIntance = FirebaseDatabase.instance;

  /// Instance of firestore DB
  final firebaseFirestore = FirebaseFirestore.instance;

  /// Instance of firebase storage
  // final firebaseStorage = FirebaseStorage.instance.ref();

  /// Current signed in user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> uploadData({required ChargerModel model}) async {
    await firebaseFirestore.collection("chargers").doc(model.chargerId).set(
          model.toMap(),
        );
    // await realtimeDBIntance.ref('transactions/${model.chargerId}')
  }

  Future<List<ChargerModel>?> getMyChargers({required String userId}) async {
    // final resp = await firebaseFirestore.collection("chargers").where("userId",isEqualTo:  )
    return null;
  }

  Future<void> initiateChargerWifi({
    required ChargerModel model,
    required bool start,
  }) async {
    await realtimeDBIntance
        .ref("chargers/${model.chargerId}/initiateCharge")
        .set((start) ? 1 : 0);
  }

  Future<ConnectionStatus> getChargerConnectionStatus(
      {required String chargerId}) async {
    final value = await realtimeDBIntance
        .ref('/chargers/$chargerId/connectionStatus')
        .get();

    if (value.value == 1) {
      return ConnectionStatus.ONLINE;
    }
    return ConnectionStatus.OFFLINE;
  }

  Future<ScheduleModel?> uploadScheduleData({
    required ScheduleModel model,
    required String chargerId,
  }) async {
    try {
      await firebaseFirestore
          .collection("chargers")
          .doc(chargerId)
          .collection("schedule")
          .add(model.toMap())
          .then((value) => model = model.copyWith(id: value.id));
      return model;
    } on FirebaseException catch (e) {
      debugPrint("----- schedule error ----- ${e.toString()}");
      Fluttertoast.showToast(msg: "Failed to add the schedule");
    }
    return null;
  }

  Future<List<ScheduleModel>> getSchedules({required String chargerId}) async {
    try {
      final list = <ScheduleModel>[];
      final documents = await firebaseFirestore
          .collection("chargers")
          .doc(chargerId)
          .collection("schedule")
          .get();
      for (final doc in documents.docs) {
        list.add(ScheduleModel.fromJson(
          json: doc.data(),
          id: doc.id,
        ));
      }
      return list;
    } catch (e) {
      debugPrint("---- failed to get schedules --- ${e.toString()}");
    }
    return <ScheduleModel>[];
  }

  Future<bool> uploadChargerData({required ChargerModel model}) async {
    debugPrint("--- uploading charger data ----");
    try {
      final updatedModel = model.copyWith(lastUsed: true);
      // for(final model in firebaseFirestore.collection("chargers").where(field))
      await firebaseFirestore
          .collection('chargers')
          .doc(model.chargerId)
          .set(updatedModel.toMap());
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to upload charger data");
      return false;
    }
  }

  Future<ChargerModel?> checkIfChargerExists() async {
    try {
      final resp = await firebaseFirestore
          .collection("chargers")
          .where("userId", isEqualTo: currentUser!.uid)
          .get();
      debugPrint("----- charger exists ---- ${resp.docs}");
      if (resp.docs.isNotEmpty) {
        await realtimeDBIntance
            .ref(
                "chargers/${resp.docs.first.data()['chargerId']}/connectionStatus")
            .set(0);
      }
      for (final charger in resp.docs) {
        final model = ChargerModel.fromFirebase(snapshot: charger);
        if (model.lastUsed!) {
          return model;
        }
      }
      return ChargerModel.fromFirebase(snapshot: resp.docs.first);
    } catch (e) {
      debugPrint(e.toString());
      Fluttertoast.showToast(msg: "Could not find your charger ");
    }
    return null;
  }

  Future<bool?> plugAndPlay({
    required bool result,
    required String chargerId,
  }) async {
    try {
      await realtimeDBIntance
          .ref('chargers/$chargerId/freemode')
          .set((result) ? 1 : 0);

print("Plug & Play response");

      return true;
    } catch (e) {
      print("Exception : $e");
    }
    return null;
  }

  Future<bool?> updateMaxCurrentLimit({
    required int maxCurrentLimit,
    required String chargerId,
  }) async {
    try {
      await realtimeDBIntance
          .ref('chargers/$chargerId/maxCurrentLimit')
          .set(maxCurrentLimit);
      return true;
    } catch (e) {}
    return null;
  }

  Future<dynamic> getChargeFlagAndStart(
      {required String value, required String chargerId}) async {
    final resp =
        await realtimeDBIntance.ref('transactions/$chargerId/$value').get();
    if (resp.value != null) {
      return resp.value as int;
    }
    return null;
  }

  Future<void> setChargeFlagAndStart({
    required String value,
    required String chargerId,
    dynamic result,
  }) async {
    await realtimeDBIntance.ref('transactions/$chargerId/$value').set(result);
  }

  // Future<String?> getChargerFirmwareList() async {
  //   String? result;
  //   try {
  //     final resp = await firebaseStorage.listAll();
  //     int max = 0;

  //     for (final firmware in resp.items) {
  //       final data = await firmware.getMetadata();
  //       if (data.updated!.millisecondsSinceEpoch >= max) {
  //         max = data.updated!.millisecondsSinceEpoch;
  //         result = firmware.name;
  //       }
  //     }
  //   } on FirebaseException catch (e) {
  //     Fluttertoast.showToast(msg: "Fetch update failure. ${e.message}");
  //   }
  //   return result;
  // }

  Future<void> updateChargerStatus({
    required String userId,
    required String chargerId,
  }) async {
    try {
      final resp = await FirebaseFunctions.instance
          .httpsCallable('selectCharger')
          // .httpsCallable("selectCharger")
          .call(<String, dynamic>{
        'userId': userId,
        'chargerId': chargerId,
      });

      debugPrint(
          "--- list of updated charger status chargers ----- ${resp.data}");
    } on FirebaseException catch (e) {
      debugPrint("---- firease expecrption --- ${e.message}");
    }
  }

  Future<List<ChargerModel>> getListChargers({required String userId}) async {
    final list = <ChargerModel>[];
    try {
      final resp = await firebaseFirestore
          .collection("chargers")
          .where("userId", isEqualTo: userId)
          .get();

      debugPrint("list of charger --- ${resp.docs}");
      for (final doc in resp.docs) {
        final model = ChargerModel.fromFirebase(snapshot: doc);
        debugPrint("--- list model ${model.toMap()}");
        list.add(model);
      }
    } catch (e) {}
    return list;
  }

  Future<bool> checkChargerUser({required ChargerModel model}) async {
    try {
      final doc = await firebaseFirestore
          .collection("chargers")
          .doc(model.chargerId)
          .get()
          .catchError(
        (err) {
          debugPrint("---- check charger user error $err");
          // return null;
        },
      );
      debugPrint("--- charger check data ---- ${doc.id}");
      // if (doc.data() == null) {
      //   return true;
      // }
      if (!doc.exists) {
        return true;
      }
      if (doc.exists && doc.data()!['userId'] == null) {
        return true;
      }
      if (doc.exists && (doc.data()!['userId'] != null)) {
        debugPrint(
            "---- model.userId == (doc.data()!['userId'] as String) --- ${model.userId == (doc.data()!['userId'] as String)}");

        return (model.userId == (doc.data()!['userId'] as String));
      }
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: '${e.message}');
    }
    return false;
  }

  Future<void> updateChargerVarFirebaseRTDB({
    required String chargerId,
    required String value,
    dynamic result,
  }) async {
    await realtimeDBIntance.ref('chargers/$chargerId/$value').set(result);
  }

  Future<void> postTransactions(
      {required List<TransactionHiveModel> list,
      required String chargerId}) async {
    try {
      final collectionRef = firebaseFirestore
          .collection("chargers")
          .doc(chargerId)
          .collection('transactions');

      for (final model in list) {
        await collectionRef.doc(model.id.toString()).set(model.toMap());
      }
    } on FirebaseException catch (e) {
      debugPrint("---- post transactions error ----- ${e.toString()}");
    }
  }

  Future<double?> getEnergyConsumed({required String chargerId}) async {
    try {
      final doc =
          await firebaseFirestore.collection("chargers").doc(chargerId).get();
      if (doc.data() != null) {
        debugPrint(
            "------ energy consumed ---- ${doc.data()!} ------- ${doc.data()!['energyConsumed']}}");
        return (double.parse((doc.data()!['energyConsumed']).toString()));
      }
    } catch (e) {
      debugPrint("------ energy consumed from firebase ---- ${e.toString()}");
    }
    return null;
  }

  Future<TransactionHiveModel?> getLastTransaction(
      {required String chargerId}) async {
    try {
      final resp = await firebaseFirestore
          .collection("chargers")
          .doc(chargerId)
          .collection("transactions")
          .orderBy('timeStop', descending: true)
          .limit(1)
          .get();
      debugPrint(
          "---- last transaction firebase ---- ${resp.docs.first.data()}");
      return TransactionHiveModel.fromFirebase(
        data: resp.docs.first.data(),
        id: resp.docs.first.id,
      );
    } catch (e) {
      debugPrint("---- last transaction failure ---- ${e.toString()}");
    }
    return null;
  }

  Future<bool> deleteCharger({required String chargerId}) async {
    try {
      final docInstance =
          firebaseFirestore.collection("chargers").doc(chargerId);

      /// Update the fields
      await docInstance.update({"userId": null, "lastUsed": false});

      return true;
    } catch (e) {
      debugPrint("charger deletion failed");
    }
    return false;
  }
}
