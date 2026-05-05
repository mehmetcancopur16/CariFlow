import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state += 1;
  }
}

final sessionVersionProvider = NotifierProvider<SessionVersionNotifier, int>(
  SessionVersionNotifier.new,
);
