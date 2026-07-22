// 蓝鲸银河 · 雷达节点状态组件 RadarStatusDot（设计规范 v2.1 §3.11 / §1.5）
//
// Phase 2「会话之魂」P2-C 交付物。零三方依赖（仅 Flutter SDK + yinhe_tokens）。
// 颜色全部引用 token（深浅双主题自适应），动效全部引用 YinheMotion token。
//
// ── 状态语义（规范 §3.11，替代单纯圆点）────────────────────────────
//   online      在线/健康：语义色圆环(1.5px) + 中心实心点；radar 模式呼吸脉冲
//               1.5s ease-in-out（Motion Ambient）
//   connecting  连接中：缺口圆环（300°，品牌蓝）；radar 模式描边旋转 1.5s 循环
//   warning     告警：语义色圆环 + 中心点；radar 模式脉冲 1.5s
//   danger      异常/危险：语义色圆环 + 中心点；radar 模式脉冲 1.5s
//   offline     离线：空心中性圆环（Neutral 400），任何模式都静止
//
// ── 三种模式（构造参数 mode，默认 radar）──────────────────────────
//   RadarDotMode.radar  完整雷达节点：圆环 + 中心点 + 呼吸脉冲/缺口旋转（默认）
//   RadarDotMode.dot    雷达结构静止版：圆环 + 中心点，无任何动画
//   RadarDotMode.static 纯实心圆点（offline 为空心环），兼容旧圆点视觉
//
// ── 尺寸（规范 §3.11：默认 12px / 中心点 4px，高密度列表 8px）─────
//   RadarDotSize.small = 8px（设备卡、列表行、连接页状态行）
//   RadarDotSize.medium = 10px（会话工具栏等中等密度）
//   RadarDotSize.large = 12px（默认；状态卡、总览位）
//   组件盒尺寸严格等于档位 px，可作为旧 8×8 圆点 Container 的原位替换。
//
// ── reduced-motion 降级（规范 §1.5 Motion Ambient → 静止态）───────
//   系统开启减少动态效果（MediaQuery.disableAnimations）时，radar 自动降级为
//   dot（保留圆环+中心点结构、去掉动画）；dot/static 本就不动画。全部动画只
//   驱动 opacity / transform，且 AnimationController 自动响应 TickerMode。
//
// ── 用法 ─────────────────────────────────────────────────────────
//   import 'package:flutter_hbb/common/widgets/radar_status_dot.dart';
//
//   // 完整状态：
//   RadarStatusDot(status: RadarDotStatus.online, size: RadarDotSize.small)
//   // 布尔在线态便捷构造：
//   RadarStatusDot.online(online: peer.online, size: RadarDotSize.small)
//
// ══ 各端集成指引 ═════════════════════════════════════════════════
//
// 【1】主窗口连接状态 OnlineStatusWidget（重要：定义文件不在本任务范围）
//   OnlineStatusWidget 定义于 lib/desktop/pages/connection_page.dart:24
//   （desktop/pages 属桌面端页面范围，由对应工程师负责；本 Phase 不代改，
//   desktop_home_page.dart 仅为使用方，无需改动）。集成步骤：
//   1. 文件头 import 'package:flutter_hbb/common/widgets/radar_status_dot.dart';
//   2. basicWidget() 中 8×8 圆点 Container（connection_page.dart 约 L115–127）：
//        Container(
//          height: 8, width: 8,
//          decoration: BoxDecoration(
//            borderRadius: BorderRadius.circular(4),
//            color: _svcStopped.value || ...connecting ? kColorWarn
//                : (...ready ? MyTheme.success : MyTheme.danger),
//          ),
//        ).marginSymmetric(horizontal: em),
//      原位替换为：
//        RadarStatusDot(
//          size: RadarDotSize.small, // 8px，与原盒尺寸一致
//          status: _svcStopped.value
//              ? RadarDotStatus.danger   // 服务停止；若需保留旧黄点改 warning
//              : stateGlobal.svcStatus.value == SvcStatus.connecting
//                  ? RadarDotStatus.connecting // 缺口蓝环旋转，替代旧黄点
//                  : (stateGlobal.svcStatus.value == SvcStatus.ready
//                      ? RadarDotStatus.online
//                      : RadarDotStatus.danger),
//        ).marginSymmetric(horizontal: em),
//   3. 状态文字 _buildConnStatusMsg() 及其余逻辑保持不变。
//
// 【2】设备卡 / 最近设备网格（common/widgets/peer_card.dart，getOnline L1469）
//   规范 §2.1.B：在线状态使用雷达节点，只在设备真实在线时点亮。getOnline()
//   内 CircleAvatar(radius: 3, backgroundColor: online ? success : warning)
//   替换为（保留外层 Tooltip 与 Padding）：
//        child: RadarStatusDot.online(
//          online: online,
//          size: RadarDotSize.small, // 高密度列表 8px
//        ),
//   注意：旧逻辑用 warning 色表示 offline；规范 §3.11 规定离线=空心中性
//   圆环，替换后语义自动对齐。peer_card.dart 若在并行任务中属他人负责，
//   则由设备卡负责人在其任务内替换，本组件已就绪可直接引用。
//
// 【3】会话工具栏（desktop 远控页工具栏 / 网络质量区）
//   连接状态位（连接中/已建立/异常）用：
//        RadarStatusDot(status: ..., size: RadarDotSize.small /* 或 medium */)
//   注意：规范 §3.11 的「网络质量 4 档信号条徽标」（优 4 格 / 良 3 格 /
//   一般 2 格 / 差 1 格 / 断开空心）不是圆点，不属于本组件，应由信号条
//   徽标组件另行实现；勿用本组件拼凑。
//
// 【4】移动端（mobile/pages 各状态点）
//   与桌面端同一组件直接复用，建议 small/medium 档；reduced-motion 与
//   TickerMode（页面不可见自动暂停）均已内置，无需端侧额外处理。
//
// ── 验证 ─────────────────────────────────────────────────────────
//   本文件交付时经括号平衡脚本 + 人工复核；集成后请在完整工程执行
//   `flutter analyze` 与桌面/移动双端目测（含系统减少动态效果开关）。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/yinhe_tokens.dart';

