import 'package:eschool/data/repositories/system/settingsRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsState {
  final bool allowVibration;
  NotificationSettingsState(this.allowVibration);
}

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  final SettingsRepository _settingsRepository;
  NotificationSettingsCubit(this._settingsRepository)
      : super(NotificationSettingsState(
            _settingsRepository.getAllowVibration(),),);

  void changeVibration(bool value) {
    _settingsRepository.setAllowVibration(value);
    emit(NotificationSettingsState(value));
  }
}
