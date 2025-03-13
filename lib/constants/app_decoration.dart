import 'package:bb_factory_test_app/constants/app_style.dart';
import 'package:bb_factory_test_app/constants/color_constants.dart';
import 'package:bb_factory_test_app/constants/size_config.dart';
import 'package:flutter/material.dart';

typedef ValidatorCallBack = String? Function(String?)?;
typedef OnChangeCallBack = void Function(String)?;
class AppDecoration {
  
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
      style: AppStyle.customTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      readOnly: readOnly ?? false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppStyle.customTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: AppStyle.customTextStyle(
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
  static LinearGradient get commonGradient => LinearGradient(
        begin: const Alignment(
          0.66,
          0.71,
        ),
        end: const Alignment(
          0.07,
          -0.54,
        ),
        colors: [
          ColorConstant.black900,
          ColorConstant.indigoA700D3,
        ],
      );

  static BoxDecoration get fillIndigo900 => BoxDecoration(
        color: ColorConstant.indigo900,
      );
  static BoxDecoration get outlineBlack90033 => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(
            0,
            -0.11,
          ),
          end: const Alignment(
            1.1,
            1.34,
          ),
          colors: [
            ColorConstant.cyanA400,
            ColorConstant.blueA200,
            ColorConstant.blueA700,
          ],
        ),
      );
  static BoxDecoration get outlineBlack90026014 => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(
            -0.02,
            -0.07,
          ),
          end: const Alignment(
            1,
            1.12,
          ),
          colors: [
            ColorConstant.greenA400,
            ColorConstant.cyan700,
          ],
        ),
      );
  static BoxDecoration get outlineIndigo900 => BoxDecoration(
        border: Border.all(
          color: ColorConstant.indigo900,
          width: getHorizontalSize(
            1,
          ),
        ),
      );
  static BoxDecoration get outlineBlack90026012 => BoxDecoration(
        color: ColorConstant.whiteA700,
        boxShadow: [
          BoxShadow(
            color: ColorConstant.black9002601,
            spreadRadius: getHorizontalSize(
              2,
            ),
            blurRadius: getHorizontalSize(
              2,
            ),
            offset: const Offset(
              -4,
              4,
            ),
          ),
        ],
      );
  static BoxDecoration get outline => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(
            -0.03,
            1.27,
          ),
          end: const Alignment(
            1.07,
            -0.87,
          ),
          colors: [
            ColorConstant.blueGray900,
            ColorConstant.blue800,
          ],
        ),
      );
  static BoxDecoration get outlineBlack90026013 => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstant.blueGray900,
            ColorConstant.indigo900,
          ],
        ),
      );
  static BoxDecoration get gradientBlack9003fIndigoA7003f => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(
            0.7,
            0.7,
          ),
          end: const Alignment(
            0.07,
            -0.54,
          ),
          colors: [
            ColorConstant.black9003f,
            ColorConstant.indigoA7003f,
          ],
        ),
      );
  static BoxDecoration get fillWhiteA700 => BoxDecoration(
        color: ColorConstant.whiteA700,
      );
  static BoxDecoration get outlineBlack90026011 => BoxDecoration(
        color: ColorConstant.whiteA700,
        boxShadow: [
          BoxShadow(
            color: ColorConstant.black9002601,
            spreadRadius: getHorizontalSize(
              2,
            ),
            blurRadius: getHorizontalSize(
              2,
            ),
            offset: const Offset(
              -2,
              -2,
            ),
          ),
        ],
      );
  static BoxDecoration get fillIndigo90001 => BoxDecoration(
        color: ColorConstant.indigo90001,
      );
  static BoxDecoration get outlineBlack9002601 => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(
            0.66,
            0.71,
          ),
          end: const Alignment(
            0.07,
            -0.54,
          ),
          colors: [
            ColorConstant.black900,
            ColorConstant.indigoA700D3,
          ],
        ),
      );
  static BoxDecoration get outlineBlack9003f => BoxDecoration(
        color: ColorConstant.whiteA700,
        boxShadow: [
          BoxShadow(
            color: ColorConstant.black9003f,
            spreadRadius: getHorizontalSize(
              2,
            ),
            blurRadius: getHorizontalSize(
              2,
            ),
            offset: const Offset(
              -4,
              4,
            ),
          ),
        ],
      );
  static BoxDecoration get outlineBlack9003f1 => BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(
            0.13,
            0,
          ),
          end: const Alignment(
            1.02,
            1.4,
          ),
          colors: [
            ColorConstant.gray90001,
            ColorConstant.indigo900,
          ],
        ),
      );
}

class BorderRadiusStyle {
  static BorderRadius circleBorder34 = BorderRadius.circular(
    getHorizontalSize(
      34,
    ),
  );

  static BorderRadius circleBorder24 = BorderRadius.circular(
    getHorizontalSize(
      24,
    ),
  );

  static BorderRadius roundedBorder15 = BorderRadius.circular(
    getHorizontalSize(
      15,
    ),
  );

  static BorderRadius roundedBorder12 = BorderRadius.circular(
    getHorizontalSize(
      12,
    ),
  );

  static BorderRadius customBorderTL65 = BorderRadius.only(
    topLeft: Radius.circular(
      getHorizontalSize(
        65,
      ),
    ),
    topRight: Radius.circular(
      getHorizontalSize(
        12,
      ),
    ),
    bottomLeft: Radius.circular(
      getHorizontalSize(
        65,
      ),
    ),
    bottomRight: Radius.circular(
      getHorizontalSize(
        12,
      ),
    ),
  );

  static BorderRadius circleBorder81 = BorderRadius.circular(
    getHorizontalSize(
      81,
    ),
  );

  static BorderRadius circleBorder100 = BorderRadius.circular(
    getHorizontalSize(
      100,
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
extension ToString on bool {
  String convertBool() {
    if (this) return "true";
    return "false";
  }
}
// Comment/Uncomment the below code based on your Flutter SDK version.

// For Flutter SDK Version 3.7.2 or greater.

double get strokeAlignInside => BorderSide.strokeAlignInside;

double get strokeAlignCenter => BorderSide.strokeAlignCenter;

double get strokeAlignOutside => BorderSide.strokeAlignOutside;
