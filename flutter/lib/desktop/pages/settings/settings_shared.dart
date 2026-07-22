// 由 desktop_setting_page.dart 拆分而来（P3-3 设置中心重构）。
// 纯移动代码 + 标识符公开化（_Card→SettingsCard 等），逻辑未变。
// 共享常量与组件：组容器 / 折叠组 / 复选 / 单选 / 按钮 / 解锁条 / Wayland 卡 / 倒数按钮。
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/dialog.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';

/// 设置中心共享常量（规范 v2.1 §2.1-C）
const double kSettingsCardFixedWidth = 540;
const double kSettingsCardLeftMargin = 15;
const double kSettingsContentHMargin = 15;
const double kSettingsContentHSubMargin = kSettingsContentHMargin + 33;
const double kSettingsCheckBoxLeftMargin = 10;
const double kSettingsRadioLeftMargin = 10;
const double kSettingsListViewBottomMargin = 15;
const double kSettingsTitleFontSize = 20;
const double kSettingsContentFontSize = 15;
const Color kSettingsAccentColor = MyTheme.accent;
/// 高级设置展开/折叠时长（规范 §1.5 Motion Collapse 0.42s）
const Duration kSettingsCardCollapseDuration = Duration(milliseconds: 420);

//#region components

// ignore: non_constant_identifier_names
/// 设置组容器（规范 v2.1 §2.1-C 去卡片化）：
/// 组标题 18/26 + 留白 + 细分隔线组织设置项（项高 ≥52），组间距 24px，
/// 不把每项放进独立卡片。danger=true 渲染危险区（3px 危险色左边条 +
/// 危险色标题），危险操作单独成组并置底。
Widget SettingsCard(
    {required String title,
    required List<Widget> children,
    List<Widget>? title_suffix,
    bool collapsible = false,
    bool initiallyExpanded = true,
    bool danger = false}) {
  if (collapsible) {
    return SettingsCollapsibleCard(
      title: title,
      titleSuffix: title_suffix,
      initiallyExpanded: initiallyExpanded,
      danger: danger,
      children: children,
    );
  }
  return Builder(
    builder: (context) => Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: danger
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: YinheColors.dangerLight, width: 3),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8, left: danger ? 9 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      translate(title),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18,
                        height: 26 / 18,
                        fontWeight: FontWeight.w600,
                        color: danger ? YinheColors.dangerLight : null,
                      ),
                    ),
                  ),
                  ...?title_suffix
                ],
              ),
            ),
          ..._settingsChildrenWithDividers(context, children, danger: danger),
        ],
      ),
    ),
  );
}

/// 设置项布局：≥52px 行高 + 细分隔线（规范 §2.1-C）。
/// 跳过 Offstage 隐藏项，避免出现多余分隔线。
List<Widget> _settingsChildrenWithDividers(
    BuildContext context, List<Widget> children,
    {bool danger = false}) {
  final visible = children
      .where((w) => !(w is Offstage && w.offstage))
      .toList(growable: false);
  final dividerColor = MyTheme.color(context).divider;
  final result = <Widget>[];
  for (var i = 0; i < visible.length; i++) {
    if (i > 0) {
      result.add(Divider(height: 1, thickness: 1, color: dividerColor));
    }
    result.add(Container(
      constraints: const BoxConstraints(minHeight: 52),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: danger ? 9 : 0),
      child: visible[i],
    ));
  }
  return result;
}

// Same look as [SettingsCard] above, but the whole title row toggles the content
// between expanded and collapsed (title row only) states.
// 高级设置默认折叠（initiallyExpanded: false），展开动效 0.42s（规范 §1.5）。
class SettingsCollapsibleCard extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? titleSuffix;
  final bool initiallyExpanded;
  final bool danger;

  const SettingsCollapsibleCard({
    Key? key,
    required this.title,
    required this.children,
    this.titleSuffix,
    this.initiallyExpanded = true,
    this.danger = false,
  }) : super(key: key);

  @override
  State<SettingsCollapsibleCard> createState() => SettingsCollapsibleCardState();
}

