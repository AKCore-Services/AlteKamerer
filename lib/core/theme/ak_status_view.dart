import 'package:flutter/material.dart';

import 'ak_brand_logo.dart';

class AkLoadingView extends StatelessWidget {
  const AkLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AkBrandLogo(variant: AkBrandLogoVariant.mark, width: 96, height: 96),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class AkErrorView extends StatelessWidget {
  const AkErrorView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Försök igen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
