import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:bb_factory_test_app/utils/constants.dart';
import 'package:bb_factory_test_app/utils/enums/store_state.dart';

class StateWidget extends StatelessWidget {
  const StateWidget({
    super.key,
    required this.state,
    required this.data,
  });

  final StoreState state;
  final String data;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case StoreState.LOADING:
        return const SpinKitCircle(
          color: Colors.blueAccent,
        );
      case StoreState.SUCCESS:
        return const SizedBox();
      case StoreState.ERROR:
        return Center(
          child: Text(
            data,
            style: Constants.customTextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case StoreState.EMPTY:
        return Center(
          child: Text(
            data,
            style: Constants.customTextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}
