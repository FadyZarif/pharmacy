import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/core/widgets/app_text_form_field.dart';
import 'package:pharmacy/features/login/data/models/user_model.dart';

import '../../../core/widgets/profile_circle.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Profile',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: ColorsManger.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 25,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    /// profile photo
                    ProfileCircle(photoUrl: user.photoUrl,size: 100,),
                    /// name
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    /// role
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16,vertical:4),
                      decoration: BoxDecoration(
                        color: ColorsManger.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    /// branch
                    Text(
                      user.branchName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  spacing: 15,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Information
                    Text('Employee Information',style: TextStyle(fontSize: 20,fontWeight:FontWeight.w600,),),
                    /// Email
                    AppTextFormField(
                      controller: TextEditingController(text: user.email),
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      readOnly: true,
                    ),
                    /// Phone
                    AppTextFormField(
                      controller: TextEditingController(text: user.phone),
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone),
                      readOnly: true,
                    ),
                    /// shift hours
                    AppTextFormField(
                      controller: TextEditingController(text: '${user.shiftHours} Hours',),
                      labelText: 'Shift Hours',
                      prefixIcon: Icon(Icons.schedule),
                      readOnly: true,
                    ),
                    /// print code
                    AppTextFormField(
                      controller: TextEditingController(text: user.printCode??'N/A',),
                      labelText: 'Print Code',
                      prefixIcon: Icon(Icons.fingerprint),
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

      ),
      ),
    );
  }
}
