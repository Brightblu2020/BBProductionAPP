import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:bb_factory_test_app/controller/controller.dart';
import 'package:bb_factory_test_app/utils/constants.dart';
import 'package:bb_factory_test_app/utils/widgets/session_banner.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.appDrawer,
    this.isDisconnect,
    this.actions,
    this.hideSession,
  });

  final bool? appDrawer;
  final bool? isDisconnect;
  final List<Widget>? actions;
  final bool? hideSession;

  @override
  Widget build(BuildContext context) {
    /// Drawer will also get added
    final controller = Get.find<Controller>();
    return AppBar(
      // backgroundColor: Colors.white,
      actions: actions,
      scrolledUnderElevation: 0.0,
      leading: (appDrawer != null)
          ? (!appDrawer!)
              ? _leadingWidget(controller)
              : _appDrawerIcon(context: context)
          : const SizedBox(),
      bottom: PreferredSize(
        preferredSize: const Size(double.maxFinite, 20),
        child: Obx(() {
          if (controller.isChargerConnected) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ip Address\n${controller.ipAddress.value}",
                        style: Constants.customTextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        "Firmware\n${(controller.chargerModel.value.firmware != null || controller.chargerModel.value.firmware != "") ? controller.chargerModel.value.firmware : "Not found"}",
                        style: Constants.customTextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        "WiFi\n${(controller.wifiModel.value.ssid != "") ? controller.wifiModel.value.ssid : "Not connected"}",
                        style: Constants.customTextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  // child: SessionBanner(),
                ),
                // const SizedBox(height: 7),
              ],
            );
          }
          return Offstage(
            offstage: hideSession != null,
            child: const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Card(),
            ),
          );
          // return const SizedBox();
        }),
      ),
      // title: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     Text(
      //       "BrightBlu",
      //       style: Constants.customTextStyle(
      //         fontWeight: FontWeight.w600,
      //         color: Colors.white,
      //         fontSize: 18,
      //       ),
      //     ),
      //     // Row(
      //     //   mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     //   children: [
      //     //     Text(
      //     //       "BrightBlu",
      //     //       style: Constants.customTextStyle(
      //     //         fontWeight: FontWeight.w600,
      //     //         color: Colors.white,
      //     //         fontSize: 15,
      //     //       ),
      //     //     ),
      //     //     Text(
      //     //       "BrightBlu",
      //     //       style: Constants.customTextStyle(
      //     //         fontWeight: FontWeight.w600,
      //     //         color: Colors.white,
      //     //         fontSize: 15,
      //     //       ),
      //     //     ),
      //     //   ],
      //     // ),
      //   ],
      // ),
      title: Constants.appHeaderImage(
        height: 50,
        width: MediaQuery.of(context).size.width / 2,
        boxFit: BoxFit.contain,
      ),
      centerTitle: true,
    );
  }

  Widget _appDrawerIcon({required BuildContext context}) {
    return IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: const Icon(
          Icons.menu_rounded,
          color: Colors.black,
        ));
  }

  IconButton _leadingWidget(Controller controller) {
    return IconButton(
      onPressed: () async {
        if (controller.isChargerConnected && isDisconnect != null) {
          await controller.disconnectCharger();
        }
        Get.back();
      },
      icon: const Icon(
        CupertinoIcons.back,
        color: Colors.black,
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size(double.maxFinite, 120);
}
