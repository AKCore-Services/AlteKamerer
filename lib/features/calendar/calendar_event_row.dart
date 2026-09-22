import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

import 'calendar_event.dart';

class CalendarEventRow extends StatelessWidget {
  const CalendarEventRow({super.key, required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 54,
              child: Text(_formatDate(event.date), style: textTheme.bodyMedium),
            ),
            SizedBox(
              width: 54,
              child: Text(event.displayTime, style: textTheme.bodyMedium),
            ),
            SizedBox(
              width: 92,
              child: Text(
                event.type,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                event.place,
                style: textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _RegistrationIndicator(event: event),
          ],
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
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
