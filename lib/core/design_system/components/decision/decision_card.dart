import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../content/app_card.dart';
import '../result/result_card.dart' show resultThumb;

/// Karar kartı (DESIGN_SYSTEM.md §10 "DecisionMoment"): karar anı kapandığında odanın üstüne
/// sabitlenir. 56 thumbnail (`radius sm`), "Karar" overline (`brand`), `title` mekan adı,
/// `caption` saat, 2px `brand` kenar. [onPressed] verilirse dokunulabilir ve tek öğe okunur.
class DecisionCard extends StatelessWidget {
  const DecisionCard({
    super.key,
    required this.placeName,
    required this.time,
    required this.photo,
    this.onPressed,
  });

  final String placeName;

  /// "Cuma 20:00" gibi, çağıranın biçimlediği saat.
  final String time;
  final Widget photo;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final label = l10n.decisionCardSemantics(placeName, time);

    return AppCard(
      selected: true,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onPressed: onPressed,
      semanticLabel: label,
      child: Semantics(
        container: true,
        label: label,
        child: ExcludeSemantics(
          child: Row(
            children: [
              resultThumb(photo),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.decisionCardOverline,
                      style: text.overline.copyWith(color: c.brand),
                    ),
                    Text(
                      placeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.title,
                    ),
                    Text(
                      time,
                      style: text.caption.tabular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
