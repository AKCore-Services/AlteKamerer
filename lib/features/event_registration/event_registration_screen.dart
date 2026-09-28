import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import 'event_registration_controller.dart';

class EventRegistrationScreen extends StatefulWidget {
  const EventRegistrationScreen({super.key, required this.controller});

  final EventRegistrationController controller;

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _RegistrationWhereChoice extends StatelessWidget {
  const _RegistrationWhereChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ChoiceChip(
        label: SizedBox(width: double.infinity, child: Text(label)),
        selected: selected,
        onSelected: enabled ? (_) => onSelected() : null,
        showCheckmark: true,
      ),
    );
  }
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();

    _commentController = TextEditingController(text: widget.controller.comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventRegistration)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AkSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.akSignupComingTo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.registrationAttending,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      _RegistrationWhereChoice(
                        key: const ValueKey('registration-where-halan'),
                        label: l10n.akSignupHalan,
                        selected: widget.controller.where == 'Hålan',
                        enabled: !widget.controller.isSaving,
                        onSelected: () => widget.controller.setWhere('Hålan'),
                      ),
                      const SizedBox(height: 8),
                      _RegistrationWhereChoice(
                        key: const ValueKey('registration-where-direct'),
                        label: l10n.akSignupDirect,
                        selected: widget.controller.where == 'Direkt',
                        enabled: !widget.controller.isSaving,
                        onSelected: () => widget.controller.setWhere('Direkt'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.registrationNotAttending,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      _RegistrationWhereChoice(
                        key: const ValueKey('registration-where-cant-come'),
                        label: l10n.akSignupCantCome,
                        selected: widget.controller.where == 'Kan inte komma',
                        enabled: !widget.controller.isSaving,
                        onSelected: () =>
                            widget.controller.setWhere('Kan inte komma'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.registrationPracticalDetails,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.directions_car_outlined),
                        title: Text(l10n.hasCar),
                        value: widget.controller.car,
                        onChanged: widget.controller.isSaving
                            ? null
                            : widget.controller.setCar,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.luggage_outlined),
                        title: Text(l10n.needsInstrumentTransport),
                        value: widget.controller.needsInstrumentTransport,
                        onChanged: widget.controller.isSaving
                            ? null
                            : widget.controller.setNeedsInstrumentTransport,
                      ),
                      if (widget.controller.availableInstruments.length ==
                          1) ...[
                        const SizedBox(height: 8),
                        InputDecorator(
                          key: const ValueKey('registration-single-instrument'),
                          decoration: InputDecoration(
                            labelText: l10n.akSignupInstrument,
                          ),
                          child: Text(
                            widget.controller.selectedInstrument ??
                                widget.controller.availableInstruments.single,
                          ),
                        ),
                      ] else if (widget.controller.availableInstruments.length >
                          1) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: const ValueKey(
                            'registration-instrument-dropdown',
                          ),
                          initialValue: widget.controller.selectedInstrument,
                          decoration: InputDecoration(
                            labelText: l10n.akSignupInstrument,
                          ),
                          items: widget.controller.availableInstruments
                              .map(
                                (instrument) => DropdownMenuItem(
                                  value: instrument,
                                  child: Text(instrument),
                                ),
                              )
                              .toList(),
                          onChanged: widget.controller.isSaving
                              ? null
                              : widget.controller.setSelectedInstrument,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        enabled: !widget.controller.isSaving,
                        minLines: 3,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: l10n.akSignupComment,
                          alignLabelWithHint: true,
                        ),
                        onChanged: widget.controller.setComment,
                      ),
                    ],
                  ),
                ),
                if (widget.controller.status ==
                    EventRegistrationStatus.error) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _errorMessage(l10n, widget.controller.error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('registration-save-button'),
                  onPressed: widget.controller.isSaving
                      ? null
                      : () async {
                          final saved = await widget.controller.save();

                          if (!saved || !context.mounted) {
                            return;
                          }

                          Navigator.of(context).pop(true);
                        },
                  child: widget.controller.isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveRegistration),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _errorMessage(AppLocalizations l10n, Object? error) {
    if (error is EventRegistrationValidationError) {
      return l10n.selectArrivalRequired;
    }

    if (error is ApiException) {
      if (error.statusCode == 400) {
        return l10n.registrationSaveInvalid;
      }

      if (error.statusCode == 404) {
        return l10n.activityNoLongerExists;
      }
    }

    return l10n.registrationSaveFailed;
  }
}
