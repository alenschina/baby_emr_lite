import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'glass_card.dart';

/// 空宝宝状态组件
/// 对齐 Design Spec：玻璃拟态图标容器 + 渐变主按钮
class EmptyBabyState extends StatelessWidget {
  const EmptyBabyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标 - 玻璃拟态容器
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.glassCardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.glassBorder, width: 1),
                boxShadow: AppTheme.subtleShadow,
              ),
              child: const Center(
                child: Text('👶', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 24),

            // 标题
            const Text(
              '开始您的第一个记录',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),

            // 描述
            const Text(
              '添加宝宝信息后即可开始管理病历、疫苗和生长记录',
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 渐变主按钮
            GradientButton(
              text: '立即添加宝宝',
              width: double.infinity,
              onPressed: () => context.go('/data'),
            ),
          ],
        ),
      ),
    );
  }
}
