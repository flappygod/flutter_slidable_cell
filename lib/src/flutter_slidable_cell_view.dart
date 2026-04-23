import 'package:flutter/material.dart';
import 'flutter_slidable_action_item.dart';
import 'flutter_slidable_base.dart';

/// 滑动 Cell 的控制器。
/// Controller for opening/closing slidable cells by [ValueKey].
class SlideableCellController {
  /// 当前的所有 entry。
  /// All registered entries.
  final Map<ValueKey, _SlideableCellControllerEntry> _entries = <ValueKey, _SlideableCellControllerEntry>{};

  /// 当前的所有状态。
  /// All cached statuses.
  final Map<ValueKey, SlideableCellStatus> _status = <ValueKey, SlideableCellStatus>{};

  /// 通用查找方法：
  /// 先按 key 直接查，再按 key.value 查。
  /// Generic finder:
  /// first lookup by key directly, then fallback to key.value.
  T? _findByValueKey<T>(Map<ValueKey, T> source, ValueKey key) {
    final direct = source[key];
    if (direct != null) {
      return direct;
    }
    for (final item in source.entries) {
      if (item.key.value == key.value) {
        return item.value;
      }
    }
    return null;
  }

  /// 找到相应的 entry。
  /// Finds the matching entry.
  _SlideableCellControllerEntry? _findEntry(ValueKey key) {
    return _findByValueKey(_entries, key);
  }

  /// 找到相应的状态。
  /// Finds the matching status.
  SlideableCellStatus _findStatus(ValueKey key) {
    return _findByValueKey(_status, key) ?? SlideableCellStatus.closed;
  }

  /// 注册一个可控制的 Cell 实例。
  /// Registers a cell entry for controller operations.
  void _register(
    ValueKey key,
    _SlideableCellControllerEntry entry,
    SlideableCellStatus initialStatus,
  ) {
    _entries[key] = entry;
    _status[key] = initialStatus;
  }

  /// 仅在 entry 与当前注册项一致时移除，避免误删。
  /// Unregister only when the entry matches current mapping.
  void _unregister(ValueKey key, _SlideableCellControllerEntry entry) {
    final current = _entries[key];
    if (identical(current, entry)) {
      _entries.remove(key);
    }
  }

  /// 更新指定 key 对应 item 的状态缓存。
  /// Updates cached open/close status for an item key.
  void _updateStatus(ValueKey key, SlideableCellStatus status) {
    _status[key] = status;
  }

  /// 获取指定 key 的当前状态，默认关闭。
  /// Returns current status for key, default is closed.
  SlideableCellStatus statusOf(ValueKey key) {
    return _findStatus(key);
  }

  /// 是否处于任一打开状态（左开或右开）。
  /// Whether the cell is currently opened on either side.
  bool isOpen(ValueKey key) {
    final status = statusOf(key);
    return status == SlideableCellStatus.leadingOpen || status == SlideableCellStatus.trailingOpen;
  }

  /// 全量状态快照（只读）。
  /// Read-only snapshot for all item statuses.
  Map<ValueKey, SlideableCellStatus> get statuses {
    return Map<ValueKey, SlideableCellStatus>.unmodifiable(_status);
  }

  /// 打开左方。
  /// Opens leading side.
  Future<void> openLeading(ValueKey key) async {
    await _findEntry(key)?.openLeading?.call();
  }

  /// 打开右方。
  /// Opens trailing side.
  Future<void> openTrailing(ValueKey key) async {
    await _findEntry(key)?.openTrailing?.call();
  }

  /// 关闭 Cell。
  /// Closes a cell.
  Future<void> closeCell(ValueKey key) async {
    await _findEntry(key)?.close?.call();
  }

  /// 关闭所有的 item。
  /// Closes all cells.
  Future<void> closeAllCells() async {
    final futures = _entries.values
        .map((entry) => entry.close)
        .whereType<Future<void> Function()>()
        .map((fn) => fn())
        .toList(growable: false);
    await Future.wait<void>(futures);
  }
}

/// 可滑动的 Cell 组件。
/// A slidable cell widget with leading/trailing actions.
class SlideableCellView extends StatefulWidget {
  /// 展开模式。
  /// Expansion mode for action layout.
  final SlideableCellExpandMode expandMode;

