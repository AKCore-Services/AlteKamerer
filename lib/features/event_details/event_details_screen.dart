// -----------------------------------------------------------------------------
// event_details_screen.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Displays event information and provides access to member registration.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../fika/fika_section.dart';
import 'event_details.dart';
import 'event_details_controller.dart';

/// Displays details for an event loaded by [EventDetailsController].
///
/// Loads the requested event when the screen opens and delegates registration
/// navigation to the callback supplied by the parent application.
class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.controller,
    this.onRegistrationPressed,
  });

  final int eventId;
  final EventDetailsController controller;
  final ValueChanged<EventDetails>? onRegistrationPressed;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) => _buildTitle(context),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return switch (widget.controller.status) {
              EventDetailsStatus.loading => const AkLoadingView(),
              EventDetailsStatus.error => AkErrorView(
                title: l10n.eventLoadFailed,
                message: l10n.eventLoadFailedMessage,
                onRetry: () {
                  widget.controller.load(widget.eventId);
                },
              ),
              EventDetailsStatus.loaded => _buildLoaded(context),
            };
          },
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cachedAt = widget.controller.cachedAt;

    if (!widget.controller.isShowingCachedData || cachedAt == null) {
      return Text(l10n.activity);
    }

    final localCachedAt = cachedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatShortDate(localCachedAt);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(localCachedAt),
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l10n.activity),
          TextSpan(
            text: '  ${l10n.eventCachedTitle(date, time)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLoaded(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = widget.controller.event;

    if (event == null) {
      return AkErrorView(
        title: l10n.eventDisplayFailed,
        message: l10n.eventInfoMissing,
      );
    }

    final fikaAssignment = parseFikaCollection(event.fikaCollection)
        .map((section) => section.backendValue)
        .join(', ');

    return RefreshIndicator(
      onRefresh: () => widget.controller.refresh(widget.eventId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          AkSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.type, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  event.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: l10n.calendarDate,
                  value: _formatDate(event.date),
                ),
                if (event.place.isNotEmpty)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: l10n.calendarPlace,
                    value: event.place,
                  ),
                if (event.halanTime.isNotEmpty)
                  _DetailRow(
                    icon: Icons.schedule,
                    label: l10n.akSignupHalan,
                    value: event.halanTime,
                  ),
                if (event.effectiveThereTime.isNotEmpty)
                  _DetailRow(
                    icon: Icons.schedule,
                    label: l10n.eventOnSite,
                    value: event.effectiveThereTime,
                  ),
                if (event.startsTime.isNotEmpty)
                  _DetailRow(
                    icon: Icons.play_arrow,
                    label: l10n.eventStart,
                    value: event.startsTime,
                  ),
                if (event.playDuration.isNotEmpty)
                  _DetailRow(
                    icon: Icons.timelapse,
                    label: l10n.eventPlayDuration,
                    value: event.playDuration,
                  ),
                if (event.stand.isNotEmpty)
                  _DetailRow(
                    icon: Icons.music_note,
                    label: l10n.eventPerformanceType,
                    value: event.stand,
                  ),
                if (fikaAssignment.isNotEmpty)
                  _DetailRow(
                    icon: Icons.local_cafe_outlined,
                    label: l10n.eventFikaAssignment,
                    value: fikaAssignment,
                  ),
              ],
            ),
          ),
          if (event.description.isNotEmpty ||
              event.internalDescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            AkSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.information,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(event.description),
                  ],
                  if (event.internalDescription.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.internalInformation,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(event.internalDescription),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _RegistrationCard(
            event: event,
            isShowingCachedData: widget.controller.isShowingCachedData,
            onPressed:
                widget.controller.isShowingCachedData ||
                    widget.onRegistrationPressed == null
                ? null
                : () {
                    widget.onRegistrationPressed!(event);
                  },
          ),
          if (event.attendees.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AttendeeCard(event: event),
          ],
        ],
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

    return '$day/$month/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final useLargeTextLayout = MediaQuery.textScalerOf(context).scale(1) >= 1.3;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: useLargeTextLayout
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(value, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                SizedBox(
                  width: 76,
                  child: Text(label, style: textTheme.labelLarge),
                ),
                Expanded(child: Text(value, style: textTheme.bodyMedium)),
              ],
            ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({
    required this.event,
    required this.isShowingCachedData,
    required this.onPressed,
  });

  final EventDetails event;
  final bool isShowingCachedData;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = event.signupState;
    final stateLabel = _signupStateLabel(l10n, state);

    return AkSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.eventRegistration,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            state == null || state.isEmpty
                ? l10n.notRegistered
                : l10n.yourStatus(stateLabel),
          ),
          if (!event.registrationAvailable) ...[
            const SizedBox(height: 16),
            Text(
              event.disabled
                  ? l10n.registrationClosed
                  : l10n.registrationUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            if (isShowingCachedData) ...[
              const SizedBox(height: 16),
              Text(
                l10n.registrationRequiresOnline,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPressed,
              child: Text(
                event.isRegistered ? l10n.changeRegistration : l10n.signUp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendeeCard extends StatelessWidget {
  const _AttendeeCard({required this.event});

  final EventDetails event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attending = event.attendees
        .where((attendee) => attendee.where != 'Kan inte komma')
        .toList();
    final notAttending = event.attendees
        .where((attendee) => attendee.where == 'Kan inte komma')
        .toList();

    final grouped = <String?, List<EventAttendee>>{};
    for (final attendee in attending) {
      grouped.putIfAbsent(attendee.instrumentName, () => []).add(attendee);
    }

    return AkSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.eventAttendees,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.registrationCounts(event.coming, event.notComing),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (attending.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.registrationAttending,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            for (final entry in grouped.entries) ...[
              _AttendeeGroup(instrumentName: entry.key, attendees: entry.value),
              if (entry.key != grouped.keys.last) const SizedBox(height: 16),
            ],
          ],
          if (notAttending.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.registrationNotAttending,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < notAttending.length; index++) ...[
              _AttendeeRow(
                attendee: notAttending[index],
                showArrivalDetails: false,
              ),
              if (index != notAttending.length - 1) const Divider(height: 24),
            ],
          ],
        ],
      ),
    );
  }
}

