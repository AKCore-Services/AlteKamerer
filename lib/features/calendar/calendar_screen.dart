// -----------------------------------------------------------------------------
// calendar_screen.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Presents calendar events, date navigation, searching, and filtering.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import '../settings/calendar_display_controller.dart';
import '../settings/calendar_display_preferences.dart';
import 'calendar_controller.dart';
import 'calendar_event.dart';
import 'calendar_event_row.dart';

/// Presents calendar events and the controls used to explore them.
///
/// Observes both calendar data and display settings. Filtering and date
/// selection are delegated to [CalendarController], while event navigation
/// and refreshing are supplied by the parent application.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.controller,
    required this.displayController,
    required this.onOpenEvent,
    required this.onRefresh,
  });

  final CalendarController controller;
  final CalendarDisplayController displayController;
  final ValueChanged<CalendarEvent> onOpenEvent;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, displayController]),
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
          _CalendarToolbar(controller: controller),
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
                  _CalendarHeader(displaySettings: displayController.settings),
                  const Divider(height: 1),
                  for (var index = 0; index < events.length; index++) ...[
                    CalendarEventRow(
                      event: events[index],
                      displaySettings: displayController.settings,
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

class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasActiveFilters =
        controller.eventTypeFilter != null ||
        controller.registrationFilter != CalendarRegistrationFilter.all;

    return Row(
      children: [
        IconButton.outlined(
          key: const ValueKey('calendar-filters-button'),
          tooltip: l10n.calendarFilter,
          onPressed: () => _showFilters(context),
          icon: Icon(
            hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _CalendarViewSelector(controller: controller)),
      ],
    );
  }

  Future<void> _showFilters(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CalendarFilterSheet(controller: controller),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarViewButton(
            label: l10n.calendarViewUpcoming,
            selected: controller.view == CalendarView.upcoming,
            onPressed: () => controller.setView(CalendarView.upcoming),
          ),
          _CalendarViewButton(
            label: l10n.calendarViewToday,
            selected: controller.view == CalendarView.today,
            onPressed: () => controller.setView(CalendarView.today),
          ),
          _CalendarViewButton(
            label: l10n.calendarViewWeek,
            selected: controller.view == CalendarView.week,
            onPressed: () => controller.setView(CalendarView.week),
          ),
          _CalendarViewButton(
            label: l10n.calendarViewMonth,
            selected: controller.view == CalendarView.month,
            onPressed: () => controller.setView(CalendarView.month),
          ),
        ],
      ),
    );
  }
}

class _CalendarViewButton extends StatelessWidget {
  const _CalendarViewButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
        textStyle: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      child: Text(label),
    );
  }
}

class _CalendarSearch extends StatelessWidget {
  const _CalendarSearch({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      key: const ValueKey('calendar-search-field'),
      decoration: InputDecoration(
        labelText: l10n.calendarSearch,
        hintText: l10n.calendarSearchHint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.search,
      onChanged: controller.setSearchQuery,
    );
  }
}

class _CalendarFilterSheet extends StatelessWidget {
  const _CalendarFilterSheet({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.calendarFilter,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _CalendarSearch(controller: controller),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  key: const ValueKey('calendar-activity-filter'),
                  initialValue: controller.eventTypeFilter,
                  decoration: InputDecoration(
                    labelText: l10n.calendarEventTypeFilter,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.calendarAllEventTypes),
                    ),
                    for (final type in controller.availableEventTypes)
                      DropdownMenuItem<String?>(
                        value: type,
                        child: Text(_eventTypeLabel(l10n, type)),
                      ),
                  ],
                  onChanged: controller.setEventTypeFilter,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CalendarRegistrationFilter>(
                  key: const ValueKey('calendar-status-filter'),
                  initialValue: controller.registrationFilter,
                  decoration: InputDecoration(
                    labelText: l10n.calendarStatusFilter,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final filter in CalendarRegistrationFilter.values)
                      DropdownMenuItem(
                        value: filter,
                        child: Text(_registrationFilterLabel(l10n, filter)),
                      ),
                  ],
                  onChanged: (filter) {
                    if (filter != null) {
                      controller.setRegistrationFilter(filter);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('calendar-reset-filters'),
                    onPressed:
                        controller.eventTypeFilter != null ||
                            controller.registrationFilter !=
                                CalendarRegistrationFilter.all
                        ? controller.resetFilters
                        : null,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.calendarResetFilters),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _registrationFilterLabel(
    AppLocalizations l10n,
    CalendarRegistrationFilter filter,
  ) {
    return switch (filter) {
      CalendarRegistrationFilter.all => l10n.calendarStatusAll,
      CalendarRegistrationFilter.coming => l10n.calendarStatusComing,
      CalendarRegistrationFilter.notRegistered =>
        l10n.calendarStatusNotRegistered,
      CalendarRegistrationFilter.notComing => l10n.calendarStatusNotComing,
    };
  }

  String _eventTypeLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'Spelning' => l10n.calendarEventTypeSpelning,
      'Rep' => l10n.calendarEventTypeRep,
      'Kårhusrep' => l10n.calendarEventTypeKarhusrep,
      'Balettrep' => l10n.calendarEventTypeBalettrep,
      'Athenrep' => l10n.calendarEventTypeAthenrep,
      'Samlingsrep' => l10n.calendarEventTypeSamlingsrep,
      'Fikarep' => l10n.calendarEventTypeFikarep,
      'Fest' => l10n.calendarEventTypeFest,
      'Evenemang' => l10n.calendarEventTypeEvenemang,
      _ => type,
    };
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
              if (!controller.isCurrentPeriod)
                TextButton(
                  key: const ValueKey('calendar-current-period-button'),
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
  const _CalendarHeader({required this.displaySettings});

  final CalendarDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.3) {
      return const SizedBox.shrink();
    }

    final dateWidth = switch (displaySettings.dateFormat) {
      CalendarDateFormat.compact => displaySettings.showWeekday ? 82.0 : 54.0,
      CalendarDateFormat.numeric => displaySettings.showWeekday ? 108.0 : 82.0,
      CalendarDateFormat.written => displaySettings.showWeekday ? 128.0 : 104.0,
    };
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: dateWidth,
            child: Text(l10n.calendarDate, style: style),
          ),
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
