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

/// Cell 当前的开合状态。
/// Current open/close status of a cell.
enum SlideableCellStatus {
  /// 完全关闭。
  /// Fully closed.
  closed,

  /// 左侧普通打开（落到 leading 实际总宽度）。
  /// Opened to leading at normal width.
  leadingOpen,

  /// 右侧普通打开（落到 trailing 实际总宽度）。
  /// Opened to trailing at normal width.
  trailingOpen,

  /// 左侧完全展开（落到父容器宽度）。
  /// Leading side fully expanded to parent width.
  leadingFullExpanded,

  /// 右侧完全展开（落到父容器宽度）。
  /// Trailing side fully expanded to parent width.
  trailingFullExpanded,
}

/// 拖动越过 `*FullExpandExtra` 阈值后，松手时的最终行为。
/// Final behavior when drag distance crosses `*FullExpandExtra` threshold.
enum SlideableExpandBehavior {
  /// 完全展开到父容器宽度。
  /// Expand fully to parent width.
  expand,

  /// 直接关闭。
  /// Close immediately.
  close,

  /// 回到普通打开宽度。
  /// Settle to normal opened width.
  open,
}

/// 自定义裁剪：根据可选的负偏移 / 正偏移定义可见区域。
/// Custom clipper that supports negative offsets to extend clip beyond bounds.
///
/// 约定：
/// - `clipLeft` 为负数时表示向外扩展，正数表示向内收缩；为 null 视为不裁剪左侧。
/// - `clipRight` 同理。
/// Convention:
/// - Negative value extends the clip outward, positive value shrinks inward;
///   null means "do not clip that side".
class ClipHorizontalRect extends CustomClipper<Rect> {
  final double? clipLeft;
  final double? clipRight;

  const ClipHorizontalRect({
    this.clipLeft,
    this.clipRight,
  });

  /// 用作"不裁剪"哨兵的远端值，
  /// 取值需要大到足够包住任何可能的 child，但又不能用 infinity 以避免 NaN。
  /// Sentinel for "no clipping" side. Large enough to cover any child,
  /// but not infinity to avoid NaN math inside Rect.
  static const double _noClipSentinel = -1.0e9;

  @override
  Rect getClip(Size size) {
    final double left = clipLeft ?? _noClipSentinel;
    final double right = clipRight ?? _noClipSentinel;
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
