import 'dart:io';
import 'package:flutter/services.dart';

/// Only Android-specific operations cross this channel. All content and recovery data
/// remain in the app's private preferences file on the device.
class NativeBridge {
  static const _channel = MethodChannel('stop_it/native');

  static Future<String> readState() async {
    if (!Platform.isAndroid) return '{}';
    return await _channel.invokeMethod<String>('readState') ?? '{}';
  }

  static Future<void> saveState(String json) async {
    if (Platform.isAndroid) await _channel.invokeMethod<bool>('saveState', {'json': json});
  }

  static Future<bool> protectionStatus() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('protectionStatus') ?? false;
  }

  static Future<bool> startProtection() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('startProtection') ?? false;
  }

  static Future<void> setDailyReminder(bool enabled) async {
    if (Platform.isAndroid) await _channel.invokeMethod<bool>('setDailyReminder', {'enabled': enabled});
  }

  static Future<void> requestNotifications() async {
    if (Platform.isAndroid) await _channel.invokeMethod<bool>('requestNotifications');
  }

  static Future<bool> stopProtection() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('stopProtection') ?? false;
  }

  static Future<void> clearState() async {
    if (Platform.isAndroid) await _channel.invokeMethod<bool>('clearState');
  }
}
