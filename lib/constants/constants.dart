import 'package:flutter/material.dart';

InputDecoration textfieldDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(fontSize: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );
}


final RegExp smsRegex =
    RegExp(r'\b(\d{6})\b(?=.*brightblu-jolt-lite\.firebaseapp\.com)');
const String fontFamily = 'Work Sans';
