import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';

class ScreenTopBackgroundContainerNoRadius extends StatelessWidget {
  final Widget? child;
  final double? heightPercentage;
  final EdgeInsets? padding;
  const ScreenTopBackgroundContainerNoRadius({
    Key? key,
    this.child,
    this.heightPercentage,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          EdgeInsets.only(
            top: MediaQuery.of(context).padding.top +
                Utils.screenContentTopPadding,
          ),
      alignment: Alignment.topCenter,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height *
          (heightPercentage ?? Utils.appBarBiggerHeightPercentage),
      decoration: BoxDecoration(
        color: Utils.getColorScheme(context).primary,
        borderRadius: const BorderRadius.only(
          // bottomLeft: Radius.circular(25),
          // bottomRight: Radius.circular(25),
        ),
      ),
      child: child,
    );
  }
}