/// 雷达节点语义状态（规范 §3.11）。
enum RadarDotStatus {
  /// 在线/健康：语义色圆环 + 中心实心点，radar 模式呼吸脉冲。
  online,

  /// 连接中：缺口圆环（品牌蓝），radar 模式描边旋转 1.5s 循环。
  connecting,

  /// 告警：语义色圆环 + 中心点，radar 模式脉冲。
  warning,

  /// 异常/危险：语义色圆环 + 中心点，radar 模式脉冲。
  danger,

  /// 离线：空心中性圆环（Neutral 400），永不动画。
  offline,
}

/// 渲染模式（详见文件头；默认 [radar]）。
enum RadarDotMode {
  /// 纯实心圆点（offline 为空心环），兼容旧圆点视觉，无动画。
  static,

  /// 圆环 + 中心点的静止雷达结构，无动画。
  dot,

  /// 完整雷达节点：圆环 + 中心点 + 呼吸脉冲 / 缺口旋转（默认）。
  radar,
}

/// 尺寸档位（规范 §3.11：默认 12px，高密度列表 8px，另补 10px 中档）。
enum RadarDotSize {
  /// 8px：设备卡、列表行、连接页状态行等高密度场景。
  small(8),

  /// 10px：会话工具栏等中等密度场景。
  medium(10),

  /// 12px：默认档（中心点 4px），状态卡、总览位。
  large(12);

  const RadarDotSize(this.px);

  /// 组件盒边长（正方形）。
  final double px;
}

/// 蓝鲸银河雷达节点状态点（规范 v2.1 §3.11）。
///
/// 状态语义、模式、尺寸、reduced-motion 降级与各端集成指引见文件头注释。
class RadarStatusDot extends StatelessWidget {
  const RadarStatusDot({
    super.key,
    required this.status,
    this.mode = RadarDotMode.radar,
    this.size = RadarDotSize.large,
    this.semanticLabel,
  });

  /// 便捷构造：布尔在线态 → [RadarDotStatus.online] / [RadarDotStatus.offline]。
  const RadarStatusDot.online({
    super.key,
    required bool online,
    this.mode = RadarDotMode.radar,
    this.size = RadarDotSize.large,
    this.semanticLabel,
  }) : status =
            online ? RadarDotStatus.online : RadarDotStatus.offline;

  /// 语义状态。
  final RadarDotStatus status;

  /// 渲染模式，默认 [RadarDotMode.radar]。
  final RadarDotMode mode;

  /// 尺寸档位，默认 [RadarDotSize.large]（12px）。
  final RadarDotSize size;

  /// 可选无障碍标签（如 '在线'）；为 null 时不附加语义。
  final String? semanticLabel;

  Color _resolveColor(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    switch (status) {
      case RadarDotStatus.online:
        return dark ? YinheColors.successDark : YinheColors.successLight;
      case RadarDotStatus.connecting:
        // 品牌蓝，深浅主题通用（规范 §3.11 连接中=品牌蓝）。
        return YinheColors.blue500;
      case RadarDotStatus.warning:
        return dark ? YinheColors.warningDark : YinheColors.warningLight;
      case RadarDotStatus.danger:
        return dark ? YinheColors.dangerDark : YinheColors.dangerLight;
      case RadarDotStatus.offline:
        return YinheColors.neutral400;
    }
  }

  @override
  Widget build(BuildContext context) {
    // reduced-motion：radar 降级为静止 dot（规范 §1.5 Motion Ambient → 静止态）。
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final RadarDotMode effective =
        (mode == RadarDotMode.radar && reduceMotion)
            ? RadarDotMode.dot
            : mode;

    final Color color = _resolveColor(Theme.of(context).brightness);
    final bool animated =
        effective == RadarDotMode.radar && status != RadarDotStatus.offline;

    Widget dot = animated
        ? _RadarPulse(status: status, color: color, size: size.px)
        : CustomPaint(
            size: Size.square(size.px),
            painter: _RadarPainter(
              status: status,
              color: color,
              mode: effective,
              phase: 1.0, // 静止渲染取最亮/全显相位
            ),
          );

    final String? label = semanticLabel;
    if (label != null) {
      dot = Semantics(label: label, child: dot);
    }
    return dot;
  }
}

