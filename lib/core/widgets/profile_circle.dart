
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileCircle extends StatelessWidget {
  final void Function()? onTap;
  final String? photoUrl;
  /// Radius (not diameter) to match CircleAvatar.radius behavior.
  final double? size;
  const ProfileCircle({super.key, this.onTap, this.photoUrl, this.size});

  @override
  Widget build(BuildContext context) {
    final radius = size ?? 30;
    final url = (photoUrl ?? '').trim();
    final hasUrl = url.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ClipOval(
          child: hasUrl
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 160),
                  placeholder: (context, _) => _placeholder(radius),
                  errorWidget: (context, _, __) => _placeholder(radius),
                )
              : _placeholder(radius),
        ),
      ),
    );
  }

  Widget _placeholder(double radius) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: radius,
        color: Colors.grey.withValues(alpha: 0.7),
      ),
    );
  }
}
