import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

typedef ValidatorCallBack = String? Function(String?)?;
typedef OnChangeCallBack = void Function(String)?;

class Constants {
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
