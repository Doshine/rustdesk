import 'package:flutter/material.dart';

import '../../common.dart';

/// 统一的状态视图（设计稿 §1.3）。
///
/// 六种状态一个组件：空 / 加载 / 错 / 部分失败 / 权限拒绝 / 离线。
/// 除加载态外**每个状态都必须给 action** —— 这是构造函数里的断言，不是约定，
/// 因为「只报错不给下一步」正是当前各页面最常见的毛病。
///
/// 文案规则（§1.3）：
/// - 说人话。「对方设备离线，最后在线是 3 天前」优于「连接失败（代码 -1）」
/// - title 一句话、不超过 20 字；detail 说为什么；action 说现在该做什么
/// - 加载超过 3 秒自动补一句正在做什么（[loadingHint]）
///
/// 颜色一律走 theme/ 映射层，不在本文件里写字面值。
enum StateKind {
  /// 没有内容，但一切正常。
  empty,

  /// 正在取数据。唯一允许没有 action 的状态。
  loading,

  /// 取失败了。
  error,

  /// 取到一部分：能显示的先显示，同时说明哪部分没到。
  partial,

  /// 服务端/系统拒绝：权限不足。
  denied,

  /// 离线：本地网络或对端不可达。
  offline,
}

/// 状态视图上的下一步动作。[label] 是动词短语（「重试」「复制我的 ID」）。
class StateAction {
  final String label;
  final VoidCallback onPressed;

  /// 次要动作，例如「复制诊断」。可空。
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  const StateAction({
    required this.label,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });
}

class StateView extends StatefulWidget {
  final StateKind kind;

  /// 发生了什么。一句话。
  final String title;

  /// 为什么 / 补充信息。
  final String? detail;

  /// 我现在该做什么。除 loading 外必填。
  final StateAction? action;

  /// 原始错误串等排查信息，折叠在最下方，默认不占视线。
  final String? diagnostic;

  /// 加载超过 [loadingHintDelay] 后补充显示的一句话，例如「正在连接接入服务器…」。
  final String? loadingHint;

  final Duration loadingHintDelay;

  /// 紧凑模式：用于 360px 面板等窄容器，缩小插图与间距。
  final bool compact;

  const StateView({
    Key? key,
    required this.kind,
    required this.title,
    this.detail,
    this.action,
    this.diagnostic,
    this.loadingHint,
    this.loadingHintDelay = const Duration(seconds: 3),
    this.compact = false,
  })  : assert(kind == StateKind.loading || action != null,
            'StateView: 除加载态外必须给 action（设计稿 §1.3）'),
        super(key: key);

  @override
  State<StateView> createState() => _StateViewState();
}

class _StateViewState extends State<StateView> {
  bool _hintVisible = false;

  @override
  void initState() {
    super.initState();
    _scheduleHint();
  }

