import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/utils/constants.dart';
import 'package:bb_factory_test_app/utils/enums/store_state.dart';

class OtpDialog extends StatelessWidget {
  OtpDialog({
    super.key,
    required BuildContext context,
  });

  final otpController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    return AlertDialog(
      surfaceTintColor: Colors.white,
      title: Constants.appHeaderImage(
        height: 30,
        width: 40,
      ),
      content: Obx(
        () {
          return Stack(
            children: [
              AlertDialog(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter OTP",
                      style: Constants.customTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Constants.textFormField(
                      controller: otpController,
                      label: "OTP",
                      keyboardType: TextInputType.number,
                    )
                  ],
                ),
              ),
              if (controller.state.value == StoreState.LOADING)
                const SpinKitCircle(
                  color: Colors.blueAccent,
                ),
            ],
          );
        },
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await controller.verifyOTP(
                  otp: otpController.text.trim(),
                  context: context,
                );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => Colors.blueAccent,
                ),
              ),
              child: Text(
                "Verify",
                style: Constants.customTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
