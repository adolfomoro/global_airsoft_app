import 'package:flutter_test/flutter_test.dart';
import 'package:global_airsoft_app/src/features/auth/presentation/widgets/username_availability_field.dart';

void main() {
  test('blocks submission only for pending or unavailable username states', () {
    expect(UsernameAvailabilityStatus.idle.blocksSubmission, isFalse);
    expect(UsernameAvailabilityStatus.waiting.blocksSubmission, isTrue);
    expect(UsernameAvailabilityStatus.checking.blocksSubmission, isTrue);
    expect(UsernameAvailabilityStatus.available.blocksSubmission, isFalse);
    expect(UsernameAvailabilityStatus.unavailable.blocksSubmission, isTrue);
    expect(UsernameAvailabilityStatus.failed.blocksSubmission, isFalse);
  });

  test('shows loading indicator only while checking availability', () {
    expect(UsernameAvailabilityStatus.idle.showsLoadingIndicator, isFalse);
    expect(UsernameAvailabilityStatus.waiting.showsLoadingIndicator, isFalse);
    expect(UsernameAvailabilityStatus.checking.showsLoadingIndicator, isTrue);
    expect(UsernameAvailabilityStatus.available.showsLoadingIndicator, isFalse);
    expect(
      UsernameAvailabilityStatus.unavailable.showsLoadingIndicator,
      isFalse,
    );
    expect(UsernameAvailabilityStatus.failed.showsLoadingIndicator, isFalse);
  });
}
