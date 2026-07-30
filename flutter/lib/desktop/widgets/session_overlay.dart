import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../common/shared_state.dart';
import '../../common/widgets/chat_page.dart';
import '../../common/widgets/quality_indicator.dart';
import '../../common/widgets/state_view.dart';
import '../../consts.dart';
import '../../models/model.dart';
import '../../models/platform_model.dart';

/// 会话画布上的功能面板（设计稿 §1.2 / §4）。
///
/// **契约：同一时刻至多一个面板。**
/// 实现方式是一个状态机而不是若干个 bool —— 每个功能各持一个 `showXxx: bool`
/// 正是当前浮窗互相叠层的成因，靠自律不叠是靠不住的。这里把「哪个 tab 开着」
/// 收敛成 [SessionOverlayController.active] 一个可空枚举：null 即关闭，
/// 打开新 tab 直接替换旧 tab，不做嵌套也不做堆栈。
enum OverlayTab { monitors, quality, permissions, files, chat, diagnostics }

extension OverlayTabMeta on OverlayTab {
  IconData get icon {
    switch (this) {
      case OverlayTab.monitors:
        return Icons.desktop_windows_outlined;
      case OverlayTab.quality:
        return Icons.tune_rounded;
      case OverlayTab.permissions:
        return Icons.verified_user_outlined;
      case OverlayTab.files:
        return Icons.folder_outlined;
      case OverlayTab.chat:
        return Icons.forum_outlined;
      case OverlayTab.diagnostics:
        return Icons.monitor_heart_outlined;
    }
  }

  String get label {
    switch (this) {
      case OverlayTab.monitors:
        return translate('overlay_tab_monitors');
      case OverlayTab.quality:
        return translate('overlay_tab_quality');
      case OverlayTab.permissions:
        return translate('overlay_tab_permissions');
      case OverlayTab.files:
        return translate('overlay_tab_files');
      case OverlayTab.chat:
        return translate('overlay_tab_chat');
      case OverlayTab.diagnostics:
        return translate('overlay_tab_diagnostics');
    }
  }
}

/// 面板状态机。一个会话一个实例，由 remote_page 持有并传给工具栏。
class SessionOverlayController {
  final Rxn<OverlayTab> _active = Rxn<OverlayTab>();

  OverlayTab? get active => _active.value;
  bool get isOpen => _active.value != null;

  /// 打开指定 tab。已经开着别的 tab 时**直接替换**，不堆叠。
  void open(OverlayTab tab) => _active.value = tab;

  /// 工具栏按钮的行为：点同一个 tab 再关掉（§1.2）。
  void toggle(OverlayTab tab) =>
      _active.value = _active.value == tab ? null : tab;

  void close() => _active.value = null;

  void dispose() => _active.close();
}

const double kSessionOverlayWidth = 360;

/// 右侧滑入面板 + 遮罩。z 序按 tokens.zIndex：遮罩 600、面板 700。
class SessionOverlay extends StatelessWidget {
  final String id;
  final FFI ffi;
  final SessionOverlayController controller;

