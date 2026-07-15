import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/pin_service.dart';
import '../security/pin_lock_controller.dart';

/// Riverpod provider for PinService.
final pinServiceProvider = Provider<PinService>((ref) {
  return PinService();
});

/// Riverpod provider for PinLockController.
final pinLockControllerProvider = Provider<PinLockController>((ref) {
  final pinService = ref.watch(pinServiceProvider);
  return PinLockController(pinService: pinService);
});