class SettingsCollapsibleCardState extends State<SettingsCollapsibleCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: widget.danger
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: YinheColors.dangerLight, width: 3),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: 8, left: widget.danger ? 9 : 0),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                      translate(widget.title),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 18,
                        height: 26 / 18,
                        fontWeight: FontWeight.w600,
                        color:
                            widget.danger ? YinheColors.dangerLight : null,
                      ),
                    )),
                    ...?widget.titleSuffix,
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: kSettingsCardCollapseDuration,
                      curve: YinheMotion.standard,
                      child: const Icon(Icons.expand_more, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _settingsChildrenWithDividers(context, widget.children,
                  danger: widget.danger),
            ),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: kSettingsCardCollapseDuration,
            firstCurve: YinheMotion.standard,
            secondCurve: YinheMotion.standard,
            sizeCurve: YinheMotion.standard,
          ),
        ],
      ),
    );
  }
}

// ignore: non_constant_identifier_names
Widget SettingsOptionCheckBox(
  BuildContext context,
  String label,
  String key, {
  Function(bool)? update,
  bool reverse = false,
  bool enabled = true,
  Icon? checkedIcon,
  bool? fakeValue,
  bool isServer = true,
  bool Function()? optGetter,
  Future<void> Function(String, bool)? optSetter,
}) {
  getOpt() => optGetter != null
      ? optGetter()
      : (isServer
          ? mainGetBoolOptionSync(key)
          : mainGetLocalBoolOptionSync(key));
  bool value = getOpt();
  final isOptFixed = isOptionFixed(key);
  if (reverse) value = !value;
  var ref = value.obs;
  onChanged(option) async {
    if (option != null) {
      if (reverse) option = !option;
      final setter =
          optSetter ?? (isServer ? mainSetBoolOption : mainSetLocalBoolOption);
      await setter(key, option);
      // 修改即时生效：2s 轻量 toast（规范 §2.1-C）
      showToast(translate('Saved'), timeout: const Duration(seconds: 2));
      final readOption = getOpt();
      if (reverse) {
        ref.value = !readOption;
      } else {
        ref.value = readOption;
      }
      update?.call(readOption);
    }
  }

  if (fakeValue != null) {
    ref.value = fakeValue;
    enabled = false;
  }

  return GestureDetector(
    child: Obx(
      () => Row(
        children: [
          Checkbox(
                  value: ref.value,
                  onChanged: enabled && !isOptFixed ? onChanged : null)
              .marginOnly(right: 5),
          Offstage(
            offstage: !ref.value || checkedIcon == null,
            child: checkedIcon?.marginOnly(right: 5),
          ),
          Expanded(
              child: Text(
            translate(label),
            style: TextStyle(color: disabledTextColor(context, enabled)),
          ))
        ],
      ),
    ).marginOnly(left: kSettingsCheckBoxLeftMargin),
    onTap: enabled && !isOptFixed
        ? () {
            onChanged(!ref.value);
          }
        : null,
  );
}

// ignore: non_constant_identifier_names
Widget SettingsRadio<T>(BuildContext context,
    {required T value,
    required T groupValue,
    required String label,
    required Function(T value)? onChanged,
    bool autoNewLine = true}) {
  final onChange2 = onChanged != null
      ? (T? value) {
          if (value != null) {
            onChanged(value);
          }
        }
      : null;
  return GestureDetector(
    child: Row(
      children: [
        Radio<T>(value: value, groupValue: groupValue, onChanged: onChange2),
        Expanded(
          child: Text(translate(label),
                  overflow: autoNewLine ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: kSettingsContentFontSize,
                      color: disabledTextColor(context, onChange2 != null)))
              .marginOnly(left: 5),
        ),
      ],
    ).marginOnly(left: kSettingsRadioLeftMargin),
    onTap: () => onChange2?.call(value),
  );
}

class WaylandCard extends StatefulWidget {
  const WaylandCard({Key? key}) : super(key: key);

  @override
  State<WaylandCard> createState() => _WaylandCardState();
}