  /// 控制器，用于外部按 key 控制开关。
  /// External controller for open/close by key.
  final SlideableCellController controller;

  /// 从关闭态到打开态的阈值比例。
  /// Open threshold ratio when gesture ends from closed state.
  final double openFactor;

  /// 从打开态到关闭态的阈值比例。
  /// Close threshold ratio when gesture ends from opened state.
  final double closeFactor;

  /// 开关动画曲线。
  /// Curve used by open/close animation.
  final Curve curve;

  /// 开关动画时长。
  /// Duration used by open/close animation.
  final Duration duration;

  /// 前景内容（会被左右拖动）。
  /// Foreground child that follows drag offset.
  final Widget child;

  /// 左侧 action 列表。
  /// Leading actions shown while dragging right.
  final List<Widget> leadingActions;

  /// 右侧 action 列表。
  /// Trailing actions shown while dragging left.
  final List<Widget> trailingActions;

  /// 左侧是否可以全展开。
  /// Whether leading side supports full expansion.
  final bool leadingFullExpandable;

  /// 左侧全展开额外触发距离。
  /// Extra distance to trigger leading full expansion.
  final double leadingFullExpandExtra;

  /// 右侧是否可以全展开。
  /// Whether trailing side supports full expansion.
  final bool trailingFullExpandable;

  /// 右侧全展开额外触发距离。
  /// Extra distance to trigger trailing full expansion.
  final double trailingFullExpandExtra;

  /// 背景颜色。
  /// Background color.
  final Color color;

  /// 打开自己的时候关闭其他的 item。
  /// Whether to close other opened items when opening current one.
  final bool closeOthersWhenOpen;

  /// 左边 expand curve。
  /// Leading expand curve.
  final Curve leadingExpandCurve;

  /// 左边 expand duration。
  /// Leading expand duration.
  final Duration leadingExpandDuration;

  /// 右边 expand curve。
  /// Trailing expand curve.
  final Curve trailingExpandCurve;

  /// 右边 expand duration。
  /// Trailing expand duration.
  final Duration trailingExpandDuration;

  const SlideableCellView({
    required super.key,
    required this.controller,
    required this.child,
    this.expandMode = SlideableCellExpandMode.adjustEdge,
    this.openFactor = 0.3,
    this.closeFactor = 0.3,
    this.curve = const Cubic(0.34, 0.84, 0.12, 1.00),
    this.duration = const Duration(milliseconds: 380),
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.leadingFullExpandable = false,
    this.trailingFullExpandable = false,
    this.leadingFullExpandExtra = 60,
    this.trailingFullExpandExtra = 60,
    this.closeOthersWhenOpen = true,
    this.color = Colors.white,
    this.leadingExpandCurve = const Cubic(0.34, 0.84, 0.12, 1.00),
    this.leadingExpandDuration = const Duration(milliseconds: 380),
    this.trailingExpandCurve = const Cubic(0.34, 0.84, 0.12, 1.00),
    this.trailingExpandDuration = const Duration(milliseconds: 380),
  }) : assert(
          key is ValueKey,
          'SlideableCellView.key 必须是 ValueKey / must be a ValueKey',
        );

  @override
  State<SlideableCellView> createState() => _SlideableCellViewState();

  /// 当前 cell 的业务 key，约定必须使用 [ValueKey]。
  /// Business key for controller mapping. Must be a [ValueKey].
  ValueKey get cellKey => key as ValueKey;
}

/// [SlideableCellView] 的状态实现。
/// Internal state implementation for [SlideableCellView].
class _SlideableCellViewState extends State<SlideableCellView> with TickerProviderStateMixin {
  /// 回弹动画控制器。
  /// Snap animation controller.
  late final AnimationController _snapAnimationController;

  /// 当前前景偏移量。
  /// Current horizontal offset of foreground child.
  double _offset = 0;

  /// 每个 action 的测量 key。
  /// Keys for measuring actual width of each action.
  late List<GlobalKey> _leadingActionKeys;
  late List<GlobalKey> _trailingActionKeys;

