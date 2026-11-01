import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/models/bonus_type.dart';
import '../../game/widgets/bonus_bar.dart';
import '../../services/ads/ad_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/audio/feedback_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../profile/profile_controller.dart';

/// Offers to restock a bonus for coins or a voluntary rewarded ad.
/// Resolves to true if the player now owns at least one.
Future<bool> showBonusRefillSheet(BuildContext context, BonusType type) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RefillSheet(type: type),
  );
  return result ?? false;
}

class _RefillSheet extends ConsumerStatefulWidget {
  const _RefillSheet({required this.type});

  final BonusType type;

  @override
  ConsumerState<_RefillSheet> createState() => _RefillSheetState();
}

class _RefillSheetState extends ConsumerState<_RefillSheet> {
  bool _busy = false;

  void _buy() {
    if (ref.read(profileProvider.notifier).buyBonus(widget.type)) {
      ref.read(feedbackProvider).play(Sfx.reward);
      Navigator.pop(context, true);
    }
  }

  Future<void> _watchAd() async {
    setState(() => _busy = true);
    final earned = await ref.read(adServiceProvider).showRewarded();
    if (!mounted) return;
    setState(() => _busy = false);
    if (earned) {
      ref.read(profileProvider.notifier).addBonus(widget.type);
      ref.read(feedbackProvider).play(Sfx.reward);
      Navigator.pop(context, true);
    } else {
      showToast(context, 'Награда не получена');
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(profileProvider.select((p) => p.coins));
    final ads = ref.watch(adServiceProvider);
    final t = widget.type;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(bonusIcon(t), size: 40, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(
              t.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              t.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: coins >= t.price && !_busy ? _buy : null,
              icon: const CoinIcon(size: 20),
              label: Text('Купить за ${t.price}'),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<bool>(
              valueListenable: ads.rewardedReady,
              builder: (context, ready, _) => OutlinedButton.icon(
                onPressed: ready && !_busy ? _watchAd : null,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(ready ? 'Смотреть рекламу (+1)' : 'Реклама сейчас недоступна'),
              ),
            ),
            if (coins < t.price)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Не хватает ${t.price - coins} монет',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
