import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../common/shared_state.dart';
import '../../consts.dart';
import '../../common/widgets/quality_indicator.dart';
import '../../models/model.dart';

/// 会话顶部质量 HUD（设计稿 §4.2）。
///
/// 设计意图是「安静」：正常时是一条灰字胶囊，不闪不跳；只有质量掉档才把该数值
/// 变色，并用**结果语言**解释一句（「切到中继，因直连丢包」），不说
/// 「H.265 码率自适应下调」这类术语。恢复后 3 秒把解释收起来。
class SessionQualityHud extends StatefulWidget {
  final String id;
  final FFI ffi;

  const SessionQualityHud({Key? key, required this.id, required this.ffi})
      : super(key: key);

  @override
  State<SessionQualityHud> createState() => _SessionQualityHudState();
}

class _SessionQualityHudState extends State<SessionQualityHud> {
  /// 解释语当前是否展开。掉档立刻展开，恢复后延时收起。
  bool _explaining = false;
  Timer? _collapseTimer;
  QualityTier _lastTier = QualityTier.good;

  /// 最近一次收到质量数据的时刻，用于判 90s 无心跳 = 离线（§1.1）。
  DateTime _lastUpdate = DateTime.now();
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    widget.ffi.qualityMonitorModel.addListener(_onQuality);
    // 单纯为了让「超过 90s 没数据」这件事本身能触发一次重绘
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.ffi.qualityMonitorModel.removeListener(_onQuality);
    _collapseTimer?.cancel();
    _heartbeat?.cancel();
    super.dispose();
  }

  void _onQuality() {
    if (!mounted) return;
    setState(() => _lastUpdate = DateTime.now());
  }

  void _syncExplanation(QualityTier tier) {
    if (tier == _lastTier) return;
    _lastTier = tier;
    _collapseTimer?.cancel();
    if (tier == QualityTier.good) {
      _collapseTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _explaining = false);
      });
    } else {
      // 掉档立刻展开；这里不能在 build 里直接 setState，推到帧后
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_explaining) setState(() => _explaining = true);
      });
    }
  }

  /// 结果语言的解释（§4.2）。只说用户感知得到的因果，不说编解码参数。
  String? _explanation(QualityTier tier, bool? direct) {
    switch (tier) {
      case QualityTier.good:
        return null;
      case QualityTier.fair:
        return direct == false
            ? translate('hud_explain_fair_relay')
            : translate('hud_explain_fair_direct');
      case QualityTier.poor:
        return translate('hud_explain_poor');
      case QualityTier.offline:
        return translate('hud_explain_offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.ffi.qualityMonitorModel;
    final data = model.data;
    final rtt = int.tryParse(data.delay ?? '');
    final stale = DateTime.now().difference(_lastUpdate) > kQualityOfflineAfter;
    final tier = qualityTierOf(rttMs: rtt, offline: stale);
    _syncExplanation(tier);

    final conn = ConnectionTypeState.find(widget.id);
    final peerName = widget.ffi.ffiModel.pi.username.isNotEmpty
        ? widget.ffi.ffiModel.pi.username
        : widget.id;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Obx(() {
          // ConnectionType.direct 是 Rx<String>：kInvalidValueStr 表示还不知道，
          // '' 是直连，'_relay' 是中继（见 shared_state.dart 的 strDirect/strIndirect）
          final raw = conn.direct.value;
          final bool? direct =
              raw == kInvalidValueStr ? null : raw == ConnectionType.strDirect;
          final path = direct == null
              ? translate('quality_path_unknown')
              : direct
                  ? translate('quality_path_direct')
                  : translate('quality_path_relay');
          final codec = data.codecFormat ?? '—';
          final explanation = _explanation(tier, direct);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QualityDot(tier: tier, isDark: true),
                    const SizedBox(width: YinheSpacing.s8),
                    _text(peerName),
                    _sep(),
                    _text(rtt == null ? '— ms' : '$rtt ms',
                        color: tier == QualityTier.good
                            ? null
                            : qualityColorOf(tier, isDark: true)),
                    _sep(),
                    _text('${data.fps ?? '—'} FPS'),
                    _sep(),
                    _text('$path · $codec'),
                  ],
                ),
              ),
              if (_explaining && explanation != null) ...[
                const SizedBox(height: YinheSpacing.s4),
                _pill(
                  child: _text(explanation,
                      color: qualityColorOf(tier, isDark: true)),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _pill({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(YinheRadius.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              // #0B101A == surface.dark.sunken，86% 不透明度（§4.2）
              color: YinheColors.surfaceSunkenDark.withOpacity(0.86),
              borderRadius: BorderRadius.circular(YinheRadius.full),
            ),
            child: child,
          ),
        ),
      );

  Widget _sep() => Container(
        width: 1,
        height: 11,
        margin: const EdgeInsets.symmetric(horizontal: YinheSpacing.s8),
        color: YinheColors.borderDark,
      );

  /// HUD 恒在深色底上，文字色不随主题翻面，固定取 text.dark.secondary。
  Widget _text(String s, {Color? color}) => Text(
        s,
        style: TextStyle(
          fontSize: 11,
          height: 16 / 11,
          color: color ?? YinheColors.textSecondaryDark,
          fontFamily: YinheFonts.mono,
          fontFamilyFallback: YinheFonts.monoFallback,
          fontFeatures: const [FontFeature('tnum')],
        ),
      );
}
