import 'package:flutter/material.dart';

/// 应用主题配置
/// 完全对齐 UI Design Spec 设计规范
/// 风格：轻盈、柔和、医疗可信、玻璃拟态（Glassmorphism）、大圆角、低对比阴影
/// 主色调：紫蓝色系 (#6B5CE7)
class AppTheme {
  // ==================== 核心品牌色 ====================
  /// Primary - 主按钮、强调色、关键数据（紫蓝色）
  static const Color brandPrimary = Color(0xFF6B5CE7);

  /// Secondary - 轻背景辅助色
  static const Color brandSecondary = Color(0xFFEEF1FF);

  /// Text Primary - 主要正文色
  static const Color textPrimary = Color(0xFF1B2340);

  // ==================== 文本色阶 ====================
  /// Text/Primary - 标题、正文
  static const Color brandDark = Color(0xFF1B2340);

  /// Text/Secondary - 次级说明、时间等
  static const Color textSecondary = Color(0xFF475569);
  static const Color slate600 = Color(0xFF475569);

  /// Text/Tertiary - 占位符、弱提示
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);

  // ==================== 功能色（Status） ====================
  /// Success - 已完成、成功提示
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  /// Warning - 库存低等提醒
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Danger - 删除、错误
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  /// Info
  static const Color info = Color(0xFF3B82F6);

  // ==================== 背景与表面（Surface） ====================
  /// 全局背景色
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color brandLight = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  /// 玻璃拟态卡片背景
  static Color get glassBackground => Colors.white.withOpacity(0.7);
  static Color get glassBackgroundHigh => Colors.white.withOpacity(0.8);
  static Color get glassBorder => Colors.white.withOpacity(0.6);
  static Color get glassInputBackground => Colors.white.withOpacity(0.6);

  // ==================== 字体配置 ====================
  /// 抖音美好体
  static const String fontFamily = 'DouyinSans';

  /// 字号/字重规范
  static const double fontSizePageTitle = 18; // Page Title - 顶栏标题
  static const double fontSizeSectionTitle = 16; // Section Title - 分组标题
  static const double fontSizeCardTitle = 16; // Card Title - 卡片主标题
  static const double fontSizeBody = 14; // Body - 正文
  static const double fontSizeCaption = 12; // Caption - 辅助信息
  static const double fontSizeMicro = 11; // Micro - 标签/导航

  // ==================== 间距规范（8pt 基准） ====================
  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing5 = 24;
  static const double spacing6 = 32;

  /// 页面左右内边距
  static const double pageHorizontalPadding = 16;

  /// 卡片内边距
  static const double cardPadding = 16;
  static const double cardPaddingLarge = 20;
  static const double cardPaddingXLarge = 24;

  /// 列表卡片间距
  static const double listItemSpacing = 12;
  static const double listItemSpacingLarge = 16;

  /// SnackBar（floating）相对 M3 默认 `insetPadding.bottom`(10) 额外上移的留白（像素）。
  static const double snackBarExtraBottomInset = 2;

  /// SnackBar 展示时长（框架默认 4s，此处缩短以便快速消失）。
  static const Duration snackBarDisplayDuration = Duration(seconds: 1);

  // ==================== 圆角规范 ====================
  /// 主要卡片 rounded-3xl
  static const double radiusCard = 24;

  /// 输入框 rounded-2xl
  static const double radiusInput = 16;

  /// 图标容器 rounded-2xl
  static const double radiusIconContainer = 16;

  /// 按钮 rounded-2xl 或 rounded-full
  static const double radiusButton = 16;

  /// 底部导航容器 rounded-3xl
  static const double radiusNav = 24;

  /// 小标签
  static const double radiusSmall = 20;
  static const double radiusXSmall = 12;

  // ==================== 阴影规范 ====================
  /// 卡片阴影：shadow-[0_18px_45px_rgba(17,24,39,0.08)]
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.08),
      blurRadius: 45,
      offset: const Offset(0, 18),
    ),
  ];

  /// 顶栏/导航阴影：shadow-[0_12px_30px_rgba(17,24,39,0.12)]
  static List<BoxShadow> get navShadow => [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.12),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  /// 浮动按钮阴影：shadow-[0_20px_50px_rgba(91,90,246,0.45)]
  static List<BoxShadow> get fabShadow => [
    BoxShadow(
      color: brandPrimary.withOpacity(0.45),
      blurRadius: 50,
      offset: const Offset(0, 20),
    ),
  ];

  /// Liquid 风格 FAB 阴影 - 多层柔和流体效果
  static List<BoxShadow> get liquidFabShadow => [
    // 主阴影 - 柔和扩散的紫蓝色
    BoxShadow(
      color: brandPrimary.withOpacity(0.35),
      blurRadius: 35,
      spreadRadius: -5,
      offset: const Offset(0, 15),
    ),
    // 次级阴影 - 粉色光晕
    BoxShadow(
      color: const Color(0xFFFF6BBD).withOpacity(0.2),
      blurRadius: 25,
      spreadRadius: -3,
      offset: const Offset(5, 10),
    ),
    // 环境光 - 淡蓝色
    BoxShadow(
      color: const Color(0xFF6366F1).withOpacity(0.15),
      blurRadius: 40,
      spreadRadius: -8,
      offset: const Offset(-3, 8),
    ),
  ];

  /// Liquid 风格 FAB 渐变
  static LinearGradient get liquidFabGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7B6BFF), // 浅紫蓝
      Color(0xFF6B5CE7), // 主紫蓝
      Color(0xFF5B4CD7), // 深紫蓝
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Liquid 风格 FAB 装饰 - 参考玻璃拟态图标容器设计
  /// 径向渐变背景 + 柔和阴影 + 细腻边框
  static BoxDecoration liquidFabDecoration({Color? gradientColor}) =>
      BoxDecoration(
        // Liquid 风格径向渐变背景
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.3,
          colors: [
            const Color(0xFF8B7BFF).withOpacity(0.98), // 亮紫蓝高光
            (gradientColor ?? brandPrimary).withOpacity(0.95), // 主色
            const Color(0xFF5B4CD7).withOpacity(0.9), // 深紫蓝
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
        // 细腻的内发光边框
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        // Liquid 风格多层柔和阴影
        boxShadow: [
          // 主阴影 - 柔和扩散的紫蓝色
          BoxShadow(
            color: (gradientColor ?? brandPrimary).withOpacity(0.35),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 12),
          ),
          // 次级阴影 - 粉色光晕
          BoxShadow(
            color: const Color(0xFFFF6BBD).withOpacity(0.18),
            blurRadius: 20,
            spreadRadius: -3,
            offset: const Offset(4, 8),
          ),
          // 顶部高光效果
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 0,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      );

  /// 按钮阴影：shadow-[0_18px_45px_rgba(91,90,246,0.35)]
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: brandPrimary.withOpacity(0.35),
      blurRadius: 45,
      offset: const Offset(0, 18),
    ),
  ];

  /// 弱阴影
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: const Color(0xFF111827).withOpacity(0.06),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  // ==================== 渐变配置 ====================
  /// 主按钮渐变：from-brand-primary to-indigo-500
  static LinearGradient get primaryButtonGradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandPrimary, Color(0xFF6366F1)],
  );

  /// 全局背景渐变 - Liquid 风格流体渐变
  /// 柔和的紫蓝色流体效果
  static BoxDecoration get appBackgroundDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFE8F4FD), // 浅蓝白
        const Color(0xFFF0E6FF), // 淡紫
        const Color(0xFFFFE8F6), // 浅粉
        const Color(0xFFE6F0FF), // 淡蓝
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    ),
  );

  /// Liquid 风格卡片装饰
  static BoxDecoration liquidCardDecoration({
    Color? baseColor,
    double borderRadius = 24,
  }) => BoxDecoration(
    // 柔和的白色基底
    color: baseColor ?? Colors.white.withOpacity(0.75),
    borderRadius: BorderRadius.circular(borderRadius),
    // 细腻的内发光边框
    border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
    // 多层柔和阴影
    boxShadow: [
      // 主阴影 - 柔和扩散
      BoxShadow(
        color: const Color(0xFF6B5CE7).withOpacity(0.08),
        blurRadius: 40,
        spreadRadius: -5,
        offset: const Offset(0, 20),
      ),
      // 顶部高光效果
      BoxShadow(
        color: Colors.white.withOpacity(0.9),
        blurRadius: 0,
        spreadRadius: 1,
        offset: const Offset(0, -1),
      ),
    ],
  );

  /// Liquid 风格渐变卡片
  static BoxDecoration get liquidGradientCard => BoxDecoration(
    // 柔和的径向渐变背景
    gradient: RadialGradient(
      center: Alignment.topLeft,
      radius: 1.5,
      colors: [
        Colors.white.withOpacity(0.95),
        Colors.white.withOpacity(0.8),
        const Color(0xFFF8F5FF).withOpacity(0.7),
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF6B5CE7).withOpacity(0.06),
        blurRadius: 50,
        spreadRadius: -10,
        offset: const Offset(0, 25),
      ),
      BoxShadow(
        color: const Color(0xFFFF6BBD).withOpacity(0.04),
        blurRadius: 30,
        spreadRadius: -5,
        offset: const Offset(10, 10),
      ),
    ],
  );

  /// 玻璃拟态卡片渐变（Liquid 风格）
  static LinearGradient get glassCardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white.withOpacity(0.92), Colors.white.withOpacity(0.78)],
  );

  /// 玻璃拟态高亮卡片渐变
  static LinearGradient get glassCardGradientHigh => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white.withOpacity(0.98), Colors.white.withOpacity(0.88)],
  );

  /// 玻璃卡片阴影（Liquid 风格 - 柔和多层）
  static List<BoxShadow> get glassCardShadow => [
    // 主阴影
    BoxShadow(
      color: brandPrimary.withOpacity(0.06),
      blurRadius: 50,
      spreadRadius: -10,
      offset: const Offset(0, 25),
    ),
    // 环境光
    BoxShadow(
      color: const Color(0xFFFF6BBD).withOpacity(0.03),
      blurRadius: 30,
      offset: const Offset(10, 10),
    ),
  ];

  /// Liquid 风格底部导航栏装饰
  static BoxDecoration liquidNavDecoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.85),
        Colors.white.withOpacity(0.75),
        const Color(0xFFF8F5FF).withOpacity(0.7),
        const Color(0xFFFFF5FC).withOpacity(0.65),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    ),
    borderRadius: BorderRadius.circular(radiusNav),
    border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
    boxShadow: [
      // 主阴影
      BoxShadow(
        color: brandPrimary.withOpacity(0.08),
        blurRadius: 35,
        spreadRadius: -5,
        offset: const Offset(0, 12),
      ),
      // 顶部高光
      BoxShadow(
        color: Colors.white.withOpacity(0.9),
        blurRadius: 0,
        spreadRadius: 1,
        offset: const Offset(0, -1),
      ),
      // 粉色环境光
      BoxShadow(
        color: const Color(0xFFFF6BBD).withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: -3,
        offset: const Offset(8, 8),
      ),
    ],
  );

  /// Liquid 风格导航项选中状态装饰
  static BoxDecoration liquidNavItemActiveDecoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        brandPrimary.withOpacity(0.15),
        brandPrimary.withOpacity(0.1),
        const Color(0xFF6366F1).withOpacity(0.08),
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: brandPrimary.withOpacity(0.1), width: 1),
  );

  // ==================== 主题数据 ====================
  /// 浅色主题
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.light,
      primary: brandPrimary,
      surface: slate50,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: slate50,
    fontFamily: fontFamily,

    // AppBar 主题 - 半透明顶栏
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      titleTextStyle: TextStyle(
        fontSize: fontSizePageTitle,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
    ),

    // 卡片主题 - 玻璃拟态
    cardTheme: CardThemeData(
      elevation: 0,
      color: glassBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
        side: BorderSide(color: glassBorder, width: 1),
      ),
    ),

    // 按钮主题 - 渐变主按钮
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        textStyle: const TextStyle(
          fontSize: fontSizeBody,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    ),

    // 输入框主题 - rounded-2xl
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassInputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: glassBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: glassBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing4,
        vertical: spacing3 + 4,
      ),
      hintStyle: const TextStyle(
        fontSize: fontSizeBody,
        color: textTertiary,
        fontFamily: fontFamily,
      ),
    ),

    // 底部导航栏主题
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: glassBackground,
      selectedItemColor: brandPrimary,
      unselectedItemColor: textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontSize: fontSizeMicro,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: fontSizeMicro,
        fontWeight: FontWeight.w500,
        fontFamily: fontFamily,
      ),
    ),

    // SnackBar：floating + 略增底部 inset，深色条相对底栏再上移 2px，减轻叠边
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: EdgeInsets.fromLTRB(
        15,
        5,
        15,
        10 + snackBarExtraBottomInset,
      ),
    ),

    // 浮动按钮主题
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brandPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    // 对话框主题 - 玻璃拟态弹层
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
        side: BorderSide(color: glassBorder, width: 1),
      ),
      backgroundColor: glassBackgroundHigh,
      elevation: 0,
    ),

    // 分割线主题
    dividerTheme: DividerThemeData(
      color: slate200.withOpacity(0.5),
      thickness: 1,
    ),

    // 文本主题
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeCardTitle,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: fontSizeSectionTitle,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        fontFamily: fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: fontSizeMicro,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: fontSizeMicro,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        fontFamily: fontFamily,
      ),
    ),
  );
}
