import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/utils/constants.dart';

class SessionBanner extends StatelessWidget {
  const SessionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    return StreamBuilder(
        stream: controller.sessionStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data! != "") {
            return Container(
              height: 25,
              decoration: BoxDecoration(
                color: Colors.blue[900],
              ),
              alignment: Alignment.center,
              child: Text(
                "Session ends in ${snapshot.data ?? ""}",
                style: Constants.customTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            );
          }
          return const SizedBox();
        });
  }
}
