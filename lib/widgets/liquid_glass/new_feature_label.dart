import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class NewFeatureLabel extends StatelessWidget {
  const NewFeatureLabel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool highContrast = MediaQuery.highContrastOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highContrast ? colors.onSurface : colors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: compact ? 1 : 3),
        child: Text(
          app.newFeature,
          maxLines: compact ? 1 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            height: compact ? 1.0 : null,
            fontWeight: FontWeight.w700,
            color: highContrast ? colors.surface : colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
