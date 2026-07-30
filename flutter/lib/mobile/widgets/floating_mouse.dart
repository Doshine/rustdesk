// 虚拟鼠标：52px 半透明圆形控制器（蓝鲸银河 P2-D，替代原 112×138 自定义左右键鼠标）。
//
// 交互模型（规范 v2.1 §2.2.C）：
// - 默认停靠屏幕右下，半透明（ idle 0.55 ），拖动/交互时提升不透明度（0.95），不遮挡输入焦点；
// - 单指拖动：移动远程光标（贴近屏幕边缘时自动滚动画布，沿用原 _CanvasScrollState）；
// - 点按 = 左键，长按 = 右键；
// - 双指竖向拖动 = 远程滚轮（方向约定与触控模式三指滚动一致：下移 scroll(1)）；
// - 与现有触控模式切换逻辑兼容：仍由 ffiModel.touchMode / VirtualMouseMode.showVirtualMouse 门控。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';

import 'motion.dart';

const double _kControllerSize = 52.0;
const double _kIdleOpacity = 0.55;
const double _kActiveOpacity = 0.95;
const double _kEdgeMargin = 24.0;
const double _kBottomMargin = 96.0;
const double _kMoveSlopPx = 6.0;
const double _kScrollStepPx = 24.0;
const int _kLongPressMillis = 500;

double? _tryParseCoordinateFromEvt(Map<String, dynamic>? evt, String key) {
  if (evt == null) return null;
  final coord = evt[key];
  if (coord == null) return null;
  return double.tryParse(coord);
}

class FloatingMouse extends StatefulWidget {
  final FFI ffi;
  const FloatingMouse({
    super.key,
    required this.ffi,
  });

  @override
  State<FloatingMouse> createState() => _FloatingMouseState();
}

class _CanvasScrollState {
  static const double speedPressed = 3.0;
  final InputModel inputModel;
  final CanvasModel canvasModel;
  final int _intervalMillis = 30;
  Timer? _timer;
  double _dx = 0;
  double _dy = 0;
  double _speed = 1.0;
  Rect _displayRect = Rect.zero;
  Offset _mouseGlobalPosition = Offset.zero;

  _CanvasScrollState({required this.inputModel, required this.canvasModel});

  double get step => 5.0 * canvasModel.scale;

  set scrollX(double speed) {
    _dx = step;
    setSpeed(speed);
  }

  set scrollY(double speed) {
    _dy = step;
    setSpeed(speed);
  }

  void tryCancel() {
    _dx = 0;
    _dy = 0;
    if (_timer == null) return;
    _timer?.cancel();
    _timer = null;
  }

  void setPressedSpeed() {
    setSpeed(_speed > 0
        ? _CanvasScrollState.speedPressed
        : -_CanvasScrollState.speedPressed);
  }

  void setReleasedSpeed() {
    setSpeed(_speed > 0 ? 1.0 : -1.0);
  }

  void setSpeed(double newSpeed) {
    _speed = newSpeed;
    if (_speed > 0) {
      _speed = _speed.clamp(0.1, 10.0);
    } else {
      _speed = _speed.clamp(-10.0, -0.1);
    }
    if (_dx != 0) {
      _dx = step * _speed;
    } else if (_dy != 0) {
      _dy = step * _speed;
    }
  }

  void tryStart(Rect displayRect, Offset mouseGlobalPosition) {
    _displayRect = displayRect;
    _mouseGlobalPosition = mouseGlobalPosition;
    if (_timer != null) return;
    _timer = Timer.periodic(Duration(milliseconds: _intervalMillis), (timer) {
      if (_dx == 0 && _dy == 0) {
        tryCancel();
      } else {
        if (_dx != 0) {
          canvasModel.panX(_dx);
        }
        if (_dy != 0) {
          canvasModel.panY(_dy);
        }
        final evt = inputModel.processEventToPeer(
            InputModel.getMouseEventMove(), _mouseGlobalPosition,
            moveCanvas: false);
        if (shouldCancelScrollTimer(evt)) {
          tryCancel();
        }
      }
    });
  }