class _AttendeeGroup extends StatelessWidget {
  const _AttendeeGroup({required this.instrumentName, required this.attendees});

  final String? instrumentName;
  final List<EventAttendee> attendees;

  @override
  Widget build(BuildContext context) {
    final label = _instrumentLabel(
      AppLocalizations.of(context),
      instrumentName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label · ${attendees.length}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < attendees.length; index++) ...[
          _AttendeeRow(attendee: attendees[index], showArrivalDetails: true),
          if (index != attendees.length - 1) const Divider(height: 24),
        ],
      ],
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({
    required this.attendee,
    required this.showArrivalDetails,
  });

  final EventAttendee attendee;
  final bool showArrivalDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final instrument = _instrumentLabel(l10n, attendee.instrumentName);
    final practicalDetails = _attendeeDetails(l10n, attendee);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attendee.personName.replaceAll("\\", ""),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(instrument, style: Theme.of(context).textTheme.bodyMedium),
        if (showArrivalDetails && practicalDetails.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(practicalDetails, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (attendee.comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(attendee.comment, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

String _attendeeDetails(AppLocalizations l10n, EventAttendee attendee) {
  final details = <String>[];

  if (attendee.where != null && attendee.where!.isNotEmpty) {
    details.add(_signupStateLabel(l10n, attendee.where));
  }

  if (!attendee.instrument) {
    details.add(l10n.needsInstrumentTransport);
  }

  if (attendee.car) {
    details.add(l10n.hasCar);
  }

  return details.join(' · ');
}

String _instrumentLabel(AppLocalizations l10n, String? instrumentName) {
  return switch (instrumentName) {
    'Altsax' => l10n.akInstrumentAltsax,
    'Balett' => l10n.akInstrumentBalett,
    'Banjo' => l10n.akInstrumentBanjo,
    'Barytonsax' => l10n.akInstrumentBarytonsax,
    'Dragspel' => l10n.akInstrumentDragspel,
    'Euphonium' => l10n.akInstrumentEuphonium,
    'Flöjt' => l10n.akInstrumentFlojt,
    'Horn' => l10n.akInstrumentHorn,
    'Klarinett' => l10n.akInstrumentKlarinett,
    'Oboe' => l10n.akInstrumentOboe,
    'Slagverk' => l10n.akInstrumentSlagverk,
    'Tenorsax' => l10n.akInstrumentTenorsax,
    'Trombon' => l10n.akInstrumentTrombon,
    'Trumpet' => l10n.akInstrumentTrumpet,
    'Tuba' => l10n.akInstrumentTuba,
    null => l10n.akSignupNoInstrument,
    '' => l10n.akSignupNoInstrument,
    _ => instrumentName,
  };
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
