import 'package:flutter/material.dart';

import '../../game/models/tile.dart';
import '../../game/widgets/tile_view.dart';
import '../../shared/theme/app_colors.dart';

/// Three-step "how to play"; shown on first launch and from menus.
Future<void> showRulesDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _RulesDialog(),
    );

class _RulesDialog extends StatefulWidget {
  const _RulesDialog();

  @override
  State<_RulesDialog> createState() => _RulesDialogState();
}

class _RulesDialogState extends State<_RulesDialog> {
  final _pages = PageController();
  int _page = 0;

  static const _steps = [
    (
      title: 'Числа текут вниз',
      text: 'Каждый такт блоки опускаются на одну клетку, а сверху появляется '
          'новое число. Его видно в окошке «Далее».',
      tiles: [2, 4, 2],
      icon: Icons.south_rounded,
    ),
    (
      title: 'Свайпни блок',
      text: 'Свайп меняет блок местами с соседней клеткой — пустой или занятой. '
          'Можно и тапнуть блок, а потом соседнюю клетку.',
      tiles: [4, 2],
      icon: Icons.swap_horiz_rounded,
    ),
    (
      title: 'Собери три',
      text: 'Три и больше одинаковых числа рядом сливаются в одно большее: '
          '2 + 2 + 2 = 4. Цепочки и комбо дают множитель очков.',
      tiles: [2, 2, 2],
      icon: Icons.merge_rounded,
    ),
    (
      title: 'Не дай полю переполниться',
      text: 'Если верхний ряд заполнен, когда должно появиться число, игра '
          'окончена. Следи за индикатором заполненности и используй бонусы.',
      tiles: [8, 16, 32],
      icon: Icons.warning_amber_rounded,
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final s in _steps)
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            Icon(s.icon, size: 36, color: context.colors.accent),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final v in s.tiles)
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: TileFace(tile: Tile(id: 0, value: v), size: 52),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: context.colors.inkSoft, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page ? context.colors.accent : context.colors.board,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => last
                      ? Navigator.of(context).pop()
                      : _pages.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                  child: Text(last ? 'Играть!' : 'Дальше'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
