import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/student/guardianPhotoCubit.dart';
import 'package:eschool/data/repositories/auth/guardianProfileRepository.dart';
import 'package:eschool/ui/widgets/system/customAppbar.dart';
import 'package:eschool/ui/widgets/student/guardianDetailsContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return const ParentProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * (0.05),
                  ),
                  BlocProvider(
                    create: (_) =>
                        GuardianPhotoCubit(GuardianProfileRepository()),
                    child: GuardianDetailsContainer(
                      guardian: context.read<AuthCubit>().getParentDetails(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: Utils.getTranslatedLabel(profileKey),
            ),
          ),
        ],
      ),
    );
  }
}
