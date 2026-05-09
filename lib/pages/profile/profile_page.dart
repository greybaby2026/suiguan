import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(title: const Text('个人中心')),
      body: const Center(
        child: Text('个人中心'),
      ),
    );
  }
}
