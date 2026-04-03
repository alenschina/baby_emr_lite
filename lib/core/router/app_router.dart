import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/data_management_screen.dart';
import '../../presentation/screens/medical_records_screen.dart';
import '../../presentation/screens/medication_screen.dart';
import '../../presentation/screens/vaccination_screen.dart';
import '../../presentation/screens/growth_screen.dart';
import '../../presentation/widgets/app_shell.dart';

/// 应用路由配置
/// 对应 Web 版路由结构
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // 单例 GoRouter 实例，避免重复创建
  static GoRouter? _router;

  static GoRouter get router {
    _router ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      routes: [
        // Shell 路由 - 带底部导航
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(currentPath: state.uri.path, child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/medical',
              name: 'medical',
              builder: (context, state) => const MedicalRecordsScreen(),
            ),
            GoRoute(
              path: '/medication',
              name: 'medication',
              builder: (context, state) => const MedicationScreen(),
            ),
            GoRoute(
              path: '/vaccination',
              name: 'vaccination',
              builder: (context, state) => const VaccinationScreen(),
            ),
            GoRoute(
              path: '/growth',
              name: 'growth',
              builder: (context, state) => const GrowthScreen(),
            ),
          ],
        ),

        // 独立页面 - 不带底部导航
        GoRoute(
          path: '/data',
          name: 'data',
          builder: (context, state) => const DataManagementScreen(),
        ),
      ],
    );
    return _router!;
  }
}

/// 路由名称常量
class RouteNames {
  static const String home = 'home';
  static const String medical = 'medical';
  static const String medication = 'medication';
  static const String vaccination = 'vaccination';
  static const String growth = 'growth';
  static const String data = 'data';
}

/// 路由路径常量
class RoutePaths {
  static const String home = '/';
  static const String medical = '/medical';
  static const String medication = '/medication';
  static const String vaccination = '/vaccination';
  static const String growth = '/growth';
  static const String data = '/data';
}
