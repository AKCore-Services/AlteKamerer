import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import 'calendar_controller.dart';
import 'calendar_event.dart';
import 'calendar_event_row.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.controller,
    required this.onOpenEvent,
    required this.onRefresh,
  });

  final CalendarController controller;
  final ValueChanged<CalendarEvent> onOpenEvent;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context);

        return switch (controller.status) {
          CalendarStatus.loading => const AkLoadingView(),
          CalendarStatus.error => AkErrorView(
            title: l10n.calendarLoadFailed,
            message: l10n.calendarLoadFailedMessage,
            onRetry: onRefresh,
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

    final events = controller.visibleEvents;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalendarViewSelector(controller: controller),
          if (controller.view == CalendarView.week ||
              controller.view == CalendarView.month) ...[
            const SizedBox(height: 12),
            _CalendarPeriodNavigation(controller: controller),
          ],
          const SizedBox(height: 16),
          if (events.isEmpty)
            const _EmptyCalendarView()
          else
            AkSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _CalendarHeader(),
                  const Divider(height: 1),
                  for (var index = 0; index < events.length; index++) ...[
                    CalendarEventRow(
                      event: events[index],
                      onTap: () {
                        onOpenEvent(events[index]);
                      },
                    ),
                    if (index != events.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarViewSelector extends StatelessWidget {
  const _CalendarViewSelector({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<CalendarView>(
        segments: [
          ButtonSegment(
            value: CalendarView.upcoming,
            label: Text(l10n.calendarViewUpcoming),
          ),
          ButtonSegment(
            value: CalendarView.today,
            label: Text(l10n.calendarViewToday),
          ),
          ButtonSegment(
            value: CalendarView.week,
            label: Text(l10n.calendarViewWeek),
          ),
          ButtonSegment(
            value: CalendarView.month,
            label: Text(l10n.calendarViewMonth),
          ),
        ],
        selected: {controller.view},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          controller.setView(selection.single);
        },
      ),
    );
  }
}

class _CalendarPeriodNavigation extends StatelessWidget {
  const _CalendarPeriodNavigation({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        IconButton(
          tooltip: controller.view == CalendarView.week
              ? l10n.calendarPreviousWeek
              : l10n.calendarPreviousMonth,
          onPressed: controller.canShowPreviousPeriod
              ? controller.showPreviousPeriod
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _periodLabel(context),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: controller.showCurrentPeriod,
                child: Text(l10n.calendarCurrentPeriod),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: controller.view == CalendarView.week
              ? l10n.calendarNextWeek
              : l10n.calendarNextMonth,
          onPressed: controller.showNextPeriod,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  String _periodLabel(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final focusedDate = controller.focusedDate;

    return switch (controller.view) {
      CalendarView.week => _weekLabel(material, focusedDate),
      CalendarView.month => material.formatMonthYear(focusedDate),
      CalendarView.upcoming || CalendarView.today => '',
    };
  }

  String _weekLabel(MaterialLocalizations material, DateTime focusedDate) {
    final monday = focusedDate.subtract(
      Duration(days: focusedDate.weekday - DateTime.monday),
    );
    final sunday = monday.add(const Duration(days: 6));

    return '${material.formatShortDate(monday)}'
        ' – ${material.formatShortDate(sunday)}';
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 54, child: Text(l10n.calendarDate, style: style)),
          SizedBox(width: 54, child: Text(l10n.calendarTime, style: style)),
          SizedBox(width: 92, child: Text(l10n.calendarType, style: style)),
          Expanded(child: Text(l10n.calendarPlace, style: style)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _EmptyCalendarView extends StatelessWidget {
  const _EmptyCalendarView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          l10n.calendarNoActivitiesInView,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyCalendar extends StatelessWidget {
  const _EmptyCalendar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.noUpcomingActivities,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyCalendar,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
