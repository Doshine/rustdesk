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
import 'yinhe_tokens_generated.dart' as generated_tokens;

/// 色板（规范 §1.1 / §1.2 / §5）
class YinheColors {
  YinheColors._();

  // ---- 品牌蓝 ----
  static const Color blue50 = generated_tokens.YinheBlue.s50;
  static const Color blue100 = generated_tokens.YinheBlue.s100;
  static const Color blue200 = generated_tokens.YinheBlue.s200;
  static const Color blue300 = generated_tokens.YinheBlue.s300;
  static const Color blue400 = generated_tokens.YinheBlue.s400;
  static const Color blue500 = generated_tokens.YinheBlue.s500; // 品牌基准色
  static const Color blue600 = generated_tokens.YinheBlue.s600;
  static const Color blue700 = generated_tokens.YinheBlue.s700;
  static const Color blue800 = generated_tokens.YinheBlue.s800;
  static const Color blue900 = generated_tokens.YinheBlue.s900;
  static const Color blue950 = generated_tokens.YinheBlue.s950;

  // ---- 星河青 ----
  static const Color cyan50 = generated_tokens.YinheCyan.s50;
  static const Color cyan100 = generated_tokens.YinheCyan.s100;
  static const Color cyan200 = generated_tokens.YinheCyan.s200;
  static const Color cyan300 = generated_tokens.YinheCyan.s300;
  static const Color cyan400 = generated_tokens.YinheCyan.s400;
  static const Color cyan500 = generated_tokens.YinheCyan.s500; // 品牌基准青
  static const Color cyan600 = generated_tokens.YinheCyan.s600;
  static const Color cyan700 = generated_tokens.YinheCyan.s700;
  static const Color cyan800 = generated_tokens.YinheCyan.s800;
  static const Color cyan900 = generated_tokens.YinheCyan.s900;
  static const Color cyan950 = generated_tokens.YinheCyan.s950;

  // ---- 中性色（向品牌蓝偏移 3–5% 的自有灰阶）----
  static const Color neutral0 = generated_tokens.YinheNeutral.s0;
  static const Color neutral50 = generated_tokens.YinheNeutral.s50;
  static const Color neutral100 = generated_tokens.YinheNeutral.s100;
  static const Color neutral200 = generated_tokens.YinheNeutral.s200;
  static const Color neutral300 = generated_tokens.YinheNeutral.s300;
  static const Color neutral400 = generated_tokens.YinheNeutral.s400;
  static const Color neutral500 = generated_tokens.YinheNeutral.s500;
  static const Color neutral600 = generated_tokens.YinheNeutral.s600;
  static const Color neutral700 = generated_tokens.YinheNeutral.s700;
  static const Color neutral800 = generated_tokens.YinheNeutral.s800;
  static const Color neutral850 = generated_tokens.YinheNeutral.s850;
  static const Color neutral900 = generated_tokens.YinheNeutral.s900;
  static const Color neutral950 = generated_tokens.YinheNeutral.s950;

  // ---- 品牌补充（tokens.json color.brand）----
  /// 品牌浅底 rgba(47,128,255,.12)：浅色选中底、当前行底
  static const Color brandSubtle = generated_tokens.YinheColors.brandSubtle;

  /// 深海军蓝 #0B1437：侧边栏 / 品牌深底（独立于 Blue 950 与 Neutral 950）
  static const Color deepNavy = generated_tokens.YinheColors.deepNavy;

  // ---- 语义色 ----
  static const Color successLight = generated_tokens.YinheColors.success;
  static const Color successDark = generated_tokens.YinheColors.successDark;
  static const Color warningLight = generated_tokens.YinheColors.warning;
  static const Color warningDark = generated_tokens.YinheColors.warningDark;
  static const Color dangerLight = generated_tokens.YinheColors.danger;
  static const Color dangerDark = generated_tokens.YinheColors.dangerDark;
  static const Color infoLight = generated_tokens.YinheColors.info;
  static const Color infoDark = generated_tokens.YinheColors.infoDark;

