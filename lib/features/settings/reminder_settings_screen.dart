import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/diagnostics/diagnostic_entry.dart';
import '../../core/diagnostics/diagnostics_service.dart';
import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_sync_service.dart';
import 'calendar_display_controller.dart';
import 'calendar_display_preferences.dart';
import 'locale_controller.dart';
import 'locale_preferences.dart';
import 'reminder_preferences.dart';
import 'settings_backup.dart';
import 'settings_backup_file_service.dart';
import 'settings_backup_service.dart';

typedef AppVersionLoader = Future<String> Function();
typedef DiagnosticsMetadataLoader = Future<DiagnosticsMetadata> Function();
typedef DiagnosticClipboardWriter = Future<void> Function(String text);
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class DiagnosticsMetadata {
  const DiagnosticsMetadata({
    required this.version,
    required this.buildNumber,
    required this.platform,
  });

  final String version;
  final String buildNumber;
  final String platform;
}

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({
    super.key,
    required this.reminderPreferences,
    required this.notificationSync,
    required this.localeController,
    required this.calendarDisplayController,
    required this.settingsBackupService,
    required this.settingsBackupFileService,
    this.diagnosticsService,
    this.apiServer,
    this.diagnosticsMetadataLoader,
    this.diagnosticClipboardWriter,
    this.appVersionLoader,
    this.externalUrlLauncher,
  });

  final ReminderPreferences reminderPreferences;
  final NotificationSync notificationSync;
  final LocaleController localeController;
  final CalendarDisplayController calendarDisplayController;
  final SettingsBackupService settingsBackupService;
  final SettingsBackupFileService settingsBackupFileService;
  final DiagnosticsService? diagnosticsService;
  final String? apiServer;
  final DiagnosticsMetadataLoader? diagnosticsMetadataLoader;
  final DiagnosticClipboardWriter? diagnosticClipboardWriter;
  final AppVersionLoader? appVersionLoader;
  final ExternalUrlLauncher? externalUrlLauncher;

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final List<_ReminderEditor> _reminders = [];

  bool _languageExpanded = true;
  bool _calendarDisplayExpanded = true;
  bool _remindersExpanded = true;
  bool _backupExpanded = false;
  bool _diagnosticsExpanded = false;
  bool _aboutExpanded = false;
  Future<String>? _appVersion;
  Future<_DiagnosticsViewData>? _diagnostics;
  _DiagnosticsStatus? _diagnosticsStatus;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isBackupBusy = false;
  bool _loadFailed = false;
  _ReminderValidation? _validation;
  _ReminderSaveStatus? _saveStatus;
  _SettingsBackupStatus? _backupStatus;

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

  Future<String> _loadAppVersion() async {
    final loader = widget.appVersionLoader;
    if (loader != null) {
      return loader();
    }

    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<DiagnosticsMetadata> _loadDiagnosticsMetadata() async {
    final loader = widget.diagnosticsMetadataLoader;
    if (loader != null) {
      return loader();
    }

    final packageInfo = await PackageInfo.fromPlatform();

    final platformName = Platform.operatingSystem == 'android'
        ? 'Android'
        : Platform.operatingSystem;

    return DiagnosticsMetadata(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platform: '$platformName ${Platform.operatingSystemVersion}'.trim(),
    );
  }

  Future<_DiagnosticsViewData> _loadDiagnostics() async {
    final service = widget.diagnosticsService;
    final metadata = await _loadDiagnosticsMetadata();

    return _DiagnosticsViewData(
      metadata: metadata,
      entries: service == null ? const [] : await service.readEntries(),
    );
  }

  void _setDiagnosticsExpanded(bool expanded) {
    setState(() {
      _diagnosticsExpanded = expanded;
      _diagnosticsStatus = null;
      if (expanded) {
        _diagnostics ??= _loadDiagnostics();
      }
    });
  }

  Future<void> _copyDiagnostics() async {
    final service = widget.diagnosticsService;
    if (service == null) {
      return;
    }

    try {
      final data = await _loadDiagnostics();
      final report = service.buildReport(
        version: data.metadata.version,
        buildNumber: data.metadata.buildNumber,
        platform: data.metadata.platform,
        apiServer: widget.apiServer ?? 'Unavailable',
        entries: data.entries,
      );

      final writer = widget.diagnosticClipboardWriter;
      if (writer != null) {
        await writer(report);
      } else {
        await Clipboard.setData(ClipboardData(text: report));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _diagnosticsStatus = _DiagnosticsStatus.copied;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _diagnosticsStatus = _DiagnosticsStatus.copyFailed;
      });
    }
  }

  Future<void> _clearDiagnostics() async {
    final service = widget.diagnosticsService;
    if (service == null) {
      return;
    }

    try {
      await service.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _diagnostics = _loadDiagnostics();
        _diagnosticsStatus = _DiagnosticsStatus.cleared;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _diagnosticsStatus = _DiagnosticsStatus.clearFailed;
      });
    }
  }

  Future<bool> _launchExternalUrl(Uri uri) {
    final launcher = widget.externalUrlLauncher;
    if (launcher != null) {
      return launcher(uri);
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _setAboutExpanded(bool expanded) {
    setState(() {
      _aboutExpanded = expanded;
      if (expanded) {
        _appVersion ??= _loadAppVersion();
      }
    });
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

  Future<void> _exportSettings() async {
    setState(() {
      _isBackupBusy = true;
      _backupStatus = null;
    });

    try {
      final contents = await widget.settingsBackupService.exportSettings();
      final saved = await widget.settingsBackupFileService.save(contents);

      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        if (saved) {
          _backupStatus = _SettingsBackupStatus.exported;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        _backupStatus = _SettingsBackupStatus.exportFailed;
      });
    }
  }

  Future<void> _importSettings() async {
    setState(() {
      _isBackupBusy = true;
      _backupStatus = null;
    });

    String? source;
    try {
      source = await widget.settingsBackupFileService.pick();

      if (source == null) {
        if (mounted) {
          setState(() {
            _isBackupBusy = false;
          });
        }
        return;
      }
    } on SettingsBackupFileFormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        _backupStatus = _SettingsBackupStatus.readFailed;
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        _backupStatus = _SettingsBackupStatus.readFailed;
      });
      return;
    }

    late final SettingsBackup backup;
    try {
      backup = widget.settingsBackupService.validateImport(source);
    } on SettingsBackupUnsupportedVersionException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        _backupStatus = _SettingsBackupStatus.unsupported;
      });
      return;
    } on SettingsBackupFormatException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        _backupStatus = _SettingsBackupStatus.invalid;
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        _backupStatus = _SettingsBackupStatus.invalid;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isBackupBusy = false;
    });

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.confirmSettingsImportTitle),
          content: Text(l10n.confirmSettingsImportDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirmImport),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isBackupBusy = true;
      _backupStatus = null;
    });

    try {
      await widget.settingsBackupService.importSettings(backup);
      await widget.notificationSync.sync();

      final offsets = await widget.reminderPreferences.getReminderOffsets();

      if (!mounted) {
        return;
      }

      _replaceReminders(offsets.map(_ReminderEditor.fromDuration).toList());

      setState(() {
        _isBackupBusy = false;
        _validation = null;
        _saveStatus = null;
        _backupStatus = _SettingsBackupStatus.imported;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackupBusy = false;
        _backupStatus = _SettingsBackupStatus.importFailed;
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

    final backupStatusMessage = switch (_backupStatus) {
      _SettingsBackupStatus.exported => l10n.settingsExported,
      _SettingsBackupStatus.exportFailed => l10n.settingsExportFailed,
      _SettingsBackupStatus.invalid => l10n.settingsImportInvalid,
      _SettingsBackupStatus.unsupported => l10n.settingsImportUnsupported,
      _SettingsBackupStatus.readFailed => l10n.settingsImportReadFailed,
      _SettingsBackupStatus.importFailed => l10n.settingsImportFailed,
      _SettingsBackupStatus.imported => l10n.settingsImported,
      null => null,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsSection(
          title: l10n.language,
          expanded: _languageExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _languageExpanded = expanded;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ListenableBuilder(
          listenable: widget.calendarDisplayController,
          builder: (context, _) {
            final settings = widget.calendarDisplayController.settings;

            return _SettingsSection(
              title: l10n.calendarDisplay,
              expanded: _calendarDisplayExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _calendarDisplayExpanded = expanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    l10n.calendarDisplayDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CalendarDateFormat>(
                    initialValue: settings.dateFormat,
                    decoration: InputDecoration(
                      labelText: l10n.calendarDateFormat,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: CalendarDateFormat.compact,
                        child: Text(l10n.calendarDateFormatCompact),
                      ),
                      DropdownMenuItem(
                        value: CalendarDateFormat.numeric,
                        child: Text(l10n.calendarDateFormatNumeric),
                      ),
                      DropdownMenuItem(
                        value: CalendarDateFormat.written,
                        child: Text(l10n.calendarDateFormatWritten),
                      ),
                    ],
                    onChanged: (format) async {
                      if (format == null) {
                        return;
                      }

                      await widget.calendarDisplayController.setDateFormat(
                        format,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CalendarTimeFormat>(
                    initialValue: settings.timeFormat,
                    decoration: InputDecoration(
                      labelText: l10n.calendarTimeFormat,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: CalendarTimeFormat.twentyFourHour,
                        child: Text(l10n.calendarTimeFormat24Hour),
                      ),
                      DropdownMenuItem(
                        value: CalendarTimeFormat.twelveHour,
                        child: Text(l10n.calendarTimeFormat12Hour),
                      ),
                    ],
                    onChanged: (format) async {
                      if (format == null) {
                        return;
                      }

                      await widget.calendarDisplayController.setTimeFormat(
                        format,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.calendarShowWeekday),
                    subtitle: Text(l10n.calendarShowWeekdayDescription),
                    value: settings.showWeekday,
                    onChanged: widget.calendarDisplayController.setShowWeekday,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: l10n.reminders,
          expanded: _remindersExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _remindersExpanded = expanded;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          Semantics(
            liveRegion: true,
            child: Text(
              validationMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        if (statusMessage != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(statusMessage)),
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
        const SizedBox(height: 16),
        _SettingsSection(
          title: l10n.settingsBackup,
          expanded: _backupExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _backupExpanded = expanded;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.settingsBackupDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isBackupBusy ? null : _exportSettings,
                icon: const Icon(Icons.file_upload_outlined),
                label: Text(l10n.exportSettings),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isBackupBusy ? null : _importSettings,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(l10n.importSettings),
              ),
              if (_isBackupBusy) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
              if (backupStatusMessage != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    backupStatusMessage,
                    style: switch (_backupStatus) {
                      _SettingsBackupStatus.exportFailed ||
                      _SettingsBackupStatus.invalid ||
                      _SettingsBackupStatus.unsupported ||
                      _SettingsBackupStatus.readFailed ||
                      _SettingsBackupStatus.importFailed => TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      _ => null,
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: l10n.diagnostics,
          expanded: _diagnosticsExpanded,
          onExpansionChanged: _setDiagnosticsExpanded,
          child: FutureBuilder<_DiagnosticsViewData>(
            future: _diagnostics,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.diagnosticsUnavailable),
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final statusMessage = switch (_diagnosticsStatus) {
                _DiagnosticsStatus.copied => l10n.diagnosticsCopied,
                _DiagnosticsStatus.copyFailed => l10n.diagnosticsCopyFailed,
                _DiagnosticsStatus.cleared => l10n.diagnosticsCleared,
                _DiagnosticsStatus.clearFailed => l10n.diagnosticsClearFailed,
                null => null,
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _DiagnosticValue(
                    label: l10n.diagnosticsVersion,
                    value: data.metadata.version,
                  ),
                  const SizedBox(height: 12),
                  _DiagnosticValue(
                    label: l10n.diagnosticsBuild,
                    value: data.metadata.buildNumber,
                  ),
                  const SizedBox(height: 12),
                  _DiagnosticValue(
                    label: l10n.diagnosticsPlatform,
                    value: data.metadata.platform,
                  ),
                  const SizedBox(height: 12),
                  _DiagnosticValue(
                    label: l10n.diagnosticsApiServer,
                    value: widget.apiServer ?? l10n.diagnosticsUnavailableValue,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.diagnosticsRecentErrors,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (data.entries.isEmpty)
                    Text(l10n.diagnosticsNoErrors)
                  else
                    for (final entry in data.entries.reversed) ...[
                      Text(
                        '${entry.subsystem}: ${entry.message}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (entry.details case final details?) ...[
                        const SizedBox(height: 4),
                        Text(
                          details,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  OutlinedButton.icon(
                    onPressed: widget.diagnosticsService == null
                        ? null
                        : _copyDiagnostics,
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(l10n.diagnosticsCopyReport),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.diagnosticsService == null
                        ? null
                        : _clearDiagnostics,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.diagnosticsClearLogs),
                  ),
                  if (statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        statusMessage,
                        style:
                            _diagnosticsStatus ==
                                    _DiagnosticsStatus.copyFailed ||
                                _diagnosticsStatus ==
                                    _DiagnosticsStatus.clearFailed
                            ? TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              )
                            : null,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: l10n.about,
          expanded: _aboutExpanded,
          onExpansionChanged: _setAboutExpanded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: _appVersion,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(l10n.aboutVersion(snapshot.data!));
                  }

                  if (snapshot.hasError) {
                    return Text(l10n.aboutVersionUnavailable);
                  }

                  return const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.aboutArchitecture,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.aboutDevelopmentTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.aboutDevelopmentDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _launchExternalUrl(
                  Uri.parse('https://github.com/LudHag/AKCore'),
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.aboutAkCoreRepository),
              ),
              TextButton.icon(
                onPressed: () => _launchExternalUrl(
                  Uri.parse('https://github.com/AKCore-Services/AlteKamerer'),
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.aboutAlteKamererRepository),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiagnosticsViewData {
  const _DiagnosticsViewData({required this.metadata, required this.entries});

  final DiagnosticsMetadata metadata;
  final List<DiagnosticEntry> entries;
}

enum _DiagnosticsStatus { copied, copyFailed, cleared, clearFailed }

class _DiagnosticValue extends StatelessWidget {
  const _DiagnosticValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 2),
        SelectableText(value),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.expanded,
    required this.onExpansionChanged,
    required this.child,
  });

  final String title;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AkSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              onTap: () => onExpansionChanged(!expanded),
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded) child,
        ],
      ),
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

enum _SettingsBackupStatus {
  exported,
  exportFailed,
  invalid,
  unsupported,
  readFailed,
  importFailed,
  imported,
}
