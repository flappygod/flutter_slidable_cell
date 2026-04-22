import 'package:flutter/material.dart';
import 'flutter_slidable_action_item.dart';
import 'flutter_slidable_base.dart';

/// 滑动 Cell 的控制器。
/// Controller for opening/closing slidable cells by [ValueKey].
class SlideableCellController {
  ///找到相应的entry
  _SlideableCellControllerEntry? _findEntry(ValueKey key) {
    //先直接找
    final direct = _entries[key];
    if (direct != null) {
      return direct;
    }
    //再通过值找
    for (final item in _entries.entries) {
      if (item.key.value == key.value) {
        return item.value;
      }
    }
    return null;
  }

  ///找到相应的状态
  SlideableCellStatus _findStatus(ValueKey key) {
    //先直接找
    final direct = _status[key];
    if (direct != null) {
      return direct;
    }
    //再通过值找
    for (final item in _status.entries) {
      if (item.key.value == key.value) {
        return item.value;
      }
    }
    return SlideableCellStatus.closed;
  }

  /// 当前的所有的entry
  final Map<ValueKey, _SlideableCellControllerEntry> _entries = <ValueKey, _SlideableCellControllerEntry>{};

  /// 当前的所有的status
  final Map<ValueKey, SlideableCellStatus> _status = <ValueKey, SlideableCellStatus>{};

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
    final status = _status[key];
    return status == SlideableCellStatus.leadingOpen || status == SlideableCellStatus.trailingOpen;
  }

  /// 全量状态快照（只读）。
  /// Read-only snapshot for all item statuses.
  Map<ValueKey, SlideableCellStatus> get statuses {
    return Map<ValueKey, SlideableCellStatus>.unmodifiable(_status);
  }

  ///打开左方
  Future<void> openLeading(ValueKey key) async {
    await _findEntry(key)?.openLeading?.call();
  }

  ///打开右方
  Future<void> openTrailing(ValueKey key) async {
    await _findEntry(key)?.openTrailing?.call();
  }

  ///关闭Cell
  Future<void> closeCell(ValueKey key) async {
    await _findEntry(key)?.close?.call();
  }

  ///关闭所有的item
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

  ///左侧是否可以全展开
  final bool leadingFullExpandable;
  final double leadingFullExpandExtra;

  ///右侧是否可以全展开
  final bool trailingFullExpandable;
  final double trailingFullExpandExtra;

  ///背景颜色
  final Color color;

  ///打开自己的时候关闭其他的item
  final bool closeOthersWhenOpen;

  ///左边expand curve
  final Curve leadingExpandCurve;

  ///左边expand duration
  final Duration leadingExpandDuration;

  ///右边expand curve
  final Curve trailingExpandCurve;

  ///右边expand duration
  final Duration trailingExpandDuration;

  const SlideableCellView({
    required super.key,
    required this.controller,
    required this.child,
    this.expandMode = SlideableCellExpandMode.adjustEdge,
    this.openFactor = 0.3,
    this.closeFactor = 0.3,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 380),
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.leadingFullExpandable = false,
    this.trailingFullExpandable = false,
    this.leadingFullExpandExtra = 60,
    this.trailingFullExpandExtra = 60,
    this.closeOthersWhenOpen = true,
    this.color = Colors.white,
    this.leadingExpandCurve = Curves.linear,
    this.leadingExpandDuration = const Duration(milliseconds: 200),
    this.trailingExpandCurve = Curves.linear,
    this.trailingExpandDuration = const Duration(milliseconds: 200),
  });

  @override
  State<StatefulWidget> createState() {
    return _SlideableCellViewState();
  }

  /// 当前 cell 的业务 key，约定必须使用 [ValueKey]。
  /// Business key for controller mapping. Must be a [ValueKey].
  ValueKey get cellKey {
    final currentKey = key;
    if (currentKey is ValueKey) {
      return currentKey;
    }
    throw FlutterError(
      'SlideableCellView.key 必须是 ValueKey，'
      '例如 ValueKey("message_1")。',
    );
  }
}

