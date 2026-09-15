import 'package:flutter/material.dart';

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
    if (event.isAttending) {
      return Tooltip(
        message: 'Anmäld: ${event.signupState}',
        child: Semantics(
          label: 'Anmäld och kommer',
          child: Icon(Icons.check_circle, color: Colors.green),
        ),
      );
    }

    if (event.isRegisteredNotAttending) {
      return Tooltip(
        message: 'Anmäld: Kan inte komma',
        child: Semantics(
          label: 'Anmäld men kommer inte',
          child: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    return Tooltip(
      message: 'Inte anmäld',
      child: Semantics(
        label: 'Inte anmäld',
        child: Icon(
          Icons.radio_button_unchecked,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}
