import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/models/bonus_type.dart';
import '../../game/widgets/bonus_bar.dart';
import '../../services/ads/ad_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/audio/feedback_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../profile/economy.dart';
import '../profile/profile_controller.dart';
import '../settings/theme_picker.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _busy = false;

  void _buy(BonusType t) {
    if (ref.read(profileProvider.notifier).buyBonus(t)) {
      ref.read(feedbackProvider).play(Sfx.reward);
      showToast(context, '${t.title}: +1');
    }
  }

  Future<void> _watchForCoins() async {
    setState(() => _busy = true);
    final earned = await ref.read(adServiceProvider).showRewarded();
    if (!mounted) return;
    setState(() => _busy = false);
    if (earned) {
      ref.read(profileProvider.notifier).grantAdCoins();
      ref.read(feedbackProvider).play(Sfx.reward);
      showToast(context, '+${Economy.adCoins} монет');
    } else {
      showToast(context, 'Награда не получена');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final adsLeft = ref.read(profileProvider.notifier).adCoinsLeftToday;
    final ads = ref.watch(adServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: CoinBadge())],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Бонусы помогают в трудный момент. В одной партии каждый можно '
              'применить не больше 3 раз.',
              style: TextStyle(color: context.colors.inkSoft),
            ),
            const SizedBox(height: 12),
            for (final t in BonusType.values) ...[
              Panel(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(bonusIcon(t), color: context.colors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(t.description, style: TextStyle(color: context.colors.inkSoft, fontSize: 13)),
                          Text(
                            'Есть: ${profile.bonusCount(t)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(84, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: profile.coins >= t.price ? () => _buy(t) : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CoinIcon(size: 18),
                          const SizedBox(width: 6),
                          Text('${t.price}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            const Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Темы', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 12),
                  ThemePicker(),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Бесплатные монеты', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Посмотри короткую рекламу и получи ${Economy.adCoins} монет. '
                    'Осталось сегодня: $adsLeft',
                    style: TextStyle(color: context.colors.inkSoft),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<bool>(
                    valueListenable: ads.rewardedReady,
                    builder: (context, ready, _) => OutlinedButton.icon(
                      onPressed: ready && adsLeft > 0 && !_busy ? _watchForCoins : null,
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: Text(ready ? 'Смотреть (+${Economy.adCoins})' : 'Реклама сейчас недоступна'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
