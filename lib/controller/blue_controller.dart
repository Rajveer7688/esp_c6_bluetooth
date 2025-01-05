import 'dart:async';
import 'package:blue/controller/switch_controller.dart';
import 'package:blue/models/bluetooth_model.dart';
import 'package:blue/repositories/bluetooth_repository.dart';
import 'package:blue/utils/constants/colors.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:blue/utils/constants/text_strings.dart';
import 'package:blue/utils/helpers/helper_functions.dart';
import 'package:blue/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/validators/validation.dart';

class BluetoothController extends GetxController {
  static BluetoothController get instance => Get.find();

  /// -- Functional Variables
  final isPairing = false.obs;
  final isScanning = false.obs;
  final isConnecting = false.obs;
  final isDisconnecting = false.obs;
  final newDevices = <BluetoothDevice>[].obs;
  final pairedDevices = <BluetoothDevice>[].obs;
  final filteredDevices = <BluetoothDevice>[].obs;
  final connectedDevices = <BluetoothDevice>[].obs;
  RxMap<String, String> deviceNames = <String, String>{}.obs;

  /// -- Static Variables
  Timer? _timer;
  final repository = Get.put(BluetoothRepository());
  final switchController = Get.put(SwitchController());
  Map<String, BluetoothConnection> activeConnections = {};