  bool shouldCancelScrollTimer(Map<String, dynamic>? evt) {
    if (evt == null) {
      return true;
    }
    double s = canvasModel.scale;
    assert(s > 0, 'canvasModel.scale should always be positive');
    if (s <= 0) {
      return true;
    }
    if (_dx != 0) {
      final x = _tryParseCoordinateFromEvt(evt, 'x');
      if (x == null) {
        return true;
      } else {
        if (_dx < 0) {
          if (isDoubleEqual(_displayRect.right - 1, x)) {
            return true;
          } else {
            final dxDisplay = _dx / s;
            if ((x - dxDisplay) > (_displayRect.right - 1)) {
              canvasModel.panX((x - _displayRect.right + 1) * s);
              return true;
            }
          }
        } else {
          if (isDoubleEqual(x, _displayRect.left)) {
            return true;
          } else {
            final dxDisplay = _dx / s;
            if ((x - dxDisplay) < _displayRect.left) {
              canvasModel.panX((x - _displayRect.left) * s);
              return true;
            }
          }
        }
      }
    }
    if (_dy != 0) {
      final y = _tryParseCoordinateFromEvt(evt, 'y');
      if (y == null) {
        return true;
      } else {
        if (_dy < 0) {
          if (isDoubleEqual(_displayRect.bottom - 1, y)) {
            return true;
          } else {
            final dyDisplay = _dy / s;
            if ((y - dyDisplay) > (_displayRect.bottom - 1)) {
              canvasModel.panY((y - _displayRect.bottom + 1) * s);
              return true;
            }
          }
        } else {
          if (isDoubleEqual(y, _displayRect.top)) {
            return true;
          } else {
            final dyDisplay = _dy / s;
            if ((y - dyDisplay) < _displayRect.top) {
              canvasModel.panY((y - _displayRect.top) * s);
              return true;
            }
          }
        }
      }
    }
    return false;
  }
}

class _FloatingMouseState extends State<FloatingMouse> {
  final GlobalKey _widgetKey = GlobalKey();
  Rect? _lastBlockedRect;

  Offset _position = Offset.zero;
  bool _isInitialized = false;

  /// 是否正在拖动/双指滚动（提升不透明度）。
  bool _interacting = false;

  final Set<int> _pointers = {};
  final Map<int, Offset> _pointerPositions = {};
  Offset _downPosition = Offset.zero;
  bool _moved = false;
  bool _longPressFired = false;
  Timer? _longPressTimer;
  double _scrollAccumPx = 0;

  late final _CanvasScrollState _canvasScrollState;
  late final VirtualMouseMode _virtualMouseMode;
  Orientation? _previousOrientation;

  InputModel get _inputModel => widget.ffi.inputModel;
  CursorModel get _cursorModel => widget.ffi.cursorModel;
  CanvasModel get _canvasModel => widget.ffi.canvasModel;

  /// 控制器边长（尊重既有缩放选项 kOptionVirtualMouseScale）。
  double get _size => _kControllerSize * _virtualMouseMode.virtualMouseScale;

  /// 远程光标锚点 = 圆心。
  Offset get _cursorGlobalPosition => _position + Offset(_size / 2, _size / 2);

