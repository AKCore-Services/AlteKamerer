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
                      DropdownButtonFormField<String>(
                        initialValue: widget.controller.where,
                        decoration: InputDecoration(
                          labelText: l10n.eventRegistration,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Hålan',
                            child: Text(l10n.akSignupHalan),
                          ),
                          DropdownMenuItem(
                            value: 'Direkt',
                            child: Text(l10n.akSignupDirect),
                          ),
                          DropdownMenuItem(
                            value: 'Kan inte komma',
                            child: Text(l10n.akSignupCantCome),
                          ),
                        ],
                        onChanged: widget.controller.isSaving
                            ? null
                            : widget.controller.setWhere,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.hasCar),
                        value: widget.controller.car,
                        onChanged: widget.controller.isSaving
                            ? null
                            : widget.controller.setCar,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.bringsOwnInstrument),
                        value: widget.controller.instrument,
                        onChanged: widget.controller.isSaving
                            ? null
                            : widget.controller.setInstrument,
                      ),
                      if (widget
                          .controller
                          .availableInstruments
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
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
                        maxLines: 4,
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
                  Text(
                    _errorMessage(l10n, widget.controller.error),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
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