/// [SlideableCellView] 的状态实现。
/// Internal state implementation for [SlideableCellView].
class _SlideableCellViewState extends State<SlideableCellView> with TickerProviderStateMixin {
  /// 回弹的控制器
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

  /// 扩展的leading controller
  late AnimationController _expandLeadingController;
  late Animation<double> _expandLeadingAnimation;
  bool _leadingForwarding = false;

  /// 扩展的training controller
  late AnimationController _expandTrainingController;
  late Animation<double> _expandTrainingAnimation;
  bool _trainingForwarding = false;

  ///初始化控制器
  void _initController() {
    _snapAnimationController = AnimationController(vsync: this);

    ///头部动画控制
    _expandLeadingController = AnimationController(
      vsync: this,
      duration: widget.leadingExpandDuration,
      reverseDuration: widget.leadingExpandDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _expandLeadingAnimation = CurvedAnimation(
      parent: _expandLeadingController,
      curve: Curves.easeInOut,
    );

    ///尾部动画控制
    _expandTrainingController = AnimationController(
      vsync: this,
      duration: widget.trailingExpandDuration,
      reverseDuration: widget.trailingExpandDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _expandTrainingAnimation = CurvedAnimation(
      parent: _expandTrainingController,
      curve: Curves.easeInOut,
    );

    ///设置监听
    _expandLeadingController.addListener(() {
      setState(() {});
    });
    _expandTrainingController.addListener(() {
      setState(() {});
    });
  }

  ///左侧forward
  void _leadingForward() {
    if (_leadingForwarding == false) {
      _leadingForwarding = true;
      _expandLeadingController.forward(from: _expandLeadingController.value);
    }
  }

  ///左侧reverse
  void _leadingReverse() {
    if (_leadingForwarding == true) {
      _leadingForwarding = false;
      _expandLeadingController.reverse(from: _expandLeadingController.value);
    }
  }

  ///右侧forward
  void _trainingForward() {
    if (_trainingForwarding = false) {
      _trainingForwarding = true;
      _expandTrainingController.forward(from: _expandTrainingController.value);
    }
  }

  ///右侧reverse
  void _trainingReverse() {
    if (_trainingForwarding = true) {
      _trainingForwarding = false;
      _expandTrainingController.reverse(from: _expandTrainingController.value);
    }
  }

  @override
  void initState() {
    super.initState();
    _initController();
    _recreateActionKeys();
    _resizeActualWidths();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant SlideableCellView oldWidget) {
    super.didUpdateWidget(oldWidget);

    ///如果长宽不一致,做完全的重建工作，重新_collectActionWidths获取宽高
    if (oldWidget.leadingActions.length != widget.leadingActions.length ||
        oldWidget.trailingActions.length != widget.trailingActions.length) {
      _recreateActionKeys();
      _resizeActualWidths();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _collectActionWidths();
        }
      });
    }

