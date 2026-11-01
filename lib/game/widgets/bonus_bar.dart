import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../models/bonus_type.dart';

IconData bonusIcon(BonusType t) => switch (t) {
      BonusType.undo => Icons.undo_rounded,
      BonusType.remove => Icons.backspace_rounded,
      BonusType.shuffle => Icons.shuffle_rounded,
      BonusType.doubleMerge => Icons.filter_2_rounded,
      BonusType.slowMotion => Icons.hourglass_bottom_rounded,
    };

class BonusButtonData {
  const BonusButtonData({
    required this.type,
    required this.stock,
    required this.usesLeft,
    required this.usable,
    required this.active,
  });

  final BonusType type;
  final int stock;
  final int usesLeft;
  final bool usable;

  /// Currently in effect (armed double, slow motion, remove targeting).
  final bool active;
}

class BonusBar extends StatelessWidget {
  const BonusBar({super.key, required this.buttons, required this.onPressed});

  final List<BonusButtonData> buttons;
  final void Function(BonusType type) onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final b in buttons)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _BonusButton(data: b, onPressed: () => onPressed(b.type)),
            ),
          ),
      ],
    );
  }
}

class _BonusButton extends StatelessWidget {
  const _BonusButton({required this.data, required this.onPressed});

  final BonusButtonData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Remove can be cancelled while targeting; other active bonuses just glow.
    final enabled = data.active
        ? data.type == BonusType.remove
        : data.usable && data.usesLeft > 0;
    final color = data.active ? AppColors.accent : AppColors.surface;
    final fg = data.active ? Colors.white : (enabled ? AppColors.ink : AppColors.inkSoft);
    return Semantics(
      button: true,
      label: '${data.type.title}: ${data.type.description}',
      child: Opacity(
        opacity: enabled || data.active ? 1 : 0.45,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(bonusIcon(data.type), color: fg, size: 26),
                            const SizedBox(height: 2),
                            Text(
                              data.type.title,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: _Badge(stock: data.stock),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final empty = stock <= 0;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: empty ? AppColors.success : AppColors.ink,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.background, width: 2),
      ),
      alignment: Alignment.center,
      child: empty
          ? const Icon(Icons.add_rounded, size: 14, color: Colors.white)
          : Text(
              '$stock',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
    );
  }
}
