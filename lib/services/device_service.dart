import 'dart:io';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      String deviceId = await FlutterUdid.udid;
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      String deviceModel = '';
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceModel = '${iosInfo.name} ${iosInfo.model}';
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceModel = 'Windows ${windowsInfo.computerName}';
      } else {
        deviceModel = 'Unknown Device';
      }

      return {
        'deviceId': deviceId,
        'deviceModel': deviceModel,
      };
    } catch (e) {
      return {
        'deviceId': 'unknown',
        'deviceModel': 'Unknown',
      };
    }
  }
}