  // ---- 深底语义文字提亮变体（tokens.json semantic.dark，WS5 rdgen 登记，仅深色）----
  /// 深色底上的警告文本提亮态
  static const Color warningTextDark = generated_tokens.YinheColors.warningTextDark;

  /// 深色底上的危险文本提亮态
  static const Color dangerTextDark = generated_tokens.YinheColors.dangerTextDark;

  // ---- 网络质量（真实语义色：优=成功、一般=警告、差=危险、断开=空心中性）----
  static const Color qualityGoodLight = generated_tokens.YinheColors.qualityGood;
  static const Color qualityFairLight = generated_tokens.YinheColors.qualityFair;
  static const Color qualityPoorLight = generated_tokens.YinheColors.qualityPoor;
  static const Color qualityOfflineLight = generated_tokens.YinheColors.qualityOffline;
  static const Color qualityGoodDark = generated_tokens.YinheColors.qualityGoodDark;
  static const Color qualityFairDark = generated_tokens.YinheColors.qualityFairDark;
  static const Color qualityPoorDark = generated_tokens.YinheColors.qualityPoorDark;
  static const Color qualityOfflineDark = generated_tokens.YinheColors.qualityOfflineDark;

  // ---- 明暗双主题表面（规范 §1.2）----
  static const Color canvasLight = generated_tokens.YinheColors.canvas;
  static const Color surfaceLight = generated_tokens.YinheColors.surface;
  static const Color surfaceRaisedLight = generated_tokens.YinheColors.raised;
  static const Color surfaceSunkenLight = generated_tokens.YinheColors.sunken;
  static const Color surfaceSelectedLight = generated_tokens.YinheColors.selected;

  static const Color canvasDark = generated_tokens.YinheColors.canvasDark;
  static const Color surfaceDark = generated_tokens.YinheColors.surfaceDark;
  static const Color surfaceRaisedDark = generated_tokens.YinheColors.raisedDark;
  static const Color surfaceSunkenDark = generated_tokens.YinheColors.sunkenDark;
  static const Color surfaceSelectedDark = generated_tokens.YinheColors.selectedDark;

  // ---- 文本 ----
  static const Color textPrimaryLight = generated_tokens.YinheColors.textPrimary;
  static const Color textSecondaryLight = generated_tokens.YinheColors.textSecondary;
  static const Color textTertiaryLight = generated_tokens.YinheColors.textTertiary;
  static const Color textDisabledLight = generated_tokens.YinheColors.textDisabled;
  static const Color textInverseLight = generated_tokens.YinheColors.textInverse;

  static const Color textPrimaryDark = generated_tokens.YinheColors.textPrimaryDark;
  static const Color textSecondaryDark = generated_tokens.YinheColors.textSecondaryDark;
  static const Color textTertiaryDark = generated_tokens.YinheColors.textTertiaryDark;
  static const Color textDisabledDark = generated_tokens.YinheColors.textDisabledDark;
  static const Color textInverseDark = generated_tokens.YinheColors.textInverseDark;

  // ---- 描边与分隔 ----
  static const Color borderLight = generated_tokens.YinheColors.border;
  static const Color borderStrongLight = generated_tokens.YinheColors.borderStrong;
  static const Color dividerLight = generated_tokens.YinheColors.borderDivider;

  static const Color borderDark = generated_tokens.YinheColors.borderDark;
  static const Color borderStrongDark = generated_tokens.YinheColors.borderStrongDark;
  static const Color dividerDark = generated_tokens.YinheColors.borderDividerDark;

