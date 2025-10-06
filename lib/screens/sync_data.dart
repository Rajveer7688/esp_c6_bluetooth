import 'package:blue/controller/blue_controller.dart';
import 'package:blue/utils/constants/colors.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/device/device_utility.dart';

class SyncDataScreen extends StatelessWidget {
  const SyncDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BluetoothController.instance;
    final minScale = 0.2;
    final maxScale = 4.0;
    final scaleFactor = 0.5;
    return Scaffold(
      appBar: AppBar(backgroundColor: TColors.white, title: Text("Sync Data", style: GoogleFonts.balooBhai2(fontSize: TSizes.fontSizeMd, fontWeight: FontWeight.w600))),
      body: Obx(() {
        if (controller.sensorData.isEmpty) {
          return Center(child: Text('No Data Available here.'));
        }

        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: InteractiveViewer(
            maxScale: maxScale,
            minScale: minScale,
            panEnabled: true,
            constrained: false,
            scaleEnabled: true,
            scaleFactor: scaleFactor,
            panAxis: PanAxis.free,
            clipBehavior: Clip.none,
            alignment: Alignment.topLeft,
            boundaryMargin: EdgeInsets.zero,
            trackpadScrollCausesScale: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(left: TSizes.defaultSpace, right: TSizes.defaultSpace, bottom: TSizes.defaultSpace * 2),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: TDeviceUtils.getScreenWidth(context)),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(topRight: Radius.circular(TSizes.borderRadiusMd), topLeft: Radius.circular(TSizes.borderRadiusMd)),
                  child: DataTable(
                    dividerThickness: 0.5,
                    horizontalMargin: TSizes.md,
                    columnSpacing: TSizes.md,
                    headingTextStyle: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, fontWeight: FontWeight.w500),
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                    border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                    columns: [
                      DataColumn2(label: Text('NO')),
                      DataColumn2(label: Text('HEART')),
                      DataColumn2(label: Text('SPO2')),
                      DataColumn2(label: Text('ACCEL-X')),
                      DataColumn2(label: Text('ACCEL-Y')),
                      DataColumn2(label: Text('ACCEL-Z')),
                      DataColumn2(label: Text('GYRO-X')),
                      DataColumn2(label: Text('GYRO-Y')),
                      DataColumn2(label: Text('GYRO-Z')),
                      DataColumn2(label: Text('TIMESTAMP')),
                    ],
                    rows: controller.sensorData.reversed.map((data) {
                      return DataRow(
                          cells: [
                            DataCell(Text(data!.packetNumber.toString())),
                            DataCell(Text(data.heartRate.toString())),
                            DataCell(Text(data.spO2.toStringAsFixed(1))),
                            DataCell(Text(data.accelX.toString())),
                            DataCell(Text(data.accelY.toString())),
                            DataCell(Text(data.accelZ.toString())),
                            DataCell(Text(data.gyroX.toString())),
                            DataCell(Text(data.gyroY.toString())),
                            DataCell(Text(data.gyroZ.toString())),
                            DataCell(Text(DateFormat('hh:mm a - d MMM').format(data.receivedAt).toString())),
                          ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
