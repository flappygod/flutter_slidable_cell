import 'package:flutter/material.dart';
import 'flutter_slideable_action_item.dart';
import 'flutter_slideable_base.dart';

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

  /// 打开左方（普通宽度）。
  /// Opens leading side at normal width.
  Future<void> openLeading(ValueKey key) async {
    await _findEntry(key)?.openLeading.call();
  }

  /// 打开右方（普通宽度）。
  /// Opens trailing side at normal width.
  Future<void> openTrailing(ValueKey key) async {
    await _findEntry(key)?.openTrailing.call();
  }

  /// 左侧完全展开（落到父容器宽度）。
  /// Fully expands the leading side to parent width.
  Future<void> openLeadingFullExpand(ValueKey key) async {
    await _findEntry(key)?.openLeadingFullExpand.call();
  }

  /// 右侧完全展开（落到父容器宽度）。
  /// Fully expands the trailing side to parent width.
  Future<void> openTrailingFullExpand(ValueKey key) async {
    await _findEntry(key)?.openTrailingFullExpand.call();
  }

  /// 关闭 Cell。
  /// Closes a cell.
  Future<void> closeCell(ValueKey key) async {
    await _findEntry(key)?.close.call();
  }

  /// 关闭所有的 item。
  /// Closes all cells.
  ///
  /// 注意：状态缓存会在每个 cell 的关闭动画完成后才回写，
  /// 调用方紧接着读 [statuses] / [statusOf] 仍可能看到旧值。
  /// Note: status cache is updated after each cell's close animation completes,
  /// so reading [statuses] / [statusOf] right after this call may still
  /// reflect the previous values until animations finish.
  Future<void> closeAllCells() async {
    final futures = _entries.values.map((entry) => entry.close()).toList(growable: false);
    await Future.wait<void>(futures);
  }

  /// 是否为打开状态（普通打开或完全展开都算）。
  /// Whether the status is opened (normal open or fully expanded).
  static bool _isOpenedStatus(SlideableCellStatus status) {
    return status != SlideableCellStatus.closed;
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

  /// 左侧全展开额外触发距离（基于 leading 实际总宽度）。
  /// Extra distance (added to leading total width) to trigger leading full expansion.
  final double leadingFullExpandExtra;

  /// 全展开触发后的最终行为：
  /// - [SlideableExpandBehavior.expand] 完全展开到父容器宽度；
  /// - [SlideableExpandBehavior.close] 直接关闭；
  /// - [SlideableExpandBehavior.open] 回到普通打开宽度。
  /// Final behavior after leading full expand is triggered.
  final SlideableExpandBehavior leadingFullExpandBehavior;

  /// leading 侧手势抬起且命中全展开阈值时的回调，
  /// 参数为本次实际生效的 [SlideableExpandBehavior]。
  /// 注意：通过 controller 调用 [SlideableCellController.openLeadingFullExpand]
  /// 不会触发该回调。
  /// Fired when the gesture ends past the leading full-expand threshold.
  /// The parameter carries the [SlideableExpandBehavior] that took effect.
  /// Note: programmatic calls to
  /// [SlideableCellController.openLeadingFullExpand] do not trigger this.
  final void Function(SlideableExpandBehavior behavior)? onLeadingFullExpand;

  /// 右侧是否可以全展开。
  /// Whether trailing side supports full expansion.
  final bool trailingFullExpandable;

  /// 右侧全展开额外触发距离（基于 trailing 实际总宽度）。
  /// Extra distance (added to trailing total width) to trigger trailing full expansion.
  final double trailingFullExpandExtra;

  /// 全展开触发后的最终行为，含义同 [leadingFullExpandBehavior]。
  /// Final behavior after trailing full expand is triggered.
  final SlideableExpandBehavior trailingFullExpandBehavior;

  /// trailing 侧手势抬起且命中全展开阈值时的回调，
  /// 参数为本次实际生效的 [SlideableExpandBehavior]。
  /// 注意：通过 controller 调用 [SlideableCellController.openTrailingFullExpand]
  /// 不会触发该回调。
  /// Fired when the gesture ends past the trailing full-expand threshold.
  /// The parameter carries the [SlideableExpandBehavior] that took effect.
  /// Note: programmatic calls to
  /// [SlideableCellController.openTrailingFullExpand] do not trigger this.
  final void Function(SlideableExpandBehavior behavior)? onTrailingFullExpand;

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
    this.openFactor = 0.25,
    this.closeFactor = 0.25,
    this.curve = const Cubic(0.34, 0.84, 0.12, 1.00),
    this.duration = const Duration(milliseconds: 500),
    //左边
    this.leadingActions = const [],
    this.leadingFullExpandable = false,
    this.leadingFullExpandExtra = 25,
    this.leadingFullExpandBehavior = SlideableExpandBehavior.expand,
    this.onLeadingFullExpand,
    //右边
    this.trailingActions = const [],
    this.trailingFullExpandable = false,
    this.trailingFullExpandExtra = 25,
    this.trailingFullExpandBehavior = SlideableExpandBehavior.expand,
    this.onTrailingFullExpand,
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

  /// 缓存的 snap 曲线 tween，可在 didUpdateWidget 改 curve 时直接替换。
  /// Cached snap curve tween, swappable when widget.curve changes.
  late CurveTween _snapCurveTween;

  /// 当前 snap 动画的起止 tween，每次 _animateTo 时复用同一对象。
  /// Reusable begin/end tween for the snap animation.
  final Tween<double> _snapValueTween = Tween<double>(begin: 0, end: 0);

  /// 当前前景偏移量。
  /// Current horizontal offset of foreground child.
  double _offset = 0;

  /// 父容器宽度（由 LayoutBuilder 提供），用于计算最大拖动距离与全展开目标。
  /// Parent width supplied by LayoutBuilder; used for max drag distance and full-expand target.
  double _parentWidth = 0;

  /// 每个 action 的测量 key。
  /// Keys for measuring actual width of each action.
  late List<GlobalKey> _leadingActionKeys;
  late List<GlobalKey> _trailingActionKeys;

  /// 每个 action 的实际宽度缓存。
  /// Cached actual width for every action widget.
  final List<double> _leadingActionActualWidths = <double>[];
  final List<double> _trailingActionActualWidths = <double>[];

  /// 控制器桥接入口（在构造期一次性绑定）。
  /// Bridge entry used by controller to trigger state animations.
  late final _SlideableCellControllerEntry _controllerEntry = _SlideableCellControllerEntry(
    openLeading: _animateToLeadingOpen,
    openTrailing: _animateToTrailingOpen,
    openLeadingFullExpand: _animateToLeadingFullExpand,
    openTrailingFullExpand: _animateToTrailingFullExpand,
    close: _animateToClosed,
  );

  /// 当前开关状态。
  /// Current open/close status.
  SlideableCellStatus _status = SlideableCellStatus.closed;

  /// 左侧扩展动画控制器。
  /// Leading expand animation controller.
  late AnimationController _expandLeadingController;

  /// 左侧扩展动画。
  /// Leading expand animation.
  late CurvedAnimation _expandLeadingAnimation;

  /// 右侧扩展动画控制器。
  /// Trailing expand animation controller.
  late AnimationController _expandTrailingController;

  /// 右侧扩展动画。
  /// Trailing expand animation.
  late CurvedAnimation _expandTrailingAnimation;

  /// 是否已经安排了宽度收集任务。
  /// Whether width collection has been scheduled.
  bool _widthCollectScheduled = false;

  @override
  void initState() {
    super.initState();
    _initAnimationControllers();
    _recreateActionKeys();
    _resetActualWidthsCache();
    widget.controller._register(widget.cellKey, _controllerEntry, _status);
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

    /// 同步 snap 曲线（duration 在 _animateTo 中按需赋值，无需此处同步）。
    /// Sync snap curve (duration is reassigned per animation in _animateTo).
    if (oldWidget.curve != widget.curve) {
      _snapCurveTween = CurveTween(curve: widget.curve);
    }

    /// 同步 leading expand 动画配置。
    /// Sync leading expand animation configuration.
    if (oldWidget.leadingExpandDuration != widget.leadingExpandDuration) {
      _expandLeadingController.duration = widget.leadingExpandDuration;
      _expandLeadingController.reverseDuration = widget.leadingExpandDuration;
    }
    if (oldWidget.leadingExpandCurve != widget.leadingExpandCurve) {
      _expandLeadingAnimation.dispose();
      _expandLeadingAnimation = CurvedAnimation(
        parent: _expandLeadingController,
        curve: widget.leadingExpandCurve,
        reverseCurve: widget.leadingExpandCurve.flipped,
      );
    }

    /// 同步 trailing expand 动画配置。
    /// Sync trailing expand animation configuration.
    if (oldWidget.trailingExpandDuration != widget.trailingExpandDuration) {
      _expandTrailingController.duration = widget.trailingExpandDuration;
      _expandTrailingController.reverseDuration = widget.trailingExpandDuration;
    }
    if (oldWidget.trailingExpandCurve != widget.trailingExpandCurve) {
      _expandTrailingAnimation.dispose();
      _expandTrailingAnimation = CurvedAnimation(
        parent: _expandTrailingController,
        curve: widget.trailingExpandCurve,
        reverseCurve: widget.trailingExpandCurve.flipped,
      );
    }

    /// 重新绑定 key 或 controller。
    /// Rebind when key or controller changes.
    if (oldWidget.cellKey != widget.cellKey || oldWidget.controller != widget.controller) {
      oldWidget.controller._unregister(oldWidget.cellKey, _controllerEntry);
      widget.controller._register(widget.cellKey, _controllerEntry, _status);
    }
  }

  @override
  void dispose() {
    widget.controller._unregister(widget.cellKey, _controllerEntry);
    _snapAnimationController.removeListener(_onSnapTick);
    _snapAnimationController.dispose();
    _expandLeadingAnimation.dispose();
    _expandLeadingController.dispose();
    _expandTrailingAnimation.dispose();
    _expandTrailingController.dispose();
    super.dispose();
  }

  /// 初始化动画控制器。
  /// Initializes animation controllers.
  void _initAnimationControllers() {
    _snapAnimationController = AnimationController(vsync: this);
    _snapCurveTween = CurveTween(curve: widget.curve);
    _snapAnimationController.addListener(_onSnapTick);

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

  /// snap 动画每帧回调：根据 controller.value 解算出当前 offset。
  /// Per-frame snap callback: derives offset from controller.value.
  void _onSnapTick() {
    if (!mounted) {
      return;
    }
    final double t = _snapCurveTween.transform(_snapAnimationController.value);
    final double next = _snapValueTween.transform(t);
    if (next == _offset) {
      return;
    }
    setState(() {
      _offset = next;
    });
    _syncExpandAnimations();
  }

  /// 根据当前 offset 推动 leading / trailing 的全展开动画。
  /// Drives leading / trailing full-expand animations based on current offset.
  ///
  /// 拆出 build 之外触发，避免在 build 中产生副作用。
  /// Triggered outside build to avoid side effects during build.
  void _syncExpandAnimations() {
    if (widget.leadingFullExpandable) {
      final double leadingWidth = _offset > 0 ? _offset : 0.0;
      if (leadingWidth > _leadingActualTotalWidth + widget.leadingFullExpandExtra) {
        _forwardExpand(_expandLeadingController);
      } else {
        _reverseExpand(_expandLeadingController);
      }
    }
    if (widget.trailingFullExpandable) {
      final double trailingWidth = _offset < 0 ? -_offset : 0.0;
      if (trailingWidth > _trailingActualTotalWidth + widget.trailingFullExpandExtra) {
        _forwardExpand(_expandTrailingController);
      } else {
        _reverseExpand(_expandTrailingController);
      }
    }
  }

  /// 通过 [AnimationStatus] 判断是否需要 forward，避免重复调用。
  /// Use [AnimationStatus] to avoid redundant forward() calls.
  void _forwardExpand(AnimationController controller) {
    final s = controller.status;
    if (s == AnimationStatus.forward || s == AnimationStatus.completed) {
      return;
    }
    controller.forward(from: controller.value);
  }

  /// 通过 [AnimationStatus] 判断是否需要 reverse，避免重复调用。
  /// Use [AnimationStatus] to avoid redundant reverse() calls.
  void _reverseExpand(AnimationController controller) {
    final s = controller.status;
    if (s == AnimationStatus.reverse || s == AnimationStatus.dismissed) {
      return;
    }
    controller.reverse(from: controller.value);
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
  /// 通过缓存的 [_snapValueTween] / [_snapCurveTween] / [_snapAnimationController]
  /// 复用对象，避免每次都创建 [CurvedAnimation] 而泄漏 listener。
  /// Reuses cached tween / curve / controller objects so that no new
  /// [CurvedAnimation] (and therefore no leaked listener) is created per call.
  Future<void> _animateTo(double target, {SlideableCellStatus? finalStatus}) async {
    if (!mounted) {
      return;
    }

    _snapAnimationController.stop();
    _snapAnimationController.duration = widget.duration;
    _snapValueTween
      ..begin = _offset
      ..end = target;

    bool completed = false;
    try {
      await _snapAnimationController.forward(from: 0);
      completed = true;
    } on TickerCanceled {
      // 动画被新的 _animateTo 或 dispose 打断时跳过收尾，
      // 避免把 _offset 强制写到一个已被取消的 target。
      // Skip finalization when interrupted by another _animateTo / dispose,
      // so that _offset is not forced to a target whose animation was canceled.
    }

    if (!mounted || !completed) {
      return;
    }

    setState(() {
      _offset = target;
    });
    _syncExpandAnimations();

    if (finalStatus != null) {
      _setStatus(finalStatus);
    } else {
      _updateStatusByOffset();
    }
  }

  /// 动画打开左侧。
  /// Animate to leading-open position.
  Future<void> _animateToLeadingOpen() {
    return _openTo(
      target: _leadingActualTotalWidth,
      status: SlideableCellStatus.leadingOpen,
    );
  }

  /// 动画打开右侧。
  /// Animate to trailing-open position.
  Future<void> _animateToTrailingOpen() {
    return _openTo(
      target: -_trailingActualTotalWidth,
      status: SlideableCellStatus.trailingOpen,
    );
  }

  /// 动画到 leading 完全展开（父容器宽度）。
  /// Animate to leading full-expand position (parent width).
  Future<void> _animateToLeadingFullExpand() {
    return _openTo(
      target: _resolvedParentWidth,
      status: SlideableCellStatus.leadingFullExpanded,
    );
  }

  /// 动画到 trailing 完全展开（父容器宽度）。
  /// Animate to trailing full-expand position (parent width).
  Future<void> _animateToTrailingFullExpand() {
    return _openTo(
      target: -_resolvedParentWidth,
      status: SlideableCellStatus.trailingFullExpanded,
    );
  }

  /// 动画关闭。
  /// Animate to closed position.
  Future<void> _animateToClosed() {
    return _animateTo(0, finalStatus: SlideableCellStatus.closed);
  }

  /// 打开到指定的位置，并按需关闭其他已打开的 cell。
  /// Opens to target offset, optionally closing other opened cells in parallel.
  Future<void> _openTo({
    required double target,
    required SlideableCellStatus status,
  }) async {
    if (widget.closeOthersWhenOpen) {
      await Future.wait([
        _closeOtherOpenedCells(),
        _animateTo(target, finalStatus: status),
      ]);
    } else {
      await _animateTo(target, finalStatus: status);
    }
  }

  /// 父容器宽度（fallback 到 MediaQuery）。
  /// Parent width with MediaQuery fallback.
  double get _resolvedParentWidth {
    if (_parentWidth > 0) {
      return _parentWidth;
    }
    return MediaQuery.sizeOf(context).width;
  }

  /// 显式设置状态并同步到 controller。
  /// Sets status explicitly and syncs to controller.
  void _setStatus(SlideableCellStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    widget.controller._updateStatus(widget.cellKey, _status);
  }

  /// 判断两个 ValueKey 是否表示同一个业务 cell。
  /// Checks whether two ValueKeys represent the same business cell.
  bool _sameCellKey(ValueKey a, ValueKey b) {
    return a.value == b.value;
  }

  /// 是否为打开状态（含完全展开）。
  /// Whether the status is opened (full-expanded counts as open).
  bool _isOpenedStatus(SlideableCellStatus status) {
    return status != SlideableCellStatus.closed;
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
    _syncExpandAnimations();
  }

  /// 手势结束阈值判定：
  /// 关闭态使用 [openFactor]，打开态使用 [closeFactor]。
  /// Gesture-end threshold decision:
  /// uses [openFactor] from closed state and [closeFactor] from opened state.
  Future<void> _onHorizontalDragEnd(DragEndDetails details) async {
    final leadingWidth = _leadingActualTotalWidth;
    final trailingWidth = _trailingActualTotalWidth;

    /// 优先判断 leading 全展开触发：
    /// 当拖动距离 > leadingWidth + leadingFullExpandExtra 时，
    /// 根据 leadingFullExpandBehavior 分别走 expand / close / open。
    /// Leading full-expand trigger has highest priority:
    /// when drag distance > leadingWidth + leadingFullExpandExtra,
    /// dispatch by leadingFullExpandBehavior (expand / close / open).
    if (widget.leadingFullExpandable &&
        _offset > 0 &&
        leadingWidth > 0 &&
        _offset > leadingWidth + widget.leadingFullExpandExtra) {
      final behavior = widget.leadingFullExpandBehavior;
      widget.onLeadingFullExpand?.call(behavior);
      switch (behavior) {
        case SlideableExpandBehavior.expand:
          await _animateToLeadingFullExpand();
          return;
        case SlideableExpandBehavior.close:
          await _animateToClosed();
          return;
        case SlideableExpandBehavior.open:
          await _animateToLeadingOpen();
          return;
      }
    }

    /// 优先判断 trailing 全展开触发，规则与 leading 对称。
    /// Trailing full-expand trigger, symmetric to leading.
    if (widget.trailingFullExpandable &&
        _offset < 0 &&
        trailingWidth > 0 &&
        (-_offset) > trailingWidth + widget.trailingFullExpandExtra) {
      final behavior = widget.trailingFullExpandBehavior;
      widget.onTrailingFullExpand?.call(behavior);
      switch (behavior) {
        case SlideableExpandBehavior.expand:
          await _animateToTrailingFullExpand();
          return;
        case SlideableExpandBehavior.close:
          await _animateToClosed();
          return;
        case SlideableExpandBehavior.open:
          await _animateToTrailingOpen();
          return;
      }
    }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        /// 用 LayoutBuilder 取父容器宽度，避免 MediaQuery 在嵌套场景下不准。
        /// Use LayoutBuilder to get parent width; MediaQuery may be inaccurate in nested layouts.
        final double resolved = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        if (resolved != _parentWidth) {
          _parentWidth = resolved;
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Container(
            color: widget.color,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                _buildChild(),
                _buildLeading(),
                _buildTrailing(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 最大的 drag 宽度。
  /// Maximum drag distance.
  ///
  /// 取 action 实际总宽度与父容器宽度中的较大值，
  /// 以便宿主比 action 总宽度更宽时仍允许拖到全展开位置。
  /// Returns max(actualTotalWidth, parentWidth) so that the cell can still
  /// be dragged to the full-expand position when the host is wider than
  /// the actions.
  double _maxDragDistance(double actualTotalWidth) {
    final double parent = _resolvedParentWidth;
    return actualTotalWidth > parent ? actualTotalWidth : parent;
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
      if (leadingWidth > totalActualWidth) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: leadingWidth,
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    return _buildActionItemContainer(
                      width: _leadingActionActualWidths[index],
                      actionChild: actionChild,
                      globalKey: globalKey,
                      alignment: Alignment.centerRight,
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
      if (trailingWidth > totalActualWidth) {
        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: trailingWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

                    return _buildActionItemContainer(
                      width: _trailingActionActualWidths[index],
                      actionChild: actionChild,
                      globalKey: globalKey,
                      alignment: Alignment.centerLeft,
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
///
/// 三个回调在 State 构造期就一次性注入，不再可空，
/// 避免运行期被遗漏赋值或被外部清空。
/// All three callbacks are injected at State construction and are non-null,
/// so the controller never has to worry about missing wiring at runtime.
class _SlideableCellControllerEntry {
  _SlideableCellControllerEntry({
    required this.openLeading,
    required this.openTrailing,
    required this.openLeadingFullExpand,
    required this.openTrailingFullExpand,
    required this.close,
  });

  final Future<void> Function() openLeading;
  final Future<void> Function() openTrailing;
  final Future<void> Function() openLeadingFullExpand;
  final Future<void> Function() openTrailingFullExpand;
  final Future<void> Function() close;
}
