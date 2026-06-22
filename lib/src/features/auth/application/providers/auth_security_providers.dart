import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:global_airsoft_app/src/features/auth/application/services/auth_security_coordinator.dart';

final Provider<AuthSecurityCoordinator> authSecurityCoordinatorProvider =
    Provider<AuthSecurityCoordinator>((Ref ref) {
      return AuthSecurityCoordinator();
    });
