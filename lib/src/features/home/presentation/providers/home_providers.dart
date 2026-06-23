import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeTab { discovery, timeline, profile }

final homeTabProvider = NotifierProvider.autoDispose<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);

final class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() {
    return HomeTab.discovery;
  }

  void select(HomeTab tab) {
    if (state == tab) {
      return;
    }

    state = tab;
  }

  void selectIndex(int index) {
    if (index < 0 || index >= HomeTab.values.length) {
      return;
    }

    select(HomeTab.values[index]);
  }
}
