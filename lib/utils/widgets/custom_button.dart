// ignore_for_file: must_be_immutable

import 'package:bb_factory_test_app/constants/color_constants.dart';
import 'package:bb_factory_test_app/constants/size_config.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  CustomButton(
      {super.key,
      this.shape,
      this.padding,
      this.variant,
      this.fontStyle,
      this.alignment,
      this.margin,
      this.onTap,
      this.width,
      this.height,
      this.text,
      this.prefixWidget,
      this.suffixWidget});

  ButtonShape? shape;

  ButtonPadding? padding;

  ButtonVariant? variant;

  ButtonFontStyle? fontStyle;

  Alignment? alignment;

  EdgeInsetsGeometry? margin;

  VoidCallback? onTap;

  double? width;

  double? height;

  String? text;

  Widget? prefixWidget;

  Widget? suffixWidget;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment!,
            child: _buildButtonWidget(),
          )
        : _buildButtonWidget();
  }

  _buildButtonWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: TextButton(
        onPressed: onTap,
        style: _buildTextButtonStyle(),
        child: _buildButtonChildWidget(),
      ),
    );
  }

  _buildButtonChildWidget() {
    if (checkGradient()) {
      return Container(
        width: width ?? double.maxFinite,
        padding: _setPadding(),
        decoration: _buildDecoration(),
        child: _buildButtonWithOrWithoutIcon(),
      );
    } else {
      return _buildButtonWithOrWithoutIcon();
    }
  }

  _buildButtonWithOrWithoutIcon() {
    if (prefixWidget != null || suffixWidget != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          prefixWidget ?? const SizedBox(),
          Text(
            text ?? "",
            textAlign: TextAlign.center,
            style: _setFontStyle(),
          ),
          suffixWidget ?? const SizedBox(),
        ],
      );
    } else {
      return Text(
        text ?? "",
        textAlign: TextAlign.center,
        style: _setFontStyle(),
      );
    }
  }

  _buildDecoration() {
    return BoxDecoration(
      border: _setBorder(),
      borderRadius: _setBorderRadius(),
      gradient: _setGradient(),
      boxShadow: _setBoxShadow(),
    );
  }

  _buildTextButtonStyle() {
    if (checkGradient()) {
      return TextButton.styleFrom(
        padding: EdgeInsets.zero,
      );
    } else {
      return TextButton.styleFrom(
        fixedSize: Size(
          width ?? double.maxFinite,
          height ?? getVerticalSize(40),
        ),
        padding: _setPadding(),
        backgroundColor: _setColor(),
        side: _setTextButtonBorder(),
        shadowColor: _setTextButtonShadowColor(),
        shape: RoundedRectangleBorder(
          borderRadius: _setBorderRadius(),
        ),
      );
    }
  }

  _setPadding() {
    switch (padding) {
      case ButtonPadding.PaddingT9:
        return getPadding(
          top: 9,
          right: 9,
          bottom: 9,
        );
      case ButtonPadding.PaddingT12:
        return getPadding(
          left: 8,
          top: 12,
          right: 8,
          bottom: 12,
        );
      case ButtonPadding.PaddingT9_1:
        return getPadding(
          left: 9,
          top: 9,
          bottom: 9,
        );
      case ButtonPadding.PaddingAll4:
        return getPadding(
          all: 4,
        );
      default:
        return getPadding(
          all: 9,
        );
    }
  }

  _setColor() {
    switch (variant) {
      case ButtonVariant.OutlineIndigo900:
        return ColorConstant.whiteA700;
      case ButtonVariant.OutlineWhiteA700:
        return ColorConstant.indigo900;
      case ButtonVariant.OutlineIndigo900_2:
        return ColorConstant.whiteA700;
      case ButtonVariant.FillWhiteA700:
        return ColorConstant.whiteA700;
      case ButtonVariant.Outline:
        return null;
      default:
        return ColorConstant.whiteA700;
    }
  }

  _setTextButtonBorder() {
    switch (variant) {
      case ButtonVariant.OutlineIndigo900:
        return BorderSide(
          color: ColorConstant.indigo900,
          width: getHorizontalSize(
            1.00,
          ),
        );
      case ButtonVariant.OutlineWhiteA700:
        return BorderSide(
          color: ColorConstant.whiteA700,
          width: getHorizontalSize(
            1.00,
          ),
        );
      case ButtonVariant.OutlineIndigo900_2:
        return BorderSide(
          color: ColorConstant.indigo900,
          width: getHorizontalSize(
            1.00,
          ),
        );
      case ButtonVariant.FillWhiteA700:
        return null;
      default:
        return BorderSide(
          color: ColorConstant.indigo900,
          width: getHorizontalSize(
            1.00,
          ),
        );
    }
  }

  _setTextButtonShadowColor() {
    switch (variant) {
      case ButtonVariant.OutlineIndigo900_2:
        return ColorConstant.black90019;
      case ButtonVariant.OutlineIndigo900:
      case ButtonVariant.OutlineWhiteA700:
      case ButtonVariant.Outline:
      case ButtonVariant.FillWhiteA700:
        return null;
      default:
        return ColorConstant.black90026;
    }
  }

  _setBorderRadius() {
    switch (shape) {
      case ButtonShape.RoundedBorder12:
        return BorderRadius.circular(
          getHorizontalSize(
            12.00,
          ),
        );
      case ButtonShape.RoundedBorder3:
        return BorderRadius.circular(
          getHorizontalSize(
            3.00,
          ),
        );
      case ButtonShape.Square:
        return BorderRadius.circular(0);
      default:
        return BorderRadius.circular(
          getHorizontalSize(
            18.00,
          ),
        );
    }
  }

  _setFontStyle() {
    switch (fontStyle) {
      case ButtonFontStyle.InterSemiBold14:
        return TextStyle(
          color: ColorConstant.black900,
          fontSize: getFontSize(
            14,
          ),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        );
      case ButtonFontStyle.InterSemiBold14Gray900:
        return TextStyle(
          color: ColorConstant.gray900,
          fontSize: getFontSize(
            14,
          ),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        );
      case ButtonFontStyle.WorkSansRomanBold14WhiteA700:
        return TextStyle(
          color: ColorConstant.whiteA700,
          fontSize: getFontSize(
            16,
          ),
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w600,
        );
      case ButtonFontStyle.WorkSansRomanLight18:
        return TextStyle(
          color: ColorConstant.gray20001,
          fontSize: getFontSize(
            18,
          ),
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w300,
        );
      case ButtonFontStyle.WorkSansRomanSemiBold16:
        return TextStyle(
          color: ColorConstant.whiteA700,
          fontSize: getFontSize(
            18,
          ),
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w600,
        );
      default:
        return TextStyle(
          color: ColorConstant.indigo900,
          fontSize: getFontSize(
            16,
          ),
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w600,
        );
    }
  }

  _setBorder() {
    switch (variant) {
      case ButtonVariant.OutlineIndigo900:
        return Border.all(
          color: ColorConstant.indigo900,
          width: getHorizontalSize(
            1.00,
          ),
        );
      case ButtonVariant.OutlineWhiteA700:
        return Border.all(
          color: ColorConstant.whiteA700,
          width: getHorizontalSize(
            1.00,
          ),
        );
      case ButtonVariant.OutlineIndigo900_2:
        return Border.all(
          color: ColorConstant.indigo900,
          width: getHorizontalSize(
            1.00,
          ),
        );
      case ButtonVariant.FillWhiteA700:
        return null;
      default:
        return Border.all(
          color: ColorConstant.indigo900,
          width: getHorizontalSize(
            1.00,
          ),
        );
    }
  }

  checkGradient() {
    switch (variant) {
      case ButtonVariant.Outline:
        return true;
      default:
        return false;
    }
  }

  _setGradient() {
    switch (variant) {
      case ButtonVariant.Outline:
        return LinearGradient(
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
        );
      case ButtonVariant.OutlineIndigo900_1:
      case ButtonVariant.OutlineIndigo900:
      case ButtonVariant.OutlineWhiteA700:
      case ButtonVariant.OutlineIndigo900_2:
      case ButtonVariant.FillWhiteA700:
        return null;
      default:
        return null;
    }
  }

  _setBoxShadow() {
    switch (variant) {
      case ButtonVariant.OutlineIndigo900_2:
        return [
          BoxShadow(
            color: ColorConstant.black90019,
            spreadRadius: getHorizontalSize(
              2.00,
            ),
            blurRadius: getHorizontalSize(
              2.00,
            ),
            offset: const Offset(
              0,
              1.85,
            ),
          ),
        ];
      case ButtonVariant.OutlineIndigo900:
      case ButtonVariant.OutlineWhiteA700:
      case ButtonVariant.Outline:
      case ButtonVariant.FillWhiteA700:
        return null;
      default:
        return [
          BoxShadow(
            color: ColorConstant.black90026,
            spreadRadius: getHorizontalSize(
              2.00,
            ),
            blurRadius: getHorizontalSize(
              2.00,
            ),
            offset: const Offset(
              -4,
              4,
            ),
          ),
        ];
    }
  }
}

enum ButtonShape {
  Square,
  CircleBorder18,
  RoundedBorder12,
  RoundedBorder3,
}

enum ButtonPadding {
  PaddingAll9,
  PaddingT9,
  PaddingT12,
  PaddingT9_1,
  PaddingAll4,
}

enum ButtonVariant {
  OutlineIndigo900_1,
  OutlineIndigo900,
  OutlineWhiteA700,
  OutlineIndigo900_2,
  Outline,
  FillWhiteA700,
}

enum ButtonFontStyle {
  WorkSansRomanBold14,
  InterSemiBold14,
  InterSemiBold14Gray900,
  WorkSansRomanBold14WhiteA700,
  WorkSansRomanLight18,
  WorkSansRomanSemiBold16,
}
