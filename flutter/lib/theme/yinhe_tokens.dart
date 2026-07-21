/// 蓝鲸银河 design tokens · Flutter 产物（WS1 手写接入版 · v2.1 最终同步）
///
/// 单一事实源：`yinhe/docs/design/tokens.json`（v2.1），生成管线
/// `yinhe/scripts/generate_tokens.py`，对应产物 `yinhe/docs/design/dist/yinhe_tokens.dart`。
/// 本文件 API 面手写维护（现有代码引用 YinheColors.blue500、YinheFonts.numeric()、
/// galaxyGradient/brandGradient、YinheMotion 的 Cubic 曲线等），所有值与 tokens.json 一致：
/// - 品牌蓝 #2F80FF 全梯度、星河青 #00C2FF 全梯度
/// - 语义色 #167C59 / #A86608 / #C53B4C（深色 #39C894 / #F5B94C / #FF6B7C；
///   深底文字提亮变体 warningTextDark #D9A441 / dangerTextDark #E56B78）
/// - 深色 Canvas #0F1420 / Surface #141B2A / Raised #192234 / Border #273247
/// - 银河三段渐变 135deg #102647 0% → #2F80FF 45% → #00C2FF 100%
/// - 间距 / 圆角 / 动效时长与 Cubic 曲线
library yinhe_tokens;

import 'package:flutter/material.dart';

/// 色板（规范 §1.1 / §1.2 / §5）
class YinheColors {
  YinheColors._();

  // ---- 品牌蓝 ----
  static const Color blue50 = Color(0xFFEEF6FF);
  static const Color blue100 = Color(0xFFD9EAFF);
  static const Color blue200 = Color(0xFFB9D7FF);
  static const Color blue300 = Color(0xFF88BCFF);
  static const Color blue400 = Color(0xFF5A9EFF);
  static const Color blue500 = Color(0xFF2F80FF); // 品牌基准色
  static const Color blue600 = Color(0xFF1768E8);
  static const Color blue700 = Color(0xFF1554BB);
  static const Color blue800 = Color(0xFF174894);
  static const Color blue900 = Color(0xFF193E73);
  static const Color blue950 = Color(0xFF102647);

  // ---- 星河青 ----
  static const Color cyan50 = Color(0xFFE9FCFF);
  static const Color cyan100 = Color(0xFFC9F7FF);
  static const Color cyan200 = Color(0xFF98EEFF);
  static const Color cyan300 = Color(0xFF5BE1FF);
  static const Color cyan400 = Color(0xFF25D1FF);
  static const Color cyan500 = Color(0xFF00C2FF); // 品牌基准青
  static const Color cyan600 = Color(0xFF009BD6);
  static const Color cyan700 = Color(0xFF087BAD);
  static const Color cyan800 = Color(0xFF0D638C);
  static const Color cyan900 = Color(0xFF125374);
  static const Color cyan950 = Color(0xFF07354F);

  // ---- 中性色（向品牌蓝偏移 3–5% 的自有灰阶）----
  static const Color neutral0 = Color(0xFFFCFDFE);
  static const Color neutral50 = Color(0xFFF7F9FC);
  static const Color neutral100 = Color(0xFFF1F4F8);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral850 = Color(0xFF182131);
  static const Color neutral900 = Color(0xFF141B2A);
  static const Color neutral950 = Color(0xFF0F1420);

  // ---- 品牌补充（tokens.json color.brand）----
  /// 品牌浅底 rgba(47,128,255,.12)：浅色选中底、当前行底
  static const Color brandSubtle = Color(0x1F2F80FF);

  /// 深海军蓝 #0B1437：侧边栏 / 品牌深底（独立于 Blue 950 与 Neutral 950）
  static const Color deepNavy = Color(0xFF0B1437);

  // ---- 语义色 ----
  static const Color successLight = Color(0xFF167C59);
  static const Color successDark = Color(0xFF39C894);
  static const Color warningLight = Color(0xFFA86608);
  static const Color warningDark = Color(0xFFF5B94C);
  static const Color dangerLight = Color(0xFFC53B4C);
  static const Color dangerDark = Color(0xFFFF6B7C);
  static const Color infoLight = Color(0xFF1768E8);
  static const Color infoDark = Color(0xFF5A9EFF);

  // ---- 深底语义文字提亮变体（tokens.json semantic.dark，WS5 rdgen 登记，仅深色）----
  /// 深色底上的警告文本提亮态
  static const Color warningTextDark = Color(0xFFD9A441);

  /// 深色底上的危险文本提亮态
  static const Color dangerTextDark = Color(0xFFE56B78);

