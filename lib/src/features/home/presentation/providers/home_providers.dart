
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/core/media/profile_photo.dart';
import 'package:global_airsoft_app/src/features/home/presentation/view_data/home_profile_view_data.dart';

enum HomeTab { discovery, timeline, profile }

final NotifierProvider<HomeTabNotifier, HomeTab> homeTabProvider =
    NotifierProvider<HomeTabNotifier, HomeTab>(HomeTabNotifier.new);

final Provider<HomeProfileViewData> homeProfileViewDataProvider =
    Provider<HomeProfileViewData>((Ref ref) {
      return const HomeProfileViewData(
        username: 'marcus.kane',
        fullName: 'Marcus Kane',
        bio: 'CQB-focused player who also enjoys long-form weekend milsim events.',
        profilePhoto: ProfilePhoto.empty(),
      );
    });

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
