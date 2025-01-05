import 'package:flutter/material.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({ super.key, required this.icon, required this.isActive, required this.onTap });

  final IconData icon;
  final bool isActive;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: TSizes.sm),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: isActive ? TColors.white : TColors.grey, size: TSizes.defaultSpace),
        style: IconButton.styleFrom(backgroundColor: isActive ? TColors.primary.withOpacity(0.8) : TColors.darkGrey.withOpacity(0.8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40))),
      ),
    );
  }
}