
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileCircle extends StatelessWidget {
  final void Function()? onTap;
  final String? photoUrl;
  final double? size;
  const ProfileCircle({super.key, this.onTap, this.photoUrl, this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size ?? 30,
        backgroundColor: Colors.grey[300],
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
                errorWidget: (context, url, error) {
                  // معالجة الأخطاء - عرض أيقونة افتراضية
                  return Icon(
                    Icons.person,
                    size: (size ?? 30) * 1.2,
                    color: Colors.grey[600],
                  );
                },
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.person,
                size: (size ?? 30) * 1.2,
                color: Colors.grey[600],
              ),
      ),
    );
  }
}
