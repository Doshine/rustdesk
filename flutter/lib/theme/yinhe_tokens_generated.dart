// GENERATED · 勿手改 · 由 yinhe/scripts/generate_tokens.py 生成
// Source : docs/design/tokens.json (version 2.1, updated 2026-07-21)
// Hash   : sha256:8241354af01a9d24c32be073f262c1432cc651dfc366deeffe3b64837fd8e4b3
// Check  : python3 yinhe/scripts/check_tokens_drift.py  （退出码非零即漂移）
// Usage : Flutter 主题常量（对应规范 §9.4 产物 flutter/lib/theme/yinhe_tokens.dart，由 WS1 接入）

//
// 设计基调：深空可信、通透连接、克制高效。Material 2（useMaterial3: false），
// 兼容 Flutter 3.24 现有 API：不使用 CardThemeData/DialogThemeData。
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// 色彩 token（规范 v2.1 §1.1 / §1.2 / §5）。
class YinheColors {
  YinheColors._();

  // ---- 品牌 ----
  static const Color brand = Color(0xFF2F80FF); // Blue 500 品牌基准色、浅色主交互色
  static const Color brandHover = Color(0xFF5A9EFF); // Blue 400 暗色主交互色
  static const Color brandActive = Color(0xFF1768E8); // Blue 600 浅色主按钮底 / hover / 文字态
  static const Color brandSubtle = Color(0x1F2F80FF);
  static const Color accent = Color(0xFF00C2FF); // Cyan 500 星河青，仅用于连接与品牌
  static const Color deepNavy = Color(0xFF0B1437);
  static const Color deepSpace = Color(0xFF0F1420); // 深空画布底，不使用纯黑
  static const Color brandHoverIconBg = Color(0x1F5A9EFF); // 深色图标按钮 hover 底

  // ---- 色阶见 YinheBlue / YinheCyan / YinheNeutral ----

  // ---- 语义色 · 浅色（v2.1 起废弃 v1 Tailwind 系 #22C55E/#F59E0B/#EF4444） ----
  static const Color success = Color(0xFF167C59);
  static const Color warning = Color(0xFFA86608);
  static const Color danger = Color(0xFFC53B4C);
  static const Color info = Color(0xFF1768E8);

  // ---- 语义色 · 深色 ----
  static const Color successDark = Color(0xFF39C894);
  static const Color warningDark = Color(0xFFF5B94C);
  static const Color dangerDark = Color(0xFFFF6B7C);
  static const Color infoDark = Color(0xFF5A9EFF);
  static const Color warningTextDark = Color(0xFFD9A441);
  static const Color dangerTextDark = Color(0xFFE56B78);

  // ---- 网络质量（真实语义色：优=成功、一般=警告、差=危险、断开=空心中性） ----
  static const Color qualityGood = Color(0xFF167C59);
  static const Color qualityFair = Color(0xFFA86608);
  static const Color qualityPoor = Color(0xFFC53B4C);
  static const Color qualityOffline = Color(0xFF94A3B8);
  static const Color qualityGoodDark = Color(0xFF39C894);
  static const Color qualityFairDark = Color(0xFFF5B94C);
  static const Color qualityPoorDark = Color(0xFFFF6B7C);
  static const Color qualityOfflineDark = Color(0xFF94A3B8);

