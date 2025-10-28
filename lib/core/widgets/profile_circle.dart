
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';


class ProfileCircle extends StatelessWidget {
  final void Function()? onTap;
  final String? photoUrl;
  final double? size;
  const ProfileCircle ({super.key, this.onTap, this.photoUrl, this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size??30,
        backgroundImage: CachedNetworkImageProvider(
          photoUrl ??
              'https://www.shutterstock.com/image-vector/avatar-gender-neutral-silhouette-vector-600nw-2470054311.jpg',
        ),
      ),
    )
    ;
  }
}
