import 'package:flutter_riverpod/flutter_riverpod.dart';

class PushTokenNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setToken(String token) {
    state = token;
  }

  String getToken() => state;
}

final pushTokenNotifierProvider = NotifierProvider<PushTokenNotifier, String>(
  PushTokenNotifier.new,
);
