import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/ak_surface_card.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Anmälan')),
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
                        'Kommer till',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: widget.controller.where,
                        decoration: const InputDecoration(labelText: 'Anmälan'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Hålan',
                            child: Text('Hålan'),
                          ),
                          DropdownMenuItem(
                            value: 'Direkt',
                            child: Text('Direkt'),
                          ),
                          DropdownMenuItem(
                            value: 'Kan inte komma',
                            child: Text('Kan inte komma'),
                          ),
                        ],
                        onChanged: widget.controller.isSaving
                            ? null
                            : widget.controller.setWhere,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Har bil'),
                        value: widget.controller.car,
                        onChanged: widget.controller.isSaving
                            ? null
                            : widget.controller.setCar,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tar med instrument själv'),
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
                          decoration: const InputDecoration(
                            labelText: 'Instrument',
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
                        decoration: const InputDecoration(
                          labelText: 'Kommentar',
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
                    _errorMessage(widget.controller.error),
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
                      : const Text('Spara anmälan'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is EventRegistrationValidationError) {
      return error.message;
    }

    if (error is ApiException) {
      if (error.statusCode == 400) {
        return 'Anmälan kunde inte sparas. Kontrollera uppgifterna och försök igen.';
      }

      if (error.statusCode == 404) {
        return 'Aktiviteten finns inte längre.';
      }
    }

    return 'Anmälan kunde inte sparas. Försök igen.';
  }
}