  const SessionOverlay({
    Key? key,
    required this.id,
    required this.ffi,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.active;
      final open = tab != null;
      return Stack(
        children: [
          // 遮罩：点击关闭。不做全屏变暗，会话画面要一直看得见。
          IgnorePointer(
            ignoring: !open,
            child: AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: YinheMotion.normal,
              curve: YinheMotion.standard,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.close,
                child: Container(color: Colors.black.withOpacity(0.28)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: kSessionOverlayWidth,
            child: AnimatedSlide(
              offset: open ? Offset.zero : const Offset(1, 0),
              duration: YinheMotion.normal,
              curve: YinheMotion.standard,
              child: open
                  ? _OverlayPanel(
                      id: id, ffi: ffi, controller: controller, tab: tab)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      );
    });
  }
}

class _OverlayPanel extends StatelessWidget {
  final String id;
  final FFI ffi;
  final SessionOverlayController controller;
  final OverlayTab tab;

  const _OverlayPanel({
    required this.id,
    required this.ffi,
    required this.controller,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    // 面板压在会话画面上，恒为深色底，不跟随主题（同 HUD 与工具栏）。
    //
    // Esc 只绑在面板自己的焦点域里：会话本身要把 Esc 透传给远端，
    // 全局拦一个 Esc 会把远端的退出键吃掉。面板打开时焦点在面板上，
    // 这时 Esc 属于面板；面板一关焦点回到画面，Esc 又是远端的。
    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): controller.close,
        },
        child: Material(
          color: YinheColors.surfaceDark,
          child: Column(
            children: [
              _header(context),
              const Divider(height: 1, color: YinheColors.dividerDark),
              Expanded(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => SizedBox(
        height: 48,
        child: Row(
          children: [
            const SizedBox(width: YinheSpacing.s16),
            Icon(tab.icon, size: 18, color: YinheColors.textSecondaryDark),
            const SizedBox(width: YinheSpacing.s8),
            Expanded(
              child: Text(
                tab.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: YinheColors.textPrimaryDark,
                ),
              ),
            ),
            IconButton(
              tooltip: translate('Close'),
              iconSize: 18,
              splashRadius: 16,
              onPressed: controller.close,
              icon: const Icon(Icons.close,
                  color: YinheColors.textSecondaryDark),
            ),
            const SizedBox(width: YinheSpacing.s4),
          ],
        ),
      );

  Widget _body(BuildContext context) {
    switch (tab) {
      case OverlayTab.monitors:
        return _MonitorsTab(id: id, ffi: ffi);
      case OverlayTab.quality:
        return _QualityTab(id: id, ffi: ffi);
      case OverlayTab.permissions:
        return _PermissionsTab(id: id, ffi: ffi);
      case OverlayTab.files:
        return _FilesTab(id: id, ffi: ffi, controller: controller);
      case OverlayTab.chat:
        return _ChatTab(id: id, ffi: ffi);
      case OverlayTab.diagnostics:
        return _DiagnosticsTab(id: id, ffi: ffi);
    }
  }
}

// ---------------------------------------------------------------- 通用零件

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            YinheSpacing.s16, YinheSpacing.s16, YinheSpacing.s16, YinheSpacing.s8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.32, // 11px * .12em
            color: YinheColors.textTertiaryDark,
          ),
        ),
      );
}

/// 情景预设卡：只说结果，不暴露编解码器参数（§4.4）。
class _PresetCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? note;

  const _PresetCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.note,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(YinheRadius.card),
        child: Container(
          padding: const EdgeInsets.all(YinheSpacing.s12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(YinheRadius.card),
            border: Border.all(
              color: selected ? MyTheme.accent : YinheColors.borderDark,
              width: selected ? 1.5 : 1,
            ),
            color: selected
                ? MyTheme.accent.withOpacity(0.10)
                : Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: YinheColors.textPrimaryDark)),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        size: 16, color: MyTheme.accent),
                ],
              ),
              const SizedBox(height: YinheSpacing.s4),
              Text(description,
                  style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: YinheColors.textTertiaryDark)),
              if (note != null) ...[
                const SizedBox(height: YinheSpacing.s4),
                Text(note!,
                    style: const TextStyle(
                        fontSize: 11, color: YinheColors.warningTextDark)),
              ],
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------- 显示器