  /// 每个 action 的实际宽度缓存。
  /// Cached actual width for every action widget.
  final List<double> _leadingActionActualWidths = <double>[];
  final List<double> _trailingActionActualWidths = <double>[];

  /// 控制器桥接入口（避免把 State 暴露给 controller）。
  /// Bridge entry used by controller to trigger state animations.
  final _SlideableCellControllerEntry _controllerEntry = _SlideableCellControllerEntry();

  /// 当前开关状态。
  /// Current open/close status.
  SlideableCellStatus _status = SlideableCellStatus.closed;

  /// 左侧扩展动画控制器。
  /// Leading expand animation controller.
  late AnimationController _expandLeadingController;

  /// 左侧扩展动画。
  /// Leading expand animation.
  late Animation<double> _expandLeadingAnimation;

  /// 左侧当前是否正在 forward。
  /// Whether leading side is currently forwarding.
  bool _leadingForwarding = false;

  /// 右侧扩展动画控制器。
  /// Trailing expand animation controller.
  late AnimationController _expandTrailingController;

  /// 右侧扩展动画。
  /// Trailing expand animation.
  late Animation<double> _expandTrailingAnimation;

  /// 右侧当前是否正在 forward。
  /// Whether trailing side is currently forwarding.
  bool _trailingForwarding = false;

  /// 是否已经安排了宽度收集任务。
  /// Whether width collection has been scheduled.
  bool _widthCollectScheduled = false;