class _WaylandCardState extends State<WaylandCard> {
  final restoreTokenKey = 'wayland-restore-token';
  static const _kClearShortcutsInhibitorEventKey =
      'clear-gnome-shortcuts-inhibitor-permission-res';
  final _clearShortcutsInhibitorFailedMsg = ''.obs;
  // Don't show the shortcuts permission reset button for now.
  // Users can change it manually:
  //   "Settings" -> "Apps" -> "RustDesk" -> "Permissions" -> "Inhibit Shortcuts".
  // For resetting(clearing) the permission from the portal permission store, you can
  // use (replace <desktop-id> with the RustDesk desktop file ID):
  //   busctl --user call org.freedesktop.impl.portal.PermissionStore \
  //   /org/freedesktop/impl/portal/PermissionStore org.freedesktop.impl.portal.PermissionStore \
  //   DeletePermission sss "gnome" "shortcuts-inhibitor" "<desktop-id>"
  // On a native install this is typically "rustdesk.desktop"; on Flatpak it is usually
  // the exported desktop ID derived from the Flatpak app-id (e.g. "com.rustdesk.RustDesk.desktop").
  //
  // We may add it back in the future if needed.
  final showResetInhibitorPermission = false;

  @override
  void initState() {
    super.initState();
    if (showResetInhibitorPermission) {
      platformFFI.registerEventHandler(
          _kClearShortcutsInhibitorEventKey, _kClearShortcutsInhibitorEventKey,
          (evt) async {
        if (!mounted) return;
        if (evt['success'] == true) {
          setState(() {});
        } else {
          _clearShortcutsInhibitorFailedMsg.value =
              evt['msg'] as String? ?? 'Unknown error';
        }
      });
    }
  }

  @override
  void dispose() {
    if (showResetInhibitorPermission) {
      platformFFI.unregisterEventHandler(
          _kClearShortcutsInhibitorEventKey, _kClearShortcutsInhibitorEventKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return futureBuilder(
      future: bind.mainHandleWaylandScreencastRestoreToken(
          key: restoreTokenKey, value: "get"),
      hasData: (restoreToken) {
        final hasShortcutsPermission = showResetInhibitorPermission &&
            bind.mainGetCommonSync(
                    key: "has-gnome-shortcuts-inhibitor-permission") ==
                "true";

        final children = [
          if (restoreToken.isNotEmpty)
            _buildClearScreenSelection(context, restoreToken),
          if (hasShortcutsPermission)
            _buildClearShortcutsInhibitorPermission(context),
        ];
        return Offstage(
          offstage: children.isEmpty,
          // 危险区（规范 §2.1-C）：清除类操作单独成组，3px 危险色左边条
          child: SettingsCard(
              title: 'Wayland', danger: true, children: children),
        );
      },
    );
  }

  Widget _buildClearScreenSelection(BuildContext context, String restoreToken) {
    onConfirm() async {
      final msg = await bind.mainHandleWaylandScreencastRestoreToken(
          key: restoreTokenKey, value: "clear");
      gFFI.dialogManager.dismissAll();
      if (msg.isNotEmpty) {
        msgBox(gFFI.sessionId, 'custom-nocancel', 'Error', msg, '',
            gFFI.dialogManager);
      } else {
        setState(() {});
      }
    }

    showConfirmMsgBox() => msgBoxCommon(
            gFFI.dialogManager,
            'Confirmation',
            Text(
              translate('confirm_clear_Wayland_screen_selection_tip'),
            ),
            [
              dialogButton('OK', onPressed: onConfirm),
              dialogButton('Cancel',
                  onPressed: () => gFFI.dialogManager.dismissAll())
            ]);

    return SettingsButton(
      'Clear Wayland screen selection',
      showConfirmMsgBox,
      tip: 'clear_Wayland_screen_selection_tip',
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
            Theme.of(context).colorScheme.error.withOpacity(0.75)),
      ),
    );
  }

