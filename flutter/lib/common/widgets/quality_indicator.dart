import 'package:flutter/material.dart';

import '../../common.dart';

/// 网络质量指示（设计稿 §1.1）。
///
/// 唯一数据源是 QualityMonitorModel 的实测 RTT —— 不做估算、不做插值，
/// 拿不到数据就是 offline，不能拿一个好看的默认值糊过去。
///
/// 两条硬规则：
/// 1. 点永远和文字标签成对出现。只靠颜色承载信息对色觉障碍用户等于没有信息。
/// 2. 离线是**空心圈**不是灰色实心。灰色实心会被读成「在线但很差」。
enum QualityTier { good, fair, poor, offline }

/// 判档（§1.1 阈值表）。
///
/// [lossPercent] 目前拿不到：QualityMonitorData 只有 speed/fps/delay/bitrate/
/// codec/chroma，没有丢包字段。参数先留着，等 Rust 侧补上丢包统计就能直接生效；
/// 在那之前只按 RTT 判档，不编造丢包数。
QualityTier qualityTierOf({
  int? rttMs,
  double? lossPercent,
  bool offline = false,
}) {
  if (offline || rttMs == null) return QualityTier.offline;
  if (rttMs > 120 || (lossPercent != null && lossPercent > 5)) {
    return QualityTier.poor;
  }
  if (rttMs >= 50 || (lossPercent != null && lossPercent >= 1)) {
    return QualityTier.fair;
  }
  return QualityTier.good;
}

/// 心跳超过这个时长没更新就判离线（§1.1）。
const Duration kQualityOfflineAfter = Duration(seconds: 90);

Color qualityColorOf(QualityTier tier, {required bool isDark}) {
  switch (tier) {
    case QualityTier.good:
      return isDark ? YinheColors.qualityGoodDark : YinheColors.qualityGoodLight;
    case QualityTier.fair:
      return isDark ? YinheColors.qualityFairDark : YinheColors.qualityFairLight;
    case QualityTier.poor:
      return isDark ? YinheColors.qualityPoorDark : YinheColors.qualityPoorLight;
    case QualityTier.offline:
      // token 里深浅同值，离线态不随主题变
      return YinheColors.qualityOfflineDark;
  }
}

/// 质量点：直径 7px；离线态为 1.5px 描边空心圆。
class QualityDot extends StatelessWidget {
  final QualityTier tier;
  final double size;

  /// 强制指定明暗，用于固定深色底（如会话 HUD）上不跟随主题的场景。
  final bool? isDark;

  const QualityDot({Key? key, required this.tier, this.size = 7, this.isDark})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final color = qualityColorOf(tier, isDark: dark);
    final offline = tier == QualityTier.offline;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: offline ? Colors.transparent : color,
          border: offline ? Border.all(color: color, width: 1.5) : null,
        ),
      ),
    );
  }
}

/// 标签文案（§1.1 固定格式）：`{RTT} ms · {直连 | 中继·{节点名}}`。
///
/// 中继节点名客户端目前拿不到（`connection_ready` 只带 secure/direct/stream_type），
/// 拿不到就只写「中继」，不瞎编节点名。
String qualityLabelText({
  int? rttMs,
  bool? direct,
  String? relayNode,
}) {
  final rtt = rttMs == null ? '—' : '$rttMs';
  final String path;
  if (direct == null) {
    path = translate('quality_path_unknown');
  } else if (direct) {
    path = translate('quality_path_direct');
  } else {
    path = relayNode == null || relayNode.isEmpty
        ? translate('quality_path_relay')
        : '${translate('quality_path_relay')}·$relayNode';
  }
  return '$rtt ms · $path';
}

/// 点 + 文字，永远成对。
class QualityIndicator extends StatelessWidget {
  final int? rttMs;
  final double? lossPercent;
  final bool offline;
  final bool? direct;
  final String? relayNode;
  final double fontSize;
  final Color? textColor;
  final bool? isDark;

  const QualityIndicator({
    Key? key,
    this.rttMs,
    this.lossPercent,
    this.offline = false,
    this.direct,
    this.relayNode,
    this.fontSize = 12,
    this.textColor,
    this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tier =
        qualityTierOf(rttMs: rttMs, lossPercent: lossPercent, offline: offline);
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final text =
        qualityLabelText(rttMs: rttMs, direct: direct, relayNode: relayNode);
    return Semantics(
      label: '${translate('quality_semantics_prefix')} $text',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QualityDot(tier: tier, isDark: dark),
          const SizedBox(width: YinheSpacing.s8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor ??
                  (dark
                      ? YinheColors.textSecondaryDark
                      : YinheColors.textSecondaryLight),
              fontFamily: YinheFonts.mono,
              fontFamilyFallback: YinheFonts.monoFallback,
              fontFeatures: const [FontFeature('tnum')],
            ),
          ),
        ],
      ),
    );
  }
}
