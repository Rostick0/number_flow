import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable time source so daily content can be tested.
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);
