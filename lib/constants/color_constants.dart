import 'package:flutter/material.dart';

class ColorConstant {
  static Color whiteA7007f = fromHex('#7fffffff');

  static Color indigoA7003301 = fromHex('#330032ff');

  static Color black9002601 = fromHex('#26000000');

  static Color blueA400 = fromHex('#1a7dfc');

  static Color blueA200 = fromHex('#4090f7');

  static Color cyanA20001 = fromHex('#02fcff');

  static Color lightBlue500 = fromHex('#02a1ff');

  static Color black9003f = fromHex('#3f000000');

  static Color lightBlueA4003f = fromHex('#3f01c9ff');

  static Color black90087 = fromHex('#87000000');

  static Color teal500 = fromHex('#07ab91');

  static Color indigoA70001 = fromHex('#0243ff');

  static Color whiteA70056 = fromHex('#56ffffff');

  static Color gray20001 = fromHex('#efefef');

  static Color blueGray900 = fromHex('#0f0f47');

  static Color tealA700 = fromHex('#09b28c');

  static Color cyanA400D6 = fromHex('#d600d7ff');

  static Color gray400 = fromHex('#c3c3c3');

  static Color lightBlueA40001 = fromHex('#02bbff');

  static Color blueGray100 = fromHex('#d6d6d6');

  static Color indigoA7003f = fromHex('#3f0000f5');

  static Color lightBlue50075 = fromHex('#7502a1ff');

  static Color indigoA7003f01 = fromHex('#3f0141ff');

  static Color gray200 = fromHex('#eeeeee');

  static Color lightBlueA4007f = fromHex('#7f01c9ff');

  static Color cyanA40075 = fromHex('#7502f5ff');

  static Color indigo90000 = fromHex('#0004047b');

  static Color gray40001 = fromHex('#b7b7b7');

  static Color indigoA700 = fromHex('#0141ff');

  static Color gray40002 = fromHex('#b3b3b3');

  static Color indigo90001 = fromHex('#0c0c57');

  static Color cyan70001 = fromHex('#07a598');

  static Color black90019 = fromHex('#19050a09');

  static Color cyanA2003f = fromHex('#3f01ffff');

  static Color blueGray40001 = fromHex('#888888');

  static Color whiteA700 = fromHex('#ffffff');

  static Color cyanA400 = fromHex('#00f0ff');

  static Color cyanA200 = fromHex('#01ffff');

  static Color red700 = fromHex('#d52845');

  static Color lightBlueA400 = fromHex('#01c9ff');

  static Color blueA700 = fromHex('#0060ff');

  static Color whiteA700D6 = fromHex('#d6ffffff');

  static Color lightBlue400 = fromHex('#2daefa');

  static Color black900D6 = fromHex('#d6000000');

  static Color blueA70001 = fromHex('#024fff');

  static Color gray50 = fromHex('#fafafa');

  static Color greenA400 = fromHex('#0acd6f');

  static Color cyanA40001 = fromHex('#02f5ff');

  static Color black900 = fromHex('#000000');

  static Color gray509b = fromHex('#9bfafafa');

  static Color greenA40002 = fromHex('#09c577');

  static Color greenA40001 = fromHex('#0acc6f');

  static Color black90026 = fromHex('#26050a09');

  static Color indigoA700D3 = fromHex('#d30000f5');

  static Color gray500 = fromHex('#979797');

  static Color blueGray400 = fromHex('#8a8a8a');

  static Color blue800 = fromHex('#306ebc');

  static Color gray900 = fromHex('#1d1e18');

  static Color gray90001 = fromHex('#171717');

  static Color blueA70075 = fromHex('#75024fff');

  static Color gray30000 = fromHex('#00dfdfdf');

  static Color whiteA70000 = fromHex('#00ffffff');

  static Color black90033 = fromHex('#33000000');

  static Color indigoA70033 = fromHex('#330041ff');

  static Color blueA20099 = fromHex('#994090f7');

  static Color indigo900 = fromHex('#04047b');

  static Color cyan700 = fromHex('#0690ae');

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
