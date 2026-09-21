import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../notifications/notification_sync_service.dart';
import 'reminder_preferences.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({
    super.key,
    required this.reminderPreferences,
    required this.notificationSync,
  });

  final ReminderPreferences reminderPreferences;
  final NotificationSync notificationSync;

  @override
  State<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final List<_ReminderEditor> _reminders = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  String? _validationMessage;
  String? _statusMessage;

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

      _replaceReminders(
        offsets.map(_ReminderEditor.fromDuration).toList(),
      );

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

  void _addReminder() {
    setState(() {
      _validationMessage = null;
      _statusMessage = null;
      _reminders.add(
        _ReminderEditor(
          amount: 1,
          unit: _ReminderUnit.hours,
        ),
      );
    });
  }

  void _removeReminder(int index) {
    setState(() {
      _validationMessage = null;
      _statusMessage = null;
      _reminders.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    final offsets = <Duration>[];

    for (final reminder in _reminders) {
      final amount = int.tryParse(reminder.controller.text);

      if (amount == null || amount <= 0) {
        setState(() {
          _validationMessage =
              'Alla påminnelser måste ha en tid som är större än 0.';
          _statusMessage = null;
        });
        return;
      }

      offsets.add(reminder.unit.toDuration(amount));
    }

    final uniqueMinutes = offsets.map((offset) => offset.inMinutes).toSet();

    if (uniqueMinutes.length != offsets.length) {
      setState(() {
        _validationMessage =
            'Två påminnelser kan inte ha samma tid före aktiviteten.';
        _statusMessage = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _validationMessage = null;
      _statusMessage = null;
    });

    try {
      await widget.reminderPreferences.setReminderOffsets(offsets);
      await widget.notificationSync.sync();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _statusMessage = 'Påminnelser sparade.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _statusMessage = 'Påminnelserna kunde inte sparas. Försök igen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AkLoadingView();
    }

    if (_loadFailed) {
      return AkErrorView(
        title: 'Kunde inte läsa inställningarna',
        message: 'Påminnelseinställningarna kunde inte läsas.',
        onRetry: _load,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AkSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Påminnelser',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Välj hur lång tid före en aktivitet du vill bli påmind.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_reminders.isEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Inga påminnelser är aktiverade.',
                ),
              ],
              for (var index = 0; index < _reminders.length; index++) ...[
                const SizedBox(height: 16),
                _ReminderRow(
                  key: ValueKey(_reminders[index]),
                  reminder: _reminders[index],
                  enabled: !_isSaving,
                  onChanged: () {
                    setState(() {
                      _validationMessage = null;
                      _statusMessage = null;
                    });
                  },
                  onRemove: () => _removeReminder(index),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _addReminder,
                icon: const Icon(Icons.add),
                label: const Text('Lägg till påminnelse'),
              ),
            ],
          ),
        ),
        if (_validationMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _validationMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (_statusMessage != null) ...[
          const SizedBox(height: 16),
          Text(_statusMessage!),
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
              : const Text('Spara inställningar'),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: reminder.controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tid före'),
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<_ReminderUnit>(
            initialValue: reminder.unit,
            decoration: const InputDecoration(labelText: 'Enhet'),
            items: const [
              DropdownMenuItem(
                value: _ReminderUnit.minutes,
                child: Text('Minuter'),
              ),
              DropdownMenuItem(
                value: _ReminderUnit.hours,
                child: Text('Timmar'),
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
          tooltip: 'Ta bort påminnelse',
          onPressed: enabled ? onRemove : null,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _ReminderEditor {
  _ReminderEditor({
    required int amount,
    required this.unit,
  }) : controller = TextEditingController(text: amount.toString());

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