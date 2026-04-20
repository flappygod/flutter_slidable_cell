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
