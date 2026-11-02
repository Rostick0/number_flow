import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/models/tile.dart';
import '../../game/widgets/tile_view.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/game_themes.dart';
import '../../services/audio/audio_service.dart';
import '../../services/audio/feedback_service.dart';
import '../../shared/widgets/common.dart';
import '../profile/profile_controller.dart';

/// Grid of theme cards, each previewing its board and a few tiles. Owned
/// themes switch on tap; locked ones offer to buy them for coins.
class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  Future<void> _offer(BuildContext context, WidgetRef ref, GameTheme theme) async {
    final coins = ref.read(profileProvider).coins;
    final short = theme.price - coins;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Тема «${theme.title}»'),
        content: Text(
          short > 0
              ? 'Стоит ${theme.price} монет. Не хватает $short — их можно заработать в партиях.'
              : 'Купить за ${theme.price} монет?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: short > 0 ? null : () => Navigator.pop(context, true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 18),
                const SizedBox(width: 6),
                Text('${theme.price}'),
              ],
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (ref.read(profileProvider.notifier).buyTheme(theme)) {
      ref.read(feedbackProvider).play(Sfx.reward);
      showToast(context, 'Тема «${theme.title}» открыта');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(profileProvider.select((p) => p.settings.theme));
    final owned = ref.watch(profileProvider.select((p) => p.ownedThemes));
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.72,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final t in GameTheme.values)
          _ThemeCard(
            theme: t,
            selected: t == current,
            locked: !t.isFree && !owned.contains(t),
            onTap: () {
              if (!ref.read(profileProvider.notifier).selectTheme(t)) _offer(context, ref, t);
            },
          ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final GameTheme theme;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  static const _previewValues = [2, 16, 128, 1024];

  @override
  Widget build(BuildContext context) {
    final c = theme.colors;
    final radius = BorderRadius.circular(16);
    const statusStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 12);
    return Semantics(
      selected: selected,
      child: Material(
        color: c.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? context.colors.accent : context.colors.board,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  // Tiles below read the previewed theme, not the active one.
                  child: Theme(
                    data: Theme.of(context).copyWith(extensions: [c]),
                    child: _MiniBoard(colors: c, values: _previewValues),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  theme.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 16,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (locked) ...[
                          const CoinIcon(size: 14),
                          const SizedBox(width: 4),
                          Text('${theme.price}', style: statusStyle.copyWith(color: c.ink)),
                        ] else if (selected) ...[
                          Icon(Icons.check_circle_rounded, size: 14, color: c.accent),
                          const SizedBox(width: 3),
                          Text('Выбрана', style: statusStyle.copyWith(color: c.accent)),
                        ] else
                          Text('Открыта', style: statusStyle.copyWith(color: c.inkSoft)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.colors, required this.values});

  final AppColors colors;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.board, borderRadius: BorderRadius.circular(10)),
        child: LayoutBuilder(
          builder: (context, box) {
            const pad = 5.0;
            final size = (box.maxWidth - pad * 3) / 2;
            return Padding(
              padding: const EdgeInsets.all(pad),
              child: Wrap(
                spacing: pad,
                runSpacing: pad,
                children: [
                  for (final v in values)
                    TileFace(
                      tile: Tile(id: 0, value: v),
                      size: size,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
