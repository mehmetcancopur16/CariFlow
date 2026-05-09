import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SecurityService {
  SecurityService._();

  static Future<bool> isDeviceCompromised() async {
    // Plugin web tarafinda implement edilmedigi icin bu platformda kontrolu pas gec.
    if (kIsWeb) {
      return false;
    }

    final supportedPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!supportedPlatform) {
      return false;
    }

    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      // ignore: unused_local_variable
      final developerMode = await FlutterJailbreakDetection.developerMode;

      // If you want to hard-block developer mode in production, include this:
      // return jailbroken || developerMode;

      return jailbroken;
    } on MissingPluginException {
      // Plugin yoksa uygulamayi kirmadan devam et.
      return false;
    }
  }
}
