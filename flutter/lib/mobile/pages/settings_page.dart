import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/setting_widgets.dart';
import 'package:flutter_hbb/desktop/pages/settings/network.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../common.dart';
import '../../common/widgets/dialog.dart';
import '../../common/widgets/login.dart';
import '../../consts.dart';
import '../../models/model.dart';
import '../../models/platform_model.dart';
import '../../theme/yinhe_tokens.dart';
import '../widgets/deploy_dialog.dart';
import '../widgets/dialog.dart';
import '../widgets/settings_widgets.dart';
import 'home_page.dart';
import 'scan_page.dart';

class SettingsPage extends StatefulWidget implements PageShape {
  @override
  final title = translate("Settings");

  @override
  final icon = Icon(Icons.settings);

  @override
  final appBarActions = bind.isDisableSettings() ? [] : [ScanButton()];

  @override
  State<SettingsPage> createState() => _SettingsState();
}

const url = 'https://rustdesk.com/';

enum KeepScreenOn {
  never,
  duringControlled,
  serviceOn,
}

String _keepScreenOnToOption(KeepScreenOn value) {
  switch (value) {
    case KeepScreenOn.never:
      return 'never';
    case KeepScreenOn.duringControlled:
      return 'during-controlled';
    case KeepScreenOn.serviceOn:
      return 'service-on';
  }
}

KeepScreenOn optionToKeepScreenOn(String value) {
  switch (value) {
    case 'never':
      return KeepScreenOn.never;
    case 'service-on':
      return KeepScreenOn.serviceOn;
    default:
      return KeepScreenOn.duringControlled;
  }
}

class _SettingsState extends State<SettingsPage> with WidgetsBindingObserver {
  final _hasIgnoreBattery =
      false; //androidVersion >= 26; // remove because not work on every device
  var _ignoreBatteryOpt = false;
  var _enableStartOnBoot = false;
  var _checkUpdateOnStartup = false;
  var _showTerminalExtraKeys = false;
  var _floatingWindowDisabled = false;
  var _keepScreenOn = KeepScreenOn.duringControlled; // relay on floating window
  var _enableAbr = false;
  var _denyLANDiscovery = false;
  var _onlyWhiteList = false;
  var _enableDirectIPAccess = false;
  var _enableRecordSession = false;
  var _enableHardwareCodec = false;
  var _allowWebSocket = false;
  var _autoRecordIncomingSession = false;
  var _autoRecordOutgoingSession = false;
  var _allowAutoDisconnect = false;
  var _localIP = "";
  var _directAccessPort = "";
  var _fingerprint = "";
  var _buildDate = "";
  var _autoDisconnectTimeout = "";
  var _hideServer = false;
  var _hideProxy = false;
  var _hideNetwork = false;
  var _hideWebSocket = false;
  var _enableTrustedDevices = false;
  var _enableUdpPunch = false;
  var _allowInsecureTlsFallback = false;
  var _disableUdp = false;
  var _enableIpv6Punch = false;
  var _isUsingPublicServer = false;
  var _allowAskForNoteAtEndOfConnection = false;
  var _preventSleepWhileConnected = true;

