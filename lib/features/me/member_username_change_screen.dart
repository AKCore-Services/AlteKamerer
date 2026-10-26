// -----------------------------------------------------------------------------
// member_username_change_screen.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Changes the authenticated member's username after verifying their
//   current password through AKCore.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../l10n/app_localizations.dart';
import 'member_credentials_api.dart';

/// Provides authenticated self-service username changes.
///
/// AKCore verifies the current password and enforces username validity and
/// uniqueness. A successful change does not invalidate the mobile session.
class MemberUsernameChangeScreen extends StatefulWidget {
  const MemberUsernameChangeScreen({
    super.key,
    required this.currentUsername,
    required this.credentialsService,
  });

  final String currentUsername;
  final MemberCredentialsService credentialsService;

  @override
  State<MemberUsernameChangeScreen> createState() =>
      _MemberUsernameChangeScreenState();
}

class _MemberUsernameChangeScreenState
    extends State<MemberUsernameChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final confirmedUsername = await widget.credentialsService.changeUsername(
        newUsername: _usernameController.text.trim(),
        currentPassword: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      _passwordController.clear();
      Navigator.of(context).pop(confirmedUsername);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error is ApiException && error.statusCode == 400
            ? l10n.credentialsUsernameRejected
            : l10n.credentialsChangeFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.credentialsChangeUsername)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_submitting,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.credentialsNewUsername,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.credentialsUsernameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_submitting,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.credentialsCurrentPassword,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.credentialsCurrentPasswordRequired;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(l10n.credentialsUpdateUsername),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