  /// 初始化控制器。
  /// Initializes animation controllers.
  void _initController() {
    _snapAnimationController = AnimationController(vsync: this);

    /// 头部动画控制。
    /// Leading expand controller.
    _expandLeadingController = AnimationController(
      vsync: this,
      duration: widget.leadingExpandDuration,
      reverseDuration: widget.leadingExpandDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _expandLeadingAnimation = CurvedAnimation(
      parent: _expandLeadingController,
      curve: widget.leadingExpandCurve,
    );

    /// 尾部动画控制。
    /// Trailing expand controller.
    _expandTrailingController = AnimationController(
      vsync: this,
      duration: widget.trailingExpandDuration,
      reverseDuration: widget.trailingExpandDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _expandTrailingAnimation = CurvedAnimation(
      parent: _expandTrailingController,
      curve: widget.trailingExpandCurve,
    );

    /// 设置监听。
    /// Add listeners for rebuild.
    _expandLeadingController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _expandTrailingController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// 左侧 forward。
  /// Forward leading expand animation.
  void _leadingForward() {
    if (_leadingForwarding == false) {
      _leadingForwarding = true;
      _expandLeadingController.forward(from: _expandLeadingController.value);
    }
  }

  /// 左侧 reverse。
  /// Reverse leading expand animation.
  void _leadingReverse() {
    if (_leadingForwarding == true) {
      _leadingForwarding = false;
      _expandLeadingController.reverse(from: _expandLeadingController.value);
    }
  }

  /// 右侧 forward。
  /// Forward trailing expand animation.
  void _trailingForward() {
    if (_trailingForwarding == false) {
      _trailingForwarding = true;
      _expandTrailingController.forward(from: _expandTrailingController.value);
    }
  }

  /// 右侧 reverse。
  /// Reverse trailing expand animation.
  void _trailingReverse() {
    if (_trailingForwarding == true) {
      _trailingForwarding = false;
      _expandTrailingController.reverse(from: _expandTrailingController.value);
    }
  }

  @override
  void initState() {
    super.initState();
    _initController();
    _recreateActionKeys();
    _resizeActualWidths();
    _bindController();
    _scheduleCollectActionWidths();
  }

  @override
  void didUpdateWidget(covariant SlideableCellView oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// 如果 action 数量不一致，做完全重建并重新测量宽度。
    /// Recreate keys and width cache when action counts change.
    if (oldWidget.leadingActions.length != widget.leadingActions.length ||
        oldWidget.trailingActions.length != widget.trailingActions.length) {
      _recreateActionKeys();
      _resizeActualWidths();
      _scheduleCollectActionWidths();
    }

    /// 重新绑定 key 或 controller。
    /// Rebind when key or controller changes.
    if (oldWidget.cellKey != widget.cellKey || oldWidget.controller != widget.controller) {
      oldWidget.controller._unregister(oldWidget.cellKey, _controllerEntry);
      _bindController();
    }
  }

  @override
  void dispose() {
    widget.controller._unregister(widget.cellKey, _controllerEntry);
    _snapAnimationController.dispose();
    _expandLeadingController.dispose();
    _expandTrailingController.dispose();
    super.dispose();
  }

  /// 安排一次 post-frame 宽度收集，避免 build 中重复注册。
  /// Schedules a post-frame width collection to avoid repeated registration in build.
  void _scheduleCollectActionWidths() {
    if (_widthCollectScheduled) {
      return;
    }
    _widthCollectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widthCollectScheduled = false;
      if (mounted) {
        _collectActionWidths();
      }
    });
  }

  /// 重新构建 action 的测量 key 列表。
  /// Rebuilds keys used for action width measurement.
  void _recreateActionKeys() {
    _leadingActionKeys = List<GlobalKey>.generate(
      widget.leadingActions.length,
      (_) => GlobalKey(),
      growable: false,
    );
    _trailingActionKeys = List<GlobalKey>.generate(
      widget.trailingActions.length,
      (_) => GlobalKey(),
      growable: false,
    );
  }

  /// 按 action 数量初始化宽度缓存。
  /// Initializes width cache with action counts.
  void _resizeActualWidths() {
    _leadingActionActualWidths
      ..clear()
      ..addAll(List<double>.filled(widget.leadingActions.length, 0));
    _trailingActionActualWidths
      ..clear()
      ..addAll(List<double>.filled(widget.trailingActions.length, 0));
  }

  /// 将当前 State 绑定到 controller。
  /// Binds state callbacks into external controller.
  void _bindController() {
    _controllerEntry.openLeading = () => _animateToLeadingOpen();
    _controllerEntry.openTrailing = () => _animateToTrailingOpen();
    _controllerEntry.close = () => _animateToClosed();
    widget.controller._register(widget.cellKey, _controllerEntry, _status);
  }

  /// 左侧 actions 实际总宽度。
  /// Total measured width of leading actions.
  double get _leadingActualTotalWidth {
    return _leadingActionActualWidths.fold(0, (sum, item) => sum + item);
  }

  /// 右侧 actions 实际总宽度。
  /// Total measured width of trailing actions.
  double get _trailingActualTotalWidth {
    return _trailingActionActualWidths.fold(0, (sum, item) => sum + item);
  }

  /// 收集 action 实际宽度并在变化时刷新。
  /// Collects real action widths and triggers rebuild if changed.
  void _collectActionWidths() {
    var changed = false;

    for (var i = 0; i < _leadingActionKeys.length; i++) {
      final width = _readWidth(_leadingActionKeys[i]);
      if (width > 0 && _leadingActionActualWidths[i] != width) {
        _leadingActionActualWidths[i] = width;
        changed = true;
      }
    }

    for (var i = 0; i < _trailingActionKeys.length; i++) {
      final width = _readWidth(_trailingActionKeys[i]);
      if (width > 0 && _trailingActionActualWidths[i] != width) {
        _trailingActionActualWidths[i] = width;
        changed = true;
      }
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  /// 从 key 对应渲染对象读取宽度。
  /// Reads width from render object bound to key.
  double _readWidth(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return 0;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.size.width;
    }
    return 0;
  }

  /// 根据偏移量刷新控制器中的状态缓存。
  /// Syncs status cache in controller from current offset.
  void _updateStatusByOffset() {
    final nextStatus = _offset.abs() < 0.0001
        ? SlideableCellStatus.closed
        : (_offset > 0 ? SlideableCellStatus.leadingOpen : SlideableCellStatus.trailingOpen);

    if (_status != nextStatus) {
      _status = nextStatus;
      widget.controller._updateStatus(widget.cellKey, _status);
    }
  }

  /// 执行偏移动画（统一入口）。
  /// Unified animation entry for offset transitions.
  Future<void> _animateTo(double target) async {
    if (!mounted) {
      return;
    }

    _snapAnimationController
      ..stop()
      ..duration = widget.duration;

    final animation = Tween<double>(
      begin: _offset,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: widget.curve,
      ),
    );

    void listener() {
      if (!mounted) {
        return;
      }
      setState(() {
        _offset = animation.value;
      });
    }

    animation.addListener(listener);
    try {
      await _snapAnimationController.forward(from: 0);
    } finally {
      animation.removeListener(listener);
    }

    if (mounted) {
      setState(() {
        _offset = target;
      });
      _updateStatusByOffset();
    }
  }

  /// 动画打开左侧。
  /// Animate to leading-open position.
  Future<void> _animateToLeadingOpen() {
    return _openTo(target: _leadingActualTotalWidth);
  }

  /// 动画打开右侧。
  /// Animate to trailing-open position.
  Future<void> _animateToTrailingOpen() {
    return _openTo(target: -_trailingActualTotalWidth);
  }

  /// 动画关闭。
  /// Animate to closed position.
  Future<void> _animateToClosed() {
    return _animateTo(0);
  }

  /// 打开到指定的位置。
  /// Opens to a target offset.
  Future<void> _openTo({required double target}) async {
    if (widget.closeOthersWhenOpen) {
      await Future.wait([
        /// 关闭其他的。
        /// Close others.
        _closeOtherOpenedCells(),

        /// 打开到指定位置。
        /// Animate to target.
        _animateTo(target),
      ]);
    } else {
      await _animateTo(target);
    }
  }

  /// 判断两个 ValueKey 是否表示同一个业务 cell。
  /// Checks whether two ValueKeys represent the same business cell.
  bool _sameCellKey(ValueKey a, ValueKey b) {
    return a.value == b.value;
  }

  /// 关闭其他已打开的 items。
  /// Closes other opened items.
  Future<void> _closeOtherOpenedCells() async {
    final statusEntries = widget.controller.statuses.entries.toList(
      growable: false,
    );
    final futures = <Future<void>>[];

    for (final entry in statusEntries) {
      final bool isCurrentCell = _sameCellKey(entry.key, widget.cellKey);
      final bool isOpened =
          entry.value == SlideableCellStatus.leadingOpen || entry.value == SlideableCellStatus.trailingOpen;

      if (!isCurrentCell && isOpened) {
        futures.add(widget.controller.closeCell(entry.key));
      }
    }

    await Future.wait(futures);
  }

  /// 手势开始时终止进行中的动画。
  /// Stop active animation when a new drag starts.
  void _onHorizontalDragStart(DragStartDetails details) {
    _snapAnimationController.stop();
  }

  /// 拖动过程中实时更新偏移，并限制在左右可展开范围内。
  /// Updates offset while dragging and clamps to action total widths.
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final next = _offset + details.delta.dx;
    final leadingLimit = _maxDragDistance(_leadingActualTotalWidth);
    final trailingLimit = _maxDragDistance(_trailingActualTotalWidth);
    final clamped = next.clamp(-trailingLimit, leadingLimit);

    if (clamped == _offset) {
      return;
    }

    setState(() {
      _offset = clamped.toDouble();
    });
  }

