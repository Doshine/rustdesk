import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../theme/yinhe_tokens.dart';

/// 连接阶段失败类型（蓝鲸银河 v2.1 §2.1.B 连接阶段失败树）。
enum ConnectingFailureKind {
  /// 对端不在线（停留「连接中继」）
  peerOffline,

  /// ID 非法 / 不存在（停留「连接中继」）
  invalidId,

  /// 密钥协商失败 / 版本不兼容（停留「安全协商」）
  negotiationFailed,

  /// 密码错误（停留「身份验证」）
  passwordError,

  /// 对端权限缺失，如 macOS 录屏/辅助功能（停留「建立画面」）
  permissionDenied,

  /// 对端主动断开（停留当前阶段）
  peerDisconnected,

  /// 其他连接错误（停留当前阶段）
  generic,
}

/// 一次连接阶段失败的展示数据（纯 UI；诊断内容全部来自现有事件/日志字段，
/// 不新建后端）。
class ConnectingFailure {
  final ConnectingFailureKind kind;

  /// 停留的阶段下标（0 连接中继 / 1 安全协商 / 2 身份验证 / 3 建立画面）。
  final int stageIndex;

  /// 原始 msgbox 事件字段（诊断详情展示用）。
  final String? type;
  final String? title;
  final String? message;
  final DateTime at;

  ConnectingFailure({
    required this.kind,
    required this.stageIndex,
    this.type,
    this.title,
    this.message,
    DateTime? at,
  }) : at = at ?? DateTime.now();
}

/// 把 Rust 侧现有 msgbox 事件（type/title/text）归类为失败树节点。
/// 仅做展示分类，不改变既有错误对话框与自动重试逻辑；
/// 返回 null 表示该事件不属于连接期失败（如输入密码、对端重启重连等）。
/// 文案依据 src/client.rs 的真实错误串（"Remote desktop is offline"、
/// "ID does not exist"、"Failed to secure tcp"、"Key mismatch"、
/// "Reset by the peer" 等）。
ConnectingFailure? classifyConnectingFailure(
    String? type, String? title, String? text, int currentStage) {
  final t = (text ?? '').toLowerCase();
  final stage = currentStage.clamp(0, 3).toInt();
  // 密码错误：失败树「身份验证」阶段（原地重输由既有 wrongPasswordDialog 承担）。
  if (type == 're-input-password') {
    return ConnectingFailure(
      kind: ConnectingFailureKind.passwordError,
      stageIndex: 2,
      type: type,
      title: title,
      message: text,
    );
  }
  final isConnError = title == 'Connection Error' || type == 'error';
  if (!isConnError) return null;
  if (t.contains('offline')) {
    return ConnectingFailure(
        kind: ConnectingFailureKind.peerOffline,
        stageIndex: 0,
        type: type,
        title: title,
        message: text);
  }
  if (t.contains('id does not exist') || t.contains('invalid id')) {
    return ConnectingFailure(
        kind: ConnectingFailureKind.invalidId,
        stageIndex: 0,
        type: type,
        title: title,
        message: text);
  }
  if (t.contains('rendezvous') ||
      t.contains('relay server') ||
      t.contains('direct connection')) {
    return ConnectingFailure(
        kind: ConnectingFailureKind.peerOffline,
        stageIndex: 0,
        type: type,
        title: title,
        message: text);
  }
  if (t.contains('secure') || t.contains('key')) {
    return ConnectingFailure(
        kind: ConnectingFailureKind.negotiationFailed,
        stageIndex: 1,
        type: type,
        title: title,
        message: text);
  }
  if (t.contains('permission') || t.contains('denied')) {
    return ConnectingFailure(
        kind: ConnectingFailureKind.permissionDenied,
        stageIndex: 3,
        type: type,
        title: title,
        message: text);
  }
  if (t.contains('reset by the peer') || t.contains('closed by the peer')) {
    return ConnectingFailure(
        kind: ConnectingFailureKind.peerDisconnected,
        stageIndex: stage,
        type: type,
        title: title,
        message: text);
  }
  return ConnectingFailure(
      kind: ConnectingFailureKind.generic,
      stageIndex: stage,
      type: type,
      title: title,
      message: text);
}