  @override
  void didUpdateWidget(covariant StateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _hintVisible = false;
      _scheduleHint();
    }
  }

  void _scheduleHint() {
    if (widget.kind != StateKind.loading || widget.loadingHint == null) return;
    Future.delayed(widget.loadingHintDelay, () {
      if (mounted && widget.kind == StateKind.loading) {
        setState(() => _hintVisible = true);
      }
    });
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  /// 每个状态的强调色。语义色双主题各取一档，不用灰色兜底——
  /// 灰色会让「出错了」和「空空如也」看起来一样。
  Color get _accent {
    switch (widget.kind) {
      case StateKind.empty:
      case StateKind.loading:
        return MyTheme.accent;
      case StateKind.error:
        return _isDark ? YinheColors.dangerDark : YinheColors.dangerLight;
      case StateKind.partial:
      case StateKind.denied:
        return _isDark ? YinheColors.warningDark : YinheColors.warningLight;
      case StateKind.offline:
        return _isDark
            ? YinheColors.qualityOfflineDark
            : YinheColors.qualityOfflineLight;
    }
  }

  IconData get _icon {
    switch (widget.kind) {
      case StateKind.empty:
        return Icons.inbox_outlined;
      case StateKind.loading:
        return Icons.autorenew_rounded;
      case StateKind.error:
        return Icons.error_outline_rounded;
      case StateKind.partial:
        return Icons.report_problem_outlined;
      case StateKind.denied:
        return Icons.lock_outline_rounded;
      case StateKind.offline:
        return Icons.cloud_off_outlined;
    }
  }

  Color get _titleColor =>
      _isDark ? YinheColors.textPrimaryDark : YinheColors.textPrimaryLight;

  Color get _detailColor =>
      _isDark ? YinheColors.textTertiaryDark : YinheColors.textTertiaryLight;

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact || !(isDesktop || isWebDesktop);
    final illoSize = compact ? 72.0 : 104.0;

    final illustration = SizedBox(
      width: illoSize,
      height: illoSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withOpacity(0.06),
              border:
                  Border.all(color: _accent.withOpacity(0.16), width: 1.5),
            ),
          ),
          if (widget.kind == StateKind.loading)
            SizedBox(
              width: illoSize * 0.52,
              height: illoSize * 0.52,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            )
          else
            Icon(_icon, size: illoSize * 0.40, color: _accent.withOpacity(0.85)),
        ],
      ),
    );

    final children = <Widget>[
      illustration,
      SizedBox(height: compact ? YinheSpacing.s16 : YinheSpacing.s20),
      Text(
        widget.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 14 : 15,
          fontWeight: FontWeight.w500,
          color: _titleColor,
        ),
      ),
    ];

    if (widget.detail?.isNotEmpty == true) {
      children
        ..add(const SizedBox(height: YinheSpacing.s8))
        ..add(Text(
          widget.detail!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _detailColor, height: 1.5),
        ));
    }

    if (_hintVisible && widget.loadingHint?.isNotEmpty == true) {
      children
        ..add(const SizedBox(height: YinheSpacing.s8))
        ..add(Text(
          widget.loadingHint!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _detailColor),
        ));
    }

    final action = widget.action;
    if (action != null) {
      children
        ..add(SizedBox(height: compact ? YinheSpacing.s16 : YinheSpacing.s20))
        ..add(Wrap(
          alignment: WrapAlignment.center,
          spacing: YinheSpacing.s8,
          runSpacing: YinheSpacing.s8,
          children: [
            _primaryButton(action.label, action.onPressed),
            if (action.secondaryLabel != null &&
                action.onSecondaryPressed != null)
              _secondaryButton(action.secondaryLabel!, action.onSecondaryPressed!),
          ],
        ));
    }

    if (widget.diagnostic?.isNotEmpty == true) {
      children
        ..add(const SizedBox(height: YinheSpacing.s12))
        ..add(_DiagnosticFold(
          text: widget.diagnostic!,
          color: _detailColor,
        ));
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? YinheSpacing.s16 : YinheSpacing.s24,
            vertical: YinheSpacing.s16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: MyTheme.accent,
          foregroundColor: YinheColors.textInverseLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(YinheRadius.control)),
          padding: const EdgeInsets.symmetric(
              horizontal: YinheSpacing.s20, vertical: YinheSpacing.s12),
          minimumSize: Size.zero,
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      );

  Widget _secondaryButton(String label, VoidCallback onPressed) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _detailColor,
          side: BorderSide(
              color: _isDark
                  ? YinheColors.borderDark
                  : YinheColors.borderLight,
              width: 1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(YinheRadius.control)),
          padding: const EdgeInsets.symmetric(
              horizontal: YinheSpacing.s16, vertical: YinheSpacing.s12),
          minimumSize: Size.zero,
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      );
}

/// 排查信息折叠区：默认收起，展开后可选中复制。
class _DiagnosticFold extends StatefulWidget {
  final String text;
  final Color color;

  const _DiagnosticFold({required this.text, required this.color});

  @override
  State<_DiagnosticFold> createState() => _DiagnosticFoldState();
}

class _DiagnosticFoldState extends State<_DiagnosticFold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(YinheRadius.controlCompact),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: YinheSpacing.s8, vertical: YinheSpacing.s4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(translate('state_diagnostic_toggle'),
                    style: TextStyle(fontSize: 11, color: widget.color)),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    size: 14, color: widget.color),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(top: YinheSpacing.s4),
            child: SelectableText(
              widget.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: widget.color,
                fontFamily: YinheFonts.mono,
                fontFamilyFallback: YinheFonts.monoFallback,
              ),
            ),
          ),
      ],
    );
  }
}
