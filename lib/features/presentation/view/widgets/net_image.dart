import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class NetImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? radius;
  final BoxFit fit;
  final Color placeholderColor;
  final Border? border;
  final double opacity;

  const NetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius,
    this.fit = BoxFit.cover,
    this.placeholderColor = AppColors.textFaint,
    this.border,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    Widget child;
    if (hasUrl) {
      child = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => Container(color: AppColors.border),
        errorWidget: (_, __, ___) => Container(color: placeholderColor),
      );
    } else {
      child = Container(width: width, height: height, color: placeholderColor);
    }

    if (opacity < 1) child = Opacity(opacity: opacity, child: child);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(borderRadius: radius, border: border),
      clipBehavior: radius != null ? Clip.antiAlias : Clip.none,
      child: child,
    );
  }
}
