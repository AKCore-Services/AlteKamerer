import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import 'event_details.dart';
import 'event_details_controller.dart';

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
      appBar: AppBar(title: Text(l10n.activity)),
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

  Widget _buildLoaded(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = widget.controller.event;

    if (event == null) {
      return AkErrorView(
        title: l10n.eventDisplayFailed,
        message: l10n.eventInfoMissing,
      );
    }

    return ListView(
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
              if (event.thereTime.isNotEmpty)
                _DetailRow(
                  icon: Icons.schedule,
                  label: l10n.eventOnSite,
                  value: event.thereTime,
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
                  label: l10n.eventMusicStand,
                  value: event.stand,
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
          onPressed: widget.onRegistrationPressed == null
              ? null
              : () {
                  widget.onRegistrationPressed!(event);
                },
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.event, required this.onPressed});

  final EventDetails event;
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
          const SizedBox(height: 8),
          Text(
            l10n.registrationCounts(event.coming, event.notComing),
            style: Theme.of(context).textTheme.bodySmall,
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

String _signupStateLabel(AppLocalizations l10n, String? signupState) {
  return switch (signupState) {
    'Hålan' => l10n.akSignupHalan,
    'Direkt' => l10n.akSignupDirect,
    'Kan inte komma' => l10n.akSignupCantCome,
    null => '',
    _ => signupState,
  };
}
