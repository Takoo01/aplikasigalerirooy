import 'package:flutter/material.dart';
import 'package:galleryapp/common/common.dart';
import 'package:galleryapp/auth/login_page.dart';
import 'package:galleryapp/main_page.dart';
import 'package:galleryapp/widgets/widgets.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  void splashing(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 5), () {
        // Navigate to MainPage after 3 seconds
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    splashing(context);

    return const Scaffold(
      body: Center(
        child: AppLogo(), // Your logo widget
      ),
    );
  }
}
