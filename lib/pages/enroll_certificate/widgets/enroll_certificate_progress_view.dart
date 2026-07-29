import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_progress.dart';

class EnrollCertificateProgressView extends StatelessWidget {
  const EnrollCertificateProgressView({
    required this.progress,
    this.showIndicator = true,
    this.onRetry,
    super.key,
  });

  final EnrollCertificateProgress progress;
  final bool showIndicator;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          key: const ValueKey<String>('enroll-certificate-progress-panel'),
          width: 360,
          height: 200,
          child: Column(
            children: <Widget>[
              SizedBox.square(
                dimension: 36,
                child: showIndicator
                    ? const CircularProgressIndicator(strokeWidth: 3)
                    : Icon(
                        Icons.info_outline_rounded,
                        size: 36,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: Center(
                  child: Text(
                    progress.primary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(
                    progress.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: onRetry == null
                    ? null
                    : FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(app.enrollCertificate.regenerate),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
