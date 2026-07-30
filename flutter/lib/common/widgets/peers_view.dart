import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/ab_model.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:window_manager/window_manager.dart';

import '../../common.dart';
import '../../models/peer_model.dart';
import '../../models/platform_model.dart';
import 'peer_card.dart';
import 'state_view.dart';

typedef PeerFilter = bool Function(Peer peer);
typedef PeerCardBuilder = Widget Function(Peer peer);

class PeerSortType {
  static const String remoteId = 'Remote ID';
  static const String remoteHost = 'Remote Host';
  static const String username = 'Username';
  static const String status = 'Status';

  static List<String> values = [
    PeerSortType.remoteId,
    PeerSortType.remoteHost,
    PeerSortType.username,
    PeerSortType.status
  ];
}

class LoadEvent {
  static const String recent = 'load_recent_peers';
  static const String favorite = 'load_fav_peers';
  static const String lan = 'load_lan_peers';
  static const String addressBook = 'load_address_book_peers';
  static const String group = 'load_group_peers';
}

class PeersModelName {
  static const String recent = 'recent peer';
  static const String favorite = 'fav peer';
  static const String lan = 'discovered peer';
  static const String addressBook = 'address book peer';
  static const String group = 'group peer';
}

/// for peer search text, global obs value
final peerSearchText = "".obs;

/// for peer sort, global obs value
RxString? _peerSort;
RxString get peerSort {
  _peerSort ??= bind.getLocalFlutterOption(k: kOptionPeerSorting).obs;
  return _peerSort!;
}

// list for listener
RxList<RxString> get obslist => [peerSearchText, peerSort].obs;

final peerSearchTextController =
    TextEditingController(text: peerSearchText.value);

class _PeersView extends StatefulWidget {
  final Peers peers;
  final PeerFilter? peerFilter;
  final PeerCardBuilder peerCardBuilder;
  final PeerTabIndex peerTabIndex;

  const _PeersView(
      {required this.peers,
      required this.peerCardBuilder,
      required this.peerTabIndex,
      this.peerFilter,
      Key? key})
      : super(key: key);

  @override
  _PeersViewState createState() => _PeersViewState();
}

