import 'package:blue/utils/constants/colors.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:blue/utils/constants/text_strings.dart';
import 'package:blue/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controller/blue_controller.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BluetoothController());
    final dark = THelperFunctions.isDarkMode(context);
    return Obx(() => Stack(
          alignment: Alignment.center,
          children: [
            // <!----- Code for Bluetooth Devices actions ----->
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// -- Connected Devices List
                if (controller.connectedDevices.isNotEmpty)
                  Text('Connected devices',
                      style: TextStyle(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          fontSize: TSizes.fontSizeSm,
                          fontWeight: FontWeight.w600)),
                if (controller.connectedDevices.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.connectedDevices.length,
                      itemBuilder: (context, index) {
                        var device = controller.connectedDevices[index];
                        return BluetoothLayout(
                            device: device, isConnected: true);
                      },
                    ),
                  ),

                /// -- Paired Devices List
                if (controller.pairedDevices.isNotEmpty)
                  Text('Paired devices',
                      style: TextStyle(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          fontSize: TSizes.fontSizeSm,
                          fontWeight: FontWeight.w600)),
                if (controller.pairedDevices.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.pairedDevices.length,
                      itemBuilder: (context, index) {
                        var device = controller.pairedDevices[index];
                        return BluetoothLayout(device: device, isPaired: true);
                      },
                    ),
                  ),

                /// -- New Devices List
                if (controller.newDevices.isNotEmpty)
                  Text('Available devices',
                      style: TextStyle(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          fontSize: TSizes.fontSizeSm,
                          fontWeight: FontWeight.w600)),
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.newDevices.length,
                    itemBuilder: (context, index) {
                      var device = controller.newDevices[index];
                      return BluetoothLayout(device: device);
                    },
                  ),
                ),
              ],
            ),

            // <!----- Code for Bluetooth Scan Button ----->
            Positioned(
                bottom: 30,
                child: TextButton(
                    onPressed: () => controller.scanDevices(),
                    style: TextButton.styleFrom(
                        minimumSize: Size(180, 52),
                        maximumSize: Size(180, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40)),
                        backgroundColor: TColors.primary),
                    child: controller.isScanning.value
                        ? SpinKitThreeBounce(color: TColors.white, size: 18)
                        : Text(TTexts.scan,
                            style: TextStyle(
                                color: TColors.white,
                                fontSize: TSizes.fontSizeMd,
                                fontWeight: FontWeight.w400))))
          ],
        ));
  }
}

class BluetoothLayout extends StatelessWidget {
  const BluetoothLayout(
      {super.key,
      required this.device,
      this.isPaired = false,
      this.isConnected = false});
  final BluetoothDevice device;
  final bool isPaired, isConnected;

  @override
  Widget build(BuildContext context) {
    final controller = BluetoothController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: TSizes.sm),
      padding: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
          color: dark ? TColors.dark : TColors.lightGrey.withOpacity(0.8),
          borderRadius: BorderRadius.circular(TSizes.sm),
          shape: BoxShape.rectangle),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                    onTap: () => isConnected ? controller.scanDevices() : {},
                    child: Text(controller.deviceNames[device.address] ?? device.name ?? 'Unknow Device',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: TSizes.fontSizeMd,
                              fontWeight: FontWeight.w600)),
                    ),
                Row(
                  children: [
                    isConnected
                        ? Container(
                            width: 6,
                            height: 6,
                            margin: EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                                color: TColors.success, shape: BoxShape.circle))
                        : SizedBox(),
                    Text(isConnected ? TTexts.connected : device.address,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: TSizes.fontSizeSm,
                            fontWeight: FontWeight.w300)),
                  ],
                )
              ],
            ),
          ),
          SizedBox(width: TSizes.md),
          Row(
            children: [
              Text('|', style: TextStyle(color: Colors.grey)),
              SizedBox(width: TSizes.md),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: dark ? TColors.black : TColors.primaryBackground,
                    shape: BoxShape.circle),
                child: IconButton(
                  onPressed: () => isPaired
                    //  ? controller.connectDevice(device)
                    ? controller.showRenameDialog(context, device)
                      : isConnected
                          ? controller.disconnectDevice(
                              device,context
                            )
                          : controller.pairDevice(device, context),
                  icon: Icon(
                      isPaired
                          ? Iconsax.link
                          : isConnected
                              ? Iconsax.bluetooth_2
                              : Iconsax.add,
                      color: TColors.primary,
                      size: 18),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
