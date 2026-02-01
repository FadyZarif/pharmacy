import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/request/logic/request_cubit.dart';

import '../../../request/data/models/request_model.dart';

class RequestItem {
  final RequestType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  RequestItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });
}

class RequestTile extends StatelessWidget {
  final RequestItem item;
  final RequestCubit requestCubit;

  const RequestTile({super.key, required this.item, required this.requestCubit});


  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(item.icon)),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          HapticFeedback.mediumImpact();
          // إغلاق الـ bottom sheet
          Navigator.of(context).pop();
          // الانتقال للشاشة الموحدة
          navigateTo(
            context,
            item.screen,
          );
        },
      ),
    );
  }
}