/// State for the peer widget.
class _PeersViewState extends State<_PeersView>
    with WindowListener, WidgetsBindingObserver {
  static const int _maxQueryCount = 3;
  final HashMap<String, String> _emptyMessages = HashMap.from({
    LoadEvent.recent: 'empty_recent_tip',
    LoadEvent.favorite: 'empty_favorite_tip',
    LoadEvent.lan: 'empty_lan_tip',
    LoadEvent.addressBook: 'empty_address_book_tip',
  });
  final space = (isDesktop || isWebDesktop) ? 12.0 : 8.0;
  final _curPeers = <String>{};
  var _lastChangeTime = DateTime.now();
  var _lastQueryPeers = <String>{};
  var _lastQueryTime = DateTime.now();
  var _lastWindowRestoreTime = DateTime.now();
  var _queryCount = 0;
  var _exit = false;
  bool _isActive = true;

  final _scrollController = ScrollController();

  _PeersViewState() {
    _startCheckOnlines();
  }

  @override
  void initState() {
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    _exit = true;
    super.dispose();
  }

  @override
  void onWindowFocus() {
    _queryCount = 0;
    _isActive = true;
  }

  @override
  void onWindowBlur() {
    // We need this comparison because window restore (on Windows) also triggers `onWindowBlur()`.
    // Maybe it's a bug of the window manager, but the source code seems to be correct.
    //
    // Although `onWindowRestore()` is called after `onWindowBlur()` in my test,
    // we need the following comparison to ensure that `_isActive` is true in the end.
    if (isWindows &&
        DateTime.now().difference(_lastWindowRestoreTime) <
            const Duration(milliseconds: 300)) {
      return;
    }
    _queryCount = _maxQueryCount;
    _isActive = false;
  }

  @override
  void onWindowRestore() {
    // Window restore (on MacOS and Linux) also triggers `onWindowFocus()`.
    // But on Windows, it triggers `onWindowBlur()`, mybe it's a bug of the window manager.
    if (!isWindows) return;
    _queryCount = 0;
    _isActive = true;
    _lastWindowRestoreTime = DateTime.now();
  }

  @override
  void onWindowMinimize() {
    // Window minimize also triggers `onWindowBlur()`.
  }

  // This function is required for mobile.
  // `onWindowFocus` works fine for desktop.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (isDesktop || isWebDesktop) return;
    if (state == AppLifecycleState.resumed) {
      _isActive = true;
      _queryCount = 0;
    } else if (state == AppLifecycleState.inactive) {
      _isActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We should avoid too many rebuilds. MacOS(m1, 14.6.1) on Flutter 3.19.6.
    // Continious rebuilds of `ChangeNotifierProvider` will cause memory leak.
    // Simple demo can reproduce this issue.
    return ChangeNotifierProvider<Peers>.value(
      value: widget.peers,
      child: Consumer<Peers>(builder: (context, peers, child) {
        if (peers.peers.isEmpty) {
          gFFI.peerTabModel.setCurrentTabCachedPeers([]);
          return _buildEmptyState();
        } else {
          return _buildPeersView(peers);
        }
      }),
    );
  }

  /// 一台设备都没有时的空状态（设计稿 §1.3 / §2.4）。
  ///
  /// 每个分页的下一步都不一样，但都必须有下一步——「空空如也」配一句
  /// 「暂无数据」是最没用的界面。最近会话给的是「复制我的 ID」（让别人连过来）
  /// 加「去连接」（自己连出去），这两件事覆盖了新用户此刻真正想干的全部。
  Widget _buildEmptyState() {
    switch (widget.peers.loadEvent) {
      case LoadEvent.recent:
        return StateView(
          kind: StateKind.empty,
          title: translate('empty_recent_title'),
          detail: translate('empty_recent_subtitle'),
          action: StateAction(
            label: translate('peers_empty_copy_my_id'),
            onPressed: _copyMyId,
            secondaryLabel: translate('empty_go_connect'),
            onSecondaryPressed: _focusConnectInput,
          ),
        );
      case LoadEvent.favorite:
        return StateView(
          kind: StateKind.empty,
          title: translate('empty_favorite_title'),
          detail: translate('empty_favorite_subtitle'),
          action: StateAction(
            label: translate('empty_go_connect'),
            onPressed: _focusConnectInput,
          ),
        );
      case LoadEvent.lan:
        return StateView(
          kind: StateKind.empty,
          title: translate('empty_lan_title'),
          detail: translate('empty_lan_subtitle'),
          action: StateAction(
            label: translate('peers_empty_copy_my_id'),
            onPressed: _copyMyId,
          ),
        );
      default:
        // 地址簿等：沿用既有译文，按 '\n' 拆成标题/说明。
        final msg =
            translate(_emptyMessages[widget.peers.loadEvent] ?? 'Empty');
        final parts = msg.split('\n');
        return StateView(
          kind: StateKind.empty,
          title: parts.first,
          detail: parts.length > 1 ? parts.sublist(1).join('\n') : null,
          action: StateAction(
            label: translate('peers_empty_copy_my_id'),
            onPressed: _copyMyId,
          ),
        );
    }
  }

  Future<void> _copyMyId() async {
    final id = await bind.mainGetMyId();
    await Clipboard.setData(ClipboardData(text: id));
    showToast(translate('Copied'));
  }

  // Focus the ID input on the connection page. The focus node is registered
  // by the connection pages (mobile and desktop) via `Get.put`.
  void _focusConnectInput() {
    if (Get.isRegistered<FocusNode>()) {
      Get.find<FocusNode>().requestFocus();
    }
  }

  onVisibilityChanged(VisibilityInfo info) {
    final peerId = _peerId((info.key as ValueKey).value);
    if (info.visibleFraction > 0.00001) {
      _curPeers.add(peerId);
    } else {
      _curPeers.remove(peerId);
    }
    _lastChangeTime = DateTime.now();
  }

  String _cardId(String id) => widget.peers.name + id;
  String _peerId(String cardId) => cardId.replaceAll(widget.peers.name, '');

  Widget _buildPeersView(Peers peers) {
    final updateEvent = peers.event;
    final peers2 = peers.peers;
    final body = ObxValue<RxList>((filters) {
      return FutureBuilder<List<Peer>>(
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var peers = snapshot.data!;
            // 这里原本有一句 `if (peers.length > 1000) peers = sublist(0, 1000)`：
            // 静默丢掉第 1001 台之后的设备，界面上没有任何痕迹，用户只会以为
            // 设备不见了。列表本身是虚拟化的（ListView/GridView.builder），
            // 渲染一万台并不需要截断；真正需要设上限的是下面那次批量在线查询。
            if (peers.isEmpty) {
              gFFI.peerTabModel.setCurrentTabCachedPeers([]);
              return peers2.isEmpty
                  ? _buildEmptyState()
                  : _buildNoMatchState();
            }
            gFFI.peerTabModel.setCurrentTabCachedPeers(peers);
            buildOnePeer(Peer peer, bool isPortrait) {
              final visibilityChild = VisibilityDetector(
                key: ValueKey(_cardId(peer.id)),
                onVisibilityChanged: onVisibilityChanged,
                child: widget.peerCardBuilder(peer),
              );
              // `Provider.of<PeerTabModel>(context)` will causes infinete loop.
              // Because `gFFI.peerTabModel.setCurrentTabCachedPeers(peers)` will trigger `notifyListeners()`.
              //
              // No need to listen the currentTab change event.
              // Because the currentTab change event will trigger the peers change event,
              // and the peers change event will trigger _buildPeersView().
              return !isPortrait
                  ? Obx(() => peerCardUiType.value == PeerUiType.list
                      ? Container(height: 45, child: visibilityChild)
                      : peerCardUiType.value == PeerUiType.grid
                          // 网格模式下宽高由 grid delegate 决定，这里不再写死
                          ? visibilityChild
                          : SizedBox(
                              width: 220, height: 42, child: visibilityChild))
                  // 设计稿 §6.1：移动端设备行高 ≥ 56。现在的内容凑出来大约 66，
                  // 但那是内容碰巧撑起来的——改一次内边距或字号就可能掉到 56 以下，
                  // 所以把下限写死而不是依赖内容。
                  : ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: visibilityChild);
            }

            // We should avoid too many rebuilds. Win10(Some machines) on Flutter 3.19.6.
            // Continious rebuilds of `ListView.builder` will cause memory leak.
            // Simple demo can reproduce this issue.
            final Widget child = Obx(() => stateGlobal.isPortrait.isTrue
                ? ListView.builder(
                    itemCount: peers.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildOnePeer(peers[index], true).marginOnly(
                          top: index == 0 ? 0 : space / 2, bottom: space / 2);
                    },
                  )
                : peerCardUiType.value == PeerUiType.list
                    ? ListView.builder(
                        controller: _scrollController,
                        itemCount: peers.length,
                        itemBuilder: (BuildContext context, int index) {
                          return buildOnePeer(peers[index], false).marginOnly(
                              right: space,
                              top: index == 0 ? 0 : space / 2,
                              bottom: space / 2);
                        },
                      )
                    : LayoutBuilder(builder: (context, constraints) {
                        // 设计稿 §2.3：repeat(auto-fill, minmax(158px, 1fr))，间距 12。
                        // Flutter 没有等价 delegate，按同样的算法自己算列数：
                        // 先看这个宽度能塞下几列 158，再把余量平摊给每一列。
                        final columns = _autoFillColumns(constraints.maxWidth);
                        // 设计稿 §2.1：在线在前、离线在后，各自带计数标题。
                        // 分组不是排序问题——「现在能连的有几台」是打开这个窗口
                        // 最先要回答的问题，混在一起就得自己一张张数。
                        final online =
                            peers.where((p) => p.online).toList(growable: false);
                        final offline = peers
                            .where((p) => !p.online)
                            .toList(growable: false);
                        // 用 CustomScrollView 而不是两个 GridView：两个各自滚动的
                        // 网格没法共用一条滚动条，而且都得脱离虚拟化。
                        return CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            ..._peerGroup(context, translate('Online'), online,
                                columns, buildOnePeer),
                            ..._peerGroup(context, translate('Offline'),
                                offline, columns, buildOnePeer),
                          ],
                        );
                      }));

            if (updateEvent == UpdateEvent.load) {
              _curPeers.clear();
              // 首屏批量查询在线状态时截断到上限：稳态查询本来就只查可见的卡片
              // （onVisibilityChanged 维护 _curPeers），一次塞一万个 id 才是问题。
              _curPeers.addAll(
                  peers.take(_kMaxInitialOnlineQuery).map((e) => e.id));
              _queryOnlines(true);
            }
            return child;
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
        future: matchPeers(filters[0].value, filters[1].value, peers2),
      );
    }, obslist);

    return body;
  }

  /// 首屏一次性查询在线状态的上限。超过的设备会在滚动到可见时按可见集补查。
  static const int _kMaxInitialOnlineQuery = 1000;

  /// 设备卡最小宽与间距（设计稿 §2.3）
  static const double _kCardMinWidth = 158;
  static const double _kCardGap = YinheSpacing.s12;

  /// 缩略图区 84 + 信息区（设计稿 §2.3）
  static const double _kCardHeight = 84 + 46;

  /// 一个分组（标题 + 网格）。空分组不出标题——「离线 0」是句废话。
  static List<Widget> _peerGroup(BuildContext context, String label,
      List<Peer> group, int columns, Widget Function(Peer, bool) buildOnePeer) {
    if (group.isEmpty) return const [];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(
              top: YinheSpacing.s16, bottom: YinheSpacing.s8),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  height: 16 / 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 11 * 0.12,
                  color: dark
                      ? YinheColors.textTertiaryDark
                      : YinheColors.textTertiaryLight,
                ),
              ),
              const SizedBox(width: YinheSpacing.s8),
              Text(
                '${group.length}',
                style: YinheFonts.numeric(
                  fontSize: 11,
                  height: 16,
                  fontWeight: FontWeight.w600,
                  color: dark
                      ? YinheColors.textSecondaryDark
                      : YinheColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: _kCardGap,
          crossAxisSpacing: _kCardGap,
          mainAxisExtent: _kCardHeight,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => buildOnePeer(group[index], false),
          childCount: group.length,
        ),
      ),
    ];
  }

  /// 等价于 CSS repeat(auto-fill, minmax(158px, 1fr))
  static int _autoFillColumns(double maxWidth) {
    if (!maxWidth.isFinite || maxWidth <= 0) return 1;
    final n = ((maxWidth + _kCardGap) / (_kCardMinWidth + _kCardGap)).floor();
    return n < 1 ? 1 : n;
  }

  /// 有设备但被搜索/标签筛没了——和「一台都没有」是两回事，下一步是清筛选。
  Widget _buildNoMatchState() => StateView(
        kind: StateKind.empty,
        title: translate('empty_search_title'),
        detail: translate('empty_search_subtitle'),
        action: StateAction(
          label: translate('peers_empty_clear_filter'),
          onPressed: () {
            peerSearchTextController.clear();
            peerSearchText.value = '';
          },
        ),
      );

  var _queryInterval = const Duration(seconds: 20);

  void _startCheckOnlines() {
    () async {
      final p = await bind.mainIsUsingPublicServer();
      if (!p) {
        _queryInterval = const Duration(seconds: 6);
      }
      while (!_exit) {
        final now = DateTime.now();
        if (!setEquals(_curPeers, _lastQueryPeers)) {
          if (now.difference(_lastChangeTime) > const Duration(seconds: 1)) {
            _queryOnlines(false);
          }
        } else {
          final skipIfIsWeb =
              isWeb && !(stateGlobal.isWebVisible && stateGlobal.isInMainPage);
          final skipIfMobile =
              (isAndroid || isIOS) && !stateGlobal.isInMainPage;
          final skipIfNotActive = skipIfIsWeb || skipIfMobile || !_isActive;
          if (!skipIfNotActive && (_queryCount < _maxQueryCount || !p)) {
            if (now.difference(_lastQueryTime) >= _queryInterval) {
              if (_curPeers.isNotEmpty) {
                bind.queryOnlines(ids: _curPeers.toList(growable: false));
                _lastQueryTime = DateTime.now();
                _queryCount += 1;
              }
            }
          }
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }();
  }

  _queryOnlines(bool isLoadEvent) {
    if (_curPeers.isNotEmpty) {
      bind.queryOnlines(ids: _curPeers.toList(growable: false));
      _queryCount = 0;
    }
    _lastQueryPeers = {..._curPeers};
    if (isLoadEvent) {
      _lastChangeTime = DateTime.now();
    } else {
      _lastQueryTime = DateTime.now().subtract(_queryInterval);
    }
  }

  Future<List<Peer>>? matchPeers(
      String searchText, String sortedBy, List<Peer> peers) async {
    if (widget.peerFilter != null) {
      peers = peers.where((peer) => widget.peerFilter!(peer)).toList();
    }

    // fallback to id sorting
    if (!PeerSortType.values.contains(sortedBy)) {
      sortedBy = PeerSortType.remoteId;
      bind.setLocalFlutterOption(
        k: kOptionPeerSorting,
        v: sortedBy,
      );
    }

    if (widget.peers.loadEvent != LoadEvent.recent) {
      switch (sortedBy) {
        case PeerSortType.remoteId:
          peers.sort((p1, p2) => p1.getId().compareTo(p2.getId()));
          break;
        case PeerSortType.remoteHost:
          peers.sort((p1, p2) =>
              p1.hostname.toLowerCase().compareTo(p2.hostname.toLowerCase()));
          break;
        case PeerSortType.username:
          peers.sort((p1, p2) =>
              p1.username.toLowerCase().compareTo(p2.username.toLowerCase()));
          break;
        case PeerSortType.status:
          peers.sort((p1, p2) => p1.online ? -1 : 1);
          break;
      }
    }

    searchText = searchText.trim();
    if (searchText.isEmpty) {
      return peers;
    }
    searchText = searchText.toLowerCase();
    final matches = await Future.wait(
        peers.map((peer) => matchPeer(searchText, peer, widget.peerTabIndex)));
    final filteredList = List<Peer>.empty(growable: true);
    for (var i = 0; i < peers.length; i++) {
      if (matches[i]) {
        filteredList.add(peers[i]);
      }
    }

    return filteredList;
  }
}

abstract class BasePeersView extends StatelessWidget {
  final PeerTabIndex peerTabIndex;
  final PeerFilter? peerFilter;
  final PeerCardBuilder peerCardBuilder;

  const BasePeersView({
    Key? key,
    required this.peerTabIndex,
    this.peerFilter,
    required this.peerCardBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Peers peers;
    switch (peerTabIndex) {
      case PeerTabIndex.recent:
        peers = gFFI.recentPeersModel;
        break;
      case PeerTabIndex.fav:
        peers = gFFI.favoritePeersModel;
        break;
      case PeerTabIndex.lan:
        peers = gFFI.lanPeersModel;
        break;
      case PeerTabIndex.ab:
        peers = gFFI.abModel.peersModel;
        break;
      case PeerTabIndex.group:
        peers = gFFI.groupModel.peersModel;
        break;
    }
    return _PeersView(
        peers: peers,
        peerFilter: peerFilter,
        peerCardBuilder: peerCardBuilder,
        peerTabIndex: peerTabIndex);
  }
}

class RecentPeersView extends BasePeersView {
  RecentPeersView(
      {Key? key, EdgeInsets? menuPadding, ScrollController? scrollController})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.recent,
          peerCardBuilder: (Peer peer) => RecentPeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    bind.mainLoadRecentPeers();
    return widget;
  }
}

class FavoritePeersView extends BasePeersView {
  FavoritePeersView(
      {Key? key, EdgeInsets? menuPadding, ScrollController? scrollController})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.fav,
          peerCardBuilder: (Peer peer) => FavoritePeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    bind.mainLoadFavPeers();
    return widget;
  }
}

