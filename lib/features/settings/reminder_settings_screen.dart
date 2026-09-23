import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_sync_service.dart';
import 'locale_controller.dart';
import 'locale_preferences.dart';
import 'reminder_preferences.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({
    super.key,
    required this.reminderPreferences,
    required this.notificationSync,
    required this.localeController,
  });

  final ReminderPreferences reminderPreferences;
  final NotificationSync notificationSync;
  final LocaleController localeController;

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final List<_ReminderEditor> _reminders = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  _ReminderValidation? _validation;
  _ReminderSaveStatus? _saveStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final reminder in _reminders) {
      reminder.dispose();
    }

    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final offsets = await widget.reminderPreferences.getReminderOffsets();

      if (!mounted) {
        return;
      }

      _replaceReminders(offsets.map(_ReminderEditor.fromDuration).toList());

      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  void _replaceReminders(List<_ReminderEditor> reminders) {
    for (final reminder in _reminders) {
      reminder.dispose();
    }

    _reminders
      ..clear()
      ..addAll(reminders);
  }

  void _clearMessages() {
    _validation = null;
    _saveStatus = null;
  }

  void _addReminder() {
    setState(() {
      _clearMessages();
      _reminders.add(_ReminderEditor(amount: 1, unit: _ReminderUnit.hours));
    });
  }

  void _removeReminder(int index) {
    setState(() {
      _clearMessages();
      _reminders.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    final offsets = <Duration>[];

    for (final reminder in _reminders) {
      final amount = int.tryParse(reminder.controller.text);

      if (amount == null || amount <= 0) {
        setState(() {
          _validation = _ReminderValidation.positiveTimeRequired;
          _saveStatus = null;
        });
        return;
      }

      offsets.add(reminder.unit.toDuration(amount));
    }

    final uniqueMinutes = offsets.map((offset) => offset.inMinutes).toSet();

    if (uniqueMinutes.length != offsets.length) {
      setState(() {
        _validation = _ReminderValidation.duplicateTime;
        _saveStatus = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _clearMessages();
    });

    try {
      await widget.reminderPreferences.setReminderOffsets(offsets);
      await widget.notificationSync.sync();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveStatus = _ReminderSaveStatus.saved;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveStatus = _ReminderSaveStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const AkLoadingView();
    }

    if (_loadFailed) {
      return AkErrorView(
        title: l10n.settingsLoadFailed,
        message: l10n.reminderSettingsLoadFailed,
        onRetry: _load,
      );
    }

    final validationMessage = switch (_validation) {
      _ReminderValidation.positiveTimeRequired =>
        l10n.reminderPositiveTimeRequired,
      _ReminderValidation.duplicateTime => l10n.duplicateReminderTime,
      null => null,
    };

    final statusMessage = switch (_saveStatus) {
      _ReminderSaveStatus.saved => l10n.remindersSaved,
      _ReminderSaveStatus.failed => l10n.remindersSaveFailed,
      null => null,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AkSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppLocalePreference>(
                initialValue: widget.localeController.preference,
                decoration: InputDecoration(labelText: l10n.language),
                items: [
                  DropdownMenuItem(
                    value: AppLocalePreference.system,
                    child: Text(l10n.systemDefault),
                  ),
                  DropdownMenuItem(
                    value: AppLocalePreference.swedish,
                    child: Text(l10n.swedish),
                  ),
                  DropdownMenuItem(
                    value: AppLocalePreference.english,
                    child: Text(l10n.english),
                  ),
                ],
                onChanged: (preference) async {
                  if (preference == null) {
                    return;
                  }

                  await widget.localeController.setPreference(preference);
                  await widget.notificationSync.sync();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AkSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reminders,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.remindersDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_reminders.isEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.noRemindersEnabled),
              ],
              for (var index = 0; index < _reminders.length; index++) ...[
                const SizedBox(height: 16),
                _ReminderRow(
                  key: ValueKey(_reminders[index]),
                  reminder: _reminders[index],
                  enabled: !_isSaving,
                  onChanged: () {
                    setState(_clearMessages);
                  },
                  onRemove: () => _removeReminder(index),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _addReminder,
                icon: const Icon(Icons.add),
                label: Text(l10n.addReminder),
              ),
            ],
          ),
        ),
        if (validationMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            validationMessage,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (statusMessage != null) ...[
          const SizedBox(height: 16),
          Text(statusMessage),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.saveSettings),
        ),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    super.key,
    required this.reminder,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final _ReminderEditor reminder;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: reminder.controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.reminderTimeBefore),
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<_ReminderUnit>(
            initialValue: reminder.unit,
            decoration: InputDecoration(labelText: l10n.unit),
            items: [
              DropdownMenuItem(
                value: _ReminderUnit.minutes,
                child: Text(l10n.akCountdownMinutes),
              ),
              DropdownMenuItem(
                value: _ReminderUnit.hours,
                child: Text(l10n.akCountdownHours),
              ),
            ],
            onChanged: enabled
                ? (unit) {
                    if (unit == null) {
                      return;
                    }

                    reminder.unit = unit;
                    onChanged();
                  }
                : null,
          ),
        ),
        IconButton(
          tooltip: l10n.removeReminder,
          onPressed: enabled ? onRemove : null,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _ReminderEditor {
  _ReminderEditor({required int amount, required this.unit})
    : controller = TextEditingController(text: amount.toString());

  factory _ReminderEditor.fromDuration(Duration duration) {
    if (duration.inMinutes % 60 == 0) {
      return _ReminderEditor(
        amount: duration.inHours,
        unit: _ReminderUnit.hours,
      );
    }

    return _ReminderEditor(
      amount: duration.inMinutes,
      unit: _ReminderUnit.minutes,
    );
  }

  final TextEditingController controller;
  _ReminderUnit unit;

  void dispose() {
    controller.dispose();
  }
}

enum _ReminderUnit {
  minutes,
  hours;

  Duration toDuration(int amount) {
    return switch (this) {
      _ReminderUnit.minutes => Duration(minutes: amount),
      _ReminderUnit.hours => Duration(hours: amount),
    };
  }
}

enum _ReminderValidation { positiveTimeRequired, duplicateTime }

enum _ReminderSaveStatus { saved, failed }
