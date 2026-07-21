import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../models/platform_model.dart';
import 'motion.dart';

/// 移动会话四阶段连接进度卡（蓝鲸银河 P2-D）。
///
/// 展示体系复用桌面 ConnectingStageCard / FfiModel.connectionStage：
/// 阶段索引仅由既有连接事件驱动（连接发起 → 0，`connection_ready` → 3），
/// 纯表现层，不改任何连接逻辑与 FFI。
/// 阶段文案按规范 v2.1 四阶段重排：连接中继 → 安全协商 → 身份验证 → 建立画面。
///
/// 失败/超时语义：
/// - Rust 侧硬错误仍由既有 msgBox 错误对话框承载（错误详情 + 重试，含自动重试），
///   与桌面一致（该流程在 model.dart/common.dart，本卡不越界改）；
/// - 长时间未完成（> 20s）时本卡内显示「连接时间较长」与重试入口，
///   重试直接 sessionReconnect 并复位阶段，不离开本卡；
/// - 「诊断详情」可随时展开查看对端 ID / 会话 / 已等待 / 加密与拓扑信息。
class MobileConnectingStageCard extends StatefulWidget {
  /// 当前阶段索引（0 起），之前的阶段视为已完成。
  final RxInt stage;
  final VoidCallback onCancel;
  final String peerId;
  final String sessionLabel;

  const MobileConnectingStageCard({
    Key? key,
    required this.stage,
    required this.onCancel,
    required this.peerId,
    required this.sessionLabel,
  }) : super(key: key);

  /// 规范 v2.1 四阶段（连接中继 → 安全协商 → 身份验证 → 建立画面）。
  static const List<String> stageLabels = [
    '连接中继',
    '安全协商',
    '身份验证',
    '建立画面',
  ];

  /// 超过该时长未完成则显示「连接时间较长」与重试入口（规范 §2.4.A 同值）。
  static const int kSlowHintSeconds = 20;

  @override
  State<MobileConnectingStageCard> createState() =>
      _MobileConnectingStageCardState();
}

class _MobileConnectingStageCardState extends State<MobileConnectingStageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  bool _diagnosticsExpanded = false;

  @override
  void initState() {
    super.initState();
    // 当前阶段脉冲：动效 token 1.5s（reduced-motion 时在 build 中静态呈现，
    // 控制器停走，见 _activeDot）。
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _onRetry() {
    // 不离开本卡的重试：复位阶段并直接发起重连（等价 reconnect 的核心调用，
    // 避免 dismissAll 把本卡换成通用 loading）。
    widget.stage.value = 0;
    setState(() => _elapsedSeconds = 0);
    bind.sessionReconnect(sessionId: gFFI.sessionId, forceRelay: false);
  }

  Widget _stageIcon(bool done, bool active, bool reduceMotion) {
    if (done) {
      return const Icon(Icons.check_circle,
          key: ValueKey('done'), size: 16, color: MyTheme.success);
    }
    if (active) {
      final dot = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: MyTheme.accent,
          shape: BoxShape.circle,
        ),
      );
      if (reduceMotion) {
        // reduced-motion：静态呈现（控制器已在 build 入口停走）
        return Container(key: const ValueKey('active'), child: dot);
      }
      return FadeTransition(
        key: const ValueKey('active'),
        opacity: _pulseController.drive(Tween<double>(begin: 0.3, end: 1.0)),
        child: dot,
      );
    }
    return Container(
      key: const ValueKey('pending'),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38, width: 1.5),
      ),
    );
  }

  Widget _buildStageRow(
      String label, bool done, bool active, bool reduceMotion) {
    final Color textColor = done
        ? Colors.white70
        : active
            ? MyTheme.accent
            : Colors.white38;
    final duration = yhMotionDuration(context, const Duration(milliseconds: 150));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44, // 触控/焦点区兜底
            height: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: duration,
                    child: _stageIcon(done, active, reduceMotion),
                  ),
                ),
              ),
            ),
          ),
          AnimatedDefaultTextStyle(
            duration: duration,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(translate(label)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnostics() {
    final ffiModel = gFFI.ffiModel;
    final secureText = ffiModel.secure == null
        ? '协商中'
        : ffiModel.secure == true
            ? '端到端加密'
            : '未加密';
    final topologyText = ffiModel.direct == null
        ? '协商中'
        : ffiModel.direct == true
            ? '直连'
            : '中继';
    final items = <String>[
      '对端 ID：${widget.peerId}',
      '会话：${widget.sessionLabel}',
      '已等待：${_elapsedSeconds}s',
      '安全：$secureText',
      '拓扑：$topologyText',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _diagnosticsExpanded = !_diagnosticsExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _diagnosticsExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color: Colors.white54,
                ),
                const SizedBox(width: 4),
                Text(translate('诊断详情'),
                    style:
                        const TextStyle(fontSize: 13, color: Colors.white54)),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectionArea(
              child: Text(
                items.join('\n'),
                style: const TextStyle(
                    fontSize: 12, color: Colors.white60, height: 1.5),
              ),
            ),
          ),
          crossFadeState: _diagnosticsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration:
              yhMotionDuration(context, const Duration(milliseconds: 150)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = yhReduceMotion(context);
    // 脉冲控制器集中在此按 reduced-motion 启停，避免在子组件 build 中产生副作用
    if (reduceMotion) {
      if (_pulseController.isAnimating) _pulseController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    }
    final showSlowHint = _elapsedSeconds >= MobileConnectingStageCard.kSlowHintSeconds;
    // 深空 surface（token 产物 yinhe_tokens.dart 落地后应替换为 token 引用）
    const surface = Color(0xFF141B2A);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(translate('正在连接'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(widget.peerId,
                style: const TextStyle(fontSize: 12, color: Colors.white38)),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final active = widget.stage.value
                .clamp(0, MobileConnectingStageCard.stageLabels.length - 1)
                .toInt();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0;
                    i < MobileConnectingStageCard.stageLabels.length;
                    i++)
                  _buildStageRow(MobileConnectingStageCard.stageLabels[i],
                      i < active, i == active, reduceMotion),
              ],
            );
          }),
          if (showSlowHint) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: MyTheme.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(translate('连接时间较长'),
                      style: const TextStyle(
                          fontSize: 12, color: MyTheme.warning)),
                ),
                TextButton(
                  onPressed: _onRetry,
                  child: Text(translate('Retry'),
                      style: const TextStyle(color: MyTheme.accent)),
                ),
              ],
            ),
          ],
          _buildDiagnostics(),
          Center(
            child: TextButton(
              onPressed: widget.onCancel,
              child: Text(translate('Cancel'),
                  style: const TextStyle(color: MyTheme.accent)),
            ),
          ),
        ],
      ),
    );
  }
}
