import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

typedef ValidatorCallBack = String? Function(String?)?;
typedef OnChangeCallBack = void Function(String)?;

class Constants {
// UUIDs for BRIGHTBLU chargers
  static const String SERVICE_UUID_1 = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String CHARACTERISTIC_UUID_RX_1 =
      "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String CHARACTERISTIC_UUID_TX_1 =
      "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

  static const String SERVICE_UUID_2 = "fb1e4001-54ae-4a28-9f74-dfccb248601d";
  static const String CHARACTERISTIC_UUID_RX_2 =
      "fb1e4002-54ae-4a28-9f74-dfccb248601d";
  static const String CHARACTERISTIC_UUID_TX_2 =
      "fb1e4003-54ae-4a28-9f74-dfccb248601d";

  // Charger model identifiers
  static const String JOLT_BUSINESS_PREFIX_1 = "4.0.";
  static const String JOLT_BUSINESS_PREFIX_2 = "5.0.";
  static const String JOLT_HOME_PLUS_PREFIX_1 = "4.1.";
  static const String JOLT_HOME_PLUS_PREFIX_2 = "5.1.";
  static const String JOLT_HOME_PREFIX = "BBJLv1.0.";

  // App version for boot notification
  static const String APP_VERSION = "JOLTINSTALLPARTNER";

  // Charger types
  static const String TYPE_BUSINESS = "JOLT Business";
  static const String TYPE_HOME_PLUS = "JOLT Home Plus";
  static const String TYPE_HOME = "JOLT Home";

  // Phase types
  static const String SINGLE_PHASE = "Single.Phase";
  static const String THREE_PHASE = "Three.Phase";

  // Power ratings
  static const String POWER_7KW = "7kW";
  static const String POWER_22KW = "22kW";

  static const String LOGO = "assets/images/brightblu_logo.svg";

  static num screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static num screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static TextStyle customTextStyle(
      {required double fontSize,
      required FontWeight fontWeight,
      Color? color}) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Work Sans',
    );
  }

  static TextFormField textFormField({
    required TextEditingController controller,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    required String label,
    ValidatorCallBack validator,
    GlobalKey<FormState>? key,
    bool? readOnly,
    OnChangeCallBack? onChanged,
    // String? hint,
  }) {
    return TextFormField(
      controller: controller,
      style: Constants.customTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      readOnly: readOnly ?? false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Constants.customTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: Constants.customTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black38),
        ),
      ),
      onChanged: onChanged ??
          (value) {
            if (key != null) {
              key.currentState!.validate();
            }
          },
      validator: validator,
    );
  }

  static Widget appHeaderImage({
    required double height,
    required double width,
    BoxFit? boxFit,
  }) =>
      Container(
        height: height,
        width: width,
        child: SvgPicture.asset(
          LOGO,
          // height: height,
          // width: width,
          fit: boxFit ?? BoxFit.contain,
        ),
      );
}

extension StringExtensions on String {
  List<String> convertList() => split(":");
  bool getToggleType() {
    if (this == "true") return true;
    return false;
  }

  bool isWss() {
    final index = indexOf(":");
    if (index != -1 && substring(0, index) == "wss") return true;
    return false;
  }

  bool checkWebsocketType({required String selectedType}) {
    final index = indexOf(":");
    if (index != -1 && substring(0, index) == selectedType) return true;
    return false;
  }
}

extension IntegerMod on int {
  String getProgress() {
    if (this == 100) {
      return "Installing firmware";
    } else if (this == 999) {
      return "Downloading firmware";
    } else if (this > 100) {
      return "Firmware installation successful";
    }
    return "Update in progress";
  }
}

extension ToString on bool {
  String convertBool() {
    if (this) return "true";
    return "false";
  }
}
