import 'package:bb_factory_test_app/constants/color_constants.dart';
import 'package:bb_factory_test_app/constants/constants.dart';
import 'package:bb_factory_test_app/constants/size_config.dart';
import 'package:flutter/material.dart';

class AppStyle {
  static TextStyle customTextStyle({
    required FontWeight fontWeight,
    required double fontSize,
    Color? color,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
      decoration: decoration,
    );
  }

  // static void customToast({required String message}) {
  //   FToast().init(Navigator.)
  // }

  static TextStyle txtWorkSansRomanRegular8 = TextStyle(
    color: ColorConstant.indigo900,
    fontSize: getFontSize(
      9,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanBold18 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      18,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w700,
  );

  static TextStyle txtWorkSansRomanLight24 = TextStyle(
    color: ColorConstant.tealA700,
    fontSize: getFontSize(
      24,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w500,
  );

  static TextStyle txtWorkSansRomanRegular10Black90087 = TextStyle(
    color: ColorConstant.black90087,
    fontSize: getFontSize(
      10,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanSemiBold24Red700 = TextStyle(
    color: ColorConstant.red700,
    fontSize: getFontSize(
      24,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanRegular14Gray40001 = TextStyle(
    color: ColorConstant.gray40001,
    fontSize: getFontSize(
      16,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w500,
  );

  static TextStyle txtWorkSansRomanSemiBold36WhiteA700 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      36,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanRegular14Gray40002 = TextStyle(
    color: ColorConstant.gray40002,
    fontSize: getFontSize(
      16,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w500,
  );

  static TextStyle txtWorkSansRomanLight28WhiteA700d6 = TextStyle(
    color: ColorConstant.whiteA700D6,
    fontSize: getFontSize(
      28,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w300,
  );

  static TextStyle txtWorkSansRomanSemiBold36 = TextStyle(
    color: ColorConstant.black900D6,
    fontSize: getFontSize(
      36,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanSemiBold14 = TextStyle(
    color: ColorConstant.gray200,
    fontSize: getFontSize(
      14,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanRegular14Black900 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      16,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w500,
  );

  static TextStyle txtWorkSansRomanRegular18 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      20,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w500,
  );

  static TextStyle txtWorkSansRomanRegular14Gray400 = TextStyle(
    color: ColorConstant.gray400,
    fontSize: getFontSize(
      16,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanRegular16 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      16,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanRegular14Gray200 = TextStyle(
    color: ColorConstant.gray200,
    fontSize: getFontSize(
      14,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanSemiBold24WhiteA700 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      24,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanRegular10 = TextStyle(
    color: ColorConstant.indigo900,
    fontSize: getFontSize(
      10,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanMedium18 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      18,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w500,
  );

  static TextStyle txtWorkSansRomanRegular11 = TextStyle(
    color: ColorConstant.gray500,
    fontSize: getFontSize(
      14,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanRegular14 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      14,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtRobotoRegular20 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      20,
    ),
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanLight28 = TextStyle(
    color: ColorConstant.cyanA400D6,
    fontSize: getFontSize(
      28,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w300,
  );

  static TextStyle txtWorkSansRomanSemiBold24Gray200 = TextStyle(
    color: ColorConstant.gray200,
    fontSize: getFontSize(
      24,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanMedium12 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      12,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w500,
  );

  static TextStyle txtWorkSansRomanLight12 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      12,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w300,
  );

  static TextStyle txtWorkSansRomanBold24 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      24,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanLight30 = TextStyle(
    color: ColorConstant.cyanA400D6,
    fontSize: getFontSize(
      30,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w300,
  );

  static TextStyle txtWorkSansRomanSemiBold40 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      30,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanRegular8Black900 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      8,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanSemiBold18WhiteA700 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      18,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanSemiBold20 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      20,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanSemiBold24 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      22,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanSemiBold14Black900 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      16,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanRegular18WhiteA700 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      18,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanRegular8WhiteA700 = TextStyle(
    color: ColorConstant.whiteA700,
    fontSize: getFontSize(
      8,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanSemiBold18 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      17,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanRegular28 = TextStyle(
    color: ColorConstant.whiteA700D6,
    fontSize: getFontSize(
      28,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanRegular14Bluegray400 = TextStyle(
    color: ColorConstant.blueGray400,
    fontSize: getFontSize(
      14,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtRobotoRegular16 = TextStyle(
    color: ColorConstant.blueGray40001,
    fontSize: getFontSize(
      16,
    ),
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanLight24CyanA400d6 = TextStyle(
    color: ColorConstant.cyanA400D6,
    fontSize: getFontSize(
      24,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w300,
  );

  static TextStyle txtWorkSansRomanSemiBold20Gray200 = TextStyle(
    color: ColorConstant.gray200,
    fontSize: getFontSize(
      20,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w600,
  );

  static TextStyle txtWorkSansRomanLight18 = TextStyle(
    color: ColorConstant.gray20001,
    fontSize: getFontSize(
      18,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w300,
  );

  static TextStyle txtWorkSansRomanRegular20 = TextStyle(
    color: ColorConstant.black900D6,
    fontSize: getFontSize(
      20,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtInterRegular14 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      14,
    ),
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
  );

  static TextStyle txtWorkSansRomanBold40 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      40,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w700,
  );

  static TextStyle txtWorkSansRomanRegular24 = TextStyle(
    color: ColorConstant.black900,
    fontSize: getFontSize(
      24,
    ),
    fontFamily: 'Work Sans',
    fontWeight: FontWeight.w400,
  );
}