/// 阶段行状态（当前阶段品牌蓝、完成成功色、等待中性色、失败危险色 —— §2.1.B）。
enum _StageStatus { pending, active, done, failed }

/// 连接中阶段卡（桌面远程会话建立过程，P2-B 连接仪式感与四阶段重构）。
///
/// 纯展示组件。活动阶段来自 [FfiModel.connectionStage]，失败态来自
/// [FfiModel.connectionFailure]，均由既有连接事件驱动（model.dart），
/// 不改动任何连接逻辑 / FFI。
///
/// 四阶段按真实协议顺序：连接中继 → 安全协商 → 身份验证 → 建立画面（§2.1.B）。
/// 连接仪式感三段式：鲸鱼尾摆描边轨迹（1.2s 循环渐变描边）→ Logo 位淡入
/// （200ms）→ 成功确认脉冲（#39C894 深 / #167C59 浅，1.4s 两圈，单次播放，
/// 点击或任意键可跳过）。`MediaQuery.disableAnimations`（Flutter 侧
/// reduced-motion 等价能力，由 WidgetsBinding 平台无障碍特性映射）开启时
/// 全部降级为静态阶段列表 + 静态「已连接」标识。
class ConnectingStageCard extends StatefulWidget {
  /// Active stage index (0-based). Stages before it are done.
  final RxInt stage;
  final VoidCallback onCancel;

  /// 失败树状态（可选）：非空时卡片停留对应阶段并给出「重试 + 诊断详情」。
  final Rx<ConnectingFailure?>? failure;

  /// 失败态「重试」入口（与既有错误对话框的 Retry 同路径：reconnect）。
  final VoidCallback? onRetry;

  /// 连接通道探测（可选）：true=UDP 直连，false=已回退 TCP（中继），null=未知。
  /// 用于「UDP 回退 TCP 不视为失败」的阶段内降级提示与诊断详情。
  final bool? Function()? direct;

  const ConnectingStageCard({
    Key? key,
    required this.stage,
    required this.onCancel,
    this.failure,
    this.onRetry,
    this.direct,
  }) : super(key: key);

  /// 四阶段按真实协议顺序（§2.1.B，不显示通用步骤编号）。
  static const List<String> stageLabels = [
    '连接中继',
    '安全协商',
    '身份验证',
    '建立画面',
  ];

  /// 阶段图标（线性风格，与图标体系 §4 的 1.5px 圆角基调一致）。
  static const List<IconData> stageIcons = [
    Icons.router, // 连接中继
    Icons.vpn_key, // 安全协商
    Icons.verified_user_outlined, // 身份验证
    Icons.desktop_windows_outlined, // 建立画面
  ];

  @override
  State<ConnectingStageCard> createState() => _ConnectingStageCardState();
}

