import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// 应用根组件
class BabyEmrLiteApp extends StatelessWidget {
  const BabyEmrLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '幼儿病例记录',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
