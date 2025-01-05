import 'package:blue/utils/constants/colors.dart';
import 'package:blue/utils/constants/sizes.dart';
import 'package:blue/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({super.key, required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems, vertical: TSizes.spaceBtwItems / 2),
      decoration: BoxDecoration(color: isSelected ? TColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(TSizes.borderRadiusXl)),
      child: Center(child: Text(label, style: GoogleFonts.recursive(color: isSelected ? TColors.white : dark ? TColors.grey : TColors.darkGrey, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
    );
  }
}