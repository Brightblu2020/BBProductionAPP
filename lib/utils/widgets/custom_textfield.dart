// ignore_for_file: must_be_immutable, constant_identifier_names

import 'package:bb_factory_test_app/constants/color_constants.dart';
import 'package:bb_factory_test_app/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FormFieldOnChanged = void Function(String);

class CustomTextFormField extends StatelessWidget {
  CustomTextFormField({
    super.key,
    this.shape,
    this.padding,
    this.variant,
    this.fontStyle,
    this.alignment,
    this.width,
    this.margin,
    this.controller,
    this.focusNode,
    this.isObscureText = false,
    this.textInputAction = TextInputAction.next,
    this.textInputType = TextInputType.text,
    this.maxLines,
    this.hintText,
    this.prefix,
    this.prefixConstraints,
    this.suffix,
    this.suffixConstraints,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.enabled,
  });

  TextFormFieldShape? shape;

  TextFormFieldPadding? padding;

  TextFormFieldVariant? variant;

  TextFormFieldFontStyle? fontStyle;

  Alignment? alignment;

  double? width;

  EdgeInsetsGeometry? margin;

  TextEditingController? controller;

  FocusNode? focusNode;

  bool? isObscureText;

  TextInputAction? textInputAction;

  TextInputType? textInputType;

  int? maxLines;

  String? hintText;

  Widget? prefix;

  BoxConstraints? prefixConstraints;

  Widget? suffix;

  BoxConstraints? suffixConstraints;

  FormFieldValidator<String>? validator;

  FormFieldOnChanged? onChanged;

  List<TextInputFormatter>? inputFormatters;

  bool? enabled;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment ?? Alignment.center,
            child: _buildTextFormFieldWidget(),
          )
        : _buildTextFormFieldWidget();
  }

  _buildTextFormFieldWidget() {
    return Container(
      width: width ?? double.maxFinite,
      margin: margin,
      child: TextFormField(
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        controller: controller,
        enabled: enabled ?? true,
        focusNode: focusNode,
        style: _setFontStyle(),
        obscureText: isObscureText!,
        textInputAction: textInputAction,
        keyboardType: textInputType,
        maxLines: maxLines ?? 1,
        decoration: _buildDecoration(),
        validator: validator,
      ),
    );
  }

  _buildDecoration() {
    return InputDecoration(
      hintText: hintText ?? "",
      hintStyle: _setFontStyle(),
      border: _setBorderStyle(),
      enabledBorder: _setBorderStyle(),
      focusedBorder: _setBorderStyle(),
      disabledBorder: _setBorderStyle(),
      prefixIcon: prefix,
      prefixIconConstraints: prefixConstraints,
      suffixIcon: suffix,
      suffixIconConstraints: suffixConstraints,
      fillColor: _setFillColor(),
      filled: _setFilled(),
      isDense: true,
      contentPadding: _setPadding(),
    );
  }

  _setFontStyle() {
    switch (fontStyle) {
      case TextFormFieldFontStyle.WorkSansRomanSemiBold18:
        return TextStyle(
          color: ColorConstant.black900,
          fontSize: getFontSize(
            18,
          ),
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w600,
        );
      case TextFormFieldFontStyle.WorkSansRomanSemiBold18WhiteA700:
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
          color: ColorConstant.black900D6,
          fontSize: getFontSize(
            20,
          ),
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w400,
        );
    }
  }

  _setOutlineBorderRadius() {
    switch (shape) {
      case TextFormFieldShape.RoundedBorder12:
        return BorderRadius.circular(
          getHorizontalSize(
            12.00,
          ),
        );
      default:
        return BorderRadius.circular(
          getHorizontalSize(
            18.00,
          ),
        );
    }
  }

  _setBorderStyle() {
    switch (variant) {
      case TextFormFieldVariant.UnderLineGray400:
        return UnderlineInputBorder(
          borderSide: BorderSide(
            color: ColorConstant.gray400,
          ),
        );
      case TextFormFieldVariant.OutlineIndigo900:
        return OutlineInputBorder(
          borderRadius: _setOutlineBorderRadius(),
          borderSide: BorderSide(
            color: ColorConstant.indigo900,
            width: 1,
          ),
        );
      case TextFormFieldVariant.OutlineBlack9002601:
        return OutlineInputBorder(
          borderRadius: _setOutlineBorderRadius(),
          borderSide: BorderSide.none,
        );
      case TextFormFieldVariant.None:
        return InputBorder.none;
      default:
        return UnderlineInputBorder(
          borderSide: BorderSide(
            color: ColorConstant.blueGray100,
          ),
        );
    }
  }

  _setFillColor() {
    switch (variant) {
      case TextFormFieldVariant.OutlineIndigo900:
        return ColorConstant.whiteA700;
      default:
        return null;
    }
  }

  _setFilled() {
    switch (variant) {
      case TextFormFieldVariant.UnderLineBluegray100:
        return false;
      case TextFormFieldVariant.UnderLineGray400:
        return false;
      case TextFormFieldVariant.OutlineIndigo900:
        return true;
      case TextFormFieldVariant.OutlineBlack9002601:
        return false;
      case TextFormFieldVariant.None:
        return false;
      default:
        return false;
    }
  }

  _setPadding() {
    switch (padding) {
      default:
        return getPadding(
          left: 18,
          top: 10,
          right: 18,
          bottom: 10,
        );
    }
  }
}

enum TextFormFieldShape {
  CircleBorder18,
  RoundedBorder12,
}

enum TextFormFieldPadding {
  PaddingT34,
}

enum TextFormFieldVariant {
  None,
  UnderLineBluegray100,
  UnderLineGray400,
  OutlineIndigo900,
  OutlineBlack9002601,
}

enum TextFormFieldFontStyle {
  WorkSansRomanRegular20,
  WorkSansRomanSemiBold18,
  WorkSansRomanSemiBold18WhiteA700,
}
