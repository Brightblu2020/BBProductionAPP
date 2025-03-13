// ignore_for_file: constant_identifier_names

enum ChargerError {
  DIODE,
  EVCOMMUNICATION,
  OVER_VOLTAGE,
  OVER_CURRENT,
  HIGHTEMPRATURE,
  EARTHLEAKAGE,
  GROUNDFAILURE,
  INTERNALERROR,
  UNDER_VOLTAGE,
  NOERROR,
  DPM,
  SDCARDFAILURE,
}

extension ErrorCodeNames on ChargerError {
  String toErrorName() {
    switch (this) {
      case ChargerError.DIODE:
        return "Diode error";
      case ChargerError.EVCOMMUNICATION:
        return "Ev communication error";
      case ChargerError.OVER_VOLTAGE:
        return "Over volatge failure";
      case ChargerError.OVER_CURRENT:
        return "Over current failure";
      case ChargerError.HIGHTEMPRATURE:
        return "High temprature";
      case ChargerError.EARTHLEAKAGE:
        return "Earth leakage error";
      case ChargerError.GROUNDFAILURE:
        return "Ground error";
      case ChargerError.INTERNALERROR:
        return "Internal error";
      case ChargerError.NOERROR:
        return "No Error";
      case ChargerError.UNDER_VOLTAGE:
        return "Under voltage failure";
      case ChargerError.DPM:
        return "DPM Error";
      case ChargerError.SDCARDFAILURE:
        return "SD Card Failure";
    }
  }

  // String errorSolution() {
  //   switch (this) {
  //     case ChargerError.DIODE:
  //       return "Arises when charging conditions are unsafe.\n\nEnsure the Charging cable is not wet and the connectors the Charger is stored in a cool dry location. If the cable is wet, please allow the cable to dry out before attempting to charge again.\n\nIf the issue still persists, please contact BRIGHTBLU for further support.";
  //     case ChargerError.EVCOMMUNICATION:
  //       return "Communication breakdown between Vehicle and Charger.\n\nEnsure the cable is inserted completely.\n\nIf the issue still persists, please contact BRIGHTBLU for further support.";
  //     case ChargerError.OVER_VOLTAGE:
  //       return "The Supply voltage is at dangerously High levels. The usual cut off is +/- 20% of 230V. You can try the following Fixes:\n\n 1.Reduce the current:\nOn the App you can set the max current limit. By reducing the current, the voltage drop is minimized. If the unit functions normally, check your supply’s sanctioned load.\n\n2. Wait till the supply is restored back to normal. It could be an issue from the Grid (Maintenance/ upgrades/ Failures etc.)\nIf the issue still persists, please contact BRIGHTBLU for further support.";
  //     case ChargerError.OVER_CURRENT:
  //       return "The vehicle is drawing more current than what the charger is capable of delivering.\n\nThe charger will stop charging to avoid any further damages.\n\nReduce the current limit and test if the issue still persists.\n\nIf the issue still persists, please contact BRIGHTBLU for further support.";
  //     case ChargerError.HIGHTEMPRATURE:
  //       return "Internal temperature has exceeded 80*C and the charger needs to cool down before It can deliver energy again.\n\nTo avoid this, ensure the charger is installed in a cool/shady location.\n\nThe charger is tested up to an ambient temperature of 45*C.\n\nIf the issue still persists, please contact BRIGHTBLU for further support.";
  //     case ChargerError.EARTHLEAKAGE:
  //       return "Earth leakage is when the current flowing in a system finds an alternative return path other than active and neutral conductors.\n\nFix: Requires a Qualified Electrician to fix this error.";
  //     case ChargerError.GROUNDFAILURE:
  //       return "Improper Earth connection.\n\nThe Voltage difference between N – P.E should not exceed 8V. \n\nFix: Requires a Qualified Electrician to fix this error.";
  //     case ChargerError.INTERNALERROR:
  //       return "One of the subcomponents of the device has failed and needs to be replaced.\n\nPlease contact BRIGHTBLU for further assistance.";
  //     case ChargerError.NOERROR:
  //       return "Bluetooth:\n\n\t1.I’m unable to find my charger on my app\n\t\t\ta.Make sure the device is within 9 meters from you charger\n\t\t\tb.Ensure Bluetooth is switched ON\n\t\t\tc.Close the app and try again\n\t\t\td.Try to turn your charger off and then back on.\n\n\t2.My Device lost connection with the app / Unresponsive\n\t\t\ta.Make sure the device is within 9 meters from you charger\n\t\t\tb.Close the app and try again\n\t\t\tc.If the problem persists, please contact us : support@brightblu.com\n\nWI-FI:\n\t1.Unable to connect to the WI-FI\n\t\t\t\ta.Ensure you’ve entered the correct password\n\t\t\tb.Check if you are able to connect to Wi-Fi with other devices\n\t\t\tc.Try restarting your router\n\t\t\td.Try to turn your charger off and then back on\n\t\n2.Unable to find my Wi-Fi SSID/Name\n\t\t\ta.Ensure your Wi-Fi router is switched on\n\t\t\tb.Your charger only supports Wi-Fi network in the 2.4GHz Channel. Ensure your router is broadcasting its SSID in the same channel\n\t\tc.Close the app and try again\n\t\td.Try to turn your charger off and then back on.\n\t\n3.Unable to Login into the charger\n\t\t\ta.Ensure the Mobile phone Wi-Fi network and Charger network are the same.\n\t\t\tb.Check if the Mobile Phone is connected to the 2.4Ghz Channel Wi-Fi network\n\t\t\tc.Check if you Username and Password are entered correctly\n\t\n4.Unable to Signup \n\t\t\ta.Ensure the Mobile phone Wi-Fi network and Charger network are the same.\n\t\t\tb.Check if the Mobile Phone is connected to the 2.4Ghz Channel Wi-Fi network";
  //     case ChargerError.UNDER_VOLTAGE:
  //       return "The Supply voltage is at dangerously low levels. The usual cut off is +/- 20% of 230V. You can try the following Fixes\n\n1. Reduce the current. On the App you can set the max current limit. By reducing the current, the voltage drop is minimized. If the unit functions normally, check your supply’s sanctioned load.\n\n2. Wait till the supply is restored back to normal. It could be an issue from the Grid (Maintenance/ upgrades/ Failures etc.).\nIf the issue still persists, please contact BRIGHTBLU for further support.";
  //     case ChargerError.DPM:
  //       return "BRIGHTBLU Power Manager communication failure.\n\nFix: Requires a Qualified Electrician to fix this error.\n\nClick OK to disable the load management and restore the charger to working conditions.\n\nImportant: Ensure that the charger's max current setting is lower than the sanctioned load to avoid power outage.";
  //   }
  // }