  /// 手势结束阈值判定：
  /// 关闭态使用 [openFactor]，打开态使用 [closeFactor]。
  /// Gesture-end threshold decision:
  /// uses [openFactor] from closed state and [closeFactor] from opened state.
  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    final leadingWidth = _leadingActualTotalWidth;
    final trailingWidth = _trailingActualTotalWidth;

    /// 左侧超出真实宽度时，优先回弹到真实宽度。
    /// If leading side exceeds actual width, snap back to actual width first.
    if (_offset > 0 && leadingWidth > 0 && _offset > leadingWidth) {
      await _animateToLeadingOpen();
      return;
    }

    /// 右侧超出真实宽度时，优先回弹到真实宽度。
    /// If trailing side exceeds actual width, snap back to actual width first.
    if (_offset < 0 && trailingWidth > 0 && (-_offset) > trailingWidth) {
      await _animateToTrailingOpen();
      return;
    }

    /// 如果当前是关闭状态。
    /// If current status is closed.
    if (_status == SlideableCellStatus.closed) {
      if (_offset > 0 && leadingWidth > 0) {
        final factor = _offset / leadingWidth;
        if (factor > widget.openFactor) {
          await _animateToLeadingOpen();
        } else {
          await _animateToClosed();
        }
      } else if (_offset < 0 && trailingWidth > 0) {
        final factor = (-_offset) / trailingWidth;
        if (factor > widget.openFactor) {
          await _animateToTrailingOpen();
        } else {
          await _animateToClosed();
        }
      } else {
        await _animateToClosed();
      }
      return;
    }

