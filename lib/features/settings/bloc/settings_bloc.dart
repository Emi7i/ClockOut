import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_settings.dart';
import '../../../domain/repositories/user_settings_repository.dart';
import '../../../domain/repositories/log_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Maximum number of distinct recently-picked accent colours to remember.
const int _maxRecentColors = 5;

/// ─────────────────────────────────────────────────────────────
///  SETTINGS BLOC
///  Manages accent colour, clock format, alarm delay, log deletion.
/// ─────────────────────────────────────────────────────────────
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final UserSettingsRepository _settingsRepo;
  final LogRepository          _logRepo;

  SettingsBloc({
    required UserSettingsRepository settingsRepo,
    required LogRepository          logRepo,
  })  : _settingsRepo = settingsRepo,
        _logRepo      = logRepo,
        super(const SettingsLoading()) {
    on<SettingsStarted>       (_onStarted);
    on<AccentColorChanged>    (_onAccentColorChanged);
    on<ClockFormatToggled>    (_onClockFormatToggled);
    on<TimeDelayChanged>      (_onTimeDelayChanged);
    on<DeleteAllLogsConfirmed>(_onDeleteAllLogs);
  }

  Future<void> _onStarted(SettingsStarted _, Emitter<SettingsState> emit) async {
    try {
      final settings = await _settingsRepo.getSettings();
      emit(SettingsLoaded(
        accentColor:       Color(settings.accentColorHex),
        is12HourFormat:    settings.is12HourFormat,
        alarmDelayMinutes: settings.alarmDelayMinutes,
        recentColors:      settings.recentAccentColors.map(Color.new).toList(),
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onAccentColorChanged(
    AccentColorChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state case SettingsLoaded loaded) {
      final updatedRecentHex = _withRecentColor(
        loaded.recentColors.map((c) => c.value).toList(),
        event.color.value,
      );
      final updated = loaded.copyWith(
        accentColor:  event.color,
        recentColors: updatedRecentHex.map(Color.new).toList(),
      );
      emit(updated);
      await _settingsRepo.updateSettings(UserSettings(
        accentColorHex:      updated.accentColor.value,
        is12HourFormat:      updated.is12HourFormat,
        alarmDelayMinutes:   updated.alarmDelayMinutes,
        recentAccentColors:  updatedRecentHex,
      ));
    }
  }

  Future<void> _onClockFormatToggled(
    ClockFormatToggled _,
    Emitter<SettingsState> emit,
  ) async {
    if (state case SettingsLoaded loaded) {
      final updated = loaded.copyWith(is12HourFormat: !loaded.is12HourFormat);
      emit(updated);
      await _settingsRepo.updateSettings(UserSettings(
        accentColorHex:     updated.accentColor.value,
        is12HourFormat:     updated.is12HourFormat,
        alarmDelayMinutes:  updated.alarmDelayMinutes,
        recentAccentColors: updated.recentColors.map((c) => c.value).toList(),
      ));
    }
  }

  Future<void> _onTimeDelayChanged(
    TimeDelayChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state case SettingsLoaded loaded) {
      final updated = loaded.copyWith(alarmDelayMinutes: event.minutes);
      emit(updated);
      await _settingsRepo.updateSettings(UserSettings(
        accentColorHex:     updated.accentColor.value,
        is12HourFormat:     updated.is12HourFormat,
        alarmDelayMinutes:  updated.alarmDelayMinutes,
        recentAccentColors: updated.recentColors.map((c) => c.value).toList(),
      ));
    }
  }

  Future<void> _onDeleteAllLogs(
    DeleteAllLogsConfirmed _,
    Emitter<SettingsState> emit,
  ) async {
    await _logRepo.deleteAllLogs();
  }

  /// Moves [newColorHex] to the front of [current], removing any earlier
  /// occurrence, and caps the result at [_maxRecentColors].
  List<int> _withRecentColor(List<int> current, int newColorHex) {
    final updated = [newColorHex, ...current.where((c) => c != newColorHex)];
    return updated.take(_maxRecentColors).toList();
  }
}
