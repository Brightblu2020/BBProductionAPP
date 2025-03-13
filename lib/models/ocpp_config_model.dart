import 'package:get/get.dart';

class OCPPConfigModel {
  OCPPConfigModel({
    required this.key,
    required this.value,
    required this.type,
    required this.readOnly,
  });

  factory OCPPConfigModel.fromjson({required Map<String, dynamic> json}) {
    return OCPPConfigModel(
      key: json['key'] as String,
      value: json['value'] as String,
      type: _getDataType(json['value'] as String),
      readOnly: json['readonly'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "key": key,
      "value": value,
      "readonly": readOnly,
    };
  }

  OCPPConfigModel copyWith({String? value}) {
    return OCPPConfigModel(
      key: key,
      value: value ?? this.value,
      type: type,
      readOnly: readOnly,
    );
  }

  static Type _getDataType(String value) {
    if (value == "true" || value == "false") {
      return bool;
    } else if (value.isAlphabetOnly) {
      return String;
    }
    return num;
  }

  final String key;
  final String value;
  final bool readOnly;
  final Type type;
}