  // ---- 表面（深色 Surface 统一 #141B2A，废弃 Flutter 旧值 #1A2130） ----
  static const Color canvas = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFCFDFE);
  static const Color raised = Color(0xFFF9FBFD);
  static const Color sunken = Color(0xFFEEF2F7);
  static const Color selected = Color(0xFFE8F2FF);
  static const Color canvasDark = Color(0xFF0F1420);
  static const Color surfaceDark = Color(0xFF141B2A);
  static const Color raisedDark = Color(0xFF192234);
  static const Color sunkenDark = Color(0xFF0B101A);
  static const Color selectedDark = Color(0xFF17335C);

  // ---- 文字 ----
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF4F5E73);
  static const Color textTertiary = Color(0xFF718096);
  static const Color textDisabled = Color(0xFFA7B0BE);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFF2F6FC);
  static const Color textSecondaryDark = Color(0xFFAAB7CA);
  static const Color textTertiaryDark = Color(0xFF7F8EA4);
  static const Color textDisabledDark = Color(0xFF526075);
  static const Color textInverseDark = Color(0xFF172033);

  // ---- 边界 ----
  static const Color border = Color(0xFFDDE3EC);
  static const Color borderStrong = Color(0xFFC6CFDB);
  static const Color borderDivider = Color(0xFFE8ECF2);
  static const Color borderDark = Color(0xFF273247);
  static const Color borderStrongDark = Color(0xFF37445C);
  static const Color borderDividerDark = Color(0xFF202B3D);

  // ---- 组件 ----
  static const Color sessionToolbarBg = Color(0xF0141B2A);
  static const Color sessionToolbarBorder = Color(0xFF37445C);

  // ---- 暗色数据可视化序列（规范 §5：蓝→青→琥珀→绿，色盲安全顺序） ----
  static const Color chartSeries1 = Color(0xFF5A9EFF);
  static const Color chartSeries2 = Color(0xFF25D1FF);
  static const Color chartSeries3 = Color(0xFFF5B94C);
  static const Color chartSeries4 = Color(0xFF39C894);
  static const Color chartGridline = Color(0xFF202B3D);
  static const Color chartSeries1Light = Color(0xFF2F80FF);
  static const Color chartSeries2Light = Color(0xFF009BD6);
  static const Color chartSeries3Light = Color(0xFFA86608);
  static const Color chartSeries4Light = Color(0xFF167C59);
  static const Color chartGridlineLight = Color(0xFFE8ECF2);
}

/// 品牌蓝色阶（规范 §1.1）。
class YinheBlue {
  YinheBlue._();
  static const Color s50 = Color(0xFFEEF6FF);
  static const Color s100 = Color(0xFFD9EAFF);
  static const Color s200 = Color(0xFFB9D7FF);
  static const Color s300 = Color(0xFF88BCFF);
  static const Color s400 = Color(0xFF5A9EFF);
  static const Color s500 = Color(0xFF2F80FF);
  static const Color s600 = Color(0xFF1768E8);
  static const Color s700 = Color(0xFF1554BB);
  static const Color s800 = Color(0xFF174894);
  static const Color s900 = Color(0xFF193E73);
  static const Color s950 = Color(0xFF102647);
}

/// 星河青色阶（规范 §1.1）。
class YinheCyan {
  YinheCyan._();
  static const Color s50 = Color(0xFFE9FCFF);
  static const Color s100 = Color(0xFFC9F7FF);
  static const Color s200 = Color(0xFF98EEFF);
  static const Color s300 = Color(0xFF5BE1FF);
  static const Color s400 = Color(0xFF25D1FF);
  static const Color s500 = Color(0xFF00C2FF);
  static const Color s600 = Color(0xFF009BD6);
  static const Color s700 = Color(0xFF087BAD);
  static const Color s800 = Color(0xFF0D638C);
  static const Color s900 = Color(0xFF125374);
  static const Color s950 = Color(0xFF07354F);
}

/// 中性灰阶：Slate 基础上向品牌蓝偏移 3–5% 的自有灰阶（规范 §1.1）。
class YinheNeutral {
  YinheNeutral._();
  static const Color s0 = Color(0xFFFCFDFE);
  static const Color s50 = Color(0xFFF7F9FC);
  static const Color s100 = Color(0xFFF1F4F8);
  static const Color s200 = Color(0xFFE2E8F0);
  static const Color s300 = Color(0xFFCBD5E1);
  static const Color s400 = Color(0xFF94A3B8);
  static const Color s500 = Color(0xFF64748B);
  static const Color s600 = Color(0xFF475569);
  static const Color s700 = Color(0xFF334155);
  static const Color s800 = Color(0xFF1E293B);
  static const Color s850 = Color(0xFF182131);
  static const Color s900 = Color(0xFF141B2A);
  static const Color s950 = Color(0xFF0F1420);
}

/// 品牌渐变（规范 §1.1：银河三段大面积、蓝青两段小面积；主按钮默认纯色不用渐变）。
class YinheGradients {
  YinheGradients._();

  /// 银河三段渐变：门户 Hero、登录品牌区、连接仪式、品牌推广卡等大面积品牌场景
  static const LinearGradient galaxy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight, // 135deg
    colors: [Color(0xFF102647), Color(0xFF2F80FF), Color(0xFF00C2FF)],
    stops: [0, 0.45, 1],
  );

  /// 蓝青两段渐变：加载轨迹、进度描边、主视觉文字、图标高光等小面积
  static const LinearGradient blueCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight, // 135deg
    colors: [Color(0xFF2F80FF), Color(0xFF00C2FF)],
    stops: [0, 1],
  );
}

