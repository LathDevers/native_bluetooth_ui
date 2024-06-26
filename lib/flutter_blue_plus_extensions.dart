library native_bluetooth_ui;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

extension BluetoothDeviceExtension on BluetoothDevice {
  String get deviceName {
    if (platformName.isEmpty && advName.isEmpty) return 'Unknown';
    if (platformName.isEmpty && advName.isNotEmpty) return advName;
    if (platformName.isNotEmpty && advName.isEmpty) return platformName;
    if (platformName.contains(RegExp(r'[Bb][Ii]-?[Vv]ital'))) return platformName;
    if (advName.contains(RegExp(r'[Bb][Ii]-?[Vv]ital'))) return advName;
    return 'Unknown';
  }

  String? get deviceNameNullable {
    if (platformName.isEmpty && advName.isEmpty) return null;
    if (platformName.isEmpty && advName.isNotEmpty) return advName;
    if (platformName.isNotEmpty && advName.isEmpty) return platformName;
    if (platformName.contains(RegExp(r'[Bb][Ii]-?[Vv]ital'))) return platformName;
    if (advName.contains(RegExp(r'[Bb][Ii]-?[Vv]ital'))) return advName;
    return null;
  }
}
