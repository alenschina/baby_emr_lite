import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// 应用外壳组件
/// 包含浮动胶囊底部导航栏，对齐 Design Spec：
/// - 浮动胶囊：bg-white/70 backdrop-blur-xl border border-white/60 rounded-3xl
/// - 单项：最小宽度 54px；图标 22px；文字 11px；Active 为 brand.primary
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppShell({super.key, required this.child, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _FloatingNavBar(currentPath: currentPath),
    );
  }
}

/// 浮动胶囊底部导航栏 - Liquid 风格
class _FloatingNavBar extends StatelessWidget {
  final String currentPath;

  const _FloatingNavBar({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: AppTheme.liquidNavDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: '首页',
                isActive: currentPath == '/',
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.medical_services_rounded,
                label: '病例',
                isActive: currentPath == '/medical',
                onTap: () => context.go('/medical'),
              ),
              _NavItem(
                icon: Icons.medication_rounded,
                label: '用药',
                isActive: currentPath == '/medication',
                onTap: () => context.go('/medication'),
              ),
              _NavItem(
                icon: Icons.vaccines_rounded,
                label: '疫苗',
                isActive: currentPath == '/vaccination',
                onTap: () => context.go('/vaccination'),
              ),
              _NavItem(
                icon: Icons.trending_up_rounded,
                label: '生长',
                isActive: currentPath == '/growth',
                onTap: () => context.go('/growth'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(minWidth: 54),
        decoration: isActive
            ? AppTheme.liquidNavItemActiveDecoration()
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.brandPrimary : AppTheme.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMicro,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.brandPrimary : AppTheme.textTertiary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
