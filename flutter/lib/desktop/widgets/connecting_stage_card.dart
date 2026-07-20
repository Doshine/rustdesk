import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';

/// Staged connection progress card shown while a desktop remote session is
/// being established (W5: connection flow status feedback).
///
/// Presentation only. The active stage index is observed from
/// [FfiModel.connectionStage], which is advanced exclusively by existing
/// connection events (connect start -> 0, `connection_ready` -> 3); no
/// connection logic or FFI is changed. The stage mapping is documented in
/// model.dart where [FfiModel.connectionStage] is updated.
class ConnectingStageCard extends StatefulWidget {
  /// Active stage index (0-based). Stages before it are done.
  final RxInt stage;
  final VoidCallback onCancel;

  const ConnectingStageCard({
    Key? key,
    required this.stage,
    required this.onCancel,
  }) : super(key: key);

  static const List<String> stageLabels = [
    '连接服务器',
    '打洞/中继协商',
    '建立加密通道',
    '等待画面',
  ];

  @override
  State<ConnectingStageCard> createState() => _ConnectingStageCardState();
}

class _ConnectingStageCardState extends State<ConnectingStageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    // Continuous breathing indicator for the active stage dot. It plays the
    // role of a spinner (not a transition); all transitions use <= 200ms
    // with standard easing per the design tokens.
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Widget _stageIcon(bool done, bool active) {
    if (done) {
      return const Icon(Icons.check_circle,
          key: ValueKey('done'), size: 16, color: MyTheme.success);
    }
    if (active) {
      return FadeTransition(
        key: const ValueKey('active'),
        opacity: _breathController.drive(Tween<double>(begin: 0.35, end: 1.0)),
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: MyTheme.accent,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return Container(
      key: const ValueKey('pending'),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withOpacity(0.6), width: 1.5),
      ),
    );
  }

  Widget _buildStageRow(
      BuildContext context, String label, bool done, bool active) {
    final Color textColor = done
        ? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87
        : active
            ? MyTheme.accent
            : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _stageIcon(done, active),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(translate(label)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Content of the connecting dialog. The caller wraps this in a
    // CustomAlertDialog because OverlayDialogManager's DialogBuilder must
    // return a CustomAlertDialog.
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(translate('正在连接'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Obx(() {
            final active = widget.stage.value
                .clamp(0, ConnectingStageCard.stageLabels.length - 1)
                .toInt();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < ConnectingStageCard.stageLabels.length; i++)
                  _buildStageRow(context, ConnectingStageCard.stageLabels[i],
                      i < active, i == active),
              ],
            );
          }),
          const SizedBox(height: 20),
          Center(child: dialogButton('Cancel', onPressed: widget.onCancel)),
        ],
      ),
    );
  }
}
