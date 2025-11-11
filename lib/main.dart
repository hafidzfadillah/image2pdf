import 'package:flutter/material.dart';
import 'package:image_to_pdf/core/theme/app_theme.dart';
import 'package:image_to_pdf/core/constants/app_constants.dart';
import 'package:image_to_pdf/features/camera/screens/camera_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const CameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