  // ---- 数据可视化序列（规范 §5：蓝→青→琥珀→绿，色盲安全顺序；语义色不占序列号）----
  static const Color chartSeries1Light = generated_tokens.YinheColors.chartSeries1Light;
  static const Color chartSeries2Light = generated_tokens.YinheColors.chartSeries2Light;
  static const Color chartSeries3Light = generated_tokens.YinheColors.chartSeries3Light;
  static const Color chartSeries4Light = generated_tokens.YinheColors.chartSeries4Light;
  static const Color chartGridlineLight = generated_tokens.YinheColors.chartGridlineLight;
  static const Color chartSeries1Dark = generated_tokens.YinheColors.chartSeries1;
  static const Color chartSeries2Dark = generated_tokens.YinheColors.chartSeries2;
  static const Color chartSeries3Dark = generated_tokens.YinheColors.chartSeries3;
  static const Color chartSeries4Dark = generated_tokens.YinheColors.chartSeries4;
  static const Color chartGridlineDark = generated_tokens.YinheColors.chartGridline;

  // ---- 组件（tokens.json component.sessionToolbar）----
  /// 会话悬浮工具栏底：rgba(20,27,42,.94)
  static const Color sessionToolbarBg = generated_tokens.YinheColors.sessionToolbarBg;

  /// 会话悬浮工具栏描边
  static const Color sessionToolbarBorder = generated_tokens.YinheColors.sessionToolbarBorder;

  // ---- 态色 ----
  /// 复制/图标钮 hover 底：rgba(90,158,255,.12)（规范 §2.1.A）
  static const Color blue400A12 = generated_tokens.YinheColors.brandHoverIconBg;

  /// Raised 顶部 1px 内高光（规范 §1.2，Flutter 以顶部渐变近似 inset 高光）
  static const Color raisedTopHighlight = Color(0x0DFFFFFF);

  // ---- 品牌渐变（规范 §1.1）----
  /// 银河三段渐变：135deg, #102647 0% → #2F80FF 45% → #00C2FF 100%
  /// 大面积品牌场景：门户 Hero、登录品牌区、连接仪式、品牌推广卡
  static const LinearGradient galaxyGradient = generated_tokens.YinheGradients.galaxy;

  /// 蓝青两段渐变：135deg, #2F80FF 0% → #00C2FF 100%
  /// 小面积：加载轨迹、进度描边、主视觉文字、图标高光
  static const LinearGradient brandGradient = generated_tokens.YinheGradients.blueCyan;
}

/// 间距（规范 §1.4，4pt 栅格）
class YinheSpacing {
  YinheSpacing._();

  static const double s2 = generated_tokens.YinheSpacing.xxs;
  static const double s4 = generated_tokens.YinheSpacing.xs;
  static const double s8 = generated_tokens.YinheSpacing.sm;
  static const double s12 = generated_tokens.YinheSpacing.md;
  static const double s16 = generated_tokens.YinheSpacing.lg;
  static const double s20 = generated_tokens.YinheSpacing.xl;
  static const double s24 = generated_tokens.YinheSpacing.xxl;
  static const double s32 = generated_tokens.YinheSpacing.xxxl;
  static const double s40 = generated_tokens.YinheSpacing.page;
  static const double s48 = generated_tokens.YinheSpacing.section;
  static const double s64 = generated_tokens.YinheSpacing.portal;
  static const double s80 = generated_tokens.YinheSpacing.portalLg;
}

/// 圆角（规范 §1.4：紧凑 6 / 默认 8 / 卡片 12 / 弹窗 16；胶囊仅用于标签与状态）
class YinheRadius {
  YinheRadius._();

  static const double controlCompact = generated_tokens.YinheRadius.compact; // 紧凑控件
  static const double control = generated_tokens.YinheRadius.base; // 默认控件
  static const double card = generated_tokens.YinheRadius.card; // 卡片
  static const double promo = generated_tokens.YinheRadius.dialog; // 推广卡 / 弹窗
  static const double full = generated_tokens.YinheRadius.full; // 胶囊（仅标签与状态）
}

/// 动效（规范 §1.5；曲线以 Cubic 对齐 CSS cubic-bezier）
class YinheMotion {
  YinheMotion._();

