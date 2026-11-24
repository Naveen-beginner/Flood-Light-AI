import 'package:flutter/services.dart';

class DeviceAiCapability {
  static const _channel =
      MethodChannel('com.example.floodlight/device_ai');

  static bool? _nanoSupported;

  static Future<bool> supportsGeminiNano() async {
    if (_nanoSupported != null) return _nanoSupported!;

    try {
      final result =
          await _channel.invokeMethod<bool>('isGeminiNanoSupported');
      _nanoSupported = result == true;
    } on MissingPluginException {
      _nanoSupported = false;
    } on PlatformException {
      _nanoSupported = false;
    } catch (_) {
      _nanoSupported = false;
    }

    return _nanoSupported!;
  }
}
