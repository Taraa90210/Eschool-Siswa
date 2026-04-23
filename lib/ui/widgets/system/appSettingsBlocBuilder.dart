import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:eschool/cubits/system/appSettingsCubit.dart';
import 'package:eschool/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/utils/system/utils.dart';

String generateRandomString(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
}

String parseCustomHtml(String input) {
  String placeholderBold = generateRandomString(10);
  String placeholderItalic = generateRandomString(10);

  while (placeholderItalic == placeholderBold) {
    placeholderItalic = generateRandomString(10);
    placeholderBold = generateRandomString(10);
  }

  input = input
               .replaceAll('\\*', placeholderBold)
               .replaceAll('\\/', placeholderItalic);

  bool isBold = false;
  bool isItalic = false;
  String output = '';

  for (int i = 0; i < input.length; i++) {
    if (input[i] == '*') {
      isBold = !isBold;
      output += isBold ? '<b>' : '</b>';
    } else if (input[i] == '/') {
      isItalic = !isItalic;
      output += isItalic ? '<i>' : '</i>';
    } else {
      output += input[i];
    }
  }

  output = output.replaceAll(placeholderBold, '*')
                 .replaceAll(placeholderItalic, '/')
                 .replaceAll("\n", "<br/>");

  return output;
}

class AppSettingsBlocBuilder extends StatelessWidget {
  final String appSettingsType;

  const AppSettingsBlocBuilder({Key? key, required this.appSettingsType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, state) {
        if (state is AppSettingsFetchSuccess) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height *
                  (Utils.appBarSmallerHeightPercentage + 0.025),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: HtmlWidget(parseCustomHtml(state.appSettingsResult)),
                ),
              ],
            ),
          );
        }
        if (state is AppSettingsFetchFailure) {
          return Center(
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: () {
                context.read<AppSettingsCubit>().fetchAppSettings(type: appSettingsType);
              },
            ),
          );
        }
        return Center(
          child: CustomCircularProgressIndicator(
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}