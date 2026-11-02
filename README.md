# Number Flow

Минималистичная мобильная головоломка на Flutter (Android). Числа стекают по
полю 5×5, игрок меняет соседние блоки местами и собирает группы из трёх и
более одинаковых чисел, не давая полю переполниться.

Правила и баланс — в [GAME_DESIGN.md](GAME_DESIGN.md), статус работ — в
[TODO.md](TODO.md).

## Запуск

```bash
flutter pub get
flutter run                 # debug на подключённом устройстве/эмуляторе
flutter test                # unit- и widget-тесты
flutter build apk --release # или appbundle для Google Play / RuStore
```

### Рекламные блоки Yandex

По умолчанию используются демо-блоки Yandex (`demo-rewarded-yandex`,
`demo-interstitial-yandex`) — они показывают тестовую рекламу. Боевые
идентификаторы передаются при сборке:

```bash
flutter build appbundle --release \
  --dart-define=YANDEX_REWARDED_ID=R-M-XXXXXX-1 \
  --dart-define=YANDEX_INTERSTITIAL_ID=R-M-XXXXXX-2
```

### Подпись release-сборки

Создайте `android/key.properties` (файл в `.gitignore`):

```properties
storeFile=/abs/path/to/upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Без этого файла release подписывается debug-ключом (только для локальной
проверки).

## Архитектура

```
lib/
  core/            день-ключ, инжектируемые часы
  game/
    engine/        GameEngine — чистый Dart, без Flutter; конфиг и снапшоты
    mechanics/     правила: течение, слияния, появление, сложность, очки, PRNG
    models/        Tile, Board, Pos, события, бонусы, статистика сессии
    modes/         GameMode + ModeRegistry (Classic, Time Attack, Daily)
    widgets/       поле, блоки, эффекты, HUD, панель бонусов
  features/
    gameplay/      GameController (Riverpod), игровой экран, пауза, итоги, сохранение партии
    home/          главный экран
    profile/       PlayerProfile, ProfileController, экономика
    achievements/  достижения, ежедневные задания, награда за вход
    shop/          магазин и пополнение бонусов
    statistics/    статистика
    settings/      настройки, правила
  services/
    storage/       SharedPreferences + JSON
    ads/           AdService (интерфейс), YandexAdService, NoAdService, политика частоты
    audio/         звуки, фоновая музыка (audioplayers) и вибрация
  shared/          темы оформления, общие виджеты
```

Ключевые решения:

- **Движок не знает про UI и время.** `GameEngine.update(dt)` продвигает
  время, все действия возвращают список `GameEvent`. Контроллер превращает
  события в звук/вибрацию, а UI — в анимации. Это делает движок
  детерминированным и полностью покрываемым тестами.
- **Механики — заменяемые объекты.** `FlowRule`, `MergeRule`, `SpawnRule`,
  `DifficultyCurve`, `ScoreCalculator` передаются в движок, новая механика —
  новая реализация без переписывания движка.
- **Режимы расширяемы.** Новый режим — класс-наследник `GameMode`
  (конфигурация движка, сид, цель) и строка в `ModeRegistry`.
- **Реклама изолирована.** Игра обращается только к `AdService`; если SDK
  недоступен, `rewardedReady` остаётся `false`, кнопки неактивны, игра
  работает полностью. Interstitial показывается только на экране итогов
  между партиями.
- **Прогресс не теряется.** Профиль записывается при каждом изменении;
  незавершённая партия сохраняется при паузе, уходе в фон и каждые 10 тиков,
  и её можно продолжить с главного экрана.
- **Темы оформления.** Палитра (`AppColors`, включая цвета блоков) —
  `ThemeExtension`, виджеты читают её через `context.colors`. Темы
  перечислены в `GameTheme` ([game_themes.dart](lib/shared/theme/game_themes.dart));
  новая тема — ещё одно значение enum с ценой в монетах (0 — бесплатная).
  Купленные темы хранятся в профиле и сбрасываются вместе с прогрессом.
  Смена темы плавно перекрашивает приложение без сброса навигации и текущей
  партии.
- **Перерисовки.** Виджеты подписываются на узкие срезы состояния
  (`select`), поле сравнивается по значению, полоска такта рисуется
  собственным тикером без перестроения дерева, эффекты анимируются внутри
  `RepaintBoundary`.

## Ассеты

- Звуки синтезированы скриптом [tool/gen_sfx.py](tool/gen_sfx.py) — собственная
  работа, без сторонних лицензий.
- Фоновая музыка (4 спокойных трека, играют в случайном порядке) синтезирована
  скриптом [tool/gen_music.py](tool/gen_music.py) — тоже собственная работа.
  Пересборка: `python3 tool/gen_music.py assets/music` (нужны numpy и ffmpeg).
- Иконка нарисована скриптом [tool/gen_icon.py](tool/gen_icon.py).