  static const Duration hover = generated_tokens.YinheMotion.hover; // ease
  static const Duration press = generated_tokens.YinheMotion.press; // ease
  static const Duration normal = generated_tokens.YinheMotion.normal; // standard
  static const Duration dialogIn = generated_tokens.YinheMotion.dialogIn;
  static const Duration dialogOut = generated_tokens.YinheMotion.dialogOut;
  static const Duration collapse = generated_tokens.YinheMotion.collapse; // standard
  static const Duration successPulse = generated_tokens.YinheMotion.successPulse;
  static const Duration ambient = generated_tokens.YinheMotion.ambient; // ease-in-out

  /// 复制成功反馈过渡（规范 WS1-4，120ms）
  static const Duration copyFeedback = generated_tokens.YinheMotion.press;

  /// 标准曲线 cubic-bezier(.2, 0, 0, 1)
  static const Cubic standard = generated_tokens.YinheMotion.standard;

  /// 进入 cubic-bezier(0, 0, .2, 1)
  static const Cubic enter = generated_tokens.YinheMotion.enter;

  /// 退出 cubic-bezier(.4, 0, 1, 1)
  static const Cubic exit = generated_tokens.YinheMotion.exit;

  /// 与 CSS ease 对齐（hover、图标反馈）
  static const Curve ease = generated_tokens.YinheMotion.ease;

  /// 与 CSS ease-in-out 对齐（雷达呼吸、环境脉冲）
  static const Curve easeInOut = generated_tokens.YinheMotion.easeInOut;
}

/// 字体栈（规范 §1.3 / §6.2 / §6.3）
/// fontFamily 与 fontFamilyFallback 统一由此提供，业务代码不得散落声明。
class YinheFonts {
  YinheFonts._();

  /// 界面字体链
  static const String interface = generated_tokens.YinheTypography.fontFamilyInterface;
  static const List<String> interfaceFallback = generated_tokens.YinheTypography.fontFamilyInterfaceFallback;

  /// 数字字体链（font-mono）：JetBrains Mono 置顶（资产声明后生效），
  /// 未打包时按链回退。
  static const String mono = generated_tokens.YinheTypography.fontFamilyMono;
  static const List<String> monoFallback = generated_tokens.YinheTypography.fontFamilyMonoFallback;

  /// ID 展示字体链（数字脸：JetBrains Mono 置顶，中文回退界面链）
  static const String idDisplay = generated_tokens.YinheTypography.fontFamilyIdDisplay;
  static const List<String> idDisplayFallback = generated_tokens.YinheTypography.fontFamilyIdDisplayFallback;

  // ---- 字号（规范 §1.3） ----
  static const double sizeCaption = generated_tokens.YinheTypography.fontSizeCaption;
  static const double sizeLabel = generated_tokens.YinheTypography.fontSizeLabel;
  static const double sizeBodyS = generated_tokens.YinheTypography.fontSizeBodyS;
  static const double sizeBodyM = generated_tokens.YinheTypography.fontSizeBodyM;
  static const double sizeBodyL = generated_tokens.YinheTypography.fontSizeBodyL;
  static const double sizeTitleM = generated_tokens.YinheTypography.fontSizeTitleM;
  static const double sizeTitleL = generated_tokens.YinheTypography.fontSizeTitleL;
  static const double sizeH3 = generated_tokens.YinheTypography.fontSizeH3;
  static const double sizeH2 = generated_tokens.YinheTypography.fontSizeH2;
  static const double sizeH1 = generated_tokens.YinheTypography.fontSizeH1;
  static const double sizeDisplay = generated_tokens.YinheTypography.fontSizeDisplay;

  // ---- 字重 ----
  static const FontWeight weightRegular = generated_tokens.YinheTypography.weightRegular;
  static const FontWeight weightMedium = generated_tokens.YinheTypography.weightMedium;
  static const FontWeight weightSemibold = generated_tokens.YinheTypography.weightSemibold;
  static const FontWeight weightBold = generated_tokens.YinheTypography.weightBold;

  // ---- 字距（em；数字脸 -0.02em、分区标签英文大写 +0.12em） ----
  static const double letterSpacingNumericFace = generated_tokens.YinheTypography.letterSpacingNumericFace;
  static const double letterSpacingSectionLabel = generated_tokens.YinheTypography.letterSpacingSectionLabel;

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
  static const TextStyle display = generated_tokens.YinheTextStyles.display;

