import 'package:eschool/ui/widgets/system/customTextContainer.dart';
// import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final String buttonTextKey;
  final Function()? onTapButton;
  final TextStyle? textStyle;
  final Icon? icon;
  const CustomTextButton(
      {super.key,
      required this.buttonTextKey,
      required this.onTapButton,
      this.textStyle,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapButton,
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: Colors.transparent)),
        child: Row(
          mainAxisSize: MainAxisSize.min, // To keep the button size minimal
          children: [
            if (icon != null) icon!, // Show the icon if it's not null
            const SizedBox(
                width: 5), // Add some space between the icon and text
            CustomTextContainer(
              textKey: buttonTextKey,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}