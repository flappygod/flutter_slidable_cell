import 'package:flutter/material.dart';

/// 滑动按钮区域的展开模式。
/// Expansion mode for action area.
enum SlideableCellExpandMode {
  /// 将可见宽度在每个 action 之间均分。
  /// Split visible width evenly across all actions.
  everyItem,

  /// action 贴边展示，超过实际总宽度后再均分。
  /// Keep actions edge-aligned, then split evenly after overflow.
  adjustEdge,
}

enum SlideableCellStatus {
  /// 完全关闭。
  /// Fully closed.
  closed,

  /// 左侧处于打开状态。
  /// Opened to leading side.
  leadingOpen,

  /// 右侧处于打开状态。
  /// Opened to trailing side.
  trailingOpen,
}

///自定义裁剪
class ClipHorizontalRect extends CustomClipper<Rect> {
  final double? clipLeft;
  final double? clipRight;
  const ClipHorizontalRect({
    this.clipLeft,
    this.clipRight,
  });
  @override
  Rect getClip(Size size) {
    final double left = clipLeft ?? -100000;
    final double right = clipRight ?? -100000;
    final double rectLeft = left < 0 ? left : left.clamp(0.0, size.width);
    final double rectRightEdge = right < 0 ? size.width - right : size.width - right.clamp(0.0, size.width);
    return Rect.fromLTRB(
      rectLeft,
      0,
      rectRightEdge,
      size.height,
    );
  }

  @override
  bool shouldReclip(covariant ClipHorizontalRect oldClipper) {
    return oldClipper.clipLeft != clipLeft || oldClipper.clipRight != clipRight;
  }
}