  /// -- Form Data for Device Rename
  final name = TextEditingController();
  GlobalKey<FormState> nameFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    scanDevices();
    checkAllRequirements();
    startVerifyingDeviceStatus();
  }

  /// -- 1. Scan Bluetooth Devices
  Future<void> scanDevices() async {
    try {
      var isRequired = await checkAllRequirements();
      if (isRequired > 0) { showRequiredMessage(isRequired); return; }

      if (isScanning.value) return;
      isScanning(true);

      if (await Permission.location.request().isGranted) {
        if (await Permission.bluetoothScan.request().isGranted &&
            await Permission.bluetoothConnect.request().isGranted &&
            await Permission.locationWhenInUse.request().isGranted) {

          /// Clear all the previous data
          newDevices.clear();
          pairedDevices.clear();
          connectedDevices.clear();

          /// Update Paired and Connected devices list
          List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
          if (bondedDevices.isNotEmpty) {
            for (var device in bondedDevices) {
              if (device.isConnected) connectedDevices.add(device);
              if (device.isBonded && !device.isConnected) pairedDevices.add(device);
              if (device.isBonded && (deviceNames[device.address] == null || deviceNames[device.address]!.isEmpty)) deviceNames[device.address] = device.name ?? 'Unknown Device';
              updateDeviceName(device);
            }
          }

          await FlutterBluetoothSerial.instance.startDiscovery().forEach((result) {
            if (!bondedDevices.any((d) => d.address == result.device.address)) {
              if (!newDevices.any((d) => d.address == result.device.address)) {
                newDevices.add(result.device);
                filterAvailableDevices('');
              }
            }
          });

          /// Update everything
          update();

          debugPrint("current scanning task is completed");
        } else {
          TLoaders.customToast(message: 'Bluetooth permissions are not granted.');
        }
      } else {
        TLoaders.customToast(message: 'Location permission is not granted.');
      }
    } catch (e) {
      debugPrint("scanning show error: $e");
      TLoaders.customToast(message: 'Something went wrong, please try again.');
    } finally {
      isScanning(false);
    }
  }

  /// -- 2. Pair Bluetooth Devices
  Future<bool> pairDevice(BluetoothDevice device, BuildContext context) async {
    try {
      var isRequired = await checkAllRequirements();
      if (isRequired > 0) { showRequiredMessage(isRequired); return false; }

      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      bool isPaired = bondedDevices.any((d) => d.address == device.address);

      if (isPaired) {
        TLoaders.customToast(message: "${device.name ?? 'Device'} is already paired.");
        return true;
      }

      bool proceedWithPairing = await showPairUnpairDialog(context, device, true);
      if (!proceedWithPairing) return false;

      bool? paired = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address);
      if (paired == true) {
        pairedDevices.add(device);
        if (deviceNames[device.address] == null || deviceNames[device.address]!.isEmpty) deviceNames[device.address] = device.name ?? 'Unknown Device';
        filteredDevices.removeWhere((d) => d.address == device.address);
        newDevices.removeWhere((d) => d.address == device.address);
        pairedDevices.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        verifyDeviceStatus();
        debugPrint("Device paired successfully.");
        return true;
      } else {
        TLoaders.customToast(message: 'Something went wrong, device not paired.');
        return false;
      }
    } catch (e) {
      debugPrint("Error during pairing: $e");
      TLoaders.customToast(message: 'Something went wrong, device not paired.');
      return false;
    }
  }

  /// -- 3. Unpair Bluetooth Devices
  Future<void> unpairDevice(BluetoothDevice device, BuildContext context) async {
    try {
      var isRequired = await checkAllRequirements();
      if (isRequired > 0) { showRequiredMessage(isRequired); return; }

      bool proceedWithUnpairing = await showPairUnpairDialog(context, device, false);

      if (!proceedWithUnpairing) {
        debugPrint("User cancelled unpairing.");
        return;
      }

      bool? success = await FlutterBluetoothSerial.instance.removeDeviceBondWithAddress(device.address);

      if (success != null && success) {
        connectedDevices.removeWhere((d) => d.address == device.address);
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

  /// -- 4. Connect Bluetooth Devices
  Future<void> connectDevice(BluetoothDevice device, BuildContext context) async {
    try {
      var isRequired = await checkAllRequirements();
      if (isRequired > 0) { showRequiredMessage(isRequired); return; }

      isConnecting.value = true;
      debugPrint("Connecting to ${device.name ?? 'Device'}...");

      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      debugPrint('This is connection: $connection');

      if (connection.isConnected) {
        if (!connectedDevices.contains(device)) connectedDevices.add(device);
        if (deviceNames[device.address] == null || deviceNames[device.address]!.isEmpty) deviceNames[device.address] = device.name ?? 'Unknown Device';
        pairedDevices.removeWhere((d) => d.address == device.address);
        activeConnections[device.address] = connection;
        debugPrint("Connected to ${device.name ?? 'Device'}");
        TLoaders.successSnackBar(title: 'Connected', message: '${device.name ?? 'Device'} connected successfully.');
      } else {
        debugPrint("Connection to ${deviceNames[device.address] ?? device.name ?? 'Device'} failed.");
        TLoaders.customToast(message: "${deviceNames[device.address] ?? device.name ?? 'Device'} couldn't connect.");
      }
    } on PlatformException {
      await unpairDevice(device, context);
      debugPrint('This is connect again.');
    } catch (e) {
      debugPrint("Error during connection: $e");
      TLoaders.customToast(message: "${deviceNames[device.address] ?? device.name ?? 'Device'} couldn't connect.");
    } finally {
      isConnecting.value = false;
    }
  }

  /// -- 5. Disconnect Bluetooth Devices
  Future<void> disconnectDevice(BluetoothDevice device, BuildContext context) async {
    try {
      var isRequired = await checkAllRequirements();
      if (isRequired > 0) { showRequiredMessage(isRequired); return; }

      isDisconnecting.value = true;
      debugPrint("Disconnecting from ${device.name ?? 'Device'}...");

      BluetoothConnection? connection = activeConnections[device.address];
      debugPrint('This is connection value: $connection');

      if (connection == null) {
        debugPrint("No active connection found for ${device.name ?? 'Device'}.");
        await unpairDevice(device, context);
        debugPrint('Unpair Device successfully');
        TLoaders.customToast(message: 'Disconnected from ${device.name ?? 'This Device'} successfully.');
        return;
      }

      if (connection.isConnected) {
        await connection.close();
        await connection.finish();
        activeConnections.remove(device.address);
        verifyDeviceStatus();
        debugPrint("Disconnected from ${device.name ?? 'Device'} successfully.");
      } else {
        debugPrint("${device.name ?? 'Device'} is already disconnected.");
      }

      connectedDevices.removeWhere((d) => d.address == device.address);
      if (!pairedDevices.contains(device)) pairedDevices.add(device);
      debugPrint("Disconnected successfully.");
    } catch (e) {
      debugPrint("Error during disconnection: $e");
    } finally {
      isDisconnecting.value = false;
    }
  }

  /// -- 6. Rename of Bluetooth Devices
  Future<void> renameDevice(BuildContext context, BluetoothDevice device) async {
    // If Device is not connected
    if (!connectedDevices.contains(device)) {
      TLoaders.customToast(message: 'Please connect your device and try again.');
      verifyDeviceStatus();
      return;
    }

    // Update the value of device name
    name.text = deviceNames[device.address] ?? device.name ?? 'Unknown Device';
    String newName = await showRenameDialog(context, device);

    if (newName.isEmpty) return;

    final bluetoothData = BluetoothModel(id: '', name: newName, macAddress: device.address, bluetoothType: device.type.stringValue);
    await repository.addOrUpdateBluetooth(bluetoothData);
    debugPrint('Data saved in firebase successfully!');
    deviceNames[device.address] = newName;
    updateDeviceName(device);
    name.clear();
    debugPrint('Device name updated successfully: ${deviceNames[device.address]}');
  }

  /// -- 7. Show Device Rename Dialog Box
  Future<dynamic> showRenameDialog(BuildContext context, BluetoothDevice device) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.defaultSpace / 2)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.infinity,
              padding: EdgeInsets.all(TSizes.defaultSpace * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Edit Bluetooth Name', style: TextStyle(fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.bold)),
                  SizedBox(height: TSizes.defaultSpace * 0.8),

                  Form(
                    key: BluetoothController.instance.nameFormKey,
                      child: TextFormField(
                        controller: BluetoothController.instance.name,
                        validator: (value) => TValidator.validateEmptyText('Bluetooth Rename', value),
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(prefixIcon: Icon(Iconsax.user, size: 18), labelText: TTexts.bluetoothName),
                      )
                  ),

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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.defaultSpace / 2),
                          ),
                          child: Text(TTexts.cancel),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: () {
                            if (!nameFormKey.currentState!.validate()) return;
                            debugPrint('This is name: ${name.text.trim()}');
                            Get.back(result: name.text.trim());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.defaultSpace / 2),
                          ),
                          child: Text(TTexts.save, style: TextStyle(color: Colors.white, fontSize: TSizes.fontSizeMd * 0.8, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  /// -- 8. Show Pair Device Dialog Box
  Future<dynamic> showPairUnpairDialog(BuildContext context, BluetoothDevice device, bool isPairing) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          final dark = THelperFunctions.isDarkMode(context);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.defaultSpace / 2)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.infinity,
              padding: EdgeInsets.all(TSizes.defaultSpace * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(isPairing ? 'Bluetooth Pairing Request' : 'Unpair ${device.name ?? 'Device'}?', style: TextStyle(fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.bold)),
                  SizedBox(height: TSizes.defaultSpace / 2),
                  Text(
                    isPairing ? 'Pair with ${device.name ?? 'Unknown Device'}?' : "To connect to this device in the future, you'll need to pair it again.",
                    style: TextStyle(fontSize: TSizes.fontSizeSm, color: dark ? TColors.lightGrey : TColors.darkGrey),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.defaultSpace / 2),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.buttonRadius * 0.8)),
                            padding: EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.defaultSpace / 2),
                          ),
                          child: Text(isPairing ? TTexts.pair : TTexts.unpair, style: TextStyle(color: Colors.white, fontSize: TSizes.fontSizeMd * 0.8, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  /// -- 9. Verify Devices Current Status
  Future<void> verifyDeviceStatus() async {
    if (await Permission.location.request().isGranted) {
      if (await Permission.bluetoothScan.request().isGranted
          && await Permission.bluetoothConnect.request().isGranted
          && await Permission.locationWhenInUse.request().isGranted) {

        /// Update Paired and Connected devices list
        List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
        if (bondedDevices.isNotEmpty) {
          for (var device in bondedDevices) {
            updateDeviceName(device);
            if (device.isConnected) {
              if (!connectedDevices.contains(device)) connectedDevices.add(device);
              pairedDevices.removeWhere((d) => d.address == device.address);
            } else if (device.isBonded && !device.isConnected) {
              if (!pairedDevices.contains(device)) pairedDevices.add(device);
              connectedDevices.removeWhere((d) => d.address == device.address);
            }
          }

          /// Discover new devices and update the list
          newDevices.removeWhere((d) => bondedDevices.any((b) => b.address == d.address));
          filteredDevices.removeWhere((d) => bondedDevices.any((b) => b.address == d.address));
        }
      }
    }
  }

  /// -- 10. Check Device Requirements
  Future<int> checkAllRequirements() async {
    switchController.isBluetoothActive();
    switchController.isLocationActive();

    await Future.delayed(Duration(milliseconds: 400));

    if (!switchController.isBluetoothOn.value) {
      return 1;
    } else if (!switchController.isLocationOn.value) {
      return 2;
    }
    return 0;
  }

  /// -- 11. Show Requirements Messages
  void showRequiredMessage(int i) {
    if (i == 1) {
      TLoaders.warningSnackBar(title: 'Bluetooth Turn On', message: 'Please turn on your device bluetooth');
    } else if (i == 2) {
      TLoaders.warningSnackBar(title: 'Location Turn On', message: 'Please turn on your device location');
    }
  }

  /// -- 12. Search on NewDevices List
  void filterAvailableDevices(String query) {
    query.isEmpty
        ? filteredDevices.assignAll(newDevices)
        : filteredDevices.assignAll(newDevices.where((device) => device.name?.toLowerCase().contains(query.toLowerCase()) ?? false));
  }

  /// -- 13. Update Device Name
  Future<String> updateDeviceName(BluetoothDevice device) async {
    final name = await repository.getBluetoothByMac(device);
    return deviceNames[device.address] = name;
  }

  /// -- 14. Start the background task
  Future<void> startVerifyingDeviceStatus() async {
    while (true) {
      await verifyDeviceStatus();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// -- 15. Stop the background task
  void stopVerifyingDeviceStatus() {
    _timer?.cancel();
    _timer = null;
  }
}
