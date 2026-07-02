import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class Logo extends StatelessWidget {
  final double fontSize;
  final TextAlign align;
  const Logo({super.key, this.fontSize = 22, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: align,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          color: AppColors.logo,
        ),
        children: const [
          TextSpan(text: 'F'),
          TextSpan(
            text: 'COMIC',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
