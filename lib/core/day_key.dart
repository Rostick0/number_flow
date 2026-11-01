/// Calendar day as an int `YYYYMMDD` in local time. Used for daily content.
int dayKeyOf(DateTime time) => time.year * 10000 + time.month * 100 + time.day;

DateTime dateOfDayKey(int key) =>
    DateTime(key ~/ 10000, key ~/ 100 % 100, key % 100);

/// Whole days from [from] to [to] (both day keys).
int daysBetween(int from, int to) =>
    (dateOfDayKey(to).difference(dateOfDayKey(from)).inHours / 24).round();
