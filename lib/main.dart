import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacy/features/splash/ui/splash_screen.dart';

import 'core/di/dependency_injection.dart';
import 'core/helpers/bloc_observer.dart';
import 'core/helpers/constants.dart';
import 'core/themes/colors.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notification Service
  await NotificationService().initialize();

  Bloc.observer = MyBlocObserver();
  await setupGetIt();
  await checkIsLogged();

  // Update FCM token if user is logged in
  if (isLogged) {
    await NotificationService().updateUserToken(currentUser.uid);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.cairoTextTheme();
    TextStyle? b(TextStyle? s) => s?.copyWith(fontWeight: FontWeight.w800);
    final boldTextTheme = baseTextTheme.copyWith(
      displayLarge: b(baseTextTheme.displayLarge),
      displayMedium: b(baseTextTheme.displayMedium),
      displaySmall: b(baseTextTheme.displaySmall),
      headlineLarge: b(baseTextTheme.headlineLarge),
      headlineMedium: b(baseTextTheme.headlineMedium),
      headlineSmall: b(baseTextTheme.headlineSmall),
      titleLarge: b(baseTextTheme.titleLarge),
      titleMedium: b(baseTextTheme.titleMedium),
      titleSmall: b(baseTextTheme.titleSmall),
      bodyLarge: b(baseTextTheme.bodyLarge),
      bodyMedium: b(baseTextTheme.bodyMedium),
      bodySmall: b(baseTextTheme.bodySmall),
      labelLarge: b(baseTextTheme.labelLarge),
      labelMedium: b(baseTextTheme.labelMedium),
      labelSmall: b(baseTextTheme.labelSmall),
    );

    return MaterialApp(
      title: 'Emad Fawzy Pharmacy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorsManger.cardColor),
        useMaterial3: true,
        // Professional app-wide font (supports Arabic well).
        textTheme: boldTextTheme,
        primaryTextTheme: boldTextTheme,
        fontFamily: GoogleFonts.cairo().fontFamily,
      ),
      home: const SplashScreen(),
    );
  }
}

