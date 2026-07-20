import 'package:flutter/material.dart';

import '../../common.dart';

/// A reusable empty / error state widget: a light brand illustration,
/// a primary message, an optional secondary message and an optional
/// action button.
///
/// Visual tokens (see docs/design/tokens.json in Doshine/yinhe):
/// - textSecondary: light #646A73 / dark #9AA4B2 (primary message, 15pt)
/// - textTertiary:  light #9AA0A6 / dark #6B7280 (secondary message, 13pt)
/// - accent ring:   MyTheme.accent (#2F80FF) at low opacity
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  // Small diagnostic text shown below the action (e.g. raw error message).
  final String? detail;
  // Accent color of the illustration, defaults to the brand accent.
  final Color accentColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.detail,
    this.accentColor = MyTheme.accent,
  }) : super(key: key);

  factory EmptyState.noPeers({Key? key, VoidCallback? onConnect}) => EmptyState(
        key: key,
        icon: Icons.history_rounded,
        title: translate('empty_recent_title'),
        subtitle: translate('empty_recent_subtitle'),
        actionText: translate('empty_go_connect'),
        onAction: onConnect,
      );

  factory EmptyState.noFavorites({Key? key}) => EmptyState(
        key: key,
        icon: Icons.star_outline_rounded,
        title: translate('empty_favorite_title'),
        subtitle: translate('empty_favorite_subtitle'),
      );

  factory EmptyState.noDiscovered({Key? key}) => EmptyState(
        key: key,
        icon: Icons.radar_rounded,
        title: translate('empty_lan_title'),
        subtitle: translate('empty_lan_subtitle'),
      );

  factory EmptyState.noAddressBook({Key? key, VoidCallback? onLogin}) =>
      EmptyState(
        key: key,
        icon: Icons.menu_book_outlined,
        title: translate('empty_ab_login_title'),
        subtitle: translate('empty_ab_login_subtitle'),
        actionText: translate('empty_go_login'),
        onAction: onLogin,
      );

  factory EmptyState.noSearchResult({Key? key}) => EmptyState(
        key: key,
        icon: Icons.search_off_rounded,
        title: translate('empty_search_title'),
        subtitle: translate('empty_search_subtitle'),
      );

  factory EmptyState.loadFailed({
    Key? key,
    VoidCallback? onRetry,
    String? detail,
  }) =>
      EmptyState(
        key: key,
        icon: Icons.cloud_off_outlined,
        title: translate('empty_load_failed_tip'),
        actionText: translate('Retry'),
        onAction: onRetry,
        detail: detail,
        accentColor: MyTheme.danger,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? const Color(0xFF9AA4B2) : const Color(0xFF646A73);
    final subtitleColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9AA0A6);
    final bool compact = !(isDesktop || isWebDesktop);
    final double illoSize = compact ? 96.0 : 112.0;

    final illustration = Container(
      width: illoSize,
      height: illoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withOpacity(0.06),
        border: Border.all(color: accentColor.withOpacity(0.16), width: 1.5),
      ),
      child: Center(
        child: Icon(
          icon,
          size: illoSize * 0.42,
          color: accentColor.withOpacity(0.85),
        ),
      ),
    );

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            illustration,
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: titleColor),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MyTheme.accent,
                  side: const BorderSide(color: MyTheme.accent, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  minimumSize: Size.zero,
                ),
                child: Text(actionText!, style: const TextStyle(fontSize: 14)),
              ),
            ],
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SelectableText(
                  detail!,
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
