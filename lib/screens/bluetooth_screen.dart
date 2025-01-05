import 'package:blue/screens/widgets/bluetooth_layout.dart';
import 'package:blue/utils/constants/colors.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:blue/utils/constants/text_strings.dart';
import 'package:blue/utils/device/device_utility.dart';
import 'package:blue/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controller/blue_controller.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({ super.key });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BluetoothController());
    final dark = THelperFunctions.isDarkMode(context);
    return Obx(() => Stack(
      alignment: Alignment.center,
      children: [
        // <!----- Code for Bluetooth Devices actions ----->
        SizedBox(
          height: TDeviceUtils.getScreenHeight(),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// -- Search Bar
                TextField(
                  onChanged: (value) => controller.filterAvailableDevices(value),
                  decoration: InputDecoration(
                    hintText: 'Search new devices',
                    prefixIcon: Icon(Iconsax.search_normal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.transparent, width: 2)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.transparent, width: 1)),
                    filled: true,
                    fillColor: dark ? TColors.darkContainer : TColors.light,
                  ),
                ),
                SizedBox(height: TSizes.md),

                /// -- Connected Devices List
                if (controller.connectedDevices.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connected devices', style: TextStyle(color: dark ? TColors.lightGrey : TColors.darkGrey, fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w600)),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: controller.connectedDevices.length,
                        itemBuilder: (context, index) {
                          var device = controller.connectedDevices[index];
                          return BluetoothLayout(device: device, isConnected: true);
                        },
                      ),
                    ],
                  ),
                if (controller.connectedDevices.isNotEmpty) SizedBox(height: TSizes.lg),

                /// -- Paired Devices List
                if (controller.pairedDevices.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paired devices', style: TextStyle(color: dark ? TColors.lightGrey : TColors.darkGrey, fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w600)),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: controller.pairedDevices.length,
                        itemBuilder: (context, index) {
                          var device = controller.pairedDevices[index];
                          return BluetoothLayout(device: device, isPaired: true);
                        },
                      ),
                    ],
                  ),
                if (controller.pairedDevices.isNotEmpty) SizedBox(height: TSizes.lg),

                /// -- New Devices List
                Obx(() {
                  return controller.filteredDevices.isNotEmpty ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available devices', style: TextStyle(color: dark ? TColors.lightGrey : TColors.darkGrey, fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w600)),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: controller.filteredDevices.length,
                        itemBuilder: (context, index) {
                          var device = controller.filteredDevices[index];
                          return BluetoothLayout(device: device);
                        },
                      ),
                    ],
                  ) : SizedBox.shrink();
                }),
              ],
            ),
          ),
        ),

        // <!----- Code for Bluetooth Scan Button ----->
        Positioned(
          bottom: 10,
          child: TextButton(
              onPressed: () => controller.scanDevices(),
              style: TextButton.styleFrom(
                minimumSize: Size(180, 52),
                maximumSize: Size(180, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                backgroundColor: TColors.primary
              ),
              child: controller.isScanning.value ? SpinKitThreeBounce(color: TColors.white, size: 18) : Text(TTexts.scan, style: TextStyle(color: TColors.white, fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.w400))
          )
        )
      ],
    ));
  }
}