  Widget _buildClearShortcutsInhibitorPermission(BuildContext context) {
    onConfirm() {
      _clearShortcutsInhibitorFailedMsg.value = '';
      bind.mainSetCommon(
          key: "clear-gnome-shortcuts-inhibitor-permission", value: "");
      gFFI.dialogManager.dismissAll();
    }

    showConfirmMsgBox() => msgBoxCommon(
            gFFI.dialogManager,
            'Confirmation',
            Text(
              translate('confirm-clear-shortcuts-inhibitor-permission-tip'),
            ),
            [
              dialogButton('OK', onPressed: onConfirm),
              dialogButton('Cancel',
                  onPressed: () => gFFI.dialogManager.dismissAll())
            ]);

    return Column(children: [
      Obx(
        () => _clearShortcutsInhibitorFailedMsg.value.isEmpty
            ? Offstage()
            : Align(
                alignment: Alignment.topLeft,
                child: Text(_clearShortcutsInhibitorFailedMsg.value,
                        style: DefaultTextStyle.of(context)
                            .style
                            .copyWith(color: Colors.red))
                    .marginOnly(bottom: 10.0)),
      ),
      SettingsButton(
        'Reset keyboard shortcuts permission',
        showConfirmMsgBox,
        tip: 'clear-shortcuts-inhibitor-permission-tip',
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
              Theme.of(context).colorScheme.error.withOpacity(0.75)),
        ),
      ),
    ]);
  }
}

// ignore: non_constant_identifier_names
Widget SettingsButton(String label, Function() onPressed,
    {bool enabled = true, String? tip, ButtonStyle? style}) {
  var button = ElevatedButton(
    onPressed: enabled ? onPressed : null,
    child: Text(
      translate(label),
    ).marginSymmetric(horizontal: 15),
    style: style,
  );
  StatefulWidget child;
  if (tip == null) {
    child = button;
  } else {
    child = Tooltip(message: translate(tip), child: button);
  }
  return Row(children: [
    child,
  ]).marginOnly(left: kSettingsContentHMargin);
}

// ignore: non_constant_identifier_names
Widget SettingsSubButton(String label, Function() onPressed, [bool enabled = true]) {
  return Row(
    children: [
      ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Text(
          translate(label),
        ).marginSymmetric(horizontal: 15),
      ),
    ],
  ).marginOnly(left: kSettingsContentHSubMargin);
}

// ignore: non_constant_identifier_names
Widget SettingsSubLabeledWidget(BuildContext context, String label, Widget child,
    {bool enabled = true}) {
  return Row(
    children: [
      Text(
        '${translate(label)}: ',
        style: TextStyle(color: disabledTextColor(context, enabled)),
      ),
      SizedBox(
        width: 10,
      ),
      child,
    ],
  ).marginOnly(left: kSettingsContentHSubMargin);
}

Widget settingsLock(
  bool locked,
  String label,
  Function() onUnlock,
) {
  return Offstage(
      offstage: !locked,
      child: Row(
        children: [
          Flexible(
            child: SizedBox(
              width: kSettingsCardFixedWidth,
              child: Card(
                child: ElevatedButton(
                  child: SizedBox(
                      height: 25,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.security_sharp,
                              size: 20,
                            ),
                            Text(translate(label)).marginOnly(left: 5),
                          ]).marginSymmetric(vertical: 2)),
                  onPressed: () async {
                    final unlockPin = bind.mainGetUnlockPin();
                    if (unlockPin.isEmpty || isUnlockPinDisabled()) {
                      bool checked = await callMainCheckSuperUserPermission();
                      if (checked) {
                        onUnlock();
                      }
                    } else {
                      checkUnlockPinDialog(unlockPin, onUnlock);
                    }
                  },
                ).marginSymmetric(horizontal: 2, vertical: 4),
              ).marginOnly(left: kSettingsCardLeftMargin),
            ).marginOnly(top: 10),
          ),
        ],
      ));
}