/// 字体栈（规范 §1.3 / §6.3：JetBrains Mono 本地托管 woff2 置顶，禁外链 CDN；
/// fontFamily 与 fontFamilyFallback 统一由本文件提供，业务代码不得散落声明）。
class YinheTypography {
  YinheTypography._();

  static const String fontFamilyInterface = 'PingFang SC';
  static const List<String> fontFamilyInterfaceFallback = ['Noto Sans CJK SC', 'Microsoft YaHei UI', 'system-ui', 'sans-serif'];

  static const String fontFamilyMono = 'JetBrains Mono';
  static const List<String> fontFamilyMonoFallback = ['SFMono-Regular', 'Roboto Mono', 'ui-monospace', 'monospace'];

  static const String fontFamilyIdDisplay = 'JetBrains Mono';
  static const List<String> fontFamilyIdDisplayFallback = ['PingFang SC', 'Microsoft YaHei UI', 'system-ui', 'sans-serif'];

  // ---- 字号（规范 §1.3） ----
  static const double fontSizeCaption = 11;
  static const double fontSizeLabel = 12;
  static const double fontSizeBodyS = 13;
  static const double fontSizeBodyM = 14;
  static const double fontSizeBodyL = 16;
  static const double fontSizeTitleM = 18;
  static const double fontSizeTitleL = 20;
  static const double fontSizeH3 = 24;
  static const double fontSizeH2 = 28;
  static const double fontSizeH1 = 34;
  static const double fontSizeDisplay = 44;

  // ---- 字重 ----
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // ---- 字距（em；数字脸 -0.02em、分区标签英文大写 +0.12em） ----
  static const double letterSpacingNumericFace = -0.02;
  static const double letterSpacingSectionLabel = 0.12;
}

/// 文字样式（规范 §1.3 字号/行高/字重表；Dart height = 行高 ÷ 字号）。
class YinheTextStyles {
  YinheTextStyles._();

  /// display 44/52 字重 600
  static const TextStyle display = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w600,
    height: 1.1818, // 52/44
  );

  /// h1 34/42 字重 600
  static const TextStyle h1 = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.2353, // 42/34
  );

  /// h2 28/36 字重 600
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2857, // 36/28
  );

  /// h3 24/32 字重 600
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3333, // 32/24
  );

  /// titleL 20/28 字重 600
  static const TextStyle titleL = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4000, // 28/20
  );

  /// titleM 18/26 字重 600
  static const TextStyle titleM = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4444, // 26/18
  );

  /// bodyL 16/24 字重 400/500
  static const TextStyle bodyL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5000, // 24/16
  );

  /// bodyM 14/22 字重 400/500
  static const TextStyle bodyM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5714, // 22/14
  );

  /// bodyS 13/20 字重 400/500
  static const TextStyle bodyS = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5385, // 20/13
  );

  /// label 12/18 字重 500/600
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5000, // 18/12
  );

  /// caption 11/16 字重 500
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4545, // 16/11
  );
}

/// 蓝鲸数字脸（排印记忆点，规范 §1.3 / §6.3）：本机 ID、门户 Hero 数字、延迟/FPS 等
/// 关键数字使用 700 字重 + -0.02em 紧字距 + JetBrains Mono + tabular-nums。
class YinheNumericFace {
  YinheNumericFace._();

  /// 关键数字样式生成：letterSpacing 以逻辑像素计（-0.02em × fontSize）。
  static TextStyle style({double fontSize = 28, double? height}) => TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: height,
        letterSpacing: -0.02 * fontSize,
        fontFamily: YinheTypography.fontFamilyMono,
        fontFamilyFallback: YinheTypography.fontFamilyMonoFallback,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 主窗口本机 ID：28/36（格式如 842 193 607）。
  static TextStyle idCard() =>
      style(fontSize: 28, height: 1.2857);

  /// 分区标签：英文大写 + 0.12em 字距。
  static TextStyle sectionLabel({double fontSize = 12}) => TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.12 * fontSize,
      );
}

/// 间距 token（4pt 栅格，规范 §1.4）。
class YinheSpacing {
  YinheSpacing._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double page = 40;
  static const double section = 48;
  static const double portal = 64;
  static const double portalLg = 80;
}

/// 圆角 token（规范 §1.4：紧凑 6 / 默认 8 / 卡片 12 / 弹窗 16；胶囊仅用于标签与状态）。
class YinheRadius {
  YinheRadius._();
  static const double compact = 6;
  static const double base = 8;
  static const double card = 12;
  static const double dialog = 16;
  static const double full = 9999;
}

