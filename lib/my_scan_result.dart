library native_bluetooth_ui;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:native_bluetooth_ui/flutter_blue_plus_extensions.dart';

class MyScanResult {
  const MyScanResult({
    required this.device,
    required this.advertisementData,
    required this.rssi,
    required this.timeStamp,
  });

  final BluetoothDevice device;
  final AdvertisementData advertisementData;
  final int rssi;
  final DateTime timeStamp;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MyScanResult && runtimeType == other.runtimeType && device == other.device;

  @override
  int get hashCode => device.hashCode;

  @override
  String toString() {
    return 'ScanResult{'
        'device: $device, '
        'advertisementData: $advertisementData, '
        'rssi: $rssi, '
        'timeStamp: $timeStamp'
        '}';
  }

  // TODO: remove BI-Vital specific code
  bool get isBIVital {
    if (device.platformName.contains(RegExp(r'[Bb][Ii]-?[Vv]ital'))) return true;
    if (advertisementData.advName.contains(RegExp(r'[Bb][Ii]-?[Vv]ital'))) return true;
    return false;
  }

  String get deviceName => device.deviceName;

  String? get deviceNameNullable => device.deviceNameNullable;
}