settingsLabeledTextField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String errorText,
    bool enabled,
    bool secure) {
  return Table(
    columnWidths: const {
      0: FixedColumnWidth(150),
      1: FlexColumnWidth(),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              '${translate(label)}:',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                color: disabledTextColor(context, enabled),
              ),
            ),
          ),
          TextField(
            controller: controller,
            enabled: enabled,
            obscureText: secure,
            autocorrect: false,
            decoration: InputDecoration(
              errorText: errorText.isNotEmpty ? errorText : null,
            ),
            style: TextStyle(
              color: disabledTextColor(context, enabled),
            ),
          ).workaroundFreezeLinuxMint(),
        ],
      ),
    ],
  ).marginOnly(bottom: 8);
}

class SettingsCountDownButton extends StatefulWidget {
  SettingsCountDownButton({
    Key? key,
    required this.text,
    required this.second,
    required this.onPressed,
  }) : super(key: key);
  final String text;
  final VoidCallback? onPressed;
  final int second;

  @override
  State<SettingsCountDownButton> createState() => SettingsCountDownButtonState();
}

class SettingsCountDownButtonState extends State<SettingsCountDownButton> {
  bool _isButtonDisabled = false;

  late int _countdownSeconds = widget.second;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 0) {
        setState(() {
          _isButtonDisabled = false;
        });
        timer.cancel();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isButtonDisabled
          ? null
          : () {
              widget.onPressed?.call();
              setState(() {
                _isButtonDisabled = true;
                _countdownSeconds = widget.second;
              });
              _startCountdownTimer();
            },
      child: Text(
        _isButtonDisabled ? '$_countdownSeconds s' : translate(widget.text),
      ),
    );
  }
}

/// 需重启项的持续提示条（规范 §2.1-C）：常显提示 + 「立即重启」按钮。
/// 渲染后端等进程启动期生效的选项使用；即时生效项不要使用。
Widget settingsRestartHint(BuildContext context) {
  final hintColor = Theme.of(context).textTheme.bodySmall?.color;
  return Row(
    children: [
      const Icon(Icons.restart_alt, size: 16, color: MyTheme.warning),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          translate('restart_required_tip'),
          style: TextStyle(fontSize: 12, height: 18 / 12, color: hintColor),
        ),
      ),
      if (!isWeb)
        TextButton(
          onPressed: settingsConfirmAndRestart,
          child: Text(translate('Restart Now')),
        ),
    ],
  ).marginOnly(left: kSettingsContentHSubMargin);
}

/// 「立即重启」：确认后关闭子窗口并退出进程（由用户/系统守护重新拉起）。
/// Flutter 侧无原生 relaunch FFI，故采用确认后退出的方式，如实记录。
void settingsConfirmAndRestart() {
  msgBoxCommon(
      gFFI.dialogManager, translate('Restart Now'), Text(translate('restart_confirm_tip')), [
    dialogButton('Cancel',
        onPressed: () => gFFI.dialogManager.dismissAll(), isOutline: true),
    dialogButton('Restart Now', onPressed: () async {
      gFFI.dialogManager.dismissAll();
      if (!isWeb) {
        await rustDeskWinManager.closeAllSubWindows();
        exit(0);
      }
    }),
  ]);
}

/// 自含状态的复选框（拆分自原文件；当前无引用，保留备用的死代码，重命名
/// _Checkbox→SettingsCheckbox，逻辑未变）。
class SettingsCheckbox extends StatefulWidget {
  final String label;
  final bool Function() getValue;
  final Future<void> Function(bool) setValue;

  const SettingsCheckbox(
      {Key? key,
      required this.label,
      required this.getValue,
      required this.setValue})
      : super(key: key);

  @override
  State<SettingsCheckbox> createState() => _SettingsCheckboxState();
}

class _SettingsCheckboxState extends State<SettingsCheckbox> {
  var value = false;

  @override
  initState() {
    super.initState();
    value = widget.getValue();
  }

  @override
  Widget build(BuildContext context) {
    onChanged(bool b) async {
      await widget.setValue(b);
      setState(() {
        value = widget.getValue();
      });
    }

    return GestureDetector(
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (_) => onChanged(!value),
          ).marginOnly(right: 5),
          Expanded(
            child: Text(translate(widget.label)),
          )
        ],
      ).marginOnly(left: kSettingsCheckBoxLeftMargin),
      onTap: () => onChanged(!value),
    );
  }
}
