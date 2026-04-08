import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/baby_providers.dart';
import '../widgets/baby_welcome_card.dart';
import '../widgets/growth_summary_card.dart';
import '../widgets/today_reminders_section.dart';
import '../widgets/empty_baby_state.dart';
import '../widgets/glass_card.dart';

/// 首页屏幕
/// 对齐 Design Spec：
/// - 全局背景：多层径向渐变 + 纵向渐变
/// - 半透明顶栏 + 玻璃拟态卡片
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBabies = ref.watch(hasBabiesProvider);
    final currentBabyAsync = ref.watch(currentBabyProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.appBackgroundDecoration,
        child: SafeArea(
          child: !hasBabies
              ? const EmptyBabyState()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 半透明顶栏
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '首页',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizePageTitle,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                            GlassIconContainer(
                              icon: Icons.settings_outlined,
                              size: 40,
                              iconSize: 20,
                              iconColor: AppTheme.textSecondary,
                              onTap: () => context.go('/data'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 内容区域
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 宝宝欢迎卡片
                          currentBabyAsync.when(
                            data: (baby) => baby != null
                                ? BabyWelcomeCard(baby: baby)
                                : const SizedBox.shrink(),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.brandPrimary,
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 12),

                          // 生长数据摘要
                          const GrowthSummaryCard(),

                          const SizedBox(height: 16),

                          // 今日提醒
                          const TodayRemindersSection(),

                          const SizedBox(height: 120), // 底部留白（给浮动导航栏）
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