    ///重新绑定key值
    if (oldWidget.cellKey != widget.cellKey || oldWidget.controller != widget.controller) {
      oldWidget.controller._unregister(oldWidget.cellKey, _controllerEntry);
      _bindController();
    }
  }

  @override
  void dispose() {
    widget.controller._unregister(widget.cellKey, _controllerEntry);
    _snapAnimationController.dispose();
    super.dispose();
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
    final nextStatus = _offset == 0
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
    final animation = Tween<double>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _snapAnimationController, curve: widget.curve),
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
    await _snapAnimationController.forward(from: 0);
    animation.removeListener(listener);
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

  ///打开到指定的位置
  Future<void> _openTo({required double target}) async {
    if (widget.closeOthersWhenOpen) {
      await Future.wait([
        //关闭其他的
        _closeOtherOpenedCells(),
        //到指定位置
        _animateTo(target),
      ]);
    } else {
      //到指定位置
      await _animateTo(target);
    }
  }

  /// 关闭其他已打开的 items
  Future<void> _closeOtherOpenedCells() async {
    final currentKeyValue = widget.cellKey.value;
    final statusEntries = widget.controller.statuses.entries.toList(growable: false);
    final futures = <Future<void>>[];
    for (final entry in statusEntries) {
      final bool isCurrentCell = entry.key.value == currentKeyValue;
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

    ///左侧超出真实宽度时，优先回弹到真实宽度。
    if (_offset > 0 && leadingWidth > 0 && _offset > leadingWidth) {
      await _animateToLeadingOpen();
      return;
    }

    ///右侧超出真实宽度时，优先回弹到真实宽度。
    if (_offset < 0 && trailingWidth > 0 && (-_offset) > trailingWidth) {
      await _animateToTrailingOpen();
      return;
    }

    ///如果是关闭的
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

    ///如果是左侧打开
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

    ///如果是右侧打开
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _collectActionWidths();
      }
    });
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

  ///最大的drag的宽度
  double _maxDragDistance(double actualTotalWidth) {
    final viewport = MediaQuery.sizeOf(context).width;
    return actualTotalWidth > viewport ? actualTotalWidth : viewport;
  }

  ///提取child的颜色
  Color? _getChildColor(Widget child) {
    if (child is SlideableActionItem) {
      return child.slideBackgroundColor;
    } else {
      return null;
    }
  }

  /// 构建左侧 actions 区域。
  /// Builds leading action area.
  Widget _buildLeading() {
    if (widget.leadingActions.isEmpty) {
      return const SizedBox.shrink();
    }
    //计算左边的宽度
    final double leadingWidth = _offset.clamp(0.0, double.infinity);

    //同样获取实际的宽度
    final double totalActualWidth = _leadingActualTotalWidth;

    //如果左侧可打开
    if (widget.leadingFullExpandable) {
      ///这里处理expand展开收起触发
      if (leadingWidth > totalActualWidth + widget.leadingFullExpandExtra) {
        //触发展开
        _leadingForward();
      } else {
        //触发反向
        _leadingReverse();
      }

      ///如果已经大于了真实宽度,但是小于触发宽度
      if (leadingWidth > totalActualWidth) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: leadingWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(
                widget.leadingActions.length,
                (index) {
                  //获取当前item的实际宽度
                  final double currentActualWidth = _leadingActionActualWidths[index];
                  //获取item的key和child
                  GlobalKey globalKey = _leadingActionKeys[index];
                  //获取item action
                  Widget actionChild = widget.leadingActions[index];
                  //对第0条做处理,计算相应item的宽度
                  double itemWidth;
                  if (index == 0) {
                    //拖动的宽度
                    double dragWidth = (leadingWidth - totalActualWidth);
                    //展开的宽度
                    double expandWidth = (totalActualWidth - currentActualWidth) * _expandLeadingController.value;
                    //这里是宽度
                    itemWidth = dragWidth + currentActualWidth;

                    ///宽度
                    print("AAAAAA::$dragWidth + BBBBBB:::$expandWidth +CCCCCC:::$itemWidth");

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
                    //返回相应的
                    return Container(
                      width: itemWidth,
                      alignment: Alignment.center,
                      color: _getChildColor(actionChild),
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: double.infinity,
                        alignment: Alignment.center,
                        child: UnconstrainedBox(
                          constrainedAxis: Axis.vertical,
                          alignment: Alignment.center,
                          child: KeyedSubtree(
                            key: globalKey,
                            child: actionChild,
                          ),
                        ),
                      ),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List<Widget>.generate(
                widget.leadingActions.length,
                (index) {
                  //获取当前item的实际宽度
                  final double currentActualWidth = _leadingActionActualWidths[index];
                  //以比例进行均分
                  final double itemWidth = totalActualWidth > 0
                      ? leadingWidth * (currentActualWidth / totalActualWidth)
                      : leadingWidth / widget.leadingActions.length;

                  //获取item的key和child
                  GlobalKey globalKey = _leadingActionKeys[index];
                  Widget actionChild = widget.leadingActions[index];

                  //返回相应的
                  return ClipRect(
                    child: Container(
                      width: itemWidth,
                      alignment: Alignment.center,
                      color: _getChildColor(actionChild),
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: double.infinity,
                        alignment: Alignment.center,
                        child: UnconstrainedBox(
                          constrainedAxis: Axis.vertical,
                          alignment: Alignment.center,
                          child: KeyedSubtree(
                            key: globalKey,
                            child: actionChild,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                growable: false,
              ),
            ),
          ),
        );
      case SlideableCellExpandMode.adjustEdge:
        //如果大于了真实宽度，也使用everyItem的均分模式
        final shouldUseProportionalWidth = totalActualWidth > 0 && leadingWidth > totalActualWidth;
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List<Widget>.generate(
                  widget.leadingActions.length,
                  (index) {
                    if (shouldUseProportionalWidth) {
                      //获取当前item的实际宽度
                      final currentActualWidth = _leadingActionActualWidths[index];
                      final itemWidth = leadingWidth * (currentActualWidth / totalActualWidth);

                      //获取item的key和child
                      GlobalKey globalKey = _leadingActionKeys[index];
                      Widget actionChild = widget.leadingActions[index];

                      return ClipRect(
                        child: Container(
                          width: itemWidth,
                          alignment: Alignment.center,
                          color: _getChildColor(actionChild),
                          child: OverflowBox(
                            minWidth: 0,
                            maxWidth: double.infinity,
                            alignment: Alignment.center,
                            child: UnconstrainedBox(
                              constrainedAxis: Axis.vertical,
                              alignment: Alignment.center,
                              child: KeyedSubtree(
                                key: globalKey,
                                child: actionChild,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      //获取item的key和child
                      GlobalKey globalKey = _leadingActionKeys[index];
                      Widget actionChild = widget.leadingActions[index];
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
    //计算右边的宽度
    double trailingWidth = _offset < 0 ? -_offset : 0.0;
    //宽度
    trailingWidth = trailingWidth.clamp(0.0, double.infinity);
    //每个的宽度
    switch (widget.expandMode) {
      case SlideableCellExpandMode.everyItem:
        final totalActualWidth = _trailingActualTotalWidth;
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
                  //使用比例进行均分
                  final currentActualWidth = _trailingActionActualWidths[index];
                  final itemWidth = totalActualWidth > 0
                      ? trailingWidth * (currentActualWidth / totalActualWidth)
                      : trailingWidth / widget.trailingActions.length;
                  //获取item的key和child
                  GlobalKey globalKey = _trailingActionKeys[index];
                  Widget actionChild = widget.trailingActions[index];
                  return ClipRect(
                    child: Container(
                      width: itemWidth,
                      alignment: Alignment.center,
                      color: _getChildColor(actionChild),
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: double.infinity,
                        alignment: Alignment.center,
                        child: UnconstrainedBox(
                          constrainedAxis: Axis.vertical,
                          alignment: Alignment.center,
                          child: KeyedSubtree(
                            key: globalKey,
                            child: actionChild,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                growable: false,
              ),
            ),
          ),
        );
      case SlideableCellExpandMode.adjustEdge:
        final totalActualWidth = _trailingActualTotalWidth;
        final shouldUseProportionalWidth = totalActualWidth > 0 && trailingWidth > totalActualWidth;
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
                    if (shouldUseProportionalWidth) {
                      //如果大于了真实宽度，也使用everyItem的均分模式
                      final currentActualWidth = _trailingActionActualWidths[index];
                      final itemWidth = trailingWidth * (currentActualWidth / totalActualWidth);

                      //获取item的key和child
                      GlobalKey globalKey = _trailingActionKeys[index];
                      Widget actionChild = widget.trailingActions[index];

                      return ClipRect(
                        child: Container(
                          width: itemWidth,
                          alignment: Alignment.center,
                          color: _getChildColor(actionChild),
                          child: OverflowBox(
                            minWidth: 0,
                            maxWidth: double.infinity,
                            alignment: Alignment.center,
                            child: UnconstrainedBox(
                              constrainedAxis: Axis.vertical,
                              alignment: Alignment.center,
                              child: KeyedSubtree(
                                key: globalKey,
                                child: actionChild,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      //获取item的key和child
                      GlobalKey globalKey = _trailingActionKeys[index];
                      Widget actionChild = widget.trailingActions[index];
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