class _ConnectingStageCardState extends State<ConnectingStageCard>
    with SingleTickerProviderStateMixin {
  /// 当前阶段呼吸指示（Motion Ambient 1.5s，承担 spinner 角色）。
  late final AnimationController _breathController;

  /// 鲸鱼尾摆轨迹描边（1.2s 循环，连接轨迹允许路径描边动画 —— §1.5）。
  late final AnimationController _trailController;

  /// 成功确认脉冲（1.4s 两圈，单次播放后静止）。
  late final AnimationController _pulseController;

  Worker? _stageWorker;
  bool _diagExpanded = false;
  bool _pulseStarted = false;
  bool _ceremonySkipped = false;
  bool _reduceMotion = false;

  static int get _lastStage => ConnectingStageCard.stageLabels.length - 1;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: YinheMotion.ambient, // Motion Ambient 1.5s（§1.5）
    );
    _trailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // 轨迹描边 1.2s 循环
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // 确认脉冲 1.4s 两圈
    );
    _stageWorker = ever<int>(widget.stage, (s) {
      if (s >= _lastStage) _startConfirmPulse();
    });
    // 若展示卡片时已处于末阶段（如快速重连），首帧后立即补齐仪式。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.stage.value >= _lastStage) _startConfirmPulse();
    });
  }

  @override
  void dispose() {
    _stageWorker?.dispose();
    _breathController.dispose();
    _trailController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startConfirmPulse() {
    if (_reduceMotion || _ceremonySkipped || _pulseStarted) return;
    _pulseStarted = true;
    _pulseController.forward(from: 0.0);
  }

  /// 仪式可跳过：点击或任意键 → 立即进入静止成功态（§2.1.B）。
  void _skipCeremony() {
    if (!_pulseStarted || _ceremonySkipped) return;
    setState(() {
      _ceremonySkipped = true;
      _pulseController.stop();
    });
  }

  Color _successColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? YinheColors.successDark // #39C894（确认脉冲指定色）
          : YinheColors.successLight;

  Color _dangerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? YinheColors.dangerDark
          : YinheColors.dangerLight;

  Color _warningColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? YinheColors.warningDark
          : YinheColors.warningLight;

  String _failureHint(ConnectingFailureKind kind) {
    switch (kind) {
      case ConnectingFailureKind.peerOffline:
        return '对端不在线，请确认对端已启动并联网';
      case ConnectingFailureKind.invalidId:
        return 'ID 无效或不存在，请检查后重新输入';
      case ConnectingFailureKind.negotiationFailed:
        return '密钥协商失败或两端版本不兼容';
      case ConnectingFailureKind.passwordError:
        return '密码错误，请重新输入';
      case ConnectingFailureKind.permissionDenied:
        return '对端权限缺失（如 macOS 录屏 / 辅助功能）';
      case ConnectingFailureKind.peerDisconnected:
        return '对端主动断开了连接';
      case ConnectingFailureKind.generic:
        return '连接未完成';
    }
  }

  String _diagNote(ConnectingFailureKind kind) {
    switch (kind) {
      case ConnectingFailureKind.peerOffline:
        return '中继节点可达性与对端最近在线时间（以回执为准）';
      case ConnectingFailureKind.invalidId:
        return 'ID 校验规则与服务器回执码';
      case ConnectingFailureKind.negotiationFailed:
        return '加密套件与握手日志';
      case ConnectingFailureKind.passwordError:
        return '验证方式为一次性 / 固定密码';
      case ConnectingFailureKind.permissionDenied:
        return '对端逐项权限状态';
      case ConnectingFailureKind.peerDisconnected:
        return '断开码与断开方';
      case ConnectingFailureKind.generic:
        return '原始回执如上';
    }
  }

  _StageStatus _statusOf(
      int i, ConnectingFailure? failure, int active, bool success) {
    if (failure != null) {
      if (i == failure.stageIndex) return _StageStatus.failed;
      if (i < failure.stageIndex) return _StageStatus.done;
      return _StageStatus.pending;
    }
    if (success || i < active) return _StageStatus.done;
    if (i == active) return _StageStatus.active;
    return _StageStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    // reduced-motion 等价能力：MediaQuery.disableAnimations 由 WidgetsBinding
    // 平台无障碍特性（系统「减弱动态效果」）映射。
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      // 降级：静止阶段列表 + 静态「已连接」标识，无呼吸/轨迹/脉冲。
      if (_breathController.isAnimating) _breathController.stop();
      if (_trailController.isAnimating) _trailController.stop();
      if (_pulseController.isAnimating) _pulseController.stop();
    } else {
      if (!_breathController.isAnimating) {
        _breathController.repeat(reverse: true);
      }
      if (!_trailController.isAnimating) _trailController.repeat();
    }
    // Content of the connecting dialog. The caller wraps this in a
    // CustomAlertDialog because OverlayDialogManager's DialogBuilder must
    // return a CustomAlertDialog.
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // 任意键跳过仪式；不吞键，事件继续向上传递。
        _skipCeremony();
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _skipCeremony,
        child: Container(
          constraints:
              const BoxConstraints(maxWidth: 420), // §2.1.B 连接中卡片宽 420
          padding: const EdgeInsets.all(24), // 内边距 24
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRitualHeader(context),
              const SizedBox(height: 12),
              Obx(() {
                final failure = widget.failure?.value;
                final success =
                    failure == null && widget.stage.value >= _lastStage;
                final title = failure != null
                    ? '连接未成功'
                    : success
                        ? '已连接'
                        : '正在连接';
                return Text(translate(title),
                    style: const TextStyle(
                        fontSize: YinheFonts.sizeBodyL,
                        fontWeight: YinheFonts.weightSemibold));
              }),
              const SizedBox(height: 16),
              Obx(() => _buildStageList(context)),
              Obx(() => _buildRelayHint(context)),
              Obx(() {
                final f = widget.failure?.value;
                if (f == null) return const SizedBox.shrink();
                return _buildFailurePanel(context, f);
              }),
              const SizedBox(height: 16),
              Obx(() => _buildButtons(context)),
            ],
          ),
        ),
      ),
    );
  }

  /// 仪式头部：鲸鱼尾摆轨迹 + Logo 占位 + 确认脉冲。
  Widget _buildRitualHeader(BuildContext context) {
    final successColor = _successColor(context);
    return SizedBox(
      height: 64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final logoCenter = Offset(w - 20, 32);
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _trailController,
                  builder: (context, _) => CustomPaint(
                    painter: _WhaleTrailPainter(
                      progress: _reduceMotion ? 1.0 : _trailController.value,
                      trailWidth: math.max(w - 52, 0.0),
                      trackColor:
                          Theme.of(context).dividerColor.withOpacity(0.35),
                    ),
                  ),
                ),
              ),
              if (_pulseStarted && !_ceremonySkipped && !_reduceMotion)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) => CustomPaint(
                      painter: _ConfirmPulsePainter(
                        progress: _pulseController.value,
                        center: logoCenter,
                        color: successColor,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                top: 12,
                child: Obx(() => _buildLogoSlot(context, successColor)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoSlot(BuildContext context, Color successColor) {
    final success = widget.failure?.value == null &&
        widget.stage.value >= _lastStage;
    // ── Logo 占位（规范 §8.4）────────────────────────────────────
    // 正式鲸 Logo 资产（鲸尾星河标，登记于 yinhe/docs/design 资产清单）
    // 到位后替换本占位：保持 40px 视觉尺寸与 12.5% 最小安全区，不重画标志。
    return AnimatedContainer(
      duration: YinheMotion.normal, // Logo 淡入显现 200ms（仪式三段式之二）
      curve: YinheMotion.standard,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: success ? null : YinheColors.brandGradient,
        color: success ? successColor : null,
      ),
      child: AnimatedSwitcher(
        duration: YinheMotion.normal,
        child: Icon(
          success ? Icons.check : Icons.waves,
          key: ValueKey(success),
          size: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStageList(BuildContext context) {
    final failure = widget.failure?.value;
    final active = widget.stage.value.clamp(0, _lastStage).toInt();
    final success = failure == null && active >= _lastStage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < ConnectingStageCard.stageLabels.length; i++)
          _buildStageRow(context, i,
              failure: failure, active: active, success: success),
      ],
    );
  }

  Widget _buildStageRow(BuildContext context, int i,
      {required ConnectingFailure? failure,
      required int active,
      required bool success}) {
    final status = _statusOf(i, failure, active, success);
    final successColor = _successColor(context);
    final dangerColor = _dangerColor(context);
    final textColor = status == _StageStatus.failed
        ? dangerColor
        : status == _StageStatus.active
            ? MyTheme.accent
            : status == _StageStatus.pending
                ? Colors.grey
                : Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              // 段间过渡 0.42s Cubic(0.2,0,0,1)（§1.5 Motion Collapse）。
              child: AnimatedSwitcher(
                duration: YinheMotion.collapse,
                switchInCurve: YinheMotion.standard,
                switchOutCurve: YinheMotion.standard,
                child: _stageBadge(status, i, successColor, dangerColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedDefaultTextStyle(
            duration: YinheMotion.collapse,
            curve: YinheMotion.standard,
            style: TextStyle(
              fontSize: YinheFonts.sizeBodyS,
              color: textColor,
              fontWeight:
                  (status == _StageStatus.active || status == _StageStatus.failed)
                      ? FontWeight.w600
                      : FontWeight.normal,
            ),
            child: Text(translate(ConnectingStageCard.stageLabels[i])),
          ),
        ],
      ),
    );
  }

  Widget _stageBadge(
      _StageStatus status, int i, Color successColor, Color dangerColor) {
    switch (status) {
      case _StageStatus.done:
        return Icon(Icons.check_circle,
            key: const ValueKey('done'), size: 18, color: successColor);
      case _StageStatus.failed:
        return Icon(Icons.error,
            key: const ValueKey('failed'), size: 18, color: dangerColor);
      case _StageStatus.active:
        final icon = Icon(ConnectingStageCard.stageIcons[i],
            size: 18, color: MyTheme.accent);
        if (_reduceMotion) {
          return SizedBox(key: const ValueKey('active'), child: icon);
        }
        return FadeTransition(
          key: const ValueKey('active'),
          opacity: _breathController.drive(Tween<double>(begin: 0.35, end: 1.0)),
          child: icon,
        );
      case _StageStatus.pending:
        return Icon(ConnectingStageCard.stageIcons[i],
            key: const ValueKey('pending'), size: 18, color: Colors.grey);
    }
  }

  /// UDP 回退 TCP：不视为失败，阶段内降级提示（§2.1.B 失败树）。
  Widget _buildRelayHint(BuildContext context) {
    final direct = widget.direct?.call();
    final active = widget.stage.value;
    final failure = widget.failure?.value;
    if (failure != null || direct != false || active < _lastStage) {
      return const SizedBox.shrink();
    }
    final warnColor = _warningColor(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_calls, size: 14, color: warnColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(translate('已回退 TCP：当前经中继连接'),
                style:
                    TextStyle(fontSize: YinheFonts.sizeLabel, color: warnColor)),
          ),
        ],
      ),
    );
  }

  /// 失败面板：停留对应阶段 + 重试 + 诊断详情（展开面板展示现有日志信息）。
  Widget _buildFailurePanel(BuildContext context, ConnectingFailure f) {
    final dangerColor = _dangerColor(context);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dangerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(YinheRadius.card),
        border: Border.all(color: dangerColor.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: dangerColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  translate(_failureHint(f.kind)),
                  style: TextStyle(
                      fontSize: YinheFonts.sizeBodyS,
                      color: dangerColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _diagExpanded = !_diagExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _diagExpanded ? 0.5 : 0.0,
                  duration: YinheMotion.collapse,
                  curve: YinheMotion.standard,
                  child: Icon(Icons.expand_more,
                      size: 16, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(width: 4),
                Text(translate('诊断详情'),
                    style: TextStyle(
                        fontSize: YinheFonts.sizeLabel,
                        color: theme.textTheme.bodySmall?.color)),
              ],
            ),
          ),
          AnimatedSize(
            duration: YinheMotion.collapse, // 折叠 0.42s（§1.5 Motion Collapse）
            curve: YinheMotion.standard,
            alignment: Alignment.topCenter,
            child: _diagExpanded
                ? _buildDiagnostics(context, f)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  /// 诊断详情：全部来自现有事件/日志字段（阶段、事件类型、回执、通道、时间），
  /// 不新建后端。
  Widget _buildDiagnostics(BuildContext context, ConnectingFailure f) {
    final direct = widget.direct?.call();
    final channel = direct == null ? '未知' : (direct ? 'UDP 直连' : 'TCP 中继');
    final at = f.at;
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}';
    final lines = <String, String>{
      '阶段': ConnectingStageCard.stageLabels[f.stageIndex.clamp(0, _lastStage).toInt()],
      '事件类型': f.type ?? '—',
      '回执标题': f.title ?? '—',
      '回执内容': f.message == null ? '—' : translate(f.message!),
      '连接通道': channel,
      '发生时间': time,
      '诊断参考': _diagNote(f.kind),
    };
    final style = TextStyle(
        fontSize: YinheFonts.sizeCaption,
        height: 1.6,
        color: Theme.of(context).textTheme.bodySmall?.color);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(YinheRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in lines.entries) Text('${e.key}：${e.value}', style: style),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    final failure = widget.failure?.value;
    if (failure == null) {
      return Center(child: dialogButton('Cancel', onPressed: widget.onCancel));
    }
    // 失败树：重试（与既有 Retry 同路径）+ 取消。
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.onRetry != null)
          dialogButton('Retry', onPressed: widget.onRetry!),
        if (widget.onRetry != null) const SizedBox(width: 12),
        dialogButton('Cancel', onPressed: widget.onCancel, isOutline: true),
      ],
    );
  }
}

