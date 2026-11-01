import 'package:number_flow/game/engine/engine_config.dart';
import 'package:number_flow/game/engine/game_engine.dart';
import 'package:number_flow/game/mechanics/merge_rule.dart';
import 'package:number_flow/game/mechanics/spawn_rule.dart';
import 'package:number_flow/game/models/board.dart';
import 'package:number_flow/game/models/position.dart';
import 'package:number_flow/game/models/tile.dart';

/// Builds cells from rows like `'2 2 . S 4*'`:
/// `.` empty, `S` stone, a number, `*` suffix = frozen for 3 ticks.
List<Tile?> parseCells(List<String> rows) {
  var id = 1;
  final cells = <Tile?>[];
  for (final row in rows) {
    for (final token in row.trim().split(RegExp(r'\s+'))) {
      if (token == '.') {
        cells.add(null);
      } else if (token == 'S') {
        cells.add(Tile(id: id++, value: 0, kind: TileKind.stone));
      } else {
        final frozen = token.endsWith('*');
        final value = int.parse(frozen ? token.substring(0, token.length - 1) : token);
        cells.add(Tile(id: id++, value: value, frozenTicks: frozen ? 3 : 0));
      }
    }
  }
  return cells;
}

GameEngine engineFrom(
  List<String> rows, {
  EngineConfig config = const EngineConfig(seed: 42),
  SpawnSpec next = const SpawnSpec(value: 2),
}) =>
    GameEngine.fromCells(config, parseCells(rows), next: next);

/// Renders the board back into the same notation (frozen marker omitted).
List<String> render(GameEngine engine) => [
      for (var r = 0; r < engine.size; r++)
        [
          for (var c = 0; c < engine.size; c++)
            switch (engine.tileAt(Pos(r, c))) {
              null => '.',
              final t when t.isStone => 'S',
              final t => '${t.value}',
            },
        ].join(' '),
    ];

bool hasMergeableGroup(GameEngine engine) {
  final board = Board(engine.size);
  for (final p in board.positions) {
    board[p] = engine.tileAt(p);
  }
  return const MergeRule().findGroups(board).isNotEmpty;
}
