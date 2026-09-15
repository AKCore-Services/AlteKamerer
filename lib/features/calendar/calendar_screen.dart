import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import 'calendar_controller.dart';
import 'calendar_event.dart';
import 'calendar_event_row.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.controller,
    required this.onOpenEvent,
  });

  final CalendarController controller;
  final ValueChanged<CalendarEvent> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return switch (controller.status) {
          CalendarStatus.loading => const AkLoadingView(),
          CalendarStatus.error => AkErrorView(
            title: 'Kunde inte hämta kalendern',
            message: 'AlteKamerer kunde inte hämta kommande aktiviteter från AKCore.',
            onRetry: controller.load,
          ),
          CalendarStatus.loaded => _buildLoaded(context),
        };
      },
    );
  }

  Widget _buildLoaded(BuildContext context) {
    if (controller.events.isEmpty) {
      return const _EmptyCalendar();
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AkSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _CalendarHeader(),
                const Divider(height: 1),
                for (
                  var index = 0;
                  index < controller.events.length;
                  index++
                ) ...[
                  CalendarEventRow(
                    event: controller.events[index],
                    onTap: () {
                      onOpenEvent(controller.events[index]);
                    },
                  ),
                  if (index != controller.events.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 54, child: Text('Datum', style: style)),
          SizedBox(width: 54, child: Text('Tid', style: style)),
          SizedBox(width: 92, child: Text('Typ', style: style)),
          Expanded(child: Text('Plats', style: style)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _EmptyCalendar extends StatelessWidget {
  const _EmptyCalendar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available, size: 48),
            const SizedBox(height: 16),
            Text(
              'Inga kommande aktiviteter',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Det finns inga aktiviteter i kalendern just nu.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
