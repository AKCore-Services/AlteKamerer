import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitet')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return switch (widget.controller.status) {
              EventDetailsStatus.loading => const AkLoadingView(),
              EventDetailsStatus.error => AkErrorView(
                title: 'Kunde inte hämta aktiviteten',
                message:
                    'AlteKamerer kunde inte hämta aktiviteten från AKCore.',
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
    final event = widget.controller.event;

    if (event == null) {
      return const AkErrorView(
        title: 'Kunde inte visa aktiviteten',
        message: 'Aktivitetsinformationen saknas.',
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
                label: 'Datum',
                value: _formatDate(event.date),
              ),
              if (event.place.isNotEmpty)
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Plats',
                  value: event.place,
                ),
              if (event.halanTime.isNotEmpty)
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'Hålan',
                  value: event.halanTime,
                ),
              if (event.thereTime.isNotEmpty)
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'På plats',
                  value: event.thereTime,
                ),
              if (event.startsTime.isNotEmpty)
                _DetailRow(
                  icon: Icons.play_arrow,
                  label: 'Start',
                  value: event.startsTime,
                ),
              if (event.playDuration.isNotEmpty)
                _DetailRow(
                  icon: Icons.timelapse,
                  label: 'Speltid',
                  value: event.playDuration,
                ),
              if (event.stand.isNotEmpty)
                _DetailRow(
                  icon: Icons.music_note,
                  label: 'Notställ',
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
                  'Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(event.description),
                ],
                if (event.internalDescription.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Intern information',
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
    final state = event.signupState;

    return AkSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anmälan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(
            state == null || state.isEmpty
                ? 'Du är inte anmäld.'
                : 'Din status: $state',
          ),
          const SizedBox(height: 8),
          Text(
            '${event.coming} kommer · ${event.notComing} kommer inte',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!event.registrationAvailable) ...[
            const SizedBox(height: 16),
            Text(
              event.disabled ? 'Anmälan är stängd för den här aktiviteten.' : 'Det går inte längre att ändra anmälan för den här aktiviteten.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPressed,
              child: Text(event.isRegistered ? 'Ändra anmälan' : 'Anmäl dig'),
            ),
          ],
        ],
      ),
    );
  }
}