    /// 如果当前是左侧打开。
    /// If current status is leading-open.
    if (_status == SlideableCellStatus.leadingOpen) {
      if (_offset <= 0 || leadingWidth <= 0) {
        await _animateToClosed();
        return;
      }

      final closedDistance = (leadingWidth - _offset).clamp(0, leadingWidth);
      final shouldClose = (closedDistance.toDouble() / leadingWidth) > widget.closeFactor;

      if (shouldClose) {
        await _animateToClosed();
      } else {
        await _animateToLeadingOpen();
      }
      return;
    }

    /// 如果当前是右侧打开。
    /// If current status is trailing-open.
    if (_offset >= 0 || trailingWidth <= 0) {
      await _animateToClosed();
      return;
    }

    final openedDistance = (-_offset).clamp(0, trailingWidth);
    final closedDistance = trailingWidth - openedDistance.toDouble();
    final shouldClose = (closedDistance / trailingWidth) > widget.closeFactor;

    if (shouldClose) {
      await _animateToClosed();
    } else {
      await _animateToTrailingOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        color: widget.color,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildChild(),
            _buildLeading(),
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  /// 最大的 drag 宽度。
  /// Maximum drag distance.
  double _maxDragDistance(double actualTotalWidth) {
    final viewport = MediaQuery.sizeOf(context).width;
    return actualTotalWidth > viewport ? actualTotalWidth : viewport;
  }

  /// 提取 child 的颜色。
  /// Extracts background color from action child.
  Color? _getChildColor(Widget child) {
    if (child is SlideableActionItem) {
      return child.slideBackgroundColor;
    } else {
      return null;
    }
  }

  /// 构建通用 action item 容器。
  /// Builds a common action item container.
  Widget _buildActionItemContainer({
    required double width,
    required Widget actionChild,
    required GlobalKey globalKey,
    Alignment alignment = Alignment.center,
  }) {
    return Container(
      width: width,
      alignment: alignment,
      color: _getChildColor(actionChild),
      child: OverflowBox(
        minWidth: 0,
        maxWidth: double.infinity,
        alignment: alignment,
        child: UnconstrainedBox(
          constrainedAxis: Axis.vertical,
          alignment: alignment,
          child: KeyedSubtree(
            key: globalKey,
            child: actionChild,
          ),
        ),
      ),
    );
  }

  /// 构建左侧 actions 区域。
  /// Builds leading action area.
  Widget _buildLeading() {
    if (widget.leadingActions.isEmpty) {
      return const SizedBox.shrink();
    }

    /// 计算左边的宽度。
    /// Current visible width of leading side.
    final double leadingWidth = _offset.clamp(0.0, double.infinity);

    /// 左侧实际总宽度。
    /// Total actual width of leading actions.
    final double totalActualWidth = _leadingActualTotalWidth;

    /// 如果左侧支持全展开。
    /// If leading side supports full expansion.
    if (widget.leadingFullExpandable) {
      /// 处理 expand 展开/收起触发。
      /// Handle expand forward/reverse trigger.
      if (leadingWidth > totalActualWidth + widget.leadingFullExpandExtra) {
        _leadingForward();
      } else {
        _leadingReverse();
      }

      /// 如果已经大于真实宽度，但是小于触发宽度。
      /// If width exceeds actual width, use full-expand layout.
      if (leadingWidth > totalActualWidth) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: leadingWidth,
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(
                widget.leadingActions.length,
                (index) {
                  final double currentActualWidth = _leadingActionActualWidths[index];
                  final GlobalKey globalKey = _leadingActionKeys[index];
                  final Widget actionChild = widget.leadingActions[index];

                  double itemWidth;

                  /// 对最后 1 条做处理，计算相应 item 的宽度。
                  /// Handle the edge item width for full expansion.
                  if (index == widget.leadingActions.length - 1) {
                    final double dragWidth = leadingWidth - totalActualWidth;
                    final double expandWidth = (totalActualWidth - currentActualWidth) * _expandLeadingAnimation.value;
                    itemWidth = dragWidth + currentActualWidth;

                    return Transform.translate(
                      offset: Offset(expandWidth, 0),
                      child: SizedBox(
                        width: itemWidth,
                        child: OverflowBox(
                          minWidth: itemWidth,
                          maxWidth: itemWidth + expandWidth,
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: itemWidth + expandWidth,
                            color: _getChildColor(actionChild),
                            child: UnconstrainedBox(
                              constrainedAxis: Axis.vertical,
                              alignment: Alignment.centerRight,
                              child: KeyedSubtree(
                                key: globalKey,
                                child: actionChild,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    itemWidth = currentActualWidth;
                    return _buildActionItemContainer(
                      width: itemWidth,
                      actionChild: actionChild,
                      globalKey: globalKey,
                    );
                  }
                },
                growable: false,
              ),
            ),
          ),
        );
      }
    }

    switch (widget.expandMode) {
      case SlideableCellExpandMode.everyItem:
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: leadingWidth,
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(
                widget.leadingActions.length,
                (index) {
                  final double currentActualWidth = _leadingActionActualWidths[index];

                  /// 以比例进行均分。
                  /// Distribute width proportionally.
                  final double itemWidth = totalActualWidth > 0
                      ? leadingWidth * (currentActualWidth / totalActualWidth)
                      : leadingWidth / widget.leadingActions.length;

                  final GlobalKey globalKey = _leadingActionKeys[index];
                  final Widget actionChild = widget.leadingActions[index];

                  return ClipRect(
                    child: _buildActionItemContainer(
                      width: itemWidth,
                      actionChild: actionChild,
                      globalKey: globalKey,
                    ),
                  );
                },
                growable: false,
              ),
            ),
          ),
        );

      case SlideableCellExpandMode.adjustEdge:

        /// 如果大于了真实宽度，也使用 everyItem 的均分模式。
        /// If width exceeds actual width, also use proportional mode.
        final bool shouldUseProportionalWidth = totalActualWidth > 0 && leadingWidth > totalActualWidth;

        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: leadingWidth,
            child: OverflowBox(
              minWidth: leadingWidth,
              maxWidth: double.infinity,
              alignment: Alignment.centerRight,
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List<Widget>.generate(
                  widget.leadingActions.length,
                  (index) {
                    final GlobalKey globalKey = _leadingActionKeys[index];
                    final Widget actionChild = widget.leadingActions[index];

                    if (shouldUseProportionalWidth) {
                      final double currentActualWidth = _leadingActionActualWidths[index];
                      final double itemWidth = leadingWidth * (currentActualWidth / totalActualWidth);

                      return ClipRect(
                        child: _buildActionItemContainer(
                          width: itemWidth,
                          actionChild: actionChild,
                          globalKey: globalKey,
                        ),
                      );
                    } else {
                      return Container(
                        color: _getChildColor(actionChild),
                        child: KeyedSubtree(
                          key: globalKey,
                          child: actionChild,
                        ),
                      );
                    }
                  },
                  growable: false,
                ),
              ),
            ),
          ),
        );
    }
  }

  /// 构建右侧 actions 区域。
  /// Builds trailing action area.
  Widget _buildTrailing() {
    if (widget.trailingActions.isEmpty) {
      return const SizedBox.shrink();
    }

    /// 计算右边的宽度。
    /// Current visible width of trailing side.
    double trailingWidth = _offset < 0 ? -_offset : 0.0;

    /// 限制宽度非负。
    /// Clamp width to non-negative.
    trailingWidth = trailingWidth.clamp(0.0, double.infinity);

    /// 右侧实际总宽度。
    /// Total actual width of trailing actions.
    final double totalActualWidth = _trailingActualTotalWidth;

    /// 如果右侧支持全展开。
    /// If trailing side supports full expansion.
    if (widget.trailingFullExpandable) {
      /// 处理 expand 展开/收起触发。
      /// Handle expand forward/reverse trigger.
      if (trailingWidth > totalActualWidth + widget.trailingFullExpandExtra) {
        _trailingForward();
      } else {
        _trailingReverse();
      }

      /// 如果已经大于真实宽度，但是小于触发宽度。
      /// If width exceeds actual width, use full-expand layout.
      if (trailingWidth > totalActualWidth) {
        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: trailingWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(
                widget.trailingActions.length,
                (index) {
                  final double currentActualWidth = _trailingActionActualWidths[index];
                  final GlobalKey globalKey = _trailingActionKeys[index];
                  final Widget actionChild = widget.trailingActions[index];

                  double itemWidth;

                  /// 对最后 1 条做处理，计算相应 item 的宽度。
                  /// Handle the edge item width for full expansion.
                  if (index == widget.trailingActions.length - 1) {
                    final double dragWidth = trailingWidth - totalActualWidth;
                    final double expandWidth = (totalActualWidth - currentActualWidth) * _expandTrailingAnimation.value;
                    itemWidth = dragWidth + currentActualWidth;

                    return Transform.translate(
                      offset: Offset(-expandWidth, 0),
                      child: SizedBox(
                        width: itemWidth,
                        child: OverflowBox(
                          minWidth: itemWidth,
                          maxWidth: itemWidth + expandWidth,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: itemWidth + expandWidth,
                            color: _getChildColor(actionChild),
                            child: UnconstrainedBox(
                              constrainedAxis: Axis.vertical,
                              alignment: Alignment.centerLeft,
                              child: KeyedSubtree(
                                key: globalKey,
                                child: actionChild,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    itemWidth = currentActualWidth;
                    return _buildActionItemContainer(
                      width: itemWidth,
                      actionChild: actionChild,
                      globalKey: globalKey,
                    );
                  }
                },
                growable: false,
              ),
            ),
          ),
        );
      }
    }

    switch (widget.expandMode) {
      case SlideableCellExpandMode.everyItem:
        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: trailingWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(
                widget.trailingActions.length,
                (index) {
                  final double currentActualWidth = _trailingActionActualWidths[index];

                  /// 使用比例进行均分。
                  /// Distribute width proportionally.
                  final double itemWidth = totalActualWidth > 0
                      ? trailingWidth * (currentActualWidth / totalActualWidth)
                      : trailingWidth / widget.trailingActions.length;

                  final GlobalKey globalKey = _trailingActionKeys[index];
                  final Widget actionChild = widget.trailingActions[index];

                  return ClipRect(
                    child: _buildActionItemContainer(
                      width: itemWidth,
                      actionChild: actionChild,
                      globalKey: globalKey,
                    ),
                  );
                },
                growable: false,
              ),
            ),
          ),
        );

      case SlideableCellExpandMode.adjustEdge:
        final bool shouldUseProportionalWidth = totalActualWidth > 0 && trailingWidth > totalActualWidth;

        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: trailingWidth,
            child: OverflowBox(
              minWidth: trailingWidth,
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List<Widget>.generate(
                  widget.trailingActions.length,
                  (index) {
                    final GlobalKey globalKey = _trailingActionKeys[index];
                    final Widget actionChild = widget.trailingActions[index];

                    if (shouldUseProportionalWidth) {
                      final double currentActualWidth = _trailingActionActualWidths[index];
                      final double itemWidth = trailingWidth * (currentActualWidth / totalActualWidth);

                      return ClipRect(
                        child: _buildActionItemContainer(
                          width: itemWidth,
                          actionChild: actionChild,
                          globalKey: globalKey,
                        ),
                      );
                    } else {
                      return Container(
                        color: _getChildColor(actionChild),
                        child: KeyedSubtree(
                          key: globalKey,
                          child: actionChild,
                        ),
                      );
                    }
                  },
                  growable: false,
                ),
              ),
            ),
          ),
        );
    }
  }

  /// 构建前景 child，并绑定水平拖动手势。
  /// Builds foreground child with horizontal drag gestures.
  Widget _buildChild() {
    return Transform.translate(
      offset: Offset(_offset, 0),
      child: widget.child,
    );
  }
}

/// 控制器到 State 的内部回调入口。
/// Internal callback holder used by controller.
class _SlideableCellControllerEntry {
  Future<void> Function()? openLeading;
  Future<void> Function()? openTrailing;
  Future<void> Function()? close;
}
