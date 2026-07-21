import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../theme/yinhe_tokens.dart';
import 'motion.dart';

/// 蓝鲸银河移动设置页原生行组件（P3-4，替代 settings_ui）。
///
/// 规范 v2.1 §2.2.D：
/// - 原生滚动列表，每个设置行最小高 52px；
/// - 开关右对齐；帮助说明在标题下方、最多两行；
/// - 触控区 ≥44px（行高 52 天然满足，行内小按钮单独补足）；
/// - 分组 = 单一圆角容器 + 内部行分隔；
/// - 色值全部引用 yinhe_tokens，动效引用 YinheMotion 并按 reduced-motion 降级。

/// 设置页明暗双主题取色（全部来自 YinheColors token）。
class YinheSettingsStyle {
  YinheSettingsStyle._();

  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// 分组容器底
  static Color groupBg(BuildContext c) =>
      _dark(c) ? YinheColors.surfaceDark : YinheColors.surfaceLight;

  static Color title(BuildContext c) =>
      _dark(c) ? YinheColors.textPrimaryDark : YinheColors.textPrimaryLight;

  static Color subtitle(BuildContext c) =>
      _dark(c) ? YinheColors.textSecondaryDark : YinheColors.textSecondaryLight;

  static Color caption(BuildContext c) =>
      _dark(c) ? YinheColors.textTertiaryDark : YinheColors.textTertiaryLight;

  static Color divider(BuildContext c) =>
      _dark(c) ? YinheColors.dividerDark : YinheColors.dividerLight;

  static Color chevron(BuildContext c) =>
      _dark(c) ? YinheColors.textDisabledDark : YinheColors.textDisabledLight;

  /// 行内文字样式
  static TextStyle titleStyle(BuildContext c) => TextStyle(
        fontSize: YinheFonts.sizeBodyM,
        height: 22 / YinheFonts.sizeBodyM,
        color: title(c),
      );

  static TextStyle subtitleStyle(BuildContext c) => TextStyle(
        fontSize: YinheFonts.sizeLabel,
        height: 18 / YinheFonts.sizeLabel,
        color: subtitle(c),
      );
}

/// 设置分组：标题 + 单一圆角容器 + 内部行分隔。
/// children 为空时不渲染（保持条件项的可见性与原实现一致）。
class YinheSettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const YinheSettingsGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    final divided = <Widget>[
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          Divider(
              height: 1,
              thickness: 1,
              indent: YinheSpacing.s16,
              color: YinheSettingsStyle.divider(context)),
        children[i],
      ],
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: YinheSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: YinheSpacing.s4, bottom: YinheSpacing.s8),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: YinheFonts.sizeLabel,
                  fontWeight: YinheFonts.weightSemibold,
                  color: YinheSettingsStyle.caption(context),
                ),
              ),
            ),
          Material(
            color: YinheSettingsStyle.groupBg(context),
            borderRadius: BorderRadius.circular(YinheRadius.card),
            clipBehavior: Clip.antiAlias,
            child: Column(children: divided),
          ),
        ],
      ),
    );
  }
}

/// 基础设置行：最小高 52px，帮助说明在标题下方最多两行。
class YinheSettingsRow extends StatelessWidget {
  final Widget? leading;

  /// 标题文字（与 titleWidget 二选一）。
  final String? title;

  /// 自定义标题（如 Obx 动态文案）。
  final Widget? titleWidget;

  /// 帮助说明（标题下方，最大两行）。
  final String? subtitle;
  final Widget? subtitleWidget;

  /// 标题行内尾随小部件（如警告图标）。
  final Widget? titleTrailing;
  final Widget? trailing;
  final VoidCallback? onTap;

  const YinheSettingsRow({
    super.key,
    this.leading,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.titleTrailing,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtitleWidget ??
        (subtitle != null
            ? Text(subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: YinheSettingsStyle.subtitleStyle(context))
            : null);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(minHeight: 52), // 规范：每行最小高 52px
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: YinheSpacing.s16, vertical: YinheSpacing.s8),
          child: Row(
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(right: YinheSpacing.s12),
                  child: IconTheme(
                    data: IconThemeData(
                        color: YinheSettingsStyle.subtitle(context), size: 22),
                    child: leading!,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: titleWidget ??
                              Text(title ?? '',
                                  style: YinheSettingsStyle.titleStyle(context)),
                        ),
                        if (titleTrailing != null) titleTrailing!,
                      ],
                    ),
                    if (sub != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: YinheSpacing.s2),
                        child: sub,
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: YinheSpacing.s8),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 开关设置行：开关右对齐；onChanged 为 null（选项被策略固定）时禁用。
/// 点击行任意位置等效切换（原 SettingsTile.switchTile 行为），触控面 ≥52px。
class YinheSettingsSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? titleTrailing;

  /// 显示在开关左侧的行内操作（如编辑按钮）。
  final Widget? action;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const YinheSettingsSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.action,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return YinheSettingsRow(
      title: title,
      subtitle: subtitle,
      titleTrailing: titleTrailing,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (action != null) action!,
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// 跳转设置行（右侧 chevron）。
class YinheSettingsNavRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;

  const YinheSettingsNavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return YinheSettingsRow(
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14, color: YinheSettingsStyle.chevron(context)),
    );
  }
}