  _SettingsState() {
    _enableAbr = option2bool(
        kOptionEnableAbr, bind.mainGetOptionSync(key: kOptionEnableAbr));
    _denyLANDiscovery = !option2bool(kOptionEnableLanDiscovery,
        bind.mainGetOptionSync(key: kOptionEnableLanDiscovery));
    _onlyWhiteList = whitelistNotEmpty();
    _enableDirectIPAccess = option2bool(
        kOptionDirectServer, bind.mainGetOptionSync(key: kOptionDirectServer));
    _enableRecordSession = option2bool(kOptionEnableRecordSession,
        bind.mainGetOptionSync(key: kOptionEnableRecordSession));
    _enableHardwareCodec = option2bool(kOptionEnableHwcodec,
        bind.mainGetOptionSync(key: kOptionEnableHwcodec));
    _allowWebSocket = mainGetBoolOptionSync(kOptionAllowWebSocket);
    _allowInsecureTlsFallback =
        mainGetBoolOptionSync(kOptionAllowInsecureTLSFallback);
    _disableUdp = bind.mainGetOptionSync(key: kOptionDisableUdp) == 'Y';
    _autoRecordIncomingSession = option2bool(kOptionAllowAutoRecordIncoming,
        bind.mainGetOptionSync(key: kOptionAllowAutoRecordIncoming));
    _autoRecordOutgoingSession = option2bool(kOptionAllowAutoRecordOutgoing,
        bind.mainGetLocalOption(key: kOptionAllowAutoRecordOutgoing));
    _localIP = bind.mainGetOptionSync(key: 'local-ip-addr');
    _directAccessPort = bind.mainGetOptionSync(key: kOptionDirectAccessPort);
    _allowAutoDisconnect = option2bool(kOptionAllowAutoDisconnect,
        bind.mainGetOptionSync(key: kOptionAllowAutoDisconnect));
    _autoDisconnectTimeout =
        bind.mainGetOptionSync(key: kOptionAutoDisconnectTimeout);
    _hideServer =
        bind.mainGetBuildinOption(key: kOptionHideServerSetting) == 'Y';
    _hideProxy = bind.mainGetBuildinOption(key: kOptionHideProxySetting) == 'Y';
    _hideNetwork =
        bind.mainGetBuildinOption(key: kOptionHideNetworkSetting) == 'Y';
    _hideWebSocket =
        bind.mainGetBuildinOption(key: kOptionHideWebSocketSetting) == 'Y' ||
            isWeb;
    _enableTrustedDevices = mainGetBoolOptionSync(kOptionEnableTrustedDevices);
    _enableUdpPunch = mainGetLocalBoolOptionSync(kOptionEnableUdpPunch);
    _enableIpv6Punch = mainGetLocalBoolOptionSync(kOptionEnableIpv6Punch);
    _allowAskForNoteAtEndOfConnection =
        mainGetLocalBoolOptionSync(kOptionAllowAskForNoteAtEndOfConnection);
    _preventSleepWhileConnected =
        mainGetLocalBoolOptionSync(kOptionKeepAwakeDuringOutgoingSessions);
    _showTerminalExtraKeys =
        mainGetLocalBoolOptionSync(kOptionEnableShowTerminalExtraKeys);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var update = false;

      if (_hasIgnoreBattery) {
        if (await checkAndUpdateIgnoreBatteryStatus()) {
          update = true;
        }
      }

      if (await checkAndUpdateStartOnBoot()) {
        update = true;
      }

      // start on boot depends on ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS and SYSTEM_ALERT_WINDOW
      var enableStartOnBoot =
          await gFFI.invokeMethod(AndroidChannel.kGetStartOnBootOpt);
      if (enableStartOnBoot) {
        if (!await canStartOnBoot()) {
          enableStartOnBoot = false;
          gFFI.invokeMethod(AndroidChannel.kSetStartOnBootOpt, false);
        }
      }

      if (enableStartOnBoot != _enableStartOnBoot) {
        update = true;
        _enableStartOnBoot = enableStartOnBoot;
      }

      var checkUpdateOnStartup =
          mainGetLocalBoolOptionSync(kOptionEnableCheckUpdate);
      if (checkUpdateOnStartup != _checkUpdateOnStartup) {
        update = true;
        _checkUpdateOnStartup = checkUpdateOnStartup;
      }

      var floatingWindowDisabled =
          bind.mainGetLocalOption(key: kOptionDisableFloatingWindow) == "Y" ||
              !await AndroidPermissionManager.check(kSystemAlertWindow);
      if (floatingWindowDisabled != _floatingWindowDisabled) {
        update = true;
        _floatingWindowDisabled = floatingWindowDisabled;
      }

      final keepScreenOn = _floatingWindowDisabled
          ? KeepScreenOn.never
          : optionToKeepScreenOn(
              bind.mainGetLocalOption(key: kOptionKeepScreenOn));
      if (keepScreenOn != _keepScreenOn) {
        update = true;
        _keepScreenOn = keepScreenOn;
      }

      final fingerprint = await bind.mainGetFingerprint();
      if (_fingerprint != fingerprint) {
        update = true;
        _fingerprint = fingerprint;
      }

      final buildDate = await bind.mainGetBuildDate();
      if (_buildDate != buildDate) {
        update = true;
        _buildDate = buildDate;
      }

      final isUsingPublicServer = await bind.mainIsUsingPublicServer();
      if (_isUsingPublicServer != isUsingPublicServer) {
        update = true;
        _isUsingPublicServer = isUsingPublicServer;
      }

      if (update) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      () async {
        final ibs = await checkAndUpdateIgnoreBatteryStatus();
        final sob = await checkAndUpdateStartOnBoot();
        if (ibs || sob) {
          setState(() {});
        }
      }();
    }
  }

  Future<bool> checkAndUpdateIgnoreBatteryStatus() async {
    final res = await AndroidPermissionManager.check(
        kRequestIgnoreBatteryOptimizations);
    if (_ignoreBatteryOpt != res) {
      _ignoreBatteryOpt = res;
      return true;
    } else {
      return false;
    }
  }

  Future<bool> checkAndUpdateStartOnBoot() async {
    if (!await canStartOnBoot() && _enableStartOnBoot) {
      _enableStartOnBoot = false;
      debugPrint(
          "checkAndUpdateStartOnBoot and set _enableStartOnBoot -> false");
      gFFI.invokeMethod(AndroidChannel.kSetStartOnBootOpt, false);
      return true;
    } else {
      return false;
    }
  }

  // ================= 蓝鲸银河 P3-4：原生设置行重写 =================
  // 规范 v2.1 §2.2.D 顺序：账号与安全置顶 → 远程控制行为 → 关于与诊断置底。
  // 所有设置项的功能逻辑（bind 调用、option key、默认值、可见性条件）
  // 与原 settings_ui 实现逐项一致，仅重排分组并替换表现层。

  @override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    final outgoingOnly = bind.isOutgoingOnly();
    final incomingOnly = bind.isIncomingOnly();
    final disabledSettings = bind.isDisableSettings();
    final hideSecuritySettings =
        bind.mainGetBuildinOption(key: kOptionHideSecuritySetting) == 'Y';
    // 原 2FA / Share screen / Enhancements 组的组级可见性条件（重排后逐项保留）
    final showControlledSections =
        isAndroid && !disabledSettings && !outgoingOnly && !hideSecuritySettings;

    final enable2fa = bind.mainHasValid2FaSync();

    onFloatingWindowChanged(bool toValue) async {
      if (toValue) {
        if (!await AndroidPermissionManager.check(kSystemAlertWindow)) {
          if (!await AndroidPermissionManager.request(kSystemAlertWindow)) {
            return;
          }
        }
      }
      final disable = !toValue;
      bind.mainSetLocalOption(
          key: kOptionDisableFloatingWindow,
          value: disable ? 'Y' : defaultOptionNo);
      setState(() => _floatingWindowDisabled = disable);
      gFFI.serverModel.androidUpdatekeepScreenOn();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: YinheSpacing.s16, vertical: YinheSpacing.s12),
      children: [
        // ---- 品牌区（原 customClientSection，顺序保持最顶）----
        if (bind.isCustomClient())
          Align(alignment: Alignment.center, child: loadPowered(context)),
        Align(alignment: Alignment.center, child: loadLogo()),

        // ---- 账号与安全（置顶）----
        if (!bind.isDisableAccount())
          YinheSettingsGroup(title: translate('Account'), children: [
            // Login / Logout（原 Account 组行，头像与文案逻辑不变）
            YinheSettingsRow(
              titleWidget: Obx(() => Text(
                  gFFI.userModel.userName.value.isEmpty
                      ? translate('Login')
                      : '${translate('Logout')} (${gFFI.userModel.accountLabelWithHandle})',
                  style: YinheSettingsStyle.titleStyle(context))),
              leading: Obx(() {
                final avatar = bind.mainResolveAvatarUrl(
                    avatar: gFFI.userModel.avatar.value);
                return buildAvatarWidget(
                      avatar: avatar,
                      size: 28,
                      borderRadius: null,
                      fallback: Icon(Icons.person),
                    ) ??
                    Icon(Icons.person);
              }),
              onTap: () {
                if (gFFI.userModel.userName.value.isEmpty) {
                  loginDialog();
                } else {
                  logOutConfirmDialog();
                }
              },
            ),
            // 会话结束备注（原「设置」组行，条件 !isDisableAccount 不变）
            YinheSettingsSwitchRow(
              title: translate('note-at-conn-end-tip'),
              value: _allowAskForNoteAtEndOfConnection,
              onChanged: (v) async {
                if (v && !gFFI.userModel.isLogin) {
                  final res = await loginDialog();
                  if (res != true) return;
                }
                await mainSetLocalBoolOption(
                    kOptionAllowAskForNoteAtEndOfConnection, v);
                final newValue = mainGetLocalBoolOptionSync(
                    kOptionAllowAskForNoteAtEndOfConnection);
                setState(() {
                  _allowAskForNoteAtEndOfConnection = newValue;
                });
              },
            ),
          ]),
        YinheSettingsGroup(title: translate('Security'), children: [
          if (showControlledSections) ...[
            // ---- 2FA（原 2FA 组）----
            YinheSettingsSwitchRow(
              title: translate('enable-2fa-title'),
              value: enable2fa,
              onChanged: (v) async {
                update() async {
                  setState(() {});
                }

                if (v == false) {
                  CommonConfirmDialog(
                      gFFI.dialogManager, translate('cancel-2fa-confirm-tip'),
                      () {
                    change2fa(callback: update);
                  });
                } else {
                  change2fa(callback: update);
                }
              },
            ),
            if (enable2fa)
              YinheSettingsSwitchRow(
                title: translate('Telegram bot'),
                value: bind.mainHasValidBotSync(),
                onChanged: (v) async {
                  update() async {
                    setState(() {});
                  }

                  if (v == false) {
                    CommonConfirmDialog(gFFI.dialogManager,
                        translate('cancel-bot-confirm-tip'), () {
                      changeBot(callback: update);
                    });
                  } else {
                    changeBot(callback: update);
                  }
                },
              ),
            if (enable2fa)
              YinheSettingsSwitchRow(
                title: translate('Enable trusted devices'),
                subtitle: '* ${translate('enable-trusted-devices-tip')}',
                value: _enableTrustedDevices,
                onChanged: isOptionFixed(kOptionEnableTrustedDevices)
                    ? null
                    : (v) async {
                        mainSetBoolOption(kOptionEnableTrustedDevices, v);
                        setState(() {
                          _enableTrustedDevices = v;
                        });
                      },
              ),
            if (enable2fa && _enableTrustedDevices)
              YinheSettingsNavRow(
                title: translate('Manage trusted devices'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return _ManageTrustedDevices();
                  }));
                },
              ),
            // ---- 被控安全（原 Share screen 组安全项）----
            YinheSettingsSwitchRow(
              title: translate('Deny LAN discovery'),
              value: _denyLANDiscovery,
              onChanged: isOptionFixed(kOptionEnableLanDiscovery)
                  ? null
                  : (v) async {
                      await bind.mainSetOption(
                          key: kOptionEnableLanDiscovery,
                          value: bool2option(kOptionEnableLanDiscovery, !v));
                      final newValue = !option2bool(
                          kOptionEnableLanDiscovery,
                          await bind.mainGetOption(
                              key: kOptionEnableLanDiscovery));
                      setState(() {
                        _denyLANDiscovery = newValue;
                      });
                    },
            ),
            YinheSettingsSwitchRow(
              title: translate('Use IP Whitelisting'),
              titleTrailing: Offstage(
                      offstage: !_onlyWhiteList,
                      child: const Icon(Icons.warning_amber_rounded,
                          color: MyTheme.warning))
                  .marginOnly(left: 5),
              value: _onlyWhiteList,
              onChanged: (_) async {
                update() async {
                  final onlyWhiteList = whitelistNotEmpty();
                  if (onlyWhiteList != _onlyWhiteList) {
                    setState(() {
                      _onlyWhiteList = onlyWhiteList;
                    });
                  }
                }

                changeWhiteList(callback: update);
              },
            ),
          ],
        ]),

        // ---- 远程控制行为 ----
        if (showControlledSections)
          YinheSettingsGroup(title: translate('Share screen'), children: [
            YinheSettingsSwitchRow(
              title: translate('Adaptive bitrate'),
              value: _enableAbr,
              onChanged: isOptionFixed(kOptionEnableAbr)
                  ? null
                  : (v) async {
                      await mainSetBoolOption(kOptionEnableAbr, v);
                      final newValue = await mainGetBoolOption(kOptionEnableAbr);
                      setState(() {
                        _enableAbr = newValue;
                      });
                    },
            ),
            YinheSettingsSwitchRow(
              title: translate('Enable recording session'),
              value: _enableRecordSession,
              onChanged: isOptionFixed(kOptionEnableRecordSession)
                  ? null
                  : (v) async {
                      await mainSetBoolOption(kOptionEnableRecordSession, v);
                      final newValue =
                          await mainGetBoolOption(kOptionEnableRecordSession);
                      setState(() {
                        _enableRecordSession = newValue;
                      });
                    },
            ),
            YinheSettingsSwitchRow(
              title: translate("Direct IP Access"),
              subtitle: _enableDirectIPAccess
                  ? '${translate("Local Address")}: $_localIP${_directAccessPort.isEmpty ? "" : ":$_directAccessPort"}'
                  : null,
              action: _enableDirectIPAccess
                  ? YinheSettingsEditButton(
                      onPressed: isOptionFixed(kOptionDirectAccessPort)
                          ? null
                          : () async {
                              final port = await changeDirectAccessPort(
                                  _localIP, _directAccessPort);
                              setState(() {
                                _directAccessPort = port;
                              });
                            })
                  : null,
              value: _enableDirectIPAccess,
              onChanged: isOptionFixed(kOptionDirectServer)
                  ? null
                  : (_) async {
                      _enableDirectIPAccess = !_enableDirectIPAccess;
                      String value =
                          bool2option(kOptionDirectServer, _enableDirectIPAccess);
                      await bind.mainSetOption(
                          key: kOptionDirectServer, value: value);
                      setState(() {});
                    },
            ),
            YinheSettingsSwitchRow(
              title: translate("auto_disconnect_option_tip"),
              subtitle: _allowAutoDisconnect
                  ? '${_autoDisconnectTimeout.isEmpty ? '10' : _autoDisconnectTimeout} min'
                  : null,
              action: _allowAutoDisconnect
                  ? YinheSettingsEditButton(
                      onPressed: isOptionFixed(kOptionAutoDisconnectTimeout)
                          ? null
                          : () async {
                              final timeout = await changeAutoDisconnectTimeout(
                                  _autoDisconnectTimeout);
                              setState(() {
                                _autoDisconnectTimeout = timeout;
                              });
                            })
                  : null,
              value: _allowAutoDisconnect,
              onChanged: isOptionFixed(kOptionAllowAutoDisconnect)
                  ? null
                  : (_) async {
                      _allowAutoDisconnect = !_allowAutoDisconnect;
                      String value = bool2option(
                          kOptionAllowAutoDisconnect, _allowAutoDisconnect);
                      await bind.mainSetOption(
                          key: kOptionAllowAutoDisconnect, value: value);
                      setState(() {});
                    },
            ),
          ]),
        if (showControlledSections)
          YinheSettingsGroup(title: translate('Enhancements'), children: [
            if (_hasIgnoreBattery)
              YinheSettingsSwitchRow(
                title: translate('Keep RustDesk background service'),
                subtitle: '* ${translate('Ignore Battery Optimizations')}',
                value: _ignoreBatteryOpt,
                onChanged: (v) async {
                  if (v) {
                    await AndroidPermissionManager.request(
                        kRequestIgnoreBatteryOptimizations);
                  } else {
                    final res = await gFFI.dialogManager.show<bool>(
                        (setState, close, context) => CustomAlertDialog(
                              title: Text(translate("Open System Setting")),
                              content: Text(translate(
                                  "android_open_battery_optimizations_tip")),
                              actions: [
                                dialogButton("Cancel",
                                    onPressed: () => close(), isOutline: true),
                                dialogButton(
                                  "Open System Setting",
                                  onPressed: () => close(true),
                                ),
                              ],
                            ));
                    if (res == true) {
                      AndroidPermissionManager.startAction(
                          kActionApplicationDetailsSettings);
                    }
                  }
                },
              ),
            YinheSettingsSwitchRow(
              title: translate('Start on boot'),
              subtitle:
                  '* ${translate('Start the screen sharing service on boot, requires special permissions')}',
              value: _enableStartOnBoot,
              onChanged: (toValue) async {
                if (toValue) {
                  // 1. request kIgnoreBatteryOptimizations
                  if (!await AndroidPermissionManager.check(
                      kRequestIgnoreBatteryOptimizations)) {
                    if (!await AndroidPermissionManager.request(
                        kRequestIgnoreBatteryOptimizations)) {
                      return;
                    }
                  }

                  // 2. request kSystemAlertWindow
                  if (!await AndroidPermissionManager.check(kSystemAlertWindow)) {
                    if (!await AndroidPermissionManager.request(
                        kSystemAlertWindow)) {
                      return;
                    }
                  }

                  // (Optional) 3. request input permission
                }
                setState(() => _enableStartOnBoot = toValue);

                gFFI.invokeMethod(AndroidChannel.kSetStartOnBootOpt, toValue);
              },
            ),
            if (!bind.isCustomClient())
              YinheSettingsSwitchRow(
                title: translate('Check for software update on startup'),
                value: _checkUpdateOnStartup,
                onChanged: (toValue) async {
                  await mainSetLocalBoolOption(kOptionEnableCheckUpdate, toValue);
                  setState(() => _checkUpdateOnStartup = toValue);
                },
              ),
            YinheSettingsSwitchRow(
              title: translate('Show terminal extra keys'),
              value: _showTerminalExtraKeys,
              onChanged: (v) async {
                await mainSetLocalBoolOption(kOptionEnableShowTerminalExtraKeys, v);
                final newValue =
                    mainGetLocalBoolOptionSync(kOptionEnableShowTerminalExtraKeys);
                setState(() {
                  _showTerminalExtraKeys = newValue;
                });
              },
            ),
            YinheSettingsSwitchRow(
              title: translate('Floating window'),
              subtitle: '* ${translate('floating_window_tip')}',
              value: !_floatingWindowDisabled,
              onChanged:
                  bind.mainIsOptionFixed(key: kOptionDisableFloatingWindow)
                      ? null
                      : onFloatingWindowChanged,
            ),
            YinheSettingsRadioRow(
              title: 'Keep screen on',
              options: [
                YinheRadioOption(
                    'Never', _keepScreenOnToOption(KeepScreenOn.never)),
                YinheRadioOption('During controlled',
                    _keepScreenOnToOption(KeepScreenOn.duringControlled)),
                YinheRadioOption('During service is on',
                    _keepScreenOnToOption(KeepScreenOn.serviceOn)),
              ],
              getter: () => _keepScreenOnToOption(_floatingWindowDisabled
                  ? KeepScreenOn.never
                  : optionToKeepScreenOn(
                      bind.mainGetLocalOption(key: kOptionKeepScreenOn))),
              setter: isOptionFixed(kOptionKeepScreenOn) ||
                      _floatingWindowDisabled
                  ? null
                  : (value) async {
                      await bind.mainSetLocalOption(
                          key: kOptionKeepScreenOn, value: value);
                      setState(() =>
                          _keepScreenOn = optionToKeepScreenOn(value));
                      gFFI.serverModel.androidUpdatekeepScreenOn();
                    },
            ),
          ]),
        if (isAndroid)
          YinheSettingsGroup(title: translate('Hardware Codec'), children: [
            YinheSettingsSwitchRow(
              title: translate('Enable hardware codec'),
              value: _enableHardwareCodec,
              onChanged: isOptionFixed(kOptionEnableHwcodec)
                  ? null
                  : (v) async {
                      await mainSetBoolOption(kOptionEnableHwcodec, v);
                      final newValue =
                          await mainGetBoolOption(kOptionEnableHwcodec);
                      setState(() {
                        _enableHardwareCodec = newValue;
                      });
                    },
            ),
          ]),
        if (isAndroid)
          YinheSettingsGroup(title: translate("Recording"), children: [
            if (!outgoingOnly)
              YinheSettingsSwitchRow(
                title: translate('Automatically record incoming sessions'),
                value: _autoRecordIncomingSession,
                onChanged: isOptionFixed(kOptionAllowAutoRecordIncoming)
                    ? null
                    : (v) async {
                        await bind.mainSetOption(
                            key: kOptionAllowAutoRecordIncoming,
                            value: bool2option(
                                kOptionAllowAutoRecordIncoming, v));
                        final newValue = option2bool(
                            kOptionAllowAutoRecordIncoming,
                            await bind.mainGetOption(
                                key: kOptionAllowAutoRecordIncoming));
                        setState(() {
                          _autoRecordIncomingSession = newValue;
                        });
                      },
              ),
            if (!incomingOnly)
              YinheSettingsSwitchRow(
                title: translate('Automatically record outgoing sessions'),
                value: _autoRecordOutgoingSession,
                onChanged: isOptionFixed(kOptionAllowAutoRecordOutgoing)
                    ? null
                    : (v) async {
                        await bind.mainSetLocalOption(
                            key: kOptionAllowAutoRecordOutgoing,
                            value: bool2option(
                                kOptionAllowAutoRecordOutgoing, v));
                        final newValue = option2bool(
                            kOptionAllowAutoRecordOutgoing,
                            bind.mainGetLocalOption(
                                key: kOptionAllowAutoRecordOutgoing));
                        setState(() {
                          _autoRecordOutgoingSession = newValue;
                        });
                      },
              ),
            YinheSettingsValueRow(
              title: translate("Directory"),
              value: bind.mainVideoSaveDirectory(root: false),
            ),
          ]),

        // ---- 网络 ----
        YinheSettingsGroup(title: translate('Network'), children: [
          if (!disabledSettings && !_hideNetwork && !_hideServer)
            YinheSettingsNavRow(
              title: translate('ID/Relay Server'),
              leading: Icon(Icons.cloud),
              onTap: () {
                showServerSettings(gFFI.dialogManager, (callback) async {
                  _isUsingPublicServer = await bind.mainIsUsingPublicServer();
                  setState(callback);
                });
              },
            ),
          if (!_hideNetwork && !_hideProxy)
            YinheSettingsNavRow(
              title: translate('Socks5/Http(s) Proxy'),
              leading: Icon(Icons.network_ping),
              onTap: () {
                changeSocks5Proxy();
              },
            ),
          if (isAndroid && !bind.isOutgoingOnly())
            YinheSettingsNavRow(
              title: translate('Deploy'),
              leading: Icon(Icons.cloud_upload),
              onTap: () {
                showDeployDialog();
              },
            ),
          if (!disabledSettings && !_hideNetwork && !_hideWebSocket)
            YinheSettingsSwitchRow(
              title: translate('Use WebSocket'),
              value: _allowWebSocket,
              onChanged: isOptionFixed(kOptionAllowWebSocket)
                  ? null
                  : (v) async {
                      await mainSetBoolOption(kOptionAllowWebSocket, v);
                      final newValue =
                          await mainGetBoolOption(kOptionAllowWebSocket);
                      setState(() {
                        _allowWebSocket = newValue;
                      });
                    },
            ),
          if (!_isUsingPublicServer)
            YinheSettingsSwitchRow(
              title: translate('Allow insecure TLS fallback'),
              value: _allowInsecureTlsFallback,
              onChanged: isOptionFixed(kOptionAllowInsecureTLSFallback)
                  ? null
                  : (v) async {
                      await mainSetBoolOption(
                          kOptionAllowInsecureTLSFallback, v);
                      final newValue = mainGetBoolOptionSync(
                          kOptionAllowInsecureTLSFallback);
                      setState(() {
                        _allowInsecureTlsFallback = newValue;
                      });
                    },
            ),
          if (isAndroid && !outgoingOnly && !_isUsingPublicServer)
            YinheSettingsSwitchRow(
              title: translate('Disable UDP'),
              value: _disableUdp,
              onChanged: isOptionFixed(kOptionDisableUdp)
                  ? null
                  : (v) async {
                      await bind.mainSetOption(
                          key: kOptionDisableUdp, value: v ? 'Y' : 'N');
                      final newValue =
                          bind.mainGetOptionSync(key: kOptionDisableUdp) == 'Y';
                      setState(() {
                        _disableUdp = newValue;
                      });
                    },
            ),
          if (!incomingOnly)
            YinheSettingsSwitchRow(
              title: translate('Enable UDP hole punching'),
              value: _enableUdpPunch,
              onChanged: (v) async {
                await mainSetLocalBoolOption(kOptionEnableUdpPunch, v);
                final newValue =
                    mainGetLocalBoolOptionSync(kOptionEnableUdpPunch);
                setState(() {
                  _enableUdpPunch = newValue;
                });
              },
            ),
          if (!incomingOnly)
            YinheSettingsSwitchRow(
              title: translate('Enable IPv6 P2P connection'),
              value: _enableIpv6Punch,
              onChanged: (v) async {
                await mainSetLocalBoolOption(kOptionEnableIpv6Punch, v);
                final newValue =
                    mainGetLocalBoolOptionSync(kOptionEnableIpv6Punch);
                setState(() {
                  _enableIpv6Punch = newValue;
                });
              },
            ),
        ]),

        // ---- 常规 ----
        YinheSettingsGroup(title: translate('General'), children: [
          YinheSettingsNavRow(
            title: translate('Language'),
            leading: Icon(Icons.translate),
            onTap: () {
              showLanguageSettings(gFFI.dialogManager);
            },
          ),
          YinheSettingsNavRow(
            title: translate(Theme.of(context).brightness == Brightness.light
                ? 'Light Theme'
                : 'Dark Theme'),
            leading: Icon(Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onTap: () {
              showThemeSettings(gFFI.dialogManager);
            },
          ),
          if (!incomingOnly)
            YinheSettingsNavRow(
              title: translate('Display Settings'),
              leading: Icon(Icons.desktop_windows_outlined),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return _DisplayPage();
                }));
              },
            ),
          if (!incomingOnly)
            YinheSettingsSwitchRow(
              title: translate('keep-awake-during-outgoing-sessions-label'),
              value: _preventSleepWhileConnected,
              onChanged: (v) async {
                await mainSetLocalBoolOption(
                    kOptionKeepAwakeDuringOutgoingSessions, v);
                setState(() {
                  _preventSleepWhileConnected = v;
                });
              },
            ),
        ]),

        // ---- 关于与诊断（置底）----
        YinheSettingsGroup(title: translate("About"), children: [
          YinheSettingsRow(
            title: translate("Version: ") + version,
            leading: Icon(Icons.info),
            onTap: () async {
              await launchUrl(Uri.parse(url));
            },
            trailing: Text('rustdesk.com',
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: YinheFonts.sizeLabel,
                    color: YinheSettingsStyle.subtitle(context))),
          ),
          YinheSettingsValueRow(
            title: translate("Build Date"),
            value: _buildDate,
            leading: Icon(Icons.query_builder),
          ),
          if (isAndroid)
            YinheSettingsValueRow(
              title: translate("Fingerprint"),
              value: _fingerprint,
              numericValue: true,
              leading: Icon(Icons.fingerprint),
              onTap: () => onCopyFingerprint(_fingerprint),
            ),
          YinheSettingsNavRow(
            title: translate("Privacy Statement"),
            leading: Icon(Icons.privacy_tip),
            onTap: () =>
                launchUrlString('https://rustdesk.com/privacy.html'),
          ),
        ]),
        const SizedBox(height: YinheSpacing.s24),
      ],
    );
  }

  Future<bool> canStartOnBoot() async {
    // start on boot depends on ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS and SYSTEM_ALERT_WINDOW
    if (_hasIgnoreBattery && !_ignoreBatteryOpt) {
      return false;
    }
    if (!await AndroidPermissionManager.check(kSystemAlertWindow)) {
      return false;
    }
    return true;
  }
}