  int errorNumber() {
    switch (this) {
      case ChargerError.DIODE:
        return 0;
      case ChargerError.EVCOMMUNICATION:
        return 1;
      case ChargerError.OVER_VOLTAGE:
        return 2;
      case ChargerError.OVER_CURRENT:
        return 3;
      case ChargerError.HIGHTEMPRATURE:
        return 4;
      case ChargerError.EARTHLEAKAGE:
        return 5;
      case ChargerError.GROUNDFAILURE:
        return 6;
      case ChargerError.INTERNALERROR:
        return 7;
      case ChargerError.UNDER_VOLTAGE:
        return 8;
      case ChargerError.NOERROR:
        return 9;
      case ChargerError.DPM:
        return 10;
      case ChargerError.SDCARDFAILURE:
        return 11;
    }
  }
}

ChargerError getChargerError({required String code}) {
  switch (code) {
    case "DiodeError":
      return ChargerError.DIODE;
    case "EVCommunicationError":
      return ChargerError.EVCOMMUNICATION;
    case "OverVoltage":
      return ChargerError.OVER_VOLTAGE;
    case "OverCurrentFailure":
      return ChargerError.OVER_CURRENT;
    case "HighTemperature":
      return ChargerError.HIGHTEMPRATURE;
    case "EarthLeakageError":
      return ChargerError.EARTHLEAKAGE;
    case "GroundFailure":
      return ChargerError.GROUNDFAILURE;
    case "InternalError":
      return ChargerError.INTERNALERROR;
    case "UnderVoltage":
      return ChargerError.UNDER_VOLTAGE;
    case "DPMError":
      return ChargerError.DPM;
    case "SDCardFailure":
      return ChargerError.SDCARDFAILURE;
    default:
      return ChargerError.NOERROR;
  }
}
