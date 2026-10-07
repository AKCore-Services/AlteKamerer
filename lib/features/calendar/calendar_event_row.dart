// -----------------------------------------------------------------------------
// calendar_event_row.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Displays a calendar event with localized times and registration status.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../fika/fika_section.dart';
import '../settings/calendar_display_preferences.dart';
import 'calendar_display_formatter.dart';
import 'calendar_event.dart';

/// Displays a calendar event and the member's registration status.
///
/// Formats dates and times using the current display preferences, and
/// switches to a stacked layout when larger text scaling requires it.
class CalendarEventRow extends StatelessWidget {
  const CalendarEventRow({
    super.key,
    required this.event,
    required this.displaySettings,
    this.memberFikaSections = const {},
    required this.onTap,
  });

  final CalendarEvent event;
  final CalendarDisplaySettings displaySettings;
  final Set<FikaSection> memberFikaSections;
  final VoidCallback onTap;

  static const fikaColumnWidth = 40.0;
  static const _formatter = CalendarDisplayFormatter();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = _formatter.formatDate(
      event.date,
      locale: locale,
      settings: displaySettings,
    );
    final formattedTime = _formatter.formatTime(
      event.displayTime,
      locale: locale,
      settings: displaySettings,
    );
    final useStackedLayout = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final showFikaColumn =
        displaySettings.fikaVisibility != FikaVisibility.dontShow;
    final assignedFikaSections = parseFikaCollection(event.fikaCollection);
    final visibleFikaSections = switch (displaySettings.fikaVisibility) {
      FikaVisibility.dontShow => const <FikaSection>{},
      FikaVisibility.mySection => {
        for (final section in assignedFikaSections)
          if (memberFikaSections.contains(section)) section,
      },
      FikaVisibility.all => assignedFikaSections,
    };
    final fikaText = visibleFikaSections
        .map(displaySettings.fikaEmojiFor)
        .join();

    final dateWidth = switch (displaySettings.dateFormat) {
      CalendarDateFormat.compact => displaySettings.showWeekday ? 82.0 : 54.0,
      CalendarDateFormat.numeric => displaySettings.showWeekday ? 108.0 : 82.0,
      CalendarDateFormat.written => displaySettings.showWeekday ? 128.0 : 104.0,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: useStackedLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarEventField(
                    label: l10n.calendarDate,
                    value: formattedDate,
                  ),
                  _CalendarEventField(
                    label: l10n.calendarTime,
                    value: formattedTime,
                  ),
                  _CalendarEventField(
                    label: l10n.calendarType,
                    value: event.type,
                  ),
                  if (event.place.isNotEmpty)
                    _CalendarEventField(
                      label: l10n.calendarPlace,
                      value: event.place,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (showFikaColumn) ...[
                        SizedBox(
                          width: fikaColumnWidth,
                          child: Text(
                            fikaText,
                            key: ValueKey('calendar-fika-${event.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _RegistrationIndicator(event: event),
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: dateWidth,
                    child: Text(
                      formattedDate,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 54,
                    child: Text(formattedTime, style: textTheme.bodyMedium),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      event.type,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      event.place,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showFikaColumn)
                    SizedBox(
                      width: fikaColumnWidth,
                      child: Text(
                        fikaText,
                        key: ValueKey('calendar-fika-${event.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _RegistrationIndicator(event: event),
                ],
              ),
      ),
    );
  }
}

class _CalendarEventField extends StatelessWidget {
  const _CalendarEventField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationIndicator extends StatelessWidget {
  const _RegistrationIndicator({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (event.isAttending) {
      return Tooltip(
        message:
            '${l10n.akUpcomingSignedUp}: '
            '${_signupStateLabel(l10n, event.signupState)}',
        child: Semantics(
          label: l10n.registeredAttending,
          child: const Icon(Icons.check_circle, color: Colors.green),
        ),
      );
    }

    if (event.isRegisteredNotAttending) {
      return Tooltip(
        message:
            '${l10n.akUpcomingSignedUp}: '
            '${_signupStateLabel(l10n, event.signupState)}',
        child: Semantics(
          label: l10n.registeredNotAttending,
          child: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    return Tooltip(
      message: l10n.notRegistered,
      child: Semantics(
        label: l10n.notRegistered,
        child: Icon(
          Icons.radio_button_unchecked,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}

String _signupStateLabel(AppLocalizations l10n, String? signupState) {
  return switch (signupState) {
    'Hålan' => l10n.akSignupHalan,
    'Direkt' => l10n.akSignupDirect,
    'Kan inte komma' => l10n.akSignupCantCome,
    null => '',
    _ => signupState,
  };
}
