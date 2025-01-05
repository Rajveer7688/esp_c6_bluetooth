import 'package:blue/controller/switch_controller.dart';
import 'package:blue/screens/bluetooth_screen.dart';
import 'package:blue/screens/widgets/button_widget.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:blue/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final switchController = Get.put(SwitchController());
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TTexts.homeAppbarTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(TTexts.homeAppbarSubTitle, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          Obx(() => ButtonWidget(icon: Iconsax.bluetooth, isActive: switchController.isBluetoothOn.value, onTap: () => switchController.isBluetoothActive())),
          Obx(() => ButtonWidget(icon: Iconsax.location, isActive: switchController.isLocationOn.value, onTap: () => switchController.isLocationActive())),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: BluetoothScreen(),
      ),
    );
  }
}


/// -- Switch buttons UI for Bluetooth and Wi-Fi Screens
/*
Container(
            margin: EdgeInsets.all(TSizes.defaultSpace),
            height: TSizes.defaultSpace * 1.6,
            decoration: BoxDecoration(color: dark ? TColors.dark : TColors.light, borderRadius: BorderRadius.circular(40)),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => switchController.selectedIndex.value = 0,
                    child: OptionTile(label: TTexts.bluetooth, isSelected: switchController.selectedIndex.value == 0),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => switchController.selectedIndex.value = 1,
                    child: OptionTile(label: TTexts.wifi, isSelected: switchController.selectedIndex.value == 1),
                  ),
                ),
              ],
            ),
            ),
          ),

          Expanded(
            child: Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: AnimatedSwitcher(duration: Duration(milliseconds: 300), child: switchController.screens[switchController.selectedIndex.value]),
            ),
            ),
          ),
 */