/// 值展示设置行（版本 / 编译日期 / 指纹 / 目录等诊断信息）。
class YinheSettingsValueRow extends StatelessWidget {
  final String title;
  final String value;
  final Widget? leading;
  final VoidCallback? onTap;

  /// 值是否使用等宽数字脸（指纹等关键数字）。
  final bool numericValue;

  const YinheSettingsValueRow({
    super.key,
    required this.title,
    required this.value,
    this.leading,
    this.onTap,
    this.numericValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return YinheSettingsRow(
      leading: leading,
      title: title,
      onTap: onTap,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: numericValue
              ? YinheFonts.numeric(
                  fontSize: YinheFonts.sizeLabel,
                  height: 18,
                  color: YinheSettingsStyle.subtitle(context),
                  fontWeight: YinheFonts.weightRegular,
                )
              : YinheSettingsStyle.subtitleStyle(context),
        ),
      ),
    );
  }
}

/// 单选弹窗行的一个选项。
class YinheRadioOption {
  final String label;
  final String value;
  const YinheRadioOption(this.label, this.value);
}

/// 弹窗单选设置行：右侧显示当前值，点击弹出单选对话框。
/// 行为与原 _getPopupDialogRadioEntry 逐项等价（含 tail / showTail /
/// notCloseValue：选中该项时不关闭对话框并展开附加设置）。
class YinheSettingsRadioRow extends StatelessWidget {
  final String title;
  final List<YinheRadioOption> options;
  final String Function() getter;
  final Future<void> Function(String value)? setter;
  final Widget? tail;
  final RxBool? showTail;
  final String? notCloseValue;

  const YinheSettingsRadioRow({
    super.key,
    required this.title,
    required this.options,
    required this.getter,
    required this.setter,
    this.tail,
    this.showTail,
    this.notCloseValue,
  });

  @override
  Widget build(BuildContext context) {
    final groupValue = ''.obs;
    final valueText = ''.obs;

    init() {
      groupValue.value = getter();
      final e =
          options.firstWhereOrNull((e) => e.value == groupValue.value);
      if (e != null) {
        valueText.value = e.label;
      }
    }

    init();

    void showDialog() async {
      gFFI.dialogManager.show((setState, close, context) {
        final onChanged = setter == null
            ? null
            : (String? value) async {
                if (value == null) return;
                await setter!(value);
                init();
                if (value != notCloseValue) {
                  close();
                }
              };

        return CustomAlertDialog(
            content: Obx(
          () => Column(children: [
            ...options
                .map((e) => getRadio(Text(translate(e.label)), e.value,
                    groupValue.value, onChanged))
                .toList(),
            AnimatedSize(
              duration:
                  yhMotionDuration(context, YinheMotion.normal),
              curve: YinheMotion.standard,
              child: Offstage(
                offstage: !(tail != null && showTail?.value == true),
                child: tail,
              ),
            ),
          ]),
        ));
      }, backDismiss: true, clickMaskDismiss: true);
    }

    return YinheSettingsRow(
      title: title,
      onTap: setter == null ? null : showDialog,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Text(
                translate(valueText.value),
                style: YinheSettingsStyle.subtitleStyle(context),
              )),
          if (setter != null)
            Padding(
              padding: const EdgeInsets.only(left: YinheSpacing.s4),
              child: Icon(Icons.arrow_forward_ios,
                  size: 14, color: YinheSettingsStyle.chevron(context)),
            ),
        ],
      ),
    );
  }
}

/// 行内编辑按钮（44px 触控区，规范 §2.2.D）。
class YinheSettingsEditButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const YinheSettingsEditButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      icon: Icon(Icons.edit,
          size: 18, color: YinheSettingsStyle.subtitle(context)),
    );
  }
}
