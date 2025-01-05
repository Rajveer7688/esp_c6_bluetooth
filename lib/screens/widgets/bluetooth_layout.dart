import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../controller/blue_controller.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_strings.dart';
import '../../utils/helpers/helper_functions.dart';

class BluetoothLayout extends StatelessWidget {
  const BluetoothLayout({ super.key, required this.device, this.isPaired = false, this.isConnected = false });
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
      decoration: BoxDecoration(color: dark ? TColors.dark : TColors.lightGrey.withOpacity(0.6), borderRadius: BorderRadius.circular(TSizes.sm), shape: BoxShape.rectangle),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => isConnected ? controller.renameDevice(context, device) : {},
                  child: Obx(() {
                    controller.updateDeviceName(device);
                    final deviceName = controller.deviceNames[device.address] ?? 'Unknown Device';
                    return Text(deviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.w600));
                  }),
                ),
                Row(
                  children: [
                    isConnected ? Container(width: 6, height: 6, margin: EdgeInsets.only(right: 6), decoration: BoxDecoration(color: TColors.success, shape: BoxShape.circle)) : SizedBox(),
                    Text(isConnected ? TTexts.connected : device.address, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w300)),
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
                decoration: BoxDecoration(color: dark ? TColors.black : TColors.primaryBackground, shape: BoxShape.circle),
                child: IconButton(
                  onPressed: () => isPaired ? controller.connectDevice(device, context) : isConnected ? controller.disconnectDevice(device, context) : controller.pairDevice(device, context),
                  icon: Icon(isPaired ? Iconsax.link : isConnected ? Iconsax.bluetooth_2 : Iconsax.add, color: TColors.primary, size: 18),
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