/// radar 模式动画宿主：驱动 1.5s Motion Ambient 相位。
///
/// 仅 online/warning/danger（呼吸，ease-in-out 往返）与 connecting（线性
/// 旋转）进入本组件；offline 与 reduced-motion 由上层短路为静止绘制。
/// TickerMode 关闭（页面不可见）时 controller 自动暂停。
class _RadarPulse extends StatefulWidget {
  const _RadarPulse({
    required this.status,
    required this.color,
    required this.size,
  });

  final RadarDotStatus status;
  final Color color;
  final double size;

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _phase;

  bool get _rotating => widget.status == RadarDotStatus.connecting;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: YinheMotion.ambient, // 1.5s（规范 §1.5 Motion Ambient）
    );
    _syncAnimation();
  }

  void _syncAnimation() {
    _controller.stop();
    _controller.value = 0;
    // 呼吸：ease-in-out 往返；旋转：线性循环。均引用 token 曲线。
    _phase = _controller.drive(
      CurveTween(curve: _rotating ? Curves.linear : YinheMotion.easeInOut),
    );
    _controller.repeat(reverse: !_rotating);
  }

  @override
  void didUpdateWidget(covariant _RadarPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool wasRotating = oldWidget.status == RadarDotStatus.connecting;
    if (wasRotating != _rotating) {
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _phase,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _RadarPainter(
            status: widget.status,
            color: widget.color,
            mode: RadarDotMode.radar,
            phase: _phase.value,
          ),
        );
      },
    );
  }
}

/// 雷达节点绘制器。全部视觉约束在 size×size 盒内，可原位替换旧圆点。
///
/// 几何（规范 §3.11）：圆环线宽 1.5px；中心点直径 = size/3（12px → 4px）。
/// 动画仅 opacity / transform（规范 §1.5）：光环用 canvas 缩放扩散，
/// 中心点用 canvas 缩放呼吸，圆环只呼吸透明度。
class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.status,
    required this.color,
    required this.mode,
    required this.phase,
  });

  final RadarDotStatus status;
  final Color color;
  final RadarDotMode mode;

  /// 动效相位 0–1（呼吸为 ease-in-out 往返值；旋转为线性值）。
  /// 静止渲染传 1.0（最亮/全显态）。
  final double phase;

  /// 圆环线宽（规范 §3.11：1.5px）。
  static const double _stroke = 1.5;

  Paint _strokePaint(double opacity) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _stroke
    ..color = color.withOpacity(opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset center = size.center(Offset.zero);
    final double ringRadius = s / 2 - _stroke / 2;
    final double dotRadius = s / 6; // 直径 = size/3

    // 离线：空心中性圆环，任何模式都不动画。
    if (status == RadarDotStatus.offline) {
      canvas.drawCircle(center, ringRadius, _strokePaint(1.0));
      return;
    }

    // static：纯实心圆点（兼容旧圆点视觉），无圆环。
    if (mode == RadarDotMode.static) {
      canvas.drawCircle(center, s / 2, Paint()..color = color);
      return;
    }

    // 连接中：300° 缺口圆环；radar 模式随相位旋转 1.5s/圈。
    if (status == RadarDotStatus.connecting) {
      final double rotation =
          mode == RadarDotMode.radar ? 2 * math.pi * phase : 0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -math.pi / 2 + rotation,
        math.pi * 5 / 3, // 300°，留 60° 缺口
        false,
        _strokePaint(1.0)..strokeCap = StrokeCap.round,
      );
      return;
    }

    // 在线/告警/危险：圆环 + 中心点；radar 模式呼吸脉冲。
    final bool pulsing = mode == RadarDotMode.radar;
    final double t = pulsing ? phase : 1.0;

    // 扩散光环：transform 缩放 dotRadius → ringRadius，透明度随扩散衰减。
    if (pulsing) {
      final double haloOpacity = 0.30 * (1 - t);
      if (haloOpacity > 0.01) {
        final double haloScale =
            dotRadius / ringRadius + (1 - dotRadius / ringRadius) * t;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(haloScale);
        // 线宽除以缩放系数，保持视觉 1.5px。
        canvas.drawCircle(
          Offset.zero,
          ringRadius,
          _strokePaint(haloOpacity)..strokeWidth = _stroke / haloScale,
        );
        canvas.restore();
      }
    }

    // 主圆环：呼吸明暗 0.55 → 1.0（仅 opacity）。
    canvas.drawCircle(center, ringRadius, _strokePaint(0.55 + 0.45 * t));

    // 中心点：呼吸缩放 1.0 → 1.18（仅 transform）。
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1 + 0.18 * t);
    canvas.drawCircle(Offset.zero, dotRadius, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.status != status ||
        oldDelegate.mode != mode;
  }
}