void showLanguageSettings(OverlayDialogManager dialogManager) async {
  try {
    final langs = json.decode(await bind.mainGetLangs()) as List<dynamic>;
    var lang = bind.mainGetLocalOption(key: kCommConfKeyLang);
    dialogManager.show((setState, close, context) {
      setLang(v) async {
        if (lang != v) {
          setState(() {
            lang = v;
          });
          await bind.mainSetLocalOption(key: kCommConfKeyLang, value: v);
          HomePage.homeKey.currentState?.refreshPages();
          Future.delayed(Duration(milliseconds: 200), close);
        }
      }

      final isOptFixed = isOptionFixed(kCommConfKeyLang);
      return CustomAlertDialog(
        content: Column(
          children: [
                getRadio(Text(translate('Default')), defaultOptionLang, lang,
                    isOptFixed ? null : setLang),
                Divider(color: MyTheme.border),
              ] +
              langs.map((e) {
                final key = e[0] as String;
                final name = e[1] as String;
                return getRadio(Text(translate(name)), key, lang,
                    isOptFixed ? null : setLang);
              }).toList(),
        ),
      );
    }, backDismiss: true, clickMaskDismiss: true);
  } catch (e) {
    //
  }
}

void showThemeSettings(OverlayDialogManager dialogManager) async {
  var themeMode = MyTheme.getThemeModePreference();

  dialogManager.show((setState, close, context) {
    setTheme(v) {
      if (themeMode != v) {
        setState(() {
          themeMode = v;
        });
        MyTheme.changeDarkMode(themeMode);
        Future.delayed(Duration(milliseconds: 200), close);
      }
    }

    final isOptFixed = isOptionFixed(kCommConfKeyTheme);
    return CustomAlertDialog(
      content: Column(children: [
        getRadio(Text(translate('Light')), ThemeMode.light, themeMode,
            isOptFixed ? null : setTheme),
        getRadio(Text(translate('Dark')), ThemeMode.dark, themeMode,
            isOptFixed ? null : setTheme),
        getRadio(Text(translate('Follow System')), ThemeMode.system, themeMode,
            isOptFixed ? null : setTheme)
      ]),
    );
  }, backDismiss: true, clickMaskDismiss: true);
}