class _MonitorsTab extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _MonitorsTab({required this.id, required this.ffi});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pi = ffi.ffiModel.pi;
      if (pi.isSet.isFalse) {
        return const StateView(
          kind: StateKind.loading,
          title: '',
          compact: true,
        );
      }
      final displays = pi.displays;
      if (displays.isEmpty) {
        return StateView(
          kind: StateKind.empty,
          compact: true,
          title: translate('overlay_monitors_empty_title'),
          detail: translate('overlay_monitors_empty_detail'),
          action: StateAction(
            label: translate('Refresh'),
            onPressed: () => bind.sessionRefresh(
                sessionId: ffi.sessionId, display: pi.currentDisplay),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.only(bottom: YinheSpacing.s16),
        children: [
          _SectionLabel(translate('overlay_tab_monitors')),
          ...List.generate(displays.length, (i) {
            final d = displays[i];
            final current = pi.currentDisplay == i;
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                  YinheSpacing.s16, 0, YinheSpacing.s16, YinheSpacing.s8),
              child: _PresetCard(
                title: '${translate('Display')} ${i + 1}'
                    '${i == pi.primaryDisplay ? ' · ${translate('Default')}' : ''}',
                description: '${d.width} × ${d.height}',
                selected: current,
                onTap: () {
                  if (!current) {
                    bind.sessionSwitchDisplay(
                        isDesktop: isDesktop,
                        sessionId: ffi.sessionId,
                        value: Int32List.fromList([i]));
                  }
                },
              ),
            );
          }),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------- 画质

/// 情景预设 → 实际参数（§4.4 的对照表）。
///
/// 用户看到的是「文字清晰优先」，落到底下才是画质档 / 4:4:4 / 自适应码率。
/// 这一层映射刻意留在 UI 侧：换了编码策略只改这里，不用改文案。
enum QualityPreset { office, media, design, weakNetwork }

extension _QualityPresetMeta on QualityPreset {
  String get key {
    switch (this) {
      case QualityPreset.office:
        return 'office';
      case QualityPreset.media:
        return 'media';
      case QualityPreset.design:
        return 'design';
      case QualityPreset.weakNetwork:
        return 'weak';
    }
  }

  String get title => translate('quality_preset_${key}_title');
  String get description => translate('quality_preset_${key}_desc');
}

class _QualityTab extends StatefulWidget {
  final String id;
  final FFI ffi;
  const _QualityTab({required this.id, required this.ffi});

  @override
  State<_QualityTab> createState() => _QualityTabState();
}

class _QualityTabState extends State<_QualityTab> {
  QualityPreset? _preset;
  bool _loading = true;
  bool _i444Supported = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessionId = widget.ffi.sessionId;
      final quality = await bind.sessionGetImageQuality(sessionId: sessionId);
      final i444 = await bind.sessionGetToggleOption(
          sessionId: sessionId, arg: kOptionI444);
      final codecs =
          await bind.sessionAlternativeCodecs(sessionId: sessionId);
      // 4:4:4 只有 VP9/AV1 支持；硬件不支持时预设要如实降级提示，不能假装选上了
      final Map codecsJson = jsonDecode(codecs);
      final supported =
          (codecsJson['vp9'] ?? true) == true || (codecsJson['av1'] ?? false) == true;
      if (!mounted) return;
      setState(() {
        _i444Supported = supported;
        _preset = _presetOf(quality, i444 == true);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  QualityPreset? _presetOf(String? quality, bool i444) {
    if (i444 && quality == kRemoteImageQualityBest) return QualityPreset.design;
    switch (quality) {
      case kRemoteImageQualityBest:
        return QualityPreset.office;
      case kRemoteImageQualityLow:
        return QualityPreset.media;
      case kRemoteImageQualityCustom:
        return QualityPreset.weakNetwork;
    }
    return null;
  }

  Future<void> _apply(QualityPreset preset) async {
    final sessionId = widget.ffi.sessionId;
    setState(() => _preset = preset);
    switch (preset) {
      case QualityPreset.office:
        // 文字清晰优先：高画质档 + 关 4:4:4（文字场景色度采样收益低）
        await bind.sessionSetImageQuality(
            sessionId: sessionId, value: kRemoteImageQualityBest);
        await _setI444(false);
        break;
      case QualityPreset.media:
        // 流畅优先：低画质档换帧率
        await bind.sessionSetImageQuality(
            sessionId: sessionId, value: kRemoteImageQualityLow);
        await _setI444(false);
        break;
      case QualityPreset.design:
        await bind.sessionSetImageQuality(
            sessionId: sessionId, value: kRemoteImageQualityBest);
        await _setI444(_i444Supported);
        break;
      case QualityPreset.weakNetwork:
        // 保证不断线：自定义低码率（30% 基准）+ 关 4:4:4
        await bind.sessionSetImageQuality(
            sessionId: sessionId, value: kRemoteImageQualityCustom);
        await bind.sessionSetCustomImageQuality(
            sessionId: sessionId, value: 30);
        await _setI444(false);
        break;
    }
  }

  Future<void> _setI444(bool on) async {
    final sessionId = widget.ffi.sessionId;
    final cur = await bind.sessionGetToggleOption(
        sessionId: sessionId, arg: kOptionI444);
    if ((cur == true) != on) {
      await bind.sessionToggleOption(sessionId: sessionId, value: kOptionI444);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return StateView(
        kind: StateKind.loading,
        compact: true,
        title: translate('overlay_quality_loading'),
        loadingHint: translate('overlay_quality_loading_hint'),
      );
    }
    if (_error != null) {
      return StateView(
        kind: StateKind.error,
        compact: true,
        title: translate('overlay_quality_error_title'),
        detail: translate('overlay_quality_error_detail'),
        diagnostic: _error,
        action: StateAction(
          label: translate('Retry'),
          onPressed: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _load();
          },
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: YinheSpacing.s16),
      children: [
        _SectionLabel(translate('overlay_quality_presets')),
        ...QualityPreset.values.map((p) => Padding(
              padding: const EdgeInsets.fromLTRB(
                  YinheSpacing.s16, 0, YinheSpacing.s16, YinheSpacing.s8),
              child: _PresetCard(
                title: p.title,
                description: p.description,
                selected: _preset == p,
                note: p == QualityPreset.design && !_i444Supported
                    ? translate('quality_preset_design_downgrade')
                    : null,
                onTap: () => _apply(p),
              ),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: YinheSpacing.s16),
          child: Text(
            translate('overlay_quality_footnote'),
            style: const TextStyle(
                fontSize: 11, height: 1.5, color: YinheColors.textTertiaryDark),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 权限

class _PermissionsTab extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _PermissionsTab({required this.id, required this.ffi});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ffi.ffiModel.pi.isSet.isFalse) {
        return StateView(
          kind: StateKind.loading,
          compact: true,
          title: translate('overlay_permissions_loading'),
        );
      }
      final perms = ffi.ffiModel.permissions;
      // 对端授予的能力是只读的：本端关不掉别人给的权限，也开不出没给的权限。
      // 所以这里全部是「对端给了没有」的如实呈现 + 一个可点的下一步。
      final rows = <Widget>[
        _permRow('keyboard', translate('overlay_perm_keyboard'), perms),
        _permRow('clipboard', translate('overlay_perm_clipboard'), perms),
        _permRow('audio', translate('overlay_perm_audio'), perms),
        _permRow('file', translate('overlay_perm_file'), perms),
        _permRow('restart', translate('overlay_perm_restart'), perms),
        _permRow('recording', translate('overlay_perm_recording'), perms),
      ];
      final denied = rows.length -
          ['keyboard', 'clipboard', 'audio', 'file', 'restart', 'recording']
              .where((k) => perms[k] != false)
              .length;
      return ListView(
        padding: const EdgeInsets.only(bottom: YinheSpacing.s16),
        children: [
          _SectionLabel(translate('overlay_permissions_granted_by_peer')),
          ...rows,
          if (denied > 0)
            Padding(
              padding: const EdgeInsets.all(YinheSpacing.s16),
              child: Text(
                translate('overlay_permissions_denied_hint'),
                style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: YinheColors.textTertiaryDark),
              ),
            ),
        ],
      );
    });
  }

  Widget _permRow(String key, String title, Map<String, bool> perms) {
    final granted = perms[key] != false;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: YinheSpacing.s16, vertical: YinheSpacing.s8),
      child: Row(
        children: [
          Icon(granted ? Icons.check_circle_outline : Icons.block,
              size: 16,
              color: granted
                  ? YinheColors.successDark
                  : YinheColors.textDisabledDark),
          const SizedBox(width: YinheSpacing.s8),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    color: granted
                        ? YinheColors.textPrimaryDark
                        : YinheColors.textDisabledDark)),
          ),
          Text(
            granted
                ? translate('overlay_perm_granted')
                : translate('overlay_perm_denied'),
            style: TextStyle(
                fontSize: 11,
                color: granted
                    ? YinheColors.successDark
                    : YinheColors.textDisabledDark),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 文件

class _FilesTab extends StatelessWidget {
  final String id;
  final FFI ffi;
  final SessionOverlayController controller;
  const _FilesTab(
      {required this.id, required this.ffi, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ready = ffi.ffiModel.pi.isSet.isTrue;
      if (!ready) {
        return StateView(
          kind: StateKind.loading,
          compact: true,
          title: translate('overlay_files_loading'),
        );
      }
      if (ffi.ffiModel.permissions['file'] == false) {
        return StateView(
          kind: StateKind.denied,
          compact: true,
          title: translate('overlay_files_denied_title'),
          detail: translate('overlay_files_denied_detail'),
          action: StateAction(
            // 打开新 tab 直接替换当前 tab（§1.2），不会叠出第二个面板
            label: translate('overlay_action_open_permissions'),
            onPressed: () => controller.open(OverlayTab.permissions),
          ),
        );
      }
      return StateView(
        kind: StateKind.empty,
        compact: true,
        title: translate('overlay_files_title'),
        detail: translate('overlay_files_detail'),
        action: StateAction(
          label: translate('Transfer file'),
          onPressed: () {
            final connToken = bind.sessionGetConnToken(sessionId: ffi.sessionId);
            connect(context, id, isFileTransfer: true, connToken: connToken);
          },
        ),
      );
    });
  }
}

// ---------------------------------------------------------------- 聊天

class _ChatTab extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _ChatTab({required this.id, required this.ffi});

  @override
  Widget build(BuildContext context) {
    // 复用既有 ChatPage：聊天从一个可拖动的独立浮窗改成面板里的一个 tab，
    // 这样它不会再和其它浮窗互相压着。
    return ChatPage(chatModel: ffi.chatModel);
  }
}

// ---------------------------------------------------------------- 诊断

class _DiagnosticsTab extends StatelessWidget {
  final String id;
  final FFI ffi;
  const _DiagnosticsTab({required this.id, required this.ffi});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ffi.qualityMonitorModel,
      builder: (context, _) {
        final d = ffi.qualityMonitorModel.data;
        final conn = ConnectionTypeState.find(id);
        final rtt = int.tryParse(d.delay ?? '');
        final rows = <List<String>>[
          [translate('ID'), id],
          [translate('Delay'), d.delay == null ? '—' : '${d.delay} ms'],
          ['FPS', d.fps ?? '—'],
          [translate('Speed'), d.speed ?? '—'],
          [translate('Bitrate'), d.targetBitrate ?? '—'],
          [translate('Codec'), d.codecFormat ?? '—'],
          ['Chroma', d.chroma ?? '—'],
        ];
        return ListView(
          padding: const EdgeInsets.only(bottom: YinheSpacing.s16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(YinheSpacing.s16,
                  YinheSpacing.s16, YinheSpacing.s16, YinheSpacing.s8),
              child: Obx(() {
                final raw = conn.direct.value;
                return QualityIndicator(
                  rttMs: rtt,
                  direct: raw == kInvalidValueStr
                      ? null
                      : raw == ConnectionType.strDirect,
                  isDark: true,
                  fontSize: 13,
                );
              }),
            ),
            const Divider(height: 1, color: YinheColors.dividerDark),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: YinheSpacing.s16, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(r[0],
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: YinheColors.textTertiaryDark))),
                      SelectableText(r[1],
                          style: YinheFonts.numeric(
                            fontSize: 12,
                            height: 18,
                            color: YinheColors.textPrimaryDark,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(YinheSpacing.s16),
              child: OutlinedButton.icon(
                onPressed: () {
                  final text = rows.map((r) => '${r[0]}: ${r[1]}').join('\n');
                  Clipboard.setData(ClipboardData(text: text));
                  showToast(translate('Copied'));
                },
                icon: const Icon(Icons.copy_all_outlined, size: 16),
                label: Text(translate('overlay_copy_diagnostics')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YinheColors.textSecondaryDark,
                  side: const BorderSide(color: YinheColors.borderDark),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(YinheRadius.control)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
