import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DeviceAiCapability {
  static const _channel = MethodChannel('com.example.floodlight/device_ai');

  static bool? _nanoSupported;

  static Future<bool> hasValidatedInternet() async {
    try {
      return await _channel.invokeMethod<bool>('hasValidatedInternet') ?? false;
    } on MissingPluginException {
      final connectivity = await Connectivity().checkConnectivity();
      return !connectivity.contains(ConnectivityResult.none);
    } on PlatformException catch (error) {
      debugPrint('Internet validation check failed: ${error.message}');
      return true;
    }
  }

  static Future<bool> supportsGeminiNano() async {
    if (_nanoSupported != null) return _nanoSupported!;

    try {
      final result = await _channel.invokeMethod<bool>('isGeminiNanoSupported');
      _nanoSupported = result == true;
    } on MissingPluginException {
      _nanoSupported = false;
    } on PlatformException catch (error) {
      debugPrint('Gemini Nano capability check failed: ${error.message}');
      _nanoSupported = false;
    }

    return _nanoSupported!;
  }

  static Future<String> generateWithGeminiNano(String prompt) async {
    final response = await _channel.invokeMethod<String>('generateGeminiNano', {
      'prompt': prompt,
    });
    if (response == null || response.trim().isEmpty) {
      throw StateError('Gemini Nano returned an empty response.');
    }
    return response;
  }
}