  // ---- 网络质量（真实语义色：优=成功、一般=警告、差=危险、断开=空心中性）----
  static const Color qualityGoodLight = Color(0xFF167C59);
  static const Color qualityFairLight = Color(0xFFA86608);
  static const Color qualityPoorLight = Color(0xFFC53B4C);
  static const Color qualityOfflineLight = Color(0xFF94A3B8);
  static const Color qualityGoodDark = Color(0xFF39C894);
  static const Color qualityFairDark = Color(0xFFF5B94C);
  static const Color qualityPoorDark = Color(0xFFFF6B7C);
  static const Color qualityOfflineDark = Color(0xFF94A3B8);

  // ---- 明暗双主题表面（规范 §1.2）----
  static const Color canvasLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFCFDFE);
  static const Color surfaceRaisedLight = Color(0xFFF9FBFD);
  static const Color surfaceSunkenLight = Color(0xFFEEF2F7);
  static const Color surfaceSelectedLight = Color(0xFFE8F2FF);

  static const Color canvasDark = Color(0xFF0F1420);
  static const Color surfaceDark = Color(0xFF141B2A);
  static const Color surfaceRaisedDark = Color(0xFF192234);
  static const Color surfaceSunkenDark = Color(0xFF0B101A);
  static const Color surfaceSelectedDark = Color(0xFF17335C);

  // ---- 文本 ----
  static const Color textPrimaryLight = Color(0xFF172033);
  static const Color textSecondaryLight = Color(0xFF4F5E73);
  static const Color textTertiaryLight = Color(0xFF718096);
  static const Color textDisabledLight = Color(0xFFA7B0BE);
  static const Color textInverseLight = Color(0xFFFFFFFF);

  static const Color textPrimaryDark = Color(0xFFF2F6FC);
  static const Color textSecondaryDark = Color(0xFFAAB7CA);
  static const Color textTertiaryDark = Color(0xFF7F8EA4);
  static const Color textDisabledDark = Color(0xFF526075);
  static const Color textInverseDark = Color(0xFF172033);

  // ---- 描边与分隔 ----
  static const Color borderLight = Color(0xFFDDE3EC);
  static const Color borderStrongLight = Color(0xFFC6CFDB);
  static const Color dividerLight = Color(0xFFE8ECF2);

  static const Color borderDark = Color(0xFF273247);
  static const Color borderStrongDark = Color(0xFF37445C);
  static const Color dividerDark = Color(0xFF202B3D);

  // ---- 数据可视化序列（规范 §5：蓝→青→琥珀→绿，色盲安全顺序；语义色不占序列号）----
  static const Color chartSeries1Light = Color(0xFF2F80FF);
  static const Color chartSeries2Light = Color(0xFF009BD6);
  static const Color chartSeries3Light = Color(0xFFA86608);
  static const Color chartSeries4Light = Color(0xFF167C59);
  static const Color chartGridlineLight = Color(0xFFE8ECF2);
  static const Color chartSeries1Dark = Color(0xFF5A9EFF);
  static const Color chartSeries2Dark = Color(0xFF25D1FF);
  static const Color chartSeries3Dark = Color(0xFFF5B94C);
  static const Color chartSeries4Dark = Color(0xFF39C894);
  static const Color chartGridlineDark = Color(0xFF202B3D);

  // ---- 组件（tokens.json component.sessionToolbar）----
  /// 会话悬浮工具栏底：rgba(20,27,42,.94)
  static const Color sessionToolbarBg = Color(0xF0141B2A);

  /// 会话悬浮工具栏描边
  static const Color sessionToolbarBorder = Color(0xFF37445C);

  // ---- 态色 ----
  /// 复制/图标钮 hover 底：rgba(90,158,255,.12)（规范 §2.1.A）
  static const Color blue400A12 = Color(0x1F5A9EFF);

  /// Raised 顶部 1px 内高光（规范 §1.2，Flutter 以顶部渐变近似 inset 高光）
  static const Color raisedTopHighlight = Color(0x0DFFFFFF);

  // ---- 品牌渐变（规范 §1.1）----
  /// 银河三段渐变：135deg, #102647 0% → #2F80FF 45% → #00C2FF 100%
  /// 大面积品牌场景：门户 Hero、登录品牌区、连接仪式、品牌推广卡
  static const LinearGradient galaxyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue950, blue500, cyan500],
    stops: [0.0, 0.45, 1.0],
  );

  /// 蓝青两段渐变：135deg, #2F80FF 0% → #00C2FF 100%
  /// 小面积：加载轨迹、进度描边、主视觉文字、图标高光
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue500, cyan500],
  );
}

