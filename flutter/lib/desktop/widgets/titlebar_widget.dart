import 'package:flutter/material.dart';

import '../../theme/yinhe_tokens.dart';

/// 桌面标题栏 · 蓝鲸银河 v2.1
///
/// 废弃旧 RustDesk 亮蓝渐变（#0C6AF6 / #0583EA / #0697EA），
/// 改为与侧栏一致的深空/浅色单色 surface + 1px 底部分隔线（规范 §2.1.A、WS1-2）。
class DesktopTitleBar extends StatelessWidget {
  final Widget? child;

  const DesktopTitleBar({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: isDark ? YinheColors.dividerDark : YinheColors.dividerLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: child ?? Offstage(),
          )
        ],
      ),
    );
  }
}
