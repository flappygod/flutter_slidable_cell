import 'package:flutter/material.dart';
import 'flutter_slidable_action_item.dart';
import 'flutter_slidable_base.dart';

/// 滑动 Cell 的控制器。
/// Controller for opening/closing slidable cells by [ValueKey].
class SlideableCellController {
  /// 当前的所有 entry。
  /// All registered entries.
  final Map<ValueKey, _SlideableCellControllerEntry> _entries = <ValueKey, _SlideableCellControllerEntry>{};

  /// 当前的所有状态缓存。
  /// All cached statuses.
  final Map<ValueKey, SlideableCellStatus> _statusMap = <ValueKey, SlideableCellStatus>{};

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
    return _findByValueKey(_statusMap, key) ?? SlideableCellStatus.closed;
  }

  /// 注册一个可控制的 Cell 实例。
  /// Registers a cell entry for controller operations.
  void _register(
    ValueKey key,
    _SlideableCellControllerEntry entry,
    SlideableCellStatus initialStatus,
  ) {
    _entries[key] = entry;
    _statusMap[key] = initialStatus;
  }

  /// 仅在 entry 与当前注册项一致时移除，避免误删。
  /// Unregister only when the entry matches current mapping.
  void _unregister(ValueKey key, _SlideableCellControllerEntry entry) {
    final current = _entries[key];
    if (identical(current, entry)) {
      _entries.remove(key);
      _statusMap.remove(key);
    }
  }

  /// 更新指定 key 对应 item 的状态缓存。
  /// Updates cached open/close status for an item key.
  void _updateStatus(ValueKey key, SlideableCellStatus status) {
    _statusMap[key] = status;
  }

  /// 获取指定 key 的当前状态，默认关闭。
  /// Returns current status for key, default is closed.
  SlideableCellStatus statusOf(ValueKey key) {
    return _findStatus(key);
  }

  /// 是否处于任一打开状态（左开或右开）。
  /// Whether the cell is currently opened on either side.
  bool isOpen(ValueKey key) {
    return _isOpenedStatus(statusOf(key));
  }

  /// 全量状态快照（只读）。
  /// Read-only snapshot for all item statuses.
  Map<ValueKey, SlideableCellStatus> get statuses {
    return Map<ValueKey, SlideableCellStatus>.unmodifiable(_statusMap);
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

  /// 是否为打开状态。
  /// Whether the status is opened.
  static bool _isOpenedStatus(SlideableCellStatus status) {
    return status == SlideableCellStatus.leadingOpen || status == SlideableCellStatus.trailingOpen;
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

  /// 最终展开的
  final SlideableExpandBehavior leadingFullExpandBehavior;

  /// 右侧是否可以全展开。
  /// Whether trailing side supports full expansion.
  final bool trailingFullExpandable;

  /// 右侧全展开额外触发距离。
  /// Extra distance to trigger trailing full expansion.
  final double trailingFullExpandExtra;

  /// 最终展开的
  final SlideableExpandBehavior trailingFullExpandBehavior;

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
    //左边
    this.leadingActions = const [],
    this.leadingFullExpandable = false,
    this.leadingFullExpandExtra = 60,
    this.leadingFullExpandBehavior = SlideableExpandBehavior.expand,
    //右边
    this.trailingActions = const [],
    this.trailingFullExpandable = false,
    this.trailingFullExpandExtra = 60,
    this.trailingFullExpandBehavior = SlideableExpandBehavior.expand,
    //打开的时候关闭其他的
    this.closeOthersWhenOpen = true,
    this.color = Colors.white,
    this.leadingExpandCurve = const Cubic(0.34, 0.84, 0.12, 1.00),
    this.leadingExpandDuration = const Duration(milliseconds: 500),
    this.trailingExpandCurve = const Cubic(0.34, 0.84, 0.12, 1.00),
    this.trailingExpandDuration = const Duration(milliseconds: 500),
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

  @override
  void initState() {
    super.initState();
    _initAnimationControllers();
    _recreateActionKeys();
    _resetActualWidthsCache();
    _bindController();
    _scheduleCollectActionWidths();
  }

  @override
  void didUpdateWidget(covariant SlideableCellView oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// action 数量变化时需要重建 key 和缓存；
    /// 即使数量不变，也仍然重新测量一次，兼容内容宽度变化。
    /// Recreate keys/cache when action counts change;
    /// even if counts stay the same, still re-measure to support width changes.
    if (oldWidget.leadingActions.length != widget.leadingActions.length ||
        oldWidget.trailingActions.length != widget.trailingActions.length) {
      _recreateActionKeys();
      _resetActualWidthsCache();
    }
    _scheduleCollectActionWidths();

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

  /// 初始化动画控制器。
  /// Initializes animation controllers.
  void _initAnimationControllers() {
    _snapAnimationController = AnimationController(vsync: this);

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
      reverseCurve: widget.leadingExpandCurve.flipped,
    );

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
      reverseCurve: widget.trailingExpandCurve.flipped,
    );

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

  /// 左侧 expand forward。
  /// Forward leading expand animation.
  void _forwardLeadingExpand() {
    if (_leadingForwarding == false) {
      _leadingForwarding = true;
      _expandLeadingController.forward(from: _expandLeadingController.value);
    }
  }

  /// 左侧 expand reverse。
  /// Reverse leading expand animation.
  void _reverseLeadingExpand() {
    if (_leadingForwarding == true) {
      _leadingForwarding = false;
      _expandLeadingController.reverse(from: _expandLeadingController.value);
    }
  }

  /// 右侧 expand forward。
  /// Forward trailing expand animation.
  void _forwardTrailingExpand() {
    if (_trailingForwarding == false) {
      _trailingForwarding = true;
      _expandTrailingController.forward(from: _expandTrailingController.value);
    }
  }

  /// 右侧 expand reverse。
  /// Reverse trailing expand animation.
  void _reverseTrailingExpand() {
    if (_trailingForwarding == true) {
      _trailingForwarding = false;
      _expandTrailingController.reverse(from: _expandTrailingController.value);
    }
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

  /// 按 action 数量重置宽度缓存。
  /// Resets width cache with action counts.
  void _resetActualWidthsCache() {
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
    final changedLeading = _collectWidthsFor(
      keys: _leadingActionKeys,
      widths: _leadingActionActualWidths,
    );
    final changedTrailing = _collectWidthsFor(
      keys: _trailingActionKeys,
      widths: _trailingActionActualWidths,
    );

    if ((changedLeading || changedTrailing) && mounted) {
      setState(() {});
    }
  }

  /// 收集一组 action 的实际宽度。
  /// Collects actual widths for a group of actions.
  bool _collectWidthsFor({
    required List<GlobalKey> keys,
    required List<double> widths,
  }) {
    var changed = false;
    for (var i = 0; i < keys.length; i++) {
      final width = _readWidth(keys[i]);
      if (width > 0 && widths[i] != width) {
        widths[i] = width;
        changed = true;
      }
    }
    return changed;
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

  /// 计算 leading 边缘 item 的额外 expandWidth。
  /// Calculates extra expandWidth for leading edge item.
  ///
  /// 规则：
  /// 其他 item 的实际宽度之和 * 动画参数。
  /// Rule:
  /// sum(other item actual widths) * animation value.
  double _computeLeadingEdgeExpandWidth({
    required int edgeIndex,
  }) {
    if (!widget.leadingFullExpandable) {
      return 0;
    }
    if (_expandLeadingAnimation.value <= 0) {
      return 0;
    }
    if (widget.leadingActions.isEmpty) {
      return 0;
    }

    double otherWidthSum = 0;
    for (int i = 0; i < widget.leadingActions.length; i++) {
      if (i == edgeIndex) {
        continue;
      }
      otherWidthSum += _leadingActionActualWidths[i];
    }
    return otherWidthSum * _expandLeadingAnimation.value;
  }

  /// 计算 leading 在 everyItem 模式下边缘 item 的额外 expandWidth。
  /// Calculates extra expandWidth for leading edge item in everyItem mode.
  ///
  /// 规则：
  /// 其他 item 的按比例宽度之和 * 动画参数。
  /// Rule:
  /// sum(other item proportional widths) * animation value.
  double _computeLeadingEveryItemExpandWidth({
    required int edgeIndex,
    required double leadingWidth,
    required double totalActualWidth,
  }) {
    if (!widget.leadingFullExpandable) {
      return 0;
    }
    if (_expandLeadingAnimation.value <= 0) {
      return 0;
    }
    if (widget.leadingActions.isEmpty) {
      return 0;
    }
    if (totalActualWidth <= 0) {
      return 0;
    }

    double otherWidthSum = 0;
    for (int i = 0; i < widget.leadingActions.length; i++) {
      if (i == edgeIndex) {
        continue;
      }
      otherWidthSum += leadingWidth * (_leadingActionActualWidths[i] / totalActualWidth);
    }
    return otherWidthSum * _expandLeadingAnimation.value;
  }

  /// 计算 trailing 边缘 item 的额外 expandWidth。
  /// Calculates extra expandWidth for trailing edge item.
  ///
  /// 规则：
  /// 其他 item 的实际宽度之和 * 动画参数。
  /// Rule:
  /// sum(other item actual widths) * animation value.
  double _computeTrailingEdgeExpandWidth({
    required int edgeIndex,
  }) {
    if (!widget.trailingFullExpandable) {
      return 0;
    }
    if (_expandTrailingAnimation.value <= 0) {
      return 0;
    }
    if (widget.trailingActions.isEmpty) {
      return 0;
    }

    double otherWidthSum = 0;
    for (int i = 0; i < widget.trailingActions.length; i++) {
      if (i == edgeIndex) {
        continue;
      }
      otherWidthSum += _trailingActionActualWidths[i];
    }
    return otherWidthSum * _expandTrailingAnimation.value;
  }

  /// 计算 trailing 在 everyItem 模式下边缘 item 的额外 expandWidth。
  /// Calculates extra expandWidth for trailing edge item in everyItem mode.
  ///
  /// 规则：
  /// 其他 item 的按比例宽度之和 * 动画参数。
  /// Rule:
  /// sum(other item proportional widths) * animation value.
  double _computeTrailingEveryItemExpandWidth({
    required int edgeIndex,
    required double trailingWidth,
    required double totalActualWidth,
  }) {
    if (!widget.trailingFullExpandable) {
      return 0;
    }
    if (_expandTrailingAnimation.value <= 0) {
      return 0;
    }
    if (widget.trailingActions.isEmpty) {
      return 0;
    }
    if (totalActualWidth <= 0) {
      return 0;
    }

    double otherWidthSum = 0;
    for (int i = 0; i < widget.trailingActions.length; i++) {
      if (i == edgeIndex) {
        continue;
      }
      otherWidthSum += trailingWidth * (_trailingActionActualWidths[i] / totalActualWidth);
    }
    return otherWidthSum * _expandTrailingAnimation.value;
  }

  /// 根据偏移量刷新控制器中的状态缓存。
  /// Syncs status cache in controller from current offset.
  ///
  /// 状态缓存只在动画落点完成后更新，
  /// 拖动中的中间态不写入 controller。
  /// Status cache is updated only after animation settles;
  /// intermediate dragging states are not written into controller.
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
  ///
  /// 每次按当前 offset 到目标值创建一次临时动画，
  /// 避免持有长期 tween 状态。
  /// Creates a temporary tween from current offset to target each time,
  /// avoiding long-lived tween state.
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
        _closeOtherOpenedCells(),
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

  /// 是否为打开状态。
  /// Whether the status is opened.
  bool _isOpenedStatus(SlideableCellStatus status) {
    return status == SlideableCellStatus.leadingOpen || status == SlideableCellStatus.trailingOpen;
  }

  /// 是否为 leading 边缘 item。
  /// Whether the index is the leading edge item.
  bool _isLeadingEdgeIndex(int index) {
    return index == widget.leadingActions.length - 1;
  }

  /// 是否为 trailing 边缘 item。
  /// Whether the index is the trailing edge item.
  bool _isTrailingEdgeIndex(int index) {
    return index == widget.trailingActions.length - 1;
  }

  /// 按比例计算 item 宽度。
  /// Calculates proportional item width.
  double _proportionalWidth({
    required double visibleWidth,
    required double currentActualWidth,
    required double totalActualWidth,
    required int itemCount,
  }) {
    return totalActualWidth > 0 ? visibleWidth * (currentActualWidth / totalActualWidth) : visibleWidth / itemCount;
  }

  /// 关闭其他已打开的 items。
  /// Closes other opened items.
  Future<void> _closeOtherOpenedCells() async {
    final statusEntries = widget.controller.statuses.entries.toList(growable: false);
    final futures = <Future<void>>[];

    for (final entry in statusEntries) {
      final bool isCurrentCell = _sameCellKey(entry.key, widget.cellKey);
      final bool isOpened = _isOpenedStatus(entry.value);

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

    if (_offset > 0 && leadingWidth > 0 && _offset > leadingWidth) {
      await _animateToLeadingOpen();
      return;
    }

    if (_offset < 0 && trailingWidth > 0 && (-_offset) > trailingWidth) {
      await _animateToTrailingOpen();
      return;
    }

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
  Color? _getChildColor(Widget child) => child is SlideableActionItem ? child.slideBackgroundColor : null;

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

  /// 构建可扩展边缘 item。
  /// Builds an expandable edge item.
  Widget _buildExpandableEdgeItem({
    required double viewportWidth,
    required double contentWidth,
    required double overflowMaxWidth,
    required Widget actionChild,
    required GlobalKey globalKey,
    required Alignment alignment,
    Offset offset = Offset.zero,
    CustomClipper<Rect>? clipper,
  }) {
    Widget child = SizedBox(
      width: viewportWidth,
      child: OverflowBox(
        minWidth: viewportWidth,
        maxWidth: overflowMaxWidth,
        alignment: alignment,
        child: Container(
          width: contentWidth,
          color: _getChildColor(actionChild),
          child: UnconstrainedBox(
            constrainedAxis: Axis.vertical,
            alignment: alignment,
            child: KeyedSubtree(
              key: globalKey,
              child: actionChild,
            ),
          ),
        ),
      ),
    );

    if (clipper != null) {
      child = ClipRect(
        clipper: clipper,
        child: child,
      );
    }

    if (offset != Offset.zero) {
      child = Transform.translate(
        offset: offset,
        child: child,
      );
    }

    return child;
  }

  /// 构建左侧 actions 区域。
  /// Builds leading action area.
  Widget _buildLeading() {
    if (widget.leadingActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final double leadingWidth = _offset.clamp(0.0, double.infinity);
    final double totalActualWidth = _leadingActualTotalWidth;

    if (widget.leadingFullExpandable) {
      if (leadingWidth > totalActualWidth + widget.leadingFullExpandExtra) {
        _forwardLeadingExpand();
      } else {
        _reverseLeadingExpand();
      }

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

                  if (_isLeadingEdgeIndex(index)) {
                    final double dragWidth = leadingWidth - totalActualWidth;
                    final double expandWidth = (totalActualWidth - currentActualWidth) * _expandLeadingAnimation.value;
                    final double itemWidth = dragWidth + currentActualWidth;

                    switch (widget.expandMode) {
                      case SlideableCellExpandMode.adjustEdge:
                        return _buildExpandableEdgeItem(
                          viewportWidth: itemWidth,
                          contentWidth: itemWidth + expandWidth,
                          overflowMaxWidth: itemWidth + expandWidth,
                          actionChild: actionChild,
                          globalKey: globalKey,
                          alignment: Alignment.centerRight,
                          offset: Offset(expandWidth, 0),
                        );
                      case SlideableCellExpandMode.everyItem:
                        return _buildExpandableEdgeItem(
                          viewportWidth: itemWidth,
                          contentWidth: itemWidth + expandWidth,
                          overflowMaxWidth: itemWidth + expandWidth,
                          actionChild: actionChild,
                          globalKey: globalKey,
                          alignment: Alignment.center,
                          offset: Offset(expandWidth / 2, 0),
                        );
                    }
                  }

                  return _buildActionItemContainer(
                    width: currentActualWidth,
                    actionChild: actionChild,
                    globalKey: globalKey,
                  );
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
                  final double itemWidth = _proportionalWidth(
                    visibleWidth: leadingWidth,
                    currentActualWidth: currentActualWidth,
                    totalActualWidth: totalActualWidth,
                    itemCount: widget.leadingActions.length,
                  );

                  final GlobalKey globalKey = _leadingActionKeys[index];
                  final Widget actionChild = widget.leadingActions[index];

                  /// 在 everyItem 模式下，如果 full-expand 动画仍在进行，
                  /// 对边缘 item 做平滑过渡，避免从 full-expand 回落时出现跳变。
                  /// In everyItem mode, keep smooth transition for the edge item
                  /// while full-expand animation is still active.
                  if (widget.leadingFullExpandable && _isLeadingEdgeIndex(index)) {
                    final double expandWidth = _computeLeadingEveryItemExpandWidth(
                      edgeIndex: index,
                      leadingWidth: leadingWidth,
                      totalActualWidth: totalActualWidth,
                    );

                    return _buildExpandableEdgeItem(
                      viewportWidth: itemWidth,
                      contentWidth: currentActualWidth + expandWidth,
                      overflowMaxWidth: currentActualWidth + expandWidth,
                      actionChild: actionChild,
                      globalKey: globalKey,
                      alignment: Alignment.center,
                      offset: Offset(expandWidth / 2, 0),
                      clipper: ClipHorizontalRect(
                        clipLeft: -(expandWidth / 2),
                        clipRight: -(expandWidth / 2),
                      ),
                    );
                  }

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
                    }

                    if (widget.leadingFullExpandable && _isLeadingEdgeIndex(index)) {
                      final double itemWidth = _leadingActionActualWidths[index];
                      final double expandWidth = _computeLeadingEdgeExpandWidth(
                        edgeIndex: index,
                      );
                      return _buildExpandableEdgeItem(
                        viewportWidth: itemWidth,
                        contentWidth: itemWidth + expandWidth,
                        overflowMaxWidth: itemWidth + expandWidth,
                        actionChild: actionChild,
                        globalKey: globalKey,
                        alignment: Alignment.centerRight,
                        offset: Offset(expandWidth, 0),
                      );
                    }
                    return Container(
                      color: _getChildColor(actionChild),
                      child: KeyedSubtree(
                        key: globalKey,
                        child: actionChild,
                      ),
                    );
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

    double trailingWidth = _offset < 0 ? -_offset : 0.0;
    trailingWidth = trailingWidth.clamp(0.0, double.infinity);

    final double totalActualWidth = _trailingActualTotalWidth;

    if (widget.trailingFullExpandable) {
      if (trailingWidth > totalActualWidth + widget.trailingFullExpandExtra) {
        _forwardTrailingExpand();
      } else {
        _reverseTrailingExpand();
      }

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

                  if (_isTrailingEdgeIndex(index)) {
                    final double dragWidth = trailingWidth - totalActualWidth;
                    final double expandWidth = (totalActualWidth - currentActualWidth) * _expandTrailingAnimation.value;
                    final double itemWidth = dragWidth + currentActualWidth;

                    switch (widget.expandMode) {
                      case SlideableCellExpandMode.adjustEdge:
                        return _buildExpandableEdgeItem(
                          viewportWidth: itemWidth,
                          contentWidth: itemWidth + expandWidth,
                          overflowMaxWidth: itemWidth + expandWidth,
                          actionChild: actionChild,
                          globalKey: globalKey,
                          alignment: Alignment.centerLeft,
                          offset: Offset(-expandWidth, 0),
                        );
                      case SlideableCellExpandMode.everyItem:
                        return _buildExpandableEdgeItem(
                          viewportWidth: itemWidth,
                          contentWidth: itemWidth + expandWidth,
                          overflowMaxWidth: itemWidth + expandWidth,
                          actionChild: actionChild,
                          globalKey: globalKey,
                          alignment: Alignment.center,
                          offset: Offset(-expandWidth / 2, 0),
                        );
                    }
                  }

                  return _buildActionItemContainer(
                    width: currentActualWidth,
                    actionChild: actionChild,
                    globalKey: globalKey,
                  );
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
                  final double itemWidth = _proportionalWidth(
                    visibleWidth: trailingWidth,
                    currentActualWidth: currentActualWidth,
                    totalActualWidth: totalActualWidth,
                    itemCount: widget.trailingActions.length,
                  );

                  final GlobalKey globalKey = _trailingActionKeys[index];
                  final Widget actionChild = widget.trailingActions[index];

                  /// 在 everyItem 模式下，如果 full-expand 动画仍在进行，
                  /// 对边缘 item 做平滑过渡，避免从 full-expand 回落时出现跳变。
                  /// In everyItem mode, keep smooth transition for the edge item
                  /// while full-expand animation is still active.
                  if (widget.trailingFullExpandable && _isTrailingEdgeIndex(index)) {
                    final double expandWidth = _computeTrailingEveryItemExpandWidth(
                      edgeIndex: index,
                      trailingWidth: trailingWidth,
                      totalActualWidth: totalActualWidth,
                    );

                    return _buildExpandableEdgeItem(
                      viewportWidth: itemWidth,
                      contentWidth: currentActualWidth + expandWidth,
                      overflowMaxWidth: currentActualWidth + expandWidth,
                      actionChild: actionChild,
                      globalKey: globalKey,
                      alignment: Alignment.center,
                      offset: Offset(-expandWidth / 2, 0),
                      clipper: ClipHorizontalRect(
                        clipLeft: -(expandWidth / 2),
                        clipRight: -(expandWidth / 2),
                      ),
                    );
                  }

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
                    }

                    if (widget.trailingFullExpandable && _isTrailingEdgeIndex(index)) {
                      final double itemWidth = _trailingActionActualWidths[index];
                      final double expandWidth = _computeTrailingEdgeExpandWidth(
                        edgeIndex: index,
                      );

                      return _buildExpandableEdgeItem(
                        viewportWidth: itemWidth,
                        contentWidth: itemWidth + expandWidth,
                        overflowMaxWidth: itemWidth + expandWidth,
                        actionChild: actionChild,
                        globalKey: globalKey,
                        alignment: Alignment.centerLeft,
                        offset: Offset(-expandWidth, 0),
                      );
                    }

                    return Container(
                      color: _getChildColor(actionChild),
                      child: KeyedSubtree(
                        key: globalKey,
                        child: actionChild,
                      ),
                    );
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