void showAbout(OverlayDialogManager dialogManager) {
  dialogManager.show((setState, close, context) {
    return CustomAlertDialog(
      title: Text(translate('About RustDesk')),
      content: Wrap(direction: Axis.vertical, spacing: 12, children: [
        Text('Version: $version'),
        InkWell(
            onTap: () async {
              const url = 'https://rustdesk.com/';
              await launchUrl(Uri.parse(url));
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('rustdesk.com',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  )),
            )),
      ]),
      actions: [],
    );
  }, clickMaskDismiss: true, backDismiss: true);
}

class ScanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.qr_code_scanner),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => ScanPage(),
          ),
        );
      },
    );
  }
}

class _DisplayPage extends StatefulWidget {
  const _DisplayPage();

  @override
  State<_DisplayPage> createState() => __DisplayPageState();
}

class __DisplayPageState extends State<_DisplayPage> {
  @override
  Widget build(BuildContext context) {
    final Map codecsJson = jsonDecode(bind.mainSupportedHwdecodings());
    final h264 = codecsJson['h264'] ?? false;
    final h265 = codecsJson['h265'] ?? false;
    var codecList = [
      YinheRadioOption('Auto', 'auto'),
      YinheRadioOption('VP8', 'vp8'),
      YinheRadioOption('VP9', 'vp9'),
      YinheRadioOption('AV1', 'av1'),
      if (h264) YinheRadioOption('H264', 'h264'),
      if (h265) YinheRadioOption('H265', 'h265')
    ];
    RxBool showCustomImageQuality = false.obs;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios)),
        title: Text(translate('Display Settings')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: YinheSpacing.s16, vertical: YinheSpacing.s12),
        children: [
          YinheSettingsGroup(children: [
            YinheSettingsRadioRow(
              title: 'Default View Style',
              options: [
                YinheRadioOption('Scale original', kRemoteViewStyleOriginal),
                YinheRadioOption('Scale adaptive', kRemoteViewStyleAdaptive)
              ],
              getter: () =>
                  bind.mainGetUserDefaultOption(key: kOptionViewStyle),
              setter: isOptionFixed(kOptionViewStyle)
                  ? null
                  : (value) async {
                      await bind.mainSetUserDefaultOption(
                          key: kOptionViewStyle, value: value);
                    },
            ),
            YinheSettingsRadioRow(
              title: 'Default Image Quality',
              options: [
                YinheRadioOption('Good image quality', kRemoteImageQualityBest),
                YinheRadioOption('Balanced', kRemoteImageQualityBalanced),
                YinheRadioOption(
                    'Optimize reaction time', kRemoteImageQualityLow),
                YinheRadioOption('Custom', kRemoteImageQualityCustom),
              ],
              getter: () {
                final v =
                    bind.mainGetUserDefaultOption(key: kOptionImageQuality);
                showCustomImageQuality.value = v == kRemoteImageQualityCustom;
                return v;
              },
              setter: isOptionFixed(kOptionImageQuality)
                  ? null
                  : (value) async {
                      await bind.mainSetUserDefaultOption(
                          key: kOptionImageQuality, value: value);
                      showCustomImageQuality.value =
                          value == kRemoteImageQualityCustom;
                    },
              tail: customImageQualitySetting(),
              showTail: showCustomImageQuality,
              notCloseValue: kRemoteImageQualityCustom,
            ),
            YinheSettingsRadioRow(
              title: 'Default Codec',
              options: codecList,
              getter: () =>
                  bind.mainGetUserDefaultOption(key: kOptionCodecPreference),
              setter: isOptionFixed(kOptionCodecPreference)
                  ? null
                  : (value) async {
                      await bind.mainSetUserDefaultOption(
                          key: kOptionCodecPreference, value: value);
                    },
            ),
          ]),
          YinheSettingsGroup(
            title: translate('Other Default Options'),
            children: otherDefaultSettings()
                .map((e) => _otherRow(e.$1, e.$2))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _otherRow(String label, String key) {
    final value = bind.mainGetUserDefaultOption(key: key) == 'Y';
    final isOptFixed = isOptionFixed(key);
    return YinheSettingsSwitchRow(
      value: value,
      title: translate(label),
      onChanged: isOptFixed
          ? null
          : (b) async {
              await bind.mainSetUserDefaultOption(
                  key: key, value: b ? 'Y' : defaultOptionNo);
              setState(() {});
            },
    );
  }
}

class _ManageTrustedDevices extends StatefulWidget {
  const _ManageTrustedDevices();

  @override
  State<_ManageTrustedDevices> createState() => __ManageTrustedDevicesState();
}

class __ManageTrustedDevicesState extends State<_ManageTrustedDevices> {
  RxList<TrustedDevice> trustedDevices = RxList.empty(growable: true);
  RxList<Uint8List> selectedDevices = RxList.empty();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Manage trusted devices')),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: selectedDevices.isEmpty
                  ? null
                  : () {
                      confrimDeleteTrustedDevicesDialog(
                          trustedDevices, selectedDevices);
                    }))
        ],
      ),
      body: FutureBuilder(
          future: TrustedDevice.get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final devices = snapshot.data as List<TrustedDevice>;
            trustedDevices = devices.obs;
            return trustedDevicesTable(trustedDevices, selectedDevices);
          }),
    );
  }
}
