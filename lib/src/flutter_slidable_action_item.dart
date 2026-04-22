import 'package:flutter/cupertino.dart';

///侧滑
class SlideableActionItem extends StatelessWidget {
  //当前的背景颜色
  final Color? color;

  //当前的child
  final Widget child;

  const SlideableActionItem({
    super.key,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