/// 间距（规范 §1.4，4pt 栅格）
class YinheSpacing {
  YinheSpacing._();

  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;
  static const double s80 = 80;
}

/// 圆角（规范 §1.4：紧凑 6 / 默认 8 / 卡片 12 / 弹窗 16；胶囊仅用于标签与状态）
class YinheRadius {
  YinheRadius._();

  static const double controlCompact = 6; // 紧凑控件
  static const double control = 8; // 默认控件
  static const double card = 12; // 卡片
  static const double promo = 16; // 推广卡 / 弹窗
  static const double full = 9999; // 胶囊（仅标签与状态）
}

/// 动效（规范 §1.5；曲线以 Cubic 对齐 CSS cubic-bezier）
class YinheMotion {
  YinheMotion._();

  static const Duration hover = Duration(milliseconds: 150); // ease
  static const Duration press = Duration(milliseconds: 120); // ease
  static const Duration normal = Duration(milliseconds: 200); // standard
  static const Duration dialogIn = Duration(milliseconds: 200);
  static const Duration dialogOut = Duration(milliseconds: 160);
  static const Duration collapse = Duration(milliseconds: 420); // standard
  static const Duration ambient = Duration(milliseconds: 1500); // ease-in-out

  /// 复制成功反馈过渡（规范 WS1-4，120ms）
  static const Duration copyFeedback = Duration(milliseconds: 120);

  /// 标准曲线 cubic-bezier(.2, 0, 0, 1)
  static const Cubic standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 进入 cubic-bezier(0, 0, .2, 1)
  static const Cubic enter = Cubic(0.0, 0.0, 0.2, 1.0);

  /// 退出 cubic-bezier(.4, 0, 1, 1)
  static const Cubic exit = Cubic(0.4, 0.0, 1.0, 1.0);

  /// 与 CSS ease 对齐（hover、图标反馈）
  static const Curve ease = Curves.ease;

  /// 与 CSS ease-in-out 对齐（雷达呼吸、环境脉冲）
  static const Curve easeInOut = Curves.easeInOut;
}

/// 字体栈（规范 §1.3 / §6.2 / §6.3）
/// fontFamily 与 fontFamilyFallback 统一由此提供，业务代码不得散落声明。
class YinheFonts {
  YinheFonts._();

  /// 界面字体链
  static const String interface = 'PingFang SC';
  static const List<String> interfaceFallback = <String>[
    'Noto Sans CJK SC',
    'Microsoft YaHei UI',
    'system-ui',
    'sans-serif',
  ];

  /// 数字字体链（font-mono）：JetBrains Mono 置顶（资产声明后生效），
  /// 未打包时按链回退。
  static const String mono = 'JetBrains Mono';
  static const List<String> monoFallback = <String>[
    'SFMono-Regular',
    'Roboto Mono',
    'ui-monospace',
    'monospace',
  ];

  /// ID 展示字体链（数字脸：JetBrains Mono 置顶，中文回退界面链）
  static const String idDisplay = 'JetBrains Mono';
  static const List<String> idDisplayFallback = <String>[
    'PingFang SC',
    'Microsoft YaHei UI',
    'system-ui',
    'sans-serif',
  ];

  // ---- 字号（规范 §1.3） ----
  static const double sizeCaption = 11;
  static const double sizeLabel = 12;
  static const double sizeBodyS = 13;
  static const double sizeBodyM = 14;
  static const double sizeBodyL = 16;
  static const double sizeTitleM = 18;
  static const double sizeTitleL = 20;
  static const double sizeH3 = 24;
  static const double sizeH2 = 28;
  static const double sizeH1 = 34;
  static const double sizeDisplay = 44;

  // ---- 字重 ----
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // ---- 字距（em；数字脸 -0.02em、分区标签英文大写 +0.12em） ----
  static const double letterSpacingNumericFace = -0.02;
  static const double letterSpacingSectionLabel = 0.12;

  /// 关键数字（数字脸）：700 字重 + -0.02em 紧字距 + tabular-nums + mono 链
  /// （规范 §1.3 蓝鲸数字脸）。字号/行高按场景覆盖。
  static TextStyle numeric({
    required double fontSize,
    required double height,
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontFamilyFallback: monoFallback,
      fontSize: fontSize,
      height: height / fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.02 * fontSize,
      color: color,
      fontFeatures: const [FontFeature('tnum')],
    );
  }
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

/// 阴影 token（规范 §1.4：Elevation 1 卡片 hover / 2 工具栏菜单 / 3 对话框；
/// 深色 Raised 顶部叠加 1px 内高光，另见 YinheColors.raisedTopHighlight）。
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
