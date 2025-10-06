import 'package:blue/screens/sync_data.dart';
import 'package:blue/screens/widgets/button_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../controller/blue_controller.dart';
import '../utils/constants/colors.dart';
import '../utils/constants/sizes.dart';
import '../utils/constants/text_strings.dart';
import '../utils/helpers/helper_functions.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BluetoothController());
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TTexts.homeAppbarTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.recursive(fontSize: TSizes.fontSizeLg, fontWeight: FontWeight.w800)),
            Text(TTexts.homeAppbarSubTitle, style: GoogleFonts.inter(fontSize: TSizes.fontSizeSm, color: Colors.grey, fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          Obx(() => ButtonWidget(icon: Iconsax.refresh, isActive: controller.isConnected.value, onTap: () => controller.getMemoryInfo())),
          Obx(() => ButtonWidget(icon: Iconsax.cloud_connection, isActive: controller.isConnected.value, onTap: () => Get.to(() => SyncDataScreen()))),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Obx(() => Padding(
          padding: EdgeInsets.only(left: TSizes.defaultSpace, right: TSizes.defaultSpace, top: TSizes.defaultSpace),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.lg),
                  decoration: BoxDecoration(
                      color: (controller.isConnected.value ? Colors.green : controller.isScanning.value ? Colors.orange : Colors.red).shade50,
                      border: Border.all(color: controller.isConnected.value ? Colors.green : controller.isScanning.value ? Colors.orange : Colors.red),
                      borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)
                  ),
                  child: Text(controller.statusMessage.value, style: GoogleFonts.recursive(color: controller.isConnected.value ? Colors.green : controller.isScanning.value ? Colors.orange : Colors.red)),
                ),
                SizedBox(height: TSizes.spaceBtwItems),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: TSizes.defaultSpace,
                  children: [
                    Obx(() => mainButton(controller.isConnected.value ? "Disconnect" : "Connect", controller.isConnected.value ? Iconsax.link_21 : Iconsax.link, () => controller.isConnected.value ? controller.disconnect() : controller.startScan())),
                    Obx(() => mainButton((controller.isConnected.value && controller.isSyncing.value) ? "Stop Sync" : "Sync Data", (controller.isConnected.value && controller.isSyncing.value) ? Iconsax.stop_circle : Iconsax.repeat, () => (controller.isConnected.value && controller.isSyncing.value) ? controller.stopSyncData() : controller.syncData())),
                  ],
                ),
                SizedBox(height: TSizes.spaceBtwItems),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: TSizes.defaultSpace,
                  children: [
                    mainButton("Get Info", Iconsax.information, () => controller.getMemoryInfo()),
                    mainButton("Erase Data", Iconsax.trush_square, () => controller.eraseData()),
                  ],
                ),
                SizedBox(height: TSizes.spaceBtwSections),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: TSizes.md,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                        decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                        child: Center(child: Column(
                          children: [
                            Text(controller.heartBeatCurrent.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeFl, color: TColors.primary, fontWeight: FontWeight.w600)),
                            Text('Heart Rate', style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w400)),
                          ],
                        )),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                        decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                        child: Center(child: Column(
                          children: [
                            Text(controller.spo2Current.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeFl, color: TColors.primary, fontWeight: FontWeight.w600)),
                            Text('Spo2', style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w400)),
                          ],
                        )),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: TSizes.spaceBtwItems),

                Container(
                  padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                  decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: TSizes.md,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: TSizes.md),
                        child: Row(
                          spacing: TSizes.md,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                                decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                                child: Center(child: Column(
                                  children: [
                                    Text(controller.accelXCurrent.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                )),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                                decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                                child: Center(child: Column(
                                  children: [
                                    Text(controller.accelYCurrent.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                )),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                                decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                                child: Center(child: Column(
                                  children: [
                                    Text(controller.accelZCurrent.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('Accelerometer', style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                SizedBox(height: TSizes.spaceBtwItems),

                Container(
                  padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                  decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: TSizes.md,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: TSizes.md),
                        child: Row(
                          spacing: TSizes.md,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                                decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                                child: Center(child: Column(
                                  children: [
                                    Text(controller.gyroXCurrent.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                )),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                                decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                                child: Center(child: Column(
                                  children: [
                                    Text(controller.gyroYCurrent.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                )),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsetsGeometry.symmetric(vertical: TSizes.md),
                                decoration: BoxDecoration(color: TColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(TSizes.borderRadiusMd)),
                                child: Center(child: Column(
                                  children: [
                                    Text(controller.gyroZCurrent.value.toString(), style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('Gyroscope', style: GoogleFonts.recursive(fontSize: TSizes.fontSizeXs, color: TColors.primary, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                SizedBox(height: TSizes.spaceBtwSections),

                AspectRatio(
                  aspectRatio: 1,
                  child: Obx(() {
                    final datasets = [controller.bpmPoints, controller.spo2Points];
                    final colors = [TColors.primary, TColors.secondary];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Heart Rate'.toUpperCase(), style: GoogleFonts.nunito(fontSize: TSizes.fontSizeXs, color: Colors.grey, fontWeight: FontWeight.w500)),
                        SizedBox(height: TSizes.sm),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(color: TColors.light.withValues(alpha: 0.2)),
                          margin: EdgeInsets.all(TSizes.sm),
                          child: LineChart(
                            transformationConfig: FlTransformationConfig(trackpadScrollCausesScale: true),
                            LineChartData(
                              lineBarsData: List.generate(datasets.length, (i) => LineChartBarData(
                                  spots: datasets[i],
                                  isCurved: true,
                                  curveSmoothness: 0.5,
                                  isStepLineChart: false,
                                  isStrokeJoinRound: true,
                                  isStrokeCapRound: true,
                                  preventCurveOverShooting: true,
                                  color: colors[i],
                                  barWidth: 2,
                                  dotData: FlDotData(show: false)
                              )),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, minIncluded: true, maxIncluded: false, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.balooBhai2(fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w400)))),
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, minIncluded: true, maxIncluded: false, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.balooBhai2(fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w400)))),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(drawHorizontalLine: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: TColors.grey, dashArray: [8], strokeWidth: 1), getDrawingVerticalLine: (value) => FlLine(color: TColors.grey, dashArray: [8], strokeWidth: 1)),
                              borderData: FlBorderData(border: Border(left: BorderSide(color: TColors.grey), bottom: BorderSide(color: TColors.grey), top: BorderSide(color: Colors.transparent), right: BorderSide(color: Colors.transparent))),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  fitInsideVertically: true,
                                  fitInsideHorizontally: true,
                                  tooltipRoundedRadius: TSizes.xs,
                                  getTooltipColor: (color) => dark ? TColors.white.withValues(alpha: 0.9) : TColors.black.withValues(alpha: 0.8),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((touchedSpot) {
                                      final lineColor = dark ? TColors.black : TColors.white;
                                      final lineName = touchedSpot.barIndex == 0 ? 'BPM' : 'SPO2';
                                      return LineTooltipItem('$lineName: ${touchedSpot.y.toStringAsFixed(2)}', textAlign: TextAlign.start, GoogleFonts.balooBhai2(color: lineColor, fontSize: TSizes.fontSizeXs, fontWeight: FontWeight.bold));
                                    }).toList();
                                  },
                                ),
                                getTouchedSpotIndicator: (barData, spotIndexes) {
                                  final lineColor = barData.color ?? TColors.primary;
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(color: Colors.transparent),
                                      FlDotData(show: true, getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(strokeWidth: 2, color: lineColor, radius: 5, strokeColor: lineColor), checkToShowDot: (spot, barData) => true),
                                    );
                                  }).toList();
                                },
                                handleBuiltInTouches: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                SizedBox(height: TSizes.spaceBtwSections),

                AspectRatio(
                  aspectRatio: 1,
                  child: Obx(() {
                    final datasets = [controller.accelXPoints, controller.accelYPoints, controller.accelZPoints];
                    final colors = [TColors.primary, TColors.secondary, Colors.deepPurple];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Accelerometer'.toUpperCase(), style: GoogleFonts.nunito(fontSize: TSizes.fontSizeXs, color: Colors.grey, fontWeight: FontWeight.w500)),
                        SizedBox(height: TSizes.sm),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(color: TColors.light.withValues(alpha: 0.2)),
                          margin: EdgeInsets.all(TSizes.sm),
                          child: LineChart(
                            transformationConfig: FlTransformationConfig(trackpadScrollCausesScale: true),
                            LineChartData(
                              lineBarsData: List.generate(datasets.length, (i) => LineChartBarData(
                                  spots: datasets[i],
                                  isCurved: true,
                                  curveSmoothness: 0.5,
                                  isStepLineChart: false,
                                  isStrokeJoinRound: true,
                                  isStrokeCapRound: true,
                                  preventCurveOverShooting: true,
                                  color: colors[i],
                                  barWidth: 2,
                                  dotData: FlDotData(show: false)
                              )),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, minIncluded: true, maxIncluded: false, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.balooBhai2(fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w400)))),
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, minIncluded: true, maxIncluded: false, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.balooBhai2(fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w400)))),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(drawHorizontalLine: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: TColors.grey, dashArray: [8], strokeWidth: 1), getDrawingVerticalLine: (value) => FlLine(color: TColors.grey, dashArray: [8], strokeWidth: 1)),
                              borderData: FlBorderData(border: Border(left: BorderSide(color: TColors.grey), bottom: BorderSide(color: TColors.grey), top: BorderSide(color: Colors.transparent), right: BorderSide(color: Colors.transparent))),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  fitInsideVertically: true,
                                  fitInsideHorizontally: true,
                                  tooltipRoundedRadius: TSizes.xs,
                                  getTooltipColor: (color) => dark ? TColors.white.withValues(alpha: 0.9) : TColors.black.withValues(alpha: 0.8),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((touchedSpot) {
                                      final lineColor = dark ? TColors.black : TColors.white;
                                      final lineName = touchedSpot.barIndex == 0 ? 'X' : touchedSpot.barIndex == 1 ? 'Y' : 'Z';
                                      return LineTooltipItem('$lineName: ${touchedSpot.y.toStringAsFixed(2)}', textAlign: TextAlign.start, GoogleFonts.balooBhai2(color: lineColor, fontSize: TSizes.fontSizeXs, fontWeight: FontWeight.bold));
                                    }).toList();
                                  },
                                ),
                                getTouchedSpotIndicator: (barData, spotIndexes) {
                                  final lineColor = barData.color ?? TColors.primary;
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(color: Colors.transparent),
                                      FlDotData(show: true, getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(strokeWidth: 2, color: lineColor, radius: 5, strokeColor: lineColor), checkToShowDot: (spot, barData) => true),
                                    );
                                  }).toList();
                                },
                                handleBuiltInTouches: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                SizedBox(height: TSizes.spaceBtwSections),

                AspectRatio(
                  aspectRatio: 1,
                  child: Obx(() {
                    final datasets = [controller.gyroXPoints, controller.gyroYPoints, controller.gyroZPoints];
                    final colors = [TColors.primary, TColors.secondary, Colors.orange];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gyroscope'.toUpperCase(), style: GoogleFonts.nunito(fontSize: TSizes.fontSizeXs, color: Colors.grey, fontWeight: FontWeight.w500)),
                        SizedBox(height: TSizes.sm),
                        Container(
                          height: 250,
                          decoration: BoxDecoration(color: TColors.light.withValues(alpha: 0.2)),
                          margin: EdgeInsets.all(TSizes.sm),
                          child: LineChart(
                            transformationConfig: FlTransformationConfig(trackpadScrollCausesScale: true),
                            LineChartData(
                              lineBarsData: List.generate(datasets.length, (i) => LineChartBarData(
                                  spots: datasets[i],
                                  isCurved: true,
                                  curveSmoothness: 0.5,
                                  isStepLineChart: false,
                                  isStrokeJoinRound: true,
                                  isStrokeCapRound: true,
                                  preventCurveOverShooting: true,
                                  color: colors[i],
                                  barWidth: 2,
                                  dotData: FlDotData(show: false)
                              )),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, minIncluded: false, maxIncluded: false, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.balooBhai2(fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w400)))),
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, minIncluded: false, reservedSize: 50, maxIncluded: false, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.balooBhai2(fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w400)))),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(drawHorizontalLine: true, drawVerticalLine: true, getDrawingHorizontalLine: (value) => FlLine(color: TColors.grey, dashArray: [8], strokeWidth: 1), getDrawingVerticalLine: (value) => FlLine(color: TColors.grey, dashArray: [8], strokeWidth: 1)),
                              borderData: FlBorderData(border: Border(left: BorderSide(color: TColors.grey), bottom: BorderSide(color: TColors.grey), top: BorderSide(color: Colors.transparent), right: BorderSide(color: Colors.transparent))),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  fitInsideVertically: true,
                                  fitInsideHorizontally: true,
                                  tooltipRoundedRadius: TSizes.xs,
                                  getTooltipColor: (color) => dark ? TColors.white.withValues(alpha: 0.9) : TColors.black.withValues(alpha: 0.8),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((touchedSpot) {
                                      final lineColor = dark ? TColors.black : TColors.white;
                                      final lineName = touchedSpot.barIndex == 0 ? 'X' : touchedSpot.barIndex == 1 ? 'Y' : 'Z';
                                      return LineTooltipItem('$lineName: ${touchedSpot.y.toStringAsFixed(2)}', textAlign: TextAlign.start, GoogleFonts.balooBhai2(color: lineColor, fontSize: TSizes.fontSizeXs, fontWeight: FontWeight.bold));
                                    }).toList();
                                  },
                                ),
                                getTouchedSpotIndicator: (barData, spotIndexes) {
                                  final lineColor = barData.color ?? TColors.primary;
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(color: Colors.transparent),
                                      FlDotData(show: true, getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(strokeWidth: 2, color: lineColor, radius: 5, strokeColor: lineColor), checkToShowDot: (spot, barData) => true),
                                    );
                                  }).toList();
                                },
                                handleBuiltInTouches: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                SizedBox(height: TSizes.spaceBtwSections),
              ],
            ),
        ),
        ),
      ),
    );
  }

  Expanded mainButton(String title, IconData iconData, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: TColors.primary, borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)),
          padding: EdgeInsets.symmetric(vertical: TSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: TSizes.sm,
            children: [
              Icon(iconData, color: TColors.white, size: TSizes.iconMd),
              Text(title, style: GoogleFonts.recursive(color: TColors.white, fontSize: TSizes.fontSizeSm, fontWeight: FontWeight.w500))
            ],
          ),
        ),
      ),
    );
  }
}
