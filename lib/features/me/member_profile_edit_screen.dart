// -----------------------------------------------------------------------------
// member_profile_edit_screen.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Edits the authenticated member's permitted AKCore profile fields using
//   the existing member profile controller and application theme.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/ak_surface_card.dart';
import '../../l10n/app_localizations.dart';
import 'instrument_catalog.dart';
import 'member_profile.dart';
import 'member_profile_controller.dart';

/// Provides self-service editing of the authenticated member's profile.
///
/// AKCore validates and persists changes. The editor only closes after the
/// controller receives a successful update response for the current session.
class MemberProfileEditScreen extends StatefulWidget {
  const MemberProfileEditScreen({
    super.key,
    required this.controller,
    required this.profile,
  });

  final MemberProfileController controller;
  final MemberProfile profile;

  @override
  State<MemberProfileEditScreen> createState() =>
      _MemberProfileEditScreenState();
}

class _MemberProfileEditScreenState extends State<MemberProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _instrumentFocus = FocusNode();
  final _otherInstrumentsFocus = FocusNode();
  bool _instrumentLabelsInitialized = false;

  // Suggestions only. AKCore remains responsible for email acceptance.
  static const _commonEmailDomains = <String>{
    'gmail.com',
    'hotmail.com',
    'hotmail.se',
    'outlook.com',
    'outlook.se',
    'live.com',
    'live.se',
    'icloud.com',
    'yahoo.com',
    'yahoo.se',
    'proton.me',
    'protonmail.com',
    'msn.com',
    'me.com',
    'mail.com',
    'telia.com',
    'bredband.net',
  };

  static const _domainSuggestions = <String, String>{
    'gmail': 'gmail.com',
    'hotmail': 'hotmail.com',
    'outlook': 'outlook.com',
    'live': 'live.com',
    'icloud': 'icloud.com',
    'yahoo': 'yahoo.com',
    'proton': 'proton.me',
    'protonmail': 'protonmail.com',
  };

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _instrument;
  late final TextEditingController _otherInstruments;

  @override
  void initState() {
    super.initState();

    final profile = widget.profile;

    _firstName = TextEditingController(text: profile.firstName);
    _lastName = TextEditingController(text: profile.lastName);
    _email = TextEditingController(text: profile.email);
    _phone = TextEditingController(text: profile.phone);
    _instrument = TextEditingController(text: profile.instrument);

    // Legacy AKCore values can include spaces after stored separators.
    // Present them cleanly and submit separate instrument values.
    _otherInstruments = TextEditingController(
      text: profile.otherInstruments
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .join(', '),
    );

    widget.controller.addListener(_handleSessionChange);
  }

  void _handleSessionChange() {
    // A reload or session cleanup invalidates the profile being edited.
    // Do not leave the previous member's form visible after logout.
    if (widget.controller.profile != null &&
        widget.controller.status == MemberProfileStatus.loaded &&
        !widget.controller.isProfilePreview) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_instrumentLabelsInitialized) {
      return;
    }

    _instrumentLabelsInitialized = true;
    final languageCode = Localizations.localeOf(context).languageCode;

    _instrument.text = InstrumentCatalog.displayValue(
      _instrument.text,
      languageCode,
    );

    _otherInstruments.text = _otherInstruments.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map((value) => InstrumentCatalog.displayValue(value, languageCode))
        .join(', ');
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSessionChange);

    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _instrument.dispose();
    _otherInstruments.dispose();
    _instrumentFocus.dispose();
    _otherInstrumentsFocus.dispose();

    super.dispose();
  }

  List<String> _parseOtherInstruments(String input) {
    return input
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(InstrumentCatalog.canonicalValue)
        .toList();
  }

  String? _validateOtherInstruments(String? value) {
    final instruments = _parseOtherInstruments(value ?? '');
    final primary = InstrumentCatalog.canonicalValue(_instrument.text);

    if (instruments.any(
      (instrument) => instrument.toLowerCase() == primary.toLowerCase(),
    )) {
      return AppLocalizations.of(context).profileEditDuplicateInstrument;
    }

    final seen = <String>{};

    for (final instrument in instruments) {
      if (!seen.add(instrument.toLowerCase())) {
        return AppLocalizations.of(context).profileEditDuplicateOtherInstrument;
      }
    }

    return null;
  }

  bool _hasBasicEmailFormat(String email) {
    if (email.isEmpty) {
      // Preserve AKCore's handling of optional/empty email values.
      return true;
    }

    final at = email.indexOf('@');

    return at > 0 &&
        at == email.lastIndexOf('@') &&
        at < email.length - 1 &&
        !RegExp(r'\\s').hasMatch(email);
  }

  String? _validateEmail(String? value) {
    if (!_hasBasicEmailFormat((value ?? '').trim())) {
      return AppLocalizations.of(context).profileEditInvalidEmail;
    }

    return null;
  }

  String? _emailDomainWarning(String value, AppLocalizations l10n) {
    final email = value.trim();

    // Do not warn about unchanged, previously accepted member data.
    if (email.isEmpty ||
        email == widget.profile.email.trim() ||
        !_hasBasicEmailFormat(email)) {
      return null;
    }

    final domain = email.split('@').last.toLowerCase();

    if (_commonEmailDomains.contains(domain)) {
      return null;
    }

    final suggestion = _domainSuggestions[domain];

    if (suggestion != null) {
      return l10n.profileEditEmailDidYouMean(suggestion);
    }

    return l10n.profileEditEmailUnknownDomain;
  }

  Future<void> _save() async {
    if (widget.controller.isSaving ||
        _formKey.currentState?.validate() != true) {
      return;
    }

    final request = MemberProfileUpdateRequest(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      instrument: InstrumentCatalog.canonicalValue(_instrument.text),
      otherInstruments: _parseOtherInstruments(_otherInstruments.text),
    );

    final saved = await widget.controller.saveProfile(request);

    if (!mounted) {
      return;
    }

    if (saved) {
      Navigator.of(context).pop(true);
    }
  }

  String _errorMessage(Object error, AppLocalizations l10n) {
    // ApiClient currently extracts only the backend's "message" field.
    // AKCore profile validation uses other response shapes, so HTTP 400
    // must not expose the resulting generic transport error to members.
    if (error is ApiException && error.statusCode == 400) {
      return l10n.profileEditInvalidData;
    }

    return l10n.profileEditSaveFailed;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required bool enabled,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    double bottomPadding = 16,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        focusNode: focusNode,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 3,
          errorMaxLines: 4,
        ),
      ),
    );
  }

  Widget _instrumentField(
    String label,
    TextEditingController controller,
    FocusNode focusNode, {
    required bool enabled,
    required String languageCode,
    bool additional = false,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        // Additional instruments are comma-separated. Only suggest for
        // the entry currently being typed, not the preceding entries.
        final query = additional
            ? controller.text.split(',').last.trim()
            : controller.text.trim();

        final suggestions = enabled && focusNode.hasFocus
            ? InstrumentCatalog.suggestions(query).take(5).toList()
            : <StandardInstrument>[];

        final values = additional
            ? _parseOtherInstruments(controller.text)
            : [InstrumentCatalog.canonicalValue(controller.text)];

        final hasCustom =
            !focusNode.hasFocus && values.any(InstrumentCatalog.isCustom);

        final l10n = AppLocalizations.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              label,
              controller,
              enabled: enabled,
              focusNode: focusNode,
              helperText: helperText,
              validator: validator,
              bottomPadding: suggestions.isEmpty ? 16 : 4,
            ),
            for (final option in suggestions)
              ListTile(
                dense: true,
                title: Text(option.label(languageCode)),
                onTap: () {
                  final selected = option.label(languageCode);

                  if (additional) {
                    final separator = controller.text.lastIndexOf(',');

                    controller.text = separator < 0
                        ? selected
                        : '${controller.text.substring(0, separator).trimRight()}, $selected';
                  } else {
                    controller.text = selected;
                  }

                  focusNode.unfocus();
                },
              ),
            if (hasCustom)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.profileEditCustomInstrumentWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final saving = widget.controller.isSaving;

        final editable =
            widget.controller.status == MemberProfileStatus.loaded &&
            widget.controller.profile != null &&
            !widget.controller.isProfilePreview;

        final fieldsEnabled = editable && !saving;
        final saveError = widget.controller.saveError;

        return PopScope(
          canPop: !saving,
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.akProfileUpdateProfile)),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AkSurfaceCard(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field(
                            l10n.akProfileFirstName,
                            _firstName,
                            enabled: fieldsEnabled,
                          ),
                          _field(
                            l10n.akProfileLastName,
                            _lastName,
                            enabled: fieldsEnabled,
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _email,
                            builder: (context, value, _) {
                              return _field(
                                l10n.akProfileEmail,
                                _email,
                                enabled: fieldsEnabled,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                helperText: _emailDomainWarning(
                                  value.text,
                                  l10n,
                                ),
                              );
                            },
                          ),
                          _field(
                            l10n.akProfilePhoneNumber,
                            _phone,
                            enabled: fieldsEnabled,
                            keyboardType: TextInputType.phone,
                          ),
                          _instrumentField(
                            l10n.akProfileInstrument,
                            _instrument,
                            _instrumentFocus,
                            enabled: fieldsEnabled,
                            languageCode: languageCode,
                          ),
                          _instrumentField(
                            l10n.akProfileOtherInstruments,
                            _otherInstruments,
                            _otherInstrumentsFocus,
                            enabled: fieldsEnabled,
                            languageCode: languageCode,
                            additional: true,
                            helperText: l10n.profileEditOtherInstrumentsHint,
                            validator: _validateOtherInstruments,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (saveError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage(saveError, l10n),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: fieldsEnabled ? _save : null,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      saving ? l10n.profileEditSaving : l10n.profileEditSave,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