  /// h1 34/42 字重 600
  static const TextStyle h1 = generated_tokens.YinheTextStyles.h1;

  /// h2 28/36 字重 600
  static const TextStyle h2 = generated_tokens.YinheTextStyles.h2;

  /// h3 24/32 字重 600
  static const TextStyle h3 = generated_tokens.YinheTextStyles.h3;

  /// titleL 20/28 字重 600
  static const TextStyle titleL = generated_tokens.YinheTextStyles.titleL;

  /// titleM 18/26 字重 600
  static const TextStyle titleM = generated_tokens.YinheTextStyles.titleM;

  /// bodyL 16/24 字重 400/500
  static const TextStyle bodyL = generated_tokens.YinheTextStyles.bodyL;

  /// bodyM 14/22 字重 400/500
  static const TextStyle bodyM = generated_tokens.YinheTextStyles.bodyM;

  /// bodyS 13/20 字重 400/500
  static const TextStyle bodyS = generated_tokens.YinheTextStyles.bodyS;

  /// label 12/18 字重 500/600
  static const TextStyle label = generated_tokens.YinheTextStyles.label;

  /// caption 11/16 字重 500
  static const TextStyle caption = generated_tokens.YinheTextStyles.caption;
}

/// 阴影 token（规范 §1.4：Elevation 1 卡片 hover / 2 工具栏菜单 / 3 对话框；
/// 深色 Raised 顶部叠加 1px 内高光，另见 YinheColors.raisedTopHighlight）。
class YinheElevation {
  YinheElevation._();

  static const List<BoxShadow> elev1 = generated_tokens.YinheElevation.elev1;
  static const List<BoxShadow> elev2 = generated_tokens.YinheElevation.elev2;
  static const List<BoxShadow> elev3 = generated_tokens.YinheElevation.elev3;
  static const List<BoxShadow> elev1Dark = generated_tokens.YinheElevation.elev1Dark;
  static const List<BoxShadow> elev2Dark = generated_tokens.YinheElevation.elev2Dark;
  static const List<BoxShadow> elev3Dark = generated_tokens.YinheElevation.elev3Dark;

  /// 深色 Raised 顶部 1px 内高光（规范 §1.2 受光三要素之二，透明度 .04~.06）。
  static const List<BoxShadow> raisedInsetDark = generated_tokens.YinheElevation.raisedInsetDark;
}

/// 层级 token（规范 §9.2）。
class YinheZIndex {
  YinheZIndex._();
  static const int base = generated_tokens.YinheZIndex.base;
  static const int sticky = generated_tokens.YinheZIndex.sticky;
  static const int dropdown = generated_tokens.YinheZIndex.dropdown;
  static const int sessionToolbar = generated_tokens.YinheZIndex.sessionToolbar;
  static const int scrim = generated_tokens.YinheZIndex.scrim;
  static const int dialog = generated_tokens.YinheZIndex.dialog;
  static const int toast = generated_tokens.YinheZIndex.toast;
}

/// 核心尺寸 token（规范 §9.1）。
class YinheSize {
  YinheSize._();
  static const double sidebarDesktop = generated_tokens.YinheSize.sidebarDesktop;
  static const double sidebarAdmin = generated_tokens.YinheSize.sidebarAdmin;
  static const double topbar = generated_tokens.YinheSize.topbar;
  static const double inputDefault = generated_tokens.YinheSize.inputDefault;
  static const double buttonDefault = generated_tokens.YinheSize.buttonDefault;
  static const double touchTarget = generated_tokens.YinheSize.touchTarget;
  static const double tableRowCompact = generated_tokens.YinheSize.tableRowCompact;
  static const double tableRowDefault = generated_tokens.YinheSize.tableRowDefault;
  static const double mobileRemoteToolbar = generated_tokens.YinheSize.mobileRemoteToolbar;
  static const double contentMax = generated_tokens.YinheSize.contentMax;
}
