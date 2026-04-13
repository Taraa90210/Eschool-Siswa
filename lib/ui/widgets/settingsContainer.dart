import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/notificationSettingsCubit.dart';
import 'package:eschool/data/repositories/settingsRepository.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/logoutButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsContainer extends StatefulWidget {
  const SettingsContainer({Key? key}) : super(key: key);

  @override
  State<SettingsContainer> createState() => _SettingsContainerState();
}

class _SettingsContainerState extends State<SettingsContainer> {
  String appVersion = "";

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
    });
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Title
                Text(
                  "Kontak & Dukungan",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Hubungi tim support dan lihat riwayat pesan Anda",
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Options
                _buildContactOption(
                  context,
                  icon: Icons.add_circle_outline,
                  title: "Hubungi Support",
                  subtitle: "Kirim pertanyaan atau laporkan masalah aplikasi",
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(Routes.submitContact);
                  },
                ),

                // Show history for all users (students and parents)
                _buildContactOption(
                  context,
                  icon: Icons.history,
                  title: "Riwayat Pesan",
                  subtitle: "Lihat pesan dan balasan dari support",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(Routes.contacts);
                  },
                ),

                // Info for all users
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'Tim support kami siap membantu Anda. Balasan akan muncul di riwayat pesan dalam 1-2 hari kerja.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 12.0,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: color.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BlocProvider(
          create: (context) => NotificationSettingsCubit(SettingsRepository()),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Title
                  Text(
                    Utils.getTranslatedLabel(notificationSettingsKey),
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    Utils.getTranslatedLabel(notificationSettingsDescKey),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Notification Settings
                  BlocBuilder<NotificationSettingsCubit,
                      NotificationSettingsState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          _buildSettingToggleTile(
                            icon: Icons.vibration,
                            title: Utils.getTranslatedLabel(allowVibrationKey),
                            subtitle: "Getaran saat menerima notifikasi",
                            value: state.allowVibration,
                            onChanged: (value) {
                              context
                                  .read<NotificationSettingsCubit>()
                                  .changeVibration(value);
                            },
                            context: context,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24.0),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20.0,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Pengaturan ini berlaku untuk semua notifikasi aplikasi kecuali notifikasi keamanan ujian.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 12.0,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppbar(BuildContext context) {
    bool isparent = context.read<AuthCubit>().isParent();
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 10,
              top: -2,
              child: isparent ? const CustomBackButton() : const SizedBox(),
            ),
            Text(
              Utils.getTranslatedLabel(settingsKey),
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required BuildContext context,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: 10,
        top: 10,
        start: MediaQuery.of(context).size.width * (0.075),
        end: MediaQuery.of(context).size.width * (0.075),
      ),
      child: DecoratedBox(
        decoration:
            BoxDecoration(border: Border.all(color: Colors.transparent)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingDetailsTile({
    required String title,
    required Function onTap,
    required BuildContext context,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: 10,
          top: 10,
          start: MediaQuery.of(context).size.width * (0.075),
          end: MediaQuery.of(context).size.width * (0.075),
        ),
        child: DecoratedBox(
          decoration:
              BoxDecoration(border: Border.all(color: Colors.transparent)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(BuildContext context) {
    return Column(
      children: [
        _buildSettingDetailsTile(
          icon: Icons.notifications,
          title: Utils.getTranslatedLabel(notificationSettingsKey),
          onTap: () {
            _showNotificationSettings(context);
          },
          context: context,
        ),
        _buildSettingDetailsTile(
          icon: Icons.password,
          title: Utils.getTranslatedLabel(changePasswordKey),
          onTap: () {
            Get.toNamed(Routes.changePassword)?.then((value) {
              if (value != null && !value['error']) {
                Utils.showCustomSnackBar(
                  context: context,
                  errorMessage: Utils.getTranslatedLabel(
                    passwordChangedSuccessfullyKey,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                );
              }
            });
          },
          context: context,
        ),
        _buildSettingDetailsTile(
          icon: Icons.contacts,
          title: "Kontak & Dukungan",
          onTap: () {
            _showContactOptions(context);
          },
          context: context,
        ),
        _buildSettingDetailsTile(
          icon: Icons.privacy_tip,
          title: Utils.getTranslatedLabel(privacyPolicyKey),
          onTap: () {
            Get.toNamed(Routes.privacyPolicy);
          },
          context: context,
        ),
        _buildSettingDetailsTile(
          icon: Icons.description,
          title: Utils.getTranslatedLabel(termsAndConditionKey),
          onTap: () {
            Get.toNamed(Routes.termsAndCondition);
          },
          context: context,
        ),
        _buildSettingDetailsTile(
          icon: Icons.info,
          title: Utils.getTranslatedLabel(aboutUsKey),
          onTap: () {
            Get.toNamed(Routes.aboutUs);
          },
          context: context,
        ),
        _buildSettingDetailsTile(
          icon: Icons.contact_support,
          title: Utils.getTranslatedLabel(contactUsKey),
          onTap: () {
            Get.toNamed(Routes.contactUs);
          },
          context: context,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(
              bottom: Utils.getScrollViewBottomPadding(context),
              top: Utils.getScrollViewTopPadding(
                      context: context,
                      appBarHeightPercentage:
                          Utils.appBarSmallerHeightPercentage) -
                  10, //10 is the top padding of first item
            ),
            child: Column(
              children: [
                _buildSettingsContainer(context),
                const SizedBox(
                  height: 25.0,
                ),
                const LogoutButton(),
                const SizedBox(
                  height: 10.0,
                ),
                Text(
                  "${Utils.getTranslatedLabel(appVersionKey)} $appVersion",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.0,
                  ),
                  textAlign: TextAlign.start,
                ),
                //extra height to avoide dashboard's bottom navigationbar
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      Utils.bottomNavigationHeightPercentage,
                ),
              ],
            ),
          ),
        ),
        _buildAppbar(context),
      ],
    );
  }
}
