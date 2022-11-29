import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';

class NearbyDevices extends StatefulWidget {
  const NearbyDevices({super.key});

  @override
  State<NearbyDevices> createState() => _NearbyDevicesState();
}

class _NearbyDevicesState extends State<NearbyDevices> {
  List<String> _devices = [];
  late FlutterReactiveBle flutterReactiveBle;
  StreamSubscription<DiscoveredDevice>? _deviceStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Platform.isAndroid) {
      flutterReactiveBle = FlutterReactiveBle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) => ListTile(
                      title: Text(_devices[index]),
                    ),
                separatorBuilder: (context, index) => const Divider(),
                itemCount: _devices.length),
          ),
          ElevatedButton(
            onPressed: () {
              if (Platform.isAndroid) {
                _requestBlePermission().then((granted) {
                  if (granted) {
                    _deviceStream?.cancel();
                    _deviceStream = flutterReactiveBle.scanForDevices(
                        withServices: [],
                        scanMode: ScanMode.lowLatency).listen((device) {
                      if (!_devices.contains(device.name)) {
                        setState(() {
                          _devices.add(device.name);
                        });
                      }
                    }, onError: (e) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text('Error:\n$e'),
                        ),
                      );
                    });
                  }
                });
              } else if (Platform.isWindows) {
                setState(() {
                  _devices = SerialPort.availablePorts;
                });
              }
            },
            child: const Text('Scan'),
          )
        ],
      ),
    );
  }

  Future<bool> _requestBlePermission() async {
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    if (int.parse(androidInfo.version.release.split('.').first) < 12) {
      if (!await Permission.locationWhenInUse.request().isGranted && mounted) {
        showNoPermissionDialog(
            context,
            'Need Location When in Use permission to operate. '
                'Location When in Use permission is not granted. '
                'Please go to privacy settings and grant Location When in Use permission.',
            'Open App Permissions',
            () => AppSettings.openAppSettings());
        return false;
      }
      return true;
    } else {
      if ((!await Permission.bluetoothConnect.request().isGranted ||
              !await Permission.bluetoothScan.request().isGranted) &&
          mounted) {
        showNoPermissionDialog(
            context,
            'Need Bluetooth permission to operate. '
                'Bluetooth permission is not granted. '
                'Please go to privacy settings and grant Bluetooth permission.',
            'Open App Permissions',
            () => AppSettings.openAppSettings());
        return false;
      }
      return true;
    }
  }

  Future<void> showNoPermissionDialog(
    BuildContext context,
    String explanation,
    String buttonText,
    Future<void> Function() openSettings,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
        title: const Text('No Bluetooth Permission '),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(explanation),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: openSettings,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