class DiscoveredPeersView extends BasePeersView {
  DiscoveredPeersView(
      {Key? key, EdgeInsets? menuPadding, ScrollController? scrollController})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.lan,
          peerCardBuilder: (Peer peer) => DiscoveredPeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    bind.mainLoadLanPeers();
    bind.mainDiscover();
    return widget;
  }
}

class AddressBookPeersView extends BasePeersView {
  AddressBookPeersView(
      {Key? key, EdgeInsets? menuPadding, ScrollController? scrollController})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.ab,
          peerFilter: (Peer peer) =>
              _hitTag(gFFI.abModel.selectedTags, peer.tags),
          peerCardBuilder: (Peer peer) => AddressBookPeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  static bool _hitTag(List<dynamic> selectedTags, List<dynamic> idents) {
    if (selectedTags.isEmpty) {
      return true;
    }
    // The result of a no-tag union with normal tags, still allows normal tags to perform union or intersection operations.
    final selectedNormalTags =
        selectedTags.where((tag) => tag != kUntagged).toList();
    if (selectedTags.contains(kUntagged)) {
      if (idents.isEmpty) return true;
      if (selectedNormalTags.isEmpty) return false;
    }
    if (gFFI.abModel.filterByIntersection.value) {
      for (final tag in selectedNormalTags) {
        if (!idents.contains(tag)) {
          return false;
        }
      }
      return true;
    } else {
      for (final tag in selectedNormalTags) {
        if (idents.contains(tag)) {
          return true;
        }
      }
      return false;
    }
  }
}

