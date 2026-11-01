import 'package:flutter_test/flutter_test.dart';
import 'package:number_flow/game/engine/engine_config.dart';
import 'package:number_flow/game/engine/engine_snapshot.dart';
import 'package:number_flow/game/engine/game_engine.dart';
import 'package:number_flow/game/mechanics/seeded_random.dart';
import 'package:number_flow/game/mechanics/spawn_rule.dart';
import 'package:number_flow/game/models/bonus_type.dart';
import 'package:number_flow/game/models/game_events.dart';
import 'package:number_flow/game/models/position.dart';

import 'board_helpers.dart';

void main() {
  group('merges', () {
    test('three equal numbers merge into the next value at the moved cell', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '2 2 4 2 .',
      ]);
      final events = engine.swap(const Pos(4, 3), Direction.left)!;
      final merge = events.whereType<MergeHappened>().single;
      expect(merge.resultTile.value, 4);
      expect(merge.anchor, const Pos(4, 2));
      expect(merge.groupSize, 3);
      expect(render(engine).last, '. . 4 4 .');
      expect(engine.score, merge.points);
      expect(merge.points, 4 * 3);
    });

    test('two equal numbers do not merge', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '2 4 2 . .',
      ]);
      final events = engine.swap(const Pos(4, 1), Direction.up)!;
      expect(events.whereType<MergeHappened>(), isEmpty);
      expect(render(engine).last, '2 . 2 . .');
    });

    test('L-shaped group of four merges once with a size bonus', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . 4 . .',
        '4 4 2 4 .',
      ]);
      final events = engine.swap(const Pos(4, 3), Direction.left)!;
      final merge = events.whereType<MergeHappened>().single;
      expect(merge.groupSize, 4);
      expect(merge.resultTile.value, 8);
      expect(merge.points, (8 * 4 * 1.5).round());
    });

    test('merge result chains into a second merge', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. 4 4 . .',
        '2 2 8 2 .',
      ]);
      // 2,2,2 merge into 4 at (4,2), which joins the two 4s above.
      final events = engine.swap(const Pos(4, 3), Direction.left)!;
      final merges = events.whereType<MergeHappened>().toList();
      expect(merges.length, 2);
      expect(merges[0].chain, 1);
      expect(merges[1].chain, 2);
      expect(merges[1].resultTile.value, 8);
      expect(merges[1].anchor, const Pos(4, 2));
      expect(hasMergeableGroup(engine), isFalse);
    });

    test('merge destroys adjacent stones', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        'S . . . .',
        '2 2 4 2 .',
      ]);
      final events = engine.swap(const Pos(4, 3), Direction.left)!;
      expect(events.whereType<StoneDestroyed>().length, 1);
      expect(engine.tileAt(const Pos(3, 0)), isNull);
      expect(engine.stats.stonesDestroyed, 1);
    });

    test('frozen tiles merge and lose their ice', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '2* 2 4 2 .',
      ]);
      engine.swap(const Pos(4, 3), Direction.left);
      expect(engine.stats.merges, 1);
      expect(engine.tileAt(const Pos(4, 2))!.isFrozen, isFalse);
    });

    test('combo grows for merges within the window and resets after it', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '8 8 16 8 .',
        '2 2 4 2 .',
      ]);
      engine.swap(const Pos(4, 3), Direction.left);
      expect(engine.combo, 1);
      engine.swap(const Pos(3, 3), Direction.left);
      expect(engine.combo, 2);
      expect(engine.comboMultiplier, closeTo(1.2, 1e-9));
      for (var i = 0; i < 3; i++) {
        engine.tick();
      }
      expect(engine.combo, 0);
    });
  });

  group('movement', () {
    test('flow moves every tile with a gap below down by exactly one cell', () {
      final engine = engineFrom([
        '4 . . . .',
        '2 . . . .',
        '. . . . 8',
        '. . . . .',
        '. 16 . . .',
      ]);
      engine.tick();
      final rows = render(engine);
      expect(rows[1].split(' ')[0], '4');
      expect(rows[2].split(' ')[0], '2');
      expect(rows[3].split(' ')[4], '8');
      expect(rows[4].split(' ')[1], '16');
    });

    test('new tile appears in the top row from the preview', () {
      final engine = engineFrom(
        ['. . . . .', '. . . . .', '. . . . .', '. . . . .', '. . . . .'],
        next: const SpawnSpec(value: 8),
      );
      final spawned = engine.tick().whereType<TileSpawned>().single;
      expect(spawned.at.row, 0);
      expect(spawned.tile.value, 8);
    });

    test('swap rules reject stones, frozen tiles, equal values and empty pairs', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '8 S 4* . .',
        '2 2 4 8 .',
      ]);
      expect(engine.swap(const Pos(4, 1), Direction.up), isNull); // stone
      expect(engine.swap(const Pos(4, 2), Direction.up), isNull); // frozen
      expect(engine.swap(const Pos(4, 0), Direction.right), isNull); // equal
      expect(engine.swap(const Pos(4, 0), Direction.left), isNull); // outside
      expect(engine.swapCells(const Pos(0, 0), const Pos(0, 1)), isNull); // empty
      expect(engine.swap(const Pos(4, 3), Direction.right), isNotNull);
    });

    test('frozen tiles thaw after their ticks', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '. . . . .',
        '4* . . . .',
      ]);
      for (var i = 0; i < 3; i++) {
        engine.tick();
      }
      expect(engine.tileAt(const Pos(4, 0))!.isFrozen, isFalse);
    });
  });

  group('game over', () {
    test('overflow when the top row is full at spawn time', () {
      final engine = engineFrom([
        '2 4 8 16 32',
        '4 8 16 32 2',
        '8 16 32 2 4',
        '16 32 2 4 8',
        '32 2 4 8 16',
      ]);
      final events = engine.tick();
      expect(events.last, isA<GameOver>());
      expect(engine.isOver, isTrue);
      expect(engine.overReason, GameOverReason.overflow);
      expect(engine.tick(), isEmpty);
      expect(engine.swap(const Pos(4, 0), Direction.right), isNull);
    });

    test('time attack ends when time runs out', () {
      final engine = GameEngine(const EngineConfig(
        seed: 1,
        timeLimit: Duration(seconds: 3),
      ));
      engine.update(const Duration(seconds: 2));
      expect(engine.isOver, isFalse);
      final events = engine.update(const Duration(seconds: 2));
      expect(events.last, isA<GameOver>());
      expect(engine.overReason, GameOverReason.timeUp);
      expect(engine.timeLeft, Duration.zero);
    });

    test('an idle endless game eventually overflows', () {
      final engine = GameEngine(const EngineConfig(seed: 7));
      var guard = 0;
      while (!engine.isOver && guard++ < 1000) {
        engine.tick();
      }
      expect(engine.isOver, isTrue);
    });
  });

  group('timing and progression', () {
    test('update runs one tick per interval', () {
      final engine = GameEngine(const EngineConfig(seed: 3));
      engine.update(engine.tickInterval * 3);
      expect(engine.tickCount, 3);
    });

    test('level rises every mergesPerLevel merges and speeds up ticks', () {
      final engine = engineFrom(
        [
          '. . . . .',
          '. . . . .',
          '. . . . .',
          '. . . . .',
          '2 2 4 2 .',
        ],
        config: const EngineConfig(seed: 1, mergesPerLevel: 1),
      );
      final slow = engine.tickInterval;
      final events = engine.swap(const Pos(4, 3), Direction.left)!;
      expect(events.whereType<LevelUp>().single.level, 2);
      expect(engine.tickInterval < slow, isTrue);
    });
  });

  group('bonuses', () {
    List<String> start() => [
          '. . . . .',
          '. . . . .',
          '. . . . .',
          '8 S . . .',
          '2 2 4 2 16',
        ];

    test('undo restores the board and score before the last move', () {
      final engine = engineFrom(start());
      final before = render(engine);
      expect(engine.canUseBonus(BonusType.undo), isFalse);
      engine.swap(const Pos(4, 3), Direction.left);
      expect(engine.score, greaterThan(0));
      expect(engine.useUndo(), isNotNull);
      expect(render(engine), before);
      expect(engine.score, 0);
      expect(engine.canUseBonus(BonusType.undo), isFalse);
      expect(engine.bonusUsesLeft(BonusType.undo), 2);
    });

    test('undo expires after a few ticks', () {
      final engine = engineFrom(start());
      engine.swap(const Pos(4, 4), Direction.up);
      for (var i = 0; i <= engine.config.undoMaxTicks; i++) {
        engine.tick();
      }
      expect(engine.canUseBonus(BonusType.undo), isFalse);
    });

    test('remove deletes any tile including stones', () {
      final engine = engineFrom(start());
      expect(engine.useRemove(const Pos(3, 1)), isNotNull);
      expect(engine.tileAt(const Pos(3, 1)), isNull);
      expect(engine.useRemove(const Pos(0, 0)), isNull);
    });

    test('shuffle keeps the multiset of values and leaves no groups', () {
      final engine = engineFrom([
        '. . . . .',
        '. . . . .',
        '4 8 . . .',
        '8 S 16 . .',
        '2 4 2 8 16',
      ]);
      final before = engine.cells.whereType<Object>().length;
      engine.useShuffle();
      expect(engine.tileAt(const Pos(3, 1))!.isStone, isTrue);
      expect(hasMergeableGroup(engine), isFalse);
      final s = engine.stats;
      expect(
        engine.cells.whereType<Object>().length,
        before - s.mergedTiles + s.merges - s.stonesDestroyed,
      );
    });

    test('double merge makes the next merge jump two levels', () {
      final engine = engineFrom(start());
      engine.useDoubleMerge();
      expect(engine.doubleArmed, isTrue);
      expect(engine.canUseBonus(BonusType.doubleMerge), isFalse);
      final merge = engine
          .swap(const Pos(4, 3), Direction.left)!
          .whereType<MergeHappened>()
          .single;
      expect(merge.doubled, isTrue);
      expect(merge.resultTile.value, 8);
      expect(engine.doubleArmed, isFalse);
    });

    test('slow motion doubles the tick interval for its duration', () {
      final engine = engineFrom(start());
      final normal = engine.tickInterval;
      engine.useSlowMotion();
      expect(engine.tickInterval, normal * 2);
      engine.update(engine.config.slowMotionDuration);
      expect(engine.isSlowMotion, isFalse);
      expect(engine.tickInterval, normal);
    });

    test('each bonus is limited per game', () {
      final engine = engineFrom(start());
      for (var i = 0; i < engine.config.bonusUsesPerGame; i++) {
        expect(engine.useRemove(Pos(4, i)), isNotNull);
      }
      expect(engine.canUseBonus(BonusType.remove), isFalse);
      expect(engine.useRemove(const Pos(4, 4)), isNull);
      expect(engine.stats.bonusesUsed, 3);
    });
  });

  group('integrity', () {
    test('random play never leaves groups, duplicates or bad values', () {
      for (var seed = 0; seed < 25; seed++) {
        final engine = GameEngine(EngineConfig(seed: seed, startLevel: 1 + seed % 12));
        final rng = SeededRandom(seed * 977);
        var steps = 0;
        while (!engine.isOver && steps++ < 400) {
          final roll = rng.nextInt(10);
          if (roll < 6) {
            final from = Pos(rng.nextInt(5), rng.nextInt(5));
            engine.swap(from, rng.pick(Direction.values));
          } else if (roll < 9) {
            engine.update(engine.tickInterval);
          } else {
            engine.useShuffle();
          }
          expect(hasMergeableGroup(engine), isFalse, reason: 'seed $seed step $steps');
          final tiles = engine.cells.whereType<Object>().toList();
          final ids = engine.cells.where((t) => t != null).map((t) => t!.id).toSet();
          expect(ids.length, tiles.length);
          for (final t in engine.cells.where((t) => t != null && !t.isStone)) {
            final v = t!.value;
            expect(v >= 2 && (v & (v - 1)) == 0, isTrue, reason: 'value $v');
          }
        }
      }
    });

    test('the same seed reproduces the same game', () {
      List<String> play(int seed) {
        final engine = GameEngine(EngineConfig(seed: seed, initialTiles: 8));
        for (var i = 0; i < 15; i++) {
          engine.tick();
        }
        return render(engine);
      }

      expect(play(20261101), play(20261101));
      expect(play(20261101), isNot(play(20261102)));
    });

    test('initial board has the requested tiles and no groups', () {
      final engine = GameEngine(const EngineConfig(seed: 5, initialTiles: 8));
      expect(engine.cells.whereType<Object>().length, 8);
      expect(hasMergeableGroup(engine), isFalse);
    });

    test('snapshot JSON roundtrip continues identically', () {
      const config = EngineConfig(seed: 99, timeLimit: Duration(seconds: 120));
      final engine = GameEngine(config);
      engine.update(const Duration(seconds: 5));
      engine.useSlowMotion();
      final json = engine.snapshot().toJson();
      final restored = GameEngine.restore(config, EngineSnapshot.fromJson(5, json));
      expect(render(restored), render(engine));
      expect(restored.score, engine.score);
      expect(restored.timeLeft, engine.timeLeft);
      expect(restored.bonusUsesLeft(BonusType.slowMotion), 2);
      for (var i = 0; i < 10; i++) {
        engine.tick();
        restored.tick();
      }
      expect(render(restored), render(engine));
    });
  });
}
