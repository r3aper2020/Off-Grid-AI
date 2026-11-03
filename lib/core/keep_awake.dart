import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a long download runs: when the phone
/// sleeps, Android drops the connection, and a multi-hundred-MB
/// download should not depend on the user tapping the screen. Failures
/// (no platform plugin in tests) are ignored.
Future<void> keepAwake(bool on) async {
  try {
    await WakelockPlus.toggle(enable: on);
  } catch (_) {}
}