/// 动效 token（规范 §1.5；全端统一引用，禁止散落魔法数字；
/// prefers-reduced-motion 降级见 tokens.json motion.reduced 与 theme.css 降级段）。
class YinheMotion {
  YinheMotion._();
  static const Duration hover = Duration(milliseconds: 150); // hover、图标反馈（降级：无过渡直接切换）
  static const Duration press = Duration(milliseconds: 120); // 按压位移/缩放（降级：无过渡直接切换）
  static const Duration normal = Duration(milliseconds: 200); // tab、菜单、toast（降级：时长压至 0.01s）
  static const Duration dialogIn = Duration(milliseconds: 200); // 对话框、弹层打开（降级：仅透明度突变）
  static const Duration dialogOut = Duration(milliseconds: 160); // 对话框、弹层关闭（降级：仅透明度突变）
  static const Duration collapse = Duration(milliseconds: 420); // 折叠展开、连接段间过渡（降级：直接展开/收起）
  static const Duration successPulse = Duration(milliseconds: 400); // 连接成功确认脉冲（单次播放，降级：静止态）
  static const Duration ambient = Duration(milliseconds: 1500); // 雷达呼吸、环境脉冲（降级：静止态）

  // ---- 曲线（与 CSS cubic-bezier 对齐） ----
  static const Cubic standard = Cubic(0.2, 0, 0, 1);
  static const Cubic enter = Cubic(0, 0, 0.2, 1);
  static const Cubic exit = Cubic(0.4, 0, 1, 1);
  static const Curve ease = Curves.ease;
  static const Curve easeInOut = Curves.easeInOut;
}

/// 阴影 token（规范 §1.4：Elevation 1 卡片 hover / 2 工具栏菜单 / 3 对话框；
/// 深色 Raised 顶部叠加 1px 内高光 insetHighlight）。
class YinheElevation {
  YinheElevation._();

  static const List<BoxShadow> elev1 = [
    BoxShadow(color: Color(0x0F12253F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0A12253F), offset: Offset(0, 4), blurRadius: 12),
  ];

  static const List<BoxShadow> elev2 = [
    BoxShadow(color: Color(0x1A12253F), offset: Offset(0, 8), blurRadius: 24),
    BoxShadow(color: Color(0x0F12253F), offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> elev3 = [
    BoxShadow(color: Color(0x2912253F), offset: Offset(0, 20), blurRadius: 56),
    BoxShadow(color: Color(0x1412253F), offset: Offset(0, 4), blurRadius: 12),
  ];

  static const List<BoxShadow> elev1Dark = [
    BoxShadow(color: Color(0x4702060E), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x2E02060E), offset: Offset(0, 4), blurRadius: 14),
  ];

  static const List<BoxShadow> elev2Dark = [
    BoxShadow(color: Color(0x6102060E), offset: Offset(0, 10), blurRadius: 28),
    BoxShadow(color: Color(0x4702060E), offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> elev3Dark = [
    BoxShadow(color: Color(0x8A02060E), offset: Offset(0, 24), blurRadius: 64),
    BoxShadow(color: Color(0x5702060E), offset: Offset(0, 4), blurRadius: 14),
  ];

  /// 深色 Raised 顶部 1px 内高光（规范 §1.2 受光三要素之二，透明度 .04~.06）。
  static const List<BoxShadow> raisedInsetDark = [
    BoxShadow(color: Color(0x0DFFFFFF), offset: Offset(0, 1), blurRadius: 0),
  ];
}

/// 层级 token（规范 §9.2）。
class YinheZIndex {
  YinheZIndex._();
  static const int base = 0;
  static const int sticky = 100;
  static const int dropdown = 300;
  static const int sessionToolbar = 400;
  static const int scrim = 600;
  static const int dialog = 700;
  static const int toast = 800;
}

/// 核心尺寸 token（规范 §9.1）。
class YinheSize {
  YinheSize._();
  static const double sidebarDesktop = 220;
  static const double sidebarAdmin = 232;
  static const double topbar = 56;
  static const double inputDefault = 40;
  static const double buttonDefault = 40;
  static const double touchTarget = 44;
  static const double tableRowCompact = 44;
  static const double tableRowDefault = 48;
  static const double mobileRemoteToolbar = 64;
  static const double contentMax = 1440;
}
