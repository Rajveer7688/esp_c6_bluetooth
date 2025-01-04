import 'dart:async';
import 'package:blue/controller/switch_controller.dart';
import 'package:blue/utils/constants/colors.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:blue/utils/constants/text_strings.dart';
import 'package:blue/utils/helpers/helper_functions.dart';
import 'package:blue/utils/popups/loaders.dart';
import 'package:blue/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  static BluetoothController get instance => Get.find();

  /// -- Functional Variables
  final newDevices = <BluetoothDevice>[].obs;
  final pairedDevices = <BluetoothDevice>[].obs;
  final connectedDevices = <BluetoothDevice>[].obs;

  final isPairing = false.obs;
  final isConnecting = false.obs;
  final isDisconnecting = false.obs;
  final isScanning = false.obs;

  Map<String, BluetoothConnection> activeconnections = {};

  //for editing devicename
  final name = TextEditingController();
  GlobalKey<FormState> nameFormKey = GlobalKey<FormState>();
  dynamic switchcontroller = SwitchController();
 // Map<String, String> deviceNames = {};

  RxMap deviceNames = {"Attribute": "Value"}.obs;

  @override
  void onInit() {
    super.onInit();
    scanDevices();
  }

  /// -- 1. Scan Bluetooth Devices
  Future<void> scanDevices() async {
    try {
      if (isScanning.value) {
        return;
      }

      isScanning(true);
      if (await Permission.location.request().isGranted) {
        if (await Permission.bluetoothScan.request().isGranted &&
            await Permission.bluetoothConnect.request().isGranted &&
            await Permission.locationWhenInUse.request().isGranted) {
          newDevices.clear();

          List<BluetoothDevice> bondedDevices =
              await FlutterBluetoothSerial.instance.getBondedDevices();
          pairedDevices.clear();
          connectedDevices.clear();

          if (bondedDevices.isNotEmpty) {
            for (var device in bondedDevices) {
              if (device.isConnected) connectedDevices.add(device);
              {
                if (device.isBonded && !device.isConnected) {
                  pairedDevices.add(device);
                }
              }
            }
            debugPrint(
                'This is connected device ${bondedDevices.single.name} with status: ${bondedDevices.single.isConnected}');
            debugPrint(
                'This is bonded device ${bondedDevices.single.name} with details: ${bondedDevices.single.isBonded}');
          }

          await FlutterBluetoothSerial.instance
              .startDiscovery()
              .forEach((result) {
            if (!bondedDevices.any((d) => d.address == result.device.address)) {
              if (!newDevices.any((d) => d.address == result.device.address)) {
                newDevices.add(result.device);
              }
            }
          });
          debugPrint("current scanning task is completed");
        } else {
          TLoaders.customToast(
              message: 'Bluetooth permissions are not granted.');
        }
      } else {
        TLoaders.customToast(message: 'Location permission is not granted.');
      }
    } catch (e) {
      debugPrint("scanning show error: $e");
    } finally {
      isScanning(false);
    }
  }

  /// -- 2. Pair Bluetooth Devices
  Future<bool> pairDevice(BluetoothDevice device, BuildContext context) async {
    try {
      List<BluetoothDevice> bondedDevices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      bool isPaired = bondedDevices.any((d) => d.address == device.address);

      if (isPaired) {
        TLoaders.customToast(
            message: "${device.name ?? 'Device'} is already paired.");
        return true;
      }

      bool proceedWithPairing =
          await showPairUnpairDialog(context, device, true);

      if (!proceedWithPairing) {
        debugPrint("User cancelled pairing.");
        return false;
      }

      debugPrint(
          "Attempting to pair with ${device.name ?? 'Unknown Device'}...");
      bool? paired = await FlutterBluetoothSerial.instance
          .bondDeviceAtAddress(device.address);

      if (paired == true) {
        pairedDevices.add(device);
        newDevices.removeWhere((d) => d.address == device.address);
        pairedDevices.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

        //  myConnection = await BluetoothConnection.toAddress(device.address);

        debugPrint("Device paired successfully.");

        debugPrint("${device.isConnected}");
        if (device.isConnected == true) {
          connectedDevices.add(device);
          debugPrint('Connected to the device ');
          if (deviceNames[device.address].value != null) {
            deviceNames[device.address].value = device.name;
            update();
          }

        }
        return true;
      } else {
        debugPrint("Pairing failed or cancelled.");
        return false;
      }
    } catch (e) {
      debugPrint("Error during pairing: $e");
      return false;
    }
  }

  /// -- 3. Unpair Bluetooth Devices
  Future<void> unpairDevice(
      BluetoothDevice device, BuildContext context) async {
    try {
      bool proceedWithUnpairing =
          await showPairUnpairDialog(context, device, false);

      if (!proceedWithUnpairing) {
        debugPrint("User cancelled unpairing.");
        return;
      }

      bool? success = await FlutterBluetoothSerial.instance
          .removeDeviceBondWithAddress(device.address);

      if (success != null && success) {
        pairedDevices.removeWhere((d) => d.address == device.address);
        newDevices.add(device);
        debugPrint("Device unpaired successfully.");
      } else {
        debugPrint("Failed to unpair the device.");
      }
    } catch (e) {
      debugPrint("Error during unpairing: $e");
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    try {
      if (device.isConnected) {
        debugPrint('Connected to the device due to pairing');
      }

      isConnecting.value = true;
      debugPrint(
          "Connecting to ${device.name ?? 'Device'} with address ${device.address}...");

      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);

      if (connection.isConnected) {
        connectedDevices.add(device);
        pairedDevices.removeWhere((d) => d.address == device.address);
        debugPrint("$activeconnections");
        activeconnections[device.address] = connection;
        debugPrint(
            "after storing connections which are active are :$activeconnections");
        debugPrint("Connected to ${device.name ?? 'Device'}");
        TLoaders.successSnackBar(
            title: 'Connected',
            message: '${device.name ?? 'Device'} connected successfully.');
        if (deviceNames[device.address] != null) {
          deviceNames[device.address].value = device.name;
          update();
        }
      } else {
        debugPrint("Connection to ${device.name ?? 'Device'} failed.");
        TLoaders.customToast(
            message: "${device.name ?? 'Device'} couldn't connect.");
      }
    } catch (e) {
      debugPrint("Error during connection: $e");
      TLoaders.customToast(
          message: "${device.name ?? 'Device'} couldn't connect.");
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> disconnectDevice(
      BluetoothDevice device, BuildContext context) async {
    try {
      BluetoothConnection? connection = activeconnections[device.address];
      debugPrint("${connection!.isConnected}");
      if (connection.isConnected) {
        debugPrint("Disconnecting from ${device.name ?? 'Device'}...");
        await connection
            .finish(); // if finish does not work use alternative - await connection.close()
        debugPrint("Disconnected from ${device.name ?? 'Device'}.");
        debugPrint("$activeconnections");

        // Update device lists
        connectedDevices.removeWhere((d) => d.address == device.address);
        pairedDevices.add(device);
        activeconnections.remove(device.address);
        debugPrint(
            "after disconnecting activeconnections are : $activeconnections");
        TLoaders.successSnackBar(
            title: 'Disconnected',
            message: '${device.name ?? 'Device'} disconnected successfully.');
      } else {
        debugPrint(
            "No active connection found for ${device.name ?? 'Device'}.");
      }
    } catch (e) {
      debugPrint("Error during disconnection: $e");
      await unpairDevice(device, context);
      debugPrint("device unpaired to disconnect properly");

      TLoaders.customToast(
          message: "Error disconnecting from ${device.name ?? 'Device'}: $e");
    }
  }


  /// -- 6. Show Pair Device Dialog Box
  Future<dynamic> showPairUnpairDialog(
      BuildContext context, BluetoothDevice device, bool isPairing) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          final dark = THelperFunctions.isDarkMode(context);
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.defaultSpace / 2)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.infinity,
              padding: EdgeInsets.all(TSizes.defaultSpace * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      isPairing
                          ? 'Bluetooth Pairing Request'
                          : 'Unpair ${device.name ?? 'Device'}?',
                      style: TextStyle(
                          fontSize: TSizes.fontSizeMd,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: TSizes.defaultSpace / 2),
                  Text(
                    isPairing
                        ? 'Pair with ${device.name ?? 'Unknown Device'}?'
                        : "To connect to this device in the future, you'll need to pair it again.",
                    style: TextStyle(
                        fontSize: TSizes.fontSizeSm,
                        color: dark ? TColors.lightGrey : TColors.darkGrey),
                  ),
                  SizedBox(height: TSizes.defaultSpace * 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
                          style: TextButton.styleFrom(
                            foregroundColor: TColors.black,
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(
                                horizontal: TSizes.defaultSpace,
                                vertical: TSizes.defaultSpace / 2),
                          ),
                          child: Text(TTexts.cancel),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(
                                horizontal: TSizes.defaultSpace,
                                vertical: TSizes.defaultSpace / 2),
                          ),
                          child: Text(isPairing ? TTexts.pair : TTexts.unpair,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: TSizes.fontSizeMd * 0.8,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

// -- 6. Rename of Bluetooth Devices
  Future<void> renameDevice(BuildContext context, BluetoothDevice device,
      List<BluetoothDevice> connectedDevices) async {
    // If Device is not connected
    if (!connectedDevices.contains(device)) {
      TLoaders.customToast(
          message: 'Please connect your device and try again.');
      verifyDeviceStatus();
      return;
    }

    // Get new device name from dialog
    String newName = await showRenameDialog(context, device);

    if (newName.isNotEmpty) {
      {
        deviceNames[device.address]= newName;
        update();
      }

      TLoaders.customToast(message: 'Device name updated to $newName');
    }
  }

  /// -- 6. Show Device Rename Dialog Box
  Future<dynamic> showRenameDialog(
      BuildContext context, BluetoothDevice device) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.defaultSpace / 2)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.infinity,
              padding: EdgeInsets.all(TSizes.defaultSpace * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Edit Bluetooth Name',
                      style: TextStyle(
                          fontSize: TSizes.fontSizeMd,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: TSizes.defaultSpace / 2),
                  Form(
                      key: BluetoothController.instance.nameFormKey,
                      child: TextFormField(
                        controller: BluetoothController.instance.name,
                        validator: (value) => TValidator.validateEmptyText(
                            'Bluetooth Rename', value),
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Iconsax.user),
                            labelText: TTexts.bluetoothName),
                      )),
                  SizedBox(height: TSizes.defaultSpace * 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: () => Get.back(result: ''),
                          style: TextButton.styleFrom(
                            foregroundColor: TColors.black,
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(
                                horizontal: TSizes.defaultSpace,
                                vertical: TSizes.defaultSpace / 2),
                          ),
                          child: Text(TTexts.cancel),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: () {
                            // Validate the form
                            if (!nameFormKey.currentState!.validate()) return;

                            // Get the trimmed name
                            String trimmedName = name.text.trim();

                            // Navigate back with the result
                            Get.back(result: trimmedName);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(
                                horizontal: TSizes.defaultSpace,
                                vertical: TSizes.defaultSpace / 2),
                          ),
                          child: Text(TTexts.save,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: TSizes.fontSizeMd * 0.8,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  /// -- 7. Verify Devices Current Status
  Future<void> verifyDeviceStatus() async {
    if (await Permission.location.request().isGranted) {
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted &&
          await Permission.locationWhenInUse.request().isGranted) {
        /// Clear all the previous data
        pairedDevices.clear();
        connectedDevices.clear();

        /// Update Paired and Connected devices list
        List<BluetoothDevice> bondedDevices =
            await FlutterBluetoothSerial.instance.getBondedDevices();
        if (bondedDevices.isNotEmpty) {
          for (var device in bondedDevices) {
            if (device.isConnected) connectedDevices.add(device);
            {
              if (device.isBonded && !device.isConnected) {
                pairedDevices.add(device);
              }
            }
          }
          // for (var device in bondedDevices) {
          //   if (device.isConnected) if (!connectedDevices.contains(device)) {
          //     connectedDevices.add(device);
          //   }
          //   if (device.isBonded && !device.isConnected) if (!pairedDevices
          //       .contains(device)) pairedDevices.add(device);
          // }
        }
      }
    }
  }

  /// -- 8. Check Device Requirements
  Future<int> checkAllRequirements(switchcontroller) async {
    switchcontroller.isBluetoothActive();
    switchcontroller.isLocationActive();

    await Future.delayed(Duration(milliseconds: 200));

    if (switchcontroller.isBluetoothOn.value) {
      return 1;
    } else if (!switchcontroller.isLocationOn.value) {
      return 2;
    }
    return 0;
  }

  /// -- 9. Show Requirements Messages
  void showRequiredMessage(int i) {
    if (i == 1) {
      TLoaders.warningSnackBar(
          title: 'Bluetooth Turn On',
          message: 'Please turn on your device bluetooth');
    } else if (i == 2) {
      TLoaders.warningSnackBar(
          title: 'Location Turn On',
          message: 'Please turn on your device location');
    }
  }
}
