import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SecurityService {
  SecurityService._();

  static Future<bool> isDeviceCompromised() async {
    final jailbroken = await FlutterJailbreakDetection.jailbroken;
    // ignore: unused_local_variable
    final developerMode = await FlutterJailbreakDetection.developerMode;

    // If you want to hard-block developer mode in production, include this:
    // return jailbroken || developerMode;

    return jailbroken;
  }
}
