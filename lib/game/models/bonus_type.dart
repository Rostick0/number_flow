enum BonusType {
  undo('Undo', 'Отменить последний ход', 60),
  remove('Remove', 'Убрать выбранный блок', 80),
  shuffle('Shuffle', 'Перемешать числа на поле', 100),
  doubleMerge('Double', 'Следующее слияние ×4 вместо ×2', 120),
  slowMotion('Slow', 'Замедлить поток на 12 секунд', 90);

  const BonusType(this.title, this.description, this.price);

  final String title;
  final String description;

  /// Shop price in coins.
  final int price;
}