  @override
  void initState() {
    super.initState();
    _virtualMouseMode = widget.ffi.ffiModel.virtualMouseMode;
    _virtualMouseMode.addListener(_onVirtualMouseModeChanged);
    _canvasScrollState =
        _CanvasScrollState(inputModel: _inputModel, canvasModel: _canvasModel);
    _cursorModel.blockEvents = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetPosition();
    });
  }

  void _onVirtualMouseModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentOrientation = MediaQuery.of(context).orientation;
    if (_previousOrientation != null &&
        _previousOrientation != currentOrientation) {
      _resetPosition();
    }
    _previousOrientation = currentOrientation;
  }

  /// 默认停靠右下（避让底部会话工具栏区域）。
  void _resetPosition() {
    final size = MediaQuery.of(context).size;
    final s = _size;
    setState(() {
      _position = Offset(
        (size.width - s - _kEdgeMargin).clamp(0.0, double.infinity),
        (size.height - s - _kBottomMargin).clamp(0.0, double.infinity),
      );
      _isInitialized = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateBlockedRect();
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    if (_lastBlockedRect != null) {
      _cursorModel.removeBlockedRect(_lastBlockedRect!);
    }
    _virtualMouseMode.removeListener(_onVirtualMouseModeChanged);
    _canvasScrollState.tryCancel();
    _cursorModel.blockEvents = false;
    super.dispose();
  }

  void _updateBlockedRect() {
    final context = _widgetKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final newRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    if (_lastBlockedRect != null) {
      _cursorModel.removeBlockedRect(_lastBlockedRect!);
    }
    _cursorModel.addBlockedRect(newRect);
    _lastBlockedRect = newRect;
  }

  void _setInteracting(bool v) {
    if (_interacting == v) return;
    setState(() => _interacting = v);
  }

  static Offset? _getPositionFromMouseRetEvt(Map<String, dynamic>? evt) {
    final x = _tryParseCoordinateFromEvt(evt, 'x');
    final y = _tryParseCoordinateFromEvt(evt, 'y');
    if (x == null || y == null) {
      return null;
    }
    return Offset(x, y);
  }

  // Returns true if [value] is within 2.01 pixels of [edge].
  // We need this near check because it can make the auto scroll easier to trigger and control.
  bool _isValueNearEdge(double edge, double value) {
    return (value - edge).abs() < 2.01;
  }

  bool _isValueAtEdge(double edge, double value) {
    return (value - edge).abs() < 0.01;
  }

  bool _isValueAtOrOutsideEdge(double edge, double? value) {
    // If value is null, then consider it outside the edge.
    return value == null || isDoubleEqual(value, edge);
  }

  // If the mouse is very close to the edge of the display,
  // we can only start auto scroll when the mouse is at the edge of the screen.
  bool _shouldAutoScrollIfCursorNearRemoteEdge(double remoteEdge,
      double remoteValue, double localEdge, double localValue) {
    if ((remoteEdge - remoteValue).abs() < 100.0) {
      if (!_isValueAtEdge(localEdge, localValue)) {
        return false;
      }
    }
    return true;
  }

  /// 单指拖动：移动控制器（远程光标跟随圆心），贴近屏幕边缘时自动滚动画布。
  void _onMoveUpdateDelta(Offset delta) {
    final context = this.context;
    final size = MediaQuery.of(context).size;
    Offset newPosition = _position + delta;
    double minX = 0;
    double minY = 0;
    double maxX = size.width - _size;
    double maxY = size.height - _size;
    newPosition = Offset(
      newPosition.dx.clamp(minX, maxX),
      newPosition.dy.clamp(minY, maxY),
    );
    setState(() {
      final isPositionChanged = !(isDoubleEqual(newPosition.dx, _position.dx) &&
          isDoubleEqual(newPosition.dy, _position.dy));
      _position = newPosition;

      Offset? mouseGlobalPosition;
      Offset? positionInRemoteDisplay;
      if (isPositionChanged) {
        mouseGlobalPosition = _cursorGlobalPosition;
        final evt = _inputModel.handleMouse(
            InputModel.getMouseEventMove(), mouseGlobalPosition,
            moveCanvas: false);
        positionInRemoteDisplay = _getPositionFromMouseRetEvt(evt);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateBlockedRect();
        });
      }

      // Get the display rect
      final displayRect = widget.ffi.ffiModel.displaysRect();
      if (displayRect == null) {
        _canvasScrollState.tryCancel();
        return;
      }

      // Get the mouse global position and position in remote display
      mouseGlobalPosition ??= _cursorGlobalPosition;
      if (positionInRemoteDisplay == null) {
        final evt = _inputModel.processEventToPeer(
            InputModel.getMouseEventMove(), mouseGlobalPosition,
            moveCanvas: false);
        positionInRemoteDisplay = _getPositionFromMouseRetEvt(evt);
      }

      // Check if need to start auto canvas scroll
      // If:
      // 1. The mouse is near the edge of the screen.
      // 2. The position in remote display is in the rect of the display.
      // 3. If the remote cursor is near the edge of the remote display,
      //    then the local mouse must be at the edge of the screen.
      // Then start auto canvas scroll.
      if (_isValueNearEdge(minX, _position.dx)) {
        bool shouldStartScroll = true;
        if (_isValueAtOrOutsideEdge(
            displayRect.left, positionInRemoteDisplay?.dx)) {
          shouldStartScroll = false;
        }
        if (positionInRemoteDisplay != null) {
          if (!_shouldAutoScrollIfCursorNearRemoteEdge(displayRect.left,
              positionInRemoteDisplay.dx, minX, _position.dx)) {
            shouldStartScroll = false;
          }
        }
        if (!shouldStartScroll) {
          _canvasScrollState.tryCancel();
          return;
        }
        _canvasScrollState.scrollX = 1.0 * _CanvasScrollState.speedPressed;
      } else if (_isValueNearEdge(minY, _position.dy)) {
        bool shouldStartScroll = true;
        if (_isValueAtOrOutsideEdge(
            displayRect.top, positionInRemoteDisplay?.dy)) {
          shouldStartScroll = false;
        }
        if (positionInRemoteDisplay != null) {
          if (!_shouldAutoScrollIfCursorNearRemoteEdge(displayRect.top,
              positionInRemoteDisplay.dy, minY, _position.dy)) {
            shouldStartScroll = false;
          }
        }
        if (!shouldStartScroll) {
          _canvasScrollState.tryCancel();
          return;
        }
        _canvasScrollState.scrollY = 1.0 * _CanvasScrollState.speedPressed;
      } else if (_isValueNearEdge(maxX, _position.dx)) {
        bool shouldStartScroll = true;
        if (_isValueAtOrOutsideEdge(
            displayRect.right - 1, positionInRemoteDisplay?.dx)) {
          shouldStartScroll = false;
        }
        if (positionInRemoteDisplay != null) {
          if (!_shouldAutoScrollIfCursorNearRemoteEdge(displayRect.right - 1,
              positionInRemoteDisplay.dx, maxX, _position.dx)) {
            shouldStartScroll = false;
          }
        }
        if (!shouldStartScroll) {
          _canvasScrollState.tryCancel();
          return;
        }
        _canvasScrollState.scrollX = -1.0 * _CanvasScrollState.speedPressed;
      } else if (_isValueNearEdge(maxY, _position.dy)) {
        bool shouldStartScroll = true;
        if (_isValueAtOrOutsideEdge(
            displayRect.bottom - 1, positionInRemoteDisplay?.dy)) {
          shouldStartScroll = false;
        }
        if (positionInRemoteDisplay != null) {
          if (!_shouldAutoScrollIfCursorNearRemoteEdge(displayRect.bottom - 1,
              positionInRemoteDisplay.dy, maxY, _position.dy)) {
            shouldStartScroll = false;
          }
        }
        if (!shouldStartScroll) {
          _canvasScrollState.tryCancel();
          return;
        }
        _canvasScrollState.scrollY = -1.0 * _CanvasScrollState.speedPressed;
      } else {
        _canvasScrollState.tryCancel();
        return;
      }
      _canvasScrollState.tryStart(displayRect, mouseGlobalPosition);
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointers.add(event.pointer);
    _pointerPositions[event.pointer] = event.position;
    if (_pointers.length == 1) {
      _moved = false;
      _longPressFired = false;
      _downPosition = event.position;
      // 长按 = 右键
      _longPressTimer?.cancel();
      _longPressTimer =
          Timer(const Duration(milliseconds: _kLongPressMillis), () {
        if (!mounted || _moved || _pointers.length != 1) return;
        _longPressFired = true;
        _inputModel.tap(MouseButtons.right);
      });
    } else {
      // 进入双指滚动：取消长按判定并重置滚动累计
      _longPressTimer?.cancel();
      _scrollAccumPx = 0;
    }
    _setInteracting(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final last = _pointerPositions[event.pointer];
    if (!_pointers.contains(event.pointer) || last == null) return;
    final delta = event.position - last;
    _pointerPositions[event.pointer] = event.position;
    if (_pointers.length >= 2) {
      // 双指竖向拖动 = 远程滚轮（方向约定同触控模式三指滚动）
      _scrollAccumPx += delta.dy;
      while (_scrollAccumPx.abs() >= _kScrollStepPx) {
        _inputModel.scroll(_scrollAccumPx > 0 ? 1 : -1);
        _scrollAccumPx -= _scrollAccumPx.sign * _kScrollStepPx;
      }
      return;
    }
    // 位移阈值按「按下点 → 当前」累计计算，避免细碎抖动既触发不了拖动又误触点按
    if (!_moved &&
        (event.position - _downPosition).distance > _kMoveSlopPx) {
      _moved = true;
      _longPressTimer?.cancel();
    }
    if (_moved) {
      _onMoveUpdateDelta(delta);
    }
  }

  void _handlePointerUp(PointerUpEvent event) =>
      _handlePointerEnd(event.pointer, true);

  void _handlePointerCancel(PointerCancelEvent event) =>
      _handlePointerEnd(event.pointer, false);

  void _handlePointerEnd(int pointer, bool isUp) {
    final wasLastSingle = _pointers.length == 1 && _pointers.contains(pointer);
    _pointers.remove(pointer);
    _pointerPositions.remove(pointer);
    if (_pointers.isEmpty) {
      _longPressTimer?.cancel();
      _canvasScrollState.tryCancel();
      _scrollAccumPx = 0;
      if (isUp && wasLastSingle && !_moved && !_longPressFired) {
        // 点按 = 左键
        _inputModel.tap(MouseButtons.left);
      }
      _moved = false;
      _setInteracting(false);
    } else {
      // 双指回到单指：仅重置滚动累计，避免位移跳变
      _scrollAccumPx = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Offstage();
    }
    if (!_virtualMouseMode.showVirtualMouse) {
      return const Offstage();
    }
    final s = _size;
    return Stack(
      children: [
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: AnimatedOpacity(
              opacity: _interacting ? _kActiveOpacity : _kIdleOpacity,
              duration: yhMotionDuration(
                  context, const Duration(milliseconds: 150)),
              curve: Curves.easeInOut,
              child: Container(
                key: _widgetKey,
                width: s,
                height: s,
                decoration: BoxDecoration(
                  // 深空 surface（token 产物落地后应替换为 token 引用）
                  color: YinheColors.surfaceDark, // tokens surface.dark.surface（spec §7.2）
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: MyTheme.accent.withOpacity(0.65), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.mouse_outlined,
                    color: Colors.white, size: s * 0.42),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
