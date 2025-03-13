import 'dart:convert';

import 'package:bb_factory_test_app/models/transaction_resp_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransactionRepository {
  static const String monthUrl =
      "https://us-central1-brightblu-jolt-lite.cloudfunctions.net/monthSessions";
  // "http://127.0.0.1:5001/brightblu-jolt-lite/us-central1/monthSessions";

  static const String monthEnergyUrl =
      "https://us-central1-brightblu-jolt-lite.cloudfunctions.net/monthEnergy";
  // "http://127.0.0.1:5001/brightblu-jolt-lite/us-central1/monthEnergy";

  static const String weekUrl =
      "https://us-central1-brightblu-jolt-lite.cloudfunctions.net/weekEnergy";
  // "http://127.0.0.1:5001/brightblu-jolt-lite/us-central1/monthEnergy";

  final functions = FirebaseFunctions.instance;
  // ..useFunctionsEmulator("http://127.0.0.1", 5001);

  Future<TransactionRespModel?> getChargingSessions({
    required String chargerId,
    required String date,
    required String type,
    required bool isEnergy,
  }) async {
    try {
      final url = (type == "0")
          ? weekUrl
          : (!isEnergy)
              ? monthEnergyUrl
              : monthUrl;
      debugPrint("------ $chargerId ----- $date ------ $type --------");
      final chargeUrl = "$url?chargerId=$chargerId&date=$date";
      debugPrint("---- charger url $chargeUrl");
      final resp = await http.get(Uri.parse(chargeUrl));
      // final callable = functions.httpsCallableFromUrl(chargeUrl);
      // final resp = await callable();

      // debugPrint("---- resp getChargerSessions --- ${resp.data}");

      final body = jsonDecode(resp.body) as Map<String, dynamic>;

      debugPrint("------ charge sessions ---- $body");

      if (body['output'] == 1) {
        return TransactionRespModel.fromJson(json: body);
      }
    } catch (e) {
      debugPrint("------ getChargingSessions ----- ${e.toString()}");
    }
    return null;
  }
}
