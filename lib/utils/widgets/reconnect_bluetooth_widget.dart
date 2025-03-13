import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
// import 'package:bb_factory_test_app/screens/main_screen.dart';
import 'package:bb_factory_test_app/utils/constants.dart';

class ReconnectBluetoothWidget extends StatelessWidget {
  const ReconnectBluetoothWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                text: "The charger has been disconnected",
                style: Constants.customTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: "\nKindly go back and connect again",
                    style: Constants.customTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                //TODO:
                // Navigator.pushAndRemoveUntil(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => const MainScreen(),
                //     ),
                //     (route) => false);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.blueAccent),
              ),
              child: Text(
                "Back",
                style: Constants.customTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