class MyGroupPeerView extends BasePeersView {
  MyGroupPeerView(
      {Key? key, EdgeInsets? menuPadding, ScrollController? scrollController})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.group,
          peerFilter: filter,
          peerCardBuilder: (Peer peer) => MyGroupPeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  static bool filter(Peer peer) {
    final model = gFFI.groupModel;
    if (model.searchAccessibleItemNameText.isNotEmpty) {
      final text = model.searchAccessibleItemNameText.value.toLowerCase();
      final searchPeersOfUser = model.users.any((user) =>
          user.name == peer.loginName &&
          (user.name.toLowerCase().contains(text) ||
              user.displayNameOrName.toLowerCase().contains(text)));
      final searchPeersOfDeviceGroup =
          peer.device_group_name.toLowerCase().contains(text) &&
              model.deviceGroups.any((g) => g.name == peer.device_group_name);
      if (!searchPeersOfUser && !searchPeersOfDeviceGroup) {
        return false;
      }
    }
    if (model.selectedAccessibleItemName.isNotEmpty) {
      if (model.isSelectedDeviceGroup.value) {
        if (model.selectedAccessibleItemName.value != peer.device_group_name) {
          return false;
        }
      } else {
        if (model.selectedAccessibleItemName.value != peer.loginName) {
          return false;
        }
      }
    }
    return true;
  }
}