/// 鲸鱼尾摆连接轨迹（仪式三段式之一）：圆角 S 形路径 + 蓝青两段渐变描边，
/// 1.2s 循环单向描边动画；reduced-motion 时 [progress] 固定为 1.0，
/// 只保留静态低亮轨迹（退化为静态阶段列表 —— §1.5 降级）。
class _WhaleTrailPainter extends CustomPainter {
  final double progress;
  final double trailWidth;
  final Color trackColor;

  _WhaleTrailPainter({
    required this.progress,
    required this.trailWidth,
    required this.trackColor,
  });

  Path _buildPath(double w, double h) {
    final p = Path();
    p.moveTo(0, h * 0.62);
    p.cubicTo(w * 0.22, h * 0.95, w * 0.30, h * 0.05, w * 0.52, h * 0.38);
    p.cubicTo(w * 0.68, h * 0.62, w * 0.80, h * 0.30, w, h * 0.50);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = math.min(trailWidth, size.width);
    if (w <= 0) return;
    final path = _buildPath(w, size.height);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawPath(path, trackPaint);
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [YinheColors.blue500, YinheColors.cyan500], // 蓝青两段渐变 §1.1
      ).createShader(Rect.fromLTWH(0, 0, w, size.height));
    for (final metric in path.computeMetrics()) {
      final total = metric.length;
      final dash = total * 0.38;
      final head = progress * (total + dash);
      final start = (head - dash).clamp(0.0, total).toDouble();
      final end = head.clamp(0.0, total).toDouble();
      if (end <= start) return;
      canvas.drawPath(metric.extractPath(start, end), trailPaint);
    }
  }

  @override
  bool shouldRepaint(_WhaleTrailPainter old) =>
      old.progress != progress ||
      old.trailWidth != trailWidth ||
      old.trackColor != trackColor;
}

/// 成功确认脉冲（仪式三段式之三）：成功色 #39C894（深色）/ #167C59（浅色），
/// 1.4s 内两圈扩散后静止，单次播放。
class _ConfirmPulsePainter extends CustomPainter {
  final double progress;
  final Offset center;
  final Color color;

  _ConfirmPulsePainter({
    required this.progress,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 2; i++) {
      final local = ((progress - i * 0.42) / 0.58).clamp(0.0, 1.0).toDouble();
      if (local <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withOpacity((1 - local) * 0.45);
      canvas.drawCircle(center, 10 + local * 26, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfirmPulsePainter old) =>
      old.progress != progress || old.center != center || old.color != color;
}
