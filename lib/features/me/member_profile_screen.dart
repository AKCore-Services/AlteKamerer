// -----------------------------------------------------------------------------
// member_profile_screen.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Displays the authenticated member's AKCore profile and registration
//   statistics, distinguishing sample data from real account information.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/theme/ak_status_view.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import 'member_profile.dart';
import 'member_profile_controller.dart';

/// Read-only profile destination for the authenticated member.
class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key, required this.controller});

  final MemberProfileController controller;

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.controller.status == MemberProfileStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final profile = widget.controller.profile;

        if (profile == null) {
          if (widget.controller.status == MemberProfileStatus.error) {
            return AkErrorView(
              title: l10n.connectionFailed,
              message: l10n.profileUnavailable,
              onRetry: widget.controller.load,
            );
          }

          return const AkLoadingView();
        }

        return RefreshIndicator(
          onRefresh: widget.controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.controller.isProfilePreview) ...[
                const _PreviewNotice(),
                const SizedBox(height: 16),
              ],
              AkSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.userName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.akProfileUserInfo,
                fields: [
                  _ProfileField(l10n.akProfileUserName, profile.userName),
                  _ProfileField(l10n.akProfileFirstName, profile.firstName),
                  _ProfileField(l10n.akProfileLastName, profile.lastName),
                  _ProfileField(l10n.akProfileEmail, profile.email),
                  _ProfileField(l10n.akProfilePhoneNumber, profile.phone),
                  _ProfileField(l10n.akProfileInstrument, profile.instrument),
                  _ProfileField(
                    l10n.akProfileOtherInstruments,
                    profile.otherInstruments.join(', '),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.akProfileRoles,
                fields: [
                  _ProfileField(l10n.akProfileRoles, profile.roles.join(', ')),
                  _ProfileField(l10n.akProfilePosts, profile.posts.join(', ')),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.akProfileLatestMedal,
                fields: [
                  _ProfileField(l10n.akProfileLatestMedal, profile.medal),
                  _ProfileField(
                    l10n.akProfileLatestMedalGiven,
                    profile.givenMedal,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _showStatistics,
                icon: const Icon(Icons.bar_chart),
                label: Text(l10n.akProfileStatisticsHeader),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatistics() async {
    final controller = widget.controller;
    final statisticsRequest = _fetchStatistics(controller);

    await showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final textTheme = Theme.of(context).textTheme;

        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.akProfileStatisticsHeader),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: FutureBuilder<MemberProfileStatistics>(
              future: statisticsRequest,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AkErrorView(
                    title: l10n.connectionFailed,
                    message: l10n.profileUnavailable,
                  );
                }

                final statistics = snapshot.data;

                if (statistics == null) {
                  return const AkLoadingView();
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (controller.isStatisticsPreview) ...[
                          const _PreviewNotice(),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          l10n.profileStatisticsRegistrationOnly,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),

                        // Overview of the existing AKCore period.
                        AkSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.profileStatsPeriod,
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.akProfileTotalGigs,
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${statistics.totalGigs}',
                                    style: textTheme.headlineLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          l10n.profileStatsChoices,
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        AkSurfaceCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              _StatChoiceRow(
                                icon: Icons.place_outlined,
                                label: l10n.profileStatsHalan,
                                value: statistics.halan,
                              ),
                              const Divider(height: 1),
                              _StatChoiceRow(
                                icon: Icons.near_me_outlined,
                                label: l10n.profileStatsDirect,
                                value: statistics.direct,
                              ),
                              const Divider(height: 1),
                              _StatChoiceRow(
                                icon: Icons.event_busy_outlined,
                                label: l10n.profileStatsCantCome,
                                value: statistics.cantCome,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          l10n.profileStatsDetails,
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final tileWidth = (constraints.maxWidth - 12) / 2;

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: tileWidth,
                                  child: _StatDetailTile(
                                    icon: Icons.directions_car_outlined,
                                    label: l10n.profileStatsCar,
                                    value: statistics.car,
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _StatDetailTile(
                                    icon: Icons.music_note_outlined,
                                    label: l10n.profileStatsInstrument,
                                    value: statistics.instrument,
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _StatDetailTile(
                                    icon: Icons.mode_comment_outlined,
                                    label: l10n.profileStatsComment,
                                    value: statistics.comment,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<MemberProfileStatistics> _fetchStatistics(
    MemberProfileController controller,
  ) async {
    await controller.loadStatistics();

    final statistics = controller.statistics;
    if (statistics == null || controller.error != null) {
      throw StateError('Profile statistics unavailable.');
    }

    return statistics;
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).profileSampleData,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ProfileField {
  const _ProfileField(this.label, this.value);

  final String label;
  final String value;
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.fields});

  final String title;
  final List<_ProfileField> fields;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AkSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final field in fields) ...[
            Text(field.label, style: textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(
              field.value.isEmpty ? '—' : field.value,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StatChoiceRow extends StatelessWidget {
  const _StatChoiceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(width: 12),
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _StatDetailTile extends StatelessWidget {
  const _StatDetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return AkSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
