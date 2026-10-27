// -----------------------------------------------------------------------------
// member_password_change_screen.dart
// -----------------------------------------------------------------------------
//
// Purpose:
//   Changes the authenticated member's password through AKCore's existing
//   API and distinguishes confirmed from uncertain request outcomes.
//
// Contains:
//   - PasswordChangeOutcome: Results requiring local session invalidation.
//   - MemberPasswordChangeScreen: Password-change form.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'member_credentials_api.dart';

/// Outcomes that require discarding the current mobile session.
enum PasswordChangeOutcome { changed, unconfirmed }

/// Allows the current member to change their password.
///
/// AKCore validates the current password and applies its password policy.
/// The caller must invalidate the local session for either returned outcome.
class MemberPasswordChangeScreen extends StatefulWidget {
  const MemberPasswordChangeScreen({
    super.key,
    required this.credentialsService,
    this.embedded = false,
    this.authController,
  }) : assert(!embedded || authController != null);

  final MemberCredentialsService credentialsService;
  final bool embedded;
  final AuthController? authController;

  @override
  State<MemberPasswordChangeScreen> createState() =>
      _MemberPasswordChangeScreenState();
}

class _MemberPasswordChangeScreenState
    extends State<MemberPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _finish(
    PasswordChangeOutcome outcome,
    AuthController? embeddedAuth,
  ) async {
    if (mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }

    if (embeddedAuth != null) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final message = outcome == PasswordChangeOutcome.changed
            ? l10n.credentialsPasswordUpdatedSignIn
            : l10n.credentialsPasswordUnconfirmedSignIn;

        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
      }

      // Invalidate even if the settings page was closed while
      // AKCore was processing the request.
      await embeddedAuth.invalidateLocalSession();
    } else if (mounted) {
      Navigator.of(context).pop(outcome);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final embeddedAuth = widget.embedded ? widget.authController : null;
    final credentialsService = widget.credentialsService;
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    PasswordChangeOutcome? outcome;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await credentialsService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      outcome = PasswordChangeOutcome.changed;
    } on ApiException catch (error) {
      if (error.statusCode == 400) {
        if (mounted) {
          setState(() {
            _errorMessage = l10n.credentialsPasswordRejected;
          });
        }
      } else {
        outcome = PasswordChangeOutcome.unconfirmed;
      }
    } catch (_) {
      outcome = PasswordChangeOutcome.unconfirmed;
    } finally {
      if (outcome == null && mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }

    if (outcome != null) {
      await _finish(outcome, embeddedAuth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.credentialsPasswordSessionNotice,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _currentPasswordController,
            enabled: !_submitting,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.credentialsCurrentPassword,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.credentialsCurrentPasswordRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            enabled: !_submitting,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.akProfileNewPassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.passwordRequired;
              }
              if (value.length < 6) {
                return l10n.credentialsPasswordTooShort;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_submitting,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.akProfileConfirmPassword,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.passwordRequired;
              }
              if (value != _newPasswordController.text) {
                return l10n.credentialsPasswordMismatch;
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_reset_outlined),
            label: Text(l10n.akProfileUpdatePassword),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return form;
    }

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.akProfileChangePassword)),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: form,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
