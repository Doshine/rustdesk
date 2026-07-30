import 'package:flutter/material.dart';

import '../../common.dart';
import '../../common/formatter/id_formatter.dart';
import '../../models/platform_model.dart';

/// 首次启动完成标记。置位后向导不再出现（设计稿 §6.3）。
const String kOptionFirstRunDone = 'yinhe-first-run-done';

/// 首次启动向导（设计稿 §6.3）。
///
/// 三步，每步一句话：权限预检 → 设备命名与归属 → 第一次安全连接。
/// 完成后不再出现。
///
/// 为什么要有它：新装的客户端打开就是一个 ID 和一堆 tab，用户不知道
/// 「我该先干什么」。这三步覆盖的正是他此刻真正要做的三件事——
/// 把该给的权限给了、让别人认得出这台机器、知道怎么发起第一次连接。
///
/// 刻意不做的事：不在这里索取权限。§6.1 要求「连接前做权限与网络预检，
/// 不在会话中途索权」，而向导阶段连要不要当被控端都还没定，
/// 这里只做**告知与自检**，真正的授权入口留在「设备」页。
class FirstRunWizard extends StatefulWidget {
  /// 关闭向导（完成或跳过）。
  final VoidCallback onDone;

  /// 跳到「设备」页去授权。
  final VoidCallback? onOpenServerPage;

  const FirstRunWizard({Key? key, required this.onDone, this.onOpenServerPage})
      : super(key: key);

  /// 是否还需要展示。已完成过就返回 false。
  static bool get pending =>
      bind.mainGetLocalOption(key: kOptionFirstRunDone) != 'Y';

  static Future<void> markDone() async =>
      await bind.mainSetLocalOption(key: kOptionFirstRunDone, value: 'Y');

  @override
  State<FirstRunWizard> createState() => _FirstRunWizardState();
}

class _FirstRunWizardState extends State<FirstRunWizard> {
  int _step = 0;
  final _nameController = TextEditingController();

  static const _kSteps = 3;

  @override
  void initState() {
    super.initState();
    _nameController.text = bind.mainGetLocalOption(key: 'custom-rendezvous-name');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _title =>
      _isDark ? YinheColors.textPrimaryDark : YinheColors.textPrimaryLight;

  Color get _detail =>
      _isDark ? YinheColors.textTertiaryDark : YinheColors.textTertiaryLight;

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await bind.mainSetLocalOption(key: 'custom-rendezvous-name', value: name);
    }
    await FirstRunWizard.markDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(YinheSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _progress(),
              const SizedBox(height: YinheSpacing.s32),
              Expanded(child: SingleChildScrollView(child: _stepBody())),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  /// 进度条：三段，走到哪段亮到哪段。不用「第 2/3 步」的文字——
  /// 一眼看得出还剩多少比读一行字快。
  Widget _progress() => Row(
        children: List.generate(_kSteps, (i) {
          final done = i <= _step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i == _kSteps - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: done
                    ? MyTheme.accent
                    : (_isDark
                        ? YinheColors.borderDark
                        : YinheColors.borderLight),
                borderRadius: BorderRadius.circular(YinheRadius.full),
              ),
            ),
          );
        }),
      );

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _stepShell(
          icon: Icons.verified_user_outlined,
          title: translate('wizard_step1_title'),
          detail: translate('wizard_step1_detail'),
          extra: _permissionHint(),
        );
      case 1:
        return _stepShell(
          icon: Icons.badge_outlined,
          title: translate('wizard_step2_title'),
          detail: translate('wizard_step2_detail'),
          extra: TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: translate('wizard_step2_placeholder'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(YinheRadius.control),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: YinheSpacing.s12, vertical: YinheSpacing.s12),
            ),
          ),
        );
      default:
        return _stepShell(
          icon: Icons.wifi_tethering,
          title: translate('wizard_step3_title'),
          detail: translate('wizard_step3_detail'),
          extra: _idCard(),
        );
    }
  }

  Widget _stepShell({
    required IconData icon,
    required String title,
    required String detail,
    Widget? extra,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MyTheme.accent.withOpacity(0.08),
              border:
                  Border.all(color: MyTheme.accent.withOpacity(0.16), width: 1.5),
            ),
            child: Icon(icon, size: 26, color: MyTheme.accent),
          ),
          const SizedBox(height: YinheSpacing.s20),
          Text(title,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: _title)),
          const SizedBox(height: YinheSpacing.s8),
          // 每步一句话（§6.3）——多写一段没人看，少写一句用户不知道为什么要做
          Text(detail,
              style: TextStyle(fontSize: 14, height: 1.6, color: _detail)),
          if (extra != null) ...[
            const SizedBox(height: YinheSpacing.s24),
            extra,
          ],
        ],
      );

  /// 权限这一步只做告知，不在这里弹系统授权框（见类注释）。
  Widget _permissionHint() => Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: widget.onOpenServerPage,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(translate('wizard_step1_action')),
          style: OutlinedButton.styleFrom(
            foregroundColor: MyTheme.accent,
            side: BorderSide(color: MyTheme.accent.withOpacity(0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(YinheRadius.control)),
            padding: const EdgeInsets.symmetric(
                horizontal: YinheSpacing.s16, vertical: YinheSpacing.s12),
          ),
        ),
      );

  Widget _idCard() {
    // mainGetMyId 是异步的（native 侧走 FFI、web 侧走 bridge），不能当同步值用。
    // flutter analyze 抓不到这类错误：generated_bridge 缺失时 bind 是 unresolved，
    // 经过 bind. 的调用全都躲过了类型检查——这个是 flutter build web 抓出来的。
    return FutureBuilder<String>(
      future: bind.mainGetMyId(),
      builder: (context, snapshot) => _idCardBody(snapshot.data ?? ''),
    );
  }

  Widget _idCardBody(String id) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: YinheSpacing.s20, vertical: YinheSpacing.s16),
      decoration: BoxDecoration(
        gradient: YinheColors.galaxyGradient,
        borderRadius: BorderRadius.circular(YinheRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate('ID').toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 11 * 0.12,
              // 渐变底不随主题变，文字色也不能变（spec §7.4-2）
              color: const Color(0xFFEAF4FF).withOpacity(0.72),
            ),
          ),
          const SizedBox(height: YinheSpacing.s4),
          Text(
            formatID(id),
            style: TextStyle(
              fontFamily: YinheFonts.idDisplay,
              fontFamilyFallback: YinheFonts.idDisplayFallback,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: 26 * 0.07,
              color: const Color(0xFFEAF4FF),
              fontFeatures: const [FontFeature('tnum')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() => Row(
        children: [
          // 跳过要一直在：强制走完三步的向导只会让人乱点
          TextButton(
            onPressed: () async {
              await FirstRunWizard.markDone();
              widget.onDone();
            },
            child: Text(translate('wizard_skip'),
                style: TextStyle(color: _detail)),
          ),
          const Spacer(),
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() => _step -= 1),
              child: Text(translate('wizard_back')),
            ),
          const SizedBox(width: YinheSpacing.s8),
          ElevatedButton(
            onPressed: () {
              if (_step < _kSteps - 1) {
                setState(() => _step += 1);
              } else {
                _finish();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent,
              foregroundColor: YinheColors.textInverseLight,
              elevation: 0,
              // 触控目标 ≥ 48（§6.1）
              minimumSize: const Size(96, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(YinheRadius.control)),
            ),
            child: Text(_step < _kSteps - 1
                ? translate('wizard_next')
                : translate('wizard_done')),
          ),
        ],
      );
}
