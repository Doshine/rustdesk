import 'package:flutter/widgets.dart';

/// 蓝鲸银河动效降级辅助（P2-D）。
///
/// 系统「减弱动态效果」开启时（Flutter 映射为 MediaQuery.disableAnimations），
/// P2-D 新增动画一律降级：脉冲/过渡动画替换为瞬时或静态呈现。
bool yhReduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// 动效时长按 reduced-motion 降级为 0；未开启时返回原时长。
Duration yhMotionDuration(BuildContext context, Duration duration) =>
    yhReduceMotion(context) ? Duration.zero : duration;
